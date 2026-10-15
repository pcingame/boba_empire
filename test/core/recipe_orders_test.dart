// Pha theo đơn: lượng trong dữ liệu luôn đặt được; khay đủ nguyên liệu; chấm điểm theo bậc.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:boba_empire/core/accessories.dart' show festivals;
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

  test('hệ số tip combo: 0 dưới combo 2, tăng 0.5 mỗi bậc, kẹp ở combo tối đa', () {
    expect([for (var c = 0; c <= 8; c++) orderComboTipFactor(c)], [0, 0, 0.5, 1, 1.5, 2, 2, 2, 2]);
    expect([for (var n = 2; n <= 6; n++) orderPatienceSeconds(n)], [36, 44, 52, 60, 68], reason: 'kiên nhẫn tăng theo số nguyên liệu');
    expect(orderComboMax, 5);
  });

  group('thử thách hằng ngày', () {
    test('đề cố định theo ngày: gọi lại ra y hệt (cả thứ tự khay); 3 món khác nhau, nhóm 1, như bậc Thạo', () {
      for (final day in [0, 1, 20000, 20740, 99999]) {
        final a = buildDailyOrders(catalog, day);
        final b = buildDailyOrders(catalog, day);
        expect(a.length, dailyOrderCount);
        expect([for (final o in a) o.recipe.id], [for (final o in b) o.recipe.id]);
        expect([for (final o in a) [for (final t in o.tray) t.name]], [for (final o in b) [for (final t in o.tray) t.name]]);
        expect({for (final o in a) o.recipe.id}.length, dailyOrderCount);
        for (final o in a) {
          expect(o.recipe.group, 1);
          expect(o.box, recipeMaxBox);
          expect(o.guide, OrderGuide.none);
          expect(o.tolerance, 0);
        }
      }
    });

    test('ngày khác nhau thì đề khác nhau (không kẹt một đề)', () {
      final sets = {for (var d = 20000; d < 20030; d++) [for (final o in buildDailyOrders(catalog, d)) o.recipe.id].join(',')};
      expect(sets.length, greaterThan(20));
    });

    test('điểm đơn: hoàn hảo 100; lệch 1 mức nửa điểm; lệch xa/thiếu 0; thừa trừ nửa; không âm', () {
      final x = catalog.playable.firstWhere((r) => r.ingredients.length >= 3);
      final o = buildOrder(x, 3, catalog, Random(5));
      int score(List<Poured> p) => scoreOrder(o, gradeOrder(o, p));
      expect(score(exact(o)), 100);

      final first = x.ingredients.first;
      final steps = amountSteps(first.unit);
      final i0 = nearestStep(first.unit, first.qty);
      Poured shifted(int d) => Poured(TrayItem(first.name, first.unit), steps[(i0 + d).clamp(0, steps.length - 1)]);
      List<Poured> withFirst(Poured p) => [p, ...exact(o).skip(1)];
      final n = x.ingredients.length;
      final d1 = i0 + 1 < steps.length ? 1 : -1;
      expect(score(withFirst(shifted(d1))), (100 * (n - 1 + 0.5) / n).round());
      final d2 = i0 + 2 < steps.length ? 2 : -2;
      expect(score(withFirst(shifted(d2))), (100 * (n - 1) / n).round());
      expect(score(exact(o).skip(1).toList()), (100 * (n - 1) / n).round()); // thiếu 1
      final extra = o.tray.firstWhere((t) => !x.ingredients.any((i) => i.name == t.name));
      expect(score([...exact(o), Poured(extra, 10)]), (100 * (n - 0.5) / n).round());
      expect(score([Poured(extra, 10)]), 0, reason: 'điểm không âm');
      expect(score(const []), 0);
    });
  });

  group('đơn lễ hội', () {
    final cat = RecipeCatalog.fromJson(
        jsonDecode(File('assets/recipes/recipes.json').readAsStringSync()) as Map<String, dynamic>);

    test('mọi dịp lễ có danh sách món; món tồn tại và thuộc nhóm 1–2 (ai cũng có sớm)', () {
      for (final f in festivals) {
        final ids = festivalRecipeIds[f.id];
        expect(ids, isNotNull, reason: 'dịp ${f.id} thiếu món chủ đề');
        for (final id in ids!) {
          expect(cat.recipes.where((x) => x.id == id && x.group <= 2).length, 1, reason: '${f.id}: món $id');
        }
      }
    });

    test('chọn món theo ngày, gắn nhãn dịp, tôn trọng pool và exclude; không có món hợp lệ ⇒ null', () {
      final pool = cat.recipes;
      final a = buildFestivalOrder('halloween', cat, const {}, 0, Random(1), pool: pool)!;
      final b = buildFestivalOrder('halloween', cat, const {}, 1, Random(1), pool: pool)!;
      expect(a.festival, 'halloween');
      expect(a.recipe.id, festivalRecipeIds['halloween']![0]);
      expect(b.recipe.id, festivalRecipeIds['halloween']![1]);
      final ex = buildFestivalOrder('halloween', cat, const {}, 0, Random(1), pool: pool, exclude: {a.recipe.id})!;
      expect(ex.recipe.id, isNot(a.recipe.id));
      expect(buildFestivalOrder('halloween', cat, const {}, 0, Random(1), pool: const []), isNull);
      expect(buildFestivalOrder('khong_co', cat, const {}, 0, Random(1), pool: pool), isNull);
      expect(buildFestivalOrder('halloween', cat, const {}, 0, Random(1),
          pool: pool, exclude: {...festivalRecipeIds['halloween']!}), isNull);
    });
  });
}
