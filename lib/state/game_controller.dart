/// Controller nối `core/` (mô phỏng) với UI qua Riverpod.
///
/// Giữ [GameState] mutable bên trong, chạy timer tick mỗi giây, và phát
/// [GameSnapshot] bất biến mỗi khi trạng thái đổi. Đây là cầu nối duy nhất —
/// UI không đụng thẳng vào GameState.
library;

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/accessories.dart';
import '../core/achievements.dart';
import '../core/balance.dart';
import '../core/collection_milestones.dart';
import '../core/daily.dart';
import '../core/daily_quests.dart';
import '../core/economy.dart';
import '../core/models.dart';
import '../core/quests.dart';
import '../core/redeem.dart';
import '../core/rival.dart';
import '../core/simulation.dart';
import '../core/starter_pack.dart' as market_starter;
import '../core/story.dart';
import '../core/vip.dart';
import '../core/wheel.dart';
import '../data/analytics_repository.dart';
import '../data/cloud_save_repository.dart';
import '../data/game_storage.dart';
import '../market/accessory_market_repository.dart';
import 'game_providers.dart';
import 'game_snapshot.dart';

class GameController extends Notifier<GameSnapshot> {
  /// Nhịp cộng tiền khi app đang mở.
  static const Duration tickInterval = Duration(seconds: 1);

  /// Tự lưu sau mỗi bao nhiêu tick (10s) để phòng mất tiến độ.
  static const int autoSaveEveryTicks = 10;

  late final GameStorage _storage;
  late final int Function() _clock;
  CloudSaveRepository? _cloudSaveRepo;
  AnalyticsRepository? _analyticsRepo;
  AccessoryMarketRepository? _marketRepo;

  /// Bookkeeping đồng bộ cloud cục bộ — xem GameStorage.loadCloudVersion()/
  /// loadCloudConflictPending() cho lý do tách riêng khỏi [_game].
  int _cloudVersion = 0;
  bool _cloudConflictPending = false;
  int _sessionStartMillis = 0;
  late GameState _game;
  Timer? _timer;
  int _ticksSinceSave = 0;
  double _offlineEarned = 0;

  /// Thành tựu vừa mở khoá, chờ UI hiển thị (xoá qua acknowledgeAchievements).
  List<Achievement> _newAchievements = const [];

  final Random _random = Random();

  /// Mưa vàng: mèo có đang hiện hay không vẫn runtime-only (không cần
  /// persist — mèo tự spawn lại). Lúc boost kết thúc thì persist trong
  /// `_game.boostUntilMillis` (xem GameState) để kill app giữa buff không
  /// mất — trước đây là field runtime riêng, đã gộp vào GameState.
  bool _catVisible = false;
  int _catShownAtMillis = 0;
  int _nextCatMillis = 0;

  /// Khách VIP (runtime, giống sự kiện mèo nhưng thưởng Kim Cương).
  bool _vipVisible = false;
  int _vipShownAtMillis = 0;
  int _nextVipMillis = 0;

  /// Đối thủ cạnh tranh — sự kiện đang chờ trả lời (runtime, giống mèo/VIP) +
  /// buff/debuff tạm sau lựa chọn đối phó (runtime như Mưa vàng — kill app là mất,
  /// khớp cách xử lý boost hiện có).
  RivalEventType? _rivalEventPending;
  int _nextRivalEventMillis = 0;
  int _rivalModUntilMillis = 0;
  double _rivalModMult = 1.0;

  @override
  GameSnapshot build() {
    _storage = ref.read(gameStorageProvider);
    _clock = ref.read(clockProvider);
    _game = _storage.load() ?? GameState.newGame(nowMillis: _clock());
    sanitizeRepeatQuest(_game);
    _cloudVersion = _storage.loadCloudVersion();
    _cloudConflictPending = _storage.loadCloudConflictPending();
    // Bù mốc cho save đã hoàn thành Chương 18 TỪ TRƯỚC lúc sửa bug 2026-09-12
    // (makeStoryChoice() không chốt storyCompleteSeconds cho chương lựa chọn
    // CUỐI — xem story-speedrun-completion-never-fired memory): người chơi
    // đã chọn nhánh xong (storyChapter đã lên 18) nhưng mốc chưa từng được
    // ghi, nên KHÔNG BAO GIỜ hiện lên Bảng xếp hạng tốc độ dù đã hoàn thành
    // thật. Không có cách nào biết lại đúng thời điểm họ thực sự hoàn thành
    // (không được ghi lúc đó) — dùng thời điểm mở app NÀY làm mốc best-effort
    // (số giây sẽ cao hơn thực tế, nhưng còn hơn không bao giờ xuất hiện được).
    // `_stampStoryFinales` tự bỏ qua khi firstPlayedMillis không đáng tin
    // (xem GameState.firstPlayedIsEstimate) — cùng logic cho mốc Chương 28.
    _stampStoryFinales(_game.storyChapter, exact: false);
    // Save từ cloud/phiên bản khác có thể liệt kê món không còn sở hữu hoặc quá số chỗ.
    _game.equippedAccessories
      ..removeWhere((id) => !_game.ownedAccessories.contains(id))
      ..removeRange(
          _game.equippedAccessories.length.clamp(0, Balance.maxEquippedAccessories),
          _game.equippedAccessories.length);
    _rollDaily();
    // Tính tiền kiếm được lúc app tắt (có cap + chống lùi giờ ở tầng core).
    _offlineEarned = applyOfflineEarnings(
      _game,
      _clock(),
      maxOfflineSeconds: _offlineCap(),
    );
    claimVipDailyGems(_game, _clock()); // Kim Cương VIP nếu sang ngày mới
    _scheduleNextCat(_clock());
    _scheduleNextVip(_clock());
    if (rivalActive(_game)) _scheduleNextRivalEvent(_clock());
    _timer = Timer.periodic(tickInterval, (_) => _onTick());
    ref.onDispose(() => _timer?.cancel());
    _awardAchievements(); // thành tựu đạt sẵn từ trước / qua tiền offline
    _sessionStartMillis = _clock();
    unawaited(_analytics?.log('session_start', {
      'stage': _game.stage,
      'prestigeStars': _game.prestigeStars,
      'lifetimeEarnings': _game.lifetimeEarnings,
    }));
    return _snapshot();
  }

  /// Hệ số boost thời gian đang áp dụng: ×3 Mưa vàng và/hoặc ×2 "thu nhập 24h"
  /// (xem QC). Cộng dồn nếu trùng.
  double _boostMultiplier() {
    final now = _clock();
    var m = 1.0;
    if (now < _game.boostUntilMillis) m *= Balance.goldenRushMultiplier;
    if (now < _game.x2IncomeUntilMillis) m *= Balance.rewardedX2Multiplier;
    if (vipActive(_game, now)) m *= Balance.vipIncomeMultiplier;
    return m > Balance.maxTimeBoostMultiplier
        ? Balance.maxTimeBoostMultiplier
        : m;
  }

  /// Buff/debuff tạm của đối thủ (1.0 nếu đã hết hạn). Áp cho thu nhập tự động
  /// khi ĐANG CHƠI và giá trị chạm — KHÔNG áp offline (giống boost tạm).
  double _rivalModifier() =>
      _clock() < _rivalModUntilMillis ? _rivalModMult : 1.0;

  /// Hệ số sự kiện giới hạn thời gian đang chạy (Remote Config) — xem
  /// eventMultiplierAt() ở economy.dart. Tách khỏi _boostMultiplier() (không
  /// cộng vào trần Balance.maxTimeBoostMultiplier): sự kiện là một tầng độc
  /// lập, giống _rivalModifier(), không phải một loại "Mưa vàng" nữa.
  double _eventMultiplier() => eventMultiplierAt(
        _clock(),
        mult: Balance.eventIncomeMult,
        startMillis: Balance.eventStartMillis,
        endMillis: Balance.eventEndMillis,
      );

  /// true nếu sự kiện đang chạy NGAY LÚC NÀY — UI dùng để hiện banner.
  bool get eventActive => _eventMultiplier() > 1.0;

  /// Số giây còn lại tới lúc sự kiện kết thúc, 0 nếu không có sự kiện đang
  /// chạy. Dùng cho đồng hồ đếm ngược ở banner.
  int get eventRemainingSeconds {
    if (!eventActive) return 0;
    return max(0, ((Balance.eventEndMillis - _clock()) / 1000).ceil());
  }

  /// Trần offline (giây) hiện tại — UI dùng để hẹn giờ thông báo "kho đã đầy"
  /// (lib/notify/reminders.dart).
  // Tên khác `offlineCapSeconds` của economy.dart (đã import) để khỏi che nó.
  int get currentOfflineCapSeconds => _offlineCap();

  /// Trần offline (giây) đã tính cấp "Kho lạnh" + cộng thưởng VIP nếu đang VIP.
  int _offlineCap() =>
      offlineCapSeconds(_game.offlineCapLevel) +
      (vipActive(_game, _clock()) ? Balance.vipOfflineBonusSeconds : 0);

  /// Người chơi chạm con mèo → kích hoạt Mưa vàng ×3 trong 2 phút.
  void activateGoldenRush() {
    if (!_catVisible) return;
    final now = _clock();
    _game.boostUntilMillis = now + Balance.goldenRushDurationMs;
    addDailyProgress(_game, DailyQuestKind.cat, 1);
    _catVisible = false;
    _scheduleNextCat(now);
    unawaited(saveNow()); // lưu ngay — persist boostUntilMillis, không đợi 10s
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
    addDailyProgress(_game, DailyQuestKind.vip, 1);
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

  // --- Đối thủ cạnh tranh ---

  void _scheduleNextRivalEvent(int now) {
    final span =
        Balance.rivalEventSpawnMaxMs - Balance.rivalEventSpawnMinMs;
    _nextRivalEventMillis =
        now + Balance.rivalEventSpawnMinMs + _random.nextInt(span + 1);
  }

  /// Vòng đời sự kiện đối thủ mỗi tick: tới giờ & chưa có sự kiện chờ → tung một
  /// sự kiện ngẫu nhiên. Đồng thời chốt "hạ đối thủ" khi đủ điều kiện.
  void _updateRival(int now) {
    if (!rivalActive(_game)) return;
    if (_rivalEventPending == null && now >= _nextRivalEventMillis) {
      _rivalEventPending = RivalEventType
          .values[_random.nextInt(RivalEventType.values.length)];
    }
    if (rivalDefeatable(_game)) {
      _game.rivalDefeated = true;
      _rivalEventPending = null;
      unawaited(saveNow());
    }
  }

  void _applyRivalOutcome(RivalOutcome o) {
    _game.money -= o.spendMoney;
    _game.gems -= o.spendGems;
    _game.rivalPressureSeconds =
        max(0.0, _game.rivalPressureSeconds + o.pressureDelta);
    if (o.modifierSeconds > 0) {
      _rivalModMult = o.modifierMult;
      _rivalModUntilMillis = _clock() + o.modifierSeconds * 1000;
    }
  }

  /// Hai lựa chọn đối phó cho sự kiện đối thủ đang chờ (rỗng nếu không có sự
  /// kiện). Chi phí theo % Xu hiện có nên tính lúc gọi.
  List<RivalOutcome> pendingRivalOptions() {
    final type = _rivalEventPending;
    return type == null ? const [] : rivalOptions(_game, type);
  }

  /// Lựa chọn [optionIndex] có đủ tài nguyên để chọn không.
  bool rivalOptionAffordable(int optionIndex) {
    final opts = pendingRivalOptions();
    return optionIndex >= 0 &&
        optionIndex < opts.length &&
        opts[optionIndex].affordableFor(_game);
  }

  /// Đối phó sự kiện đối thủ bằng lựa chọn [optionIndex] (0/1). Trả về false nếu
  /// không đủ tài nguyên hoặc không có sự kiện. Lưu ngay (có tiêu 💎).
  bool resolveRivalEvent(int optionIndex) {
    final type = _rivalEventPending;
    if (type == null) return false;
    final outcome = rivalOptions(_game, type)[optionIndex];
    if (!outcome.affordableFor(_game)) return false;
    _applyRivalOutcome(outcome);
    _rivalEventPending = null;
    _scheduleNextRivalEvent(_clock());
    if (rivalDefeatable(_game)) _game.rivalDefeated = true;
    unawaited(saveNow());
    state = _snapshot();
    return true;
  }

  /// Phớt lờ sự kiện đối thủ: đối thủ lấn tới + debuff tạm.
  void ignoreRivalEvent() {
    if (_rivalEventPending == null) return;
    _applyRivalOutcome(rivalIgnoreOutcome);
    _rivalEventPending = null;
    _scheduleNextRivalEvent(_clock());
    unawaited(saveNow());
    state = _snapshot();
  }

  /// UI đã hiển thị xong một chương truyện (nút "Tiếp tục"): bump con trỏ chương.
  /// Với chương lựa chọn, con trỏ vẫn bump nhưng `pendingStoryChapterId` còn trả
  /// lại chính nó tới khi [makeStoryChoice] được gọi.
  void acknowledgeStoryBeat() {
    final id = pendingChapterId(_game);
    if (id == null) return;
    final firstTime = id > _game.storyChapter;
    markChapterSeen(_game, id);
    if (firstTime && id == rivalIntroChapter) {
      _scheduleNextRivalEvent(_clock());
    }
    // Vừa xem xong chương cuối lần đầu — chốt mốc thời gian hoàn thành cốt
    // truyện (giây thực tế kể từ firstPlayedMillis), dùng cho Bảng xếp hạng
    // tốc độ. Ghi 1 lần, không đổi lại (giống storyChoiceA/B/C/D).
    if (firstTime) _stampStoryFinales(id, exact: true);
    unawaited(saveNow());
    state = _snapshot();
  }

  /// Chốt mốc thời gian hoàn thành cốt truyện (giây thực tế từ firstPlayedMillis)
  /// cho bảng "Hồi 1" (Chương 18), "Hồi 2" (Chương 28) và "Hồi 3" (Chương 36).
  /// Mỗi mốc ghi đúng 1 lần. [exact] = chương vừa xem xong (== mốc); false =
  /// save đã ở chương >= mốc (bù mốc lúc mở app).
  void _stampStoryFinales(int chapter, {required bool exact}) {
    // firstPlayedMillis là giá trị ĐOÁN (save cũ chưa từng có mốc thật, xem
    // GameState.firstPlayedIsEstimate) → `clock - firstPlayedMillis` có thể
    // ra một con số nhỏ giả tạo (đo được trên bảng xếp hạng thật: 86s, 150s
    // cho save lẽ ra phải mất hàng giờ mới lên tới GĐ12). Không chốt gì cả
    // còn hơn chốt sai — bỏ qua vĩnh viễn cho save này, không phải lỗi.
    if (_game.firstPlayedIsEstimate) return;
    bool hit(int finale) => exact ? chapter == finale : chapter >= finale;
    final seconds = max(1, (_clock() - _game.firstPlayedMillis) ~/ 1000);
    if (hit(storyFinaleChapterId) && _game.storyCompleteSeconds == null) {
      _game.storyCompleteSeconds = seconds;
    }
    if (hit(storyExtendedFinaleChapterId) &&
        _game.storyExtCompleteSeconds == null) {
      _game.storyExtCompleteSeconds = seconds;
    }
    if (hit(storyThirdActFinaleChapterId) &&
        _game.storyThirdActCompleteSeconds == null) {
      _game.storyThirdActCompleteSeconds = seconds;
    }
  }

  /// Ghi lựa chọn nhánh cho chương đang hiển thị. Trả về true nếu vừa ghi.
  bool makeStoryChoice(String optionKey) {
    final id = pendingChapterId(_game);
    if (id == null) return false;
    if (!applyStoryChoice(_game, id, optionKey)) return false;
    final firstTime = id > _game.storyChapter;
    markChapterSeen(_game, id);
    // Bug thật (2026-09-12): Chương 18 (chương CUỐI) cũng là chương lựa chọn
    // — story_dialog.dart không hề render nút "Tiếp tục" cho chương lựa chọn
    // (actions: isChoice ? null : [...]), chỉ có 2 nút chọn nhánh gọi
    // onChoose → hàm này. Trước đây mốc storyCompleteSeconds CHỈ được chốt ở
    // acknowledgeStoryBeat() (nhánh "Tiếp tục") — nghĩa là không người chơi
    // thật nào từng kích hoạt được nó khi hoàn thành cốt truyện thật sự, làm
    // Bảng xếp hạng tốc độ hoàn thành không bao giờ có dữ liệu thật. Chốt
    // cùng logic ở đây, giống hệt acknowledgeStoryBeat.
    if (firstTime) _stampStoryFinales(id, exact: true);
    unawaited(saveNow());
    state = _snapshot();
    return true;
  }

  /// Ép con trỏ chương (chỉ dùng cho test).
  @visibleForTesting
  void debugSetStoryChapter(int chapter) {
    _game.storyChapter = chapter;
    if (rivalActive(_game)) _scheduleNextRivalEvent(_clock());
    state = _snapshot();
  }

  /// Ép hiện một sự kiện đối thủ ngay (chỉ dùng cho test).
  @visibleForTesting
  void debugSpawnRivalEvent(RivalEventType type) {
    _rivalEventPending = type;
    state = _snapshot();
  }

  /// Chạy một nhịp tick (chỉ dùng cho test, thay cho việc chờ timer thật).
  @visibleForTesting
  void debugTick() => _onTick();

  /// Cộng tiền ngay (chỉ dùng cho test).
  @visibleForTesting
  void debugGrantCash(double amount) {
    grantBonus(_game, amount);
    state = _snapshot();
  }

  /// Đếm số cấp nâng cấp: vừa vào [GameState.buyCount] (nhiệm vụ chuỗi) vừa vào
  /// nhiệm vụ ngày "Nâng cấp". Đếm SỐ LẦN MUA, không đếm cấp hiện có — nên
  /// Nhượng quyền/Kỷ Nguyên (reset cấp) không làm tiến độ ngày tụt.
  void _addBuys(int n) {
    if (n <= 0) return;
    _game.buyCount += n;
    addDailyProgress(_game, DailyQuestKind.buy, n.toDouble());
  }

  /// Sang ngày (UTC) mới thì đổi bộ nhiệm vụ ngày. Gọi TRƯỚC khi cộng tiền
  /// offline để Xu lúc vắng tính vào ngày hôm nay, không bị xoá ngay sau đó.
  void _rollDaily() {
    rollDailyQuests(
      _game,
      _clock(),
      effectiveIncomePerSecond(_game, Balance.generators,
          bonusPerStar: Balance.bonusPerStar),
    );
  }

  /// Nhận thưởng nhiệm vụ ngày thứ [index] (0..2). Trả về 💎 nhận (0 nếu chưa
  /// xong/đã nhận). Lưu ngay vì 💎 là premium.
  int claimDailyQuestReward(int index) {
    final gems = claimDailyQuest(_game, index);
    if (gems > 0) {
      unawaited(saveNow());
      state = _snapshot();
    }
    return gems;
  }

  /// Nhận thưởng "xong cả 3 nhiệm vụ ngày" — kèm rớt 1 phụ kiện sưu tập
  /// (trùng thì quy đổi 💎, xem grantAccessory). Không đổi chữ ký trả về
  /// (int gems) để khỏi đụng `claim()` helper dùng chung ở daily_quests_dialog.dart
  /// — phụ kiện vừa nhận không có popup riêng, xem ở màn "Kho phụ kiện".
  /// Lần rớt phụ kiện gần nhất (nhiệm vụ ngày hoặc rương vòng quay) — KHÔNG lưu, chỉ để UI
  /// đọc ngay sau khi nhận và hiện "khoảnh khắc nhận".
  AccessoryDrop? lastAccessoryDrop;

  /// Rớt 1 phụ kiện ngẫu nhiên: cấp cho ván, ghi nhận lên server NGAY (không đợi lúc đăng
  /// bán — xem _registerAccessoryDropServerSide và PROPOSAL_ACCESSORY_MARKET.md §0 cho lý do:
  /// chặn thông đồng 2 tài khoản bơm phụ kiện giả). Fire-and-forget: không chặn/trễ việc
  /// nhận thưởng cục bộ. Dùng chung cho nhiệm vụ ngày và rương vòng quay.
  AccessoryDrop _dropAccessory({
    required String source,
    AccessoryRarity? rarity,
  }) {
    final rolled = rarity == null
        ? rollAccessoryWith(_random)
        : rollAccessoryOfRarity(rarity, _random.nextDouble());
    final isNew = grantAccessory(_game, rolled);
    unawaited(
      _registerAccessoryDropServerSide(
        rolled.id,
        1 + (_game.accessorySpares[rolled.id] ?? 0),
      ),
    );
    logEvent('accessory_dropped', {
      'source': source,
      'accessory': rolled.id,
      'rarity': rolled.rarity.name,
      'isNew': isNew,
    });
    return lastAccessoryDrop = AccessoryDrop(rolled, isNew: isNew);
  }

  /// Ghi 1 sự kiện analytics (best-effort, không bao giờ ném). Public để Chợ
  /// (controller riêng) dùng chung cùng đường ghi.
  void logEvent(String event, [Map<String, dynamic> props = const {}]) =>
      unawaited(_analytics?.log(event, props));

  @visibleForTesting
  set debugAnalytics(AnalyticsRepository? repo) => _analyticsRepo = repo;

  int claimDailyBonus() {
    final gems = claimDailyQuestBonus(_game);
    if (gems > 0) {
      _dropAccessory(source: 'daily_quest');
      unawaited(saveNow());
      state = _snapshot();
    }
    return gems;
  }

  /// Chợ Phụ kiện: bớt 1 món khỏi kho local NGAY sau khi đăng bán thành công
  /// trên server (xem AccessoryMarketController.listItem). Lưu ngay (không
  /// đợi tick nền) để giảm cửa sổ "hồi sinh" món đã bán qua đồng bộ đa máy
  /// — xem PROPOSAL_ACCESSORY_MARKET.md §5.
  void removeOwnedAccessoryLocally(String accessoryId) {
    final spare = _game.accessorySpares[accessoryId] ?? 0;
    if (spare > 1) {
      _game.accessorySpares[accessoryId] = spare - 1;
    } else if (spare == 1) {
      _game.accessorySpares.remove(accessoryId);
    } else if (!_game.ownedAccessories.remove(accessoryId)) {
      return;
    } else {
      // Bán nốt bản cuối → không còn món để trưng bày.
      _game.equippedAccessories.remove(accessoryId);
    }
    unawaited(saveNow());
    state = _snapshot();
  }

  /// Bật/tắt trưng bày [accessoryId] quanh cốc. Chỉ trưng bày món ĐANG CÓ, tối đa
  /// [Balance.maxEquippedAccessories]. Trả về false nếu không đổi được (chưa có món,
  /// hoặc đã đủ chỗ khi định thêm).
  bool toggleEquippedAccessory(String accessoryId) {
    final equipped = _game.equippedAccessories;
    if (equipped.remove(accessoryId)) {
      // đã bỏ
    } else if (_game.ownedAccessories.contains(accessoryId) &&
        equipped.length < Balance.maxEquippedAccessories) {
      equipped.add(accessoryId);
    } else {
      return false;
    }
    unawaited(saveNow());
    state = _snapshot();
    return true;
  }

  /// Chợ Phụ kiện: thêm 1 món vào kho local sau khi mua hoặc huỷ đăng thành
  /// công trên server (xem AccessoryMarketController.buyItem/cancelItem).
  void addOwnedAccessoryLocally(String accessoryId) {
    if (_game.ownedAccessories.contains(accessoryId)) {
      _game.accessorySpares[accessoryId] =
          (_game.accessorySpares[accessoryId] ?? 0) + 1;
    } else {
      _game.ownedAccessories.add(accessoryId);
    }
    unawaited(saveNow());
    state = _snapshot();
  }

  /// Chạm ly → +tiền (nhân boost Mưa vàng nếu đang có). Trả về số Xu vừa nhận
  /// để UI hiện hiệu ứng "+X" bay lên.
  double tapCup() {
    _game.tapCount++;
    addDailyProgress(_game, DailyQuestKind.tap, 1);
    final gained =
        tap(_game,
            boostMultiplier:
                _boostMultiplier() * _rivalModifier() * _eventMultiplier());
    state = _snapshot();
    return gained;
  }

  /// Nâng cấp một nguồn thu. Trả về true nếu đủ tiền và mua thành công.
  bool buy(String generatorId) {
    final ok = buyUpgrade(_game, generatorId);
    if (ok) {
      _addBuys(1);
      _awardAchievements();
      state = _snapshot();
    }
    return ok;
  }

  /// Mua liền [count] cấp (nút "×10"). Trả về số cấp thực mua (0 nếu thiếu tiền).
  int buyBulk(String generatorId, int count) {
    final bought = buyUpgradeBulk(_game, generatorId, count);
    if (bought > 0) {
      _addBuys(bought);
      _awardAchievements();
      state = _snapshot();
    }
    return bought;
  }

  /// Mua tối đa số cấp có thể (nút "MAX"). Trả về số cấp thực mua.
  int buyMax(String generatorId) {
    final config = Balance.generators.firstWhere((c) => c.id == generatorId);
    final count = maxAffordableLevels(
      config,
      _game.levels[generatorId] ?? 0,
      _game.money,
      upgradeCostMultiplier(_game.prestigeDiscountLevel),
    );
    return buyBulk(generatorId, count);
  }

  /// Nhận thưởng nhiệm vụ hiện tại (nếu đã đạt) và sang nhiệm vụ kế. Trả về gems
  /// nhận (0 nếu chưa đạt). Lưu ngay vì gems premium.
  int claimCurrentQuest() {
    final gems = claimQuest(_game);
    if (gems > 0) {
      unawaited(saveNow());
      state = _snapshot();
    }
    return gems;
  }

  /// Mở khóa giai đoạn kế tiếp bằng tiền. Trả về true nếu thành công.
  bool unlockStage() {
    final ok = unlockNextStage(_game);
    if (ok) {
      _awardAchievements();
      unawaited(saveNow());
      unawaited(_analytics?.log('stage_reached', {'stage': _game.stage}));
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

  /// "Mở giai đoạn tức thì" bằng 💎. Trả về true nếu thành công.
  bool buyInstantStage() {
    final ok = buyInstantStageUnlock(_game);
    if (ok) {
      _awardAchievements();
      unawaited(saveNow());
      state = _snapshot();
    }
    return ok;
  }

  /// "Tua nhanh" bằng 💎. Trả về số Xu vừa cộng (0 nếu thiếu 💎 / chưa có thu nhập).
  double buyGemTimeSkipReward() {
    final reward = buyGemTimeSkip(_game, _clock());
    if (reward > 0) {
      unawaited(saveNow());
      state = _snapshot();
    }
    return reward;
  }

  /// Nhận thưởng đăng nhập hằng ngày. Trả về (gems nhận, streak mới); gems=0
  /// nếu chưa tới ngày mới. Lưu ngay vì gems là premium.
  ({int gems, int streak}) claimDailyReward() {
    final gems = claimDaily(_game, _clock());
    if (gems > 0) {
      unawaited(saveNow());
      state = _snapshot();
    }
    return (gems: gems, streak: _game.dailyStreak);
  }

  /// Nâng perk "Siêu thu nhập" bằng ⭐ Sao. Lưu ngay (premium). True nếu mua được.
  bool buyPrestigeIncomeUpgrade() {
    final ok = buyPrestigeIncome(_game);
    if (ok) {
      unawaited(saveNow());
      state = _snapshot();
    }
    return ok;
  }

  /// Nâng perk "Siêu chạm" bằng ⭐ Sao. Lưu ngay (premium). True nếu mua được.
  bool buyPrestigeTapUpgrade() {
    final ok = buyPrestigeTap(_game);
    if (ok) {
      unawaited(saveNow());
      state = _snapshot();
    }
    return ok;
  }

  /// Nâng perk "Siêu offline" bằng ⭐ Sao. True nếu mua được.
  bool buyPrestigeOfflineUpgrade() => _buyPerk(() => buyPrestigeOffline(_game));

  /// Nâng perk "Vốn khởi nghiệp" bằng ⭐ Sao. True nếu mua được.
  bool buyPrestigeStartCashUpgrade() =>
      _buyPerk(() => buyPrestigeStartCash(_game));

  /// Nâng perk "Giữ giai đoạn" bằng ⭐ Sao. True nếu mua được.
  bool buyPrestigeKeepStageUpgrade() =>
      _buyPerk(() => buyPrestigeKeepStage(_game));

  /// Nâng perk "Mua sỉ" bằng ⭐ Sao. True nếu mua được.
  bool buyPrestigeDiscountUpgrade() => _buyPerk(() => buyPrestigeDiscount(_game));

  /// Mở khoá perk "Tự động mua" bằng ⭐ Sao. True nếu mua được.
  bool buyPrestigeAutoBuyUpgrade() => _buyPerk(() => buyPrestigeAutoBuy(_game));

  /// Bật/tắt công tắc auto-buy (chỉ có tác dụng khi có perk). Lưu ngay.
  void setAutoBuy(bool on) {
    if (_game.autoBuyEnabled == on) return;
    _game.autoBuyEnabled = on;
    unawaited(saveNow());
    state = _snapshot();
  }

  bool _buyPerk(bool Function() action) {
    final ok = action();
    if (ok) {
      unawaited(saveNow());
      state = _snapshot();
    }
    return ok;
  }

  /// Nhượng quyền. Trả về số Sao vừa nhận (0 nếu chưa đủ).
  double doPrestige() {
    final gained = prestige(_game);
    if (gained > 0) {
      _awardAchievements();
      unawaited(saveNow());
      unawaited(_analytics?.log('prestige', {
        'starsGained': gained,
        'totalStars': _game.prestigeStars,
      }));
      state = _snapshot();
    }
    return gained;
  }

  /// Kỷ Nguyên hoá (prestige tầng 2). Trả về số Điểm vừa nhận (0 nếu chưa đủ
  /// điều kiện — không đổi gì). Lưu NGAY: đây là reset lớn, kill app giữa
  /// chừng mà không lưu thì mất cả Điểm lẫn tiến độ.
  int doAscend() {
    final gained = ascend(_game);
    if (gained > 0) {
      _dropAccessory(
        source: 'ascension',
        rarity: _random.nextDouble() < Balance.ascensionLegendaryChance
            ? AccessoryRarity.legendary
            : AccessoryRarity.epic,
      );
      _awardAchievements();
      unawaited(saveNow());
      unawaited(_analytics?.log('ascend', {
        'pointsGained': gained,
        'ascensionCount': _game.ascensionCount,
      }));
      state = _snapshot();
    }
    return gained;
  }

  bool buyAscensionIncomeUpgrade() => _buyPerk(() => buyAscensionIncome(_game));
  bool buyAscensionStarBonusUpgrade() =>
      _buyPerk(() => buyAscensionStarBonus(_game));
  bool buyAscensionStarGainUpgrade() =>
      _buyPerk(() => buyAscensionStarGain(_game));

  /// UI gọi khi app chuyển nền (AppLifecycleState.paused/hidden), CẠNH
  /// saveNow() chứ không thay — ghi thời lượng session vừa chơi. Reset mốc
  /// bắt đầu ngay để lần resume sau tính đúng (app không tự tạo phiên mới
  /// qua build() nếu chỉ resume, không kill hẳn).
  void endSession() {
    final seconds = (_clock() - _sessionStartMillis) / 1000;
    if (seconds > 0) {
      unawaited(_analytics?.log('session_end', {'seconds': seconds}));
    }
    _sessionStartMillis = _clock();
  }

  /// Lưu ngay — UI gọi khi app chuyển nền (AppLifecycleState.paused). Đẩy
  /// kèm lên cloud (no-op nếu chưa liên kết email, hoặc nếu Supabase chưa
  /// init — VD chạy test không qua `main()` — xem [_cloudSave]).
  Future<void> saveNow() async {
    await _storage.save(_game, nowMillis: _clock());
    final cloud = _cloudSave;
    if (cloud != null) unawaited(_syncCloud(cloud));
  }

  /// Đẩy save lên cloud CÓ ĐIỀU KIỆN (xem
  /// CloudSaveRepository.pushIfCurrent) — KHÔNG ghi đè mù như trước đây.
  /// Nếu version cloud đã đổi (máy khác vừa lưu sau lần đồng bộ gần nhất
  /// của máy này), đánh dấu [_cloudConflictPending] thay vì âm thầm ghi đè
  /// — dialog Đồng bộ đám mây tự phát hiện cờ này và hỏi lại người chơi
  /// (khôi phục / giữ máy này) ở lần mở kế tiếp, tái dùng đúng luồng xung
  /// đột đã có lúc liên kết lần đầu. Xem known-issues-backlog memory mục 7.
  Future<void> _syncCloud(CloudSaveRepository cloud) async {
    if (!cloud.isLinked) return;
    try {
      final newVersion = await cloud.pushIfCurrent(_game.toJson(), _cloudVersion);
      if (newVersion != null) {
        applyCloudSyncVersion(newVersion);
      } else if (!_cloudConflictPending) {
        _cloudConflictPending = true;
        unawaited(_storage.saveCloudConflictPending(true));
      }
    } catch (_) {
      // Lỗi mạng — bỏ qua, saveNow() lần kế tiếp tự thử lại.
    }
  }

  /// Ghi nhận mốc đồng bộ cloud mới (sau push/pull thành công) + xoá cờ
  /// xung đột nếu có. Gọi từ [_syncCloud] và từ CloudSaveController (qua
  /// `onSyncVersionKnown`/`onRestore`) sau khi người chơi giải quyết xung
  /// đột (khôi phục hoặc giữ máy này) hoặc sau lần liên kết đầu tiên.
  void applyCloudSyncVersion(int version) {
    _cloudVersion = version;
    _cloudConflictPending = false;
    unawaited(_storage.saveCloudVersion(version));
    unawaited(_storage.saveCloudConflictPending(false));
  }

  /// true nếu lần lưu nền gần nhất phát hiện xung đột chưa xử lý — dialog
  /// Đồng bộ đám mây đọc qua đây để tự hỏi lại khi mở.
  bool get cloudConflictPending => _cloudConflictPending;

  /// Lazy + tự bắt lỗi: `Supabase.instance` ném assert nếu chưa gọi
  /// `Supabase.initialize()` (luôn đúng trong test, vì test dựng
  /// GameController thẳng qua ProviderScope, không qua `main()`). Đồng bộ
  /// cloud là tiện ích cộng thêm — KHÔNG được phép làm hỏng save local hay
  /// làm crash bất kỳ chỗ nào gọi saveNow() nếu Supabase có vấn đề.
  CloudSaveRepository? get _cloudSave {
    if (_cloudSaveRepo != null) return _cloudSaveRepo;
    try {
      return _cloudSaveRepo = CloudSaveRepository(Supabase.instance.client);
    } catch (_) {
      return null;
    }
  }

  /// Cùng nguyên tắc lazy + tự bắt lỗi như [_cloudSave] — analytics KHÔNG
  /// BAO GIỜ được phép ảnh hưởng gameplay (xem AnalyticsRepository).
  AnalyticsRepository? get _analytics {
    if (_analyticsRepo != null) return _analyticsRepo;
    try {
      return _analyticsRepo = AnalyticsRepository(
        Supabase.instance.client,
        ref.read(sharedPreferencesProvider),
      );
    } catch (_) {
      return null;
    }
  }

  /// Cùng nguyên tắc lazy + tự bắt lỗi như [_cloudSave] — ghi nhận rớt phụ
  /// kiện lên server KHÔNG BAO GIỜ được phép chặn/làm hỏng việc nhận thưởng
  /// nhiệm vụ ngày cục bộ nếu Supabase có vấn đề (xem [claimDailyBonus]).
  @visibleForTesting
  set debugMarketRepo(AccessoryMarketRepository? repo) => _marketRepo = repo;

  AccessoryMarketRepository? get _market {
    if (_marketRepo != null) return _marketRepo;
    try {
      return _marketRepo = AccessoryMarketRepository(Supabase.instance.client);
    } catch (_) {
      return null;
    }
  }

  /// Ghi nhận món vừa rớt lên server (accessory_server_ownership) — cho
  /// phép đăng bán sau này trên Chợ Phụ kiện (xem PROPOSAL_ACCESSORY_MARKET.md
  /// §0, lý do cần RPC này: list_accessory phải verify sở hữu server-side,
  /// không tin suông lời client). Lỗi mạng ở đây KHÔNG được chặn việc nhận
  /// thưởng cục bộ — [AccessoryMarketController.reconcileOwnership] sẽ bù
  /// lại lúc mở Chợ nếu lần này lỡ mất.
  Future<void> _registerAccessoryDropServerSide(
    String accessoryId,
    int copies,
  ) async {
    try {
      await _market?.registerDrop(accessoryId, copies: copies);
    } catch (e) {
      developer.log('đăng ký sở hữu phụ kiện lỗi, sẽ bù lúc mở Chợ: $e',
          name: 'Market');
    }
  }

  /// Thêm/bỏ [accessoryId] khỏi danh sách muốn có. Trả danh sách mới, hoặc null
  /// nếu đầy ([Balance.maxWishlist]) khi đang thêm.
  List<String>? toggleWishlist(String accessoryId) {
    final list = _game.wishlist;
    if (!list.remove(accessoryId)) {
      if (list.length >= Balance.maxWishlist) return null;
      list.add(accessoryId);
    }
    unawaited(saveNow());
    state = _snapshot();
    return List.of(list);
  }

  void _markMilestoneClaimed(int count) {
    if (!_game.collectionMilestonesClaimed.contains(count)) {
      _game.collectionMilestonesClaimed.add(count);
    }
    unawaited(saveNow());
    state = _snapshot();
  }

  /// Nhận thưởng mốc sưu tập [count] (server trước, đánh dấu cục bộ sau). Trả
  /// số Xu Chợ nhận được, hoặc mã lỗi (`not_reached`, `already_claimed`,
  /// `network`) — `already_claimed` cũng đánh dấu cục bộ để ẩn nút.
  Future<({int? coins, String? error})> claimCollectionMilestone(
      int count) async {
    final market = _market;
    final m = collectionMilestones.where((m) => m.count == count).firstOrNull;
    if (market == null ||
        m == null ||
        !milestoneReached(_game, m) ||
        milestoneClaimed(_game, m)) {
      return (coins: null, error: 'not_reached');
    }
    try {
      // Server tự đếm món — bù những món local có mà server chưa biết (cùng
      // việc đối chiếu lúc mở Chợ) để không bị 'not_reached' oan.
      final server = await market.fetchServerCopies();
      for (final id in _game.ownedAccessories.toList()) {
        if (!server.containsKey(id)) {
          await market.registerDrop(id,
              copies: 1 + (_game.accessorySpares[id] ?? 0));
        }
      }
      final coins = await market.claimCollectionMilestone(count);
      logEvent('collection_milestone', {'milestone': count, 'coins': coins});
      _markMilestoneClaimed(count);
      return (coins: coins, error: null);
    } catch (e) {
      final msg = '$e';
      if (msg.contains('already_claimed')) {
        _markMilestoneClaimed(count);
        return (coins: null, error: 'already_claimed');
      }
      developer.log('nhận mốc sưu tập lỗi: $e', name: 'Market');
      return (
        coins: null,
        error: msg.contains('not_reached') ? 'not_reached' : 'network'
      );
    }
  }

  /// Nhận Gói Khởi Nghiệp Chợ: server trước, cấp cục bộ sau (cùng nguyên tắc
  /// [convertGemsToMarketCoins]). Trả null nếu xong, hoặc mã lỗi server
  /// (`already_claimed`, `not_eligible`, `daily_cap`, `network`).
  Future<String?> claimMarketStarter() async {
    final market = _market;
    if (market == null || !market_starter.starterPackEligible(_game)) {
      return 'not_eligible';
    }
    final item = market_starter.starterPackAccessory(_game);
    try {
      await market.claimStarterPack(item.id, _game.stage);
    } catch (e) {
      final msg = '$e';
      if (msg.contains('already_claimed')) {
        _game.starterPackClaimed = true; // server đã ghi nhận — thôi hiện thẻ
        unawaited(saveNow());
        state = _snapshot();
        return 'already_claimed';
      }
      developer.log('nhận Gói Khởi Nghiệp lỗi: $e', name: 'Market');
      return msg.contains('daily_cap')
          ? 'daily_cap'
          : msg.contains('not_eligible')
              ? 'not_eligible'
              : 'network';
    }
    market_starter.grantMarketStarter(_game, item);
    logEvent('starter_pack_claimed', {'accessory': item.id});
    unawaited(saveNow());
    state = _snapshot();
    return null;
  }

  /// Đổi 💎 lấy Xu Chợ — MỘT CHIỀU (xem Balance.marketCoinsPerGem). Gọi RPC
  /// trước, chỉ trừ 💎 cục bộ nếu RPC thành công — tránh mất 💎 oan nếu lỗi
  /// mạng giữa chừng. Trả false nếu không đủ 💎 hoặc RPC lỗi.
  Future<bool> convertGemsToMarketCoins(int marketCoinsWanted) async {
    if (marketCoinsWanted <= 0) return false;
    final cost = marketCoinsWanted / Balance.marketCoinsPerGem;
    if (!(_game.gems >= cost)) return false;
    final market = _market;
    if (market == null) return false;
    try {
      await market.creditMarketCoins(marketCoinsWanted);
    } catch (e) {
      developer.log('đổi 💎 lấy Xu Chợ lỗi mạng, chưa trừ gì cục bộ: $e',
          name: 'Market');
      return false;
    }
    _game.gems -= cost;
    unawaited(saveNow());
    state = _snapshot();
    return true;
  }

  /// Đổi Xu lấy Xu Chợ theo giây-thu-nhập HIỆN TẠI (xem
  /// Balance.marketCoinsIncomeSeconds) — không dùng tỉ giá Xu cố định vì Xu
  /// co giãn nhiều bậc suốt game. Cùng nguyên tắc server-trước-trừ-sau như
  /// convertGemsToMarketCoins.
  Future<bool> convertMoneyToMarketCoins(int marketCoinsWanted) async {
    if (marketCoinsWanted <= 0) return false;
    final income = effectiveIncomePerSecond(_game, Balance.generators,
        bonusPerStar: Balance.bonusPerStar);
    if (!income.isFinite || income <= 0) return false;
    final cost = marketCoinsWanted * Balance.marketCoinsIncomeSeconds * income;
    // `!(x >= y)` thay vì `x < y` để NaN cũng bị từ chối.
    if (!cost.isFinite || cost <= 0 || !(_game.money >= cost)) return false;
    final market = _market;
    if (market == null) return false;
    try {
      await market.creditMarketCoins(marketCoinsWanted);
    } catch (e) {
      developer.log('đổi Xu lấy Xu Chợ lỗi mạng, chưa trừ gì cục bộ: $e',
          name: 'Market');
      return false;
    }
    _game.money -= cost;
    unawaited(saveNow());
    state = _snapshot();
    return true;
  }

  /// Xuất save hiện tại dạng JSON — dùng cho Đồng bộ đám mây (đẩy save máy
  /// này lên cloud lần đầu liên kết / khi chọn "Giữ máy này" lúc xung đột).
  Map<String, dynamic> exportSaveJson() => _game.toJson();

  /// Ghi đè toàn bộ ván hiện tại bằng save khôi phục từ cloud (người chơi
  /// chọn "Khôi phục" ở dialog Đồng bộ đám mây khi phát hiện save khác trên
  /// cloud). Lưu local ngay để không mất nếu app bị tắt giữa chừng.
  void restoreFromCloud(Map<String, dynamic> json, {required int cloudVersion}) {
    final GameState restored;
    try {
      restored = GameState.fromJson(json);
    } catch (e) {
      // Payload cloud hỏng/không khớp schema (máy khác version) — bỏ qua,
      // giữ nguyên save hiện tại thay vì crash (cùng nguyên tắc như
      // game_storage.dart khi load local hỏng).
      debugPrint('restoreFromCloud: payload hỏng, bỏ qua: $e');
      return;
    }
    _game = restored..lastSeenMillis = _clock();
    sanitizeRepeatQuest(_game);
    applyCloudSyncVersion(cloudVersion);
    unawaited(saveNow());
    state = _snapshot();
  }

  /// UI gọi khi app trở lại foreground: bù tiền cho khoảng vừa ở nền.
  void handleResume() {
    _rollDaily();
    _offlineEarned = applyOfflineEarnings(
      _game,
      _clock(),
      maxOfflineSeconds: _offlineCap(),
    );
    claimVipDailyGems(_game, _clock());
    state = _snapshot();
  }

  /// UI gọi sau khi đã hiện popup tiền offline.
  void acknowledgeOffline() {
    if (_offlineEarned == 0) return;
    _offlineEarned = 0;
    state = _snapshot();
  }

  /// Trao mọi thành tựu vừa đạt (nếu có) và xếp hàng cho UI báo. Gọi ở các điểm
  /// state đổi (mua, mở giai đoạn, prestige, tick). KHÔNG tự phát snapshot —
  /// người gọi phát ngay sau đó.
  void _awardAchievements() {
    final newly = grantNewAchievements(_game);
    if (newly.isNotEmpty) {
      _newAchievements = [..._newAchievements, ...newly];
      unawaited(saveNow());
    }
  }

  /// UI gọi sau khi đã hiển thị thông báo mở khoá thành tựu.
  void acknowledgeAchievements() {
    if (_newAchievements.isEmpty) return;
    _newAchievements = const [];
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

  /// Bật "x2 thu nhập 24h" (sau khi xem QC). Cộng dồn thời gian nếu đang có.
  void activateX2Income() {
    final now = _clock();
    final from =
        now > _game.x2IncomeUntilMillis ? now : _game.x2IncomeUntilMillis;
    _game.x2IncomeUntilMillis = from + Balance.rewardedX2DurationMs;
    unawaited(saveNow());
    state = _snapshot();
  }

  /// Tua nhanh (xem QC): thưởng [Balance.rewardedTimeSkipSeconds] giây sản xuất
  /// theo nhịp cơ bản. Trả về số Xu thưởng (0 nếu chưa có thu nhập).
  double claimTimeSkip() {
    final reward = effectiveIncomePerSecond(
          _game,
          Balance.generators,
          bonusPerStar: Balance.bonusPerStar,
        ) *
        Balance.rewardedTimeSkipSeconds;
    if (reward <= 0) return 0;
    grantBonus(_game, reward);
    state = _snapshot();
    return reward;
  }

  /// Quay Vòng quay may mắn. [free]=true đánh dấu đã dùng lượt free hôm nay. Trả
  /// về (chỉ số ô trúng, loại thưởng, giá trị đã nhận) để UI quay + báo.
  ({int index, WheelKind kind, double value, AccessoryDrop? drop}) spin(
      {required bool free}) {
    final i = spinWheel(_random.nextDouble());
    final p = wheelPrizes[i];
    addDailyProgress(_game, DailyQuestKind.spin, 1);
    double value = 0;
    AccessoryDrop? drop;
    switch (p.kind) {
      case WheelKind.chest:
        drop = _dropAccessory(source: 'wheel');
        value = drop.isNew ? 1 : 0;
      case WheelKind.coins:
        value = effectiveIncomePerSecond(
              _game,
              Balance.generators,
              bonusPerStar: Balance.bonusPerStar,
            ) *
            p.amount;
        grantBonus(_game, value);
      case WheelKind.gems:
        value = p.amount.toDouble();
        grantGems(_game, value);
      case WheelKind.x2:
        final now = _clock();
        final from =
            now > _game.x2IncomeUntilMillis ? now : _game.x2IncomeUntilMillis;
        _game.x2IncomeUntilMillis = from + Balance.rewardedX2DurationMs;
        value = Balance.rewardedX2DurationMs / 3600000; // giờ
    }
    if (free) _game.lastFreeSpinDay = dayIndex(_clock());
    unawaited(saveNow());
    state = _snapshot();
    return (index: i, kind: p.kind, value: value, drop: drop);
  }

  /// Nhập mã quà tặng (VD mã bù đắp sự cố) — xem `core/redeem.dart`. Lưu ngay
  /// nếu thành công (gems là premium).
  ({RedeemStatus status, double gems}) redeemCode(String code) {
    final result = applyRedeemCode(_game, code, _clock());
    if (result.status == RedeemStatus.success) {
      unawaited(saveNow());
      state = _snapshot();
    }
    return result;
  }

  /// Nhận Kim Cương miễn phí (sau khi xem QC). Lưu ngay vì gems là premium.
  void grantFreeGems() {
    grantGems(_game, Balance.rewardedFreeGems.toDouble());
    unawaited(saveNow());
    state = _snapshot();
  }

  /// Bật "x2 thu nhập vĩnh viễn" (IAP). Idempotent — restore nhiều lần vẫn đúng.
  void applyDoubleIncome() {
    if (_game.doubleIncomeOwned) return;
    _game.doubleIncomeOwned = true;
    unawaited(saveNow());
    state = _snapshot();
  }

  /// Kích hoạt/gia hạn VIP Pass 30 ngày (IAP). Nhận luôn Kim Cương VIP hôm nay.
  void buyVip() {
    activateVip(_game, _clock());
    claimVipDailyGems(_game, _clock());
    unawaited(saveNow());
    state = _snapshot();
  }

  /// "Đập heo đất" (IAP): trao toàn bộ Kim Cương đã tích rồi reset heo. Trả về
  /// số gems trao (0 nếu heo rỗng). Lưu ngay vì gems premium.
  double breakPiggy() {
    final gained = _game.piggyGems;
    if (gained <= 0) return 0;
    grantGems(_game, gained);
    _game.piggyGems = 0;
    unawaited(saveNow());
    state = _snapshot();
    return gained;
  }

  /// Trao Kim Cương mua bằng tiền thật (IAP consumable). Lưu ngay vì premium.
  void grantGemsPurchase(double amount) {
    grantGems(_game, amount);
    unawaited(saveNow());
    state = _snapshot();
  }

  /// Trao Kim Cương thưởng sau trận Đấu Trường (thắng/thua) — xem
  /// `lib/arena/arena_controller.dart`. Module Đấu Trường không đụng trực
  /// tiếp vào `GameState`, chỉ gọi qua đây, giống đường quest/IAP/ads.
  void grantArenaReward(int gems) {
    grantGems(_game, gems.toDouble());
    unawaited(saveNow());
    state = _snapshot();
  }

  /// Đánh dấu đã xem hướng dẫn Trân Châu Rơi (để lần sau không tự hiện nữa).
  void markM3HowToSeen() {
    if (_game.m3HowToSeen) return;
    setM3HowToSeen(_game);
    unawaited(saveNow());
    state = _snapshot();
  }

  /// Ghi kết quả một màn Ghép 3 (chơi đơn) và trao thưởng. Trả về (Xu, 💎) vừa
  /// nhận — 0 nếu không phá được kỷ lục sao cũ của màn đó.
  (double, int) grantMatch3Result(int levelId, int stars) {
    final firstClear = stars > 0 &&
        (levelId > _game.m3Stars.length || _game.m3Stars[levelId - 1] == 0);
    lastAccessoryDrop = null;
    final reward = applyMatch3Result(
      _game,
      levelId,
      stars,
      incomePerSecond: state.incomePerSecond,
    );
    final milestone = Balance.m3AccessoryMilestones[levelId];
    if (firstClear && milestone != null) {
      _dropAccessory(source: 'match3', rarity: milestone);
    }
    // LUÔN lưu + phát snapshot mới khi màn có sao: `applyMatch3Result` ghi
    // `m3Stars` kể cả lúc thưởng bằng 0, và chính bản ghi đó mới là thứ mở khoá
    // màn sau. Chỉ lưu khi có thưởng thì người chơi mới (thu nhập/giây = 0) qua
    // màn 1 mà màn 2 vẫn khoá, mở lại app là mất sạch tiến độ.
    if (stars > 0) {
      unawaited(saveNow());
      state = _snapshot();
    }
    return reward;
  }

  /// Trao Kim Cương thưởng giữ hạng cao trên Bảng xếp hạng — xem
  /// `lib/leaderboard/leaderboard_controller.dart`. Cùng nguyên tắc với
  /// [grantArenaReward]: module Bảng xếp hạng không đụng trực tiếp
  /// GameState, chỉ gọi qua đây.
  void grantLeaderboardReward(int gems) {
    grantGems(_game, gems.toDouble());
    unawaited(saveNow());
    state = _snapshot();
  }

  /// Bật "Gỡ quảng cáo" (IAP). Idempotent — an toàn khi khôi phục nhiều lần.
  void applyRemoveAds() {
    setAdsRemoved(_game);
    unawaited(saveNow());
    state = _snapshot();
  }

  /// Trao "Gói khởi động" đúng một lần (chống trùng khi restore). Trả về true
  /// nếu vừa trao (để UI báo), false nếu đã sở hữu.
  bool applyStarterPack() {
    final granted = claimStarterPack(_game, Balance.iapStarterGems);
    if (granted) {
      unawaited(saveNow());
      state = _snapshot();
    }
    return granted;
  }

  /// Đánh dấu đã xem hướng dẫn "Cách chơi". Lưu ngay để lần sau không tự hiện.
  void markTutorialSeen() {
    if (_game.tutorialSeen) return;
    setTutorialSeen(_game);
    unawaited(saveNow());
    state = _snapshot();
  }

  /// Xóa save và bắt đầu ván mới (nút chơi lại / debug).
  Future<void> resetGame() async {
    await _storage.clear();
    _game = GameState.newGame(nowMillis: _clock());
    _ticksSinceSave = 0;
    state = _snapshot();
  }

  void _onTick() {
    _rollDaily();
    final now = _clock();
    final dt = (now - _game.lastSeenMillis) / 1000.0;
    if (dt > 0) {
      tick(_game, dt,
          boostMultiplier:
              _boostMultiplier() * _rivalModifier() * _eventMultiplier());
      fillPiggy(_game, dt); // heo đất tích theo thời gian chơi
      // Sự kiện đối thủ đang chờ trả lời → đối thủ "lấn tới" (nhỏ, tạo cảm giác gấp).
      if (_rivalEventPending != null && rivalActive(_game)) {
        _game.rivalPressureSeconds +=
            dt * Balance.rivalPendingPressurePerSecond;
      }
      // Giữ mốc "đã tính tiền tới đây" luôn cập nhật trong lúc chơi, để lần
      // tính offline kế tiếp không đếm trùng thời gian online.
      _game.lastSeenMillis = now;
    }
    _addBuys(autoBuyBest(_game)); // perk "Tự động mua" (no-op nếu tắt)
    _updateCat(now);
    _updateVip(now);
    _updateRival(now);
    _awardAchievements(); // bắt các mốc lifetimeEarnings tăng theo thời gian
    if (++_ticksSinceSave >= autoSaveEveryTicks) {
      _ticksSinceSave = 0;
      unawaited(saveNow());
    }
    state = _snapshot();
  }

  /// Tiến độ tới ngưỡng Kỷ Nguyên theo THANG LOG (0..1): lifetime tăng theo cấp
  /// số nhân nên thang tuyến tính gần như luôn hiển thị 0% rồi nhảy vọt.
  double _ascensionProgress() {
    final since = lifetimeSinceAscension(_game);
    if (since <= 1) return 0;
    return (log(since) / log(Balance.ascensionMinLifetime)).clamp(0.0, 1.0);
  }

  GameSnapshot _snapshot() {
    // Tính một lần các giá trị dùng nhiều lần trong snapshot (chạy mỗi giây).
    final now = _clock();
    final qp = currentQuestProgress(_game);
    final vip = vipActive(_game, now);
    final remainingMs = _game.boostUntilMillis - now;
    return GameSnapshot(
      money: _game.money,
      gems: _game.gems,
      incomePerSecond: effectiveIncomePerSecond(
        _game,
        Balance.generators,
        bonusPerStar: Balance.bonusPerStar,
        boostMultiplier:
            _boostMultiplier() * _rivalModifier() * _eventMultiplier(),
      ),
      prestigeStars: _game.prestigeStars,
      prestigeStarsAvailable: prestigeStarsAvailable(_game),
      offlineEarned: _offlineEarned,
      catVisible: _catVisible,
      boostRemainingSeconds: remainingMs > 0 ? remainingMs / 1000.0 : 0,
      vipVisible: _vipVisible,
      eventActive: eventActive,
      eventRemainingSeconds: eventRemainingSeconds,
      eventMultiplier: _eventMultiplier(),
      gemBoostLevel: _game.gemBoostLevel,
      offlineCapLevel: _game.offlineCapLevel,
      stage: _game.stage,
      adsRemoved: _game.adsRemoved,
      // Bản sao: dùng chung instance thì `.select((s) => s.m3Stars)` so sánh
      // ra "y nguyên" (cùng object) và UI không bao giờ rebuild.
      m3Stars: List.unmodifiable(_game.m3Stars),
      // Bản sao — cùng lý do m3Stars ở trên (xem snapshot-list-aliasing-select
      // memory: chia sẻ instance List làm `.select()` không rebuild).
      ownedAccessories: List.unmodifiable(_game.ownedAccessories),
      accessorySpares: Map.unmodifiable(_game.accessorySpares),
      equippedAccessories: List.unmodifiable(_game.equippedAccessories),
      collectionMilestonesClaimed:
          List.unmodifiable(_game.collectionMilestonesClaimed),
      wishlist: List.unmodifiable(_game.wishlist),
      m3HowToSeen: _game.m3HowToSeen,
      starterPackOwned: _game.starterPackOwned,
      tutorialSeen: _game.tutorialSeen,
      dailyAvailable: dailyAvailable(_game, now),
      newAchievements: _newAchievements,
      lifetimeEarnings: _game.lifetimeEarnings,
      achievementsClaimed: _game.achievementsClaimed,
      prestigeStarsSpendable: prestigeStarsSpendable(_game),
      prestigeIncomeLevel: _game.prestigeIncomeLevel,
      prestigeTapLevel: _game.prestigeTapLevel,
      prestigeOfflineLevel: _game.prestigeOfflineLevel,
      prestigeStartCashLevel: _game.prestigeStartCashLevel,
      prestigeKeepStageLevel: _game.prestigeKeepStageLevel,
      prestigeDiscountLevel: _game.prestigeDiscountLevel,
      upgradeCostMult: upgradeCostMultiplier(_game.prestigeDiscountLevel),
      globalMilestoneMult: globalMilestoneMultiplier(_game),
      currentQuest: currentQuest(_game),
      questProgress: qp,
      questDone: currentQuestDone(_game),
      prestigeAutoBuyLevel: _game.prestigeAutoBuyLevel,
      autoBuyEnabled: _game.autoBuyEnabled,
      doubleIncomeOwned: _game.doubleIncomeOwned,
      x2IncomeRemainingSeconds:
          max(0, (_game.x2IncomeUntilMillis - now) / 1000.0),
      piggyGems: _game.piggyGems,
      adFree: _game.adsRemoved || vip,
      vipActive: vip,
      vipRemainingSeconds: max(0, (_game.vipUntilMillis - now) / 1000.0),
      freeSpinAvailable: dayIndex(now) > _game.lastFreeSpinDay,
      gemTimeSkipRemainingToday: gemTimeSkipRemainingToday(_game, now),
      storyChapter: _game.storyChapter,
      pendingStoryChapterId: pendingChapterId(_game),
      storyChoiceA: _game.storyChoiceA,
      storyChoiceB: _game.storyChoiceB,
      storyCompleteSeconds: _game.storyCompleteSeconds,
      storyExtCompleteSeconds: _game.storyExtCompleteSeconds,
      storyThirdActCompleteSeconds: _game.storyThirdActCompleteSeconds,
      rivalActive: rivalActive(_game),
      rivalDefeated: _game.rivalDefeated,
      rivalStanding: rivalStanding(_game),
      rivalPowerRatio: rivalPowerRatio(_game),
      pendingRivalEvent: _rivalEventPending,
      rivalModifierRemainingSeconds:
          max(0, (_rivalModUntilMillis - now) / 1000.0),
      rivalModifierMult: _rivalModifier(),
      dailyQuests: [
        for (final q in currentDailyQuests(_game))
          DailyQuestView(
            kind: q.kind,
            target: q.target,
            progress: dailyQuestProgress(_game, q.kind),
            rewardGems: q.rewardGems,
            claimed: dailyQuestClaimed(_game, q),
          ),
      ],
      dailyBonusAvailable: dailyBonusAvailable(_game),
      dailyBonusClaimed: _game.dailyBonusClaimed,
      starterPackReady: market_starter.starterPackEligible(_game),
      dailyClaimableCount: dailyClaimableCount(_game),
      ascensionCount: _game.ascensionCount,
      ascensionPointsAvailable: ascensionPointsAvailable(_game),
      ascensionPointsSpendable: ascensionPointsSpendable(_game),
      ascensionProgress: _ascensionProgress(),
      ascensionIncomeLevel: _game.ascensionIncomeLevel,
      ascensionStarBonusLevel: _game.ascensionStarBonusLevel,
      ascensionStarGainLevel: _game.ascensionStarGainLevel,
      levels: _game.levels,
    );
  }
}
