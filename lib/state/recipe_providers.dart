import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/widgets.dart';

import '../core/recipe_names.dart';
import '../core/recipes.dart';

/// Danh mục công thức (đọc một lần từ assets/recipes/recipes.json). Test ghi đè bằng dữ liệu có sẵn.
final recipeCatalogProvider = FutureProvider<RecipeCatalog>((ref) async {
  final raw = await rootBundle.loadString('assets/recipes/recipes.json');
  return RecipeCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});

/// Nguồn ngẫu nhiên cho việc xáo câu hỏi; test ghi đè bằng Random có seed.
final recipeRandomProvider = Provider<Random>((ref) => Random());

/// Bản dịch tên món/nguyên liệu/nhóm (đọc một lần từ assets/recipes/names.json). Lỗi nạp → null (UI rơi về tiếng Việt).
final recipeNamesProvider = FutureProvider<RecipeNames?>((ref) async {
  try {
    return RecipeNames.fromJson(jsonDecode(await rootBundle.loadString('assets/recipes/names.json')) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});

/// Nhãn theo ngôn ngữ hiện tại của [context]; tự cập nhật khi bản dịch nạp xong.
RecipeLabels recipeLabelsOf(WidgetRef ref, BuildContext context) =>
    RecipeLabels(ref.watch(recipeNamesProvider).value, Localizations.localeOf(context).languageCode);
