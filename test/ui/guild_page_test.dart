// Trang Hội: các trạng thái, luồng tạo/vào/rời/kick/nhận thưởng, và không tràn
// ở màn 320px mọi ngôn ngữ (tên hội/biệt danh rất dài).
import 'dart:ui' as ui;

import 'package:boba_empire/core/guild.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/guild/guild_controller.dart';
import 'package:boba_empire/guild/guild_repository.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/flair.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/guild_leaderboard_page.dart';
import 'package:boba_empire/ui/guild_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../guild/fake_guild_repository.dart';

final _now = DateTime.utc(2026, 10, 8).millisecondsSinceEpoch;

/// GameController có Timer.periodic: container phải dispose NGAY sau khi gỡ cây
/// widget, TRƯỚC bước kiểm "không còn timer" của flutter_test (addTearDown chạy
/// quá muộn) — xem bẫy ghi trong memory festival-event-quests.
final _live = <ProviderContainer>[];

/// Cuộn tới widget trong ListView (ListView dựng lười: chưa cuộn tới thì chưa có).
Future<void> _scrollTo(WidgetTester tester, Key key) =>
    tester.dragUntilVisible(
        find.byKey(key), find.byType(ListView), const Offset(0, -150));

/// Gỡ cây widget rồi dispose mọi container đang sống (dùng giữa hai lần _pump
/// trong cùng một test: hai GameController sống song song làm pumpAndSettle
/// không bao giờ yên).
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (final c in _live) {
    c.dispose();
  }
  _live.clear();
}

void gTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    try {
      await body(tester);
    } finally {
      await _teardown(tester);
    }
  });
}

class _Flair extends FlairCache {
  @override
  Map<String, String> build() => {};
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeGuildRepository repo, {
  String locale = 'vi',
  Widget home = const GuildPage(),
  double score = 0,
  double gems = 5000,
  Size size = const Size(320, 640),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: _now)
        ..gems = gems
        ..guildWeek = guildWeekIndex(_now)
        ..guildWeekScore = score,
      nowMillis: _now);
  final List<Override> overrides = [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => _now),
    guildRepositoryProvider.overrideWithValue(repo),
    flairCacheProvider.overrideWith(_Flair.new),
  ];
  final c = ProviderContainer(overrides: overrides);
  _live.add(c);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: ui.Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  ));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('chưa có hội', () {
    gTest('hiện danh sách công khai; vào hội qua hộp thoại tên', (tester) async {
      final repo = FakeGuildRepository(listing: sampleListing);
      await _pump(tester, repo);
      expect(find.textContaining('Public Club'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guild-join-g9')));
      await tester.pumpAndSettle();
      // Tên điền sẵn từ BXH (Alice).
      expect(find.widgetWithText(TextField, 'Alice'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guild-nickname-ok')));
      await tester.pumpAndSettle();
      expect(repo.lastJoin!['guildId'], 'g9');
      expect(repo.lastJoin!['nickname'], 'Alice');
      expect(find.textContaining('[BB] Boba Club'), findsOneWidget); // đã vào hội
    });

    gTest('không còn mã mời / hội riêng trong giao diện', (tester) async {
      await _pump(tester, FakeGuildRepository(listing: sampleListing));
      expect(find.byKey(const Key('guild-code-button')), findsNothing);
      await tester.tap(find.byKey(const Key('guild-create-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guild-public-switch')), findsNothing);
    });

    gTest('danh sách rỗng hiện lời mời tạo hội đầu tiên', (tester) async {
      await _pump(tester, FakeGuildRepository());
      expect(find.textContaining('Hãy tạo hội đầu tiên'), findsOneWidget);
    });

    gTest('hội đầy/không tồn tại: hiện thông báo lỗi đúng', (tester) async {
      final repo = FakeGuildRepository(listing: sampleListing)
        ..failures['join'] = const GuildException(GuildFailure.guildFull);
      await _pump(tester, repo);
      await tester.tap(find.byKey(const Key('guild-join-g9')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-nickname-ok')));
      await tester.pumpAndSettle();
      expect(find.text('Hội đã đủ thành viên.'), findsOneWidget);
      expect(find.byKey(const Key('guild-leave-button')), findsNothing);
    });

    gTest('báo cáo hội từ menu danh sách', (tester) async {
      final repo = FakeGuildRepository(listing: sampleListing);
      await _pump(tester, repo);
      await tester.tap(find.byKey(const Key('guild-menu-g9')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Báo cáo hội').last);
      await tester.pumpAndSettle();
      expect(repo.calls, contains('report'));
      expect(find.text('Đã gửi báo cáo, cảm ơn bạn.'), findsOneWidget);
    });

    gTest('tạo hội: tag sai bị chặn ngay (không gọi server); đúng thì tạo',
        (tester) async {
      final repo = FakeGuildRepository();
      await _pump(tester, repo, score: 99);
      await tester.tap(find.byKey(const Key('guild-create-button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('guild-name-field')), 'Boba Club');
      await tester.enterText(find.byKey(const Key('guild-tag-field')), 'b!');
      await tester.tap(find.byKey(const Key('guild-create-ok')));
      await tester.pumpAndSettle();
      expect(find.text('Tên hoặc tag không hợp lệ.'), findsOneWidget);
      expect(repo.lastCreate, isNull);

      await tester.tap(find.byKey(const Key('guild-create-button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('guild-name-field')), 'Boba Club');
      await tester.enterText(find.byKey(const Key('guild-tag-field')), 'bb');
      await tester.ensureVisible(find.byKey(const Key('guild-emoji-🐉')));
      await tester.tap(find.byKey(const Key('guild-emoji-🐉')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('guild-create-ok')));
      await tester.pumpAndSettle();
      expect(repo.lastCreate!['name'], 'Boba Club');
      expect(repo.lastCreate!['emoji'], '🐉');
      expect(repo.lastCreate!['score'], 99);
      expect(find.textContaining('Boba Club'), findsOneWidget);
    });

    gTest('hộp thoại tạo hội hiện phí 2000 💎', (tester) async {
      await _pump(tester, FakeGuildRepository());
      await tester.tap(find.byKey(const Key('guild-create-button')));
      await tester.pumpAndSettle();
      expect(find.text('Phí tạo hội: 2000 💎'), findsOneWidget);
    });

    gTest('thiếu 💎: thông báo cần 2000 💎, không gọi server, không trừ',
        (tester) async {
      final repo = FakeGuildRepository();
      final c = await _pump(tester, repo, gems: 1999);
      await tester.tap(find.byKey(const Key('guild-create-button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('guild-name-field')), 'Boba Club');
      await tester.enterText(find.byKey(const Key('guild-tag-field')), 'bb');
      await tester.tap(find.byKey(const Key('guild-create-ok')));
      await tester.pumpAndSettle();
      expect(find.text('Cần 2000 💎 để tạo hội.'), findsOneWidget);
      expect(repo.lastCreate, isNull);
      expect(c.read(gameControllerProvider).gems, 1999);
    });

    gTest('đủ 💎: tạo xong bị trừ đúng 2000', (tester) async {
      final repo = FakeGuildRepository();
      final c = await _pump(tester, repo, gems: 2500);
      await tester.tap(find.byKey(const Key('guild-create-button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('guild-name-field')), 'Boba Club');
      await tester.enterText(find.byKey(const Key('guild-tag-field')), 'bb');
      await tester.tap(find.byKey(const Key('guild-create-ok')));
      await tester.pumpAndSettle();
      expect(repo.lastCreate, isNotNull);
      expect(c.read(gameControllerProvider).gems, 500);
    });

    gTest('tên hội đã có → thông báo, vẫn ở màn chưa có hội', (tester) async {
      final repo = FakeGuildRepository()
        ..failures['create'] = const GuildException(GuildFailure.nameTaken);
      await _pump(tester, repo);
      await tester.tap(find.byKey(const Key('guild-create-button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('guild-name-field')), 'Boba Club');
      await tester.enterText(find.byKey(const Key('guild-tag-field')), 'bb');
      await tester.tap(find.byKey(const Key('guild-create-ok')));
      await tester.pumpAndSettle();
      expect(find.text('Tên hội đã có người dùng.'), findsOneWidget);
      expect(find.byKey(const Key('guild-create-button')), findsOneWidget);
    });
  });

  group('hội cần duyệt', () {
    const priv = GuildSummary(
        id: 'p1',
        name: 'Private Club',
        tag: 'PV',
        emoji: '🔒',
        memberCount: 3,
        weekTotal: 0,
        requiresApproval: true);
    const open = GuildSummary(
        id: 'o1',
        name: 'Open Club',
        tag: 'OP',
        emoji: '🟢',
        memberCount: 3,
        weekTotal: 0);

    gTest('danh sách: hội cần duyệt có 🔒 + "Xin vào", hội thường "Vào"',
        (tester) async {
      await _pump(tester, FakeGuildRepository(listing: [priv, open]));
      expect(find.textContaining('🔒 [PV] Private Club'), findsOneWidget);
      expect(find.textContaining('[OP] Open Club'), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const Key('guild-join-p1')), matching: find.text('Xin vào')),
          findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const Key('guild-join-o1')), matching: find.text('Vào')),
          findsOneWidget);
    });

    gTest('xin vào hội cần duyệt: gửi yêu cầu (KHÔNG vào hội), báo đã gửi, nút thành "Chờ duyệt"',
        (tester) async {
      final repo = FakeGuildRepository(listing: [priv]);
      await _pump(tester, repo, score: 12);
      await tester.tap(find.byKey(const Key('guild-join-p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-nickname-ok')));
      await tester.pumpAndSettle();
      expect(repo.lastRequest, {'guildId': 'p1', 'nickname': 'Alice', 'score': 12});
      expect(repo.lastJoin, isNull, reason: 'không được vào thẳng');
      expect(find.text('Đã gửi yêu cầu, chờ chủ hội duyệt.'), findsOneWidget);
      expect(find.byKey(const Key('guild-cancel-request-p1')), findsOneWidget);
      expect(find.byKey(const Key('guild-join-p1')), findsNothing);
    });

    gTest('bấm "Chờ duyệt" để hủy yêu cầu → quay lại "Xin vào"', (tester) async {
      final repo = FakeGuildRepository(listing: [priv]);
      await _pump(tester, repo);
      await tester.tap(find.byKey(const Key('guild-join-p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-nickname-ok')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-cancel-request-p1')));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('cancelRequest'));
      expect(find.byKey(const Key('guild-join-p1')), findsOneWidget);
    });

    gTest('hội thường: vào ngay, không qua đường xin duyệt', (tester) async {
      final repo = FakeGuildRepository(listing: [open]);
      await _pump(tester, repo);
      await tester.tap(find.byKey(const Key('guild-join-o1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-nickname-ok')));
      await tester.pumpAndSettle();
      expect(repo.lastJoin!['guildId'], 'o1');
      expect(repo.lastRequest, isNull);
    });

    gTest('hội đầy yêu cầu: thông báo đúng', (tester) async {
      final repo = FakeGuildRepository(listing: [priv])
        ..failures['requestJoin'] = const GuildException(GuildFailure.requestsFull);
      await _pump(tester, repo);
      await tester.tap(find.byKey(const Key('guild-join-p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-nickname-ok')));
      await tester.pumpAndSettle();
      expect(find.text('Hội đang có quá nhiều yêu cầu chờ duyệt.'), findsOneWidget);
    });

    gTest('tạo hội: mặc định không cần duyệt; bật công tắc thì gửi requiresApproval',
        (tester) async {
      for (final on in [false, true]) {
        final repo = FakeGuildRepository();
        await _pump(tester, repo);
        await tester.tap(find.byKey(const Key('guild-create-button')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('guild-name-field')), 'Boba Club');
        await tester.enterText(find.byKey(const Key('guild-tag-field')), 'bb');
        if (on) {
          await tester.ensureVisible(find.byKey(const Key('guild-approval-switch')));
          await tester.tap(find.byKey(const Key('guild-approval-switch')));
          await tester.pump();
        }
        await tester.tap(find.byKey(const Key('guild-create-ok')));
        await tester.pumpAndSettle();
        expect(repo.lastCreate!['requiresApproval'], on);
        await _teardown(tester);
      }
    });

    gTest('chủ hội thấy yêu cầu; thành viên thường KHÔNG thấy dù dữ liệu có',
        (tester) async {
      const reqs = [GuildJoinRequest(userId: 'r1', nickname: 'Rin')];
      await _pump(tester,
          FakeGuildRepository(mine: fakeGuild(requiresApproval: true, requests: reqs)));
      expect(find.text('Yêu cầu vào hội (1)'), findsOneWidget);
      expect(find.byKey(const Key('guild-accept-r1')), findsOneWidget);
      await _teardown(tester);
      await _pump(
          tester,
          FakeGuildRepository(
              mine: fakeGuild(ownerId: 'u2', requiresApproval: true, requests: reqs)));
      expect(find.textContaining('Yêu cầu vào hội'), findsNothing);
      expect(find.byKey(const Key('guild-accept-r1')), findsNothing);
    });

    gTest('duyệt → thành viên mới xuất hiện, yêu cầu biến mất; từ chối → chỉ biến mất',
        (tester) async {
      final repo = FakeGuildRepository(
          mine: fakeGuild(requiresApproval: true, requests: const [
        GuildJoinRequest(userId: 'r1', nickname: 'Rin'),
        GuildJoinRequest(userId: 'r2', nickname: 'Rex'),
      ]));
      await _pump(tester, repo);
      await tester.tap(find.byKey(const Key('guild-accept-r1')));
      await tester.pumpAndSettle();
      expect(repo.responded, ['r1:accept']);
      expect(find.text('Yêu cầu vào hội (1)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guild-reject-r2')));
      await tester.pumpAndSettle();
      expect(repo.responded, ['r1:accept', 'r2:reject']);
      expect(find.textContaining('Yêu cầu vào hội'), findsNothing);
      await _scrollTo(tester, const Key('guild-leave-button'));
      expect(find.text('Rin'), findsOneWidget); // đã vào danh sách thành viên
      expect(find.text('Rex'), findsNothing);
    });

    gTest('duyệt lỗi (hội đầy): thông báo, yêu cầu còn đó', (tester) async {
      final repo = FakeGuildRepository(
          mine: fakeGuild(requiresApproval: true, requests: const [
        GuildJoinRequest(userId: 'r1', nickname: 'Rin'),
      ]))
        ..failures['respondRequest'] = const GuildException(GuildFailure.guildFull);
      await _pump(tester, repo);
      await tester.tap(find.byKey(const Key('guild-accept-r1')));
      await tester.pumpAndSettle();
      expect(find.text('Hội đã đủ thành viên.'), findsOneWidget);
      expect(find.byKey(const Key('guild-accept-r1')), findsOneWidget);
    });
  });

  group('đang ở hội', () {
    gTest('hiện tên, mã mời, thành viên; chủ hội thấy nút kick, thành viên thì không',
        (tester) async {
      await _pump(tester, FakeGuildRepository(mine: fakeGuild()));
      expect(find.textContaining('[BB] Boba Club'), findsOneWidget);
      expect(find.byKey(const Key('guild-kick-u2')), findsOneWidget);
      expect(find.byKey(const Key('guild-kick-me')), findsNothing, reason: 'không tự kick');
    });

    gTest('không phải chủ → không có nút kick', (tester) async {
      await _pump(tester, FakeGuildRepository(mine: fakeGuild(ownerId: 'u2')));
      expect(find.byKey(const Key('guild-kick-u3')), findsNothing);
    });

    gTest('kick: hỏi xác nhận rồi gọi server; huỷ thì không', (tester) async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      await _pump(tester, repo);
      await tester.tap(find.byKey(const Key('guild-kick-u2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy').evaluate().isNotEmpty ? find.text('Hủy') : find.text('Huỷ'));
      await tester.pumpAndSettle();
      expect(repo.calls.contains('kick'), isFalse);
      await tester.tap(find.byKey(const Key('guild-kick-u2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-confirm-ok')));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('kick'));
      expect(find.byKey(const Key('guild-kick-u2')), findsNothing);
    });

    gTest('rời hội: hỏi xác nhận rồi về màn chưa có hội', (tester) async {
      final repo = FakeGuildRepository(mine: fakeGuild(), listing: sampleListing);
      await _pump(tester, repo);
      await _scrollTo(tester, const Key('guild-leave-button'));
      await tester.tap(find.byKey(const Key('guild-leave-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-confirm-ok')));
      await tester.pumpAndSettle();
      expect(repo.mine, isNull);
      expect(find.byKey(const Key('guild-create-button')), findsOneWidget);
    });

    gTest('nút nhận: chỉ bật khi hội đạt mốc VÀ mình đóng góp đủ; chưa đủ có gợi ý',
        (tester) async {
      // Hội 15.000 (đạt mốc 1), mình 400 điểm → nhận được mốc 1, mốc 2/3 khoá.
      await _pump(tester, FakeGuildRepository(mine: fakeGuild(total: 15000)));
      FilledButton b(int i) => tester.widget<FilledButton>(
          find.byKey(Key('guild-claim-$i')));
      await _scrollTo(tester, const Key('guild-claim-0'));
      expect(b(0).onPressed, isNotNull);
      expect(b(1).onPressed, isNull);
      expect(b(2).onPressed, isNull);
    });

    gTest('đạt mốc nhưng đóng góp < tối thiểu: khoá + hiện gợi ý',
        (tester) async {
      final g = fakeGuild(total: 15000, members: const [
        GuildMemberInfo(userId: 'me', nickname: 'Alice', points: 50),
        GuildMemberInfo(userId: 'u2', nickname: 'Bob', points: 14950),
      ]);
      await _pump(tester, FakeGuildRepository(mine: g));
      await _scrollTo(tester, const Key('guild-claim-0'));
      expect(tester.widget<FilledButton>(find.byKey(const Key('guild-claim-0'))).onPressed,
          isNull);
      expect(find.textContaining('≥300'), findsOneWidget);
    });

    gTest('mốc đã nhận hiện "Đã nhận" và khoá', (tester) async {
      await _pump(tester,
          FakeGuildRepository(mine: fakeGuild(total: 15000, claimed: const [1])));
      await _scrollTo(tester, const Key('guild-claim-0'));
      expect(find.text('Đã nhận'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('guild-claim-0'))).onPressed,
          isNull);
    });

    gTest('bấm nhận: cộng 💎 cục bộ, hiện thông báo, nút chuyển "Đã nhận"',
        (tester) async {
      final repo = FakeGuildRepository(mine: fakeGuild(total: 15000));
      final c = await _pump(tester, repo);
      final gems0 = c.read(gameControllerProvider).gems;
      await _scrollTo(tester, const Key('guild-claim-0'));
      await tester.tap(find.byKey(const Key('guild-claim-0')));
      await tester.pumpAndSettle();
      expect(c.read(gameControllerProvider).gems, gems0 + guildMilestones[0].gems);
      expect(find.text('Nhận +${guildMilestones[0].gems} 💎'), findsOneWidget);
      expect(find.text('Đã nhận'), findsOneWidget);
    });

    gTest('server từ chối nhận: thông báo lỗi, KHÔNG cộng 💎', (tester) async {
      final repo = FakeGuildRepository(mine: fakeGuild(total: 15000))
        ..failures['claimReward'] =
            const GuildException(GuildFailure.notEnoughContribution);
      final c = await _pump(tester, repo);
      final gems0 = c.read(gameControllerProvider).gems;
      await _scrollTo(tester, const Key('guild-claim-0'));
      await tester.tap(find.byKey(const Key('guild-claim-0')));
      await tester.pumpAndSettle();
      expect(c.read(gameControllerProvider).gems, gems0);
      expect(find.text('Bạn cần đóng góp thêm điểm trong tuần này.'), findsOneWidget);
    });
  });

  gTest('lỗi mạng khi tải: hiện nút thử lại và thử lại được', (tester) async {
    final repo = FakeGuildRepository(listing: sampleListing)
      ..failures['myGuild'] = const GuildException(GuildFailure.network);
    await _pump(tester, repo);
    expect(find.text('Không kết nối được, thử lại sau nhé.'), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('Public Club'), findsOneWidget);
  });

  group('BXH hội', () {
    gTest('hiện hạng, tên, điểm; tên rất dài không tràn', (tester) async {
      final repo = FakeGuildRepository()
        ..board = const [
          GuildSummary(
              id: 'a', name: 'TênHộiRấtRấtRấtDàiĐếnMứcPhảiCắt', tag: 'AA',
              emoji: '🐉', memberCount: 30, weekTotal: 999999999, rank: 1),
          GuildSummary(
              id: 'b', name: 'Nhỏ', tag: 'BB', emoji: '🧋',
              memberCount: 2, weekTotal: 5, rank: 2),
        ];
      await _pump(tester, repo, home: const GuildLeaderboardPage());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('[BB] Nhỏ'), findsOneWidget);
    });

    gTest('rỗng và lỗi', (tester) async {
      await _pump(tester, FakeGuildRepository(), home: const GuildLeaderboardPage());
      expect(find.text('Tuần này chưa hội nào có điểm.'), findsOneWidget);
      await _teardown(tester);
      final bad = FakeGuildRepository()
        ..failures['leaderboard'] = const GuildException(GuildFailure.network);
      await _pump(tester, bad, home: const GuildLeaderboardPage());
      expect(find.byType(FilledButton), findsOneWidget);
    });

    gTest('mở BXH từ nút trên trang Hội', (tester) async {
      final repo = FakeGuildRepository()..board = const [];
      await _pump(tester, repo);
      await tester.tap(find.byKey(const Key('guild-leaderboard-button')));
      await tester.pumpAndSettle();
      expect(find.text('Tuần này chưa hội nào có điểm.'), findsOneWidget);
    });
  });

  for (final locale in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    gTest('[$locale] không tràn trên 320px: danh sách, hội của mình, hộp thoại',
        (tester) async {
      const longName = 'MộtCáiTênHộiDàiDằngDặcKhôngCóKhoảngTrắng';
      final none = FakeGuildRepository(listing: const [
        GuildSummary(
            id: 'g9', name: longName, tag: 'ABCD', emoji: '🐉',
            memberCount: 30, weekTotal: 999999999, requiresApproval: true),
        GuildSummary(
            id: 'g8', name: longName, tag: 'EFGH', emoji: '🐉',
            memberCount: 30, weekTotal: 999999999, requiresApproval: true,
            requested: true),
      ]);
      await _pump(tester, none, locale: locale);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('guild-create-button')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('guild-create-ok')).hitTestable().first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await _teardown(tester);
      final mine = FakeGuildRepository(
        mine: fakeGuild(name: longName, total: 150000, requiresApproval: true,
            requests: const [
              GuildJoinRequest(userId: 'r1', nickname: 'Người Xin Vào Với Cái Tên Rất Rất Dài'),
            ],
            members: const [
          GuildMemberInfo(
              userId: 'me', nickname: 'Biệt Danh Rất Dài Nhưng Phải Vừa', points: 99999999),
          GuildMemberInfo(userId: 'u2', nickname: longName, points: 12345678),
        ]),
      );
      await _pump(tester, mine, locale: locale);
      expect(tester.takeException(), isNull);
      await tester.dragUntilVisible(find.byKey(const Key('guild-leave-button')),
          find.byType(ListView), const Offset(0, -200));
      expect(tester.takeException(), isNull);
    });
  }
}
