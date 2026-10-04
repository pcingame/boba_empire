import 'dart:ui' as ui;

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_pack_dialog.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dialog gói phụ kiện không tràn ở mọi ngôn ngữ, cả trong mùa sự kiện, và
/// mua xong có hiện món vừa rớt.
void main() {
  for (final locale in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    for (final season in [false, true]) {
      testWidgets('[$locale] season=$season: dialog gói không tràn, mua được',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await GameStorage(prefs).save(
            GameState.newGame(nowMillis: 0)..gems = 5000,
            nowMillis: 0);
        final now = (season ? festivals.first.start.millisecondsSinceEpoch : 0);
        await tester.pumpWidget(ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            clockProvider.overrideWithValue(() => now),
          ],
          child: MaterialApp(
            locale: ui.Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (c) => TextButton(
                  onPressed: () => showAccessoryPacks(c),
                  child: const Text('open')),
            ),
          ),
        ));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('accessory-pack-epic')));
        await tester.tap(find.byKey(const Key('accessory-pack-epic')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('accessory-reveal')), findsOneWidget);
      });
    }
  }
}
