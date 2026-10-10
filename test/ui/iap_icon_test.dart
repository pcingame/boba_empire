import 'package:boba_empire/iap/iap_products.dart';
import 'package:boba_empire/ui/widgets/iap_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mọi gói IAP có hình riêng (emoji + dải màu); gói gần giống nhau vẫn khác nhau', () {
    final seen = <String>{};
    for (final p in IapProduct.values) {
      final a = iapArt(p);
      expect(a.emoji, isNotEmpty, reason: p.id);
      expect(a.colors.length, greaterThanOrEqualTo(2), reason: p.id);
      // Gỡ QC và Combo cùng emoji 🚫 nhưng phải khác màu/nhãn để không nhầm.
      seen.add('${a.emoji}|${a.colors.first.toARGB32()}|${a.badge}');
    }
    expect(seen.length, IapProduct.values.length);
  });

  testWidgets('IapIcon dựng đủ mọi gói, kể cả khi chữ phóng to, không tràn', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
          body: Wrap(children: [
            for (final p in IapProduct.values) IapIcon(product: p),
          ]),
        ),
      ),
    ));
    for (final p in IapProduct.values) {
      expect(find.byKey(Key('iap-icon-${p.id}')), findsOneWidget, reason: p.id);
    }
    expect(find.text('×2'), findsNWidgets(2)); // x2 thu nhập + combo
    expect(tester.takeException(), isNull);
  });
}
