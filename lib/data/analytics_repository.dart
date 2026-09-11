/// Ghi sự kiện chơi game NHẸ (không PII) lên Supabase — để có dữ liệu chơi
/// thật (thời lượng session, phễu tiến trình theo giai đoạn, tần suất
/// prestige) trước khi tune lại balance, thay vì đoán tiếp (xem
/// PROPOSAL_ANALYTICS.md, GAME_DESIGN.md §15 "cần playtest").
///
/// Cố tình KHÔNG dùng auth (khác Arena/cloud save) — ghi bằng `device_id`
/// sinh cục bộ (random, lưu SharedPreferences), để không buộc MỌI người
/// chơi phải có mạng/đăng nhập chỉ để mở app — phá vỡ đúng thứ game đang
/// làm tốt (chơi offline được). Bù lại: best-effort tuyệt đối, lỗi mạng/
/// Supabase KHÔNG BAO GIỜ được phép ảnh hưởng gameplay.
library;

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._client, this._prefs);

  final SupabaseClient _client;
  final SharedPreferences _prefs;

  static const _deviceIdKey = 'analytics_device_id';

  /// Id ẩn danh ổn định theo máy — KHÔNG phải Supabase auth user, chỉ để
  /// nhóm sự kiện cùng 1 máy lại với nhau (VD tính thời lượng session).
  String get _deviceId {
    final existing = _prefs.getString(_deviceIdKey);
    if (existing != null) return existing;
    final id = _generateId();
    unawaited(_prefs.setString(_deviceIdKey, id));
    return id;
  }

  static String _generateId() {
    final rand = Random.secure();
    return List.generate(32, (_) => rand.nextInt(16).toRadixString(16)).join();
  }

  /// Ghi 1 sự kiện. Không throw ra ngoài — lỗi bị nuốt (log nội bộ) đúng
  /// tinh thần "không bao giờ được phép ảnh hưởng gameplay" ở trên.
  Future<void> log(String event, [Map<String, dynamic> props = const {}]) async {
    try {
      await _client.from('analytics_events').insert({
        'device_id': _deviceId,
        'event': event,
        'props': props,
      });
    } catch (e) {
      developer.log('analytics log lỗi (bỏ qua): $e', name: 'Analytics');
    }
  }
}
