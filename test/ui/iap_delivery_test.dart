import 'dart:async';

import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/iap/iap_products.dart';
import 'package:boba_empire/iap/iap_service.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// IapService giả có thể bơm sản phẩm vào stream để test luồng trao thưởng.
class _FakeIap implements IapService {
  final StreamController<IapProduct> _c =
      StreamController<IapProduct>.broadcast();
  @override
  Stream<IapProduct> get purchases => _c.stream;
  @override
  Stream<IapProduct> get purchaseFailed => const Stream.empty();
  @override
  Future<Map<IapProduct, String>> loadPrices() async => const {};
  @override
  void buy(IapProduct product) {}
  @override
  Future<void> restore() async {}
  void emit(IapProduct p) => _c.add(p);
}

Future<ProviderContainer> _pump(WidgetTester tester, _FakeIap iap) async {
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
  await tester.pump();
  return ProviderScope.containerOf(tester.element(find.byType(HomePage)));
}

void main() {
  testWidgets('mua gói gems nhỏ → +100 Kim Cương', (tester) async {
    final iap = _FakeIap();
    final container = await _pump(tester, iap);
    expect(container.read(gameControllerProvider).gems, 0);

    iap.emit(IapProduct.gemsSmall);
    await tester.pump();

    expect(container.read(gameControllerProvider).gems, 100);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mua gói gems lớn → cộng đúng số của bậc đó', (tester) async {
    final iap = _FakeIap();
    final container = await _pump(tester, iap);

    iap.emit(IapProduct.gemsLarge);
    await tester.pump();

    expect(container.read(gameControllerProvider).gems, IapProduct.gemsLarge.gems);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mua gỡ QC → bật cờ adsRemoved', (tester) async {
    final iap = _FakeIap();
    final container = await _pump(tester, iap);

    iap.emit(IapProduct.removeAds);
    await tester.pump();

    expect(container.read(gameControllerProvider).adsRemoved, true);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mua gói gems huge/mega → cộng đúng số của bậc đó', (tester) async {
    final iap = _FakeIap();
    final container = await _pump(tester, iap);

    iap.emit(IapProduct.gemsHuge);
    await tester.pump();
    iap.emit(IapProduct.gemsMega);
    await tester.pump();

    expect(container.read(gameControllerProvider).gems,
        IapProduct.gemsHuge.gems + IapProduct.gemsMega.gems);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('kho lạnh vĩnh viễn: +8h trần offline, phát lại không cộng thêm',
      (tester) async {
    final iap = _FakeIap();
    final container = await _pump(tester, iap);
    final notifier = container.read(gameControllerProvider.notifier);
    final before = notifier.currentOfflineCapSeconds;

    iap.emit(IapProduct.coldStorage);
    await tester.pump();
    iap.emit(IapProduct.coldStorage); // restore
    await tester.pump();

    expect(container.read(gameControllerProvider).coldStorageOwned, true);
    expect(notifier.currentOfflineCapSeconds,
        before + Balance.coldStorageBonusSeconds);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mua mới cộng điểm nạp; khôi phục gói vĩnh viễn không cộng lại',
      (tester) async {
    final iap = _FakeIap();
    final container = await _pump(tester, iap);

    iap.emit(IapProduct.removeAds);
    await tester.pump();
    expect(container.read(gameControllerProvider).topupPoints,
        IapProduct.removeAds.topup);

    iap.emit(IapProduct.removeAds); // restore lúc mở app
    await tester.pump();
    expect(container.read(gameControllerProvider).topupPoints,
        IapProduct.removeAds.topup);

    iap.emit(IapProduct.gemsMega); // gói tiêu hao: lần nào cũng mới
    await tester.pump();
    iap.emit(IapProduct.gemsMega);
    await tester.pump();
    expect(container.read(gameControllerProvider).topupPoints,
        IapProduct.removeAds.topup + 2 * IapProduct.gemsMega.topup);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('combo gỡ QC + x2: bật cả hai cờ', (tester) async {
    final iap = _FakeIap();
    final container = await _pump(tester, iap);

    iap.emit(IapProduct.comboNoAdsX2);
    await tester.pump();

    final s = container.read(gameControllerProvider);
    expect(s.adsRemoved, true);
    expect(s.doubleIncomeOwned, true);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('gói khởi động chỉ trao một lần dù phát lại (restore)',
      (tester) async {
    final iap = _FakeIap();
    final container = await _pump(tester, iap);

    iap.emit(IapProduct.starterPack);
    await tester.pump();
    expect(container.read(gameControllerProvider).gems, 300);
    expect(container.read(gameControllerProvider).starterPackOwned, true);

    // Phát lại (giống restore lúc mở app): không cộng thêm.
    iap.emit(IapProduct.starterPack);
    await tester.pump();
    expect(container.read(gameControllerProvider).gems, 300);

    await tester.pumpWidget(const SizedBox());
  });
}
