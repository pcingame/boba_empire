// Hình ảnh Pha theo đơn: màu nguyên liệu ổn định + phân biệt được, ly vẽ không lỗi với mọi lớp.
import 'dart:convert';
import 'dart:io';

import 'package:boba_empire/core/recipes.dart';
import 'package:boba_empire/ui/widgets/order_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = RecipeCatalog.fromJson(
      jsonDecode(File('assets/recipes/recipes.json').readAsStringSync()) as Map<String, dynamic>);

  test('ingredientColor: ổn định, khớp từ khoá cụ thể trước, mọi nguyên liệu đều có màu', () {
    expect(ingredientColor('Sữa tươi'), ingredientColor('Sữa tươi'));
    expect(ingredientColor('Sữa đặc'), isNot(ingredientColor('Trân châu đen')));
    // "sữa hạnh nhân" phải thắng "sữa" chung.
    expect(ingredientColor('Sữa hạnh nhân'), isNot(ingredientColor('Sữa tươi')));
    // Không khớp từ khoá: màu sinh từ tên, vẫn ổn định.
    expect(ingredientColor('Xyz lạ'), ingredientColor('Xyz lạ'));
    final colors = {for (final r in catalog.recipes) for (final i in r.ingredients) i.name: ingredientColor(i.name)};
    expect(colors.length, greaterThan(80));
    expect(colors.values.toSet().length, greaterThan(30), reason: 'màu phải đủ đa dạng để phân biệt lớp');
  });

  testWidgets('OrderCup: vẽ được ly rỗng, nhiều lớp, tổng vượt 100% (co lại), nắp + lắc; đổi lớp không ném', (tester) async {
    Future<void> show(List<CupLayer> l, {bool lid = false, bool shake = false}) => tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: OrderCup(layers: l, lidded: lid, shaking: shake)))));
    await show(const []);
    expect(find.byKey(const Key('order-cup-paint')), findsOneWidget);
    await show([CupLayer(Colors.brown, 0.3), CupLayer(Colors.white, 0.2)]);
    await tester.pump(const Duration(milliseconds: 400));
    await show([CupLayer(Colors.brown, 0.9), CupLayer(Colors.white, 0.9), CupLayer(Colors.red, 0.9)], lid: true);
    await tester.pump(const Duration(milliseconds: 400));
    await show([CupLayer(Colors.brown, 0.5)], lid: true, shake: true);
    await tester.pump(const Duration(milliseconds: 300));
    await show(const [], lid: false, shake: false);
    expect(tester.takeException(), isNull);
  });
}
