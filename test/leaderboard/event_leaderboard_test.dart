// BXH Sự kiện: điểm tính được, đọc hàng RPC, và SQL phải khớp lịch dịp lễ Dart.
// Đường mạng (submit/fetch) không test được — repo không có mock SupabaseClient.
import 'dart:io';

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/event_quests.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/leaderboard/event_leaderboard_repository.dart';
import 'package:flutter_test/flutter_test.dart';

String _ts(DateTime d) {
  String p(int n) => n.toString().padLeft(2, '0');
  return "timestamptz '${d.year}-${p(d.month)}-${p(d.day)} "
      "${p(d.hour)}:${p(d.minute)}:${p(d.second)}+00'";
}

void main() {
  group('eventScore', () {
    test('chạm + 50 x (mèo + VIP); KHÔNG tính nâng cấp', () {
      final s = GameState.newGame(nowMillis: 0);
      expect(eventScore(s), 0);
      s.eventProgress
        ..['tap'] = 100
        ..['cat'] = 2
        ..['vip'] = 3
        ..['buy'] = 99999;
      expect(eventScore(s), 100 + 50 * 5);
    });

    test('số hỏng (NaN/Infinity) -> 0, không ném lỗi', () {
      expect(eventScoreOf({'tap': double.infinity}), 0);
      expect(eventScoreOf({'tap': double.nan}), 0);
    });

    test('mirror từ nhiệm vụ ngày + reset khi sang dịp: điểm về 0', () {
      final s = GameState.newGame(nowMillis: 0);
      rollEvent(s, DateTime.utc(2026, 10, 25));
      s.eventProgress['tap'] = 500;
      expect(eventScore(s), 500);
      rollEvent(s, DateTime.utc(2026, 12, 20)); // sang Giáng Sinh
      expect(eventScore(s), 0);
    });
  });

  test('đọc một hàng từ RPC', () {
    final e = EventLeaderboardEntry.fromRow(const {
      'user_id': 'abc',
      'nickname': 'Phương',
      'score': 1234,
      'rank': 2,
    });
    expect((e.userId, e.nickname, e.score, e.rank), ('abc', 'Phương', 1234, 2));
  });

  group('SQL khớp Dart', () {
    final sql =
        File('supabase/event_leaderboard_schema.sql').readAsStringSync();

    test('mọi dịp lễ có đúng cửa sổ [start, end) trong event_leaderboard_window',
        () {
      for (final f in festivals) {
        final row = RegExp("\\('${f.id}',\\s*(timestamptz '[^']+'),\\s*"
                "(timestamptz '[^']+')\\)")
            .firstMatch(sql);
        expect(row, isNotNull, reason: 'thiếu ${f.id} trong SQL');
        expect(row!.group(1), _ts(f.start), reason: '${f.id} start');
        expect(row.group(2), _ts(f.end), reason: '${f.id} end');
      }
    });

    test('SQL không có dịp thừa mà Dart không có', () {
      final ids = RegExp(r"\('([a-z_]+)',\s*timestamptz")
          .allMatches(sql)
          .map((m) => m.group(1))
          .toSet();
      expect(ids, festivals.map((f) => f.id).toSet());
    });

    test('client không ghi thẳng vào bảng: không có policy insert/update', () {
      expect(sql.contains('for insert'), isFalse);
      expect(sql.contains('for update'), isFalse);
      expect(sql.contains('security definer'), isTrue);
    });

    test('trần tốc độ/giờ của server cho phép người chơi thật nhưng chặn bot',
        () {
      final cap =
          int.parse(RegExp(r'select (\d+) \$\$').firstMatch(sql)!.group(1)!);
      // Người thật: ~10 chạm/giây liên tục = 36.000/giờ (+ mèo/VIP) -> phải lọt.
      expect(cap, greaterThan(36000 + 5000));
      // Auto-click 50/giây = 180.000/giờ -> phải bị chặn.
      expect(cap, lessThan(180000));
    });
  });
}
