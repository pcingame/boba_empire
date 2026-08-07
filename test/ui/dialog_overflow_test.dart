import 'dart:ui' as ui;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/iap/iap_products.dart';
import 'package:boba_empire/iap/iap_service.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Trả giá cho mọi sản phẩm để mục IAP (mô tả dài) render đầy đủ.
class _PricedIap implements IapService {
  @override
  Future<Map<IapProduct, String>> loadPrices() async =>
      {for (final p in IapProduct.values) p: r'$0.99'};
  @override
  Stream<IapProduct> get purchases => const Stream.empty();
  @override
  void buy(IapProduct product) {}
  @override
  Future<void> restore() async {}
}

/// Bơm app ở [locale] với [seed], màn 400×800 (bề rộng chật nhất). Nếu bất kỳ
/// dialog nào tràn, framework ném exception → test tự fail.
Future<void> _pump(
  WidgetTester tester, {
  required String locale,
  required GameState seed,
  int clock = 0,
  IapService? iap,
}) async {
  tester.platformDispatcher.localesTestValue = [ui.Locale(locale)];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => clock),
        if (iap != null) iapServiceProvider.overrideWithValue(iap),
      ],
      child: const BobaEmpireApp(),
    ),
  );
  await tester.pumpAndSettle();
}

// Các ngôn ngữ tầng 2 (chuỗi dài hơn vi/en).
const _locales = ['pt', 'es', 'id', 'th'];

void main() {
  for (final locale in _locales) {
    testWidgets('[$locale] dialog Nhượng quyền không tràn', (tester) async {
      await _pump(
        tester,
        locale: locale,
        seed: GameState.newGame(nowMillis: 0)
          ..money = 500
          ..levels['tra_den'] = 3
          ..lifetimeEarnings = 1000000, // đủ Sao → hiện nút xác nhận đầy chữ
      );
      await tester.tap(find.byKey(const Key('prestige-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('prestige-confirm')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('[$locale] Cửa hàng (kèm IAP) không tràn', (tester) async {
      await _pump(
        tester,
        locale: locale,
        seed: GameState.newGame(nowMillis: 0)..gems = 5,
        iap: _PricedIap(),
      );
      await tester.tap(find.byKey(const Key('gem-shop-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('iap-buy-boba_starter_pack')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('[$locale] bảng Cách chơi không tràn', (tester) async {
      await _pump(
        tester,
        locale: locale,
        seed: GameState.newGame(nowMillis: 0),
      );
      await tester.tap(find.byKey(const Key('how-to-play-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('how-to-play-close')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('[$locale] popup offline không tràn', (tester) async {
      await _pump(
        tester,
        locale: locale,
        seed: GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2,
        clock: 60000, // mở sau 60s → có tiền offline, popup tự hiện
      );
      expect(find.byKey(const Key('offline-double')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
