/// Hộp "Có gì mới" hiện MỘT lần sau khi người chơi cập nhật lên bản có nội dung
/// mới. Đổi [whatsNewVersion] (và chuỗi l10n `whatsNew*`) mỗi lần có bản mới
/// đáng báo; bản khác không có nội dung thì chỉ ghi nhớ phiên bản, không hiện gì.
library;

/// Phiên bản app mà nội dung hộp hiện tại mô tả.
const whatsNewVersion = '1.0.8';

/// Khoá SharedPreferences: phiên bản gần nhất app đã "ghi nhận".
const whatsNewSeenKey = 'whats_new_seen_version';

/// [seen] = phiên bản đã ghi nhận lần trước (null = chưa từng ghi, tức bản cũ
/// chưa có tính năng này HOẶC cài mới). [hasSave] phân biệt hai trường hợp đó:
/// cài mới (chưa có save) thì không hiện — người mới chưa "cập nhật" gì cả.
bool shouldShowWhatsNew({
  required String? seen,
  required String current,
  required bool hasSave,
}) =>
    current == whatsNewVersion && seen != current && (seen != null || hasSave);
