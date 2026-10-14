import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/recipes.dart';

/// Danh mục công thức (đọc một lần từ assets/recipes/recipes.json). Test ghi đè bằng dữ liệu có sẵn.
final recipeCatalogProvider = FutureProvider<RecipeCatalog>((ref) async {
  final raw = await rootBundle.loadString('assets/recipes/recipes.json');
  return RecipeCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});

/// Nguồn ngẫu nhiên cho việc xáo câu hỏi; test ghi đè bằng Random có seed.
final recipeRandomProvider = Provider<Random>((ref) => Random());
