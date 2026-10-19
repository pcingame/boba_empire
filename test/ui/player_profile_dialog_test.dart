import 'dart:io';
import 'dart:ui' as ui;

import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/player_profile.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/player_profile_dialog.dart';
import 'package:boba_empire/ui/web_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('parseProfileRows', () {
    test('sắp theo thứ tự bảng, bỏ bảng lạ / dữ liệu hỏng', () {
      final rows = parseProfileRows([
        {'board': 'vip', 'rank': 3, 'value': 500},
        {'board': 'income', 'rank': 1, 'value': 1.5e30},
        {'board': 'bang_moi_cua_server', 'rank': 1, 'value': 1},
        {'board': 'guild', 'rank': 1, 'value': 1200, 'label': 'Alpha'}, // chỉ web hiện dòng hội
        {'board': 'pearls', 'rank': 'x', 'value': 1},
        {'board': 'speed', 'rank': 2, 'value': null},
        'rac',
        {'board': 'collection', 'rank': 4.0, 'value': 12},
      ]);
      expect(rows.map((r) => r.board), [
        ProfileBoard.income,
        ProfileBoard.collection,
        ProfileBoard.vip,
      ]);
      expect(rows[1].rank, 4);
      expect(rows[0].value, 1.5e30);
    });

    test('không phải danh sách -> rỗng', () {
      expect(parseProfileRows(null), isEmpty);
      expect(parseProfileRows({'a': 1}), isEmpty);
      expect(parseProfileRows([]), isEmpty);
    });

    test('id bảng khớp cột board của SQL', () {
      final sql = RegExp(r"'(\w+)'::text")
          .allMatches(
            File('supabase/player_profile_schema.sql').readAsStringSync(),
          )
          .map((m) => m.group(1))
          .toSet();
      // 'guild' chỉ dành cho web (app bỏ qua) nên không có trong ProfileBoard.
      expect(sql, {for (final b in ProfileBoard.values) b.name, 'guild'});
    });
  });

  test(
    'các bảng cá nhân đều mở được hồ sơ khi bấm dòng; bảng Hội/Đấu Trường thì không',
    () {
      for (final f in [
        'leaderboard_page',
        'm3_leaderboard_page',
        'story_speedrun_page',
        'vip_leaderboard_page',
        'collection_peek_dialog',
      ]) {
        expect(
          File('lib/ui/$f.dart').readAsStringSync(),
          contains('showPlayerProfile('),
          reason: f,
        );
      }
    },
  );

  Future<List<Uri>> pump(
    WidgetTester tester,
    AsyncValue<List<ProfileRank>> result, {
    String locale = 'en',
    Size size = const Size(400, 800),
    String name = 'Alice',
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final opened = <Uri>[];
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          playerProfileProvider.overrideWith((ref, n) async {
            if (result is AsyncError) throw StateError('x');
            return result.value ?? [];
          }),
          urlOpenerProvider.overrideWithValue((u) async {
            opened.add(u);
            return true;
          }),
        ],
        child: MaterialApp(
          locale: ui.Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (c) => TextButton(
                onPressed: () => showPlayerProfile(c, name),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return opened;
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  final full = AsyncData([
    const ProfileRank(ProfileBoard.income, 1, 4.5e74),
    const ProfileRank(ProfileBoard.pearls, 5, 62),
    const ProfileRank(ProfileBoard.collection, 2, 96),
    const ProfileRank(ProfileBoard.speed, 7, 93784),
    const ProfileRank(ProfileBoard.vip, 12, 123456),
  ]);

  testWidgets('có nút Kết bạn ở hồ sơ người khác', (tester) async {
    await pump(tester, full);
    expect(find.byKey(const Key('profile-add-friend')), findsOneWidget);
  });

  testWidgets('hồ sơ CỦA MÌNH: không có nút Kết bạn', (tester) async {
    SharedPreferences.setMockInitialValues({'leaderboard_nickname': 'Alice'});
    await pump(tester, full);
    expect(find.byKey(const Key('profile-add-friend')), findsNothing);
  });

  testWidgets('hiện tên + hạng + điểm từng bảng', (tester) async {
    await pump(tester, full);
    expect(find.text('Profile: Alice'), findsOneWidget);
    for (final b in ProfileBoard.values) {
      expect(find.byKey(Key('profile-row-${b.name}')), findsOneWidget);
    }
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#12'), findsOneWidget);
    expect(find.text('62 ⭐'), findsOneWidget);
    expect(find.text('96'), findsOneWidget);
    expect(find.text('1d 2h'), findsOneWidget); // 93784s
    expect(tester.takeException(), isNull);
  });

  testWidgets('chưa có hạng nào -> câu thông báo; lỗi -> báo lỗi mạng', (
    tester,
  ) async {
    await pump(tester, const AsyncData(<ProfileRank>[]));
    expect(find.byKey(const Key('profile-empty')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await pump(tester, AsyncError(StateError('x'), StackTrace.empty));
    expect(find.byKey(const Key('profile-error')), findsOneWidget);
  });

  testWidgets(
    '"Xem trên web" mở đúng liên kết hồ sơ (tên có dấu cách/ký tự lạ được mã hoá)',
    (tester) async {
      final opened = await pump(tester, full, name: 'Trà Sữa & Bánh');
      await tester.tap(find.byKey(const Key('profile-open-web')));
      await tester.pump();
      expect(opened, [Uri.parse(webProfileUrl('Trà Sữa & Bánh'))]);
      expect(opened.single.queryParameters['player'], 'Trà Sữa & Bánh');
    },
  );

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('320px không tràn, tên dài + số cực lớn ($lang)', (
      tester,
    ) async {
      await pump(
        tester,
        full,
        locale: lang,
        size: const Size(320, 600),
        name: 'TenRatDaiTenRatDai20',
      );
      expect(tester.takeException(), isNull, reason: lang);
      expect(
        find.textContaining(RegExp(r'\{[a-z]+\}')),
        findsNothing,
        reason: lang,
      );
    });
  }
}
