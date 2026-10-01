import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _fresh() => GameState.newGame(nowMillis: 0);

void main() {
  test('danh mục: 50 món, id không trùng, đúng phân bố độ hiếm 25/13/9/3', () {
    expect(accessories.length, 50);
    expect(accessories.map((a) => a.id).toSet().length, 50); // không trùng id
    final byRarity = <AccessoryRarity, int>{};
    for (final a in accessories) {
      byRarity[a.rarity] = (byRarity[a.rarity] ?? 0) + 1;
    }
    expect(byRarity[AccessoryRarity.common], 25);
    expect(byRarity[AccessoryRarity.rare], 13);
    expect(byRarity[AccessoryRarity.epic], 9);
    expect(byRarity[AccessoryRarity.legendary], 3);
  });

  test('accessoryById: tìm đúng món, id lạ thì ném lỗi (không có id lạ trong'
      ' dữ liệu nội bộ nên chấp nhận throw thay vì fallback im lặng)', () {
    expect(accessoryById('dragon').rarity, AccessoryRarity.legendary);
    expect(() => accessoryById('no_such_id'), throwsStateError);
  });

  group('rollAccessory', () {
    test('roll01 = 0 -> luôn ra độ hiếm đầu tiên theo trọng số (common) và'
        ' món đầu trong nhóm đó', () {
      final a = rollAccessory(0, 0);
      expect(a.rarity, AccessoryRarity.common);
      expect(a.id, accessories.first.id);
    });

    test('roll01 sát 1 -> luôn ra độ hiếm cuối (legendary)', () {
      final a = rollAccessory(0.999999, 0.999999);
      expect(a.rarity, AccessoryRarity.legendary);
    });

    test('itemRoll01 quét hết [0,1) chỉ ra món trong ĐÚNG nhóm độ hiếm đã'
        ' chọn, không lệch nhóm, không crash', () {
      for (var i = 0; i < 1000; i++) {
        final itemRoll = i / 1000;
        final a = rollAccessory(0, itemRoll); // luôn common
        expect(a.rarity, AccessoryRarity.common);
      }
    });

    test('trọng số lệch đúng hướng: common phổ biến hơn hẳn legendary khi'
        ' quét đều roll01 trên [0,1) (tỉ lệ diện tích ~ trọng số)', () {
      final counts = <AccessoryRarity, int>{};
      final rng = List.generate(5000, (i) => i / 5000.0);
      for (final r in rng) {
        final a = rollAccessory(r, 0);
        counts[a.rarity] = (counts[a.rarity] ?? 0) + 1;
      }
      expect(counts[AccessoryRarity.common]! > counts[AccessoryRarity.rare]!,
          isTrue);
      expect(counts[AccessoryRarity.rare]! > counts[AccessoryRarity.epic]!,
          isTrue);
      expect(
          counts[AccessoryRarity.epic]! > counts[AccessoryRarity.legendary]!,
          isTrue);
    });
  });

  group('grantAccessory', () {
    test('món mới: thêm vào ownedAccessories, trả về true, không cộng 💎', () {
      final s = _fresh();
      final a = accessoryById('mint_leaf');
      final gemsBefore = s.gems;
      final isNew = grantAccessory(s, a);
      expect(isNew, isTrue);
      expect(s.ownedAccessories, contains('mint_leaf'));
      expect(s.gems, gemsBefore);
    });

    test('món đã có (trùng): KHÔNG thêm lần 2, quy đổi đúng'
        ' Balance.duplicateAccessoryGems, trả về false', () {
      final s = _fresh();
      final a = accessoryById('cupcake');
      grantAccessory(s, a);
      final gemsAfterFirst = s.gems;
      final isNew = grantAccessory(s, a);
      expect(isNew, isFalse);
      expect(s.ownedAccessories.where((id) => id == 'cupcake').length, 1);
      expect(s.gems, gemsAfterFirst + Balance.duplicateAccessoryGems);
    });

    test('rớt liên tiếp nhiều món khác nhau: mỗi món chỉ xuất hiện 1 lần', () {
      final s = _fresh();
      for (final a in accessories) {
        grantAccessory(s, a);
      }
      expect(s.ownedAccessories.length, accessories.length);
      expect(s.ownedAccessories.toSet().length, accessories.length);
    });
  });
}
