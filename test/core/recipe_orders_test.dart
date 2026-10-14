// Pha theo đơn: lượng trong dữ liệu luôn đặt được; khay đủ nguyên liệu; chấm điểm theo bậc.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:boba_empire/core/recipe_mastery.dart';
import 'package:boba_empire/core/recipe_orders.dart';
import 'package:boba_empire/core/recipes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = RecipeCatalog.fromJson(
      jsonDecode(File('assets/recipes/recipes.json').readAsStringSync()) as Map<String, dynamic>);

  List<Poured> exact(Order o) => [
        for (final i in o.recipe.ingredients) Poured(TrayItem(i.name, i.unit), i.qty),
      ];

  test('mọi lượng trong dữ liệu nằm đúng trên thanh trượt; mỗi tên nguyên liệu chỉ một đơn vị', () {
    final units = <String, String>{};
    for (final r in catalog.recipes) {
      for (final i in r.ingredients) {
        expect(amountSteps(i.unit), contains(i.qty), reason: '${r.name}/${i.name} ${i.qty}${i.unit}');
        expect(units.putIfAbsent(i.name, () => i.unit), i.unit, reason: i.name);
      }
    }
  });

  test('khay: chứa đủ nguyên liệu của món, không trùng tên, nhiễu tăng theo bậc', () {
    final r = Random(1);
    for (final x in catalog.playable) {
      for (var box = 0; box <= recipeMaxBox; box++) {
        final o = buildOrder(x, box, catalog, r);
        final names = [for (final t in o.tray) t.name];
        expect(names.toSet().length, names.length, reason: x.name);
        for (final i in x.ingredients) {
          expect(names, contains(i.name));
        }
        expect(names.length, x.ingredients.length + trayDistractorsForBox(box), reason: '${x.name} bậc $box');
      }
    }
  });

  test('gợi ý giảm dần theo bậc', () {
    expect([for (var b = 0; b <= 3; b++) guideForBox(b)], OrderGuide.values);
  });

  test('chấm: đúng hết = 3 sao; thiếu/thừa/lệch → sai', () {
    final x = catalog.playable.firstWhere((r) => r.ingredients.length >= 3);
    final o = buildOrder(x, 3, catalog, Random(2));
    final ok = gradeOrder(o, exact(o));
    expect((ok.correct, ok.stars), (true, 3));

    final miss = gradeOrder(o, exact(o).sublist(1));
    expect(miss.correct, false);
    expect(miss.items.first.verdict, ItemVerdict.missing);

    final extraTray = o.tray.firstWhere((t) => !x.ingredients.any((i) => i.name == t.name));
    final extra = gradeOrder(o, [...exact(o), Poured(extraTray, 10)]);
    expect((extra.correct, extra.items.last.verdict), (false, ItemVerdict.extra));
  });

  test('dung sai: bậc Mới/Quen lệch 1 mức vẫn đạt (2 sao), bậc Thuộc/Thạo thì không; lệch 2 mức luôn sai', () {
    final x = catalog.playable.first;
    final first = x.ingredients.first;
    final steps = amountSteps(first.unit);
    final i0 = nearestStep(first.unit, first.qty);
    List<Poured> shifted(Order o, int d) => [
          for (final i in o.recipe.ingredients)
            Poured(TrayItem(i.name, i.unit), i == first ? steps[i0 + d] : i.qty),
        ];
    for (var box = 0; box <= 3; box++) {
      final o = buildOrder(x, box, catalog, Random(3));
      final one = gradeOrder(o, shifted(o, i0 + 1 < steps.length ? 1 : -1));
      expect(one.correct, box <= 1, reason: 'bậc $box');
      if (box <= 1) expect(one.stars, 2);
      final two = gradeOrder(o, shifted(o, i0 + 2 < steps.length ? 2 : -2));
      expect(two.correct, false, reason: 'bậc $box');
      expect(two.items.first.verdict, ItemVerdict.wrongAmount);
    }
  });

  test('buildOrders: đủ số đơn, bậc lấy từ tiến độ', () {
    final pool = catalog.inGroup(1);
    final os = buildOrders(catalog, {pool.first.id: const RecipeProgress(box: 2, dueDay: 0, best: 2)}, 100, Random(4),
        pool: pool);
    expect(os.length, 5);
    for (final o in os) {
      expect(o.box, o.recipe.id == pool.first.id ? 2 : 0);
    }
  });
}
