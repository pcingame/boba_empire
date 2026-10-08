// GuildController: tải trạng thái, báo điểm tuần, các hành động, và nhận thưởng
// (server xác nhận TRƯỚC rồi mới cộng 💎/phụ kiện cục bộ).
import 'package:boba_empire/core/guild.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/guild/guild_controller.dart';
import 'package:boba_empire/guild/guild_repository.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_guild_repository.dart';

final _now = DateTime.utc(2026, 10, 8).millisecondsSinceEpoch;

Future<ProviderContainer> _open(FakeGuildRepository repo,
    {double score = 500, double gems = 0}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: _now)
        ..gems = gems
        ..guildWeek = guildWeekIndex(_now)
        ..guildWeekScore = score,
      nowMillis: _now);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => _now),
    guildRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(c.dispose);
  return c;
}

GuildController _ctrl(ProviderContainer c) =>
    c.read(guildControllerProvider.notifier);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('refresh', () {
    test('chưa có hội → GuildNone + danh sách công khai; không báo điểm', () async {
      final repo = FakeGuildRepository(listing: sampleListing);
      final c = await _open(repo);
      await _ctrl(c).refresh();
      final s = c.read(guildControllerProvider);
      expect(s, isA<GuildNone>());
      expect((s as GuildNone).listing.single.name, 'Public Club');
      expect(repo.lastSubmitted, isNull);
    });

    test('có hội + điểm > 0 → báo điểm tuần rồi tải lại', () async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      final c = await _open(repo, score: 500);
      await _ctrl(c).refresh();
      expect(repo.lastSubmitted, 500);
      expect(repo.calls.where((x) => x == 'myGuild').length, 2);
      final s = c.read(guildControllerProvider) as GuildMine;
      expect(s.isOwner, isTrue);
      expect(s.myPoints, 400);
    });

    test('điểm tuần = 0 → không gọi server báo điểm', () async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      final c = await _open(repo, score: 0);
      await _ctrl(c).refresh();
      expect(repo.calls.contains('submitScore'), isFalse);
      expect(c.read(guildControllerProvider), isA<GuildMine>());
    });

    test('báo điểm lỗi không che mất trạng thái hội', () async {
      final repo = FakeGuildRepository(mine: fakeGuild())
        ..failures['submitScore'] = const GuildException(GuildFailure.network);
      final c = await _open(repo);
      await _ctrl(c).refresh();
      expect(c.read(guildControllerProvider), isA<GuildMine>());
    });

    test('lỗi mạng khi tải → GuildError (UI có nút thử lại)', () async {
      final repo = FakeGuildRepository()
        ..failures['myGuild'] = const GuildException(GuildFailure.network);
      final c = await _open(repo);
      await _ctrl(c).refresh();
      expect(c.read(guildControllerProvider), isA<GuildError>());
      await _ctrl(c).refresh(); // thử lại được
      expect(c.read(guildControllerProvider), isA<GuildNone>());
    });

    test('không phải chủ hội → isOwner false', () async {
      final repo = FakeGuildRepository(mine: fakeGuild(ownerId: 'u2'));
      final c = await _open(repo);
      await _ctrl(c).refresh();
      expect((c.read(guildControllerProvider) as GuildMine).isOwner, isFalse);
    });
  });

  group('hành động', () {
    test('tạo hội: cắt khoảng trắng, gửi điểm tuần hiện tại làm mốc, vào GuildMine',
        () async {
      final repo = FakeGuildRepository();
      final c = await _open(repo, score: 321, gems: 5000);
      final out = await _ctrl(c).create(
          name: '  Boba Club ',
          tag: ' bb ',
          emoji: '🐉',
          requiresApproval: true,
          nickname: ' Alice ');
      expect(out.ok, isTrue);
      expect(repo.lastCreate, {
        'name': 'Boba Club',
        'tag': 'bb',
        'emoji': '🐉',
        'requiresApproval': true,
        'nickname': 'Alice',
        'score': 321,
      });
      expect(c.read(guildControllerProvider), isA<GuildMine>());
      expect(c.read(gameControllerProvider).gems, 5000 - guildCreateCostGems);
    });

    test('phí tạo hội: thiếu 💎 → từ chối, KHÔNG gọi server, KHÔNG trừ', () async {
      final repo = FakeGuildRepository(listing: sampleListing);
      final c = await _open(repo, gems: guildCreateCostGems - 1.0);
      await _ctrl(c).refresh();
      final out = await _ctrl(c).create(
          name: 'Boba Club', tag: 'bb', emoji: '🧋', requiresApproval: false, nickname: 'A');
      expect(out.failure, GuildFailure.notEnoughGems);
      expect(repo.calls.contains('create'), isFalse);
      expect(c.read(gameControllerProvider).gems, guildCreateCostGems - 1.0);
      expect(c.read(guildControllerProvider), isA<GuildNone>());
    });

    test('phí tạo hội: đúng đủ 2000💎 → tạo được, còn 0, không âm', () async {
      final repo = FakeGuildRepository();
      final c = await _open(repo, gems: guildCreateCostGems.toDouble());
      final out = await _ctrl(c).create(
          name: 'Boba Club', tag: 'bb', emoji: '🧋', requiresApproval: false, nickname: 'A');
      expect(out.ok, isTrue);
      expect(c.read(gameControllerProvider).gems, 0);
    });

    test('phí tạo hội: server lỗi (tên trùng...) → KHÔNG mất 💎', () async {
      final repo = FakeGuildRepository()
        ..failures['create'] = const GuildException(GuildFailure.nameTaken);
      final c = await _open(repo, gems: 3000);
      await _ctrl(c).create(
          name: 'Boba Club', tag: 'bb', emoji: '🧋', requiresApproval: false, nickname: 'A');
      expect(c.read(gameControllerProvider).gems, 3000);
    });

    test('vào hội KHÔNG tốn 💎', () async {
      final repo = FakeGuildRepository(listing: sampleListing);
      final c = await _open(repo, gems: 7);
      expect((await _ctrl(c).join(guildId: 'g9', nickname: 'Z')).ok, isTrue);
      expect(c.read(gameControllerProvider).gems, 7);
    });

    test('tạo hội lỗi: trả đúng lỗi, trạng thái giữ nguyên', () async {
      for (final f in [GuildFailure.nameTaken, GuildFailure.invalidName, GuildFailure.alreadyInGuild]) {
        final repo = FakeGuildRepository(listing: sampleListing)
          ..failures['create'] = GuildException(f);
        final c = await _open(repo, gems: 5000);
        await _ctrl(c).refresh();
        final out = await _ctrl(c).create(
            name: 'x', tag: 'y', emoji: '🧋', requiresApproval: false, nickname: 'n');
        expect(out.failure, f);
        expect(c.read(guildControllerProvider), isA<GuildNone>());
      }
    });

    test('vào hội: gửi id + tên đã cắt khoảng trắng + điểm tuần làm mốc; hội đầy → lỗi',
        () async {
      var repo = FakeGuildRepository(listing: sampleListing);
      var c = await _open(repo, score: 7);
      expect((await _ctrl(c).join(guildId: 'g9', nickname: ' Z ')).ok, isTrue);
      expect(repo.lastJoin, {'guildId': 'g9', 'nickname': 'Z', 'score': 7});

      repo = FakeGuildRepository()
        ..failures['join'] = const GuildException(GuildFailure.guildFull);
      c = await _open(repo);
      expect((await _ctrl(c).join(guildId: 'g9', nickname: 'Z')).failure,
          GuildFailure.guildFull);
    });

    test('rời hội → GuildNone', () async {
      final repo = FakeGuildRepository(mine: fakeGuild(), listing: sampleListing);
      final c = await _open(repo);
      await _ctrl(c).refresh();
      expect((await _ctrl(c).leave()).ok, isTrue);
      expect(c.read(guildControllerProvider), isA<GuildNone>());
    });

    test('kick: gọi repo và danh sách thành viên cập nhật', () async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      final c = await _open(repo);
      await _ctrl(c).refresh();
      expect((await _ctrl(c).kick('u2')).ok, isTrue);
      final s = c.read(guildControllerProvider) as GuildMine;
      expect(s.guild.members.map((m) => m.userId), ['me', 'u3']);
    });

    test('báo cáo: thành công / bị chặn (báo hội của mình)', () async {
      final repo = FakeGuildRepository();
      final c = await _open(repo);
      expect((await _ctrl(c).report('g9', 'x')).ok, isTrue);
      repo.failures['report'] = const GuildException(GuildFailure.notFound);
      expect((await _ctrl(c).report('g9', 'x')).failure, GuildFailure.notFound);
    });

    test('lỗi lạ (không phải GuildException) → network, không ném ra ngoài',
        () async {
      final repo = FakeGuildRepository(mine: fakeGuild())
        ..failures['leave'] = StateError('boom');
      final c = await _open(repo);
      expect((await _ctrl(c).leave()).failure, GuildFailure.network);
    });
  });

  group('hội cần duyệt', () {
    const priv = GuildSummary(
        id: 'p1',
        name: 'Private',
        tag: 'PV',
        emoji: '🔒',
        memberCount: 3,
        weekTotal: 0,
        requiresApproval: true);

    test('xin vào: gửi id + tên đã cắt + điểm tuần làm mốc; sau đó danh sách báo "đã xin"',
        () async {
      final repo = FakeGuildRepository(listing: [priv]);
      final c = await _open(repo, score: 42);
      final out = await _ctrl(c).requestJoin(guildId: 'p1', nickname: ' Z ');
      expect(out.ok, isTrue);
      expect(repo.lastRequest, {'guildId': 'p1', 'nickname': 'Z', 'score': 42});
      final s = c.read(guildControllerProvider) as GuildNone;
      expect(s.listing.single.requested, isTrue);
    });

    test('hủy yêu cầu → danh sách hết "đã xin"', () async {
      final repo = FakeGuildRepository(listing: [priv]);
      final c = await _open(repo);
      await _ctrl(c).requestJoin(guildId: 'p1', nickname: 'Z');
      expect((await _ctrl(c).cancelRequest()).ok, isTrue);
      expect((c.read(guildControllerProvider) as GuildNone).listing.single.requested,
          isFalse);
    });

    test('xin vào lỗi: hội đầy yêu cầu / không tìm thấy; trạng thái giữ nguyên', () async {
      for (final f in [GuildFailure.requestsFull, GuildFailure.notFound, GuildFailure.invalidName]) {
        final repo = FakeGuildRepository(listing: [priv])
          ..failures['requestJoin'] = GuildException(f);
        final c = await _open(repo);
        await _ctrl(c).refresh();
        expect((await _ctrl(c).requestJoin(guildId: 'p1', nickname: 'Z')).failure, f);
        expect((c.read(guildControllerProvider) as GuildNone).listing.single.requested,
            isFalse);
      }
    });

    test('vào thẳng hội cần duyệt bị server chặn → approvalRequired', () async {
      final repo = FakeGuildRepository(listing: [priv])
        ..failures['join'] = const GuildException(GuildFailure.approvalRequired);
      final c = await _open(repo);
      expect((await _ctrl(c).join(guildId: 'p1', nickname: 'Z')).failure,
          GuildFailure.approvalRequired);
    });

    test('chủ hội duyệt: người xin thành thành viên, yêu cầu biến mất', () async {
      final repo = FakeGuildRepository(
          mine: fakeGuild(requiresApproval: true, requests: const [
        GuildJoinRequest(userId: 'r1', nickname: 'Rin'),
        GuildJoinRequest(userId: 'r2', nickname: 'Rex'),
      ]));
      final c = await _open(repo);
      await _ctrl(c).refresh();
      expect((c.read(guildControllerProvider) as GuildMine).guild.requests.length, 2);
      expect((await _ctrl(c).respond('r1', accept: true)).ok, isTrue);
      final s = c.read(guildControllerProvider) as GuildMine;
      expect(s.guild.requests.map((r) => r.userId), ['r2']);
      expect(s.guild.members.map((m) => m.nickname), contains('Rin'));
    });

    test('chủ hội từ chối: không thêm thành viên', () async {
      final repo = FakeGuildRepository(
          mine: fakeGuild(requiresApproval: true, requests: const [
        GuildJoinRequest(userId: 'r1', nickname: 'Rin'),
      ]));
      final c = await _open(repo);
      await _ctrl(c).refresh();
      final before = (c.read(guildControllerProvider) as GuildMine).guild.members.length;
      await _ctrl(c).respond('r1', accept: false);
      final s = c.read(guildControllerProvider) as GuildMine;
      expect(s.guild.requests, isEmpty);
      expect(s.guild.members.length, before);
      expect(repo.responded, ['r1:reject']);
    });

    test('duyệt lỗi (hội đầy / không phải chủ): trả lỗi, danh sách yêu cầu giữ nguyên',
        () async {
      final repo = FakeGuildRepository(
          mine: fakeGuild(requiresApproval: true, requests: const [
        GuildJoinRequest(userId: 'r1', nickname: 'Rin'),
      ]))
        ..failures['respondRequest'] = const GuildException(GuildFailure.guildFull);
      final c = await _open(repo);
      await _ctrl(c).refresh();
      expect((await _ctrl(c).respond('r1', accept: true)).failure, GuildFailure.guildFull);
      expect((c.read(guildControllerProvider) as GuildMine).guild.requests.length, 1);
    });

    test('MyGuild.fromJson: có/không có requests, requires_approval', () {
      final base = {
        'guild': {'id': 'g', 'name': 'N', 'tag': 'TG', 'emoji': '🧋', 'owner_id': 'o'},
        'total': 0,
        'claimed': [],
        'members': [],
      };
      final plain = MyGuild.fromJson(base);
      expect(plain.requiresApproval, isFalse);
      expect(plain.requests, isEmpty);
      final full = MyGuild.fromJson({
        ...base,
        'guild': {...(base['guild'] as Map<String, dynamic>), 'requires_approval': true},
        'requests': [
          {'user_id': 'u1', 'nickname': 'Rin'}
        ],
      });
      expect(full.requiresApproval, isTrue);
      expect(full.requests.single.nickname, 'Rin');
    });

    test('GuildSummary.fromRow đọc requires_approval/requested (thiếu → false)', () {
      final row = {
        'id': 'g', 'name': 'N', 'tag': 'TG', 'emoji': '🧋',
        'member_count': 3, 'week_total': 10,
      };
      final a = GuildSummary.fromRow(row);
      expect((a.requiresApproval, a.requested), (false, false));
      final b = GuildSummary.fromRow(
          {...row, 'requires_approval': true, 'requested': true});
      expect((b.requiresApproval, b.requested), (true, true));
    });
  });

  group('nhận thưởng mốc', () {
    test('mốc 1: server xác nhận → +💎, KHÔNG có phụ kiện', () async {
      final repo = FakeGuildRepository(mine: fakeGuild(total: 12000));
      final c = await _open(repo, gems: 5);
      final out = await _ctrl(c).claim(0);
      expect(out.ok, isTrue);
      expect(out.gems, guildMilestones[0].gems);
      expect(out.drop, isNull);
      expect(c.read(gameControllerProvider).gems, 5 + guildMilestones[0].gems);
      expect(repo.calls, containsAllInOrder(['submitScore', 'claimReward']));
      expect((c.read(guildControllerProvider) as GuildMine).guild.claimed, [1]);
    });

    test('mốc cuối: +💎 và 1 phụ kiện', () async {
      final repo = FakeGuildRepository(mine: fakeGuild(total: 130000));
      final c = await _open(repo, gems: 0);
      final before = c.read(gameControllerProvider).ownedAccessories.length;
      final out = await _ctrl(c).claim(2);
      expect(out.ok, isTrue);
      expect(out.drop, isNotNull);
      expect(c.read(gameControllerProvider).gems,
          greaterThanOrEqualTo(guildMilestones[2].gems));
      // Món mới thì thêm vào bộ; trùng thì +1 bản dư/💎 — ít nhất không mất gì.
      expect(c.read(gameControllerProvider).ownedAccessories.length,
          greaterThanOrEqualTo(before));
    });

    test('server từ chối (chưa đủ điểm / đã nhận): KHÔNG cộng 💎', () async {
      for (final f in [GuildFailure.notEnoughContribution, GuildFailure.network]) {
        final repo = FakeGuildRepository(mine: fakeGuild(total: 12000))
          ..failures['claimReward'] = GuildException(f);
        final c = await _open(repo, gems: 5);
        final out = await _ctrl(c).claim(0);
        expect(out.failure, f);
        expect(c.read(gameControllerProvider).gems, 5);
      }
    });

    test('báo điểm trước khi nhận lỗi → không nhận, không cộng 💎', () async {
      final repo = FakeGuildRepository(mine: fakeGuild(total: 12000))
        ..failures['submitScore'] = const GuildException(GuildFailure.network);
      final c = await _open(repo, gems: 5);
      expect((await _ctrl(c).claim(0)).failure, GuildFailure.network);
      expect(repo.calls.contains('claimReward'), isFalse);
      expect(c.read(gameControllerProvider).gems, 5);
    });

    test('chỉ số mốc ngoài phạm vi bị từ chối, không gọi server', () async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      final c = await _open(repo);
      expect((await _ctrl(c).claim(-1)).ok, isFalse);
      expect((await _ctrl(c).claim(99)).ok, isFalse);
      expect(repo.calls, isEmpty);
    });
  });

  test('guildFailureFromMessage: dịch đúng thông điệp RPC, lạ → network', () {
    const cases = {
      'name taken': GuildFailure.nameTaken,
      'guild full': GuildFailure.guildFull,
      'already in guild': GuildFailure.alreadyInGuild,
      'invalid name': GuildFailure.invalidName,
      'not found': GuildFailure.notFound,
      'not enough contribution': GuildFailure.notEnoughContribution,
      'milestone not reached': GuildFailure.notEnoughContribution,
      'approval required': GuildFailure.approvalRequired,
      'too many requests': GuildFailure.requestsFull,
      'NAME TAKEN (dup)': GuildFailure.nameTaken,
      'something unexpected': GuildFailure.network,
      '': GuildFailure.network,
    };
    cases.forEach((msg, want) {
      expect(guildFailureFromMessage(msg), want, reason: msg);
    });
  });

  test('MyGuild.fromJson đọc đúng JSON của guild_my()', () {
    final g = MyGuild.fromJson({
      'guild': {
        'id': 'g1', 'name': 'N', 'tag': 'TG', 'emoji': '🧋', 'owner_id': 'o'
      },
      'week': '2026-10-05',
      'total': 15000,
      'claimed': [1],
      'members': [
        {'user_id': 'o', 'nickname': 'Own', 'points': 9000},
        {'user_id': 'm', 'nickname': 'Mem', 'points': 6000},
      ],
    });
    expect((g.name, g.tag, g.total), ('N', 'TG', 15000));
    expect(g.claimed, [1]);
    expect(g.pointsOf('m'), 6000);
    expect(g.pointsOf('nobody'), 0);
  });
}
