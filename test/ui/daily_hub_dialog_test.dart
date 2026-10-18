import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/daily_hub_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final tab in DailyHubTab.values) {
    testWidgets('showDailyHub(${tab.name}) mở đúng tab, chuyển tab không lỗi', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ]);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
              builder: (ctx) => TextButton(onPressed: () => showDailyHub(ctx, tab), child: const Text('open'))),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final bar = tester.widget<TabBar>(find.byType(TabBar));
      expect(bar.controller?.index ?? DefaultTabController.of(tester.element(find.byType(TabBar))).index, tab.index);
      for (final k in ['daily', 'weekly', 'rewards']) {
        await tester.tap(find.byKey(Key('hub-tab-$k')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
}
