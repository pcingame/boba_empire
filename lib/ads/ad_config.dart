/// Cấu hình ID quảng cáo.
///
/// ⚠️ ĐANG DÙNG TEST AD UNIT ID CHÍNH THỨC CỦA GOOGLE — an toàn để phát triển,
/// nhưng PHẢI thay bằng ID thật từ AdMob console trước khi phát hành (nếu không
/// sẽ vi phạm chính sách AdMob khi bấm quảng cáo thật). Xem SETUP.md.
library;

import 'dart:io' show Platform;

class AdConfig {
  const AdConfig._();

  /// Rewarded ad — test unit id của Google (KHÁC theo nền tảng).
  static const String _androidRewardedTest =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosRewardedTest =
      'ca-app-pub-3940256099942544/1712485313';

  /// Unit id rewarded theo nền tảng đang chạy.
  static String get rewardedUnitId =>
      Platform.isIOS ? _iosRewardedTest : _androidRewardedTest;
}
