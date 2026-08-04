import 'package:boba_empire/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dưới 1000 hiển thị nguyên', () {
    expect(formatNumber(0), '0');
    expect(formatNumber(7), '7');
    expect(formatNumber(950), '950');
  });

  test('hậu tố K/M/B/T', () {
    expect(formatNumber(1500), '1.50K');
    expect(formatNumber(2.5e6), '2.50M');
    expect(formatNumber(3e9), '3.00B');
    expect(formatNumber(1.234e12), '1.23T');
  });

  test('vượt T dùng hậu tố kép', () {
    expect(formatNumber(1e15), '1.00aa');
  });

  test('số âm giữ dấu', () {
    expect(formatNumber(-2500), '-2.50K');
  });
}
