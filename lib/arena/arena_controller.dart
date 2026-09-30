/// Điều phối 1 phiên Đấu Trường phía client: hàng đợi ghép trận → trong trận
/// (đếm ngược 60s, tính điểm 2 bên theo log thời gian thực) → kết quả.
///
/// Không đụng tới [GameController]/`GameState` trực tiếp — chỉ gọi
/// [onRewardGems] (UI nối tới `GameController.grantArenaReward`) đúng một
/// lần khi có kết quả, y như đường quest/IAP/ads.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'arena_config.dart';
import 'arena_models.dart';
import 'arena_repository.dart';
import 'arena_rules.dart';
import 'match3_rules.dart';

sealed class ArenaViewState {
  const ArenaViewState();
}

class ArenaIdle extends ArenaViewState {
  const ArenaIdle();
}

class ArenaQueued extends ArenaViewState {
  const ArenaQueued();
}

class ArenaInMatch extends ArenaViewState {
  const ArenaInMatch({
    required this.myScore,
    required this.opponentScore,
    required this.remaining,
    required this.tiersBought,
    this.mode = ArenaMode.tap,
    this.boardCells = const [],
    this.frames = const [],
    this.moveId = 0,
    this.stuck = false,
  });

  final ArenaMode mode;

  /// Dạng match3: bảng của MÌNH (64 ô, loại 0..4), các bảng trung gian của nước
  /// vừa đi để UI phát hoạt ảnh ([moveId] tăng mỗi nước hợp lệ), và [stuck] =
  /// không còn nước đi hợp lệ nào.
  final List<int> boardCells;
  final List<List<int>> frames;
  final int moveId;
  final bool stuck;

  final double myScore;
  final double opponentScore;
  final Duration remaining;

  /// Các mốc (0..2) đã gửi mua — dùng để khoá nút ngay lập tức (optimistic),
  /// không đợi server xác nhận mới ẩn nút đi.
  final Set<int> tiersBought;
}

class ArenaFinished extends ArenaViewState {
  const ArenaFinished(this.result);
  final ArenaResult result;
}

class ArenaError extends ArenaViewState {
  const ArenaError(this.message);
  final String message;
}

class ArenaController extends Notifier<ArenaViewState> {
  ArenaRepository? _repo;
  StreamSubscription<List<ArenaLogEntry>>? _actionsSub;
  Timer? _ticker;
  Timer? _queuePoll;
  String? _matchId;
  DateTime? _endsAt;
  List<ArenaLogEntry> _log = const [];
  final Set<int> _tiersBought = {};
  bool _resolving = false;

  ArenaMode _mode = ArenaMode.tap;
  List<int> _seq = const [];
  Match3Board _board = Match3Board.initial(const []);
  int _myMatchScore = 0;
  int _moveId = 0;
  List<List<int>> _lastFrames = const [];
  bool _stuck = false;
  bool _swapInFlight = false;
  bool _boardSynced = false;

  /// Gọi khi trận kết thúc để trao thưởng vào ván chính — set từ UI (nối tới
  /// `grantGems` của [GameController]) để module này không phải import
  /// `state/game_controller.dart` trực tiếp (giữ tách biệt như đề xuất).
  void Function(int gems)? onRewardGems;

  @override
  ArenaViewState build() {
    ref.onDispose(_cancelAll);
    return const ArenaIdle();
  }

  ArenaRepository get _repository =>
      _repo ??= ArenaRepository(Supabase.instance.client);

  Future<void> startMatchmaking([ArenaMode mode = ArenaMode.tap]) async {
    _cancelAll();
    _mode = mode;
    _tiersBought.clear();
    state = const ArenaQueued();
    try {
      await _repository.ensureSignedIn();
      await _pollForMatch();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> cancelQueue() async {
    _queuePoll?.cancel();
    if (state is ArenaQueued) {
      state = const ArenaIdle();
    }
    try {
      await _repository.leaveQueue();
    } catch (_) {
      // Không có gì để làm nếu leave thất bại — hàng đợi tự dọn khi trận sau
      // ghép hụt, không chặn người dùng thoát màn hình.
    }
  }

  Future<void> _pollForMatch() async {
    if (state is! ArenaQueued) return; // đã bị huỷ giữa chừng
    ArenaMatch? match;
    try {
      match = await _repository.joinQueue(_mode);
    } catch (e) {
      if (state is! ArenaQueued) return; // huỷ giữa lúc đang chờ mạng
      _fail(e);
      return;
    }
    // Người dùng có thể đã bấm "Huỷ" TRONG LÚC request trên đang bay — kiểm
    // tra lại state sau await, không tự ý đẩy họ vào trận nếu họ đã thoát ra.
    if (state is! ArenaQueued) return;
    if (match != null) {
      _enterMatch(match);
      return;
    }
    _queuePoll = Timer(const Duration(seconds: 2), _pollForMatch);
  }

  void _enterMatch(ArenaMatch match) {
    _matchId = match.id;
    _endsAt = match.endsAt;
    _log = const [];
    _resolving = false;
    _mode = match.mode;
    _seq = match.seq;
    _board = Match3Board.initial(_seq);
    _myMatchScore = 0;
    _moveId = 0;
    _lastFrames = const [];
    _stuck = false;
    _swapInFlight = false;
    _boardSynced = false;
    state = _buildState(0, 0);
    _actionsSub = _repository.watchActions(match.id).listen(
      (log) {
        _log = log;
        // Lần đầu (hoặc vào lại trận đang dở sau khi mở lại app) dựng bảng của
        // mình từ log server — nguồn sự thật, không phải bộ đếm cục bộ.
        if (_mode == ArenaMode.match3 && !_boardSynced) _resyncBoard();
        _recompute();
      },
      // Không bắt thì lỗi realtime (mất kết nối, token hết hạn giữa trận...)
      // rơi thành unhandled stream error — crash cả app. Xem [_fail].
      onError: _fail,
    );
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _onTick());
  }

  void _onTick() {
    if (state is! ArenaInMatch) return;
    if (_remaining() <= Duration.zero) {
      _finishMatch();
      return;
    }
    _recompute();
  }

  Duration _remaining() {
    final endsAt = _endsAt;
    if (endsAt == null) return Duration.zero;
    final d = endsAt.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  void _recompute() {
    if (state is! ArenaInMatch) return;
    final me = _repository.myUserId;
    if (me == null) return;
    final mine = <ArenaAction>[];
    final theirs = <ArenaAction>[];
    for (final entry in _log) {
      (entry.playerId == me ? mine : theirs).add(entry.action);
    }
    if (_mode == ArenaMode.match3) {
      state = _buildState(
        _myMatchScore.toDouble(),
        match3ComputeScore(_seq, theirs).toDouble(),
      );
      return;
    }
    state = _buildState(arenaComputeScore(mine), arenaComputeScore(theirs));
  }

  ArenaInMatch _buildState(double myScore, double opponentScore) {
    final match3 = _mode == ArenaMode.match3;
    return ArenaInMatch(
      myScore: myScore,
      opponentScore: opponentScore,
      remaining: _remaining(),
      tiersBought: Set.unmodifiable(_tiersBought),
      mode: _mode,
      boardCells: match3 ? List<int>.unmodifiable(_board.cells) : const [],
      frames: _lastFrames,
      moveId: _moveId,
      stuck: match3 && _stuck,
    );
  }

  /// Dựng lại bảng + điểm của MÌNH từ log server (thứ tự `at`, rồi `id`).
  void _resyncBoard() {
    final me = _repository.myUserId;
    if (me == null) return;
    final mine = [
      for (final e in _log)
        if (e.playerId == me && e.action.kind == ArenaActionKind.swap) e.action,
    ]..sort((a, b) {
        final byTime = a.at.compareTo(b.at);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    _board = Match3Board.initial(_seq);
    _myMatchScore = 0;
    for (var n = 0; n < mine.length && n < m3MaxMoves; n++) {
      _myMatchScore += _board.trySwap(mine[n].cell ?? -1, mine[n].dir ?? -1).score;
    }
    _lastFrames = const [];
    _stuck = !_board.hasAnyMove();
    _boardSynced = true;
  }

  /// Đổi ô [cell] với hàng xóm theo [dir] (0 = phải, 1 = dưới). Trả false (và
  /// không gửi server) nếu nước không hợp lệ. Cập nhật bảng cục bộ ngay (mượt),
  /// gửi server sau; mỗi lúc chỉ 1 nước đang bay — vừa giữ tốc độ dưới
  /// rate-limit server, vừa đảm bảo bảng cục bộ luôn khớp số nước server đã
  /// nhận. Lỗi mạng/bị chối → dựng lại từ log.
  bool swap(int cell, int dir) {
    final matchId = _matchId;
    final current = state;
    if (matchId == null || current is! ArenaInMatch) return false;
    if (_mode != ArenaMode.match3 || _swapInFlight || _stuck) return false;
    if (current.remaining <= Duration.zero) return false;
    final move = _board.trySwap(cell, dir);
    if (!move.valid) return false;
    _myMatchScore += move.score;
    _moveId++;
    _lastFrames = move.frames;
    _stuck = !_board.hasAnyMove();
    _swapInFlight = true;
    _recompute();
    unawaited(_submitSwap(matchId, cell, dir));
    return true;
  }

  Future<void> _submitSwap(String matchId, int cell, int dir) async {
    try {
      await _repository.submitSwap(matchId, cell, dir);
    } catch (e) {
      developer.log('nước đi bị chặn: $e', name: 'Arena');
      _resyncBoard();
    } finally {
      _swapInFlight = false;
      _recompute();
    }
  }

  /// Chạm ly trong trận — gửi lên server "cho có" (fire-and-forget); điểm
  /// hiển thị cập nhật qua log realtime ở [_recompute], không chờ phản hồi ở
  /// đây để giữ cảm giác bấm mượt (xem ghi chú trong PROPOSAL §3).
  ///
  /// Người chơi bấm nhanh tay rất dễ vượt rate-limit 12 tap/giây ở server
  /// (`arena_submit_action` ném lỗi) — PHẢI bắt lỗi ở đây dù không hiển thị
  /// gì, nếu không mỗi cú chạm bị chặn sẽ là 1 Future lỗi không ai xử lý.
  void tap() {
    final matchId = _matchId;
    final current = state;
    if (matchId == null || current is! ArenaInMatch) return;
    if (current.remaining <= Duration.zero) return; // đang chốt trận, đừng gửi thêm
    unawaited(
      _repository.submitAction(matchId, ArenaActionKind.tap).catchError((e) {
        developer.log('tap bị chặn (rate limit hoặc hết giờ): $e', name: 'Arena');
      }),
    );
  }

  /// Mua mốc nâng cấp thứ [tier] (0..2). Khoá nút ngay (optimistic) — nếu
  /// server từ chối (VD 2 request đua nhau) thì coi như mất lượt, không thử
  /// lại để tránh spam.
  Future<void> buyTier(int tier) async {
    final matchId = _matchId;
    final current = state;
    if (matchId == null || current is! ArenaInMatch) return;
    if (current.tiersBought.contains(tier)) return;
    _tiersBought.add(tier);
    _recompute();
    final kind = switch (tier) {
      0 => ArenaActionKind.buyTier1,
      1 => ArenaActionKind.buyTier2,
      2 => ArenaActionKind.buyTier3,
      _ => throw ArgumentError('tier phải trong 0..2, nhận $tier'),
    };
    try {
      await _repository.submitAction(matchId, kind);
    } catch (_) {
      // Server từ chối (VD chưa đủ tiền do lệch nhịp mạng) — bỏ khoá lại để
      // người chơi có thể thử mốc khác/mốc này lần nữa khi đủ tiền thật.
      _tiersBought.remove(tier);
      _recompute();
    }
  }

  Future<void> _finishMatch() async {
    if (_resolving) return;
    _resolving = true;
    _ticker?.cancel();
    await _actionsSub?.cancel();
    final matchId = _matchId;
    final me = _repository.myUserId;
    if (matchId == null || me == null) {
      state = const ArenaError('Thiếu thông tin trận đấu.');
      return;
    }
    try {
      // Server chối "match not finished yet" nếu đồng hồ client/server lệch
      // nhẹ (client tưởng hết giờ sớm hơn) — thử lại vài lần thay vì báo lỗi
      // ngay, tránh phiền người chơi vì vài trăm mili-giây lệch nhịp.
      ArenaMatch? resolved;
      for (var attempt = 0; attempt < 5 && resolved == null; attempt++) {
        try {
          resolved = await _repository.resolveMatch(matchId);
        } catch (e) {
          if (attempt == 4) rethrow;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
      final iAmPlayerA = me == resolved!.playerA;
      final myScore = iAmPlayerA ? resolved.scoreA : resolved.scoreB;
      final opponentScore = iAmPlayerA ? resolved.scoreB : resolved.scoreA;
      final result = ArenaResult(
        myScore: myScore,
        opponentScore: opponentScore,
        won: resolved.winner == me,
      );
      state = ArenaFinished(result);
      onRewardGems?.call(result.won ? ArenaConfig.winGems : ArenaConfig.loseGems);
    } catch (e) {
      _fail(e);
    }
  }

  void backToIdle() {
    _cancelAll();
    state = const ArenaIdle();
  }

  /// Ghi log chi tiết (không phơi ra UI — thông báo lỗi kỹ thuật khó hiểu với
  /// người chơi thường) rồi hiện thông báo chung, giống cách xử lý lỗi
  /// rewarded ad ở `real_ad_service.dart`.
  void _fail(Object error) {
    developer.log('$error', name: 'Arena');
    state = const ArenaError('Đấu Trường đang gặp sự cố, thử lại sau nhé.');
  }

  void _cancelAll() {
    _queuePoll?.cancel();
    _ticker?.cancel();
    unawaited(_actionsSub?.cancel());
    _queuePoll = null;
    _ticker = null;
    _actionsSub = null;
    _matchId = null;
    _endsAt = null;
    _log = const [];
    _tiersBought.clear();
    _resolving = false;
    _seq = const [];
    _board = Match3Board.initial(const []);
    _myMatchScore = 0;
    _moveId = 0;
    _lastFrames = const [];
    _stuck = false;
    _swapInFlight = false;
    _boardSynced = false;
  }
}

/// Số người đang ở Đấu Trường (Realtime Presence). autoDispose: chỉ giữ kết nối
/// khi trang Đấu Trường đang mở và có nghe.
final arenaOnlineCountProvider = StreamProvider.autoDispose<int>(
  (ref) => ArenaRepository(Supabase.instance.client).watchOnlineCount(),
);

final arenaControllerProvider =
    NotifierProvider<ArenaController, ArenaViewState>(ArenaController.new);
