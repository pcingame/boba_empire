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
  static const String _androidRewardedProd =
      'ca-app-pub-9748541552219348/6536401991';
  static const String _iosRewardedProd =
      'ca-app-pub-9748541552219348/7263782428';

  /// Test device ID (cách nhau dấu phẩy) qua `--dart-define=ADMOB_TEST_DEVICES=`.
  ///
  /// Máy có ID ở đây nhận QUẢNG CÁO TEST kể cả khi chạy bản release với unit
  /// id thật — để tự test trên máy thật mà không bơm request/impression vào
  /// tài khoản production (tài khoản mới ít thiết bị mà lặp lại một máy dễ bị
  /// Google đưa vào "Limited ad serving", xem SETUP.md). ID lấy từ log của
  /// SDK ở lần chạy đầu: "Use RequestConfiguration...setTestDeviceIds(...)"
  /// (Android logcat) / "To get test ads on this device, set testDeviceIds"
  /// (iOS console). Rỗng = không máy nào là test device (mặc định, an toàn cho
  /// người dùng thật).
  static const String _testDevicesRaw =
      String.fromEnvironment('ADMOB_TEST_DEVICES');

  static List<String> get testDeviceIds => [
        for (final id in _testDevicesRaw.split(','))
          if (id.trim().isNotEmpty) id.trim(),
      ];

  /// Unit id rewarded theo nền tảng; debug → test, release → thật.
  static String get rewardedUnitId {
    if (kReleaseMode) {
      return Platform.isIOS ? _iosRewardedProd : _androidRewardedProd;
    }
    return Platform.isIOS ? _iosRewardedTest : _androidRewardedTest;
  }
}
