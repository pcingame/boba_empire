// Lời nhắc liên kết email: quyết định + trạng thái lưu.
import 'package:boba_empire/core/cloud_remind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;

bool _due({
  bool linked = false,
  int opens = 3,
  int count = 0,
  int last = 0,
  int now = 10 * _day,
}) =>
    cloudRemindDue(
        linked: linked,
        opens: opens,
        shownCount: count,
        lastShownMs: last,
        nowMs: now);

void main() {
  group('cloudRemindDue', () {
    test('đã liên kết → không bao giờ nhắc', () {
      expect(_due(linked: true), isFalse);
      expect(_due(linked: true, opens: 100), isFalse);
    });

    test('chưa đủ 3 lần mở → chưa nhắc (không làm phiền người mới)', () {
      expect(_due(opens: 1), isFalse);
      expect(_due(opens: 2), isFalse);
      expect(_due(opens: 3), isTrue);
    });

    test('đã nhắc rồi: phải cách đủ 3 ngày, đúng biên', () {
      const last = 5 * _day;
      expect(_due(last: last, now: last + 3 * _day - 1), isFalse);
      expect(_due(last: last, now: last + 3 * _day), isTrue);
    });

    test('tối đa 5 lần rồi thôi', () {
      expect(_due(count: 4, last: 1), isTrue);
      expect(_due(count: 5, last: 1), isFalse);
      expect(_due(count: 99, last: 1), isFalse);
    });

    test('đồng hồ máy bị lùi → không nhắc dồn', () {
      expect(_due(last: 9 * _day, now: 2 * _day), isFalse);
    });
  });

  group('takeCloudRemindTurn (qua SharedPreferences)', () {
    Future<SharedPreferences> prefs() async {
      SharedPreferences.setMockInitialValues({});
      return SharedPreferences.getInstance();
    }

    test('chuỗi lần mở: 1,2 im lặng, 3 nhắc, 4 (cùng ngày) im, sau 3 ngày nhắc lại',
        () async {
      final p = await prefs();
      var now = 100 * _day;
      bool turn() => takeCloudRemindTurn(p, linked: false, nowMs: now);
      expect(turn(), isFalse); // mở lần 1
      expect(turn(), isFalse); // 2
      expect(turn(), isTrue); // 3 → nhắc
      expect(p.getInt(cloudRemindCountKey), 1);
      expect(turn(), isFalse); // 4, cùng ngày
      now += 2 * _day;
      expect(turn(), isFalse); // mới 2 ngày
      now += _day;
      expect(turn(), isTrue); // đủ 3 ngày kể từ lần nhắc
      expect(p.getInt(cloudRemindCountKey), 2);
    });

    test('đúng 5 lần nhắc rồi dừng vĩnh viễn dù mở bao nhiêu lần', () async {
      final p = await prefs();
      var now = 100 * _day;
      var shown = 0;
      for (var i = 0; i < 60; i++) {
        if (takeCloudRemindTurn(p, linked: false, nowMs: now)) shown++;
        now += 4 * _day;
      }
      expect(shown, cloudRemindMaxTimes);
    });

    test('người đã liên kết: không nhắc và không tốn lượt nhắc', () async {
      final p = await prefs();
      for (var i = 0; i < 10; i++) {
        expect(takeCloudRemindTurn(p, linked: true, nowMs: 100 * _day), isFalse);
      }
      expect(p.getInt(cloudRemindCountKey) ?? 0, 0);
      // Sau này gỡ liên kết → nhắc được ngay vì đã đủ lượt mở.
      expect(takeCloudRemindTurn(p, linked: false, nowMs: 100 * _day), isTrue);
    });

    test('trạng thái sống sót qua khởi động lại app (cùng prefs)', () async {
      final p = await prefs();
      for (var i = 0; i < 3; i++) {
        takeCloudRemindTurn(p, linked: false, nowMs: 100 * _day);
      }
      expect(p.getInt(cloudRemindOpensKey), 3);
      expect(p.getInt(cloudRemindLastKey), 100 * _day);
    });
  });
}
