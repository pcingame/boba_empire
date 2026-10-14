// Bản dịch tên món/nguyên liệu/nhóm: đủ và khớp dữ liệu gốc ở cả 6 ngôn ngữ, không trùng, đúng chữ viết, có đường lui.
import 'dart:convert';
import 'dart:io';

import 'package:boba_empire/core/recipe_names.dart';
import 'package:boba_empire/core/recipes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = RecipeCatalog.fromJson(
      jsonDecode(File('assets/recipes/recipes.json').readAsStringSync()) as Map<String, dynamic>);
  final raw = jsonDecode(File('assets/recipes/names.json').readAsStringSync()) as Map<String, dynamic>;
  final names = RecipeNames.fromJson(raw);
  const langs = ['en', 'es', 'id', 'ko', 'pt', 'th'];
  final ingredients = {for (final r in catalog.recipes) for (final i in r.ingredients) i.name};

  test('có đủ 6 ngôn ngữ', () {
    expect(names.languages.toSet(), langs.toSet());
  });

  for (final lang in langs) {
    group('[$lang]', () {
      test('đủ MỌI món, nguyên liệu, nhóm của dữ liệu gốc — không thừa, không thiếu, không trống', () {
        final t = raw[lang] as Map<String, dynamic>;
        expect((t['recipes'] as Map).keys.toSet(), {for (final r in catalog.recipes) '${r.id}'});
        expect((t['ingredients'] as Map).keys.toSet(), ingredients);
        expect((t['groups'] as Map).keys.toSet(), {for (final g in catalog.groupNames.keys) '$g'});
        for (final table in ['recipes', 'ingredients', 'groups']) {
          for (final e in (t[table] as Map).entries) {
            expect((e.value as String).trim(), isNotEmpty, reason: '$lang/$table/${e.key}');
            expect(e.value, equals((e.value as String).trim()), reason: 'thừa khoảng trắng đầu/cuối: ${e.key}');
          }
        }
      });

      test('KHÔNG trùng nhau trong cùng ngôn ngữ (hai món/nguyên liệu khác nhau không được hiện cùng một nhãn)', () {
        for (final table in ['recipes', 'ingredients']) {
          final values = ((raw[lang] as Map)[table] as Map).values.cast<String>().toList();
          final seen = <String>{};
          final dup = [for (final v in values) if (!seen.add(v.toLowerCase())) v];
          expect(dup, isEmpty, reason: '$lang/$table trùng: $dup');
        }
      });

      test('đúng chữ viết của ngôn ngữ (không sót tiếng Việt / không toàn Latin ở ko, th)', () {
        final all = [
          for (final table in ['recipes', 'ingredients', 'groups']) ...((raw[lang] as Map)[table] as Map).values.cast<String>(),
        ];
        // Chữ chỉ có trong tiếng Việt (ơ ư ă đ và các dấu thanh trên nguyên âm).
        final viOnly = RegExp(r'[ơưăđƠƯĂĐạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ]');
        if (['en', 'es', 'id', 'pt'].contains(lang)) {
          for (final v in all) {
            expect(viOnly.hasMatch(v), isFalse, reason: '$lang: "$v" còn chữ tiếng Việt');
          }
        }
        if (lang == 'ko') {
          for (final v in all) {
            expect(RegExp(r'[가-힣]').hasMatch(v), isTrue, reason: 'ko: "$v" không có chữ Hàn');
          }
        }
        if (lang == 'th') {
          for (final v in all) {
            expect(RegExp(r'[฀-๿]').hasMatch(v), isTrue, reason: 'th: "$v" không có chữ Thái');
          }
        }
      });

      test('độ dài hợp lý để vừa thẻ (không có nhãn dài bất thường)', () {
        for (final table in ['recipes', 'ingredients', 'groups']) {
          for (final e in ((raw[lang] as Map)[table] as Map).entries) {
            expect((e.value as String).length, lessThanOrEqualTo(48), reason: '$lang/$table/${e.key} quá dài');
          }
        }
      });
    });
  }

  group('RecipeNames / RecipeLabels', () {
    final first = catalog.byId(1)!;

    test('tra theo ngôn ngữ; vi và ngôn ngữ lạ rơi về tên tiếng Việt', () {
      expect(names.recipe(first, 'en'), 'Black Milk Tea');
      expect(names.recipe(first, 'th'), 'ชานมชาดำ');
      expect(names.recipe(first, 'vi'), first.name);
      expect(names.recipe(first, 'fr'), first.name);
      expect(names.ingredient('Bột kem béo', 'ko'), '프림(크리머)');
      expect(names.ingredient('Bột kem béo', 'vi'), 'Bột kem béo');
      expect(names.ingredient('Nguyên liệu lạ', 'en'), 'Nguyên liệu lạ'); // mục mới chưa dịch
      expect(names.group(1, 'Trà sữa truyền thống', 'es'), 'Tés con leche clásicos');
      expect(names.group(99, 'Nhóm lạ', 'es'), 'Nhóm lạ');
    });

    test('RecipeLabels: chưa nạp bản dịch (null) thì toàn bộ là tiếng Việt', () {
      const l = RecipeLabels(null, 'en');
      expect(l.recipe(first), first.name);
      expect(l.ingredient('Matcha'), 'Matcha');
      expect(l.group(1, 'Trà sữa truyền thống'), 'Trà sữa truyền thống');
      expect(l.ingredientLine('Bột kem béo 30 g'), 'Bột kem béo 30 g');
    });

    test('ingredientLine: dịch tên, GIỮ NGUYÊN lượng và đơn vị (cả số lẻ, ml)', () {
      final l = RecipeLabels(names, 'en');
      expect(l.ingredientLine('Bột kem béo 30 g'), 'Non-dairy creamer 30 g');
      expect(l.ingredientLine('Nước nóng 200 ml'), 'Hot water 200 ml');
      expect(l.ingredientLine('Bột quế 1 g'), 'Cinnamon powder 1 g');
      expect(l.ingredientLine('Hồng trà khô 12.5 g'), 'Dry black tea 12.5 g');
      expect(l.ingredientLine('Matcha'), 'Matcha'); // dòng không có lượng: chỉ dịch tên
    });

    test('mọi dòng của mọi công thức đều dịch được ở mọi ngôn ngữ và giữ đúng lượng', () {
      for (final lang in langs) {
        final l = RecipeLabels(names, lang);
        for (final r in catalog.recipes) {
          for (final i in r.ingredients) {
            final out = l.ingredientLine(i.label);
            expect(out.endsWith(i.amount), isTrue, reason: '$lang: "$out" mất lượng "${i.amount}"');
            expect(out.startsWith(l.ingredient(i.name)), isTrue);
          }
        }
      }
    });
  });
}
