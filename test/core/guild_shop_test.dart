// Danh mục cửa hàng hội: dữ liệu nhất quán, không đụng id/emoji của bộ sưu tập chính,
// có tên ở MỌI ngôn ngữ.
import 'dart:ui';

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/guild_shop.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/l10n/l10n_ext.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('id có tiền tố guild_, không trùng id/emoji của bộ sưu tập chính hay lễ hội', () {
    final others = [...accessories, for (final f in festivals) ...f.items];
    final ids = others.map((a) => a.id).toSet();
    final emojis = others.map((a) => a.emoji).toSet();
    for (final a in guildAccessories) {
      expect(a.id, startsWith('guild_'));
      expect(ids, isNot(contains(a.id)), reason: a.id);
      expect(emojis, isNot(contains(a.emoji)), reason: '${a.id} ${a.emoji}');
    }
    expect(guildAccessories.map((a) => a.id).toSet().length, guildAccessories.length);
  });

  test('tra cứu theo id hoạt động (trưng bày/Kho dùng accessoryById)', () {
    for (final a in guildAccessories) {
      expect(accessoryById(a.id).emoji, a.emoji);
    }
    expect(limitedAccessories.map((a) => a.id),
        containsAll(guildAccessories.map((a) => a.id)));
  });

  test('có tên dịch ở cả 7 ngôn ngữ (không rơi về id thô)', () {
    for (final code in ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th']) {
      final l10n = lookupAppLocalizations(Locale(code));
      for (final a in guildAccessories) {
        final name = accessoryName(l10n, a.id);
        expect(name, isNotEmpty);
        expect(name, isNot(a.id), reason: '$code ${a.id}');
      }
    }
  });

  test('giá hợp lý: mọi món hiếm hơn đều đắt hơn mọi món kém hiếm hơn, đều > 0', () {
    expect(guildShopItems.every((i) => i.price > 0), isTrue);
    for (final lo in guildShopItems) {
      for (final hi in guildShopItems) {
        if (lo.accessory.rarity.index < hi.accessory.rarity.index) {
          expect(lo.price, lessThan(hi.price), reason: '${lo.id} vs ${hi.id}');
        }
      }
    }
  });

  test('nhiệm vụ tuần: ngưỡng và thưởng tăng dần', () {
    expect(guildQuests.length, 3);
    for (var i = 1; i < guildQuests.length; i++) {
      expect(guildQuests[i].need, greaterThan(guildQuests[i - 1].need));
      expect(guildQuests[i].reward, greaterThan(guildQuests[i - 1].reward));
    }
  });

  test('buff: có lợi thật nhưng không quá tay; trần buff ≥ 1 lần mua', () {
    expect(Balance.guildBuffMult, greaterThan(1.0));
    expect(Balance.guildBuffMult, lessThanOrEqualTo(1.25));
    expect(guildBuffMaxHours, greaterThanOrEqualTo(guildBuffHours));
    expect(guildBuffPrice, greaterThan(0));
  });

  test('nạp 💎 tối đa mỗi ngày đủ mua món đắt nhất trong vài ngày (không nhanh quá)', () {
    final legend = guildShopItems.map((i) => i.price).reduce((a, b) => a > b ? a : b);
    final daysToLegend = legend / (guildDonateDailyCap * guildCoinsPerGem);
    expect(daysToLegend, greaterThanOrEqualTo(2),
        reason: 'không cho một người mua hết kho trong một ngày');
  });
}
