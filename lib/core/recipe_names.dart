/// Tên món / nguyên liệu / nhóm theo ngôn ngữ (assets/recipes/names.json, sinh bằng scripts/make_recipe_names.py).
/// Dữ liệu gốc (recipes.json) là tiếng Việt và là KHOÁ để so khớp/ra đề; bản dịch chỉ dùng để HIỂN THỊ. Thiếu bản
/// dịch (ngôn ngữ lạ, mục mới chưa dịch) thì rơi về tên tiếng Việt, không bao giờ để trống.
library;

import 'recipes.dart';

class RecipeNames {
  RecipeNames(this._byLang);

  factory RecipeNames.fromJson(Map<String, dynamic> j) => RecipeNames({
        for (final e in j.entries)
          e.key: {
            for (final t in (e.value as Map<String, dynamic>).entries)
              t.key: {for (final x in (t.value as Map<String, dynamic>).entries) x.key: x.value as String},
          },
      });

  /// lang → bảng ('groups' | 'recipes' | 'ingredients') → khoá → tên.
  final Map<String, Map<String, Map<String, String>>> _byLang;

  /// Các ngôn ngữ có bản dịch.
  Iterable<String> get languages => _byLang.keys;

  String? _get(String lang, String table, String key) => _byLang[lang]?[table]?[key];

  String recipe(Recipe r, String lang) => _get(lang, 'recipes', '${r.id}') ?? r.name;

  /// [viName] là tên tiếng Việt của nguyên liệu (khoá).
  String ingredient(String viName, String lang) => _get(lang, 'ingredients', viName) ?? viName;

  String group(int id, String viName, String lang) => _get(lang, 'groups', '$id') ?? viName;
}

/// Bộ nhãn đã gắn sẵn ngôn ngữ — UI cầm cái này thay vì cầm cả [RecipeNames] + mã ngôn ngữ. [names] null (đang
/// nạp / lỗi nạp) thì mọi hàm trả tên tiếng Việt.
class RecipeLabels {
  const RecipeLabels(this.names, this.lang);

  final RecipeNames? names;
  final String lang;

  String recipe(Recipe r) => names?.recipe(r, lang) ?? r.name;
  String ingredient(String viName) => names?.ingredient(viName, lang) ?? viName;
  String group(int id, String viName) => names?.group(id, viName, lang) ?? viName;

  /// Một dòng công thức "Tên nguyên liệu 10 g" (tên tiếng Việt) → cùng dòng với tên đã dịch, lượng giữ nguyên.
  String ingredientLine(String viLine) {
    final m = RegExp(r'^(.*?)\s+(\d+(?:\.\d+)?\s*(?:g|ml))$').firstMatch(viLine);
    return m == null ? ingredient(viLine) : '${ingredient(m.group(1)!)} ${m.group(2)}';
  }
}
