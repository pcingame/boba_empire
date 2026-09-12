/// Định dạng số lớn kiểu game idle: 1234 -> "1.23K", 5.6e9 -> "5.60B".
///
/// Dùng `double` (mục 10). Sau mốc T (10^12) chuyển sang hậu tố kép aa, bb...
library;

const List<String> _suffixes = [
  '', 'K', 'M', 'B', 'T', //
  'aa', 'bb', 'cc', 'dd', 'ee', 'ff', 'gg', 'hh', 'ii', 'jj',
];

/// Ví dụ: 0 -> "0", 950 -> "950", 1500 -> "1.50K", 2.5e6 -> "2.50M".
///
/// [decimals] chỉnh số lẻ sau hậu tố (mặc định 2); dùng để rút gọn chuỗi cho
/// chỗ hiển thị chật (VD huy hiệu góc icon — xem `_CountBadge` trong
/// home_page.dart).
String formatNumber(double value, {int decimals = 2}) {
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
  final s = '${n.toStringAsFixed(decimals)}${_suffixes[tier]}';
  return negative ? '-$s' : s;
}

/// Thời lượng dạng gọn "3d 5h", "5h 20m", "20m 5s" — dùng cho bảng xếp hạng
/// tốc độ hoàn thành cốt truyện. Chữ viết tắt d/h/m/s KHÔNG dịch theo ngôn
/// ngữ, giống hậu tố K/M/B/T ở [formatNumber] — quy ước đã có trong game.
String formatDuration(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  final days = s ~/ 86400;
  final hours = (s % 86400) ~/ 3600;
  final minutes = (s % 3600) ~/ 60;
  final seconds = s % 60;
  if (days > 0) return '${days}d ${hours}h';
  if (hours > 0) return '${hours}h ${minutes}m';
  if (minutes > 0) return '${minutes}m ${seconds}s';
  return '${seconds}s';
}
