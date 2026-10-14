/// Sinh câu hỏi luyện công thức (thuần, nhận Random từ ngoài nên test được tất định).
library;

import 'dart:math' as math;

import 'recipe_mastery.dart';
import 'recipes.dart';

enum QuizKind {
  /// Điền nguyên liệu còn thiếu (thấy lượng, ẩn tên) — bậc Mới.
  missingIngredient,

  /// Đoán lượng của một nguyên liệu — bậc Quen.
  quantity,

  /// Chọn công thức đầy đủ đúng trong 4 bản (3 bản bị đổi một chi tiết) — bậc Thuộc/Thạo.
  fullRecipe,
}

class QuizQuestion {
  const QuizQuestion({
    required this.recipe,
    required this.kind,
    required this.options,
    required this.answer,
    this.target = -1,
  });

  final Recipe recipe;
  final QuizKind kind;

  /// Bốn lựa chọn hiển thị. Với [QuizKind.fullRecipe] mỗi lựa chọn là các dòng nguyên liệu nối bằng '\n'.
  final List<String> options;

  /// Chỉ số lựa chọn đúng trong [options].
  final int answer;

  /// Chỉ số nguyên liệu bị hỏi (missingIngredient / quantity); -1 với fullRecipe.
  final int target;

  String get correctText => options[answer];
}

/// Loại câu hỏi cho món đang ở bậc [box].
QuizKind kindForBox(int box, math.Random r) => switch (box) {
      0 => QuizKind.missingIngredient,
      1 => QuizKind.quantity,
      // Bậc cao vẫn xen câu đoán lượng để không đơn điệu.
      _ => r.nextDouble() < 0.7 ? QuizKind.fullRecipe : QuizKind.quantity,
    };

List<T> _shuffled<T>(Iterable<T> it, math.Random r) => it.toList()..shuffle(r);

QuizQuestion buildQuestion(Recipe recipe, QuizKind kind, RecipeCatalog catalog, math.Random r) {
  // Đáp án nhiễu lấy từ CÙNG NHÓM cho hợp lý (nhóm cà phê thì nhiễu là đồ cà phê…); nhóm quá nhỏ thì lấy chung.
  final groupPool = catalog.inGroup(recipe.group);
  final pool = groupPool.length >= 8 ? groupPool : catalog.playable;
  switch (kind) {
    case QuizKind.missingIngredient:
      final t = r.nextInt(recipe.ingredients.length);
      final correct = recipe.ingredients[t].name;
      final inRecipe = {for (final i in recipe.ingredients) i.name};
      final others = {for (final x in pool) for (final i in x.ingredients) i.name}..removeAll(inRecipe);
      final wrong = _shuffled(others, r).take(3).toList();
      final options = _shuffled([correct, ...wrong], r);
      return QuizQuestion(
          recipe: recipe, kind: kind, options: options, answer: options.indexOf(correct), target: t);

    case QuizKind.quantity:
      final t = r.nextInt(recipe.ingredients.length);
      final ing = recipe.ingredients[t];
      return _quantityQuestion(recipe, t, ing, pool, r);

    case QuizKind.fullRecipe:
      final correct = recipe.ingredients.map((i) => i.label).join('\n');
      final seen = {correct};
      final options = <String>[correct];
      // Mỗi bản sai đổi đúng một chi tiết: một nguyên liệu hoặc một lượng.
      var guard = 0;
      while (options.length < 4 && guard++ < 60) {
        final t = r.nextInt(recipe.ingredients.length);
        final list = [...recipe.ingredients];
        final ing = list[t];
        if (r.nextBool()) {
          final used = {for (final i in list) i.name};
          final cands = {for (final x in pool) for (final i in x.ingredients) i.name}..removeAll(used);
          if (cands.isEmpty) continue;
          list[t] = RecipeIngredient(_shuffled(cands, r).first, ing.qty, ing.unit);
        } else {
          final q = _nearbyQuantities(ing, pool, r).first;
          list[t] = RecipeIngredient(ing.name, q, ing.unit);
        }
        final text = list.map((i) => i.label).join('\n');
        if (seen.add(text)) options.add(text);
      }
      final shuffled = _shuffled(options, r);
      return QuizQuestion(
          recipe: recipe, kind: kind, options: shuffled, answer: shuffled.indexOf(correct));
  }
}

QuizQuestion _quantityQuestion(
    Recipe recipe, int t, RecipeIngredient ing, List<Recipe> pool, math.Random r) {
  final wrong = _nearbyQuantities(ing, pool, r).take(3).toList();
  final labels = _shuffled([ing.qty, ...wrong], r).map((q) => RecipeIngredient(ing.name, q, ing.unit).amount).toList();
  return QuizQuestion(
      recipe: recipe,
      kind: QuizKind.quantity,
      options: labels,
      answer: labels.indexOf(ing.amount),
      target: t);
}

/// Các lượng khác của cùng đơn vị, gần lượng thật nhất (gây nhiễu hợp lý), luôn ≥ 3 giá trị khác nhau.
List<double> _nearbyQuantities(RecipeIngredient ing, List<Recipe> pool, math.Random r) {
  final seen = <double>{ing.qty};
  final cands = <double>[];
  // Lượng của chính nguyên liệu này ở món khác, rồi lượng cùng đơn vị bất kỳ.
  for (final x in pool) {
    for (final i in x.ingredients) {
      if (i.unit == ing.unit && seen.add(i.qty)) cands.add(i.qty);
    }
  }
  cands.sort((a, b) => ((a - ing.qty).abs()).compareTo((b - ing.qty).abs()));
  final near = cands.take(6).toList();
  final out = _shuffled(near, r);
  // Bù nếu dữ liệu quá thưa: bội số của 5.
  var step = 5.0;
  while (out.length < 3) {
    final v = ing.qty + step;
    if (seen.add(v)) out.add(v);
    step += 5;
  }
  return out;
}

/// Chọn [count] món cho một buổi: ưu tiên món ĐẾN HẠN ôn (bậc thấp trước), thiếu thì bù món chưa tới hạn (chỉ để
/// luyện). [pool] = các món được phép (mặc định mọi món chơi được; UI truyền các món của nhóm đã mở). Dùng chung
/// cho buổi trắc nghiệm ([buildSession]) và buổi pha theo đơn (recipe_orders.dart).
List<Recipe> pickRecipes(
  RecipeCatalog catalog,
  Map<int, RecipeProgress> progress,
  int today,
  math.Random r, {
  int count = 8,
  Iterable<Recipe>? pool,
}) {
  RecipeProgress p(Recipe x) => progress[x.id] ?? const RecipeProgress();
  final all = _shuffled(pool ?? catalog.playable, r); // xáo trước: ngang bậc thì ngẫu nhiên
  // Bậc thấp trước; cùng bậc giữ thứ tự đã xáo (so thêm chỉ số — List.sort không đảm bảo ổn định).
  final due = [for (final x in all) if (p(x).isDue(today)) x]
    ..sort((a, b) {
      final c = p(a).box.compareTo(p(b).box);
      return c != 0 ? c : all.indexOf(a).compareTo(all.indexOf(b));
    });
  final rest = [for (final x in all) if (!p(x).isDue(today)) x];
  return [...due, ...rest].take(count).toList();
}

/// Một buổi luyện trắc nghiệm: [pickRecipes] rồi sinh câu hỏi theo bậc của từng món.
List<QuizQuestion> buildSession(
  RecipeCatalog catalog,
  Map<int, RecipeProgress> progress,
  int today,
  math.Random r, {
  int count = 8,
  Iterable<Recipe>? pool,
}) {
  final picked = pickRecipes(catalog, progress, today, r, count: count, pool: pool);
  RecipeProgress p(Recipe x) => progress[x.id] ?? const RecipeProgress();
  return [
    for (final x in picked) buildQuestion(x, kindForBox(p(x).box, r), catalog, r),
  ];
}
