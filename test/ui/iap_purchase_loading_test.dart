/// Regression cho bug thật: "lúc mua nạp bằng tiền thật thiếu loading để
/// hiện phương thức thanh toán" — từ lúc bấm mua tới lúc có tín hiệu về
/// (thành công/thất bại), UI từng im lặng hoàn toàn, trông như treo máy.
library;

import 'dart:async';

import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/iap/iap_products.dart';
import 'package:boba_empire/iap/iap_service.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cloud save giả: bắt đầu ở trạng thái [linked]; [link] mô phỏng việc liên kết xong.
class _FakeCloud extends CloudSaveController {
  _FakeCloud(this._linked);
  final bool _linked;
  @override
  CloudSaveViewState build() =>
      _linked ? const CloudSaveLinked('a@b.c') : const CloudSaveUnlinked();
  void link() => state = const CloudSaveLinked('a@b.c');
}

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

Future<ProviderContainer> _pump(WidgetTester tester, IapService iap,
    {bool linked = true, _FakeCloud? cloud, GameState? seed}) async {
  cloud ??= _FakeCloud(linked);
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  if (seed != null) await GameStorage(prefs).save(seed, nowMillis: 0);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
        iapServiceProvider.overrideWithValue(iap),
        cloudSaveControllerProvider.overrideWith(() => cloud!),
      ],
      child: const BobaEmpireApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(BobaEmpireApp)));
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

  Future<Finder> openShopBuyButton(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('gem-shop-button')));
    await tester.pumpAndSettle();
    final buyBtn = find.byKey(Key('iap-buy-${IapProduct.gemsSmall.id}'));
    await tester.ensureVisible(buyBtn);
    await tester.pumpAndSettle();
    return buyBtn;
  }

  testWidgets('chưa liên kết email: bấm mua hiện hộp yêu cầu, KHÔNG mua; Để sau thì thôi',
      (tester) async {
    final iap = _ControlledIap();
    await _pump(tester, iap, linked: false);
    final buyBtn = await openShopBuyButton(tester);

    await tester.tap(buyBtn);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email-gate-dialog')), findsOneWidget);
    expect(iap.buyCallCount, 0);

    await tester.tap(find.byKey(const Key('email-gate-cancel')));
    await tester.pumpAndSettle();
    expect(iap.buyCallCount, 0);
    expect(_spinnerIn(buyBtn), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('chưa liên kết: chọn Liên kết → mở màn email; liên kết xong mới mua',
      (tester) async {
    final iap = _ControlledIap();
    final cloud = _FakeCloud(false);
    await _pump(tester, iap, cloud: cloud);
    final buyBtn = await openShopBuyButton(tester);

    await tester.tap(buyBtn);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('email-gate-link')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget); // form nhập email của cloud save
    expect(iap.buyCallCount, 0);

    // Người chơi liên kết thành công rồi đóng hộp thoại (chạm ra ngoài).
    cloud.link();
    await tester.pump();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(iap.buyCallCount, 1);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('đóng màn email mà chưa liên kết → không mua', (tester) async {
    final iap = _ControlledIap();
    await _pump(tester, iap, linked: false);
    final buyBtn = await openShopBuyButton(tester);

    await tester.tap(buyBtn);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('email-gate-link')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5)); // đóng mà chưa liên kết
    await tester.pumpAndSettle();
    expect(iap.buyCallCount, 0);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('heo đất (IAP) cũng cần email: chưa liên kết thì chặn', (tester) async {
    final iap = _ControlledIap();
    await _pump(tester, iap,
        linked: false,
        seed: GameState.newGame(nowMillis: 0)..piggyGems = Balance.piggyMinBreak + 1);
    await tester.tap(find.byKey(const Key('rewards-chip')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, r'Đập $0.99'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email-gate-dialog')), findsOneWidget);
    expect(iap.buyCallCount, 0);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('heo đất khi đã liên kết email: mua luôn', (tester) async {
    final iap = _ControlledIap();
    await _pump(tester, iap,
        seed: GameState.newGame(nowMillis: 0)..piggyGems = Balance.piggyMinBreak + 1);
    await tester.tap(find.byKey(const Key('rewards-chip')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, r'Đập $0.99'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email-gate-dialog')), findsNothing);
    expect(iap.buyCallCount, 1);

    await tester.pumpWidget(const SizedBox());
  });
}
