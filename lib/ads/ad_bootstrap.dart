/// Khởi tạo AdMob: thu thập đồng ý (UMP/GDPR) rồi init SDK. Gọi một lần ở
/// main() và KHÔNG await (form đồng ý + gọi mạng sẽ chặn frame đầu) — truyền
/// Future trả về cho `RealAdService(ready:)`. Chỉ chạy trên Android/iOS.
library;

import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

class AdBootstrap {
  const AdBootstrap._();

  /// Future của lần [initialize] đang chạy, do `main()` gán. MỌI chỗ đụng tới
  /// SDK quảng cáo phải chờ nó trước: gọi sớm hơn thì kênh nền tảng trả về
  /// rỗng/null và im lặng thất bại (đã gặp: banner không bao giờ hiện, không
  /// báo lỗi gì). Null ở nền tảng không có quảng cáo — `await null` vô hại.
  static Future<void>? ready;

  static Future<void> initialize() async {
    // Đồng ý là yêu cầu pháp lý ở EEA/UK cho quảng cáo cá nhân hóa. Thu thập
    // trước; lỗi thì vẫn init để game không kẹt (test ad không cần consent).
    try {
      await _gatherConsent();
    } catch (_) {}
    // Đặt test device TRƯỚC initialize để request đầu tiên đã được đánh dấu.
    final testIds = AdConfig.testDeviceIds;
    if (testIds.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testIds),
      );
    }
    await MobileAds.instance.initialize();
  }

  static Future<void> _gatherConsent() {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((_) {
          if (!completer.isCompleted) completer.complete();
        });
      },
      (error) {
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }
}
