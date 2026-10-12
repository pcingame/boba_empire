// SQL Hội phải khớp hằng số Dart, và đóng đúng các cửa bảo mật.
// (Hành vi thật của SQL được chạy bằng scripts/test_guild_sql.sh trên Postgres.)
import 'dart:io';

import 'package:boba_empire/core/guild.dart';
import 'package:boba_empire/core/guild_shop.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File('supabase/guild_schema.sql').readAsStringSync();
  final repo = File('lib/guild/guild_repository.dart').readAsStringSync();

  int constant(String fn) =>
      int.parse(RegExp('function $fn\\(\\) returns integer\\s*'
              r'language sql immutable as \$\$ select (\d+) \$\$')
          .firstMatch(sql)!
          .group(1)!);

  test('giới hạn thành viên và điểm tối thiểu để nhận khớp Dart', () {
    expect(constant('guild_max_members'), guildMaxMembers);
    expect(constant('guild_min_points_to_claim'), guildMinPointsToClaim);
  });

  test('sức chứa ban đầu / bước mở rộng / giá khớp Dart', () {
    expect(constant('guild_base_members'), guildBaseMembers);
    expect(constant('guild_expand_step'), guildExpandStep);
    final costs = {
      for (final m in RegExp(r'when (\d+) then (\d+)').allMatches(
          sql.substring(sql.indexOf('function guild_expand_cost')).split(r'$$;').first.split(r'$$').elementAt(1)))
        int.parse(m.group(1)!): int.parse(m.group(2)!)
    };
    // Mọi bậc từ ban đầu tới trần: SQL và Dart cùng giá; tới trần thì Dart trả null.
    for (var c = guildBaseMembers; c < guildMaxMembers; c += guildExpandStep) {
      expect(costs[c], guildExpandCostFor(c), reason: '$c');
    }
    expect(costs.length, (guildMaxMembers - guildBaseMembers) ~/ guildExpandStep);
    expect(guildExpandCostFor(guildMaxMembers), isNull);
  });

  test('mốc tuần khớp Dart (thứ tự và giá trị)', () {
    final m = RegExp(r'when (\d) then (\d+)')
        .allMatches(sql.substring(sql.indexOf('guild_milestone_threshold')))
        .take(guildMilestones.length)
        .map((x) => (int.parse(x.group(1)!), int.parse(x.group(2)!)))
        .toList();
    expect(m, [
      for (var i = 0; i < guildMilestones.length; i++)
        (i + 1, guildMilestones[i].threshold),
    ]);
  });

  test('trần điểm/giờ cho người thật nhưng chặn auto-click (cùng BXH sự kiện)',
      () {
    final cap = constant('guild_score_per_hour');
    expect(cap, greaterThan(36000 + 5000)); // ~10 chạm/giây + mèo/VIP
    expect(cap, lessThan(180000)); // 50 chạm/giây
  });

  test('mọi bảng bật RLS và KHÔNG có policy nào (chỉ RPC được ghi)', () {
    for (final t in [
      'guilds',
      'guild_members',
      'guild_reward_claims',
      'guild_reports'
    ]) {
      expect(sql.contains(RegExp('alter table $t\\s+enable row level security')),
          isTrue,
          reason: t);
    }
    expect(sql.contains('create policy'), isFalse);
  });

  test('RPC mà app gọi đều tồn tại và được cấp quyền authenticated', () {
    final called = RegExp(r"_rpc\('(\w+)'").allMatches(repo).map((m) => m.group(1)!);
    expect(called.toSet().length, greaterThanOrEqualTo(10));
    for (final fn in called.toSet()) {
      expect(sql.contains('create or replace function $fn('), isTrue,
          reason: 'thiếu $fn trong SQL');
      expect(sql.contains("'$fn("), isTrue,
          reason: '$fn chưa có trong danh sách cấp quyền');
    }
  });

  test('mọi RPC ghi dữ liệu là security definer có search_path cố định', () {
    final defs = RegExp(r'create or replace function (guild_\w+)\(')
        .allMatches(sql)
        .map((m) => m.group(1)!)
        .toSet();
    for (final fn in [
      'guild_create',
      'guild_join',
      'guild_leave',
      'guild_kick',
      'guild_submit_score',
      'guild_report',
      'guild_claim_reward',
      'guild_request_join',
      'guild_cancel_request',
      'guild_respond_request',
    ]) {
      expect(defs, contains(fn));
      final body = sql.substring(sql.indexOf('create or replace function $fn('));
      final head = body.substring(0, body.indexOf(r'$$'));
      expect(head.contains('security definer set search_path = public'), isTrue,
          reason: fn);
    }
  });

  test('chặn nhận thưởng hai lần và ăn theo: có khoá chính + điều kiện điểm', () {
    expect(sql.contains('primary key (user_id, week, milestone)'), isTrue);
    expect(sql.contains('guild_min_points_to_claim()'), isTrue);
  });

  test('báo cáo: ≥3 người báo thì ẩn', () {
    expect(sql.contains(RegExp(r'count\(\*\) from guild_reports[^;]*>= 3')),
        isTrue);
  });

  test('đã gỡ mã mời/hội riêng: không còn trong SQL, và có lệnh dọn bản cũ', () {
    final live = sql
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('--'))
        .join('\n');
    // Chỉ còn xuất hiện trong lệnh dọn (drop column/function) của bản cũ.
    final withoutCleanup = live
        .split('\n')
        .where((l) => !l.contains('drop column') && !l.contains('drop function'))
        .join('\n');
    for (final dead in ['invite_code', 'is_public', 'p_code', 'p_public']) {
      expect(withoutCleanup.contains(dead), isFalse, reason: dead);
    }
    for (final old in [
      'drop column if exists is_public',
      'drop column if exists invite_code',
      'drop function if exists guild_create(text, text, text, boolean, text, bigint)',
      'drop function if exists guild_join(uuid, text, text, bigint)',
      'drop function if exists guild_list_public(integer)',
    ]) {
      expect(sql.contains(old), isTrue, reason: old);
    }
  });

  test('tặng 💎: hằng số và mức tặng khớp SQL, mọi RPC bị khoá quyền', () {
    expect(constant('guild_gift_send_daily_cap'), guildGiftSendDailyCap);
    expect(constant('guild_gift_receive_daily_cap'), guildGiftReceiveDailyCap);
    expect(constant('guild_gift_expire_days'), guildGiftExpireDays);
    final m = RegExp(r'select p_amount in \(([\d, ]+)\)').firstMatch(sql);
    expect(m, isNotNull);
    expect(m!.group(1)!.split(',').map((e) => int.parse(e.trim())).toList(),
        guildGiftAmounts);
    expect(sql, contains('check (amount in (10, 20, 50))'));
    expect(sql, contains('alter table guild_gifts enable row level security'));
    for (final f in ['guild_gift_send(uuid,integer)', 'guild_gift_inbox()', 'guild_gift_claim(bigint)']) {
      expect(sql, contains("'$f'"), reason: '$f phải nằm trong danh sách cấp quyền authenticated');
    }
  });

  test('Boss Hội: hằng số, công thức thưởng, RPC và cột guild_my khớp Dart', () {
    expect(constant('guild_boss_hp_per_member'), guildBossHpPerMember);
    expect(constant('guild_boss_min_hp'), guildBossMinHp);
    expect(constant('guild_boss_max_tier'), guildBossMaxTier);
    // Công thức thưởng theo bậc (SQL ghi dạng biểu thức) khớp hàm Dart.
    expect(sql, contains('select 100 + 50 * p_tier'));
    expect(sql, contains('select 100 + 100 * p_tier'));
    for (final t in [0, 1, 4]) {
      expect(guildBossRewardGems(t), 100 + 50 * t);
      expect(guildBossRewardCoins(t), 100 + 100 * t);
    }
    expect(sql, contains("'guild_claim_boss()'"));
    expect(sql, contains("'boss', jsonb_build_object("));
    expect(sql, contains('alter table guild_boss_claims enable row level security'));
    expect(sql, contains('revoke all on function guild_boss_hp(uuid) from public, anon, authenticated'));
    expect(sql, contains('revoke all on function guild_boss_tier(uuid) from public, anon, authenticated'));
    expect(repo, contains("'guild_claim_boss'"));
    expect(repo, contains("'boss alive'"));
    // Phần trăm tăng HP mỗi bậc (25%) khớp lời nói trong chú thích của app.
    expect(sql, contains('100 + 25 * guild_boss_tier'));
  });

  test('thưởng thu nhập theo VIP của hội: hằng số SQL ↔ Dart, hàm nội bộ bị khoá', () {
    expect(constant('guild_vip_bonus_per_member'), guildVipBonusPerMember);
    expect(constant('guild_vip_bonus_cap'), guildVipBonusCap);
    expect(constant('guild_vip_min_level'), guildVipMinLevel);
    expect(sql, contains("'guild_vip_bonus()'"));
    expect(sql, contains('revoke all on function guild_vip_count(uuid) from public, anon, authenticated'));
    expect(sql, contains('revoke all on function guild_vip_bonus_pct(uuid) from public, anon, authenticated'));
    expect(sql, contains("'vip_bonus', guild_vip_bonus_pct(v_g.id)"));
    expect(repo, contains("'guild_vip_bonus'"));
    expect(repo, contains("j['vip_bonus']"));
  });

  test('BXH VIP của Hội: hàm SQL có mặt, khoá quyền, chịu được thiếu bảng VIP', () {
    expect(sql, contains('function guild_leaderboard_vip(p_limit integer default 50)'));
    expect(sql, contains("'guild_leaderboard_vip(integer)'"));
    expect(sql, contains('exception when undefined_table then'));
    // App đọc đúng tên RPC và cột.
    expect(repo, contains("'guild_leaderboard_vip'"));
    expect(repo, contains("r['vip_exp']"));
  });

  group('Xu Hội / cửa hàng / BXH phụ khớp SQL', () {
    test('hằng số nạp 💎, buff, số người tối thiểu của BXH trung bình', () {
      expect(constant('guild_donate_daily_cap'), guildDonateDailyCap);
      expect(constant('guild_coins_per_gem'), guildCoinsPerGem);
      expect(constant('guild_buff_price'), guildBuffPrice);
      expect(constant('guild_buff_hours'), guildBuffHours);
      expect(constant('guild_buff_max_hours'), guildBuffMaxHours);
      expect(constant('guild_avg_min_members'), guildAvgMinMembers);
      expect(constant('guild_max_officers'), guildMaxOfficers);
      expect(constant('guild_fund_per_member'), guildFundPerMember);
      expect(constant('guild_fund_min_target'), guildFundMinTarget);
      expect(constant('guild_fund_reward'), guildFundReward);
      expect(constant('guild_fund_min_donation'), guildFundMinDonation);
      expect(constant('guild_team_min_points'), guildTeamMinPoints);
      expect(constant('guild_team_reward'), guildTeamReward);
    });

    test('nhiệm vụ tuần: ngưỡng điểm và thưởng khớp từng bậc', () {
      final need = RegExp(r'guild_quest_need[\s\S]*?when 1 then (\d+) when 2 then (\d+) when 3 then (\d+)')
          .firstMatch(sql)!;
      final reward = RegExp(r'guild_quest_reward[\s\S]*?when 1 then (\d+) when 2 then (\d+) when 3 then (\d+)')
          .firstMatch(sql)!;
      for (var i = 0; i < guildQuests.length; i++) {
        expect(int.parse(need.group(i + 1)!), guildQuests[i].need, reason: 'need ${i + 1}');
        expect(int.parse(reward.group(i + 1)!), guildQuests[i].reward, reason: 'reward ${i + 1}');
      }
    });

    test('bảng giá: mọi món trong cửa hàng có giá y hệt ở SQL, và SQL không bán món lạ', () {
      final block = sql.substring(sql.indexOf('function guild_item_price'));
      final sqlPrices = {
        for (final m in RegExp(r"when '(guild_\w+)' then (\d+)")
            .allMatches(block.substring(0, block.indexOf(r'$$;') > 0 ? block.indexOf('end') : block.length)))
          m.group(1)!: int.parse(m.group(2)!),
      };
      expect(sqlPrices, {for (final i in guildShopItems) i.id: i.price});
    });

    test('hàm nội bộ ghi lịch sử bị thu hồi quyền; RPC mới được cấp quyền', () {
      expect(
          sql.contains(RegExp(
              r'revoke all on function guild_log_week\(uuid, date, bigint\)\s+from public, anon, authenticated')),
          isTrue);
      for (final fn in [
        'guild_leaderboard_avg(integer)',
        'guild_leaderboard_streak(integer)',
        'guild_donate(integer)',
        'guild_claim_quest(integer)',
        'guild_buy_item(text)',
        'guild_buy_buff()',
        'guild_buff_seconds()',
        'guild_chat_post(text)',
        'guild_chat_list(integer)',
        'guild_chat_delete(bigint)',
        'guild_chat_pin(bigint)',
        'guild_chat_report(bigint)',
        'guild_claim_fund()',
        'guild_claim_team()',
      ]) {
        expect(sql.contains("'$fn'"), isTrue, reason: '$fn chưa cấp quyền');
      }
    });

    test('emoji reaction khớp danh sách ở guild_reaction_ok', () {
      final fn = RegExp(r'function guild_reaction_ok.*?\$\$;', dotAll: true).firstMatch(sql)!.group(0)!;
      final inSql = RegExp(r"'([^']+)'").allMatches(fn.substring(fn.indexOf('array['))).map((m) => m.group(1)).toList();
      expect(inSql, guildReactionEmojis);
      expect(sql.contains("'guild_chat_react(bigint,text)'"), isTrue, reason: 'chưa cấp quyền');
    });

    test('mọi bảng mới bật RLS và không có policy', () {
      for (final t in [
        'guild_week_totals',
        'guild_coin_wallets',
        'guild_donations',
        'guild_quest_claims',
        'guild_purchases',
        'guild_messages',
        'guild_message_reports',
        'guild_fund_claims',
      ]) {
        expect(sql.contains(RegExp('alter table $t\\s+enable row level security')), isTrue,
            reason: t);
      }
      expect(sql.contains('create policy'), isFalse);
    });
  });
}
