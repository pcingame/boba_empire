/// Tính năng online (Hội, Chợ, Đấu Trường, bảng xếp hạng…) chỉ chạy với tài khoản đã LIÊN KẾT email
/// (xem cloud_save_repository.dart): người chơi không bị tạo tài khoản ẩn danh âm thầm nữa — mọi dữ
/// liệu trên server gắn với một tài khoản khôi phục được. Phiên ẩn danh cũ (từ bản trước) cũng bị coi
/// là chưa liên kết cho tới khi nâng cấp bằng email (giữ nguyên user_id, không mất Hội/ví/BXH).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Chưa liên kết email nên chưa dùng được tính năng online. UI chặn trước ở cổng
/// (`ensureOnlineLinked`); lỗi này chỉ lọt tới các đường chạy nền, nơi nó được nuốt im lặng.
class NotLinkedException implements Exception {
  const NotLinkedException();
  @override
  String toString() => 'NotLinkedException: cần liên kết email để dùng tính năng online';
}

/// user_id của tài khoản đã liên kết; ném [NotLinkedException] nếu chưa đăng nhập hoặc còn ẩn danh.
String requireLinkedId(User? user) {
  if (user == null || user.isAnonymous) throw const NotLinkedException();
  return user.id;
}
