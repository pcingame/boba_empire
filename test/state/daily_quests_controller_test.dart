import 'package:boba_empire/core/daily_quests.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/state/game_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dayMs = 24 * 60 * 60 * 1000;

/// Ngày đầu tiên (từ 20000) có [kind] trong bộ nhiệm vụ — để test từng loại hook.
int _dayWith(DailyQuestKind kind) {
  for (var d = 20000;; d++) {
    if (dailyQuestsFor(d, 1e6).any((q) => q.kind == kind)) return d;
  }
}

class _H {
  _H(this.container, this.setNow);
  final ProviderContainer container;
  final void Function(int) setNow;
  GameSnapshot get snap => container.read(gameControllerProvider);
  dynamic get ctrl => container.read(gameControllerProvider.notifier);
  double progress(DailyQuestKind k) =>
      snap.dailyQuests.firstWhere((q) => q.kind == k).progress;
}

Future<_H> _harness(int day,
    {GameState Function(int now)? seed, int savedAgoMs = 0}) async {
  final now = day * _dayMs + 1000;
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final s = seed?.call(now) ?? GameState.newGame(nowMillis: now);
  // GameStorage.save đóng dấu lastSeenMillis = nowMillis → dùng để giả lập "vắng mặt".
  await GameStorage(prefs).save(s, nowMillis: now - savedAgoMs);
  var clock = now;
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => clock),
  ]);
  addTearDown(c.dispose);
  return _H(c, (t) => clock = t);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mở app: có đủ 3 nhiệm vụ của ngày hôm nay, tiến độ 0', () async {
    final h = await _harness(20000);
    expect(h.snap.dailyQuests.length, 3);
    expect(h.snap.dailyQuests.every((q) => q.progress == 0 || q.kind == DailyQuestKind.earn),
        isTrue);
    expect(h.snap.dailyClaimableCount, 0);
  });

  test('chạm ly tăng tiến độ nhiệm vụ Chạm', () async {
    final h = await _harness(_dayWith(DailyQuestKind.tap));
    h.ctrl.tapCup();
    h.ctrl.tapCup();
    expect(h.progress(DailyQuestKind.tap), 2);
  });

  test('mua nâng cấp (đơn + nhiều + auto) tăng tiến độ Nâng cấp', () async {
    final h = await _harness(_dayWith(DailyQuestKind.buy),
        seed: (now) => GameState.newGame(nowMillis: now)..money = 1e6);
    h.ctrl.buy('tra_den');
    expect(h.progress(DailyQuestKind.buy), 1);
    final n = h.ctrl.buyBulk('tra_den', 5) as int;
    expect(h.progress(DailyQuestKind.buy), 1.0 + n);
  });

  test('bắt mèo / khách VIP / quay vòng quay đều được đếm', () async {
    final hc = await _harness(_dayWith(DailyQuestKind.cat));
    hc.ctrl.debugSpawnCat();
    hc.ctrl.activateGoldenRush();
    expect(hc.progress(DailyQuestKind.cat), 1);

    final hv = await _harness(_dayWith(DailyQuestKind.vip));
    hv.ctrl.debugSpawnVip();
    hv.ctrl.collectVip();
    expect(hv.progress(DailyQuestKind.vip), 1);

    final hs = await _harness(_dayWith(DailyQuestKind.spin));
    hs.ctrl.spin(free: true);
    expect(hs.progress(DailyQuestKind.spin), 1);
  });

  test('HỒI QUY: Xu kiếm lúc app tắt tính vào ngày hôm nay, không bị xoá', () async {
    final day = _dayWith(DailyQuestKind.earn);
    // Vắng 1 giờ, có thu nhập → build() cộng tiền offline SAU khi sang ngày.
    final h = await _harness(day,
        savedAgoMs: 3600 * 1000,
        seed: (now) => GameState.newGame(nowMillis: now)..levels['tra_den'] = 10);
    expect(h.snap.offlineEarned, greaterThan(0));
    expect(h.progress(DailyQuestKind.earn), greaterThan(0));
  });

  test('qua ngày (tick) đổi bộ, xoá tiến độ và cờ đã nhận', () async {
    final day = _dayWith(DailyQuestKind.tap);
    final h = await _harness(day);
    h.ctrl.tapCup();
    expect(h.progress(DailyQuestKind.tap), 1);
    h.setNow((day + 1) * _dayMs + 1000);
    h.ctrl.debugTick();
    final next = dailyQuestsFor(day + 1, 1e6).map((q) => q.kind).toList();
    expect(h.snap.dailyQuests.map((q) => q.kind).toList(), next);
    expect(h.snap.dailyQuests.every((q) => q.progress == 0 || q.kind == DailyQuestKind.earn),
        isTrue);
  });

  test('nhận thưởng: cộng 💎, chỉ một lần, lưu ngay', () async {
    final day = _dayWith(DailyQuestKind.cat);
    final h = await _harness(day);
    h.ctrl.debugSpawnCat();
    h.ctrl.activateGoldenRush();
    final idx = h.snap.dailyQuests.indexWhere((q) => q.kind == DailyQuestKind.cat);
    expect(h.snap.dailyClaimableCount, 1);
    final gems0 = h.snap.gems;
    final got = h.ctrl.claimDailyQuestReward(idx) as int;
    expect(got, greaterThan(0));
    expect(h.snap.gems, gems0 + got);
    expect(h.ctrl.claimDailyQuestReward(idx), 0); // đã nhận
    expect(h.snap.dailyClaimableCount, 0);

    final prefs = await SharedPreferences.getInstance();
    final reloaded = GameStorage(prefs).load()!;
    expect(reloaded.dailyClaimed, contains('cat'));
    expect(reloaded.gems, gems0 + got);
  });

  test('nhận thưởng "xong cả 3 nhiệm vụ ngày" cũng cấp 1 phụ kiện sưu tập'
      ' mới (ván mới nên chắc chắn chưa trùng món nào)', () async {
    final day = 20000;
    final kinds = dailyQuestsFor(day, 1e6).map((q) => q.kind.name).toList();
    final h = await _harness(day,
        seed: (now) => GameState.newGame(nowMillis: now)
          ..dailyQuestDay = day // khớp "hôm nay" để rollDailyQuests không đổi bộ
          ..dailyClaimed.addAll(kinds));
    expect(h.snap.dailyBonusAvailable, isTrue);
    expect(h.snap.ownedAccessories, isEmpty);
    final gemsBefore = h.snap.gems;
    final got = h.ctrl.claimDailyBonus() as int;
    expect(got, greaterThan(0));
    expect(h.snap.ownedAccessories.length, 1);
    // Món đầu tiên của 1 ván mới chắc chắn là MỚI (chưa có gì để trùng) nên
    // không có 💎 quy đổi cộng thêm ngoài thưởng bonus.
    expect(h.snap.gems, gemsBefore + got);
    // UI đọc lastAccessoryDrop ngay sau khi nhận để hiện "khoảnh khắc nhận".
    final drop = h.ctrl.lastAccessoryDrop;
    expect(drop, isNotNull);
    expect(drop!.isNew, isTrue);
    expect(h.snap.ownedAccessories, [drop.accessory.id]);
  });

  test('Nhượng quyền không xoá tiến độ nhiệm vụ ngày', () async {
    final day = _dayWith(DailyQuestKind.tap);
    final h = await _harness(day,
        seed: (now) => GameState.newGame(nowMillis: now)
          ..lifetimeEarnings = 1e9);
    h.ctrl.tapCup();
    h.ctrl.doPrestige();
    expect(h.progress(DailyQuestKind.tap), 1);
  });
}
