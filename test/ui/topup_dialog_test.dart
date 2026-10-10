import 'package:boba_empire/core/topup.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/topup_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Mốc nạp: nút Nhận chỉ bật khi đủ điểm, nhận xong hiện Đã nhận',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () => showTopupDialog(c),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    FilledButton claim(int i) =>
        tester.widget<FilledButton>(find.byKey(Key('topup-claim-$i')));
    expect(claim(0).onPressed, isNull); // 0 điểm: chưa đủ

    container.read(gameControllerProvider.notifier).addTopupPoints(topupTiers[0].points);
    await tester.pump();
    expect(claim(0).onPressed, isNotNull);
    expect(claim(1).onPressed, isNull);

    await tester.tap(find.byKey(const Key('topup-claim-0')));
    await tester.pump();
    expect(find.byKey(const Key('topup-claim-0')), findsNothing);
    expect(find.text('Claimed'), findsOneWidget);
    expect(container.read(gameControllerProvider).gems, topupTiers[0].gems);

    // GameController có Timer.periodic: gỡ cây rồi dispose trước khi test kết thúc.
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}
