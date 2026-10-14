// BXH Thợ pha chế (giao diện): các trạng thái, tên rất dài không tràn ở 320px mọi ngôn ngữ, lối vào từ màn công thức.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:boba_empire/core/recipes.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/flair.dart';
import 'package:boba_empire/leaderboard/recipe_leaderboard_controller.dart';
import 'package:boba_empire/leaderboard/recipe_leaderboard_repository.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/state/recipe_providers.dart';
import 'package:boba_empire/ui/recipe_hub_page.dart';
import 'package:boba_empire/ui/recipe_leaderboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _long = 'TênRấtDàiTênRấtDàiTênRấtDàiTênRất';

final _entries = [
  const RecipeLeaderboardEntry(userId: 'u1', nickname: _long, mastered: 100, rank: 1),
  const RecipeLeaderboardEntry(userId: 'me', nickname: 'Tôi', mastered: 20, rank: 2),
  const RecipeLeaderboardEntry(userId: 'u3', nickname: 'C', mastered: 5, rank: 3),
];

class _Fake extends RecipeLeaderboardController {
  _Fake(this.initial);
  final RecipeLeaderboardViewState initial;
  int refreshes = 0;
  @override
  RecipeLeaderboardViewState build() => initial;
  @override
  Future<void> refresh({bool silent = false}) async => refreshes++;
  @override
  Future<void> submitNickname(String nickname) async {
    state = RecipeLeaderboardLoaded(entries: _entries, myUserId: 'me', myMastered: 3);
  }
}

class _Flair extends FlairCache {
  @override
  Map<String, String> build() => {};
}

Future<_Fake> _pump(WidgetTester tester, RecipeLeaderboardViewState s,
    {String locale = 'vi', Widget home = const RecipeLeaderboardPage(), double scale = 1.0}) async {
  tester.view.physicalSize = const Size(320 * 2, 640 * 2);
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final fake = _Fake(s);
  await tester.pumpWidget(const SizedBox()); // gỡ cây cũ: mỗi lần dựng phải có ProviderScope mới
  final catalog = RecipeCatalog.fromJson(
      jsonDecode(File('assets/recipes/recipes.json').readAsStringSync()) as Map<String, dynamic>);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      recipeLeaderboardControllerProvider.overrideWith(() => fake),
      flairCacheProvider.overrideWith(_Flair.new),
      recipeCatalogProvider.overrideWith((ref) async => catalog),
    ],
    child: MaterialApp(
      locale: ui.Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  ));
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets('đã tải: 3 hàng đúng hạng/số món; mở trang thì tải bảng; chưa có món Thạo thì có dòng nhắc', (tester) async {
    final fake = await _pump(
        tester, RecipeLeaderboardLoaded(entries: _entries, myUserId: 'me', myMastered: 0));
    expect(fake.refreshes, 1);
    expect(find.text('BXH Thợ pha chế'), findsOneWidget);
    expect(find.text('Thạo 100 món'), findsOneWidget);
    expect(find.text('Thạo 5 món'), findsOneWidget);
    expect(find.byKey(const Key('rlb-none')), findsOneWidget);
    expect(find.byKey(const Key('rlb-row-2')), findsOneWidget);
  });

  testWidgets('top 3 có huy chương 🥇🥈🥉, hạng 4+ hiện số; hàng của mình có viền nổi bật', (tester) async {
    final entries = [
      const RecipeLeaderboardEntry(userId: 'a', nickname: 'A', mastered: 9, rank: 1),
      const RecipeLeaderboardEntry(userId: 'b', nickname: 'B', mastered: 8, rank: 2),
      const RecipeLeaderboardEntry(userId: 'c', nickname: 'C', mastered: 7, rank: 3),
      const RecipeLeaderboardEntry(userId: 'me', nickname: 'Tôi', mastered: 6, rank: 4),
    ];
    await _pump(tester, RecipeLeaderboardLoaded(entries: entries, myUserId: 'me', myMastered: 6));
    expect([find.text('🥇'), find.text('🥈'), find.text('🥉')].map((f) => f.evaluate().length), [1, 1, 1]);
    expect(find.text('4'), findsOneWidget);
    // Chỉ hàng của mình có khung viền (Container có border bọc ngoài ô).
    int framed() => find
        .byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).border != null)
        .evaluate()
        .length;
    expect(framed(), 1);
  });

  testWidgets('đã có món Thạo: không hiện dòng nhắc', (tester) async {
    await _pump(tester, RecipeLeaderboardLoaded(entries: _entries, myUserId: 'me', myMastered: 5));
    expect(find.byKey(const Key('rlb-none')), findsNothing);
  });

  testWidgets('chưa có hàng nào: câu mời; lỗi: nút thử lại gọi tải lại; cần tên: form rồi hiện bảng', (tester) async {
    await _pump(tester, const RecipeLeaderboardLoaded(entries: [], myUserId: null, myMastered: 0));
    expect(find.textContaining('đầu tiên'), findsOneWidget);

    final f2 = await _pump(tester, const RecipeLeaderboardError());
    expect(find.byKey(const Key('rlb-retry')), findsOneWidget);
    await tester.tap(find.byKey(const Key('rlb-retry')));
    await tester.pump();
    expect(f2.refreshes, 2); // lúc mở trang + bấm thử lại

    await _pump(tester, const RecipeLeaderboardNeedsNickname());
    expect(find.byKey(const Key('rlb-nickname')), findsOneWidget);
    await tester.tap(find.byKey(const Key('rlb-submit'))); // tên rỗng: không làm gì
    await tester.pump();
    expect(find.byKey(const Key('rlb-row-0')), findsNothing);
    await tester.enterText(find.byKey(const Key('rlb-nickname')), 'Boba');
    await tester.tap(find.byKey(const Key('rlb-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rlb-row-0')), findsOneWidget);
  });

  testWidgets('lối vào: biểu tượng cúp ở màn công thức mở bảng xếp hạng', (tester) async {
    await _pump(tester, RecipeLeaderboardLoaded(entries: _entries, myUserId: 'me', myMastered: 1),
        home: const RecipeHubPage());
    expect(find.byKey(const Key('recipe-leaderboard')), findsOneWidget);
    await tester.tap(find.byKey(const Key('recipe-leaderboard')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rlb-row-0')), findsOneWidget);
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('không tràn ở 320px, chữ 1.5×, tên rất dài ($lang)', (tester) async {
      for (final s in <RecipeLeaderboardViewState>[
        RecipeLeaderboardLoaded(entries: _entries, myUserId: 'me', myMastered: 0),
        const RecipeLeaderboardNeedsNickname(),
        const RecipeLeaderboardError(),
        const RecipeLeaderboardLoaded(entries: [], myUserId: null, myMastered: 0),
      ]) {
        await _pump(tester, s, locale: lang, scale: 1.5);
        expect(tester.takeException(), isNull, reason: '$lang · $s');
      }
    });
  }
}
