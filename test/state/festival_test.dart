import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _open(int nowMs, {double gems = 1000}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs)
      .save(GameState.newGame(nowMillis: nowMs)..gems = gems, nowMillis: nowMs);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => nowMs),
  ]);
  addTearDown(c.dispose);
  return c;
}

dynamic _ctrl(ProviderContainer c) => c.read(gameControllerProvider.notifier);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final inWindow = festivals.first.start.millisecondsSinceEpoch + 1000;

  group('dữ liệu dịp lễ', () {
    test('id không trùng với bộ sưu tập chính hay dịp khác; mỗi dịp 4 món', () {
      final ids = [
        ...accessories.map((a) => a.id),
        ...limitedAccessories.map((a) => a.id),
      ];
      expect(ids.toSet().length, ids.length);
      for (final f in festivals) {
        expect(f.items.length, 4);
        expect(f.end.isAfter(f.start), isTrue);
      }
    });

    test('các dịp không chồng lấn', () {
      final s = [...festivals]..sort((a, b) => a.start.compareTo(b.start));
      for (var i = 1; i < s.length; i++) {
        expect(!s[i].start.isBefore(s[i - 1].end), isTrue,
            reason: '${s[i].id} chồng ${s[i - 1].id}');
      }
    });

    test('activeFestival: đúng biên [start, end)', () {
      final f = festivals.first;
      expect(activeFestival(f.start.subtract(const Duration(seconds: 1))), isNull);
      expect(activeFestival(f.start)?.id, f.id);
      expect(activeFestival(f.end.subtract(const Duration(seconds: 1)))?.id, f.id);
      expect(activeFestival(f.end), isNull);
    });

    test('accessoryById tìm được cả món độc quyền', () {
      expect(accessoryById('santa').rarity, AccessoryRarity.legendary);
    });
  });

  group('mua Gói Lễ Hội', () {
    test('trong dịp: trừ 80💎, nhận món của dịp đó, KHÔNG đụng bộ sưu tập chính',
        () async {
      final c = await _open(inWindow);
      final d = _ctrl(c).buyFestivalPack() as AccessoryDrop?;
      expect(d, isNotNull);
      expect(d!.isNew, isTrue);
      expect(festivals.first.items.map((a) => a.id), contains(d.accessory.id));
      final s = c.read(gameControllerProvider);
      expect(s.gems, 1000 - Balance.festivalPackGems);
      expect(s.ownedLimited, [d.accessory.id]);
      expect(s.ownedAccessories, isEmpty); // không tính vào số đếm sưu tập/BXH
    });

    test('4 gói liên tiếp ra đủ 4 món khác nhau; gói thứ 5 đổi 💎 (trùng)',
        () async {
      final c = await _open(inWindow);
      for (var i = 0; i < 4; i++) {
        expect((_ctrl(c).buyFestivalPack() as AccessoryDrop).isNew, isTrue);
      }
      expect(c.read(gameControllerProvider).ownedLimited.toSet().length, 4);
      final before = c.read(gameControllerProvider).gems;
      final fifth = _ctrl(c).buyFestivalPack() as AccessoryDrop;
      expect(fifth.isNew, isFalse);
      expect(c.read(gameControllerProvider).gems,
          before - Balance.festivalPackGems + Balance.duplicateAccessoryGems);
      expect(c.read(gameControllerProvider).ownedLimited.length, 4);
    });

    test('ngoài dịp / thiếu 💎: không mua được, không trừ', () async {
      final out = await _open(festivals.first.end.millisecondsSinceEpoch + 1000);
      expect(_ctrl(out).buyFestivalPack(), isNull);
      expect(out.read(gameControllerProvider).gems, 1000);
      final poor = await _open(inWindow, gems: 79);
      expect(_ctrl(poor).buyFestivalPack(), isNull);
      expect(poor.read(gameControllerProvider).gems, 79);
    });

    test('món độc quyền trưng bày được và qua lưu/tải', () async {
      final c = await _open(inWindow);
      final id = (_ctrl(c).buyFestivalPack() as AccessoryDrop).accessory.id;
      expect(_ctrl(c).toggleEquippedAccessory(id), isTrue);
      expect(c.read(gameControllerProvider).equippedAccessories, [id]);
      final json = GameState.newGame(nowMillis: 0)..ownedLimited.add(id);
      expect(GameState.fromJson(json.toJson()).ownedLimited, [id]);
      // save cũ không có field → rỗng
      final old = json.toJson()..remove('ownedLimited');
      expect(GameState.fromJson(old).ownedLimited, isEmpty);
    });
  });
}
