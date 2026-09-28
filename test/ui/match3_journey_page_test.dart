// Lưới màn ở máy hẹp + cỡ chữ hệ thống phóng to: ô là hình vuông cố định nên
// nội dung (số màn + biểu tượng thu thập + 3 sao) rất dễ tràn.
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/match3_journey_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boba_empire/l10n/app_localizations.dart';

/// Dựng trang danh sách màn với [scale] là cỡ chữ hệ thống.
Future<ProviderContainer> _pump(WidgetTester tester, double scale) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
    GameState.newGame(nowMillis: 0)..m3Stars.addAll([3, 2, 1, 1]),
    nowMillis: 0,
  );
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const Match3JourneyPage(),
    ),
  ));
  await tester.pump();
  return c;
}

void main() {
  testWidgets('cuộn hết cỡ KHÔNG bật hiệu ứng kéo giãn (nó bóp méo ô vuông)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = await _pump(tester, 1.0);

    // Kéo quá cuối danh sách: mặc định của Android sẽ dựng
    // StretchingOverscrollIndicator và bóp nội dung ở mép.
    await tester.fling(find.byType(GridView), const Offset(0, -6000), 8000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);

    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('lưới màn không tràn ở 320px, cỡ chữ x$scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      // Save đã mở vài màn, gồm cả màn thu thập (có thêm 1 dòng biểu tượng).
      await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)..m3Stars.addAll([3, 2, 1, 1]),
        nowMillis: 0,
      );
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ]);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const Match3JourneyPage(),
        ),
      ));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(Balance.m3LevelCount, greaterThan(0));

      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
}
