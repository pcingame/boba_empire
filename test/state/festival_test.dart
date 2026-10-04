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

  group('lịch dịp lễ', () {
    // Ngày lễ chính (đã đối chiếu âm lịch: Tết 6/2/2027, Trung Thu 15/9/2027)
    // phải nằm TRONG cửa sổ bán của dịp tương ứng.
    final holidays = {
      'halloween': DateTime.utc(2026, 10, 31),
      'christmas': DateTime.utc(2026, 12, 24),
      'new_year': DateTime.utc(2027, 1, 1),
      'tet': DateTime.utc(2027, 2, 6),
      'valentine': DateTime.utc(2027, 2, 14),
      'womens_day': DateTime.utc(2027, 3, 8),
      'mid_autumn': DateTime.utc(2027, 9, 15),
    };
    test('mỗi dịp bao trùm đúng ngày lễ chính của nó', () {
      expect(festivals.map((f) => f.id).toSet(), holidays.keys.toSet());
      holidays.forEach((id, day) {
        expect(activeFestival(day)?.id, id, reason: 'ngày lễ của $id');
        expect(activeFestival(day.add(const Duration(hours: 23, minutes: 59)))?.id, id);
      });
    });

    test('quét từng ngày 10/2026–12/2027: tối đa 1 dịp, mỗi dịp liên tục', () {
      final seen = <String>[];
      for (var d = DateTime.utc(2026, 10, 1);
          d.isBefore(DateTime.utc(2028, 1, 1));
          d = d.add(const Duration(days: 1))) {
        final a = activeFestival(d);
        final matches = festivals.where(
            (f) => !d.isBefore(f.start) && d.isBefore(f.end)).length;
        expect(matches, lessThanOrEqualTo(1), reason: '$d');
        if (a != null && (seen.isEmpty || seen.last != a.id)) seen.add(a.id);
      }
      // Mỗi dịp xuất hiện đúng 1 đoạn liên tục (không bị cắt đôi).
      expect(seen.toSet().length, seen.length);
      expect(seen.length, festivals.length);
    });

    test('mỗi dịp có đủ độ hiếm đa dạng và đúng 1 huyền thoại', () {
      for (final f in festivals) {
        expect(f.items.where((a) => a.rarity == AccessoryRarity.legendary).length, 1,
            reason: f.id);
        expect(f.items.map((a) => a.rarity).toSet().length, greaterThanOrEqualTo(2));
      }
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

  group('mọi dịp mua được trọn bộ', () {
    for (final f in festivals) {
      test('${f.id}: 4 gói = đủ 4 món, cả 4 đều tra tên/emoji được', () async {
        final c = await _open(f.start.millisecondsSinceEpoch + 1);
        for (var i = 0; i < 4; i++) {
          _ctrl(c).buyFestivalPack();
        }
        expect(c.read(gameControllerProvider).ownedLimited.toSet(),
            f.items.map((a) => a.id).toSet());
        for (final a in f.items) {
          expect(accessoryById(a.id).emoji, a.emoji);
        }
      });
    }
  });

  test('50 lượt mua ngẫu nhiên: không bao giờ vượt 4 món/dịp, 💎 không âm',
      () async {
    final c = await _open(inWindow, gems: 5000);
    for (var i = 0; i < 50; i++) {
      _ctrl(c).buyFestivalPack();
      final s = c.read(gameControllerProvider);
      expect(s.ownedLimited.length, lessThanOrEqualTo(4));
      expect(s.gems, greaterThanOrEqualTo(0));
    }
  });

  test('đóng/mở lại app: món độc quyền + trưng bày được giữ nguyên', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final id = festivals.first.items.last.id; // huyền thoại
    await GameStorage(prefs).save(
        GameState.newGame(nowMillis: inWindow)
          ..ownedLimited.add(id)
          ..equippedAccessories.add(id),
        nowMillis: inWindow);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => inWindow),
    ]);
    addTearDown(c.dispose);
    final s = c.read(gameControllerProvider);
    expect(s.ownedLimited, [id]);
    expect(s.equippedAccessories, [id]); // load cleanup không xoá món độc quyền
  });
}
