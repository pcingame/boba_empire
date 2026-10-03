import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/starter_pack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('đủ điều kiện: giai đoạn ≥3 + từng nhận nhiệm vụ ngày + chưa nhận', () {
    final s = GameState.newGame(nowMillis: 0);
    expect(starterPackEligible(s), isFalse);
    s.stage = 3;
    expect(starterPackEligible(s), isFalse); // thiếu nhiệm vụ
    s.dailyQuestEverClaimed = true;
    expect(starterPackEligible(s), isTrue);
    s.starterPackClaimed = true;
    expect(starterPackEligible(s), isFalse);
  });

  test('cấp món Thường chưa có + 1 bản dư, không quy đổi 💎', () {
    final s = GameState.newGame(nowMillis: 0)..stage = 3;
    final item = starterPackAccessory(s);
    expect(item.rarity, AccessoryRarity.common);
    final gems = s.gems;
    grantMarketStarter(s, item);
    expect(s.ownedAccessories, contains(item.id));
    expect(s.accessorySpares[item.id], 1);
    expect(s.gems, gems);
    expect(s.starterPackClaimed, isTrue);
  });

  test('đã có hết món Thường: vẫn cấp, chỉ thành bản dư', () {
    final s = GameState.newGame(nowMillis: 0);
    for (final a in accessories.where((a) => a.rarity == AccessoryRarity.common)) {
      s.ownedAccessories.add(a.id);
    }
    final item = starterPackAccessory(s);
    grantMarketStarter(s, item);
    expect(s.accessorySpares[item.id], 1);
  });

  test('cờ nhiệm vụ lưu/đọc qua JSON', () {
    final s = GameState.newGame(nowMillis: 0)
      ..dailyQuestEverClaimed = true
      ..starterPackClaimed = true;
    final r = GameState.fromJson(s.toJson());
    expect(r.dailyQuestEverClaimed, isTrue);
    expect(r.starterPackClaimed, isTrue);
  });
}
