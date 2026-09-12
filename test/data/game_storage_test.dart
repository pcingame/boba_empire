import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameStorage> _storage() async {
  SharedPreferences.setMockInitialValues({});
  return GameStorage(await SharedPreferences.getInstance());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('chưa có save -> load trả null', () async {
    final storage = await _storage();
    expect(storage.load(), isNull);
  });

  test('save rồi load giữ nguyên trạng thái', () async {
    final storage = await _storage();
    final state = GameState.newGame(nowMillis: 0)
      ..money = 1234.5
      ..gems = 3
      ..tapValue = 2
      ..levels['tra_den'] = 5
      ..lifetimeEarnings = 9999
      ..prestigeStars = 7;

    await storage.save(state, nowMillis: 5000);
    final loaded = storage.load()!;

    expect(loaded.money, 1234.5);
    expect(loaded.gems, 3);
    expect(loaded.tapValue, 2);
    expect(loaded.levels['tra_den'], 5);
    expect(loaded.lifetimeEarnings, 9999);
    expect(loaded.prestigeStars, 7);
  });

  test('save đóng dấu lastSeenMillis = thời điểm lưu', () async {
    final storage = await _storage();
    final state = GameState.newGame(nowMillis: 0);
    await storage.save(state, nowMillis: 42000);
    expect(state.lastSeenMillis, 42000); // mutate tại chỗ
    expect(storage.load()!.lastSeenMillis, 42000);
  });

  test('save rồi load giữ nguyên firstPlayedMillis/storyCompleteSeconds',
      () async {
    final storage = await _storage();
    final state = GameState.newGame(nowMillis: 1000)
      ..storyCompleteSeconds = 12345;
    await storage.save(state, nowMillis: 2000);
    final loaded = storage.load()!;
    expect(loaded.firstPlayedMillis, 1000);
    expect(loaded.storyCompleteSeconds, 12345);
  });

  test(
      'save cũ (trước khi có firstPlayedMillis) -> tự lấy lastSeenMillis làm '
      'mốc gần đúng', () {
    final oldSaveJson = (GameState.newGame(nowMillis: 777)
          ..lastSeenMillis = 999)
        .toJson()
      ..remove('firstPlayedMillis');
    final loaded = GameState.fromJson(oldSaveJson);
    expect(loaded.firstPlayedMillis, 999); // = lastSeenMillis, không phải 777
    expect(loaded.storyCompleteSeconds, isNull);
  });

  group('bookkeeping đồng bộ cloud (cố ý tách khỏi GameState)', () {
    test('mặc định: version=0, chưa có xung đột', () async {
      final storage = await _storage();
      expect(storage.loadCloudVersion(), 0);
      expect(storage.loadCloudConflictPending(), isFalse);
    });

    test('lưu/đọc version và cờ xung đột độc lập, không đụng save chính',
        () async {
      final storage = await _storage();
      final state = GameState.newGame(nowMillis: 0)..money = 500;
      await storage.save(state, nowMillis: 0);

      await storage.saveCloudVersion(7);
      await storage.saveCloudConflictPending(true);

      expect(storage.loadCloudVersion(), 7);
      expect(storage.loadCloudConflictPending(), isTrue);
      expect(storage.load()!.money, 500); // save chính không bị ảnh hưởng
    });
  });

  test('vòng save -> load -> offline tính đúng khoảng vắng', () async {
    final storage = await _storage();
    final state = GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2;
    // tra_den: 0.5/level/s * 2 = 1.0/s (chưa prestige).

    await storage.save(state, nowMillis: 10000); // lastSeen = 10s
    final loaded = storage.load()!;
    final earned = applyOfflineEarnings(loaded, 70000); // vắng 60s
    expect(earned, closeTo(60, 1e-9));
    expect(loaded.money, closeTo(60, 1e-9));
  });

  test('save hỏng -> load trả null thay vì ném lỗi', () async {
    SharedPreferences.setMockInitialValues({'game_state': 'không-phải-json{'});
    final storage = GameStorage(await SharedPreferences.getInstance());
    expect(storage.load(), isNull);
  });

  test('clear xóa save', () async {
    final storage = await _storage();
    await storage.save(GameState.newGame(nowMillis: 0), nowMillis: 0);
    expect(storage.load(), isNotNull);
    await storage.clear();
    expect(storage.load(), isNull);
  });
}
