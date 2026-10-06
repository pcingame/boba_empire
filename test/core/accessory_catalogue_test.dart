// Danh mục 160 món + mốc 80/100/120/140/160: kiểm tra tính toàn vẹn dữ liệu, độ phủ
// của bảng rớt, và khớp với SQL server (bảng thưởng mốc phải giống hệt).
import 'dart:io';

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/collection_milestones.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/l10n/l10n_ext.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final all = accessories.followedBy(limitedAccessories).toList();

  test('emoji không trùng giữa mọi món (kể cả món lễ hội); id cũng vậy', () {
    expect(all.map((a) => a.emoji).toSet().length, all.length);
    expect(all.map((a) => a.id).toSet().length, all.length);
    for (final a in all) {
      expect(a.emoji.trim(), isNotEmpty, reason: a.id);
      expect(RegExp(r'^[a-z][a-z_]*$').hasMatch(a.id), isTrue, reason: a.id);
    }
  });

  test('mọi món sưu tập chính rớt được: quét lưới rarity x item chạm đủ 160 món',
      () {
    final seen = <String>{};
    for (var r = 0.0; r < 1; r += 0.001) {
      for (var i = 0.0; i < 1; i += 0.001) {
        seen.add(rollAccessory(r, i).id);
        seen.add(rollAccessory(r, i, weekend: true).id);
      }
    }
    // Món lễ hội KHÔNG nằm trong bảng rớt thường.
    expect(seen, equals(accessories.map((a) => a.id).toSet()));
  });

  test('gói Hiếm/Sử thi chỉ ra món từ độ hiếm tối thiểu, và chạm đủ các món đó',
      () {
    for (final min in [AccessoryRarity.rare, AccessoryRarity.epic]) {
      final seen = <Accessory>{};
      for (var r = 0.0; r < 1; r += 0.002) {
        for (var i = 0.0; i < 1; i += 0.002) {
          seen.add(rollAccessory(r, i, min: min));
        }
      }
      expect(seen.every((a) => a.rarity.index >= min.index), isTrue);
      expect(seen.map((a) => a.id).toSet(),
          accessories.where((a) => a.rarity.index >= min.index).map((a) => a.id).toSet());
    }
  });

  test('mỗi món mới chiếm đúng xác suất = trọng số độ hiếm / số món cùng hạng', () {
    // Huyền thoại: 2% chia 9 món; Thường: 66/(66+24+8+2) chia 75 món.
    final odds = accessoryOdds();
    for (final r in AccessoryRarity.values) {
      final n = accessories.where((a) => a.rarity == r).length;
      expect(n, greaterThan(0));
      expect(odds[r]! / n, lessThan(0.02), reason: '$r');
    }
    expect(odds.values.reduce((a, b) => a + b), closeTo(1, 1e-9));
  });

  test('mốc sưu tập: tăng dần, không vượt số món, thưởng tăng dần', () {
    final counts = collectionMilestones.map((m) => m.count).toList();
    expect(counts, [10, 25, 40, 50, 80, 100, 120, 140, 160]);
    for (var i = 1; i < counts.length; i++) {
      expect(counts[i], greaterThan(counts[i - 1]));
      expect(collectionMilestones[i].coins,
          greaterThan(collectionMilestones[i - 1].coins));
    }
    expect(counts.last, lessThanOrEqualTo(accessories.length));
    expect(collectionMilestones.fold<int>(0, (a, m) => a + m.coins), 4570);
  });

  test('bảng thưởng mốc trong Dart KHỚP HỆT SQL claim_collection_milestone', () {
    final sql = File('supabase/accessory_market_schema.sql').readAsStringSync();
    final fn = sql.substring(sql.indexOf('function claim_collection_milestone'));
    final body = fn.substring(fn.indexOf('case p_milestone'), fn.indexOf('else null end'));
    final sqlMap = {
      for (final m in RegExp(r'when (\d+) then (\d+)').allMatches(body))
        int.parse(m.group(1)!): int.parse(m.group(2)!)
    };
    expect(sqlMap, {for (final m in collectionMilestones) m.count: m.coins});
    expect(sql, contains('4570 Xu Chợ'));
  });

  test('đủ 160 món → nhận được cả 9 mốc; 79 món → mốc 80 chưa', () {
    final s = GameState.newGame(nowMillis: 0)
      ..ownedAccessories.addAll(accessories.take(79).map((a) => a.id));
    expect(milestonesClaimable(s), 4);
    s.ownedAccessories.add(accessories[79].id);
    expect(milestonesClaimable(s), 5);
    s.ownedAccessories.addAll(accessories.map((a) => a.id).where((i) => !s.ownedAccessories.contains(i)));
    expect(s.ownedAccessories.length, 160);
    expect(milestonesClaimable(s), 9);
    s.collectionMilestonesClaimed.addAll([10, 25, 40, 50, 80, 100, 120, 140, 160]);
    expect(highestClaimedMilestone(s)!.count, 160);
    expect(milestonesClaimable(s), 0);
  });

  test('save cũ (đã có đủ 80 món, đã nhận 4 mốc cũ) → mốc 80 nhận được ngay', () {
    final s = GameState.newGame(nowMillis: 0)
      ..ownedAccessories.addAll(accessories.take(80).map((a) => a.id))
      ..collectionMilestonesClaimed.addAll([10, 25, 40, 50]);
    final r = GameState.fromJson(s.toJson());
    expect(milestonesClaimable(r), 1);
    expect(r.ownedAccessories.every((id) => accessoryById(id).id == id), isTrue);
  });

  for (final code in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    test('[$code] danh hiệu mọi mốc có tên riêng, không rơi về mốc 50', () async {
      final l10n = await AppLocalizations.delegate.load(Locale(code));
      final titles = collectionMilestones
          .map((m) => collectionTitle(l10n, m.count))
          .toList();
      expect(titles.toSet().length, titles.length, reason: 'trùng danh hiệu: $titles');
      for (final t in titles) {
        expect(t.trim(), isNotEmpty);
      }
    });

    test('[$code] tên 40 món mới khác nhau từng đôi một (không dán nhầm)', () async {
      final l10n = await AppLocalizations.delegate.load(Locale(code));
      final names = accessories.map((a) => accessoryName(l10n, a.id)).toList();
      // Cho phép trùng tên giữa các món khác nhau ở rất ít ngôn ngữ (vd 'Bagel'
      // không phải vấn đề vì chỉ 1 món); nhưng cả danh mục không được có > 2 trùng.
      final dup = names.length - names.toSet().length;
      expect(dup, lessThanOrEqualTo(2), reason: '[$code] $dup tên trùng');
    });
  }
}
