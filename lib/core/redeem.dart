/// Mã quà tặng — bù đắp thủ công (VD mã xin lỗi sau sự cố crash, sự kiện đặc
/// biệt). Thuần dữ liệu + hàm thuần, giống các module core/ khác.
library;

import 'models.dart';
import 'simulation.dart' show grantGems;

/// code (đã chuẩn hoá UPPERCASE, trim) -> số Kim Cương thưởng. Thêm mã mới ở
/// đây khi cần gửi quà đợt sau — không cần đổi UI/controller.
const Map<String, double> redeemCodes = {
  'XINLOI2026': 1000,
};

enum RedeemStatus { success, alreadyClaimed, invalid }

/// Áp [rawCode] vào [state]. Thuần — không lưu, bên gọi (GameController) tự
/// `saveNow()` khi status == success.
({RedeemStatus status, double gems}) applyRedeemCode(
  GameState state,
  String rawCode,
) {
  final code = rawCode.trim().toUpperCase();
  final reward = redeemCodes[code];
  if (reward == null) return (status: RedeemStatus.invalid, gems: 0);
  if (state.redeemedCodes.contains(code)) {
    return (status: RedeemStatus.alreadyClaimed, gems: 0);
  }
  grantGems(state, reward);
  state.redeemedCodes.add(code);
  return (status: RedeemStatus.success, gems: reward);
}
