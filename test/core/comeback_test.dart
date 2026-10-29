import 'package:boba_empire/core/comeback.dart';
import 'package:boba_empire/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

const _day = 24 * 60 * 60 * 1000;
final _now = DateTime.utc(2026, 10, 29).millisecondsSinceEpoch;

void main() {
  test('bậc quà theo số ngày vắng; chưa đủ 3 ngày hoặc đồng hồ lùi = 0', () {
    expect(comebackGems(3 * _day - 1), 0);
    expect(comebackGems(-5 * _day), 0);
    expect(comebackGems(3 * _day), 50);
    expect(comebackGems(7 * _day), 100);
    expect(comebackGems(14 * _day), 200);
    expect(comebackGems(400 * _day), 200);
  });

  test('trao quà một lần rồi chờ 7 ngày mới nhận lại', () {
    final s = GameState.newGame(nowMillis: _now)
      ..gems = 10
      ..lifetimeEarnings = 1;
    expect(claimComeback(s, _now, 1 * _day), 0);
    expect(claimComeback(s, _now, 5 * _day), 50);
    expect(s.gems, 60);
    expect(claimComeback(s, _now + 1000, 20 * _day), 0, reason: 'còn trong thời gian chờ');
    expect(claimComeback(s, _now + 7 * _day, 20 * _day), 200);
    expect(s.gems, 260);
  });

  test('save chưa kiếm được Xu nào (người mới) không có quà', () {
    final s = GameState.newGame(nowMillis: _now);
    expect(claimComeback(s, _now, 30 * _day), 0);
    expect(s.gems, 0);
  });

  test('lưu/đọc giữ mốc; save cũ thiếu trường = 0', () {
    final s = GameState.newGame(nowMillis: _now)..lastComebackMillis = 123;
    expect(GameState.fromJson(s.toJson()).lastComebackMillis, 123);
    final old = s.toJson()..remove('lastComebackMillis');
    expect(GameState.fromJson(old).lastComebackMillis, 0);
  });
}
