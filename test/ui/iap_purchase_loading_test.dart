/// Regression cho bug thật: "lúc mua nạp bằng tiền thật thiếu loading để
/// hiện phương thức thanh toán" — từ lúc bấm mua tới lúc có tín hiệu về
/// (thành công/thất bại), UI từng im lặng hoàn toàn, trông như treo máy.
library;

import 'dart:async';

import 'package:boba_empire/iap/iap_products.dart';
import 'package:boba_empire/iap/iap_service.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// IapService giả: có giá (để nút mua hiện ra) + 2 stream điều khiển được để
/// mô phỏng thành công/thất bại sau khi bấm mua, giống RealIapService thật.
class _ControlledIap implements IapService {
  final _purchases = StreamController<IapProduct>.broadcast();
  final _failed = StreamController<IapProduct>.broadcast();
  int buyCallCount = 0;

  @override
  Future<Map<IapProduct, String>> loadPrices() async =>
      {for (final p in IapProduct.values) p: r'$0.99'};
  @override
  Stream<IapProduct> get purchases => _purchases.stream;
  @override
  Stream<IapProduct> get purchaseFailed => _failed.stream;
  @override
  void buy(IapProduct product) => buyCallCount++;
  @override
  Future<void> restore() async {}

  void succeed(IapProduct p) => _purchases.add(p);
  void fail(IapProduct p) => _failed.add(p);
}

Future<void> _pump(WidgetTester tester, IapService iap) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
        iapServiceProvider.overrideWithValue(iap),
      ],
      child: const BobaEmpireApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _spinnerIn(Finder button) => find.descendant(
      of: button,
      matching: find.byType(CircularProgressIndicator),
    );

void main() {
  testWidgets(
      'bấm mua hiện vòng xoay NGAY (không im lặng) tới khi có tín hiệu '
      'thành công', (tester) async {
    final iap = _ControlledIap();
    await _pump(tester, iap);

    await tester.tap(find.byKey(const Key('gem-shop-button')));
    await tester.pumpAndSettle();

    final buyBtn = find.byKey(Key('iap-buy-${IapProduct.gemsSmall.id}'));
    expect(buyBtn, findsOneWidget);
    expect(_spinnerIn(buyBtn), findsNothing);

    // Mục IAP nằm cuối 1 dialog cuộn được — cuộn cho chắc trước khi bấm
    // (dialog đủ nội dung có thể để nút ngoài khung nhìn ban đầu).
    await tester.ensureVisible(buyBtn);
    await tester.pumpAndSettle();
    await tester.tap(buyBtn);
    await tester.pump(); // 1 frame ngay sau khi bấm — không đợi network thật
    expect(iap.buyCallCount, 1);
    expect(_spinnerIn(buyBtn), findsOneWidget);

    iap.succeed(IapProduct.gemsSmall);
    await tester.pump();
    expect(_spinnerIn(buyBtn), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mua thất bại/huỷ cũng tắt vòng xoay (không kẹt loading mãi)',
      (tester) async {
    final iap = _ControlledIap();
    await _pump(tester, iap);

    await tester.tap(find.byKey(const Key('gem-shop-button')));
    await tester.pumpAndSettle();

    final buyBtn = find.byKey(Key('iap-buy-${IapProduct.gemsSmall.id}'));
    await tester.ensureVisible(buyBtn);
    await tester.pumpAndSettle();
    await tester.tap(buyBtn);
    await tester.pump();
    expect(_spinnerIn(buyBtn), findsOneWidget);

    iap.fail(IapProduct.gemsSmall);
    await tester.pump();
    expect(_spinnerIn(buyBtn), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
