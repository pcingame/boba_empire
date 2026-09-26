import 'package:boba_empire/arena/arena_controller.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/arena_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> _app(Locale locale, Stream<int> online) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      arenaOnlineCountProvider.overrideWith((ref) => online),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ArenaPage(),
    ),
  );
}

void main() {
  testWidgets('hiện số người đang online, 1 người vẫn hiện, số nhiều đúng', (tester) async {
    await tester.pumpWidget(await _app(const Locale('en'), Stream.value(1)));
    await tester.pumpAndSettle();
    expect(find.text('1 player online'), findsOneWidget);

    await tester.pumpWidget(await _app(const Locale('en'), Stream.value(37)));
    await tester.pumpAndSettle();
    expect(find.text('37 players online'), findsOneWidget);

    await tester.pumpWidget(await _app(const Locale('vi'), Stream.value(5)));
    await tester.pumpAndSettle();
    expect(find.text('5 người đang online'), findsOneWidget);
  });

  testWidgets('chưa có số (đang kết nối/lỗi) thì ẩn, không hiện 0', (tester) async {
    await tester.pumpWidget(await _app(const Locale('vi'), const Stream<int>.empty()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('arena-online')), findsNothing);
    expect(find.textContaining('online'), findsNothing);
  });

  testWidgets('số cập nhật khi có người vào/ra', (tester) async {
    final controller = Stream<int>.fromIterable([1, 2, 3]).asBroadcastStream();
    await tester.pumpWidget(await _app(const Locale('en'), controller));
    await tester.pumpAndSettle();
    expect(find.text('3 players online'), findsOneWidget);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('không tràn ở ${locale.languageCode}, máy nhỏ + chữ to + số lớn', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(1.6)),
          child: await _app(locale, Stream.value(1234567)),
        ),
      );
      await tester.pumpAndSettle(); // ném FlutterError nếu RenderFlex tràn
      expect(find.byKey(const Key('arena-online')), findsOneWidget);
    });
  }
}
