// BXH Thợ pha chế: khớp SQL (trần 100 = số món, tên bảng thưởng), đọc hàng từ RPC, bảng thưởng có 'recipes'.
import 'dart:convert';
import 'dart:io';

import 'package:boba_empire/core/lb_rewards.dart';
import 'package:boba_empire/core/recipe_mastery.dart';
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
}
