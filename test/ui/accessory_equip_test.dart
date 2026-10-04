/// Trưng bày phụ kiện quanh cốc: lưu/đọc save, bật-tắt có giới hạn, tự gỡ khi bán nốt,
/// chạm trong Kho, và hiện ở màn chính (thuần trang trí, không buff gì).
library;

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/ui/accessory_inventory_page.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container({GameState? seed}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  if (seed != null) await GameStorage(prefs).save(seed, nowMillis: 0);
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
  ]);
}

void main() {
  group('GameState', () {
    test('equippedAccessories lưu/đọc được; save cũ thiếu trường → rỗng', () {
      final s = GameState.newGame(nowMillis: 0)
        ..ownedAccessories.addAll(['dragon', 'galaxy'])
        ..equippedAccessories.addAll(['dragon', 'galaxy']);
      expect(GameState.fromJson(s.toJson()).equippedAccessories,
          ['dragon', 'galaxy']);
      expect(
          GameState.fromJson(s.toJson()..remove('equippedAccessories'))
              .equippedAccessories,
          isEmpty);
    });

    test('dữ liệu hỏng không làm mất save (bỏ phần tử sai kiểu / sai dạng)', () {
      final json = GameState.newGame(nowMillis: 0).toJson();
      json['equippedAccessories'] = ['dragon', 5, null, 'galaxy'];
      expect(GameState.fromJson(json).equippedAccessories, ['dragon', 'galaxy']);
      json['equippedAccessories'] = 'not-a-list';
      expect(GameState.fromJson(json).equippedAccessories, isEmpty);
    });
  });

  group('GameController', () {
    test('bật/tắt: chỉ món ĐANG CÓ, tối đa ${Balance.maxEquippedAccessories}', () async {
      final c = await _container(
        seed: GameState.newGame(nowMillis: 0)
          ..ownedAccessories.addAll(['mint_leaf', 'cupcake', 'cookie', 'dragon']),
      );
      addTearDown(c.dispose);
      final ctrl = c.read(gameControllerProvider.notifier);
      List<String> eq() => c.read(gameControllerProvider).equippedAccessories;

      expect(ctrl.toggleEquippedAccessory('galaxy'), isFalse); // chưa có
      expect(eq(), isEmpty);

      expect(ctrl.toggleEquippedAccessory('mint_leaf'), isTrue);
      expect(ctrl.toggleEquippedAccessory('cupcake'), isTrue);
      expect(ctrl.toggleEquippedAccessory('cookie'), isTrue);
      expect(eq(), ['mint_leaf', 'cupcake', 'cookie']);

      expect(ctrl.toggleEquippedAccessory('dragon'), isFalse); // đã đủ 3
      expect(eq().length, 3);

      expect(ctrl.toggleEquippedAccessory('cupcake'), isTrue); // bỏ một món
      expect(eq(), ['mint_leaf', 'cookie']);
      expect(ctrl.toggleEquippedAccessory('dragon'), isTrue); // giờ thêm được
    });

    test('bán nốt bản cuối → tự gỡ; bán bản DƯ thì vẫn trưng bày', () async {
      final c = await _container(
        seed: GameState.newGame(nowMillis: 0)
          ..ownedAccessories.addAll(['dragon'])
          ..accessorySpares['dragon'] = 1
          ..equippedAccessories.add('dragon'),
      );
      addTearDown(c.dispose);
      final ctrl = c.read(gameControllerProvider.notifier);
      List<String> eq() => c.read(gameControllerProvider).equippedAccessories;

      ctrl.removeOwnedAccessoryLocally('dragon'); // bán bản dư
      expect(eq(), ['dragon']);
      ctrl.removeOwnedAccessoryLocally('dragon'); // bán bản cuối
      expect(eq(), isEmpty);
      expect(c.read(gameControllerProvider).ownedAccessories, isEmpty);
    });

    test('nạp save: bỏ món không còn sở hữu và cắt về tối đa', () async {
      final c = await _container(
        seed: GameState.newGame(nowMillis: 0)
          ..ownedAccessories.addAll(['mint_leaf', 'cupcake', 'cookie', 'dragon'])
          ..equippedAccessories
              .addAll(['galaxy', 'mint_leaf', 'cupcake', 'cookie', 'dragon']),
      );
      addTearDown(c.dispose);
      final eq = c.read(gameControllerProvider).equippedAccessories;
      expect(eq, ['mint_leaf', 'cupcake', 'cookie']); // galaxy bỏ; dragon vượt 3
    });
  });

  testWidgets('màn chính: phụ kiện đang trưng bày hiện quanh cốc; bỏ thì biến mất',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = await _container(
      seed: GameState.newGame(nowMillis: 0)
        ..ownedAccessories.addAll(['dragon', 'galaxy']),
    );
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c, child: const BobaEmpireApp()));
    await tester.pumpAndSettle();
    final floaters = find.byKey(const Key('equipped-floaters'));
    Finder emoji(String e) =>
        find.descendant(of: floaters, matching: find.text(e));
    expect(emoji('🐉'), findsNothing);

    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.toggleEquippedAccessory('dragon');
    ctrl.toggleEquippedAccessory('galaxy');
    await tester.pump();
    expect(emoji('🐉'), findsOneWidget);
    expect(emoji('🌌'), findsOneWidget);

    ctrl.toggleEquippedAccessory('dragon');
    await tester.pump();
    expect(emoji('🐉'), findsNothing);
    expect(emoji('🌌'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('màn chính: nút Sưu tập ngang hàng Ưu đãi/Nhiệm vụ, mở Kho, chấm đỏ khi có mốc',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3); // máy hẹp
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await _container(
      seed: GameState.newGame(nowMillis: 0)
        ..ownedAccessories.addAll(accessories.take(10).map((a) => a.id)),
    );
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c, child: const BobaEmpireApp()));
    await tester.pumpAndSettle();
    final chip = find.byKey(const Key('collection-chip'));
    final quests = find.byKey(const Key('daily-quests-chip'));
    expect(chip, findsOneWidget);
    expect((tester.getCenter(chip).dy - tester.getCenter(quests).dy).abs(),
        lessThan(6), reason: 'cùng hàng với chip Nhiệm vụ');
    expect(tester.takeException(), isNull, reason: 'không tràn ở 320px/1.3x');
    // Nút có NHÃN chữ (không chỉ icon) và không đè lên chip Nhiệm vụ bên cạnh.
    expect(find.descendant(of: chip, matching: find.text('✨ Bộ sưu tập')),
        findsOneWidget);
    expect(tester.getRect(chip).left,
        greaterThanOrEqualTo(tester.getRect(quests).right - 0.5),
        reason: 'không đè chip Nhiệm vụ');
    // 3 nút rộng đều nhau; 💎 ở hàng tiền bên dưới (không chen vào hàng nút).
    expect(tester.getRect(chip).width,
        closeTo(tester.getRect(quests).width, 1),
        reason: 'các nút rộng đều nhau');
    final gem = tester.getCenter(find.textContaining('💎'));
    expect(gem.dy, greaterThan(tester.getRect(chip).bottom),
        reason: '💎 nằm dưới hàng nút');
    // Có 10 món → mốc 10 chờ nhận → chấm đỏ "1" nằm trong nút.
    expect(find.descendant(of: chip, matching: find.text('1')), findsOneWidget);

    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.byType(AccessoryInventoryPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('Kho: mỗi ô lấp đầy ô lưới (không co hẹp lệch trái)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 7600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = await _container(seed: GameState.newGame(nowMillis: 0));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(
        locale: Locale('vi'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AccessoryInventoryPage(),
      ),
    ));
    await tester.pumpAndSettle();
    // 400 - 24 padding - 20 khoảng cách = 356 / 3 ≈ 118.7
    final w = tester
        .getSize(find.descendant(
          of: find.byKey(const Key('accessory-cell-mint_leaf')),
          matching: find.byType(Opacity),
        ))
        .width;
    expect(w, closeTo(118.67, 1));
    c.dispose();
  });

  testWidgets('Kho: chạm món ĐÃ CÓ để trưng bày/bỏ; món khoá không đổi; đủ chỗ thì báo',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 7600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = await _container(
      seed: GameState.newGame(nowMillis: 0)
        ..ownedAccessories.addAll(['mint_leaf', 'cupcake', 'cookie', 'dragon']),
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(
        locale: Locale('vi'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AccessoryInventoryPage(),
      ),
    ));
    await tester.pumpAndSettle();
    List<String> eq() => c.read(gameControllerProvider).equippedAccessories;
    expect(find.textContaining('Trưng bày 0/3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('accessory-cell-galaxy'))); // chưa có
    await tester.pump();
    expect(eq(), isEmpty);

    for (final id in ['mint_leaf', 'cupcake', 'cookie']) {
      await tester.tap(find.byKey(Key('accessory-cell-$id')));
      await tester.pump();
    }
    expect(eq(), ['mint_leaf', 'cupcake', 'cookie']);
    expect(find.textContaining('Trưng bày 3/3'), findsOneWidget);
    expect(find.text('📌'), findsNWidgets(3));

    await tester.tap(find.byKey(const Key('accessory-cell-dragon'))); // đủ chỗ
    await tester.pump();
    expect(eq().length, 3);
    expect(find.textContaining('Đã đủ 3 món trưng bày'), findsOneWidget);

    await tester.tap(find.byKey(const Key('accessory-cell-cupcake'))); // bỏ
    await tester.pumpAndSettle();
    expect(eq(), ['mint_leaf', 'cookie']);
    expect(find.text('📌'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
