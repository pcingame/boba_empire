import 'package:boba_empire/core/accessories.dart' show AccessoryRarity;
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/topup.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/iap/iap_products.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/l10n/l10n_ext.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;

/// [clock] đọc lại mỗi lần gọi → test dịch được thời gian giữa các lần nhận.
Future<ProviderContainer> _ctl(GameState seed, {int Function()? clock}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(clock ?? () => 0),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cấp VIP theo bậc EXP, bậc cuối = số bậc', () {
    expect(topupVipLevel(0), 0);
    expect(topupVipLevel(499), 0);
    expect(topupVipLevel(500), 1);
    expect(topupVipLevel(2999), 2);
    expect(topupVipLevel(3000), 3);
    expect(topupVipLevel(99999999), topupTiers.length);
    expect(vipIncomeMultiplier(0), 1.0);
    expect(vipIncomeMultiplier(500), closeTo(1.02, 1e-9));
  });

  test('có 10 cấp VIP, mỗi cấp có biệt danh khác nhau ở cả 7 ngôn ngữ', () {
    expect(topupTiers.length, 10);
    for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
      final l10n = lookupAppLocalizations(Locale(lang));
      final names = [
        for (var i = 1; i <= topupTiers.length; i++) vipName(l10n, i),
      ];
      expect(names.every((n) => n.isNotEmpty), isTrue, reason: lang);
      expect(names.toSet().length, names.length, reason: '$lang trùng tên');
    }
    expect(vipName(lookupAppLocalizations(const Locale('en')), 11), '');
  });

  test('mọi sản phẩm IAP có EXP > 0; IAP luôn nhiều EXP hơn mua bằng 💎 cùng giá trị',
      () {
    for (final p in IapProduct.values) {
      expect(p.vipExp, greaterThan(0), reason: p.id);
    }
    // 💎 trong gói → nếu đem mua EXP chỉ ra gems/10 EXP, ít hơn EXP của chính gói.
    for (final p in IapProduct.values.where((p) => p.isGems)) {
      final viaGems = p.gems / (vipExpBlockGems / vipExpBlock);
      expect(p.vipExp, greaterThan(viaGems), reason: p.id);
    }
  });

  test('EXP tăng thu nhập theo cấp VIP', () async {
    final c = await _ctl(GameState.newGame(nowMillis: 0)..levels['tra_den'] = 10);
    final n = c.read(gameControllerProvider.notifier);
    final before = c.read(gameControllerProvider).incomePerSecond;
    n.addVipExp(500); // VIP 1
    expect(c.read(gameControllerProvider).incomePerSecond,
        closeTo(before * 1.02, 1e-6));
  });

  test('mua EXP bằng 💎: trừ 💎, cộng EXP, thiếu 💎 thì không; trần chặn', () async {
    final c = await _ctl(GameState.newGame(nowMillis: 0)..gems = 999);
    final n = c.read(gameControllerProvider.notifier);
    expect(n.buyVipExp(), isFalse); // thiếu 1 💎
    expect(c.read(gameControllerProvider).vipExp, 0);

    final c2 = await _ctl(GameState.newGame(nowMillis: 0)..gems = 5000);
    final n2 = c2.read(gameControllerProvider.notifier);
    expect(n2.buyVipExp(), isTrue);
    final s = c2.read(gameControllerProvider);
    expect(s.gems, 5000 - vipExpBlockGems);
    expect(s.vipExp, vipExpBlock);
    expect(s.vipExpFromGems, vipExpBlock);

    // Chạm trần: đủ 💎 vẫn không mua được và không bị trừ.
    final c3 = await _ctl(GameState.newGame(nowMillis: 0)
      ..gems = 1e9
      ..vipExpFromGems = vipExpGemCap);
    expect(c3.read(gameControllerProvider.notifier).buyVipExp(), isFalse);
    expect(c3.read(gameControllerProvider).gems, 1e9);
    // Đúng sát trần: mua được khối cuối rồi dừng.
    final c4 = await _ctl(GameState.newGame(nowMillis: 0)
      ..gems = 1e9
      ..vipExpFromGems = vipExpGemCap - vipExpBlock);
    final n4 = c4.read(gameControllerProvider.notifier);
    expect(n4.buyVipExp(), isTrue);
    expect(n4.buyVipExp(), isFalse);
  });

  test('EXP mua bằng 💎 không bao giờ tới cấp 7+ (chỉ nạp thật mới tới)', () {
    expect(topupVipLevel(vipExpGemCap), 6);
  });

  test('nhận mốc: chưa đủ EXP → null; đủ → +💎 một lần; nhận lại → null',
      () async {
    final c = await _ctl(GameState.newGame(nowMillis: 0));
    final n = c.read(gameControllerProvider.notifier);
    expect(n.claimTopupTier(0), isNull);
    n.addVipExp(topupTiers[0].exp);
    final gems0 = c.read(gameControllerProvider).gems;
    expect(n.claimTopupTier(0), isNotNull);
    expect(c.read(gameControllerProvider).gems, gems0 + topupTiers[0].gems);
    expect(n.claimTopupTier(0), isNull);
    expect(c.read(gameControllerProvider).topupClaimed, [0]);
    expect(n.claimTopupTier(-1), isNull);
    expect(n.claimTopupTier(999), isNull);
  });

  test('bậc có phụ kiện: rớt đúng khi có accessory', () async {
    final c = await _ctl(GameState.newGame(nowMillis: 0));
    final n = c.read(gameControllerProvider.notifier);
    n.addVipExp(topupTiers.last.exp);
    for (var i = 0; i < topupTiers.length; i++) {
      final r = n.claimTopupTier(i)!;
      expect(r.drop != null, topupTiers[i].accessory != null, reason: 'bậc $i');
    }
    expect(c.read(gameControllerProvider).topupClaimed.length, topupTiers.length);
    expect(c.read(gameControllerProvider).ownedAccessories, isNotEmpty);
  });

  test('quà VIP: chưa có cấp → không nhận; mỗi kỳ một lần, sang kỳ mới nhận lại',
      () async {
    var now = 100 * _day; // ngày 100 kể từ epoch
    final c = await _ctl(GameState.newGame(nowMillis: 0), clock: () => now);
    final n = c.read(gameControllerProvider.notifier);
    for (final p in VipPeriod.values) {
      expect(n.claimVipBenefit(p), isNull, reason: 'cấp 0 ${p.name}');
    }

    n.addVipExp(topupTiers[2].exp); // VIP 3
    final gems0 = c.read(gameControllerProvider).gems;
    final d = n.claimVipBenefit(VipPeriod.daily)!;
    expect(d.gems, 30);
    expect(d.drop, isNull);
    expect(n.claimVipBenefit(VipPeriod.daily), isNull); // cùng ngày
    final w = n.claimVipBenefit(VipPeriod.weekly)!;
    expect(w.gems, 210);
    expect(w.drop, isNotNull);
    final m = n.claimVipBenefit(VipPeriod.monthly)!;
    expect(m.gems, 900);
    expect(m.drop, isNotNull);
    expect(c.read(gameControllerProvider).gems, gems0 + 30 + 210 + 900);

    now += _day; // ngày kế: chỉ quà ngày được nhận lại
    expect(n.claimVipBenefit(VipPeriod.daily), isNotNull);
    // ngày 100 → 101 vẫn cùng tuần (thứ Hai-Chủ nhật) nên quà tuần chưa nhận lại được.
    expect(n.claimVipBenefit(VipPeriod.weekly), isNull);
    now += 40 * _day; // qua cả tuần lẫn tháng
    expect(n.claimVipBenefit(VipPeriod.weekly), isNotNull);
    expect(n.claimVipBenefit(VipPeriod.monthly), isNotNull);
  });

  test('chỉ số kỳ: tuần bắt đầu thứ Hai, tháng theo lịch UTC', () {
    // 2026-10-05 là thứ Hai, 2026-10-11 là Chủ nhật, 2026-10-12 lại là thứ Hai.
    int ms(int y, int m, int d) => DateTime.utc(y, m, d).millisecondsSinceEpoch;
    final mon = vipPeriodIndex(VipPeriod.weekly, ms(2026, 10, 5));
    expect(vipPeriodIndex(VipPeriod.weekly, ms(2026, 10, 11)), mon);
    expect(vipPeriodIndex(VipPeriod.weekly, ms(2026, 10, 12)), mon + 1);
    expect(vipPeriodIndex(VipPeriod.monthly, ms(2026, 10, 31)),
        vipPeriodIndex(VipPeriod.monthly, ms(2026, 10, 1)));
    expect(vipPeriodIndex(VipPeriod.monthly, ms(2026, 11, 1)),
        vipPeriodIndex(VipPeriod.monthly, ms(2026, 10, 1)) + 1);
  });

  test('quà theo cấp tăng dần và độ hiếm phụ kiện đúng ngưỡng', () {
    expect(vipBenefit(VipPeriod.daily, 0), isNull);
    for (final p in VipPeriod.values) {
      var prev = 0.0;
      for (var l = 1; l <= topupTiers.length; l++) {
        final g = vipBenefit(p, l)!.gems;
        expect(g, greaterThan(prev), reason: '${p.name} L$l');
        prev = g;
      }
    }
    expect(vipBenefit(VipPeriod.daily, 10)!.accessory, isNull);
    expect(vipBenefit(VipPeriod.weekly, 10)!.accessory, AccessoryRarity.legendary);
    expect(vipBenefit(VipPeriod.monthly, 1)!.accessory, isNotNull);
  });

  test('EXP, EXP mua bằng 💎, bậc và kỳ đã nhận được lưu qua save/load', () {
    final g = GameState.newGame(nowMillis: 0)
      ..vipExp = 4200
      ..vipExpFromGems = 300
      ..vipClaimDay = 11
      ..vipClaimWeek = 12
      ..vipClaimMonth = 13
      ..topupClaimed.add(1);
    final back = GameState.fromJson(g.toJson());
    expect(back.vipExp, 4200);
    expect(back.vipExpFromGems, 300);
    expect([back.vipClaimDay, back.vipClaimWeek, back.vipClaimMonth], [11, 12, 13]);
    expect(back.topupClaimed, [1]);
    final old = GameState.fromJson(GameState.newGame(nowMillis: 0).toJson()
      ..remove('vipExp')
      ..remove('vipExpFromGems')
      ..remove('topupClaimed'));
    expect(old.vipExp, 0);
    expect(old.vipExpFromGems, 0);
    expect(old.topupClaimed, isEmpty);
  });
}
