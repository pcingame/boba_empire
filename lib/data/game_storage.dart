/// Lưu/đọc [GameState] dưới dạng MỘT blob JSON qua shared_preferences.
///
/// Idle game chỉ cần persist một object trạng thái, không cần schema NoSQL —
/// `setString` của shared_preferences đã ghi thay-thế nguyên khóa (atomic ở
/// tầng nền), nên không cần ghi file tạm rồi rename.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/models.dart';

class GameStorage {
  GameStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'game_state';

  /// Phiên bản schema — để sau này migrate save cũ khi model đổi.
  static const int _schemaVersion = 1;

  /// Ghi trạng thái xuống đĩa.
  ///
  /// Đóng dấu [GameState.lastSeenMillis] = thời điểm lưu: lúc online mọi khoản
  /// thu nhập đã được cộng tới hiện tại, nên đây là mốc "đã tính tiền tới đây".
  /// Khi mở lại app, [applyOfflineEarnings] dùng mốc này để tính khoảng vắng.
  /// [nowMillis] cho phép test bơm thời gian cố định.
  Future<void> save(GameState state, {int? nowMillis}) async {
    state.lastSeenMillis = nowMillis ?? DateTime.now().millisecondsSinceEpoch;
    final payload = <String, dynamic>{
      'version': _schemaVersion,
      'state': state.toJson(),
    };
    await _prefs.setString(_key, jsonEncode(payload));
  }

  /// Đọc trạng thái đã lưu, hoặc null nếu chưa có / save hỏng.
  ///
  /// Save hỏng (JSON lỗi, thiếu trường) trả về null thay vì ném lỗi, để game
  /// khởi động lại như ván mới thay vì crash ngay màn hình đầu.
  GameState? load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final state = payload['state'] as Map<String, dynamic>;
      return GameState.fromJson(state);
    } catch (_) {
      return null;
    }
  }

  /// Xóa save (dùng cho nút "chơi lại từ đầu" / debug).
  Future<void> clear() => _prefs.remove(_key);

  // --- Bookkeeping đồng bộ cloud (2026-09-12) ---
  //
  // CỐ Ý tách riêng khỏi save chính ([GameState]/[_key] ở trên): đây là
  // trạng thái ĐỒNG BỘ cục bộ của THIẾT BỊ này (mốc version cloud gần nhất
  // đã xác nhận khớp, có đang chờ xử lý xung đột hay không) — không phải
  // dữ liệu ván chơi. Gộp chung vào GameState sẽ khiến giá trị này bị đẩy
  // theo mỗi lần push/pull save lên/từ cloud (vòng lặp vô nghĩa, dễ nhầm
  // "version của máy A" thành "version của máy B" khi khôi phục). Xem
  // CloudSaveRepository.pushIfCurrent() / known-issues-backlog memory mục 7.

  static const _cloudVersionKey = 'cloud_sync_version';
  static const _cloudConflictKey = 'cloud_sync_conflict_pending';

  /// Version cloud gần nhất máy này xác nhận khớp (0 = chưa từng đồng bộ).
  int loadCloudVersion() => _prefs.getInt(_cloudVersionKey) ?? 0;

  Future<void> saveCloudVersion(int version) =>
      _prefs.setInt(_cloudVersionKey, version);

  /// True nếu lần đẩy save nền gần nhất phát hiện version cloud đã đổi (máy
  /// khác vừa lưu) mà chưa được người chơi xử lý (khôi phục / giữ máy này).
  bool loadCloudConflictPending() => _prefs.getBool(_cloudConflictKey) ?? false;

  Future<void> saveCloudConflictPending(bool value) =>
      _prefs.setBool(_cloudConflictKey, value);
}
