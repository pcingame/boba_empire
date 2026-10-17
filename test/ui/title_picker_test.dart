// Danh hiệu hồ sơ: mở khoá theo tiến độ, chọn được và lưu máy; id khớp whitelist SQL.
import 'dart:io';

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/titles.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/player_title.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/title_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('id danh hiệu khớp whitelist trong SQL', () {
    final sql = File('supabase/player_title_schema.sql').readAsStringSync();
    final m = RegExp(r"p_id not in \(([^)]*)\)").firstMatch(sql)!.group(1)!;
    final ids = RegExp(r"'(\w+)'").allMatches(m).map((x) => x.group(1)).toSet();
    expect(ids, {for (final t in playerTitles) t.id});
  });

  testWidgets('stage 5: Ông Chủ mở, Đại Gia khoá; chọn được và lưu máy', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(GameState.newGame(nowMillis: 0)..stage = 5, nowMillis: 0);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 1000),
    ]);
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: TitlePickerDialog()),
      ),
    ));
    await tester.pump();
    await tester.tap(find.byKey(const Key('title-mogul')));
    await tester.pump();
    expect(c.read(selectedTitleProvider), '');
    await tester.tap(find.byKey(const Key('title-tycoon')));
    await tester.pump();
    expect(c.read(selectedTitleProvider), 'tycoon');
    expect(prefs.getString('profile_title'), 'tycoon');
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
