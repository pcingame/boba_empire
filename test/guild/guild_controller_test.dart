// GuildController: tải trạng thái, báo điểm tuần, các hành động, và nhận thưởng
// (server xác nhận TRƯỚC rồi mới cộng 💎/phụ kiện cục bộ).
import 'package:boba_empire/core/guild.dart';
import 'package:boba_empire/core/guild_shop.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/topup.dart';
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
    {double score = 500, double gems = 0, int vipExp = 0}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: _now)
        ..gems = gems
        ..vipExp = vipExp
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

  group('Xu Hội: nạp 💎, nhiệm vụ, cửa hàng, buff', () {
    Future<ProviderContainer> mine(FakeGuildRepository repo,
        {double gems = 500, double score = 500}) async {
      final c = await _open(repo, gems: gems, score: score);
      await _ctrl(c).refresh();
      return c;
    }

    test('nạp: thiếu 💎 → từ chối, KHÔNG gọi server, không trừ', () async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      final c = await mine(repo, gems: 50);
      final out = await _ctrl(c).donate(100);
      expect(out.failure, GuildFailure.notEnoughGemsToSpend);
      expect(repo.calls.contains('donate'), isFalse);
      expect(c.read(gameControllerProvider).gems, 50);
    });

    test('nạp: vượt hạn mức ngày → dailyLimit, KHÔNG gọi server', () async {
      final repo = FakeGuildRepository(mine: fakeGuild(donatedToday: 995));
      final c = await mine(repo);
      final out = await _ctrl(c).donate(10);
      expect(out.failure, GuildFailure.dailyLimit);
      expect(repo.calls.contains('donate'), isFalse);
      // Vừa đủ hạn mức thì được.
      expect((await _ctrl(c).donate(5)).ok, isTrue);
    });

    test('nạp: thành công → trừ đúng 💎, ví tăng, số đã nạp hôm nay tăng', () async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      final c = await mine(repo, gems: 500);
      expect((await _ctrl(c).donate(100)).ok, isTrue);
      expect(c.read(gameControllerProvider).gems, 400);
      final s = c.read(guildControllerProvider) as GuildMine;
      expect(s.guild.wallet, 100 * guildCoinsPerGem);
      expect(s.guild.donatedToday, 100);
    });

    test('nạp: số không hợp lệ (0, âm) bị chặn ngay', () async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      final c = await mine(repo);
      expect((await _ctrl(c).donate(0)).failure, GuildFailure.invalidInput);
      expect((await _ctrl(c).donate(-5)).failure, GuildFailure.invalidInput);
      expect(repo.calls.contains('donate'), isFalse);
    });

    test('nạp: server lỗi → KHÔNG mất 💎', () async {
      final repo = FakeGuildRepository(mine: fakeGuild())
        ..failures['donate'] = const GuildException(GuildFailure.dailyLimit);
      final c = await mine(repo, gems: 500);
      expect((await _ctrl(c).donate(100)).failure, GuildFailure.dailyLimit);
      expect(c.read(gameControllerProvider).gems, 500);
    });

    test('nhiệm vụ tuần: báo điểm trước, rồi nhận; Xu Hội cộng đúng thưởng', () async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      final c = await mine(repo, score: 5000);
      repo.calls.clear();
      expect((await _ctrl(c).claimQuest(1)).ok, isTrue);
      expect(repo.calls, containsAllInOrder(['submitScore', 'claimQuest']));
      expect((c.read(guildControllerProvider) as GuildMine).guild.wallet,
          guildQuests[1].reward);
      expect((c.read(guildControllerProvider) as GuildMine).guild.questsClaimed, [2]);
    });

    test('nhiệm vụ tuần: chỉ số sai bị chặn; lỗi server được trả về', () async {
      final repo = FakeGuildRepository(mine: fakeGuild())
        ..failures['claimQuest'] =
            const GuildException(GuildFailure.notEnoughContribution);
      final c = await mine(repo);
      expect((await _ctrl(c).claimQuest(-1)).failure, GuildFailure.invalidInput);
      expect((await _ctrl(c).claimQuest(7)).failure, GuildFailure.invalidInput);
      expect((await _ctrl(c).claimQuest(2)).failure,
          GuildFailure.notEnoughContribution);
    });

    test('đổi phụ kiện: cấp vào ownedLimited CHỈ sau khi server trừ ví', () async {
      final repo = FakeGuildRepository(mine: fakeGuild(wallet: 2000));
      final c = await mine(repo);
      expect(c.read(gameControllerProvider).ownedLimited, isEmpty);
      expect((await _ctrl(c).buyItem('guild_flag')).ok, isTrue);
      expect(c.read(gameControllerProvider).ownedLimited, ['guild_flag']);
      expect((c.read(guildControllerProvider) as GuildMine).guild.wallet,
          2000 - 500);
    });

    test('đổi phụ kiện: server từ chối (thiếu Xu / đã có) → KHÔNG cấp', () async {
      for (final f in [GuildFailure.notEnoughCoins, GuildFailure.alreadyOwned]) {
        final repo = FakeGuildRepository(mine: fakeGuild(wallet: 2000))
          ..failures['buyItem'] = GuildException(f);
        final c = await mine(repo);
        expect((await _ctrl(c).buyItem('guild_dragon')).failure, f);
        expect(c.read(gameControllerProvider).ownedLimited, isEmpty);
      }
    });

    test('mua buff: áp ngay cho game (thu nhập nhân hệ số) và hết hạn theo giây server',
        () async {
      final repo = FakeGuildRepository(mine: fakeGuild(wallet: 2000));
      final c = await mine(repo);
      expect(c.read(gameControllerProvider).guildBuffActive, isFalse);
      expect((await _ctrl(c).buyBuff()).ok, isTrue);
      expect(c.read(gameControllerProvider).guildBuffActive, isTrue);
      expect((c.read(guildControllerProvider) as GuildMine).guild.wallet,
          2000 - guildBuffPrice);
    });

    test('mua buff lỗi (thiếu Xu / đã tối đa) → không có buff', () async {
      for (final f in [GuildFailure.notEnoughCoins, GuildFailure.buffMaxed]) {
        final repo = FakeGuildRepository(mine: fakeGuild(wallet: 2000))
          ..failures['buyBuff'] = GuildException(f);
        final c = await mine(repo);
        expect((await _ctrl(c).buyBuff()).failure, f);
        expect(c.read(gameControllerProvider).guildBuffActive, isFalse);
      }
    });

    test('refresh đồng bộ phần chạy ở game: cờ ở hội, buff từ server, khôi phục phụ kiện',
        () async {
      final repo = FakeGuildRepository(
          mine: fakeGuild(buffSeconds: 3600, ownedItems: ['guild_castle', 'x_lạ']));
      final c = await _open(repo, gems: 0);
      expect(c.read(gameControllerProvider).guildJoined, isFalse);
      await _ctrl(c).refresh();
      final g = c.read(gameControllerProvider);
      expect(g.guildJoined, isTrue);
      expect(g.guildBuffActive, isTrue);
      expect(g.ownedLimited, ['guild_castle'], reason: 'id lạ bị bỏ qua');
    });

    test('rời hội/không còn ở hội: cờ tắt và buff bị xoá', () async {
      final repo = FakeGuildRepository(
          mine: fakeGuild(buffSeconds: 3600), listing: sampleListing);
      final c = await mine(repo);
      expect(c.read(gameControllerProvider).guildBuffActive, isTrue);
      await _ctrl(c).leave();
      final g = c.read(gameControllerProvider);
      expect(g.guildJoined, isFalse);
      expect(g.guildBuffActive, isFalse);
    });

    test('syncBuff: không ở hội → không gọi server', () async {
      final repo = FakeGuildRepository();
      final c = await _open(repo);
      await _ctrl(c).syncBuff();
      expect(repo.calls, isEmpty);
    });

    test('syncBuff: ở hội → áp buff server báo; gọi lại trong 10 phút thì bỏ qua',
        () async {
      final repo = FakeGuildRepository(mine: fakeGuild())..serverBuffSeconds = 7200;
      final c = await mine(repo);
      repo.calls.clear();
      await _ctrl(c).syncBuff();
      expect(repo.calls, ['buffSeconds', 'vipBonus']);
      expect(c.read(gameControllerProvider).guildBuffActive, isTrue);
      await _ctrl(c).syncBuff();
      expect(repo.calls, ['buffSeconds', 'vipBonus'], reason: 'giới hạn tần suất');
    });

    test('thưởng VIP của hội: refresh áp %, rời hội thì mất ngay', () async {
      final repo = FakeGuildRepository(mine: fakeGuild(vipMembers: 3, vipBonus: 3));
      final c = await mine(repo);
      var g = c.read(gameControllerProvider);
      expect((g.guildJoined, g.guildVipBonusPct), (true, 3));
      await _ctrl(c).leave();
      g = c.read(gameControllerProvider);
      expect((g.guildJoined, g.guildVipBonusPct), (false, 0));
    });

    test('thưởng VIP: kẹp ở trần dù server báo quá cao hoặc âm', () async {
      final repo = FakeGuildRepository(mine: fakeGuild(vipBonus: 99));
      final c = await mine(repo);
      expect(c.read(gameControllerProvider).guildVipBonusPct, guildVipBonusCap);
      c.read(gameControllerProvider.notifier).applyGuildVipBonus(-4);
      expect(c.read(gameControllerProvider).guildVipBonusPct, 0);
    });

    test('syncBuff cũng lấy thưởng VIP; RPC lỗi thì giữ giá trị cũ, buff vẫn áp', () async {
      final repo = FakeGuildRepository(mine: fakeGuild(vipBonus: 2))..serverVipBonus = 4;
      final c = await mine(repo);
      expect(c.read(gameControllerProvider).guildVipBonusPct, 2);
      repo.calls.clear();
      await _ctrl(c).syncBuff();
      expect(c.read(gameControllerProvider).guildVipBonusPct, 4);

      final repo2 = FakeGuildRepository(mine: fakeGuild(vipBonus: 2))
        ..serverBuffSeconds = 7200
        ..failures['vipBonus'] = const GuildException(GuildFailure.network);
      final c2 = await mine(repo2);
      await _ctrl(c2).syncBuff();
      expect(c2.read(gameControllerProvider).guildVipBonusPct, 2); // giữ nguyên
      expect(c2.read(gameControllerProvider).guildBuffActive, isTrue);
    });

    test('thu nhập: thưởng VIP của hội nhân vào thu nhập chỉ khi ở hội; kẹp ở trần', () async {
      final repo = FakeGuildRepository();
      final c = await _open(repo);
      final game = c.read(gameControllerProvider.notifier);
      // Có sẵn nguồn thu để thu nhập > 0.
      final base = c.read(gameControllerProvider).incomePerSecond;
      game.applyGuildVipBonus(3);
      expect(c.read(gameControllerProvider).incomePerSecond, base, reason: 'chưa ở hội → không áp');
      game.setGuildJoined(true);
      game.applyGuildVipBonus(3);
      final withBonus = c.read(gameControllerProvider).incomePerSecond;
      expect(withBonus, closeTo(base * 1.03, base * 1e-9 + 1e-9));
      game.applyGuildVipBonus(50);
      expect(c.read(gameControllerProvider).incomePerSecond, closeTo(base * 1.05, base * 1e-9 + 1e-9));
    });

    test('applyGuildVipBonus khi KHÔNG ở hội luôn về 0 (RPC báo trễ sau khi rời hội)', () async {
      final repo = FakeGuildRepository();
      final c = await _open(repo);
      final game = c.read(gameControllerProvider.notifier);
      game.applyGuildVipBonus(4);
      expect(c.read(gameControllerProvider).guildVipBonusPct, 0);
      game.setGuildJoined(true);
      game.applyGuildVipBonus(4);
      expect(c.read(gameControllerProvider).guildVipBonusPct, 4);
      game.setGuildJoined(false);
      game.applyGuildVipBonus(4); // trễ
      expect(c.read(gameControllerProvider).guildVipBonusPct, 0);
    });

    test('guildVipBonusMultiplier: không ở hội = 1; kẹp 0..trần', () {
      expect(guildVipBonusMultiplier(joined: false, pct: 5), 1.0);
      expect(guildVipBonusMultiplier(joined: true, pct: 0), 1.0);
      expect(guildVipBonusMultiplier(joined: true, pct: 3), closeTo(1.03, 1e-12));
      expect(guildVipBonusMultiplier(joined: true, pct: 99), closeTo(1.05, 1e-12));
      expect(guildVipBonusMultiplier(joined: true, pct: -5), 1.0);
    });

    test('syncBuff: lỗi mạng bị nuốt, buff cũ giữ nguyên', () async {
      final repo = FakeGuildRepository(mine: fakeGuild(buffSeconds: 3600));
      final c = await mine(repo);
      repo.failures['buffSeconds'] = const GuildException(GuildFailure.network);
      await _ctrl(c).syncBuff();
      expect(c.read(gameControllerProvider).guildBuffActive, isTrue);
    });

    test('MyGuild.fromJson đọc đủ trường mới; thiếu thì về mặc định', () {
      final base = {
        'guild': {'id': 'g', 'name': 'N', 'tag': 'TG', 'emoji': '🧋', 'owner_id': 'o'},
        'total': 0, 'claimed': [], 'members': [],
      };
      final d = MyGuild.fromJson(base);
      expect((d.streak, d.buffSeconds, d.wallet, d.donatedToday), (0, 0, 0, 0));
      expect(d.questsClaimed, isEmpty);
      expect(d.ownedItems, isEmpty);
      final f = MyGuild.fromJson({
        ...base,
        'streak': 4,
        'buff_seconds': 120,
        'wallet': 777,
        'quests_claimed': [1, 3],
        'owned_items': ['guild_flag'],
        'donated_today': 250,
      });
      expect((f.streak, f.buffSeconds, f.wallet, f.donatedToday), (4, 120, 777, 250));
      expect(f.questsClaimed, [1, 3]);
      expect(f.ownedItems, ['guild_flag']);
    });

    test('GuildSummary.fromRow đọc avg_points và streak (thiếu → null)', () {
      final row = {
        'id': 'g', 'name': 'N', 'tag': 'TG', 'emoji': '🧋',
        'member_count': 6, 'week_total': 60000,
      };
      final a = GuildSummary.fromRow(row);
      expect((a.avgPoints, a.streak), (null, null));
      final b = GuildSummary.fromRow({...row, 'avg_points': 10000, 'streak': 3});
      expect((b.avgPoints, b.streak), (10000, 3));
    });

    test('guildFailureFromMessage: lỗi mới của Xu Hội', () {
      const cases = {
        'daily limit': GuildFailure.dailyLimit,
        'not enough coins': GuildFailure.notEnoughCoins,
        'already owned': GuildFailure.alreadyOwned,
        'buff maxed': GuildFailure.buffMaxed,
        'already claimed': GuildFailure.alreadyClaimed,
        'invalid amount': GuildFailure.invalidInput,
        'invalid item': GuildFailure.invalidInput,
        'invalid tier': GuildFailure.invalidInput,
      };
      cases.forEach((m, f) => expect(guildFailureFromMessage(m), f, reason: m));
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

  group('Boss Hội hàng tuần', () {
    Future<ProviderContainer> mine(FakeGuildRepository repo, {double gems = 0}) async {
      final c = await _open(repo, gems: gems);
      await _ctrl(c).refresh();
      return c;
    }

    test('hằng số và thưởng theo bậc; boss xoay vòng theo tuần', () {
      expect([for (var t = 0; t <= guildBossMaxTier; t++) guildBossRewardGems(t)],
          [100, 150, 200, 250, 300]);
      expect([for (var t = 0; t <= guildBossMaxTier; t++) guildBossRewardCoins(t)],
          [100, 200, 300, 400, 500]);
      expect(guildBossEmojis.length, 6);
      expect({for (var w = 0; w < 6; w++) guildBossIndex(w)}.length, 6);
      expect(guildBossIndex(6), guildBossIndex(0));
    });

    test('MyGuild.fromJson đọc boss; server cũ không có boss → HP 0 (ẩn thẻ)', () {
      final base = {
        'guild': {'id': 'g', 'name': 'N', 'tag': 'TG', 'emoji': '🧋', 'owner_id': 'o'},
        'total': 0, 'claimed': [], 'members': [],
      };
      final old = MyGuild.fromJson(base);
      expect((old.bossHp, old.bossTier, old.bossClaimed), (0, 0, false));
      final f = MyGuild.fromJson({
        ...base,
        'boss': {'hp': 36000, 'tier': 2, 'claimed': true},
      });
      expect((f.bossHp, f.bossTier, f.bossClaimed), (36000, 2, true));
    });

    test('nhận rương: server OK rồi mới cộng đúng 💎 theo bậc; trả cả Xu Hội', () async {
      final repo = FakeGuildRepository(mine: fakeGuild(total: 40000, bossHp: 36000, bossTier: 2));
      final c = await mine(repo, gems: 10);
      final out = await _ctrl(c).claimBoss();
      expect(out.ok, isTrue);
      expect((out.gems, out.coins), (200, 300));
      expect(c.read(gameControllerProvider).gems, 210);
      final s = c.read(guildControllerProvider) as GuildMine;
      expect(s.guild.bossClaimed, isTrue);
    });

    test('mọi lỗi server → không cộng 💎, trả đúng loại lỗi', () async {
      for (final f in [
        GuildFailure.bossAlive,
        GuildFailure.notEnoughContribution,
        GuildFailure.alreadyClaimed,
        GuildFailure.network,
      ]) {
        final repo = FakeGuildRepository(mine: fakeGuild(bossHp: 1000))
          ..failures['claimBoss'] = GuildException(f);
        final c = await mine(repo, gems: 5);
        final out = await _ctrl(c).claimBoss();
        expect(out.failure, f);
        expect(c.read(gameControllerProvider).gems, 5, reason: '$f');
      }
    });

    test('báo điểm tuần trước khi nhận (server thấy đóng góp mới nhất)', () async {
      final repo = FakeGuildRepository(mine: fakeGuild(bossHp: 1000));
      final c = await _open(repo, score: 800);
      await _ctrl(c).refresh();
      repo.calls.clear();
      await _ctrl(c).claimBoss();
      expect(repo.calls.indexOf('submitScore'), lessThan(repo.calls.indexOf('claimBoss')));
    });

    test('thông điệp "boss alive" của server ánh xạ thành bossAlive', () {
      expect(guildFailureFromMessage('PostgrestException: boss alive'), GuildFailure.bossAlive);
    });
  });

  group('ưu đãi phí tạo hội theo cấp VIP', () {
    Future<GuildOutcome> create(ProviderContainer c) => _ctrl(c).create(
        name: 'Boba', tag: 'BB', emoji: '🧋', requiresApproval: false, nickname: 'Alice');

    test('bảng ưu đãi: <5 không giảm, 5→25%, 8→50%, 10→miễn phí', () {
      expect([for (final l in [0, 4, 5, 7, 8, 9, 10]) guildCreateDiscountPercent(l)],
          [0, 0, 25, 25, 50, 50, 100]);
      expect([for (final l in [0, 4, 5, 8, 10]) guildCreateCostFor(l)],
          [2000, 2000, 1500, 1000, 0]);
    });

    test('VIP 8: thiếu 💎 so với phí đã giảm → từ chối; đủ → trừ đúng 1000', () async {
      final repo = FakeGuildRepository(listing: sampleListing);
      final c = await _open(repo, gems: 999, vipExp: topupTiers[7].exp);
      expect((await create(c)).failure, GuildFailure.notEnoughGems);
      expect(repo.calls.contains('create'), isFalse);

      final repo2 = FakeGuildRepository(listing: sampleListing);
      final c2 = await _open(repo2, gems: 1500, vipExp: topupTiers[7].exp);
      expect((await create(c2)).ok, isTrue);
      expect(c2.read(gameControllerProvider).gems, 500);
    });

    test('VIP 10: tạo hội miễn phí kể cả khi 0 💎; không bị trừ âm', () async {
      final repo = FakeGuildRepository(listing: sampleListing);
      final c = await _open(repo, gems: 0, vipExp: topupTiers[9].exp);
      expect((await create(c)).ok, isTrue);
      expect(c.read(gameControllerProvider).gems, 0);
    });

    test('VIP 5: giảm 25% (1500)', () async {
      final repo = FakeGuildRepository(listing: sampleListing);
      final c = await _open(repo, gems: 1499, vipExp: topupTiers[4].exp);
      expect((await create(c)).failure, GuildFailure.notEnoughGems);
      final repo2 = FakeGuildRepository(listing: sampleListing);
      final c2 = await _open(repo2, gems: 2000, vipExp: topupTiers[4].exp);
      expect((await create(c2)).ok, isTrue);
      expect(c2.read(gameControllerProvider).gems, 500);
    });

    test('không VIP: vẫn 2000 như cũ', () async {
      final repo = FakeGuildRepository(listing: sampleListing);
      final c = await _open(repo, gems: 5000);
      expect((await create(c)).ok, isTrue);
      expect(c.read(gameControllerProvider).gems, 3000);
    });
  });

  group('tặng 💎 giữa hội viên', () {
    Future<ProviderContainer> mine(FakeGuildRepository repo, {double gems = 0}) async {
      final c = await _open(repo, gems: gems);
      await _ctrl(c).refresh();
      return c;
    }

    test('thiếu 💎 → từ chối, KHÔNG gọi server, không trừ', () async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      final c = await mine(repo, gems: 5);
      final out = await _ctrl(c).sendGift('u2', 10);
      expect(out.failure, GuildFailure.notEnoughGemsToSpend);
      expect(repo.calls.contains('giftSend'), isFalse);
      expect(c.read(gameControllerProvider).gems, 5);
    });

    test('mức tặng ngoài danh sách bị chặn ngay', () async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      final c = await mine(repo, gems: 500);
      expect((await _ctrl(c).sendGift('u2', 15)).failure, GuildFailure.invalidInput);
      expect(repo.calls.contains('giftSend'), isFalse);
    });

    test('thành công → server ghi nhận rồi mới trừ đúng 💎', () async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      final c = await mine(repo, gems: 100);
      expect((await _ctrl(c).sendGift('u2', 50)).ok, isTrue);
      expect(repo.sentGifts, [('u2', 50)]);
      expect(c.read(gameControllerProvider).gems, 50);
    });

    test('server báo quá trần ngày → giftLimit và KHÔNG trừ 💎', () async {
      final repo = FakeGuildRepository(mine: fakeGuild())
        ..failures['giftSend'] = const GuildException(GuildFailure.dailyLimit);
      final c = await mine(repo, gems: 100);
      final out = await _ctrl(c).sendGift('u2', 50);
      expect(out.failure, GuildFailure.giftLimit);
      expect(c.read(gameControllerProvider).gems, 100);
    });

    test('nhận quà: server đánh dấu rồi mới cộng 💎; hộp thư giảm', () async {
      final repo = FakeGuildRepository(mine: fakeGuild())
        ..gifts = [const GuildGift(id: 7, fromNickname: 'Bob', amount: 20)];
      final c = await mine(repo, gems: 0);
      expect((await _ctrl(c).giftInbox()).single.fromNickname, 'Bob');
      final r = await _ctrl(c).claimGift(7);
      expect(r.outcome.ok, isTrue);
      expect(r.gems, 20);
      expect(c.read(gameControllerProvider).gems, 20);
      expect(await _ctrl(c).giftInbox(), isEmpty);
    });

    test('nhận quà lỗi → không cộng 💎', () async {
      final repo = FakeGuildRepository(mine: fakeGuild())
        ..gifts = [const GuildGift(id: 7, fromNickname: 'Bob', amount: 20)]
        ..failures['giftClaim'] = const GuildException(GuildFailure.alreadyClaimed);
      final c = await mine(repo, gems: 0);
      final r = await _ctrl(c).claimGift(7);
      expect(r.outcome.failure, GuildFailure.alreadyClaimed);
      expect(c.read(gameControllerProvider).gems, 0);
    });
  });

  group('chat hội', () {
    test('guildFailureFromMessage: lỗi chat; RPC chưa có trên server cũ → network (không văng)', () {
      expect(guildFailureFromMessage('chat rate limited'), GuildFailure.chatRateLimited);
      expect(guildFailureFromMessage('text blocked'), GuildFailure.textBlocked);
      expect(
          guildFailureFromMessage(
              'Could not find the function public.guild_chat_list(p_limit) in the schema cache'),
          GuildFailure.network);
    });

    test('GuildChat.fromJson: ghim null / có ghim; thứ tự giữ nguyên (mới nhất đầu)', () {
      final a = GuildChat.fromJson({
        'pinned': null,
        'messages': [
          {'id': 5, 'user_id': 'a', 'nickname': 'A', 'body': 'x'},
          {'id': 4, 'user_id': 'b', 'nickname': 'B', 'body': 'y'},
        ],
      });
      expect(a.pinned, isNull);
      expect(a.messages.map((m) => m.id), [5, 4]);
      final b = GuildChat.fromJson({
        'pinned': {'id': 9, 'user_id': 'o', 'nickname': 'O', 'body': 'z'},
        'messages': [],
      });
      expect(b.pinned!.body, 'z');
      expect(b.messages, isEmpty);
    });

    test('chatPost/Delete/Pin: thành công → ok; lỗi server → đúng failure; lỗi lạ → network', () async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      final c = _ctrl(await _open(repo));
      expect((await c.chatPost('hi')).ok, isTrue);
      expect(repo.chatMessages.single.body, 'hi');
      expect((await c.chatPin(repo.chatMessages.single.id)).ok, isTrue);
      expect(repo.chatPinnedId, repo.chatMessages.single.id);
      expect((await c.chatDelete(repo.chatMessages.single.id)).ok, isTrue);

      repo.failures['chatPost'] = const GuildException(GuildFailure.textBlocked);
      expect((await c.chatPost('x')).failure, GuildFailure.textBlocked);
      repo.failures['chatDelete'] = StateError('boom');
      expect((await c.chatDelete(1)).failure, GuildFailure.network);
      repo.failures['chatPin'] = const GuildException(GuildFailure.notFound);
      expect((await c.chatPin(1)).failure, GuildFailure.notFound);
    });

    test('hành động chat KHÔNG tải lại trạng thái hội (không gọi myGuild)', () async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      final c = _ctrl(await _open(repo));
      await c.chatPost('hi');
      expect(repo.calls.where((e) => e == 'myGuild'), isEmpty);
    });
  });

  group('vai trò hội', () {
    GuildMine view(String me, List<GuildMemberInfo> ms, {String owner = 'boss'}) => GuildMine(
        guild: fakeGuild(ownerId: owner, members: ms), myUserId: me);
    GuildMemberInfo m(String id, GuildRole r) =>
        GuildMemberInfo(userId: id, nickname: id, points: 0, role: r);
    final all = [
      m('boss', GuildRole.owner),
      m('off', GuildRole.officer),
      m('off2', GuildRole.officer),
      m('mem', GuildRole.member),
    ];

    test('chủ hội: canModerate, kick mọi người khác trừ chính mình', () {
      final v = view('boss', all);
      expect(v.isOwner, isTrue);
      expect(v.canModerate, isTrue);
      expect(all.where(v.canKick).map((e) => e.userId), ['off', 'off2', 'mem']);
    });

    test('phó hội: canModerate, chỉ kick thành viên thường', () {
      final v = view('off', all);
      expect(v.isOwner, isFalse);
      expect(v.isOfficer, isTrue);
      expect(v.canModerate, isTrue);
      expect(all.where(v.canKick).map((e) => e.userId), ['mem']);
    });

    test('thành viên thường: không quyền gì', () {
      final v = view('mem', all);
      expect(v.isOfficer, isFalse);
      expect(v.canModerate, isFalse);
      expect(all.where(v.canKick), isEmpty);
    });

    test('MyGuild.fromJson: đọc role; server cũ (không có role) suy chủ từ owner_id', () {
      Map<String, dynamic> json(Map<String, dynamic> extra) => {
            'guild': {'id': 'g', 'name': 'N', 'tag': 'T', 'emoji': 'e', 'owner_id': 'a'},
            'total': 0,
            'claimed': [],
            'members': [
              {'user_id': 'a', 'nickname': 'A', 'points': 1, ...extra},
              {'user_id': 'b', 'nickname': 'B', 'points': 2, 'role': 'officer'},
              {'user_id': 'c', 'nickname': 'C', 'points': 3, 'role': 'member'},
            ],
          };
      final withRole = MyGuild.fromJson(json({'role': 'owner'}));
      expect(withRole.members.map((e) => e.role),
          [GuildRole.owner, GuildRole.officer, GuildRole.member]);
      final old = MyGuild.fromJson(json({}));
      expect(old.members.first.role, GuildRole.owner, reason: 'server cũ: chủ suy từ owner_id');
    });

    test('GuildEvent.fromJson: loại lạ → joined (không văng); target null', () {
      final e = GuildEvent.fromJson(
          {'kind': 'kicked', 'actor': 'A', 'target': 'B', 'created_at': '2026-10-10T00:00:00Z'});
      expect(e.kind, GuildEventKind.kicked);
      expect(e.target, 'B');
      expect(e.createdAt, isNotNull);
      final u = GuildEvent.fromJson({'kind': 'tuongLai', 'actor': 'A', 'target': null});
      expect(u.kind, GuildEventKind.joined);
      expect(u.target, isNull);
    });

    test('lỗi RPC → GuildFailure; RPC chưa có trên server cũ → network', () {
      expect(guildFailureFromMessage('not allowed'), GuildFailure.notAllowed);
      expect(guildFailureFromMessage('too many officers'), GuildFailure.officersFull);
      expect(guildFailureFromMessage('Could not find the function public.guild_set_officer'),
          GuildFailure.network);
    });

    test('setOfficer/transferOwner: gọi repo, làm mới trạng thái; lỗi → failure', () async {
      final repo = FakeGuildRepository(mine: fakeGuild(members: [
        m('me', GuildRole.owner),
        m('x', GuildRole.member),
      ]));
      final c = _ctrl(await _open(repo));
      expect((await c.setOfficer('x', on: true)).ok, isTrue);
      expect(repo.roleCalls, ['officer:x:true']);
      expect(repo.mine!.members.last.role, GuildRole.officer);
      repo.failures['setOfficer'] = const GuildException(GuildFailure.officersFull);
      expect((await c.setOfficer('x', on: false)).failure, GuildFailure.officersFull);
      expect((await c.transferOwner('x')).ok, isTrue);
      expect(repo.mine!.ownerId, 'x');
    });
  });
}
