# SETUP — Quảng cáo (AdMob) & Mua hàng (IAP)

Code đã tích hợp **AdMob rewarded** + **in_app_purchase** sau các interface trừu
tượng. Hiện đang chạy bằng **TEST ID của Google** và **product ID placeholder**,
chỉ bật trên **Android/iOS** (desktop/web giữ stub). Dưới đây là những việc
**bạn phải tự làm** trong console trước khi phát hành.

> Đối tượng đã chốt: **General (13+)** — KHÔNG child-directed. Nếu sau này nhắm
> trẻ em, xem mục [Play Families](#play-families) — phải đổi cấu hình quảng cáo.

---

## 1. AdMob (quảng cáo thưởng)

1. Tạo tài khoản & app tại <https://apps.admob.com> (một app Android, một iOS).
2. Lấy **App ID** (dạng `ca-app-pub-XXXX~YYYY`) và tạo **Rewarded ad unit** cho
   mỗi nền tảng (dạng `ca-app-pub-XXXX/ZZZZ`).
3. Thay TEST ID bằng ID thật:
   - `lib/ads/ad_config.dart` → `_androidRewardedTest`, `_iosRewardedTest`
   - `android/app/src/main/AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID`
   - `ios/Runner/Info.plist` → `GADApplicationIdentifier`
4. **Đồng ý người dùng (UMP/GDPR):** vào AdMob → Privacy & messaging → tạo
   **GDPR message** (và **US state regulations** nếu cần). Code đã gọi
   `ConsentInformation`/`ConsentForm` trong `lib/ads/ad_bootstrap.dart`; message
   phải được cấu hình trong console thì form mới hiện ở EEA/UK.
5. Test bằng thiết bị thật + [test device IDs](https://developers.google.com/admob/flutter/test-ads)
   để không bị AdMob khoá vì tự bấm quảng cáo thật.

⚠️ **Không phát hành khi còn TEST ID** — bấm quảng cáo thật trên test unit là vi
phạm chính sách; nhưng dùng ID thật khi phát triển cũng dễ bị khoá. Chỉ đổi sang
ID thật ở bản release.

---

## 2. In-app purchase (mua bằng tiền thật)

Product ID phải **khớp** hằng trong `lib/iap/iap_products.dart`:

| Product ID          | Loại            | Trao gì (`Balance`)         |
| ------------------- | --------------- | --------------------------- |
| `boba_gems_small`   | Consumable      | +`iapGemsSmall` (100) 💎     |
| `boba_remove_ads`   | Non-consumable  | bật `adsRemoved`            |
| `boba_starter_pack` | Non-consumable  | +`iapStarterGems` (300) 💎, một lần |

### Android (Play Console)
1. Tạo app, **Monetize → Products → In-app products / Subscriptions**, thêm 3
   product với đúng ID trên, đặt giá.
2. Upload một bản build (internal testing) — IAP chỉ hoạt động với app đã ký &
   đúng applicationId, cài qua Play.
3. Thêm **License testers** (Play Console → Setup → License testing) để mua thử
   không mất tiền.

### iOS (App Store Connect)
1. Tạo 3 In-App Purchase với cùng product ID, điền metadata + giá.
2. Test bằng **Sandbox tester**.

### ⚠️ Xác thực biên nhận (bảo mật)
`RealIapService` hiện trao thưởng NGAY khi store báo `purchased` (client-only) —
có thể bị giả mạo. Trước khi phát hành nên thêm **verify receipt phía server**
(Google Play Developer API / App Store `verifyReceipt`) rồi mới trao. Điểm chèn:
`lib/iap/real_iap_service.dart` → `_onPurchases` (verify trước khi `_delivered.add`).

---

## 3. Play Families & chính sách {#play-families}

App khai báo **General audience (13+)**, nên:
- Play Console → **Policy → App content**: khai **Target audience & content** là
  13+ (không chọn nhóm tuổi trẻ em) → KHÔNG vào Designed for Families.
- **Ads declaration**: có quảng cáo → khai "Yes".
- **Data safety**: khai đúng SDK thu thập (AdMob thu thập ID quảng cáo…).
- iOS: đã có `NSUserTrackingUsageDescription` (ATT) trong Info.plist.

Nếu **đổi hướng sang trẻ em (Designed for Families)** thì bắt buộc:
- `AdRequest` phải gắn `tagForChildDirectedTreatment` + chỉ quảng cáo **không cá
  nhân hóa**, SDK phải nằm trong danh sách families-certified.
- IAP phải sau **parental gate**.
- → Cần sửa `lib/ads/*` và luồng mua; KHÔNG dùng cấu hình hiện tại như-nguyên.

---

## 4. Ghi chú build

- AdMob & IAP là **plugin mobile-only** → build **Windows/desktop vẫn hỏng**
  (ngoài ra `audioplayers_windows` cần VS2022). Verify trên Android/iOS.
- Test tự động (`flutter test`) dùng **stub** cho cả Ad lẫn IAP nên chạy được
  mọi nơi, không đụng SDK thật.
