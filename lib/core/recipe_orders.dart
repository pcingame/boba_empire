/// Chế độ "Pha theo đơn": khách gọi một món, người chơi chọn nguyên liệu từ khay (kéo vào ly) và đặt lượng. Hàm thuần
/// (nhận Random từ ngoài) — chấm điểm, ra đề, độ khó theo bậc thuộc của món.
library;

import 'dart:math' as math;

import 'recipe_mastery.dart';
import 'recipe_quiz.dart' show pickRecipes;
import 'recipes.dart';

/// Các mức lượng chọn được (thanh trượt theo chỉ số). PHẢI chứa mọi lượng có trong dữ liệu để luôn pha đúng được
/// (test kiểm). Bước rời rạc và không đều: sát thực tế hơn thanh liên tục (ai pha cũng đo theo mốc 5/10/15…).
const List<double> recipeGramSteps = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 120];
const List<double> recipeMlSteps = [2, 5, 10, 15, 20, 25, 30, 35, 40, 50, 60, 70, 80, 100, 120, 150, 180, 200, 220, 230, 250, 300];

List<double> amountSteps(String unit) => unit == 'g' ? recipeGramSteps : recipeMlSteps;

/// Chỉ số của mức gần [value] nhất trong [amountSteps].
int nearestStep(String unit, double value) {
  final s = amountSteps(unit);
  var best = 0;
  for (var i = 1; i < s.length; i++) {
    if ((s[i] - value).abs() < (s[best] - value).abs()) best = i;
  }
  return best;
}

/// Mức gợi ý hiển thị cho người chơi theo bậc thuộc: món càng thuộc càng ít gợi ý.
enum OrderGuide {
  /// Bậc Mới: thấy cả công thức mẫu (tên + lượng).
  full,

  /// Bậc Quen: thấy tên các nguyên liệu, phải nhớ lượng.
  names,

  /// Bậc Thuộc: chỉ biết số nguyên liệu.
  count,

  /// Bậc Thạo: chỉ có tên món.
  none,
}

OrderGuide guideForBox(int box) => switch (box) {
      0 => OrderGuide.full,
      1 => OrderGuide.names,
      2 => OrderGuide.count,
      _ => OrderGuide.none,
    };

/// Số nguyên liệu gây nhiễu thêm vào khay theo bậc.
int trayDistractorsForBox(int box) => 2 + box.clamp(0, recipeMaxBox);

/// Sai lệch lượng tối đa (số mức trên thanh trượt) vẫn tính là ĐÚNG món: bậc Mới/Quen cho lệch 1 mức, từ bậc Thuộc
/// phải đúng từng mức.
int toleranceForBox(int box) => box <= 1 ? 1 : 0;

/// Một nguyên liệu trên khay: tên (khoá tiếng Việt) + đơn vị.
class TrayItem {
  const TrayItem(this.name, this.unit);
  final String name;
  final String unit;

  @override
  bool operator ==(Object other) => other is TrayItem && other.name == name && other.unit == unit;

  @override
  int get hashCode => Object.hash(name, unit);
}

class Order {
  const Order({required this.recipe, required this.box, required this.tray, required this.guide});

  final Recipe recipe;

  /// Bậc thuộc của món lúc ra đơn (quyết định gợi ý, khay, dung sai).
  final int box;

  /// Khay nguyên liệu đã xáo: nguyên liệu của món + gây nhiễu cùng nhóm.
  final List<TrayItem> tray;
  final OrderGuide guide;

  int get tolerance => toleranceForBox(box);
}

/// Ra một đơn cho [recipe] đang ở bậc [box].
Order buildOrder(Recipe recipe, int box, RecipeCatalog catalog, math.Random r) {
  final own = [for (final i in recipe.ingredients) TrayItem(i.name, i.unit)];
  final ownNames = {for (final i in own) i.name};
  // Nhiễu lấy từ CÙNG nhóm cho hợp lý; nhóm nhỏ thì lấy chung.
  final groupPool = catalog.inGroup(recipe.group);
  final pool = groupPool.length >= 8 ? groupPool : catalog.playable;
  final seen = <String>{...ownNames};
  final others = <TrayItem>[];
  for (final x in pool) {
    for (final i in x.ingredients) {
      if (seen.add(i.name)) others.add(TrayItem(i.name, i.unit));
    }
  }
  others.shuffle(r);
  final tray = [...own, ...others.take(trayDistractorsForBox(box))]..shuffle(r);
  return Order(recipe: recipe, box: box, tray: tray, guide: guideForBox(box));
}

/// Một buổi [count] đơn: món chọn như buổi trắc nghiệm (đến hạn trước, bậc thấp trước).
List<Order> buildOrders(
  RecipeCatalog catalog,
  Map<int, RecipeProgress> progress,
  int today,
  math.Random r, {
  int count = 5,
  Iterable<Recipe>? pool,
}) {
  final picked = pickRecipes(catalog, progress, today, r, count: count, pool: pool);
  return [for (final x in picked) buildOrder(x, (progress[x.id] ?? const RecipeProgress()).box, catalog, r)];
}

/// Nguyên liệu đã cho vào ly với lượng người chơi chọn.
class Poured {
  const Poured(this.item, this.value);
  final TrayItem item;
  final double value;
}

enum ItemVerdict {
  /// Đúng nguyên liệu, đúng lượng.
  exact,

  /// Đúng nguyên liệu, lệch 1 mức (đạt ở bậc Mới/Quen).
  close,

  /// Đúng nguyên liệu nhưng lượng lệch ≥ 2 mức, hoặc lệch 1 mức ở bậc phải chính xác.
  wrongAmount,

  /// Cần nhưng chưa cho.
  missing,

  /// Cho thừa nguyên liệu không có trong công thức.
  extra,
}

class ItemGrade {
  const ItemGrade(this.name, this.unit, this.verdict, {this.mine, this.right});

  final String name;
  final String unit;
  final ItemVerdict verdict;

  /// Lượng người chơi cho (null nếu thiếu) / lượng đúng của công thức (null nếu thừa).
  final double? mine;
  final double? right;

  bool get ok => verdict == ItemVerdict.exact || verdict == ItemVerdict.close;
}

class OrderResult {
  const OrderResult(this.items, {required this.correct, required this.stars});

  /// Công thức theo thứ tự nguyên liệu của món, rồi các nguyên liệu thừa.
  final List<ItemGrade> items;

  /// Tính là pha ĐÚNG (đủ, không thừa, lượng trong dung sai) — dùng để ghi bậc thuộc.
  final bool correct;

  /// 3 = hoàn hảo (mọi lượng chính xác); 2 = đạt nhưng có lượng lệch 1 mức; 1 = chưa đúng.
  final int stars;
}

/// Chấm [poured] cho [order]. Cùng một nguyên liệu cho nhiều lần thì lấy lần cuối.
OrderResult gradeOrder(Order order, List<Poured> poured) {
  final byName = {for (final p in poured) p.item.name: p};
  final items = <ItemGrade>[];
  for (final ing in order.recipe.ingredients) {
    final p = byName.remove(ing.name);
    if (p == null) {
      items.add(ItemGrade(ing.name, ing.unit, ItemVerdict.missing, right: ing.qty));
      continue;
    }
    final diff = (nearestStep(ing.unit, p.value) - nearestStep(ing.unit, ing.qty)).abs();
    final verdict = diff == 0
        ? ItemVerdict.exact
        : (diff <= order.tolerance ? ItemVerdict.close : ItemVerdict.wrongAmount);
    items.add(ItemGrade(ing.name, ing.unit, verdict, mine: p.value, right: ing.qty));
  }
  for (final p in byName.values) {
    items.add(ItemGrade(p.item.name, p.item.unit, ItemVerdict.extra, mine: p.value));
  }
  final correct = items.every((g) => g.ok);
  final perfect = items.every((g) => g.verdict == ItemVerdict.exact);
  return OrderResult(items, correct: correct, stars: perfect ? 3 : (correct ? 2 : 1));
}
