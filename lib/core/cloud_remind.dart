/// Nhắc người chơi CHƯA liên kết email bật đồng bộ đám mây — không có nó, đổi
/// máy / cài lại game là mất Xu, 💎, phụ kiện và cả Xu Chợ (ví nằm trên server
/// gắn với tài khoản). Nhắc nhẹ: từ lần mở app thứ [cloudRemindMinOpens], cách
/// nhau [cloudRemindIntervalMs], tối đa [cloudRemindMaxTimes] lần rồi thôi.
/// Hàm thuần ([cloudRemindDue]) + một hàm đọc/ghi SharedPreferences.
library;

import 'package:shared_preferences/shared_preferences.dart';

const int cloudRemindMinOpens = 3;
const int cloudRemindMaxTimes = 5;
const int cloudRemindIntervalMs = 3 * 24 * 60 * 60 * 1000;

const cloudRemindOpensKey = 'cloud_remind_opens';
const cloudRemindCountKey = 'cloud_remind_count';
const cloudRemindLastKey = 'cloud_remind_last_ms';

/// Đã đến lúc nhắc chưa. [lastShownMs] = 0 nghĩa là chưa từng nhắc. Đồng hồ máy
/// bị lùi (now < last) thì KHÔNG nhắc — tránh nhắc dồn khi chỉnh giờ.
bool cloudRemindDue({
  required bool linked,
  required int opens,
  required int shownCount,
  required int lastShownMs,
  required int nowMs,
}) {
  if (linked) return false;
  if (opens < cloudRemindMinOpens) return false;
  if (shownCount >= cloudRemindMaxTimes) return false;
  if (lastShownMs == 0) return true;
  return nowMs - lastShownMs >= cloudRemindIntervalMs;
}

/// Gọi MỘT lần mỗi lần mở app: đếm lượt mở, và nếu đến lúc nhắc thì ghi nhận đã
/// nhắc (đếm + mốc giờ) rồi trả true để UI hiện hộp thoại.
bool takeCloudRemindTurn(
  SharedPreferences prefs, {
  required bool linked,
  required int nowMs,
}) {
  final opens = (prefs.getInt(cloudRemindOpensKey) ?? 0) + 1;
  prefs.setInt(cloudRemindOpensKey, opens);
  final count = prefs.getInt(cloudRemindCountKey) ?? 0;
  final due = cloudRemindDue(
    linked: linked,
    opens: opens,
    shownCount: count,
    lastShownMs: prefs.getInt(cloudRemindLastKey) ?? 0,
    nowMs: nowMs,
  );
  if (due) {
    prefs.setInt(cloudRemindCountKey, count + 1);
    prefs.setInt(cloudRemindLastKey, nowMs);
  }
  return due;
}
