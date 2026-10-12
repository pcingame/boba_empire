// Trang Hội: các trạng thái, luồng tạo/vào/rời/kick/nhận thưởng, và không tràn
// ở màn 320px mọi ngôn ngữ (tên hội/biệt danh rất dài).
import 'dart:ui' as ui;

import 'package:boba_empire/core/format.dart';
import 'package:boba_empire/core/guild.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/topup.dart';
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
Future<void> _scrollTo(WidgetTester tester, Key key) async {
  await tester.dragUntilVisible(
      find.byKey(key), find.byType(ListView), const Offset(0, -150));
  // dragUntilVisible dừng khi widget vừa được dựng (có thể còn lấp ló dưới mép màn): kéo hẳn vào
  // vùng nhìn thấy để tap() trúng.
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
}

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

/// Cấp VIP giả theo userId (me=2 không khung; u2=5; u3=10).
class _Vips extends VipLevels {
  @override
  Map<String, int> build() => {'me': 2, 'u2': 5, 'u3': 10, 'r1': 6};
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
  List<Override> extra = const [],
  int vipExp = 0,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: _now)
        ..gems = gems
        ..vipExp = vipExp
        ..guildWeek = guildWeekIndex(_now)
        ..guildWeekScore = score,
      nowMillis: _now);
  final List<Override> overrides = [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => _now),
    guildRepositoryProvider.overrideWithValue(repo),
    flairCacheProvider.overrideWith(_Flair.new),
    ...extra,
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
      await _scrollTo(tester, const Key('guild-kick-u2'));
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
      await _scrollTo(tester, const Key('guild-kick-u2'));
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

  group('phí tạo hội theo VIP (giao diện)', () {
    Future<void> openCreate(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('guild-create-button')));
      await tester.pumpAndSettle();
    }

    gTest('không VIP: phí 2000, không dòng ưu đãi', (tester) async {
      await _pump(tester, FakeGuildRepository(listing: sampleListing), locale: 'en');
      await openCreate(tester);
      expect(find.text('Guild creation fee: 2000 💎'), findsOneWidget);
      expect(find.byKey(const Key('guild-create-discount')), findsNothing);
    });

    gTest('VIP 8: phí 1000 kèm dòng ưu đãi 50%', (tester) async {
      await _pump(tester, FakeGuildRepository(listing: sampleListing),
          locale: 'en', vipExp: topupTiers[7].exp);
      await openCreate(tester);
      expect(find.text('Guild creation fee: 1000 💎'), findsOneWidget);
      expect(find.text('VIP perk: 50% off the guild creation fee'), findsOneWidget);
    });

    gTest('VIP 10: phí 0 kèm ưu đãi 100%', (tester) async {
      await _pump(tester, FakeGuildRepository(listing: sampleListing),
          locale: 'en', vipExp: topupTiers[9].exp);
      await openCreate(tester);
      expect(find.text('Guild creation fee: 0 💎'), findsOneWidget);
      expect(find.text('VIP perk: 100% off the guild creation fee'), findsOneWidget);
    });

    gTest('thiếu 💎 nạp/tặng không còn báo nhầm "cần 2000 💎 để tạo hội"', (tester) async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      await _pump(tester, repo, locale: 'en', gems: 5);
      await _scrollTo(tester, const Key('guild-gift-u2'));
      await tester.tap(find.byKey(const Key('guild-gift-u2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-gift-amount-10')));
      await tester.pumpAndSettle();
      expect(find.text('Not enough 💎.'), findsOneWidget);
      expect(find.textContaining('to create a guild'), findsNothing);
    });
  });

  group('Boss Hội (giao diện)', () {
    // fakeGuild: ở test này người chơi (me) có điểm tuần 400 ≥ 300 nên đủ điều kiện nhận.
    String bossName(int idx) => const [
          'Pearl Dragon', 'Shaved-Ice Titan', 'Black-Tea Kraken',
          'Pudding Bear', 'Matcha Tiger', 'Cheese-Foam Phoenix',
        ][idx];

    gTest('server cũ chưa có boss (HP 0): không hiện thẻ', (tester) async {
      await _pump(tester, FakeGuildRepository(mine: fakeGuild()), locale: 'en');
      await _scrollTo(tester, const Key('guild-leave-button'));
      expect(find.byKey(const Key('guild-boss')), findsNothing);
    });

    gTest('boss còn sống: tên theo tuần, bậc, tiến độ; chưa có nút nhận', (tester) async {
      final repo = FakeGuildRepository(
          mine: fakeGuild(total: 12000, bossHp: 36000, bossTier: 2));
      await _pump(tester, repo, locale: 'en');
      await _scrollTo(tester, const Key('guild-boss'));
      final idx = guildBossIndex(guildWeekIndex(_now));
      expect(find.text(bossName(idx)), findsOneWidget);
      expect(find.text(guildBossEmojis[idx]), findsOneWidget);
      expect(find.text('Tier 3'), findsOneWidget); // bậc 2 hiển thị là "Bậc 3" (bắt đầu từ 1)
      expect(find.text('${formatNumber(12000)} / ${formatNumber(36000)} damage'),
          findsOneWidget);
      expect(find.byKey(const Key('guild-boss-claim')), findsNothing);
    });

    gTest('hạ boss + đủ điểm: nhận rương → cộng 💎, nút đổi thành "đã nhận"', (tester) async {
      final repo = FakeGuildRepository(
          mine: fakeGuild(total: 40000, bossHp: 36000, bossTier: 2));
      final c = await _pump(tester, repo, locale: 'en', gems: 0);
      await _scrollTo(tester, const Key('guild-boss-claim'));
      await tester.ensureVisible(find.byKey(const Key('guild-boss-claim')));
      await tester.pumpAndSettle();
      expect(find.text('Claim chest: +200 💎 +300 Guild Coins'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guild-boss-claim')));
      await tester.pumpAndSettle();
      expect(c.read(gameControllerProvider).gems, 200);
      expect(find.text('Chest claimed'), findsOneWidget);
      expect(find.text('Boss chest: +200 💎 +300 Guild Coins'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('guild-boss-claim'))).onPressed,
          isNull);
    });

    gTest('hạ boss nhưng mình chưa đủ điểm tối thiểu: nút tắt + lời nhắc', (tester) async {
      final repo = FakeGuildRepository(
          mine: fakeGuild(total: 40000, bossHp: 36000, bossTier: 0, members: const [
        GuildMemberInfo(userId: 'me', nickname: 'Alice', points: 100),
        GuildMemberInfo(userId: 'u2', nickname: 'Bob', points: 39900),
      ]));
      await _pump(tester, repo, locale: 'en');
      await _scrollTo(tester, const Key('guild-boss-claim'));
      expect(tester.widget<FilledButton>(find.byKey(const Key('guild-boss-claim'))).onPressed,
          isNull);
      expect(find.textContaining('300'), findsWidgets);
    });

    gTest('đã nhận rương từ trước (từ server): nút tắt, ghi "đã nhận"', (tester) async {
      final repo = FakeGuildRepository(
          mine: fakeGuild(total: 99999, bossHp: 36000, bossClaimed: true));
      await _pump(tester, repo, locale: 'en');
      await _scrollTo(tester, const Key('guild-boss-claim'));
      expect(find.text('Chest claimed'), findsOneWidget);
    });

    gTest('server từ chối nhận (boss chưa hạ): hiện lỗi, không cộng 💎', (tester) async {
      final repo = FakeGuildRepository(
          mine: fakeGuild(total: 40000, bossHp: 36000))
        ..failures['claimBoss'] = const GuildException(GuildFailure.bossAlive);
      final c = await _pump(tester, repo, locale: 'en', gems: 0);
      await _scrollTo(tester, const Key('guild-boss-claim'));
      await tester.ensureVisible(find.byKey(const Key('guild-boss-claim')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-boss-claim')));
      await tester.pumpAndSettle();
      expect(find.text('The boss is still alive.'), findsOneWidget);
      expect(c.read(gameControllerProvider).gems, 0);
    });

    for (final lang in ['vi', 'es', 'id', 'pt', 'th', 'ko']) {
      gTest('thẻ boss bậc 5 đã hạ không tràn ở 320px ($lang)', (tester) async {
        final repo = FakeGuildRepository(
            mine: fakeGuild(total: 99999999, bossHp: 48000, bossTier: 4));
        await _pump(tester, repo, locale: lang);
        await _scrollTo(tester, const Key('guild-boss-claim'));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('thưởng thu nhập theo VIP của hội (giao diện)', () {
    gTest('có VIP: hiện đúng số thành viên và % (tham số không bị đảo)', (tester) async {
      await _pump(
          tester, FakeGuildRepository(mine: fakeGuild(vipMembers: 3, vipBonus: 3)),
          locale: 'en');
      expect(find.text('VIP bonus: 3 VIP members → +3% income for the whole guild'),
          findsOneWidget);
    });

    gTest('chạm vào dòng thưởng: hiện cách có thưởng, đúng số (tham số không bị đảo)',
        (tester) async {
      await _pump(
          tester, FakeGuildRepository(mine: fakeGuild(vipMembers: 3, vipBonus: 3)),
          locale: 'en');
      await tester.tap(find.byKey(const Key('guild-vip-bonus')));
      await tester.pumpAndSettle();
      expect(
          find.text('Each member at VIP 5+ adds +1% income for the whole guild (max +5%)'),
          findsOneWidget);
    });

    for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
      gTest('dòng thưởng VIP + gợi ý không tràn ở 320px ($lang)', (tester) async {
        await _pump(tester,
            FakeGuildRepository(mine: fakeGuild(vipMembers: 12, vipBonus: 5)),
            locale: lang);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('guild-vip-bonus')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    gTest('chưa có VIP: không có dòng thưởng, không chiếm chỗ', (tester) async {
      await _pump(tester, FakeGuildRepository(mine: fakeGuild()), locale: 'en');
      expect(find.byKey(const Key('guild-vip-bonus')), findsNothing);
    });
  });

  group('VIP trong Hội', () {
    final vip = [vipLevelProvider.overrideWith(_Vips.new)];

    gTest('danh sách thành viên: nhãn VIP, khung theo cấp và dòng danh hiệu từ VIP 5',
        (tester) async {
      await _pump(tester, FakeGuildRepository(mine: fakeGuild()),
          locale: 'en', extra: vip, size: const Size(360, 900));
      await _scrollTo(tester, const Key('guild-gift-u3'));
      expect(find.text('VIP 2'), findsOneWidget);
      expect(find.text('VIP 5'), findsOneWidget);
      expect(find.text('VIP 10'), findsOneWidget);
      // Khung: chỉ cấp ≥ 3 (u2, u3); dòng danh hiệu: chỉ cấp ≥ 5 (u2, u3).
      expect(find.byKey(const Key('vip-frame')), findsNWidgets(2));
      expect(find.text('👑 Shop Owner'), findsOneWidget);
      expect(find.text('👑 Boba Emperor'), findsOneWidget);
      expect(find.byKey(const Key('vip-title-line')), findsNWidgets(2));
    });

    gTest('đơn xin vào hội: chủ hội thấy nhãn VIP của người xin', (tester) async {
      final repo = FakeGuildRepository(
          mine: fakeGuild(
              requests: const [GuildJoinRequest(userId: 'r1', nickname: 'Người Xin')]));
      await _pump(tester, repo, locale: 'en', extra: vip);
      expect(find.text('Người Xin'), findsOneWidget);
      expect(find.text('VIP 6'), findsOneWidget);
      expect(find.byKey(const Key('guild-accept-r1')), findsOneWidget);
    });

    for (final lang in ['vi', 'es', 'th', 'ko']) {
      gTest('VIP 10 + tên rất dài không tràn ở 320px ($lang)', (tester) async {
        const longName = 'MộtBiệtDanhRấtRấtDàiNhưThế';
        final repo = FakeGuildRepository(
            mine: fakeGuild(members: const [
          GuildMemberInfo(userId: 'me', nickname: 'Alice', points: 400),
          GuildMemberInfo(userId: 'u3', nickname: longName, points: 12345678),
        ]));
        await _pump(tester, repo, locale: lang, extra: vip);
        await _scrollTo(tester, const Key('guild-gift-u3'));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('tặng 💎 giữa hội viên', () {
    gTest('mọi hội viên khác có nút tặng; chính mình thì không', (tester) async {
      await _pump(tester, FakeGuildRepository(mine: fakeGuild()), locale: 'en');
      await _scrollTo(tester, const Key('guild-gift-u3'));
      expect(find.byKey(const Key('guild-gift-u2')), findsOneWidget);
      expect(find.byKey(const Key('guild-gift-u3')), findsOneWidget);
      expect(find.byKey(const Key('guild-gift-me')), findsNothing);
    });

    gTest('chọn mức tặng → gửi lên server, trừ 💎, báo đã tặng', (tester) async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      final c = await _pump(tester, repo, locale: 'en', gems: 100);
      await _scrollTo(tester, const Key('guild-gift-u2'));
      await tester.tap(find.byKey(const Key('guild-gift-u2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guild-gift-dialog')), findsOneWidget);
      for (final a in guildGiftAmounts) {
        expect(find.byKey(Key('guild-gift-amount-$a')), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('guild-gift-amount-20')));
      await tester.pumpAndSettle();
      expect(repo.sentGifts, [('u2', 20)]);
      expect(c.read(gameControllerProvider).gems, 80);
      expect(find.text('Sent 20 💎 to Bob'), findsOneWidget);
    });

    gTest('thiếu 💎 → báo lỗi, không gửi', (tester) async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      final c = await _pump(tester, repo, locale: 'en', gems: 5);
      await _scrollTo(tester, const Key('guild-gift-u2'));
      await tester.tap(find.byKey(const Key('guild-gift-u2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-gift-amount-10')));
      await tester.pumpAndSettle();
      expect(repo.sentGifts, isEmpty);
      expect(c.read(gameControllerProvider).gems, 5);
    });

    gTest('hộp thư: thẻ quà hiện khi có quà, nhận → cộng 💎 và thẻ biến mất',
        (tester) async {
      final repo = FakeGuildRepository(mine: fakeGuild())
        ..gifts = [const GuildGift(id: 7, fromNickname: 'Bob', amount: 20)];
      final c = await _pump(tester, repo, locale: 'en', gems: 0);
      expect(find.byKey(const Key('guild-gift-inbox')), findsOneWidget);
      expect(find.text('Bob · +20 💎'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guild-gift-claim-7')));
      await tester.pumpAndSettle();
      expect(c.read(gameControllerProvider).gems, 20);
      expect(find.byKey(const Key('guild-gift-inbox')), findsNothing);
    });

    gTest('không có quà → không có thẻ quà', (tester) async {
      await _pump(tester, FakeGuildRepository(mine: fakeGuild()), locale: 'en');
      expect(find.byKey(const Key('guild-gift-inbox')), findsNothing);
    });

    for (final lang in ['vi', 'es', 'th', 'ko']) {
      gTest('không tràn ở 320px khi có quà và nút tặng ($lang)', (tester) async {
        final repo = FakeGuildRepository(mine: fakeGuild())
          ..gifts = [
            const GuildGift(id: 1, fromNickname: 'MộtBiệtDanhRấtDàiNhưThế', amount: 50),
          ];
        await _pump(tester, repo, locale: lang);
        expect(tester.takeException(), isNull);
        await _scrollTo(tester, const Key('guild-gift-u2'));
        expect(tester.takeException(), isNull);
      });
    }
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

    gTest('tab VIP: xếp hội theo tổng VIP EXP, có ghi chú; rỗng và lỗi có thông báo', (tester) async {
      final repo = FakeGuildRepository()
        ..boardVip = const [
          GuildSummary(
              id: 'a', name: 'Rồng Vàng', tag: 'RV', emoji: '🐉',
              memberCount: 10, weekTotal: 100, rank: 1, vipExp: 123456),
          GuildSummary(
              id: 'b', name: 'Nhỏ', tag: 'BB', emoji: '🧋',
              memberCount: 2, weekTotal: 5, rank: 2, vipExp: 600),
        ];
      await _pump(tester, repo, home: const GuildLeaderboardPage(), locale: 'en');
      // Thanh tab cuộn ngang ở màn hẹp: cuộn tới tab VIP trước khi bấm.
      await tester.ensureVisible(find.byKey(const Key('guild-lb-tab-vip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-lb-tab-vip')));
      await tester.pumpAndSettle();
      expect(find.textContaining('[RV] Rồng Vàng'), findsOneWidget);
      expect(find.text('${formatNumber(123456)} EXP'), findsOneWidget);
      expect(find.text('${formatNumber(600)} EXP'), findsOneWidget);
      expect(find.byKey(const Key('guild-lb-note')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _teardown(tester);

      await _pump(tester, FakeGuildRepository(), home: const GuildLeaderboardPage(), locale: 'en');
      // Thanh tab cuộn ngang ở màn hẹp: cuộn tới tab VIP trước khi bấm.
      await tester.ensureVisible(find.byKey(const Key('guild-lb-tab-vip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-lb-tab-vip')));
      await tester.pumpAndSettle();
      expect(find.text('No guild has VIP members on the board yet.'), findsOneWidget);
      await _teardown(tester);

      final bad = FakeGuildRepository()
        ..failures['leaderboardVip'] = const GuildException(GuildFailure.network);
      await _pump(tester, bad, home: const GuildLeaderboardPage(), locale: 'en');
      // Thanh tab cuộn ngang ở màn hẹp: cuộn tới tab VIP trước khi bấm.
      await tester.ensureVisible(find.byKey(const Key('guild-lb-tab-vip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-lb-tab-vip')));
      await tester.pumpAndSettle();
      expect(find.byType(FilledButton), findsOneWidget); // Thử lại
    });

    for (final lang in ['vi', 'es', 'th', 'ko', 'id', 'pt']) {
      gTest('4 tab BXH Hội không tràn ở 320px ($lang)', (tester) async {
        final repo = FakeGuildRepository()
          ..boardVip = const [
            GuildSummary(
                id: 'a', name: 'TênHộiRấtRấtRấtDàiĐếnMứcPhảiCắt', tag: 'AAAA', emoji: '🐉',
                memberCount: 30, weekTotal: 1, rank: 1, vipExp: 99999999999),
          ];
        await _pump(tester, repo, home: const GuildLeaderboardPage(), locale: lang);
        expect(tester.takeException(), isNull);
        for (final k in ['total', 'avg', 'streak', 'vip']) {
          await tester.ensureVisible(find.byKey(Key('guild-lb-tab-$k')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(Key('guild-lb-tab-$k')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$lang tab $k');
        }
      });
    }

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

  group('giao diện nâng cấp', () {
    gTest('banner: chip chuỗi/VIP/buff chỉ hiện khi có giá trị', (tester) async {
      await _pump(tester, FakeGuildRepository(mine: fakeGuild()));
      for (final k in ['guild-streak', 'guild-vip-bonus', 'guild-buff-line']) {
        expect(find.byKey(Key(k)), findsNothing, reason: k);
      }
      await _teardown(tester);
      await _pump(
          tester,
          FakeGuildRepository(
              mine: fakeGuild(streak: 3, vipMembers: 2, vipBonus: 2, buffSeconds: 3600)));
      for (final k in ['guild-streak', 'guild-vip-bonus', 'guild-buff-line']) {
        expect(find.byKey(Key(k)), findsOneWidget, reason: k);
      }
    });

    gTest('lối tắt Chat/Hoạt động nằm trong trang, không còn ở thanh tiêu đề', (tester) async {
      await _pump(tester, FakeGuildRepository(mine: fakeGuild()));
      for (final k in ['guild-chat-button', 'guild-activity-button']) {
        expect(find.byKey(Key(k)), findsOneWidget, reason: k);
        expect(find.descendant(of: find.byType(AppBar), matching: find.byKey(Key(k))), findsNothing,
            reason: '$k không còn ở AppBar');
      }
      expect(find.descendant(of: find.byType(AppBar), matching: find.byKey(const Key('guild-leaderboard-button'))),
          findsOneWidget);
    });

    gTest('huy chương chỉ cho top 3 có điểm; người 0 điểm không có', (tester) async {
      final g = fakeGuild(members: const [
        GuildMemberInfo(userId: 'me', nickname: 'Alice', points: 400),
        GuildMemberInfo(userId: 'u2', nickname: 'Bob', points: 100),
        GuildMemberInfo(userId: 'u3', nickname: 'Cy', points: 0),
        GuildMemberInfo(userId: 'u4', nickname: 'Dee', points: 0),
      ]);
      await _pump(tester, FakeGuildRepository(mine: g));
      await _scrollTo(tester, const Key('guild-leave-button'));
      expect(find.text('🥇 '), findsOneWidget);
      expect(find.text('🥈 '), findsOneWidget);
      expect(find.text('🥉 '), findsNothing, reason: 'hạng 3 có 0 điểm');
    });

    gTest('vòng trạng thái mốc: 🔒 chưa đạt, 🎁 nhận được, ✅ đã nhận, ⚠️ thiếu điểm cá nhân',
        (tester) async {
      // Tổng 50000: mốc 1 (10k) và mốc 2 (40k) đạt, mốc 3 (120k) chưa. Mốc 1 đã nhận.
      await _pump(tester, FakeGuildRepository(mine: fakeGuild(total: 50000, claimed: const [1])));
      await _scrollTo(tester, const Key('guild-claim-2'));
      expect(find.text('✅'), findsOneWidget);
      expect(find.text('🎁'), findsWidgets); // mốc 2 nhận được (🎁 còn xuất hiện ở phần thưởng mốc cuối)
      expect(find.text('🔒'), findsOneWidget);
      await _teardown(tester);
      // Mình chỉ 50 điểm (<300): mốc đạt nhưng chưa nhận được → ⚠️.
      await _pump(
          tester,
          FakeGuildRepository(
              mine: fakeGuild(total: 15000, members: const [
            GuildMemberInfo(userId: 'me', nickname: 'Alice', points: 50),
            GuildMemberInfo(userId: 'u2', nickname: 'Bob', points: 14950),
          ])));
      await _scrollTo(tester, const Key('guild-claim-0'));
      expect(find.text('⚠️'), findsOneWidget);
    });

    for (final l in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
      gTest('[$l] chế độ tối 320px: banner đủ chip + 30 thành viên + boss, không tràn', (tester) async {
        final g = fakeGuild(
          name: 'Câu Lạc Bộ Trà Sữa Rất Dài Tên Để Thử Tràn',
          streak: 12,
          vipMembers: 7,
          vipBonus: 5,
          buffSeconds: 90000,
          total: 130000,
          bossHp: 120000,
          bossTier: 4,
          members: [
            for (var i = 0; i < 30; i++)
              GuildMemberInfo(
                  userId: i == 0 ? 'me' : 'u$i',
                  nickname: 'Người chơi tên khá dài $i',
                  points: 100000 - i * 3000,
                  role: i == 1 ? GuildRole.officer : GuildRole.member),
          ],
        );
        await _pump(tester, FakeGuildRepository(mine: g),
            locale: l, home: Theme(data: ThemeData.dark(), child: const GuildPage()));
        expect(tester.takeException(), isNull);
        for (var i = 0; i < 12; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -400));
          await tester.pumpAndSettle(); // chờ huy hiệu thành viên mới dựng (bộ đếm 50ms)
          expect(tester.takeException(), isNull, reason: 'cuộn lần $i');
        }
      });
    }
  });
}
