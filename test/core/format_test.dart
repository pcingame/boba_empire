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

  group('formatDuration', () {
    test('dưới 1 phút -> giây', () {
      expect(formatDuration(0), '0s');
      expect(formatDuration(45), '45s');
    });

    test('dưới 1 giờ -> phút + giây lẻ', () {
      expect(formatDuration(60), '1m 0s');
      expect(formatDuration(125), '2m 5s');
    });

    test('dưới 1 ngày -> giờ + phút lẻ', () {
      expect(formatDuration(3600), '1h 0m');
      expect(formatDuration(3660 + 300), '1h 6m');
    });

    test('từ 1 ngày trở lên -> ngày + giờ lẻ', () {
      expect(formatDuration(86400), '1d 0h');
      expect(formatDuration(86400 * 3 + 3600 * 5), '3d 5h');
    });

    test('số âm coi như 0 (không hiển thị thời lượng âm)', () {
      expect(formatDuration(-10), '0s');
    });
  });
}
