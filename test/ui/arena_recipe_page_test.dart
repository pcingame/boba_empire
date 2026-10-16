// Đấu Trường — dạng PK công thức: nút chọn dạng, thân màn trong trận (tiến độ, vào pha, chờ đối thủ), không tràn.
import 'package:boba_empire/arena/arena_controller.dart';
import 'package:boba_empire/arena/arena_models.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/arena_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Fake extends ArenaController {
  _Fake(this.initial);
  final ArenaViewState initial;
  ArenaMode? started;

  @override
  ArenaViewState build() => initial;

  @override
  Future<void> startMatchmaking([ArenaMode mode = ArenaMode.tap]) async => started = mode;
}

Future<_Fake> _pump(WidgetTester tester, ArenaViewState state, {Locale locale = const Locale('vi'), double scale = 1}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final fake = _Fake(state);
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      arenaOnlineCountProvider.overrideWith((ref) => Stream.value(3)),
      arenaControllerProvider.overrideWith(() => fake),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: const Size(320, 640), textScaler: TextScaler.linear(scale)),
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
    ),
  ));
  await tester.pump();
  await tester.pump();
  return fake;
}

ArenaInMatch _match({Set<int> mine = const {}, int theirs = 0}) => ArenaInMatch(
      mode: ArenaMode.recipe,
      myScore: 180,
      opponentScore: 90,
      remaining: const Duration(seconds: 120),
      tiersBought: const {},
      orderIds: const [1, 2, 3, 4, 5],
      myServed: mine,
      theirServed: theirs,
    );

void main() {
  testWidgets('màn chờ có nút PK Công thức, bấm → ghép trận dạng recipe', (tester) async {
    final fake = await _pump(tester, const ArenaIdle());
    final btn = find.byKey(const Key('arena-start-recipe'));
    await tester.ensureVisible(btn);
    await tester.tap(btn);
    expect(fake.started, ArenaMode.recipe);
  });

  testWidgets('trong trận: hiện tiến độ hai bên + nút vào pha; xong đủ 5 đơn thì chờ đối thủ', (tester) async {
    await _pump(tester, _match(mine: {0, 1}, theirs: 3));
    expect(find.text('Bạn xong 2/5 đơn · Đối thủ 3/5'), findsOneWidget);
    expect(find.byKey(const Key('arena-recipe-start-brewing')), findsOneWidget);
    expect(find.byKey(const Key('arena-recipe-waiting')), findsNothing);

    await _pump(tester, _match(mine: {0, 1, 2, 3, 4}, theirs: 3));
    expect(find.byKey(const Key('arena-recipe-start-brewing')), findsNothing);
    expect(find.byKey(const Key('arena-recipe-waiting')), findsOneWidget);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('không tràn ở ${locale.languageCode}, 320px + chữ 1.6×', (tester) async {
      await _pump(tester, const ArenaIdle(), locale: locale, scale: 1.6);
      expect(find.byKey(const Key('arena-start-recipe')), findsOneWidget);
      await _pump(tester, _match(mine: {0}, theirs: 1), locale: locale, scale: 1.6);
      expect(find.byKey(const Key('arena-recipe-progress')), findsOneWidget);
    });
  }
}
