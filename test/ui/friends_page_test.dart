// Bạn bè: danh sách + tặng quà (Xu chỉ cộng SAU khi server xác nhận), lời mời, tìm/kết bạn, BXH bạn bè,
// nhận quà, lỗi server, không tràn ở 320px mọi ngôn ngữ; hằng số/chữ ký khớp SQL.
import 'dart:io';

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/friends/friends.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/player_avatar.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/friends_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo implements FriendsRepository {
  FriendsOverview data = const FriendsOverview();
  List<FriendCandidate> found = const [];
  String requestResult = 'sent';
  FriendException? giftError;
  int gifts = 0;
  final log = <String>[];

  @override
  Future<FriendsOverview> overview() async => data;
  @override
  Future<List<FriendCandidate>> search(String nickname) async {
    log.add('search:$nickname');
    return found;
  }

  @override
  Future<String> request(String userId) async {
    log.add('request:$userId');
    return requestResult;
  }

  @override
  Future<void> respond(String userId, bool accept) async {
    log.add('respond:$userId:$accept');
    data = data.copyWith(incoming: [for (final r in data.incoming) if (r.userId != userId) r]);
  }

  @override
  Future<void> remove(String userId) async {
    log.add('remove:$userId');
    data = data.copyWith(friends: [for (final f in data.friends) if (f.userId != userId) f]);
  }

  @override
  Future<void> sendGift(String userId) async {
    if (giftError != null) throw giftError!;
    log.add('gift:$userId');
  }

  @override
  Future<int> claimGifts() async {
    log.add('claim');
    return gifts;
  }
}

Friend _f(String id, String name, {int stage = 3, double income = 1000, int xp = 0, int orders = 0, bool sent = false}) =>
    Friend(userId: id, nickname: name, stage: stage, income: income, seasonXp: xp, orders: orders, giftSent: sent);

Future<(ProviderContainer, _Repo)> _open(WidgetTester tester, _Repo repo,
    {String locale = 'vi', Size size = const Size(400, 800), String initialQuery = ''}) async {
  SharedPreferences.setMockInitialValues({'leaderboard_nickname': 'Tôi'});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 1000),
    friendsRepositoryProvider.overrideWithValue(repo),
    playerAvatarProvider.overrideWith((ref, n) async => ''),
  ]);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: FriendsPage(initialQuery: initialQuery),
    ),
  ));
  await tester.pumpAndSettle();
  return (c, repo);
}

Future<void> _done(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  test('hằng số quà và giới hạn khớp SQL', () {
    final sql = File('supabase/friends_schema.sql').readAsStringSync();
    expect(sql, contains('>= 50')); // trần bạn
    expect(sql, contains('>= 30')); // trần lời mời đang chờ
    for (final fn in ['friend_search', 'friend_request', 'friend_respond', 'friend_remove', 'friend_overview', 'friend_gift_send', 'friend_gift_claim']) {
      expect(sql, contains('function $fn('), reason: fn);
    }
  });

  test('friendErrorOf gom thông điệp server', () {
    expect(friendErrorOf('too many requests'), FriendError.limit);
    expect(friendErrorOf('friend limit'), FriendError.limit);
    expect(friendErrorOf('already sent'), FriendError.alreadySent);
    expect(friendErrorOf('email link required'), FriendError.linkRequired);
    expect(friendErrorOf('not friends'), FriendError.notFound);
    expect(friendErrorOf('socket'), FriendError.network);
  });

  test('friendRanking: mình lẫn bạn, giảm dần, hoà thì mình trước', () {
    const o = FriendsOverview(myIncome: 500, mySeasonXp: 10, myOrders: 3, friends: [
      Friend(userId: 'a', nickname: 'A', stage: 1, income: 900, seasonXp: 10, orders: 1, giftSent: false),
      Friend(userId: 'b', nickname: 'B', stage: 1, income: 100, seasonXp: 50, orders: 3, giftSent: false),
    ]);
    expect(friendRanking(o, FriendBoard.income, 'Tôi').map((r) => r.nickname), ['A', 'Tôi', 'B']);
    expect(friendRanking(o, FriendBoard.season, 'Tôi').map((r) => r.nickname), ['B', 'Tôi', 'A']);
    expect(friendRanking(o, FriendBoard.orders, 'Tôi').map((r) => r.nickname), ['Tôi', 'B', 'A']);
  });

  testWidgets('danh sách rỗng: gợi ý sang tab Thêm bạn', (tester) async {
    final (c, _) = await _open(tester, _Repo());
    expect(find.byKey(const Key('friends-empty')), findsOneWidget);
    await _done(tester, c);
  });

  testWidgets('tặng quà: server xác nhận rồi mới cộng Xu; nút chuyển sang đã tặng', (tester) async {
    final repo = _Repo()..data = FriendsOverview(friends: [_f('u1', 'Bình')]);
    final (c, _) = await _open(tester, repo);
    final before = c.read(gameControllerProvider).money;
    await tester.tap(find.byKey(const Key('friend-gift-u1')));
    await tester.pumpAndSettle();
    expect(repo.log, ['gift:u1']);
    expect(c.read(gameControllerProvider).money - before, greaterThanOrEqualTo(friendGiftFloor));
    expect(tester.widget<FilledButton>(find.byKey(const Key('friend-gift-u1'))).onPressed, isNull);
    await _done(tester, c);
  });

  testWidgets('tặng quà lỗi (đã tặng hôm nay): KHÔNG cộng Xu, báo lỗi', (tester) async {
    final repo = _Repo()
      ..data = FriendsOverview(friends: [_f('u1', 'Bình')])
      ..giftError = const FriendException(FriendError.alreadySent);
    final (c, _) = await _open(tester, repo);
    final before = c.read(gameControllerProvider).money;
    await tester.tap(find.byKey(const Key('friend-gift-u1')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).money, before);
    expect(find.textContaining('đã tặng quà'), findsOneWidget);
    await _done(tester, c);
  });

  testWidgets('nhận quà chờ: cộng theo số quà, thanh quà biến mất', (tester) async {
    final repo = _Repo()
      ..data = FriendsOverview(friends: [_f('u1', 'Bình')], giftsWaiting: 3)
      ..gifts = 3;
    final (c, _) = await _open(tester, repo);
    final before = c.read(gameControllerProvider).money;
    await tester.tap(find.byKey(const Key('friends-gift-claim')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).money - before, greaterThanOrEqualTo(3 * friendGiftFloor));
    expect(find.byKey(const Key('friends-gift-claim')), findsNothing);
    await _done(tester, c);
  });

  testWidgets('xoá bạn: hỏi xác nhận rồi gọi server', (tester) async {
    final repo = _Repo()..data = FriendsOverview(friends: [_f('u1', 'Bình')]);
    final (c, _) = await _open(tester, repo);
    await tester.tap(find.byKey(const Key('friend-remove-u1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('friend-remove-confirm')));
    await tester.pumpAndSettle();
    expect(repo.log, ['remove:u1']);
    expect(find.byKey(const Key('friend-u1')), findsNothing);
    await _done(tester, c);
  });

  testWidgets('lời mời: tab hiện số, chấp nhận gọi server rồi biến mất', (tester) async {
    final repo = _Repo()..data = const FriendsOverview(incoming: [FriendRequestIn('u9', 'Chi')]);
    final (c, _) = await _open(tester, repo);
    expect(find.text('Lời mời (1)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('friends-tab-requests')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request-accept-u9')));
    await tester.pumpAndSettle();
    expect(repo.log, ['respond:u9:true']);
    expect(find.byKey(const Key('friends-requests-empty')), findsOneWidget);
    await _done(tester, c);
  });

  testWidgets('thêm bạn: tìm theo tên, gửi lời mời; không thấy → báo', (tester) async {
    final repo = _Repo()..found = const [FriendCandidate('u5', 'Dũng', 7)];
    final (c, _) = await _open(tester, repo);
    await tester.tap(find.byKey(const Key('friends-tab-add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('friends-search-field')), 'Dũng');
    await tester.tap(find.byKey(const Key('friends-search-button')));
    await tester.pumpAndSettle();
    expect(repo.log, ['search:Dũng']);
    await tester.tap(find.byKey(const Key('candidate-add-u5')));
    await tester.pumpAndSettle();
    expect(repo.log.last, 'request:u5');
    expect(find.text('Đã gửi lời mời'), findsOneWidget);

    repo.found = const [];
    await tester.enterText(find.byKey(const Key('friends-search-field')), 'Zzz');
    await tester.tap(find.byKey(const Key('friends-search-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('friends-search-empty')), findsOneWidget);
    await _done(tester, c);
  });

  testWidgets('mở từ hồ sơ trùng tên: tab Thêm bạn có sẵn từ khoá và kết quả', (tester) async {
    final repo = _Repo()..found = const [FriendCandidate('a', 'Bình', 7), FriendCandidate('b', 'Bình', 1)];
    final (c, _) = await _open(tester, repo, initialQuery: 'Bình');
    expect(find.byKey(const Key('candidate-a')), findsOneWidget);
    expect(find.byKey(const Key('candidate-b')), findsOneWidget);
    await _done(tester, c);
  });

  testWidgets('BXH bạn bè: có dòng của mình, đổi bảng xếp lại', (tester) async {
    final repo = _Repo()
      ..data = FriendsOverview(myIncome: 500, mySeasonXp: 900, friends: [_f('u1', 'Bình', income: 900, xp: 10)]);
    final (c, _) = await _open(tester, repo);
    await tester.ensureVisible(find.byKey(const Key('friends-tab-rank')));
    await tester.tap(find.byKey(const Key('friends-tab-rank')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('friends-rank-row-0')), matching: find.text('Bình')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('friends-rank-row-1')), matching: find.textContaining('Tôi')), findsOneWidget);
    await tester.tap(find.byKey(const Key('friends-rank-season')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('friends-rank-row-0')), matching: find.textContaining('Tôi')), findsOneWidget);
    await _done(tester, c);
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th']) {
    testWidgets('không tràn ở 320px, chữ 1.5×, tên rất dài, quà chờ ($lang)', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final repo = _Repo()
        ..data = FriendsOverview(
          myIncome: 1e30,
          giftsWaiting: 12,
          friends: [_f('u1', 'Tên rất dài rất dài rất dài', income: 1e300), _f('u2', 'B', sent: true)],
          incoming: const [FriendRequestIn('u9', 'Một cái tên cực kỳ dài dòng')],
        )
        ..found = const [FriendCandidate('u5', 'Tên rất dài rất dài rất dài', 18)];
      final (c, _) = await _open(tester, repo, locale: lang, size: const Size(320, 640));
      for (final k in ['list', 'requests', 'add', 'rank']) {
        await tester.ensureVisible(find.byKey(Key('friends-tab-$k')));
        await tester.tap(find.byKey(Key('friends-tab-$k')));
        await tester.pumpAndSettle();
        if (k == 'add') {
          await tester.enterText(find.byKey(const Key('friends-search-field')), 'x');
          await tester.tap(find.byKey(const Key('friends-search-button')));
          await tester.pumpAndSettle();
        }
        final ex = tester.takeException();
        expect(ex, isNull, reason: '$lang $k ${ex is FlutterError ? ex.toStringDeep().split('\n').take(14).join('\n') : ''}');
      }
      await _done(tester, c);
    });
  }
}
