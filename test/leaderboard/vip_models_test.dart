import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/topup.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/guild/guild_repository.dart';
import 'package:boba_empire/leaderboard/vip_leaderboard_repository.dart';
import 'package:boba_empire/leaderboard/vip_presence.dart';
import 'package:boba_empire/referral/referral_repository.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phần PARSE dữ liệu server (không cần Supabase): đọc đủ trường, và chịu được thiếu/kiểu lạ.
void main() {
  test('VipLeaderboardEntry.fromRow: đọc đủ cột; số có thể là num/double; online mặc định false', () {
    final e = VipLeaderboardEntry.fromRow({
      'user_id': 'u1',
      'nickname': 'Alice',
      'vip_exp': 12000,
      'level': 5.0, // PostgREST đôi khi trả double
      'rank': 1,
      'online': true,
    });
    expect((e.userId, e.nickname, e.vipExp, e.level, e.rank, e.online),
        ('u1', 'Alice', 12000, 5, 1, true));
    final off = VipLeaderboardEntry.fromRow({
      'user_id': 'u2', 'nickname': 'Bob', 'vip_exp': 600, 'level': 1, 'rank': 2,
    });
    expect(off.online, isFalse); // server cũ chưa có cột online
  });

  test('VipAnnouncement.fromRecord: đọc user/nickname/cấp; thiếu cấp → ngưỡng danh hiệu', () {
    final a = VipAnnouncement.fromRecord(
        {'user_id': 'u1', 'nickname': 'Tom', 'level': 8, 'id': 3});
    expect((a.userId, a.nickname, a.level), ('u1', 'Tom', 8));
    final b = VipAnnouncement.fromRecord({'user_id': 'u2', 'nickname': 'Pat'});
    expect(b.level, vipTitleMinLevel);
  });

  test('ReferralStatus.fromJson: đọc đủ; thiếu trường → mặc định an toàn', () {
    final s = ReferralStatus.fromJson({
      'code': 'ABC234', 'invited': 5, 'reached': 2, 'claimable': 1, 'redeemed': true,
    });
    expect((s.code, s.invited, s.reached, s.claimable, s.redeemed),
        ('ABC234', 5, 2, 1, true));
    final empty = ReferralStatus.fromJson({});
    expect((empty.code, empty.invited, empty.reached, empty.claimable, empty.redeemed),
        ('', 0, 0, 0, false));
  });

  test('GuildGift.fromJson và GuildSummary.fromRow(vip_exp)', () {
    final g = GuildGift.fromJson({
      'id': 9, 'from_nickname': 'Bob', 'amount': 50, 'created_at': '2026-10-10T00:00:00Z',
    });
    expect((g.id, g.fromNickname, g.amount), (9, 'Bob', 50));
    expect(g.createdAt, DateTime.utc(2026, 10, 10));
    expect(GuildGift.fromJson({'id': 1, 'amount': 10}).fromNickname, '?'); // thiếu tên → "?"
    final s = GuildSummary.fromRow({
      'id': 'g', 'name': 'N', 'tag': 'T', 'emoji': '🧋',
      'member_count': 3, 'week_total': 10, 'vip_exp': 33000,
    });
    expect(s.vipExp, 33000);
    expect(GuildSummary.fromRow({
      'id': 'g', 'name': 'N', 'tag': 'T', 'emoji': '🧋', 'member_count': 3, 'week_total': 10,
    }).vipExp, isNull);
  });

  test('VipPresence: ping/listen/dispose không ném lỗi khi chưa có Supabase / chưa đủ cấp',
      () async {
    SharedPreferences.setMockInitialValues({'leaderboard_nickname': 'Alice'});
    final prefs = await SharedPreferences.getInstance();
    // Đủ VIP 5 và có biệt danh → đi tới bước gọi Supabase (chưa khởi tạo) → lỗi bị nuốt.
    await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)..vipExp = topupTiers[4].exp,
        nowMillis: 0);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
    ]);
    addTearDown(c.dispose);
    final presence = c.read(vipPresenceProvider);
    await presence.ping();
    var shown = 0;
    presence.listen((_) => shown++);
    presence.listen((_) => shown++); // gọi hai lần không lỗi
    expect(shown, 0);
    presence.dispose();
  });
}
