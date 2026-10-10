// Chụp ảnh các gói IAP trong Cửa hàng 💎 để gửi App Review (mỗi gói một ảnh) + màn VIP.
// Giá là GIÁ GIẢ cho ảnh, KHÔNG phải giá bán thật — nhớ khớp với giá đặt trên ASC.
//
//   SHOT_DIR=build/iap_review_shots flutter drive --driver=test_driver/screenshots.dart \
//     --target=integration_test/iap_review_shots_test.dart -d <udid>
//
// Cùng khung với collection_160_test.dart (thao tác chạy BÊN TRONG app). Không chạm mạng.
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

/// Giá hiển thị trong ảnh (USD).
const _prices = {
  IapProduct.gemsSmall: r'$0.99',
  IapProduct.gemsMedium: r'$4.99',
  IapProduct.gemsLarge: r'$9.99',
  IapProduct.gemsHuge: r'$14.99',
  IapProduct.gemsMega: r'$19.99',
  IapProduct.removeAds: r'$2.99',
  IapProduct.doubleIncome: r'$4.99',
  IapProduct.piggyBreak: r'$1.99',
  IapProduct.vip30: r'$4.99',
  IapProduct.starterPack: r'$0.99',
  IapProduct.coldStorage: r'$2.99',
  IapProduct.comboNoAdsX2: r'$5.99',
};

class _PricedIap implements IapService {
  @override
  Future<Map<IapProduct, String>> loadPrices() async => _prices;
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
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Ảnh các gói IAP cho App Review', (tester) async {
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
      ..m3HowToSeen = true
      ..gems = 250
      ..stage = 3
      ..vipExp = 3200 // VIP 3 để màn VIP có nội dung
      ..lastSeenMillis = now
      ..firstPlayedMillis = now;
    await GameStorage(prefs).save(save, nowMillis: now);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      iapServiceProvider.overrideWithValue(_PricedIap()),
      appVersionProvider.overrideWithValue(() async => '1.0.9'),
    ]);
    addTearDown(c.dispose);

    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
    await settle(tester);

    Future<void> shoot(String name) async {
      await settle(tester, 6);
      debugPrint('SHOT $name');
      await binding.takeScreenshot(name);
    }

    await tester.tap(find.byKey(const Key('gem-shop-button')));
    await settle(tester, 24);

    // Mỗi gói một ảnh: cuộn gói đó lên giữa khung nhìn rồi chụp.
    var n = 0;
    for (final p in IapProduct.values) {
      final tile = find.byKey(Key('iap-buy-${p.id}'));
      if (tile.evaluate().isEmpty) continue; // piggy nằm ở hộp "Kiếm thêm", không ở đây
      // Đặt hàng của gói ở giữa hộp thoại (alignment 0.45) cho khỏi bị cắt mép trên.
      await Scrollable.ensureVisible(tester.element(tile),
          alignment: 0.45, duration: const Duration(milliseconds: 200));
      await settle(tester, 10);
      await shoot('iap_${(++n).toString().padLeft(2, '0')}_${p.id}');
    }

    // Màn Mốc nạp & VIP.
    await tester.ensureVisible(find.byKey(const Key('topup-open')));
    await settle(tester, 6);
    await tester.tap(find.byKey(const Key('topup-open')));
    await settle(tester, 24);
    await shoot('vip_screen');
  });
}
