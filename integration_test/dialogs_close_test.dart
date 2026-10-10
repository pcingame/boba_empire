// Kiểm thử THẬT trên máy ảo (animation BẬT như bản phát hành) cho việc mở/đóng các
// hộp thoại mới: Cửa hàng 💎, cổng email, Mốc nạp & VIP, Hướng dẫn VIP, BXH VIP.
//
//   flutter drive --driver=test_driver/screenshots.dart \
//     --target=integration_test/dialogs_close_test.dart -d <udid> --no-dds
//
// Giá IAP là giả (để mục nạp tiền hiện ra). Không chạm mạng.
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/iap/iap_products.dart';
import 'package:boba_empire/iap/iap_service.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/home_page.dart' as home;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PricedIap implements IapService {
  @override
  Future<Map<IapProduct, String>> loadPrices() async =>
      {for (final p in IapProduct.values) p: r'$0.99'};
  @override
  Stream<IapProduct> get purchases => const Stream.empty();
  @override
  Stream<IapProduct> get purchaseFailed => const Stream.empty();
  @override
  void buy(IapProduct product) {}
  @override
  Future<void> restore() async {}
}

Future<void> settle(WidgetTester tester, [int frames = 16]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mở/đóng các hộp thoại mới với animation thật', (tester) async {
    home.debugAutoShowTutorial = false;
    home.debugAutoShowDaily = false;
    home.debugAutoShowStory = false;
    SharedPreferences.setMockInitialValues(
        {'flutter.app_locale': 'en', 'flutter.market_intro_seen': true});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: now)
        ..tutorialSeen = true
        ..m3HowToSeen = true
        ..gems = 5000
        ..stage = 3
        ..vipExp = 3200
        ..lastSeenMillis = now
        ..firstPlayedMillis = now,
      nowMillis: now,
    );
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      iapServiceProvider.overrideWithValue(_PricedIap()),
      appVersionProvider.overrideWithValue(() async => '1.0.9'),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
    await settle(tester, 30);

    Future<void> expectOpen(Finder f, String why) async {
      await settle(tester, 20);
      expect(f, findsOneWidget, reason: 'phải MỞ: $why');
    }

    Future<void> tapClose(String why) async {
      final close = find.widgetWithText(TextButton, 'Close');
      expect(close, findsWidgets, reason: 'có nút Close: $why');
      await tester.tap(close.last);
      await settle(tester, 20);
    }

    // 1) Cửa hàng 💎: mở → Close.
    await tester.tap(find.byKey(const Key('gem-shop-button')));
    await expectOpen(find.byType(AlertDialog), 'cửa hàng 💎');
    await tapClose('cửa hàng 💎');
    expect(find.byType(AlertDialog), findsNothing, reason: 'Close đóng cửa hàng');

    // 2) Mở lại, chạm ra ngoài (barrier) cũng đóng được.
    await tester.tap(find.byKey(const Key('gem-shop-button')));
    await expectOpen(find.byType(AlertDialog), 'cửa hàng 💎 lần 2');
    await tester.tapAt(const Offset(4, 4));
    await settle(tester, 20);
    expect(find.byType(AlertDialog), findsNothing, reason: 'chạm ngoài đóng cửa hàng');

    // 3) Cổng email: bấm mua khi chưa liên kết → hộp → Cancel → đóng, cửa hàng vẫn còn.
    await tester.tap(find.byKey(const Key('gem-shop-button')));
    await expectOpen(find.byType(AlertDialog), 'cửa hàng 💎 lần 3');
    final buy = find.byKey(Key('iap-buy-${IapProduct.gemsSmall.id}'));
    await tester.ensureVisible(buy);
    await settle(tester, 10);
    await tester.tap(buy);
    await expectOpen(find.byKey(const Key('email-gate-dialog')), 'cổng email');
    await tester.tap(find.byKey(const Key('email-gate-cancel')));
    await settle(tester, 20);
    expect(find.byKey(const Key('email-gate-dialog')), findsNothing,
        reason: 'Cancel đóng cổng email');
    expect(find.text('Close'), findsOneWidget, reason: 'cửa hàng còn mở dưới cổng');

    // 4) Màn VIP → hướng dẫn → đóng → BXH VIP (trang) → back → đóng VIP → đóng cửa hàng.
    await tester.ensureVisible(find.byKey(const Key('topup-open')));
    await settle(tester, 6);
    await tester.tap(find.byKey(const Key('topup-open')));
    await expectOpen(find.byKey(const Key('vip-how-to-button')), 'màn VIP');
    await tester.tap(find.byKey(const Key('vip-how-to-button')));
    await expectOpen(find.byKey(const Key('vip-how-to-close')), 'hướng dẫn VIP');
    await tester.tap(find.byKey(const Key('vip-how-to-close')));
    await settle(tester, 20);
    expect(find.byKey(const Key('vip-how-to-close')), findsNothing,
        reason: 'đóng hướng dẫn VIP');
    await tester.ensureVisible(find.byKey(const Key('vip-open-leaderboard')));
    await settle(tester, 6);
    await tester.tap(find.byKey(const Key('vip-open-leaderboard')));
    await settle(tester, 40);
    expect(find.byType(BackButton), findsOneWidget, reason: 'BXH VIP mở thành trang');
    await tester.tap(find.byType(BackButton));
    await settle(tester, 30);
    expect(find.byKey(const Key('vip-how-to-button')), findsOneWidget,
        reason: 'back từ BXH VIP về màn VIP');
    await tapClose('màn VIP'); // đóng màn VIP
    expect(find.byKey(const Key('vip-how-to-button')), findsNothing);
    await tapClose('cửa hàng 💎'); // đóng cửa hàng
    expect(find.byType(AlertDialog), findsNothing, reason: 'đóng hết hộp thoại');
  });
}
