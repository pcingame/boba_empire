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
  /// [auth] chỉ để test thay GoTrue giả; mặc định dùng `client.auth`.
  CloudSaveRepository(this._client, {GoTrueClient? auth}) : _auth = auth ?? _client.auth;

  final SupabaseClient _client;
  final GoTrueClient _auth;

  /// true khi mã vừa gửi là mã NÂNG CẤP tài khoản ẩn danh (updateUser) → xác nhận bằng
  /// [OtpType.emailChange]; false = mã đăng nhập thường ([OtpType.email]).
  bool _upgradePending = false;

  /// Đã đăng nhập bằng tài khoản THẬT (không phải phiên ẩn danh của Đấu
  /// Trường) — chỉ tài khoản này mới coi là "đã liên kết cloud save".
  bool get isLinked {
    final user = _auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  String? get linkedEmail => isLinked ? _auth.currentUser?.email : null;

  /// Gửi mã xác nhận tới [email] (độ dài do Supabase quyết định, đã gặp cả
  /// 8 số thực tế — đừng giả định cố định 6 số). Ném lỗi nếu Supabase từ chối (VD gửi quá
  /// nhanh liên tiếp — server tự giới hạn, không cần tự làm cooldown ở đây).
  ///
  /// Đang là phiên ẩn danh (người chơi bản cũ đã có Hội/ví Chợ/BXH) thì NÂNG CẤP tại chỗ bằng
  /// `updateUser(email)`: giữ nguyên user_id nên không mất gì trên server. `signInWithOtp` thì tạo
  /// một tài khoản MỚI (user_id khác) — mọi thứ gắn với user_id cũ ở lại tài khoản cũ. Email đã
  /// thuộc tài khoản khác (người chơi cũ đăng nhập máy mới) thì rơi về đăng nhập thường vào tài
  /// khoản đó (tải save cloud của họ về).
  Future<void> sendCode(String email) async {
    final user = _auth.currentUser;
    if (user != null && user.isAnonymous) {
      try {
        await _auth.updateUser(UserAttributes(email: email));
        _upgradePending = true;
        return;
      } on AuthException catch (e) {
        if (!_isEmailTaken(e)) rethrow;
      }
    }
    _upgradePending = false;
    await _auth.signInWithOtp(email: email);
  }

  static bool _isEmailTaken(AuthException e) =>
      e.code == 'email_exists' ||
      e.message.toLowerCase().contains('already been registered') ||
      e.message.toLowerCase().contains('already registered');

  /// Xác nhận mã. Mã nâng cấp (xem [sendCode]) dùng loại `email_change`; mã đăng nhập dùng `email`.
  Future<void> verifyCode(String email, String code) => _auth.verifyOTP(
        email: email,
        token: code,
        type: _upgradePending ? OtpType.emailChange : OtpType.email,
      );

  Future<void> signOut() => _auth.signOut();

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
