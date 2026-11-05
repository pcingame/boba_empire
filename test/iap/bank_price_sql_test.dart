import 'dart:io';

import 'package:boba_empire/iap/bank_config.dart';
import 'package:boba_empire/iap/iap_products.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bankPriceVnd khớp bảng bank_prices trong SQL và phủ mọi sản phẩm IAP', () {
    final sql = File('supabase/bank_orders_schema.sql').readAsStringSync();
    final sqlPrices = {
      for (final m in RegExp(r"\('(boba_\w+)', (\d+)\)").allMatches(sql))
        m[1]!: int.parse(m[2]!),
    };
    expect(bankPriceVnd, sqlPrices);
    expect(bankPriceVnd.keys.toSet(), IapProduct.values.map((p) => p.id).toSet());
  });

  test('formatVnd chèn dấu chấm hàng nghìn', () {
    expect(formatVnd(100000), '100.000đ');
    expect(formatVnd(20000), '20.000đ');
  });
}
