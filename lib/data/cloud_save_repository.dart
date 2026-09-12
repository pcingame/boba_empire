/// Lớp nói chuyện trực tiếp với Supabase cho "Đồng bộ đám mây" (cloud save
/// qua email OTP) — xem PROPOSAL_CLOUD_SAVE.md và `supabase/cloud_save_schema.sql`.
///
/// Độc lập với `arena/arena_repository.dart` — dùng chung `SupabaseClient`
/// (đã init ở `main.dart`) nhưng khác bảng, khác luồng auth, không phụ thuộc
/// nhau. Người chơi chưa từng đăng nhập ẩn danh (Đấu Trường) vẫn dùng được
/// cloud save bình thường: `signInWithOtp` tự tạo tài khoản permanent mới.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

class CloudSaveResult {
  const CloudSaveResult({
    required this.data,
    required this.updatedAt,
    required this.version,
  });
  final Map<String, dynamic> data;
  final DateTime updatedAt;

  /// Mốc đồng bộ lạc quan (optimistic concurrency) — xem [pushIfCurrent].
  final int version;
}

class CloudSaveRepository {
  CloudSaveRepository(this._client);

  final SupabaseClient _client;

  /// Đã đăng nhập bằng tài khoản THẬT (không phải phiên ẩn danh của Đấu
  /// Trường) — chỉ tài khoản này mới coi là "đã liên kết cloud save".
  bool get isLinked {
    final user = _client.auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  String? get linkedEmail => isLinked ? _client.auth.currentUser?.email : null;

  /// Gửi mã xác nhận tới [email] (độ dài do Supabase quyết định, đã gặp cả
  /// 8 số thực tế — đừng giả định cố định 6 số). Ném lỗi nếu Supabase từ chối (VD gửi quá
  /// nhanh liên tiếp — server tự giới hạn, không cần tự làm cooldown ở đây).
  Future<void> sendCode(String email) => _client.auth.signInWithOtp(email: email);

  /// Xác nhận mã — thành công thì phiên hiện tại (kể cả đang ẩn danh) chuyển
  /// thành tài khoản permanent gắn với [email].
  Future<void> verifyCode(String email, String code) => _client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.email,
      );

  Future<void> signOut() => _client.auth.signOut();

  /// Đẩy save hiện tại lên cloud KHÔNG ĐIỀU KIỆN — GHI ĐÈ bất kể version
  /// hiện tại trên server là gì. Chỉ dùng cho 2 trường hợp người chơi đã
  /// CHỦ ĐỘNG chọn ghi đè: lần liên kết đầu tiên (chưa có gì để xung đột),
  /// và bấm "Giữ máy này" ở dialog xung đột (đồng ý ghi đè). Mọi lần lưu
  /// nền tự động khác PHẢI dùng [pushIfCurrent] — xem đó để biết lý do.
  ///
  /// Trả về version mới sau khi ghi (server tự tăng) — gọi
  /// [GameController.applyCloudSyncVersion] với giá trị này để lần lưu nền
  /// kế tiếp biết đúng mốc mà so sánh.
  Future<int> push(Map<String, dynamic> saveJson) async {
    if (!isLinked) return 0;
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from('player_saves')
        .upsert({'user_id': uid, 'data': saveJson}).select();
    return (rows.first['version'] as num).toInt();
  }

  /// Đẩy save lên cloud CHỈ KHI version trên server vẫn đúng bằng
  /// [expectedVersion] — optimistic concurrency, chống ghi đè mù. Dùng cho
  /// MỌI lần lưu nền tự động ([GameController.saveNow]): nếu máy khác đã
  /// đẩy save của họ lên sau lần đồng bộ gần nhất của máy này, version trên
  /// server đã tăng lên khác — client này KHÔNG được phép âm thầm ghi đè
  /// tiến trình của máy kia.
  ///
  /// Trả về version mới nếu ghi thành công; `null` nếu version không khớp
  /// (xung đột — có save mới hơn từ máy khác chưa được xử lý) HOẶC nếu
  /// chưa liên kết. Gọi không ném lỗi cho trường hợp xung đột — đây là kết
  /// quả BÌNH THƯỜNG cần xử lý, không phải lỗi mạng/hệ thống.
  Future<int?> pushIfCurrent(
    Map<String, dynamic> saveJson,
    int expectedVersion,
  ) async {
    if (!isLinked) return null;
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from('player_saves')
        .update({'data': saveJson})
        .eq('user_id', uid)
        .eq('version', expectedVersion)
        .select();
    if (rows.isEmpty) return null;
    return (rows.first['version'] as num).toInt();
  }

  /// Đọc save trên cloud của tài khoản đang đăng nhập — null nếu tài khoản
  /// này chưa từng push lần nào (mới liên kết lần đầu).
  Future<CloudSaveResult?> pull() async {
    if (!isLinked) return null;
    final uid = _client.auth.currentUser!.id;
    final row = await _client
        .from('player_saves')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return null;
    return CloudSaveResult(
      data: row['data'] as Map<String, dynamic>,
      updatedAt: DateTime.parse(row['updated_at'] as String),
      version: (row['version'] as num).toInt(),
    );
  }
}
