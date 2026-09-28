// Bảng xếp hạng Trân Châu Rơi: phần tính được và phần đọc dữ liệu về.
// Đường mạng (submit/fetch) không test được — repo này không có mock
// SupabaseClient, giống mọi tính năng Supabase khác.
import 'package:boba_empire/core/match3_levels.dart';
import 'package:boba_empire/leaderboard/m3_leaderboard_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tiến độ đem đi xếp hạng', () {
    test('tổng sao và số màn đã qua', () {
      expect(m3TotalStars(const []), 0);
      expect(m3LevelsCleared(const []), 0);
      expect(m3TotalStars(const [3, 2, 0, 1]), 6);
      expect(m3LevelsCleared(const [3, 2, 0, 1]), 3,
          reason: 'màn 0 sao không tính');
    });

    test('BẤT BIẾN mà SQL dựa vào: tổng sao <= 3 x số màn đã qua', () {
      // `m3_stars_le_3x_levels` trong m3_leaderboard_schema.sql chặn kiểu gian
      // lận "1 màn, 900 sao". Client gửi số vi phạm thì insert bị từ chối và
      // người chơi THẬT không lên bảng được — nên phải đúng ngay từ đây.
      for (final data in [
        const <int>[],
        const [1],
        const [3, 3, 3],
        const [0, 0, 0],
        const [3, 0, 2, 0, 1],
      ]) {
        expect(m3TotalStars(data), lessThanOrEqualTo(m3LevelsCleared(data) * 3),
            reason: '$data');
      }
      final full = List<int>.filled(60, 3);
      expect(m3TotalStars(full), 180);
      expect(m3TotalStars(full), lessThanOrEqualTo(m3LevelsCleared(full) * 3));
    });
  });

  test('đọc một hàng từ RPC', () {
    final e = M3LeaderboardEntry.fromRow(const {
      'user_id': 'abc',
      'nickname': 'Phương',
      'stars': 42,
      'levels_cleared': 17,
      'rank': 3,
    });
    expect(e.userId, 'abc');
    expect(e.nickname, 'Phương');
    expect(e.stars, 42);
    expect(e.levelsCleared, 17);
    expect(e.rank, 3);
  });
}
