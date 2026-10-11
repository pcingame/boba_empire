import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/topup.dart';
import 'package:boba_empire/core/vip_shop.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/l10n/l10n_ext.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('8 món: id có tiền tố vip_, giá và cấp yêu cầu tăng dần, cấp trong 1..10', () {
    expect(vipShopItems.length, 8);
    for (final i in vipShopItems) {
      expect(i.id.startsWith('vip_'), isTrue, reason: i.id);
      expect(i.minLevel, inInclusiveRange(1, topupTiers.length), reason: i.id);
      expect(i.price, greaterThan(0), reason: i.id);
    }
    for (var n = 1; n < vipShopItems.length; n++) {
      expect(vipShopItems[n].price, greaterThan(vipShopItems[n - 1].price));
      expect(vipShopItems[n].minLevel, greaterThanOrEqualTo(vipShopItems[n - 1].minLevel));
    }
    // Cấp đầu mua được món đầu; cấp càng cao mở thêm món (có món cho từng cấp 1..8).
    expect([for (final i in vipShopItems) i.minLevel], [1, 2, 3, 4, 5, 6, 7, 8]);
  });

  test('món VIP nằm trong nhóm độc quyền (limitedAccessories), không lẫn bộ sưu tập chính', () {
    final limited = limitedAccessories.map((a) => a.id).toSet();
    final main = accessories.map((a) => a.id).toSet();
    for (final a in vipAccessories) {
      expect(limited.contains(a.id), isTrue, reason: a.id);
      expect(main.contains(a.id), isFalse, reason: a.id);
      expect(accessoryById(a.id).emoji, a.emoji);
    }
  });

  test('Xu VIP theo kỳ: ngày 5×cấp, tuần 35×cấp, tháng 150×cấp; cấp 0 không có', () {
    for (final p in VipPeriod.values) {
      expect(vipCoinsFor(p, 0), 0);
      expect(vipCoinsFor(p, -3), 0);
    }
    expect([for (final l in [1, 3, 10]) vipCoinsFor(VipPeriod.daily, l)], [5, 15, 50]);
    expect([for (final l in [1, 3, 10]) vipCoinsFor(VipPeriod.weekly, l)], [35, 105, 350]);
    expect([for (final l in [1, 3, 10]) vipCoinsFor(VipPeriod.monthly, l)], [150, 450, 1500]);
  });

  test('tốc độ kiếm Xu VIP hợp lý: cấp 1 mua được món rẻ nhất trong ~2 tuần; cấp 10 đủ món đắt nhất trong ~3 tuần',
      () {
    int perWeek(int level) =>
        7 * vipCoinsFor(VipPeriod.daily, level) +
        vipCoinsFor(VipPeriod.weekly, level) +
        (vipCoinsFor(VipPeriod.monthly, level) * 7 / 30).round();
    expect(vipShopItems.first.price / perWeek(1), lessThan(2.5)); // tuần
    expect(vipShopItems.last.price / perWeek(10), lessThan(3));
    expect(vipShopItems.last.price / perWeek(8), lessThan(4));
  });

  test('tên 8 món có ở cả 7 ngôn ngữ và khác nhau từng đôi một', () {
    for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
      final l10n = lookupAppLocalizations(Locale(lang));
      final names = [for (final i in vipShopItems) accessoryName(l10n, i.id)];
      expect(names.every((n) => n.trim().isNotEmpty), isTrue, reason: lang);
      expect(names.toSet().length, names.length, reason: '$lang trùng tên');
    }
  });
}
