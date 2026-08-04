/// Controller nối `core/` (mô phỏng) với UI qua Riverpod.
///
/// Giữ [GameState] mutable bên trong, chạy timer tick mỗi giây, và phát
/// [GameSnapshot] bất biến mỗi khi trạng thái đổi. Đây là cầu nối duy nhất —
/// UI không đụng thẳng vào GameState.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/balance.dart';
import '../core/economy.dart';
import '../core/models.dart';
import '../core/simulation.dart';
import '../data/game_storage.dart';
import 'game_providers.dart';
import 'game_snapshot.dart';

class GameController extends Notifier<GameSnapshot> {
  /// Nhịp cộng tiền khi app đang mở.
  static const Duration tickInterval = Duration(seconds: 1);

  /// Tự lưu sau mỗi bao nhiêu tick (10s) để phòng mất tiến độ.
  static const int autoSaveEveryTicks = 10;

  late final GameStorage _storage;
  late final int Function() _clock;
  late GameState _game;
  Timer? _timer;
  int _ticksSinceSave = 0;
  double _offlineEarned = 0;

  final Random _random = Random();

  /// Mưa vàng (runtime, KHÔNG persist): boost kết thúc lúc nào, mèo có đang hiện.
  int _boostUntilMillis = 0;
  bool _catVisible = false;
  int _catShownAtMillis = 0;
  int _nextCatMillis = 0;

  /// Khách VIP (runtime, giống sự kiện mèo nhưng thưởng Kim Cương).
  bool _vipVisible = false;
  int _vipShownAtMillis = 0;
  int _nextVipMillis = 0;

  @override
  GameSnapshot build() {
    _storage = ref.read(gameStorageProvider);
    _clock = ref.read(clockProvider);
    _game = _storage.load() ?? GameState.newGame(nowMillis: _clock());
    // Tính tiền kiếm được lúc app tắt (có cap + chống lùi giờ ở tầng core).
    _offlineEarned = applyOfflineEarnings(
      _game,
      _clock(),
      maxOfflineSeconds: offlineCapSeconds(_game.offlineCapLevel),
    );
    _scheduleNextCat(_clock());
    _scheduleNextVip(_clock());
    _timer = Timer.periodic(tickInterval, (_) => _onTick());
    ref.onDispose(() => _timer?.cancel());
    return _snapshot();
  }

  /// Hệ số boost đang áp dụng (×3 khi Mưa vàng còn hiệu lực, ngược lại 1.0).
  double _boostMultiplier() =>
      _clock() < _boostUntilMillis ? Balance.goldenRushMultiplier : 1.0;

  /// Người chơi chạm con mèo → kích hoạt Mưa vàng ×3 trong 2 phút.
  void activateGoldenRush() {
    if (!_catVisible) return;
    final now = _clock();
    _boostUntilMillis = now + Balance.goldenRushDurationMs;
    _catVisible = false;
    _scheduleNextCat(now);
    state = _snapshot();
  }

  void _scheduleNextCat(int now) {
    final span = Balance.catSpawnMaxMs - Balance.catSpawnMinMs;
    _nextCatMillis = now + Balance.catSpawnMinMs + _random.nextInt(span + 1);
  }

  /// Cập nhật vòng đời con mèo mỗi tick: hiện khi tới giờ, tự ẩn nếu để lâu.
  void _updateCat(int now) {
    if (!_catVisible && now >= _nextCatMillis) {
      _catVisible = true;
      _catShownAtMillis = now;
    } else if (_catVisible && now - _catShownAtMillis >= Balance.catLingerMs) {
      _catVisible = false;
      _scheduleNextCat(now);
    }
  }

  /// Ép hiện mèo ngay (chỉ dùng cho test).
  @visibleForTesting
  void debugSpawnCat() {
    _catVisible = true;
    _catShownAtMillis = _clock();
    state = _snapshot();
  }

  /// Khách VIP đến (đi ô tô): thu tiền lớn + tip Kim Cương. KHÔNG cần xem quảng
  /// cáo — đây là thưởng cho sự hiện diện và là nguồn "faucet" Kim Cương.
  /// Trả về phần thưởng để UI hiển thị (0/0 nếu không có VIP).
  ({double cash, int gems}) collectVip() {
    if (!_vipVisible) return (cash: 0.0, gems: 0);
    final now = _clock();
    final gems = Balance.vipGemsMin +
        _random.nextInt(Balance.vipGemsMax - Balance.vipGemsMin + 1);
    final production = effectiveIncomePerSecond(
          _game,
          Balance.generators,
          bonusPerStar: Balance.bonusPerStar,
        ) *
        Balance.vipCashSeconds;
    final cash = max(production, _game.tapValue * 10); // "x10 tiền" làm sàn
    grantBonus(_game, cash);
    _game.gems += gems;
    _vipVisible = false;
    _scheduleNextVip(now);
    state = _snapshot();
    return (cash: cash, gems: gems);
  }

  void _scheduleNextVip(int now) {
    final span = Balance.vipSpawnMaxMs - Balance.vipSpawnMinMs;
    _nextVipMillis = now + Balance.vipSpawnMinMs + _random.nextInt(span + 1);
  }

  /// Cập nhật vòng đời VIP mỗi tick (song song với mèo).
  void _updateVip(int now) {
    if (!_vipVisible && now >= _nextVipMillis) {
      _vipVisible = true;
      _vipShownAtMillis = now;
    } else if (_vipVisible && now - _vipShownAtMillis >= Balance.vipLingerMs) {
      _vipVisible = false;
      _scheduleNextVip(now);
    }
  }

  /// Ép hiện VIP ngay (chỉ dùng cho test).
  @visibleForTesting
  void debugSpawnVip() {
    _vipVisible = true;
    _vipShownAtMillis = _clock();
    state = _snapshot();
  }

  /// Chạy một nhịp tick (chỉ dùng cho test, thay cho việc chờ timer thật).
  @visibleForTesting
  void debugTick() => _onTick();

  /// Chạm ly → +tiền (nhân boost Mưa vàng nếu đang có).
  void tapCup() {
    tap(_game, boostMultiplier: _boostMultiplier());
    state = _snapshot();
  }

  /// Nâng cấp một nguồn thu. Trả về true nếu đủ tiền và mua thành công.
  bool buy(String generatorId) {
    final ok = buyUpgrade(_game, generatorId);
    if (ok) state = _snapshot();
    return ok;
  }

  /// Mở khóa giai đoạn kế tiếp bằng tiền. Trả về true nếu thành công.
  bool unlockStage() {
    final ok = unlockNextStage(_game);
    if (ok) {
      unawaited(saveNow());
      state = _snapshot();
    }
    return ok;
  }

  /// Mua vật phẩm Kim Cương "Tăng thu nhập". Lưu ngay vì gems là premium.
  bool buyGemBoostUpgrade() {
    final ok = buyGemBoost(_game);
    if (ok) {
      unawaited(saveNow());
      state = _snapshot();
    }
    return ok;
  }

  /// Mua vật phẩm Kim Cương "Kho lạnh offline". Lưu ngay vì gems là premium.
  bool buyOfflineCapUpgrade() {
    final ok = buyOfflineCap(_game);
    if (ok) {
      unawaited(saveNow());
      state = _snapshot();
    }
    return ok;
  }

  /// Nhượng quyền. Trả về số Sao vừa nhận (0 nếu chưa đủ).
  int doPrestige() {
    final gained = prestige(_game);
    if (gained > 0) {
      unawaited(saveNow());
      state = _snapshot();
    }
    return gained;
  }

  /// Lưu ngay — UI gọi khi app chuyển nền (AppLifecycleState.paused).
  Future<void> saveNow() => _storage.save(_game, nowMillis: _clock());

  /// UI gọi khi app trở lại foreground: bù tiền cho khoảng vừa ở nền.
  void handleResume() {
    _offlineEarned = applyOfflineEarnings(
      _game,
      _clock(),
      maxOfflineSeconds: offlineCapSeconds(_game.offlineCapLevel),
    );
    state = _snapshot();
  }

  /// UI gọi sau khi đã hiện popup tiền offline.
  void acknowledgeOffline() {
    if (_offlineEarned == 0) return;
    _offlineEarned = 0;
    state = _snapshot();
  }

  /// Nhân đôi tiền offline (sau khi người chơi xem quảng cáo thưởng): cộng
  /// thêm đúng bằng số vừa nhận. Trả về số Xu thưởng thêm (0 nếu không có).
  double claimDoubleOffline() {
    if (_offlineEarned <= 0) return 0;
    final bonus = _offlineEarned;
    grantBonus(_game, bonus);
    _offlineEarned = 0;
    state = _snapshot();
    return bonus;
  }

  /// "Tiền tức thì" (sau khi xem quảng cáo): thưởng bằng
  /// [Balance.instantCashSeconds] giây sản xuất theo nhịp cơ bản (không tính
  /// boost Mưa vàng cho ổn định). Trả về số Xu thưởng (0 nếu chưa có thu nhập).
  double claimInstantCash() {
    final reward = effectiveIncomePerSecond(
          _game,
          Balance.generators,
          bonusPerStar: Balance.bonusPerStar,
        ) *
        Balance.instantCashSeconds;
    if (reward <= 0) return 0;
    grantBonus(_game, reward);
    state = _snapshot();
    return reward;
  }

  /// Xóa save và bắt đầu ván mới (nút chơi lại / debug).
  Future<void> resetGame() async {
    await _storage.clear();
    _game = GameState.newGame(nowMillis: _clock());
    _ticksSinceSave = 0;
    state = _snapshot();
  }

  void _onTick() {
    final now = _clock();
    final dt = (now - _game.lastSeenMillis) / 1000.0;
    if (dt > 0) {
      tick(_game, dt, boostMultiplier: _boostMultiplier());
      // Giữ mốc "đã tính tiền tới đây" luôn cập nhật trong lúc chơi, để lần
      // tính offline kế tiếp không đếm trùng thời gian online.
      _game.lastSeenMillis = now;
    }
    _updateCat(now);
    _updateVip(now);
    if (++_ticksSinceSave >= autoSaveEveryTicks) {
      _ticksSinceSave = 0;
      unawaited(saveNow());
    }
    state = _snapshot();
  }

  GameSnapshot _snapshot() {
    final remainingMs = _boostUntilMillis - _clock();
    return GameSnapshot(
      money: _game.money,
      gems: _game.gems,
      incomePerSecond: effectiveIncomePerSecond(
        _game,
        Balance.generators,
        bonusPerStar: Balance.bonusPerStar,
        boostMultiplier: _boostMultiplier(),
      ),
      prestigeStars: _game.prestigeStars,
      prestigeStarsAvailable: prestigeStarsAvailable(_game),
      offlineEarned: _offlineEarned,
      catVisible: _catVisible,
      boostRemainingSeconds: remainingMs > 0 ? remainingMs / 1000.0 : 0,
      vipVisible: _vipVisible,
      gemBoostLevel: _game.gemBoostLevel,
      offlineCapLevel: _game.offlineCapLevel,
      stage: _game.stage,
      levels: _game.levels,
    );
  }
}
