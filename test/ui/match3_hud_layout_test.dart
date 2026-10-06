// HUD màn Ghép 3 (chip "Nước còn: N") không tràn ở mọi ngôn ngữ, máy nhỏ 320dp
// + chữ to — en/es từng tràn 7,8px.
library;

import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/core/match3_levels.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/match3_play_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    for (final size in const [Size(320, 640), Size(640, 320)]) {
      testWidgets(
        '[${locale.languageCode}] ${size.width.toInt()}x${size.height.toInt()}: HUD không tràn',
        (tester) async {
          tester.view.physicalSize = size * 2;
          tester.view.devicePixelRatio = 2;
          tester.platformDispatcher.textScaleFactorTestValue = 1.3;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          final c = ProviderContainer(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              clockProvider.overrideWithValue(() => 0),
              adServiceProvider.overrideWithValue(const StubAdService()),
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
                home: const Match3PlayPage(level: Match3Level(1)),
              ),
            ),
          );
          await tester.pump();
          await tester.pump();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          c.dispose();
        },
      );
    }
  }
}
