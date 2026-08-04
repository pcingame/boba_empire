/// Định dạng số lớn kiểu game idle: 1234 -> "1.23K", 5.6e9 -> "5.60B".
///
/// Dùng `double` (mục 10). Sau mốc T (10^12) chuyển sang hậu tố kép aa, bb...
library;

const List<String> _suffixes = [
  '', 'K', 'M', 'B', 'T', //
  'aa', 'bb', 'cc', 'dd', 'ee', 'ff', 'gg', 'hh', 'ii', 'jj',
];

/// Ví dụ: 0 -> "0", 950 -> "950", 1500 -> "1.50K", 2.5e6 -> "2.50M".
String formatNumber(double value) {
  if (value.isNaN || value.isInfinite) return '0';
  final negative = value < 0;
  var n = value.abs();
  if (n < 1000) {
    final s = n < 10 ? n.toStringAsFixed(n == n.roundToDouble() ? 0 : 1)
                     : n.toStringAsFixed(0);
    return negative ? '-$s' : s;
  }
  var tier = 0;
  while (n >= 1000 && tier < _suffixes.length - 1) {
    n /= 1000;
    tier++;
  }
  final s = '${n.toStringAsFixed(2)}${_suffixes[tier]}';
  return negative ? '-$s' : s;
}
