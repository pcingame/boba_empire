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

import '../core/achievements.dart';
import '../core/balance.dart';
import '../core/daily.dart';
import '../core/economy.dart';
import '../core/models.dart';
import '../core/quests.dart';
import '../core/simulation.dart';
import '../core/vip.dart';
import '../core/wheel.dart';
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

  /// Thành tựu vừa mở khoá, chờ UI hiển thị (xoá qua acknowledgeAchievements).
  List<Achievement> _newAchievements = const [];

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
      maxOfflineSeconds: _offlineCap(),
    );
    claimVipDailyGems(_game, _clock()); // Kim Cương VIP nếu sang ngày mới
    _scheduleNextCat(_clock());
    _scheduleNextVip(_clock());
    _timer = Timer.periodic(tickInterval, (_) => _onTick());
    ref.onDispose(() => _timer?.cancel());
    _awardAchievements(); // thành tựu đạt sẵn từ trước / qua tiền offline
    return _snapshot();
  }

  /// Hệ số boost thời gian đang áp dụng: ×3 Mưa vàng và/hoặc ×2 "thu nhập 24h"
  /// (xem QC). Cộng dồn nếu trùng.
  double _boostMultiplier() {
    final now = _clock();
    var m = 1.0;
    if (now < _boostUntilMillis) m *= Balance.goldenRushMultiplier;
    if (now < _game.x2IncomeUntilMillis) m *= Balance.rewardedX2Multiplier;
    if (vipActive(_game, now)) m *= Balance.vipIncomeMultiplier;
    return m;
  }

  /// Trần offline (giây) đã tính cấp "Kho lạnh" + cộng thưởng VIP nếu đang VIP.
  int _offlineCap() =>
      offlineCapSeconds(_game.offlineCapLevel) +
      (vipActive(_game, _clock()) ? Balance.vipOfflineBonusSeconds : 0);

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

  /// Chạm ly → +tiền (nhân boost Mưa vàng nếu đang có). Trả về số Xu vừa nhận
  /// để UI hiện hiệu ứng "+X" bay lên.
  double tapCup() {
    _game.tapCount++;
    final gained = tap(_game, boostMultiplier: _boostMultiplier());
    state = _snapshot();
    return gained;
  }

  /// Nâng cấp một nguồn thu. Trả về true nếu đủ tiền và mua thành công.
  bool buy(String generatorId) {
    final ok = buyUpgrade(_game, generatorId);
    if (ok) {
      _game.buyCount++;
      _awardAchievements();
      state = _snapshot();
    }
    return ok;
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

  /// Nhượng quyền. Trả về số Sao vừa nhận (0 nếu chưa đủ).
  int doPrestige() {
    final gained = prestige(_game);
    if (gained > 0) {
      _awardAchievements();
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
  ({int index, WheelKind kind, double value}) spin({required bool free}) {
    final i = spinWheel(_random.nextDouble());
    final p = wheelPrizes[i];
    double value = 0;
    switch (p.kind) {
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
    return (index: i, kind: p.kind, value: value);
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
    _awardAchievements(); // bắt các mốc lifetimeEarnings tăng theo thời gian
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
      adsRemoved: _game.adsRemoved,
      starterPackOwned: _game.starterPackOwned,
      tutorialSeen: _game.tutorialSeen,
      dailyAvailable: dailyAvailable(_game, _clock()),
      newAchievements: _newAchievements,
      lifetimeEarnings: _game.lifetimeEarnings,
      achievementsClaimed: _game.achievementsClaimed,
      prestigeStarsSpendable: prestigeStarsSpendable(_game),
      prestigeIncomeLevel: _game.prestigeIncomeLevel,
      prestigeTapLevel: _game.prestigeTapLevel,
      currentQuest: currentQuest(_game),
      questProgress: currentQuest(_game) == null
          ? 0
          : questProgress(_game, currentQuest(_game)!.metric),
      questDone: currentQuestDone(_game),
      doubleIncomeOwned: _game.doubleIncomeOwned,
      x2IncomeRemainingSeconds:
          max(0, (_game.x2IncomeUntilMillis - _clock()) / 1000.0),
      piggyGems: _game.piggyGems,
      adFree: _game.adsRemoved || vipActive(_game, _clock()),
      vipActive: vipActive(_game, _clock()),
      vipRemainingSeconds:
          max(0, (_game.vipUntilMillis - _clock()) / 1000.0),
      freeSpinAvailable: dayIndex(_clock()) > _game.lastFreeSpinDay,
      levels: _game.levels,
    );
  }
}
