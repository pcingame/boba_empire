// BXH Thợ pha chế: khớp SQL (trần 100 = số món, tên bảng thưởng), đọc hàng từ RPC, bảng thưởng có 'recipes'.
import 'dart:convert';
import 'dart:io';

import 'package:boba_empire/core/lb_rewards.dart';
import 'package:boba_empire/core/recipe_mastery.dart';
import 'package:boba_empire/core/recipe_orders.dart';
import 'package:boba_empire/core/recipes.dart';
import 'package:boba_empire/leaderboard/lb_rewards.dart';
import 'package:boba_empire/leaderboard/recipe_leaderboard_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File('supabase/recipe_leaderboard_schema.sql').readAsStringSync();
  final catalog = RecipeCatalog.fromJson(
      jsonDecode(File('assets/recipes/recipes.json').readAsStringSync()) as Map<String, dynamic>);

  test('trần SQL = số món trong danh mục (mở thêm món phải sửa cả hai)', () {
    final cap = int.parse(RegExp(r'mastered\s+integer not null check \(mastered between 0 and (\d+)\)')
        .firstMatch(sql)!
        .group(1)!);
    expect(cap, catalog.recipes.length);
  });

  test('SQL: chỉ tăng, RLS chỉ hàng của mình, top kẹp 100, khách đọc được', () {
    expect(sql, contains('new.mastered < old.mastered'));
    expect(sql, contains('auth.uid() = user_id'));
    expect(sql, contains('least(coalesce(p_limit, 50), 100)'));
    expect(sql, contains('grant execute on function recipe_leaderboard_top(integer) to anon, authenticated'));
    expect(sql, isNot(contains('for delete')), reason: 'không có policy xoá');
  });

  test('bảng thưởng: SQL liệt kê đủ board mới, snapshot đọc đúng nguồn, Dart có LbBoard.recipes', () {
    final rewards = File('supabase/leaderboard_rewards_schema.sql').readAsStringSync();
    expect(rewards, contains("'recipes'"));
    expect(rewards, contains('recipe_leaderboard_entries'));
    expect(rewards, contains('e.mastered::numeric as v'));
    expect(LbBoard.values.map((b) => b.name), contains('recipes'));
    // Server mới hơn gửi board lạ thì bản app cũ bỏ qua dòng đó (không ném).
    expect(parseLbRewards([
      {'week': '2026-10-12', 'board': 'recipes', 'rank': 1, 'gems': 300, 'claimed': false},
      {'week': '2026-10-12', 'board': 'khong_biet', 'rank': 1, 'gems': 300},
    ]).map((r) => r.board), [LbBoard.recipes]);
  });

  test('bảng thưởng có Pha theo đơn (cộng dồn) và Thử thách ngày (tổng điểm TUẦN TRƯỚC, top 10)', () {
    final rewards = File('supabase/leaderboard_rewards_schema.sql').readAsStringSync();
    expect(rewards, contains("'orders'"));
    expect(rewards, contains('recipe_order_leaderboard_entries'));
    expect(rewards, contains('e.perfected::numeric as v'));
    expect(LbBoard.values.map((b) => b.name), containsAll(['orders', 'daily']));
    // Thử thách ngày: cộng điểm các ngày của tuần trước (không dính tuần này), loại ẩn danh, top 10.
    expect(rewards, contains('recipe_daily_scores'));
    expect(rewards, contains('sum(d.score)'));
    expect(rewards, contains('d.day >= v_from and d.day < v_to'));
    expect(rewards, contains('not u.is_anonymous and d.day'));
    expect(rewards, contains('b.rn <= 10'));
  });

  test('đọc một hàng từ RPC', () {
    final e = RecipeLeaderboardEntry.fromRow(const {'user_id': 'abc', 'nickname': 'Boba', 'mastered': 7, 'rank': 3});
    expect((e.userId, e.nickname, e.mastered, e.rank), ('abc', 'Boba', 7, 3));
  });

  test('số đem đi xếp hạng: chỉ đếm món đã TỪNG Thạo (best), xuống bậc không làm giảm', () {
    final progress = {
      '1': [3, 10, 3], // đang Thạo
      '2': [2, 10, 3], // từng Thạo, đã tụt xuống Thuộc: vẫn tính
      '3': [2, 10, 2], // chưa từng Thạo
      '4': [0, 0, 0],
    };
    expect(recipeMasteredEver(progress), 2);
    expect(recipeMasteredEver({}), 0);
    // Không bao giờ vượt tổng số món (trần SQL).
    expect(recipeMasteredEver({for (final r in catalog.recipes) '${r.id}': [3, 0, 3]}), lessThanOrEqualTo(100));
  });

  test('mốc rương phụ kiện: tăng dần, độ hiếm tăng dần, không vượt số món chơi được', () {
    final keys = recipeAccessoryMilestones.keys.toList();
    expect(keys, [...keys]..sort());
    final rarities = recipeAccessoryMilestones.values.map((r) => r.index).toList();
    expect(rarities, [...rarities]..sort());
    expect(keys.last, lessThanOrEqualTo(catalog.playable.length));
  });

  group('bảng Pha theo đơn', () {
    final osql = File('supabase/recipe_order_leaderboard_schema.sql').readAsStringSync();

    test('trần SQL = số món; chỉ tăng; ghi cần đã liên kết email ở SERVER; không policy xoá', () {
      final cap = int.parse(
          RegExp(r'perfected\s+integer not null check \(perfected between 0 and (\d+)\)').firstMatch(osql)!.group(1)!);
      expect(cap, catalog.recipes.length);
      expect(osql, contains('new.perfected < old.perfected'));
      expect(osql, contains('least(coalesce(p_limit, 50), 100)'));
      // Cả INSERT lẫn UPDATE (using + with check) đều đòi is_linked_user().
      expect(RegExp(r'is_linked_user\(\)').allMatches(osql.split('create table').last).length, greaterThanOrEqualTo(3));
      expect(osql, isNot(contains('for delete')));
    });

    test('enum bảng: tên bảng/RPC/cột khớp SQL; đọc hàng theo đúng cột', () {
      expect(osql, contains('create table if not exists ${RecipeBoard.orders.table}'));
      expect(osql, contains('function ${RecipeBoard.orders.topRpc}'));
      expect(sql, contains('function ${RecipeBoard.quiz.topRpc}'));
      final row = {'user_id': 'u', 'nickname': 'n', 'perfected': 7, 'mastered': 1, 'rank': 2};
      expect(RecipeLeaderboardEntry.fromRow(row, RecipeBoard.orders).mastered, 7);
      expect(RecipeLeaderboardEntry.fromRow(row).mastered, 1);
    });
  });

  group('bảng thử thách ngày', () {
    final dsql = File('supabase/recipe_daily_schema.sql').readAsStringSync();

    test('SQL: trần 300 = dailyMaxScore, ngày do server đặt, chỉ INSERT (bất biến), cần email, top theo hôm nay', () {
      expect(dsql, contains('check (score between 0 and $dailyMaxScore)'));
      expect(dsql, contains('default recipe_daily_today()'));
      expect(dsql, contains('with check (auth.uid() = user_id and day = recipe_daily_today() and is_linked_user())'));
      expect(dsql, isNot(contains('for update')));
      expect(dsql, isNot(contains('for delete')));
      expect(dsql, contains('where day = recipe_daily_today()'));
      expect(dsql, contains('least(coalesce(p_limit, 50), 100)'));
    });

    test('enum bảng: bảng/RPC/cột khớp SQL', () {
      expect(dsql, contains('create table if not exists ${RecipeBoard.daily.table}'));
      expect(dsql, contains('function ${RecipeBoard.daily.topRpc}'));
      final row = {'user_id': 'u', 'nickname': 'n', 'score': 222, 'rank': 1};
      expect(RecipeLeaderboardEntry.fromRow(row, RecipeBoard.daily).mastered, 222);
    });
  });
}
