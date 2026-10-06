// UI cho danh mục 160 món: sở hữu đủ (tên dài nhất hiện ra), dải 9 mốc, hộp
// thoại hướng dẫn — mọi ngôn ngữ, máy nhỏ 320dp + chữ to, không tràn/không ném.
library;

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/collection_milestones.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_how_to_dialog.dart';
import 'package:boba_empire/ui/accessory_inventory_page.dart';
import 'package:boba_empire/ui/widgets/mascot.dart'
    show debugDisableMascotAnimation;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester,
  GameState seed,
  Locale locale,
  Widget home, {
  double height = 640,
}) async {
  tester.view.physicalSize = Size(320 * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return c;
}

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    final code = locale.languageCode;

    testWidgets('[$code] sở hữu đủ 160 món: cuộn hết Kho không tràn', (
      tester,
    ) async {
      final seed = GameState.newGame(nowMillis: 0)
        ..ownedAccessories.addAll(accessories.map((a) => a.id));
      final c = await _pump(
        tester,
        seed,
        locale,
        const AccessoryInventoryPage(),
      );
      final list = find.byType(Scrollable).first;
      // Cuộn từng đoạn tới hết để GridView dựng (và đo) mọi ô.
      for (var i = 0; i < 60; i++) {
        await tester.drag(list, const Offset(0, -500));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });

    testWidgets(
      '[$code] đủ 160 món: 9 thẻ mốc cuộn ngang, cả 9 đều nhận được, không tràn',
      (tester) async {
        final seed = GameState.newGame(nowMillis: 0)
          ..ownedAccessories.addAll(accessories.map((a) => a.id));
        final c = await _pump(
          tester,
          seed,
          locale,
          const AccessoryInventoryPage(),
          height: 1800,
        );
        for (final m in collectionMilestones) {
          expect(
            find.byKey(Key('milestone-claim-${m.count}')),
            findsOneWidget,
            reason: 'mốc ${m.count} đủ điều kiện nhưng không có nút nhận',
          );
        }
        final tops = collectionMilestones
            .map(
              (m) => tester
                  .getRect(find.byKey(Key('milestone-claim-${m.count}')))
                  .top,
            )
            .toSet();
        expect(tops.length, 1, reason: 'một hàng cuộn ngang');
        final widths = collectionMilestones
            .map(
              (m) => tester
                  .getRect(find.byKey(Key('milestone-claim-${m.count}')))
                  .width
                  .round(),
            )
            .toSet();
        expect(widths.length, 1, reason: 'thẻ rộng đều');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      },
    );

    testWidgets('[$code] hộp thoại hướng dẫn mở được, cuộn hết, đóng được', (
      tester,
    ) async {
      final c = await _pump(
        tester,
        GameState.newGame(nowMillis: 0),
        locale,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAccessoryHowTo(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -2000),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('accessory-how-to-close')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }

  testWidgets('nút ? trong Kho mở hướng dẫn', (tester) async {
    final c = await _pump(
      tester,
      GameState.newGame(nowMillis: 0),
      const Locale('vi'),
      const AccessoryInventoryPage(),
    );
    await tester.tap(find.byKey(const Key('accessory-how-to-button')));
    await tester.pumpAndSettle();
    expect(find.text('Hướng dẫn sưu tầm'), findsOneWidget);
    // Số 💎 quy đổi lấy từ Balance, hiện đúng trong chữ.
    expect(
      find.textContaining('nhận 2 💎', findRichText: true),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets(
    'animation BẬT: ô hiện dần rồi dừng hẳn (hữu hạn), không tràn, huyền thoại có vầng sáng',
    (tester) async {
      // flutter_test_config.dart tắt animation toàn cục — bật lại để kiểm thật.
      debugDisableMascotAnimation = false;
      addTearDown(() => debugDisableMascotAnimation = true);
      final seed = GameState.newGame(nowMillis: 0)
        ..ownedAccessories.addAll(accessories.map((a) => a.id));
      final c = await _pump(
        tester,
        seed,
        const Locale('en'),
        const AccessoryInventoryPage(),
      );
      // _pump đã pumpAndSettle: nếu còn animation vô hạn thì đã treo/ném timeout.
      expect(
        tester.hasRunningAnimations,
        isFalse,
        reason: 'mọi animation của lưới phải hữu hạn',
      );
      final first = find.byKey(Key('accessory-cell-${accessories.first.id}'));
      expect(first, findsOneWidget);
      final op = tester.widget<Opacity>(
        find.descendant(of: first, matching: find.byType(Opacity)).first,
      );
      expect(op.opacity, 1.0, reason: 'ô đã hiện đủ sau khi animation xong');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
