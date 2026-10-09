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

  group('Xu Hội / cửa hàng / BXH phụ khớp SQL', () {
    test('hằng số nạp 💎, buff, số người tối thiểu của BXH trung bình', () {
      expect(constant('guild_donate_daily_cap'), guildDonateDailyCap);
      expect(constant('guild_coins_per_gem'), guildCoinsPerGem);
      expect(constant('guild_buff_price'), guildBuffPrice);
      expect(constant('guild_buff_hours'), guildBuffHours);
      expect(constant('guild_buff_max_hours'), guildBuffMaxHours);
      expect(constant('guild_avg_min_members'), guildAvgMinMembers);
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
      ]) {
        expect(sql.contains("'$fn'"), isTrue, reason: '$fn chưa cấp quyền');
      }
    });

    test('mọi bảng mới bật RLS và không có policy', () {
      for (final t in [
        'guild_week_totals',
        'guild_coin_wallets',
        'guild_donations',
        'guild_quest_claims',
        'guild_purchases',
      ]) {
        expect(sql.contains(RegExp('alter table $t\\s+enable row level security')), isTrue,
            reason: t);
      }
      expect(sql.contains('create policy'), isFalse);
    });
  });
}
