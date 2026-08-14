/// Cấu hình ID quảng cáo.
///
/// Debug dùng TEST ID của Google (an toàn); release mới dùng ID THẬT — tránh
/// tự bấm quảng cáo thật lúc dev (Google coi là invalid traffic, có thể khóa
/// tài khoản AdMob). Xem SETUP.md.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kReleaseMode;

class AdConfig {
  const AdConfig._();

  /// Rewarded — test unit id của Google (KHÁC theo nền tảng), dùng khi debug.
  static const String _androidRewardedTest =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosRewardedTest =
      'ca-app-pub-3940256099942544/1712485313';

  /// Rewarded unit id THẬT dùng ở bản release.
  /// iOS chưa tạo app AdMob → tạm dùng test cho tới khi phát hành iOS.
  static const String _androidRewardedProd =
      'ca-app-pub-9748541552219348/6536401991';
  static const String _iosRewardedProd = _iosRewardedTest;

  /// Unit id rewarded theo nền tảng; debug → test, release → thật.
  static String get rewardedUnitId {
    if (kReleaseMode) {
      return Platform.isIOS ? _iosRewardedProd : _androidRewardedProd;
    }
    return Platform.isIOS ? _iosRewardedTest : _androidRewardedTest;
  }
}
