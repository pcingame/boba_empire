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
  const CloudSaveResult({required this.data, required this.updatedAt});
  final Map<String, dynamic> data;
  final DateTime updatedAt;
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

  /// Gửi mã 6 số tới [email]. Ném lỗi nếu Supabase từ chối (VD gửi quá
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

  /// Đẩy save hiện tại lên cloud. No-op nếu chưa liên kết (tránh ghi rác vào
  /// bảng khi mới chỉ có phiên ẩn danh của Đấu Trường).
  Future<void> push(Map<String, dynamic> saveJson) async {
    if (!isLinked) return;
    final uid = _client.auth.currentUser!.id;
    await _client.from('player_saves').upsert({'user_id': uid, 'data': saveJson});
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
    );
  }
}
