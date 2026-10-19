// BXH Chi nhánh: nộp tổng cấp khi có biệt danh, hỏi tên khi chưa có, rỗng; SQL trần khớp client; không tràn 320px.
import 'dart:io';

import 'package:boba_empire/core/branches.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/branch_leaderboard.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/branch_leaderboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo implements BranchLbRepository {
  List<BranchLbEntry> rows = [];
  final submits = <(String, int, int)>[];
  @override
  Future<void> submit(String n, int total, int opened) async => submits.add((n, total, opened));
  @override
  Future<List<BranchLbEntry>> top() async => rows;
  @override
  String? get myUserId => 'me';
}

Future<(ProviderContainer, _Repo, SharedPreferences)> _open(WidgetTester tester,
    {String nickname = '',
    Map<String, int> levels = const {},
    List<BranchLbEntry> rows = const [],
    String locale = 'vi',
    Size size = const Size(400, 900)}) async {
  SharedPreferences.setMockInitialValues({if (nickname.isNotEmpty) 'leaderboard_nickname': nickname});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 1000)..branchLevels.addAll(levels), nowMillis: 1000);
  final repo = _Repo()..rows = rows;
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 2000),
    branchLbRepositoryProvider.overrideWithValue(repo),
  ]);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const BranchLeaderboardPage(),
    ),
  ));
  await tester.pumpAndSettle();
  return (c, repo, prefs);
}

void main() {
  test('trần SQL đủ chứa tối đa của client', () {
    final sql = File('supabase/branch_leaderboard_schema.sql').readAsStringSync();
    expect(sql, contains('total_levels between 0 and 500'));
    expect(branchCities.length * branchMaxLevel, lessThanOrEqualTo(500));
    expect(branchCities.length, lessThanOrEqualTo(50));
  });

  testWidgets('có biệt danh + chi nhánh: nộp tổng cấp rồi hiện danh sách', (tester) async {
    final (c, repo, _) = await _open(tester,
        nickname: 'Tôi',
        levels: {'saigon': 3, 'tokyo': 5},
        rows: const [BranchLbEntry('u1', 'Bạn A', 90, 12, 1), BranchLbEntry('me', 'Tôi', 8, 2, 2)]);
    expect(repo.submits.single, ('Tôi', 8, 2));
    expect(find.byKey(const Key('branch-lb-row-u1')), findsOneWidget);
    expect(find.textContaining('90 cấp'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('chưa có biệt danh: hiện form tên, nhập xong thì nộp', (tester) async {
    final (c, repo, prefs) = await _open(tester, levels: {'saigon': 2});
    expect(find.byKey(const Key('branch-lb-name')), findsOneWidget);
    repo.rows = const [BranchLbEntry('me', 'Tôi', 2, 1, 1)];
    await tester.enterText(find.byKey(const Key('branch-lb-name')), 'Tôi');
    await tester.tap(find.byKey(const Key('branch-lb-submit')));
    await tester.pumpAndSettle();
    expect(prefs.getString('leaderboard_nickname'), 'Tôi');
    expect(repo.submits.single.$2, 2);
    expect(find.byKey(const Key('branch-lb-row-me')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('chưa mở chi nhánh: không nộp, không đòi tên, hiện trạng thái rỗng', (tester) async {
    final (c, repo, _) = await _open(tester);
    expect(repo.submits, isEmpty);
    expect(find.byKey(const Key('branch-lb-name')), findsNothing);
    expect(find.byKey(const Key('branch-lb-empty')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th']) {
    testWidgets('không tràn ở 320px, chữ lớn ($lang)', (tester) async {
      tester.view.devicePixelRatio = 1;
      final (c, _, _) = await _open(tester,
          nickname: 'Một-biệt-danh-rất-dài',
          levels: {'saigon': 3},
          rows: [for (var i = 1; i <= 5; i++) BranchLbEntry('u$i', 'Người chơi số $i rất dài', 170, 17, i)],
          locale: lang,
          size: const Size(320, 640));
      expect(tester.takeException(), isNull, reason: lang);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
}
