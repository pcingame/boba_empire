import 'package:boba_empire/core/format.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/topup.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/flair.dart';
import 'package:boba_empire/leaderboard/player_profile.dart';
import 'package:boba_empire/leaderboard/vip_leaderboard_controller.dart';
import 'package:boba_empire/leaderboard/vip_leaderboard_repository.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/vip_leaderboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRepo implements VipLeaderboardRepository {
  _FakeRepo(this.rows, {this.fail = false});
  final List<VipLeaderboardEntry> rows;
  bool fail;
  @override
  Future<List<VipLeaderboardEntry>> fetchTop({int limit = 50}) async {
    if (fail) throw StateError('mạng lỗi');
    return rows;
  }
}

VipLeaderboardEntry _e(String id, String name, int exp, int rank, {bool online = false}) =>
    VipLeaderboardEntry(
      userId: id,
      nickname: name,
      vipExp: exp,
      level: topupVipLevel(exp),
      rank: rank,
      online: online,
    );

class _FlairEmpty extends FlairCache {
  @override
  Map<String, String> build() => {};
}

Future<ProviderContainer> _open(
  WidgetTester tester, {
  required _FakeRepo repo,
  int vipExp = 0,
  String? nickname,
}) async {
  await tester.binding.setSurfaceSize(const Size(360, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({
    'leaderboard_nickname': ?nickname,
  });
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0)..vipExp = vipExp, nowMillis: 0);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
    vipLeaderboardRepositoryProvider.overrideWithValue(repo),
    flairCacheProvider.overrideWith(_FlairEmpty.new),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const VipLeaderboardPage(),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return container;
}

Future<void> _close(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  testWidgets('hiện hạng, nhãn VIP, biệt danh cấp, EXP và chấm xanh chỉ ở người online',
      (tester) async {
    final c = await _open(
      tester,
      repo: _FakeRepo([
        _e('u1', 'Alice', 12000, 1, online: true),
        _e('u2', 'Bob', 600, 2),
      ]),
      nickname: 'Me',
    );
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('VIP 5'), findsOneWidget);
    expect(find.text('Shop Owner'), findsOneWidget); // biệt danh cấp 5
    expect(find.text('VIP 1'), findsOneWidget);
    expect(find.text('Regular'), findsOneWidget);
    expect(find.text('${formatNumber(12000)} EXP'), findsOneWidget);
    expect(find.byKey(const Key('vip-lb-online')), findsOneWidget);
    // Người chơi chưa có VIP: hiện gợi ý đạt VIP 1.
    expect(find.byKey(const Key('vip-lb-no-vip')), findsOneWidget);
    await _close(tester, c);
  });

  testWidgets('đã có VIP mà chưa có biệt danh → form đặt biệt danh, nộp xong tải bảng',
      (tester) async {
    final c = await _open(
      tester,
      repo: _FakeRepo([_e('u1', 'Alice', 12000, 1)]),
      vipExp: topupTiers[0].exp,
    );
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Me');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Alice'), findsOneWidget);
    expect(find.byKey(const Key('vip-lb-no-vip')), findsNothing); // đã có VIP
    final prefs = c.read(sharedPreferencesProvider);
    expect(prefs.getString('leaderboard_nickname'), 'Me');
    await _close(tester, c);
  });

  testWidgets('bảng trống và lỗi mạng có thông báo, thử lại được', (tester) async {
    final repo = _FakeRepo([], fail: true);
    final c = await _open(tester, repo: repo, nickname: 'Me');
    expect(find.text('Retry'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Nobody is on the VIP leaderboard yet.'), findsOneWidget);
    await _close(tester, c);
  });

  testWidgets('bấm một dòng -> mở hồ sơ người đó (hạng + điểm từng bảng)', (tester) async {
    final c = await _open(
      tester,
      repo: _FakeRepo([_e('u1', 'Alice', 900, 1), _e('u2', 'Bob', 100, 2)]),
    );
    await tester.tap(find.byKey(const Key('vip-lb-row-u2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // Supabase chưa khởi tạo trong test -> RPC lỗi -> hộp thoại báo lỗi mạng, không crash.
    expect(find.text('Profile: Bob'), findsOneWidget);
    expect(find.byKey(const Key('profile-error')), findsOneWidget);
    expect(playerProfileProvider('Bob'), isNotNull);
    await _close(tester, c);
  });
}
