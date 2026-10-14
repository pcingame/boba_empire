/// Dữ liệu công thức pha chế (assets/recipes/recipes.json, sinh bằng scripts/make_recipes.py từ
/// source.md) cho trò luyện nhớ công thức. Hàm thuần — không đụng Flutter.
library;

/// Nhóm công thức đang chơi được (1 = Trà sữa truyền thống, 20 món). Các nhóm còn lại đã có sẵn trong
/// dữ liệu, mở thêm bằng cách thêm số nhóm vào đây.
const List<int> recipePlayableGroups = [1];

class RecipeIngredient {
  const RecipeIngredient(this.name, this.qty, this.unit);

  factory RecipeIngredient.fromJson(Map<String, dynamic> j) =>
      RecipeIngredient(j['name'] as String, (j['qty'] as num).toDouble(), j['unit'] as String);

  final String name;
  final double qty;

  /// 'g' hoặc 'ml'.
  final String unit;

  /// "30 g" / "12.5 ml".
  String get amount => '${_fmt(qty)} $unit';

  /// "Bột kem béo 30 g".
  String get label => '$name $amount';

  @override
  bool operator ==(Object other) =>
      other is RecipeIngredient && other.name == name && other.qty == qty && other.unit == unit;

  @override
  int get hashCode => Object.hash(name, qty, unit);
}

String _fmt(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();

class Recipe {
  const Recipe(this.id, this.name, this.group, this.ingredients);

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        (j['id'] as num).toInt(),
        j['name'] as String,
        (j['group'] as num).toInt(),
        [for (final i in j['ingredients'] as List) RecipeIngredient.fromJson(i as Map<String, dynamic>)],
      );

  final int id;
  final String name;
  final int group;
  final List<RecipeIngredient> ingredients;
}

class RecipeCatalog {
  RecipeCatalog(this.recipes, this.groupNames);

  factory RecipeCatalog.fromJson(Map<String, dynamic> j) => RecipeCatalog(
        [for (final r in j['recipes'] as List) Recipe.fromJson(r as Map<String, dynamic>)],
        {for (final g in j['groups'] as List) (g as Map)['id'] as int: g['name'] as String},
      );

  final List<Recipe> recipes;
  final Map<int, String> groupNames;

  /// Các món chơi được (theo [recipePlayableGroups]).
  List<Recipe> get playable => [for (final r in recipes) if (recipePlayableGroups.contains(r.group)) r];

  Recipe? byId(int id) {
    for (final r in recipes) {
      if (r.id == id) return r;
    }
    return null;
  }
}

/// Emoji cho nguyên liệu (nhận theo từ khoá trong tên; thứ tự quan trọng — từ khoá cụ thể trước).
/// Không có emoji hợp thì 🥤. Chỉ là trang trí: người chơi luôn thấy cả TÊN chữ.
String ingredientEmoji(String name) {
  final n = name.toLowerCase();
  const table = <(String, String)>[
    ('matcha', '🍵'),
    ('lục trà', '🍵'),
    ('hồng trà', '🫖'),
    ('ô long', '🍂'),
    ('trà thái', '🧡'),
    ('trà ', '🍃'),
    ('nước nóng', '♨️'),
    ('nước cốt dừa', '🥥'),
    ('sữa hạnh nhân', '🌰'),
    ('sữa đặc', '🥛'),
    ('sữa', '🥛'),
    ('bột kem', '🥄'),
    ('kem cheese', '🧀'),
    ('kem muối', '🧂'),
    ('kem', '🍦'),
    ('đường đen', '🟤'),
    ('đường', '🍬'),
    ('mật ong', '🍯'),
    ('cacao', '🍫'),
    ('chocolate', '🍫'),
    ('khoai môn', '🍠'),
    ('pudding', '🍮'),
    ('caramel', '🍮'),
    ('bạc hà', '🌿'),
    ('dâu', '🍓'),
    ('chuối', '🍌'),
    ('đào', '🍑'),
    ('cam', '🍊'),
    ('chanh', '🍋'),
    ('xoài', '🥭'),
    ('dứa', '🍍'),
    ('cà phê', '☕'),
    ('espresso', '☕'),
    ('trân châu', '⚫'),
    ('oreo', '🍪'),
  ];
  for (final (k, e) in table) {
    if (n.contains(k)) return e;
  }
  return '🥤';
}
