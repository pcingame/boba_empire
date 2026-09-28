// Hình học thanh sao: 3 ngôi sao phải nằm ĐÚNG trục ngang của thanh tiến độ, và
// tâm mỗi sao rơi đúng vào vị trí mốc của nó. Nhìn mắt rất khó thấy lệch vài
// pixel — đo mới chắc (lỗi cũ lệch 4px, người chơi nhận ra).
import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/core/balance.dart';
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
  testWidgets('sao nằm đúng trục thanh và đúng vị trí mốc', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
      adServiceProvider.overrideWithValue(const StubAdService()),
    ]);

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
        home: Match3PlayPage(level: Match3Level(1)),
      ),
    ));
    await tester.pump();

    final bar = tester.getRect(find.byType(LinearProgressIndicator));
    final stars = find.byIcon(Icons.star_outline_rounded);
    expect(stars, findsNWidgets(3), reason: 'phải có đúng 3 mốc sao');

    const target = 1; // mốc 1 sao = target; dùng công thức thật ở dưới
    expect(target, 1);
    final full = match3StarThreshold(const Match3Level(1).target, 3);

    for (var i = 0; i < 3; i++) {
      final r = tester.getRect(stars.at(i));
      // 1) Cùng trục ngang với thanh.
      expect(r.center.dy, closeTo(bar.center.dy, 0.5),
          reason: 'sao ${i + 1} lệch trục dọc so với thanh');

      // 2) Tâm sao rơi đúng mốc của nó (trừ khi bị ép vào trong mép thanh).
      final ratio = match3StarThreshold(const Match3Level(1).target, i + 1) / full;
      final want = (bar.left + bar.width * ratio)
          .clamp(bar.left + r.width / 2, bar.right - r.width / 2);
      expect(r.center.dx, closeTo(want, 1.0),
          reason: 'sao ${i + 1} lệch ngang so với mốc');
    }

    // 3) Sao không được tràn ra ngoài hai đầu thanh.
    for (var i = 0; i < 3; i++) {
      final r = tester.getRect(stars.at(i));
      expect(r.left, greaterThanOrEqualTo(bar.left - 0.5));
      expect(r.right, lessThanOrEqualTo(bar.right + 0.5));
    }

    expect(Balance.m3Star3Mult, greaterThan(Balance.m3Star2Mult));
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
