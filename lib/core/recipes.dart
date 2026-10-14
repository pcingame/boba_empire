/// Dữ liệu công thức pha chế (assets/recipes/recipes.json, sinh bằng scripts/make_recipes.py từ
/// source.md) cho trò luyện nhớ công thức. Hàm thuần — không đụng Flutter.
library;

/// Nhóm công thức chơi được, THEO THỨ TỰ MỞ: nhóm đầu mở sẵn, mỗi nhóm sau mở khi người chơi đã thuộc đủ món của
/// nhóm ngay trước (xem [recipeGroupUnlocked]) — để mỗi buổi luyện tập trung vào một nhóm chứ không rải đều 100 món.
const List<int> recipePlayableGroups = [1, 2, 3, 4, 5];

/// Để mở nhóm kế: cần chừng này món của nhóm trước đã từng đạt bậc "Thuộc" trở lên (`best` ≥ [recipeGroupUnlockBox]).
const int recipeGroupUnlockLearned = 10;
const int recipeGroupUnlockBox = 2;

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

  /// Các món của nhóm [group] (theo thứ tự id).
  List<Recipe> inGroup(int group) => [for (final r in recipes) if (r.group == group) r];

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
    ('hoa hồng', '🌹'),
    ('việt quất', '🫐'),
    ('dưa hấu', '🍉'),
    ('kiwi', '🥝'),
    ('nho', '🍇'),
    ('mận', '🟣'),
    ('nhãn', '🟡'),
    ('vải', '🍒'),
    ('táo', '🍎'),
    ('ổi', '🍐'),
    ('lựu', '🔴'),
    ('tắc', '🍊'),
    ('sả', '🌾'),
    ('bột quế', '🪵'),
    ('gạo rang', '🍚'),
    ('mè đen', '🖤'),
    ('đậu đỏ', '🫘'),
    ('hạt phỉ', '🌰'),
    ('lòng đỏ', '🥚'),
    ('vanilla', '🌼'),
    ('tonic', '🫧'),
    ('soda', '🫧'),
    ('cold brew', '🧊'),
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
    ('nước', '💧'),
  ];
  for (final (k, e) in table) {
    if (n.contains(k)) return e;
  }
  return '🥤';
}

/// Số món của nhóm [group] đã từng đạt bậc [recipeGroupUnlockBox] trở lên (đếm theo `best` nên chỉ tăng).
/// [bestOf] trả về `best` của một món (0 nếu chưa luyện).
int recipeGroupLearned(RecipeCatalog catalog, int group, int Function(int recipeId) bestOf) =>
    catalog.inGroup(group).where((r) => bestOf(r.id) >= recipeGroupUnlockBox).length;

/// Nhóm đã mở chưa: nhóm đầu luôn mở; nhóm sau mở khi nhóm ngay trước có ≥ [recipeGroupUnlockLearned] món đã thuộc.
/// Vì đếm theo `best` (chỉ tăng) nên đã mở là mở mãi. Nhóm không nằm trong [recipePlayableGroups] không mở.
bool recipeGroupUnlocked(RecipeCatalog catalog, int group, int Function(int recipeId) bestOf) {
  final i = recipePlayableGroups.indexOf(group);
  if (i < 0) return false;
  if (i == 0) return true;
  return recipeGroupLearned(catalog, recipePlayableGroups[i - 1], bestOf) >= recipeGroupUnlockLearned;
}

/// Các món chơi được ngay bây giờ: thuộc các nhóm đã mở.
List<Recipe> unlockedRecipes(RecipeCatalog catalog, int Function(int recipeId) bestOf) => [
      for (final g in recipePlayableGroups)
        if (recipeGroupUnlocked(catalog, g, bestOf)) ...catalog.inGroup(g),
    ];
