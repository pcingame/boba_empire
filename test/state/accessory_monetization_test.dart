import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;

Future<ProviderContainer> _open({
  int day = 100, // thứ Hai? không quan trọng: chỉ so sánh tương đối
  double gems = 1000,
  bool bonusClaimed = false,
  int nowMs = 0,
}) async {
  final now = nowMs != 0 ? nowMs : day * _day + 1000;
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: now)
        ..gems = gems
        ..dailyQuestDay = now ~/ _day
        ..dailyBonusClaimed = bonusClaimed,
      nowMillis: now);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now),
  ]);
  addTearDown(c.dispose);
  return c;
}

dynamic _ctrl(ProviderContainer c) => c.read(gameControllerProvider.notifier);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('tỉ lệ & roll tối thiểu', () {
    test('odds tổng = 1 và không có độ hiếm dưới min', () {
      for (final min in AccessoryRarity.values) {
        final o = accessoryOdds(min: min);
        expect(o.values.fold<double>(0, (a, b) => a + b), closeTo(1, 1e-9));
        expect(o.keys.every((r) => r.index >= min.index), isTrue);
      }
    });

    test('roll với min=epic không bao giờ ra thường/hiếm', () {
      for (var i = 0; i < 200; i++) {
        final a = rollAccessory(i / 200, (i * 7 % 200) / 200,
            min: AccessoryRarity.epic);
        expect(a.rarity.index, greaterThanOrEqualTo(AccessoryRarity.epic.index));
      }
    });

    test('mặc định (min=common) giữ nguyên hành vi cũ', () {
      expect(accessoryOdds()[AccessoryRarity.common],
          closeTo(Balance.accessoryWeightCommon / 100, 1e-9));
    });
  });

  group('giá & mùa', () {
    test('ngoài mùa giá gốc, trong mùa giảm 25%, hết mùa quay về gốc', () {
      final f = festivals.first;
      final before = f.start.subtract(const Duration(seconds: 1));
      final inside = f.start;
      expect(AccessoryPack.epic.cost(before), 200);
      expect(AccessoryPack.epic.cost(inside), 150);
      expect(AccessoryPack.epic.cost(festivals.first.end), 200);
    });

    test('VIP có thêm 1 chỗ trưng bày', () {
      expect(maxEquippedFor(vip: true), maxEquippedFor(vip: false) + 1);
    });
  });

  group('mua gói', () {
    test('đủ 💎: trừ đúng giá, có rớt, đúng độ hiếm tối thiểu', () async {
      final c = await _open(gems: 500);
      final drop = _ctrl(c).buyAccessoryPack(AccessoryPack.epic) as AccessoryDrop?;
      expect(drop, isNotNull);
      expect(drop!.accessory.rarity.index,
          greaterThanOrEqualTo(AccessoryRarity.epic.index));
      final gemsLeft = c.read(gameControllerProvider).gems;
      // trùng món → +2 💎 hoàn; mới → không hoàn
      expect(gemsLeft, drop.isNew ? 300 : 302);
    });

    test('thiếu 💎: không trừ, không rớt', () async {
      final c = await _open(gems: 10);
      expect(_ctrl(c).buyAccessoryPack(AccessoryPack.basic), isNull);
      expect(c.read(gameControllerProvider).gems, 10);
      expect(c.read(gameControllerProvider).ownedAccessories, isEmpty);
    });
  });

  group('lượt rớt xem QC', () {
    test('chỉ sau khi nhận thưởng cả bộ; 1 lần/ngày', () async {
      final locked = await _open(bonusClaimed: false);
      expect(locked.read(gameControllerProvider).accessoryAdDropAvailable, isFalse);
      expect(_ctrl(locked).claimAdAccessoryDrop(), isNull);

      final c = await _open(bonusClaimed: true);
      expect(c.read(gameControllerProvider).accessoryAdDropAvailable, isTrue);
      expect(_ctrl(c).claimAdAccessoryDrop(), isNotNull);
      expect(c.read(gameControllerProvider).accessoryAdDropAvailable, isFalse);
      expect(_ctrl(c).claimAdAccessoryDrop(), isNull); // lần 2 cùng ngày: không
    });
  });

  group('vòng quay phụ kiện', () {
    test('quay bằng 💎: trừ đúng 30, có rớt; thiếu 💎 thì không', () async {
      final c = await _open(gems: 120);
      final d = _ctrl(c).spinAccessoryWheel(withAd: false) as AccessoryDrop?;
      expect(d, isNotNull);
      expect(c.read(gameControllerProvider).gems, d!.isNew ? 90 : 92);
      final poor = await _open(gems: 29);
      expect(_ctrl(poor).spinAccessoryWheel(withAd: false), isNull);
      expect(poor.read(gameControllerProvider).gems, 29);
    });

    test('quay xem QC: hạn mức/ngày, hết thì null, sang ngày mới được lại',
        () async {
      final c = await _open(gems: 0);
      for (var i = 0; i < Balance.accessorySpinAdsPerDay; i++) {
        expect(c.read(gameControllerProvider).accessoryAdSpinsLeft,
            Balance.accessorySpinAdsPerDay - i);
        expect(_ctrl(c).spinAccessoryWheel(withAd: true), isNotNull);
      }
      expect(c.read(gameControllerProvider).accessoryAdSpinsLeft, 0);
      expect(_ctrl(c).spinAccessoryWheel(withAd: true), isNull);
      expect(c.read(gameControllerProvider).gems, greaterThanOrEqualTo(0));
    });

    test('hạn mức reset khi sang ngày UTC mới', () {
      final s = GameState.newGame(nowMillis: 0)
        ..accessoryAdSpinDay = 100
        ..accessoryAdSpins = Balance.accessorySpinAdsPerDay;
      expect(accessoryAdSpinsLeft(s, 100 * _day + 5), 0);
      expect(accessoryAdSpinsLeft(s, 101 * _day + 5),
          Balance.accessorySpinAdsPerDay);
    });
  });
}
