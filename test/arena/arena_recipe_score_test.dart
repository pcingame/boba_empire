// PK công thức: điểm một đơn do server (SQL) chấm lại — vector PHẢI trùng supabase/tests/arena_recipe_scenarios.sql,
// và dữ liệu món/bước lượng trong SQL PHẢI khớp assets + recipe_orders.dart.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:boba_empire/core/recipe_mastery.dart';
import 'package:boba_empire/core/recipe_orders.dart';
import 'package:boba_empire/core/recipes.dart';
import 'package:flutter_test/flutter_test.dart';

final _catalog = RecipeCatalog.fromJson(
    jsonDecode(File('assets/recipes/recipes.json').readAsStringSync()) as Map<String, dynamic>);

int _score(int recipeId, Map<String, double> pours) {
  final r = _catalog.recipes.firstWhere((x) => x.id == recipeId);
  final order = buildOrder(r, recipeMaxBox, _catalog, Random(1));
  final unit = {for (final i in r.ingredients) i.name: i.unit};
  final poured = [
    for (final e in pours.entries) Poured(TrayItem(e.key, unit[e.key] ?? 'g'), e.value),
  ];
  return scoreOrder(order, gradeOrder(order, poured));
}

void main() {
  test('vector chấm điểm trùng SQL (recipe 1, bậc Thạo)', () {
    const all = {'Hồng trà khô': 10.0, 'Nước nóng': 200.0, 'Bột kem béo': 30.0, 'Sữa đặc': 15.0, 'Đường nước': 20.0};
    expect(_score(1, all), 100);
    expect(_score(1, {...all, 'Hồng trà khô': 12}), 90);
    expect(_score(1, {...all}..remove('Đường nước')), 80);
    expect(_score(1, {...all, 'Matcha': 5}), 90);
    expect(_score(1, {...all, 'Hồng trà khô': 20}), 80);
    expect(_score(1, {}), 0);
    expect(_score(1, {'Hồng trà khô': 10}), 20);
    expect(_score(1, {'Hồng trà khô': 12, 'Nước nóng': 200, 'Matcha': 5}), 20);
    expect(_score(1, {'Nước nóng': 205}), 20);
    expect(_score(1, {'Matcha': 5, 'Sữa tươi': 100}), 0);
  });

  test('dữ liệu trong arena_schema.sql khớp assets: món nhóm 1 và bước lượng', () {
    final sql = File('supabase/arena_schema.sql').readAsStringSync();
    final rows = RegExp(r"\((\d+), '(\[.*?\])'::jsonb\)").allMatches(sql).toList();
    final group1 = _catalog.inGroup(1);
    expect(rows.length, group1.length);
    for (final m in rows) {
      final id = int.parse(m.group(1)!);
      final r = group1.firstWhere((x) => x.id == id, orElse: () => fail('SQL có món $id ngoài nhóm 1'));
      final ings = (jsonDecode(m.group(2)!) as List).cast<Map<String, dynamic>>();
      expect([for (final i in ings) (i['name'], (i['qty'] as num).toDouble(), i['unit'])],
          [for (final i in r.ingredients) (i.name, i.qty, i.unit)],
          reason: 'món $id');
    }
    List<double> steps(String unit) {
      final m = RegExp("case when p_unit = 'g'\\s+then array\\[([^\\]]*)\\]::numeric\\[\\]\\s+else array\\[([^\\]]*)\\]").firstMatch(sql)!;
      return [for (final x in m.group(unit == 'g' ? 1 : 2)!.split(',')) double.parse(x)];
    }
    expect(steps('g'), recipeGramSteps);
    expect(steps('ml'), recipeMlSteps);
  });
}
