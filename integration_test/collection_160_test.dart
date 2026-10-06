// Kiểm thử THẬT trên máy ảo cho Kho phụ kiện 160 món: dải mốc cuộn ngang, hướng
// dẫn, lưới, trưng bày, hiệu ứng nhận món — animation BẬT như bản phát hành.
//
//   SHOT_DIR=/tmp/shots flutter drive --driver=test_driver/screenshots.dart \
//     --target=integration_test/collection_160_test.dart -d <udid>
//
// Cùng khung với screenshots_test.dart (thao tác chạy BÊN TRONG app, không cần
// quyền Accessibility). Không chạm mạng: Chợ giả, không đăng nhập Supabase.
import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/collection_milestones.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/market/accessory_market_controller.dart';
import 'package:boba_empire/market/market_highlight.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/home_page.dart' as home;
import 'package:boba_empire/ui/widgets/accessory_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EmptyMarket extends AccessoryMarketController {
  @override
  AccessoryMarketViewState build() => const AccessoryMarketLoaded(
        listings: [],
        myListings: [],
        walletBalance: 0,
        myUserId: 'me',
        recentSales: [],
      );

  @override
  Future<void> refresh({bool silent = false}) async {}
}

Future<void> settle(WidgetTester tester, [int frames = 16]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _dismissBlockingDialog(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    if (find.byType(Dialog).evaluate().isEmpty) return;
    final btn = find.descendant(
        of: find.byType(Dialog), matching: find.byType(TextButton));
    if (btn.evaluate().isEmpty) return;
    await tester.tap(btn.first, warnIfMissed: false);
    await settle(tester);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Kho 160 món trên máy ảo', (tester) async {
    home.debugAutoShowTutorial = false;
    home.debugAutoShowDaily = false;
    home.debugAutoShowStory = false;
    try {
      await binding.convertFlutterSurfaceToImage();
    } catch (_) {}

    SharedPreferences.setMockInitialValues(
        {'flutter.app_locale': 'en', 'flutter.market_intro_seen': true});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final save = GameState.newGame(nowMillis: now)
      ..tutorialSeen = true
      ..starterPackClaimed = true
      ..m3HowToSeen = true
      ..adsRemoved = true
      ..gems = 5000
      ..stage = 3
      ..collectionMilestonesClaimed.addAll([10, 25, 40, 50])
      ..ownedAccessories.addAll(accessories.map((a) => a.id))
      ..lastSeenMillis = now
      ..firstPlayedMillis = now;
    await GameStorage(prefs).save(save, nowMillis: now);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      accessoryMarketControllerProvider.overrideWith(_EmptyMarket.new),
      marketHighlightProvider.overrideWith((ref) async => null),
      appVersionProvider.overrideWithValue(() async => '1.0.5'),
    ]);
    addTearDown(c.dispose);

    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
    await settle(tester);
    await _dismissBlockingDialog(tester);

    Future<void> shoot(String name) async {
      await settle(tester, 6);
      debugPrint('SHOT $name');
      await binding.takeScreenshot(name);
    }

    // --- Mở Kho ---
    await tester.tap(find.byKey(const Key('collection-chip')));
    await settle(tester, 24);
    expect(find.text('160/160 collected'), findsOneWidget);
    await shoot('a_top');

    // --- Dải mốc: tự cuộn tới mốc 80 (đã nhận 4 mốc đầu), cuộn hết tới 160 ---
    final strip = find.byType(SingleChildScrollView).first;
    for (final m in collectionMilestones.where((m) => m.count >= 80)) {
      expect(find.byKey(Key('milestone-claim-${m.count}')), findsOneWidget,
          reason: 'mốc ${m.count} nhận được');
    }
    final r80 = tester.getRect(find.byKey(const Key('milestone-claim-80')));
    final vp = tester.getRect(strip);
    expect(r80.left, greaterThanOrEqualTo(vp.left - 1),
        reason: 'mốc kế tiếp được cuộn vào khung nhìn');
    expect(r80.right, lessThanOrEqualTo(vp.right + 1));
    await tester.drag(strip, const Offset(-600, 0));
    await settle(tester, 20);
    final r160 = tester.getRect(find.byKey(const Key('milestone-claim-160')));
    expect(r160.right, lessThanOrEqualTo(vp.right + 1),
        reason: 'cuộn hết thì thấy mốc 160');
    await shoot('b_strip_end');

    // --- Hướng dẫn ---
    await tester.tap(find.byKey(const Key('accessory-how-to-button')));
    await settle(tester, 20);
    expect(find.text('Collecting guide'), findsOneWidget);
    await shoot('c_howto');
    await tester.tap(find.byKey(const Key('accessory-how-to-close')));
    await settle(tester, 20);

    // --- Cuộn lưới qua cả 160 món, không ném lỗi ---
    final list = find.byType(Scrollable).first;
    var step = 0;
    for (var i = 0; i < 80; i++) {
      await tester.drag(list, const Offset(0, -700));
      await settle(tester, 4);
      if (i == 8 || i == 18 || i == 28) await shoot('d_scroll_${step++}');
    }
    expect(tester.takeException(), isNull);

    // --- Trưng bày: chạm món Huyền thoại mới ---
    await tester.scrollUntilVisible(
        find.byKey(const Key('accessory-cell-genie')), -300,
        scrollable: list);
    await settle(tester, 20);
    await shoot('e_legendary_new');
    await tester.tap(find.byKey(const Key('accessory-cell-genie')));
    await settle(tester, 20);
    expect(c.read(gameControllerProvider).equippedAccessories, ['genie']);
    expect(find.text('📌'), findsWidgets);
    await shoot('f_equipped');

    // --- Hiệu ứng nhận món ---
    final ctx = tester.element(find.byType(Scaffold).first);
    playAccessoryReveal(ctx, AccessoryDrop(accessoryById('mermaid'), isNew: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    // Tên món cũng có trong lưới phía sau → dùng nhãn "NEW" (chỉ overlay có).
    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('Mermaid'), findsNWidgets(2));
    await shoot('g_reveal');
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('NEW'), findsNothing, reason: 'hiệu ứng tự gỡ');
    expect(find.text('Mermaid'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
