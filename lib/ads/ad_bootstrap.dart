/// Khởi tạo AdMob: thu thập đồng ý (UMP/GDPR) rồi init SDK. Gọi một lần ở
/// main() TRƯỚC khi tạo RealAdService. Chỉ chạy trên Android/iOS.
library;

import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBootstrap {
  const AdBootstrap._();

  static Future<void> initialize() async {
    // Đồng ý là yêu cầu pháp lý ở EEA/UK cho quảng cáo cá nhân hóa. Thu thập
    // trước; lỗi thì vẫn init để game không kẹt (test ad không cần consent).
    try {
      await _gatherConsent();
    } catch (_) {}
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
