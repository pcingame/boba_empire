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
    // m3HowToSeen: các test này soi LƯỚI MÀN, không muốn bảng hướng dẫn tự
    // bật che mất (hành vi lần đầu mở tab, có test riêng bên dưới).
    GameState.newGame(nowMillis: 0)
      ..m3HowToSeen = true
      ..m3Stars.addAll([3, 2, 1, 1]),
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
  _howToTests();
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
        // m3HowToSeen: các test này soi LƯỚI MÀN, không muốn bảng hướng dẫn tự
    // bật che mất (hành vi lần đầu mở tab, có test riêng bên dưới).
    GameState.newGame(nowMillis: 0)
      ..m3HowToSeen = true
      ..m3Stars.addAll([3, 2, 1, 1]),
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

// --- Bảng hướng dẫn: tự hiện LẦN ĐẦU, sau đó chỉ mở bằng nút ? ---
void _howToTests() {
  testWidgets('lần đầu mở tab thì tự hiện hướng dẫn, lần sau thì không',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // Ván mới: chưa xem hướng dẫn bao giờ.
    await GameStorage(prefs)
        .save(GameState.newGame(nowMillis: 0), nowMillis: 0);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
    ]);

    Future<void> pump() => tester.pumpWidget(UncontrolledProviderScope(
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
            home: Match3JourneyPage(),
          ),
        ));

    await pump();
    await tester.pumpAndSettle();
    expect(find.text('Chơi Trân Châu Rơi'), findsOneWidget,
        reason: 'lần đầu phải tự hiện');
    expect(c.read(gameControllerProvider).m3HowToSeen, isTrue);

    await tester.tap(find.byKey(const Key('m3-how-to-close')));
    await tester.pumpAndSettle();
    expect(find.text('Chơi Trân Châu Rơi'), findsNothing);

    // Mở lại trang: KHÔNG tự hiện nữa.
    await tester.pumpWidget(const SizedBox());
    await pump();
    await tester.pumpAndSettle();
    expect(find.text('Chơi Trân Châu Rơi'), findsNothing,
        reason: 'đã xem rồi thì đừng hiện lại');

    // Nhưng nút ? vẫn mở được bất cứ lúc nào.
    await tester.tap(find.byKey(const Key('m3-how-to-button')));
    await tester.pumpAndSettle();
    expect(find.text('Chơi Trân Châu Rơi'), findsOneWidget);
    // Có nhắc tới kẹo đặc biệt và mốc sao — hai luật không đoán ra được.
    expect(find.textContaining('BOM CHÉO'), findsOneWidget);
    expect(find.textContaining('Chơi nốt'), findsOneWidget);

    await tester.tap(find.byKey(const Key('m3-how-to-close')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
