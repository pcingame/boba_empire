// Android 12+ dùng hiệu ứng KÉO GIÃN (StretchingOverscrollIndicator) khi cuộn quá
// đầu/cuối danh sách. App tắt hiệu ứng này ở cấp MaterialApp — trước đây mỗi trang
// tắt riêng nên trang nào quên (vd. BXH phụ kiện) vẫn bị co giãn.
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/leaderboard/accessory_leaderboard_controller.dart';
import 'package:boba_empire/leaderboard/accessory_leaderboard_repository.dart';
import 'package:boba_empire/leaderboard/flair.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_leaderboard_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Fake extends AccessoryLeaderboardController {
  @override
  AccessoryLeaderboardViewState build() => AccessoryLeaderboardLoaded(
        entries: [
          for (var i = 1; i <= 40; i++)
            AccessoryLeaderboardEntry(
                userId: 'u$i', nickname: 'Player $i', ownedCount: 100 - i, rank: i),
        ],
        myUserId: 'u1',
        myOwnedCount: 99,
      );

  @override
  Future<void> refresh({bool silent = false}) async {}
}

class _Flair extends FlairCache {
  @override
  Map<String, String> build() => {};
}

void main() {
  for (final platform in [TargetPlatform.android]) {
    testWidgets('[$platform] BXH phụ kiện: không có hiệu ứng kéo giãn/glow khi cuộn quá',
        (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(
          GameState.newGame(nowMillis: 0)..tutorialSeen = true,
          nowMillis: 0);
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 1000),
        accessoryLeaderboardControllerProvider.overrideWith(_Fake.new),
        flairCacheProvider.overrideWith(_Flair.new),
      ]);
      await tester.pumpWidget(
          UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
      await tester.pump(const Duration(milliseconds: 300));

      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(
          builder: (_) => const AccessoryLeaderboardPage()));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(StretchingOverscrollIndicator), findsNothing,
          reason: 'Android 12+: hiệu ứng kéo giãn');
      expect(find.byType(GlowingOverscrollIndicator), findsNothing);

      // Kéo quá đầu danh sách: nội dung không bị biến dạng (không có Transform co giãn).
      final before = tester.getRect(find.text('Player 1'));
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pump(const Duration(milliseconds: 100));
      final during = tester.getRect(find.text('Player 1'));
      expect(during.height, before.height, reason: 'không bị kéo dãn chiều cao');

      await tester.pumpWidget(const SizedBox());
      c.dispose();
      // Phải trả lại TRƯỚC khi test kết thúc (addTearDown chạy quá muộn).
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
