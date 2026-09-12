/// Test cho phần "đồng bộ cloud phát hiện xung đột sau lần liên kết đầu"
/// (fix cho known-issues-backlog memory mục 7 — trước đây mỗi lần lưu nền
/// ghi đè cloud mù, không kiểm tra gì). Chỉ test được phần LOGIC/BOOKKEEPING
/// cục bộ (GameController.applyCloudSyncVersion/cloudConflictPending/
/// restoreFromCloud) — phần gọi Supabase thật (CloudSaveRepository.
/// pushIfCurrent) đã verify trực tiếp bằng curl vào project sống, giống mọi
/// tính năng Supabase khác trong session này (không có hạ tầng mock
/// SupabaseClient trong codebase).
library;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_controller.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<
    ({
      GameController ctrl,
      double Function() money,
      GameStorage storage,
      SharedPreferences prefs,
    })> _boot(GameState seed) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = GameStorage(prefs);
  await storage.save(seed, nowMillis: 0);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
  ]);
  addTearDown(container.dispose);
  return (
    ctrl: container.read(gameControllerProvider.notifier),
    money: () => container.read(gameControllerProvider).money,
    storage: storage,
    prefs: prefs,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mặc định (chưa từng đồng bộ): cloudConflictPending = false', () async {
    final b = await _boot(GameState.newGame(nowMillis: 0));
    expect(b.ctrl.cloudConflictPending, isFalse);
  });

  test(
      'applyCloudSyncVersion ghi version + xoá cờ xung đột, lưu xuống đĩa '
      'độc lập với save chính', () async {
    final b = await _boot(GameState.newGame(nowMillis: 0));
    // Giả lập đã từng phát hiện xung đột từ 1 lần lưu nền trước đó.
    await b.storage.saveCloudConflictPending(true);

    b.ctrl.applyCloudSyncVersion(5);
    expect(b.ctrl.cloudConflictPending, isFalse);

    // Đợi các Future.unawaited bên trong applyCloudSyncVersion chạy xong.
    await Future<void>.delayed(Duration.zero);
    expect(b.storage.loadCloudVersion(), 5);
    expect(b.storage.loadCloudConflictPending(), isFalse);
  });

  test(
      'restoreFromCloud: nạp save mới + ghi version cloud + xoá cờ xung đột',
      () async {
    final b = await _boot(GameState.newGame(nowMillis: 0)..money = 10);
    await b.storage.saveCloudConflictPending(true);

    final cloudJson = (GameState.newGame(nowMillis: 0)..money = 9999).toJson();
    b.ctrl.restoreFromCloud(cloudJson, cloudVersion: 42);

    expect(b.money(), 9999); // đã nạp save từ cloud
    expect(b.ctrl.cloudConflictPending, isFalse);

    await Future<void>.delayed(Duration.zero);
    expect(b.storage.loadCloudVersion(), 42);
    expect(b.storage.loadCloudConflictPending(), isFalse);
  });
}
