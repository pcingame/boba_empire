// Công thức: dữ liệu hợp lệ + khớp nguồn; bậc thuộc/ôn cách quãng; sinh câu hỏi luyện.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:boba_empire/core/recipe_mastery.dart';
import 'package:boba_empire/core/recipe_quiz.dart';
import 'package:boba_empire/core/recipes.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeCatalog _catalog() => RecipeCatalog.fromJson(
    jsonDecode(File('assets/recipes/recipes.json').readAsStringSync()) as Map<String, dynamic>);

void main() {
  final catalog = _catalog();

  group('dữ liệu', () {
    test('100 món, id 1..100 liên tục, 5 nhóm; nhóm chơi được có 20 món', () {
      expect(catalog.recipes.map((r) => r.id), List.generate(100, (i) => i + 1));
      expect(catalog.groupNames.length, 5);
      expect(catalog.playable.length, 20);
      expect({for (final r in catalog.playable) r.group}, recipePlayableGroups.toSet());
    });

    test('mỗi món: 1–8 nguyên liệu, lượng > 0, đơn vị g/ml, không trùng tên trong món, tên viết hoa đầu', () {
      for (final r in catalog.recipes) {
        expect(r.ingredients, isNotEmpty, reason: r.name);
        expect(r.ingredients.length, lessThanOrEqualTo(8), reason: r.name);
        expect({for (final i in r.ingredients) i.name}.length, r.ingredients.length, reason: 'trùng nguyên liệu ở ${r.name}');
        for (final i in r.ingredients) {
          expect(i.qty, greaterThan(0), reason: '${r.name}/${i.name}');
          expect(['g', 'ml'], contains(i.unit), reason: '${r.name}/${i.name}');
          expect(i.name[0], i.name[0].toUpperCase(), reason: 'tên nguyên liệu nên viết hoa đầu: ${i.name}');
        }
      }
    });

    test('recipes.json khớp source.md (chạy scripts/make_recipes.py nếu lệch)', () {
      final md = File('scripts/data/recipes_source.md').readAsStringSync();
      final rows = RegExp(r'^\|\s*(\d+)\s*\|', multiLine: true).allMatches(md).length;
      expect(rows, catalog.recipes.length);
      // Nguyên liệu và lượng của vài món đầu/cuối đúng như file nguồn.
      expect(catalog.byId(1)!.name, 'Hồng trà sữa');
      expect(catalog.byId(1)!.ingredients.first.label, 'Hồng trà khô 10 g');
      expect(catalog.byId(1)!.ingredients.length, 5);
      expect(catalog.byId(100), isNotNull);
    });

    test('mọi nguyên liệu nhóm chơi được đều có emoji hợp lệ (không rơi vào dự phòng sai) hoặc dự phòng 🥤', () {
      for (final r in catalog.playable) {
        for (final i in r.ingredients) {
          final e = ingredientEmoji(i.name);
          expect(e, isNotEmpty);
        }
      }
      expect(ingredientEmoji('Matcha'), '🍵');
      expect(ingredientEmoji('Bột kem béo'), '🥄');
      expect(ingredientEmoji('Kem cheese'), '🧀');
      expect(ingredientEmoji('thứ lạ'), '🥤');
    });
  });

  group('bậc thuộc / ôn cách quãng', () {
    test('món mới đến hạn; đúng → lên bậc, hẹn theo bảng; ngày ôn tới lại lên tiếp', () {
      var p = const RecipeProgress();
      expect(p.isDue(0), isTrue);
      var o = applyRecipeAnswer(p, true, 10);
      expect((o.next.box, o.next.dueDay, o.next.best), (1, 10 + recipeIntervalDays[1], 1));
      expect((o.counted, o.leveledUp, o.newBest), (true, true, true));
      p = o.next;
      o = applyRecipeAnswer(p, true, 10 + 1);
      expect((o.next.box, o.next.dueDay), (2, 11 + recipeIntervalDays[2]));
      o = applyRecipeAnswer(o.next, true, o.next.dueDay);
      expect(o.next.box, recipeMaxBox);
      expect(o.newBest, isTrue);
      // Đã Thạo: đúng nữa chỉ dời lịch, không lên, không thưởng.
      final again = applyRecipeAnswer(o.next, true, o.next.dueDay);
      expect((again.next.box, again.leveledUp, again.newBest), (3, false, false));
      expect(again.next.dueDay, o.next.dueDay + recipeIntervalDays[3]);
    });

    test('CHỐNG CÀY: món chưa tới hạn → trả lời đúng/sai không đổi gì', () {
      const p = RecipeProgress(box: 1, dueDay: 20, best: 1);
      for (final correct in [true, false]) {
        final o = applyRecipeAnswer(p, correct, 19);
        expect(o.counted, isFalse);
        expect(o.next.toList(), p.toList());
        expect((o.leveledUp, o.newBest), (false, false));
      }
    });

    test('sai → xuống một bậc (không dưới 0), hẹn ôn ngay; best giữ nguyên', () {
      const p = RecipeProgress(box: 2, dueDay: 5, best: 2);
      final o = applyRecipeAnswer(p, false, 5);
      expect((o.next.box, o.next.dueDay, o.next.best), (1, 5, 2));
      expect(applyRecipeAnswer(const RecipeProgress(), false, 3).next.box, 0);
    });

    test('CHỐNG CÀY THƯỞNG: sai rồi đúng lại cùng ngày không tính là kỷ lục mới', () {
      var p = const RecipeProgress(box: 2, dueDay: 5, best: 2);
      p = applyRecipeAnswer(p, false, 5).next; // xuống bậc 1
      final up = applyRecipeAnswer(p, true, 5); // lên lại bậc 2 = bằng best
      expect(up.next.box, 2);
      expect(up.leveledUp, isTrue);
      expect(up.newBest, isFalse);
    });

    test('lưu/đọc: kẹp giá trị hỏng', () {
      expect(RecipeProgress.fromList([2, 7, 3]).toList(), [2, 7, 3]);
      expect(RecipeProgress.fromList([99, -4, -1]).toList(), [3, 0, 3]); // box kẹp 3; best ≥ box
      expect(RecipeProgress.fromList([]).toList(), [0, 0, 0]);
      expect(RecipeProgress.fromList(['x', null, 1.7]).toList(), [0, 0, 1]);
    });

    test('bảng thưởng: tăng dần, độ dài khớp số bậc', () {
      expect(recipeRewardSeconds.length, recipeMaxBox + 1);
      expect(recipeRewardFloorTaps.length, recipeMaxBox + 1);
      expect(recipeIntervalDays.length, recipeMaxBox + 1);
      expect(recipeRewardSeconds, [...recipeRewardSeconds]..sort());
      expect(recipeIntervalDays, [...recipeIntervalDays]..sort());
    });
  });

  group('câu hỏi', () {
    bool uniq(List<String> l) => l.toSet().length == l.length;

    test('điền nguyên liệu thiếu: 4 lựa chọn khác nhau, đúng 1 đáp án, nhiễu không thuộc món', () {
      final r = Random(1);
      for (final recipe in catalog.playable) {
        for (var k = 0; k < 10; k++) {
          final q = buildQuestion(recipe, QuizKind.missingIngredient, catalog, r);
          expect(q.options.length, 4);
          expect(uniq(q.options), isTrue);
          expect(q.correctText, recipe.ingredients[q.target].name);
          final names = {for (final i in recipe.ingredients) i.name};
          expect(q.options.where(names.contains).length, 1, reason: 'nhiễu không được là nguyên liệu khác của chính món');
        }
      }
    });

    test('đoán lượng: 4 lượng khác nhau cùng đơn vị, đáp án đúng lượng thật', () {
      final r = Random(2);
      for (final recipe in catalog.playable) {
        for (var k = 0; k < 10; k++) {
          final q = buildQuestion(recipe, QuizKind.quantity, catalog, r);
          final ing = recipe.ingredients[q.target];
          expect(q.options.length, 4);
          expect(uniq(q.options), isTrue);
          expect(q.correctText, ing.amount);
          expect(q.options.every((o) => o.endsWith(' ${ing.unit}')), isTrue);
        }
      }
    });

    test('công thức đầy đủ: 4 bản khác nhau, đúng 1 bản trùng công thức thật, bản sai lệch đúng 1 chi tiết', () {
      final r = Random(3);
      for (final recipe in catalog.playable) {
        for (var k = 0; k < 10; k++) {
          final q = buildQuestion(recipe, QuizKind.fullRecipe, catalog, r);
          expect(q.options.length, 4);
          expect(uniq(q.options), isTrue);
          final truth = recipe.ingredients.map((i) => i.label).toList();
          expect(q.options[q.answer].split('\n'), truth);
          for (var i = 0; i < 4; i++) {
            if (i == q.answer) continue;
            final lines = q.options[i].split('\n');
            expect(lines.length, truth.length);
            var diff = 0;
            for (var j = 0; j < lines.length; j++) {
              if (lines[j] != truth[j]) diff++;
            }
            expect(diff, 1, reason: 'bản sai phải lệch đúng một dòng');
          }
        }
      }
    });

    test('loại câu hỏi theo bậc: 0 → thiếu nguyên liệu, 1 → đoán lượng, 2–3 → công thức đầy đủ hoặc đoán lượng', () {
      final r = Random(4);
      expect(kindForBox(0, r), QuizKind.missingIngredient);
      expect(kindForBox(1, r), QuizKind.quantity);
      final kinds = {for (var i = 0; i < 200; i++) kindForBox(3, r)};
      expect(kinds, {QuizKind.fullRecipe, QuizKind.quantity});
    });

    test('xác định theo seed', () {
      final a = buildSession(catalog, {}, 0, Random(9));
      final b = buildSession(catalog, {}, 0, Random(9));
      expect([for (final q in a) (q.recipe.id, q.kind, q.options.join('|'))],
          [for (final q in b) (q.recipe.id, q.kind, q.options.join('|'))]);
    });
  });

  group('buổi luyện', () {
    test('mặc định 8 câu, món khác nhau, toàn món chơi được', () {
      final s = buildSession(catalog, {}, 0, Random(5));
      expect(s.length, 8);
      expect({for (final q in s) q.recipe.id}.length, 8);
      expect(s.every((q) => recipePlayableGroups.contains(q.recipe.group)), isTrue);
      expect(s.every((q) => q.kind == QuizKind.missingIngredient), isTrue); // toàn món mới
    });

    test('ưu tiên món đến hạn, bậc thấp trước; thiếu thì bù món chưa tới hạn', () {
      final ids = catalog.playable.map((r) => r.id).toList();
      // 3 món đến hạn (bậc 2, 0, 1); 17 món còn lại hẹn xa.
      final progress = {
        for (final id in ids) id: const RecipeProgress(box: 3, dueDay: 99, best: 3),
        ids[0]: const RecipeProgress(box: 2, dueDay: 5, best: 2),
        ids[1]: const RecipeProgress(box: 0, dueDay: 0, best: 0),
        ids[2]: const RecipeProgress(box: 1, dueDay: 7, best: 1),
      };
      final s = buildSession(catalog, progress, 10, Random(6));
      expect(s.take(3).map((q) => q.recipe.id), [ids[1], ids[2], ids[0]]); // bậc 0, 1, 2
      expect(s.length, 8); // 3 đến hạn + 5 bù (chỉ để luyện)
      expect(s.skip(3).every((q) => !progress[q.recipe.id]!.isDue(10)), isTrue);
    });

    test('count tuỳ chỉnh; không vượt quá số món có', () {
      expect(buildSession(catalog, {}, 0, Random(7), count: 3).length, 3);
      expect(buildSession(catalog, {}, 0, Random(7), count: 99).length, 20);
    });
  });

  group('chuỗi ngày ôn', () {
    RecipeStreak go(RecipeStreak s, int day) => updateRecipeStreak(s, day).next;

    test('lần đầu = 1; cùng ngày không đổi; ngày liên tiếp +1; bỏ lỡ ≥ 1 ngày bắt đầu lại từ 1', () {
      var s = const RecipeStreak();
      final first = updateRecipeStreak(s, 100);
      expect((first.next.days, first.extended), (1, true));
      s = first.next;
      final same = updateRecipeStreak(s, 100);
      expect((same.next.days, same.extended, same.milestoneGems), (1, false, 0));
      s = go(s, 101);
      s = go(s, 102);
      expect(s.days, 3);
      expect(go(s, 104).days, 1); // lỡ ngày 103 → đứt
      expect(go(s, 110).days, 1);
    });

    test('mốc 💎 chỉ khi vượt kỷ lục: 3 ngày +10, đứt rồi gây lại tới 3 KHÔNG nhận lại', () {
      var s = const RecipeStreak();
      var gems = 0;
      for (var d = 1; d <= 3; d++) {
        final u = updateRecipeStreak(s, d);
        gems += u.milestoneGems;
        s = u.next;
      }
      expect(gems, recipeStreakMilestoneGems[3]);
      expect(s.best, 3);
      // Đứt, gây lại 1 → 2 → 3: đã từng đạt 3 nên không thưởng nữa.
      var again = 0;
      for (var d = 10; d <= 12; d++) {
        final u = updateRecipeStreak(s, d);
        again += u.milestoneGems;
        s = u.next;
      }
      expect((s.days, again), (3, 0));
      // Vượt kỷ lục tới mốc kế (7) thì nhận.
      var seven = 0;
      for (var d = 13; d <= 16; d++) {
        final u = updateRecipeStreak(s, d);
        seven += u.milestoneGems;
        s = u.next;
      }
      expect((s.days, seven), (7, recipeStreakMilestoneGems[7]));
    });

    test('aliveDays: sống nếu ôn hôm nay/hôm qua; đứt thì 0; reviewedToday', () {
      const s = RecipeStreak(days: 5, lastDay: 100, best: 5);
      expect(s.aliveDays(100), 5);
      expect(s.aliveDays(101), 5);
      expect(s.aliveDays(102), 0);
      expect(const RecipeStreak().aliveDays(50), 0);
      expect((s.reviewedToday(100), s.reviewedToday(101)), (true, false));
    });

    test('cứu chuỗi: chỉ khi bỏ lỡ ĐÚNG một ngày và chuỗi ≥ 2; cứu xong chuỗi +1 và nối tiếp được', () {
      const s = RecipeStreak(days: 4, lastDay: 100, best: 4);
      expect((s.restorable(101), s.restorable(102), s.restorable(103)), (false, true, false));
      expect(const RecipeStreak(days: 1, lastDay: 100).restorable(102), isFalse);
      expect(const RecipeStreak().restorable(2), isFalse);
      expect(restoreRecipeStreak(s, 101), s); // không cứu được → giữ nguyên
      expect(restoreRecipeStreak(s, 103), s);
      final r = restoreRecipeStreak(s, 102);
      expect((r.days, r.lastDay, r.best), (5, 101, 5));
      expect(r.restorable(102), isFalse); // cứu rồi không cứu lại
      final next = updateRecipeStreak(r, 102);
      expect((next.next.days, next.extended), (6, true)); // ôn hôm nay nối tiếp
    });

    test('bảng mốc: tăng dần, không rỗng', () {
      final keys = recipeStreakMilestoneGems.keys.toList();
      expect(keys, [...keys]..sort());
      expect(recipeStreakMilestoneGems.values.every((g) => g > 0), isTrue);
    });
  });
}
