/// Mã quà tặng — bù đắp thủ công (VD mã xin lỗi sau sự cố crash, mã cho
/// reviewer Google Play test tính năng trả phí). Thuần dữ liệu + hàm thuần,
/// giống các module core/ khác.
library;

import 'models.dart';
import 'simulation.dart' show grantGems, setAdsRemoved;
import 'vip.dart' show activateVip;

/// code (đã chuẩn hoá UPPERCASE, trim) -> phần thưởng. Thêm mã mới ở đây khi
/// cần gửi quà đợt sau — không cần đổi UI/controller.
const Map<String, ({double gems, bool adsRemoved, bool vip})> redeemCodes = {
  'XINLOI2026': (gems: 1000, adsRemoved: false, vip: false),
  // Google Play yêu cầu cấp quyền xem nội dung trả phí cho reviewer khi nộp
  // bản thử nghiệm khép kín — mã này mở Gỡ QC + VIP + Kim Cương để họ đánh
  // giá được tính năng IAP mà không cần trả tiền thật. Ghi mã này vào ô
  // "Testing instructions" khi nộp lên Play Console.
  'REVIEWER2026': (gems: 5000, adsRemoved: true, vip: true),
};

enum RedeemStatus { success, alreadyClaimed, invalid }

/// Áp [rawCode] vào [state]. Thuần — không lưu, bên gọi (GameController) tự
/// `saveNow()` khi status == success.
({RedeemStatus status, double gems}) applyRedeemCode(
  GameState state,
  String rawCode,
  int nowMillis,
) {
  final code = rawCode.trim().toUpperCase();
  final reward = redeemCodes[code];
  if (reward == null) return (status: RedeemStatus.invalid, gems: 0);
  if (state.redeemedCodes.contains(code)) {
    return (status: RedeemStatus.alreadyClaimed, gems: 0);
  }
  if (reward.gems > 0) grantGems(state, reward.gems);
  if (reward.adsRemoved) setAdsRemoved(state);
  if (reward.vip) activateVip(state, nowMillis);
  state.redeemedCodes.add(code);
  return (status: RedeemStatus.success, gems: reward.gems);
}
