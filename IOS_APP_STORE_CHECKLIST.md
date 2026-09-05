# IOS APP STORE CHECKLIST — đẩy Boba Empire lên App Store

Bổ sung cho [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) (Play Store). Chỉ liệt kê
việc **riêng iOS** hoặc khác Android. Nội dung listing: [STORE_LISTING.md](STORE_LISTING.md).
Ads/IAP chi tiết: [SETUP.md](SETUP.md).

Ký hiệu: 🔴 chặn nộp/duyệt · 🟡 nên làm · 🟢 tùy chọn.
Trạng thái: `[ ]` chưa · `[~]` một phần · `[x]` xong.

---

## 0. Chặn nộp — phát hiện trong repo (làm trước)

- [ ] 🔴 **PrivacyInfo.xcprivacy CHƯA có** — Apple bắt buộc từ 05/2024. Không có
  → App Store Connect từ chối upload. Tạo qua Xcode (mục 2.5).
- [ ] 🔴 **GADApplicationIdentifier còn TEST ID** trong `ios/Runner/Info.plist`
  (`ca-app-pub-3940256099942544~1458002511`). Phải là App ID iOS thật từ AdMob.
  Ship test ad = vi phạm chính sách Google → khóa tài khoản.
- [ ] 🔴 **Rewarded unit iOS còn test** — `lib/ads/ad_config.dart`:
  `_iosRewardedProd = _iosRewardedTest`. Tạo app + unit iOS trong AdMob, thay ID
  thật (mục 3).
- [x] 🟡 **iPhone-only** (đã quyết định) — `TARGETED_DEVICE_FAMILY = "1"` (3 chỗ
  trong `project.pbxproj`) + bỏ `UISupportedInterfaceOrientations~ipad` khỏi
  Info.plist. Khỏi cần screenshot/test iPad nữa.
- [x] 🟢 **ITSAppUsesNonExemptEncryption = false** — đã thêm vào Info.plist (app
  chỉ dùng HTTPS chuẩn → miễn khai export compliance mỗi lần nộp).

---

## 1. Tài khoản & App Store Connect

- [ ] 🔴 **Apple Developer Program** — $99/năm, cần duyệt 24–48h. (Cá nhân hay
  Organization đều được; game này đang ký team `P3MPHWPJ62`.)
- [ ] 🔴 **App ID** `com.pcingame.bobaempire` trong Certificates, IDs & Profiles
  → bật capability **In-App Purchase** (và **App Attest**/không cần).
- [ ] 🔴 Tạo app trong **App Store Connect**: Platform iOS, tên
  `Đế Chế Trà Sữa` / `Boba Empire`, primary language `Vietnamese`, bundle ID
  chọn đúng, SKU tùy ý.
- [ ] 🟡 **App Store Connect API key** (nếu muốn upload bằng CI/Transporter CLI
  thay vì Xcode Organizer).

## 2. Cấu hình Xcode project

- [ ] 🔴 **Signing** — mở `ios/Runner.xcworkspace`, target Runner → Signing &
  Capabilities: tick "Automatically manage signing", chọn Team `P3MPHWPJ62`.
  Xcode sẽ tạo **Apple Distribution certificate** + **App Store provisioning
  profile**. (Hiện `CODE_SIGN_STYLE = Automatic` — OK.)
- [ ] 🔴 **Capability: In-App Purchase** — thêm trong Signing & Capabilities
  (plugin `in_app_purchase_storekit` cần entitlement này).
- [ ] 🟡 **Version / build** — `pubspec.yaml` đang `1.0.0+1`. Info.plist đọc
  `$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)` từ đây. ⚠️ pbxproj có
  hardcode `MARKETING_VERSION = 1.0` / `CURRENT_PROJECT_VERSION = 1` ở vài config
  — kiểm archive hiện đúng `1.0.0 (1)`; mỗi lần nộp phải **tăng build number**
  (`1.0.0+2`…), không được trùng.
- [ ] 🟡 **Bỏ NSAllowsArbitraryLoads nếu có** — Info.plist hiện KHÔNG có ATS
  ngoại lệ (tốt).
- [ ] 🔴 **SKAdNetworkItems** — Info.plist chỉ có 1 ID của Google. Thêm danh sách
  đầy đủ (~100+) từ [Google's SKAdNetwork list](https://developers.google.com/admob/ios/3p-skadnetwork)
  để đo lường & doanh thu ad không bị thiếu hụt.
- [ ] 🟡 **Launch screen** — `LaunchScreen.storyboard`. Đảm bảo không giống
  splash/quảng cáo (Apple guideline 2.3.x); nền đơn giản + logo là được.

### 2.5. PrivacyInfo.xcprivacy (🔴 bắt buộc)

Trong Xcode: **File → New → File → App Privacy** → lưu vào group `Runner`
(`ios/Runner/PrivacyInfo.xcprivacy`), tick target Runner. Nội dung tối thiểu cho
app này (có AdMob + ATT + shared_preferences):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <true/>
  <key>NSPrivacyTrackingDomains</key>
  <array>
    <!-- Lấy đúng danh sách từ tài liệu AdMob privacy manifest.
         Pod google_mobile_ads 9.x đã kèm manifest riêng cho SDK; app-level
         chỉ cần khai tracking = true. Nếu Apple cảnh báo thiếu domain, thêm
         theo hướng dẫn Google. -->
  </array>
  <key>NSPrivacyCollectedDataTypes</key>
  <array/>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>CA92.1</string></array>
    </dict>
  </array>
</dict>
</plist>
```

- [ ] Kiểm sau khi `pod install`: các pod (`google_mobile_ads`,
  `shared_preferences_foundation`, `path_provider`) tự kèm `.xcprivacy` của
  chúng — không cần copy thủ công.

## 3. AdMob iOS

- [ ] 🔴 Tạo **app iOS** trong AdMob (khác app Android) → lấy **App ID iOS**,
  thay vào `GADApplicationIdentifier` (Info.plist).
- [ ] 🔴 Tạo **Rewarded ad unit iOS** → thay `_iosRewardedProd` trong
  `lib/ads/ad_config.dart` (bỏ dòng `= _iosRewardedTest`).
- [ ] 🔴 **UMP / GDPR consent message** — `ad_bootstrap.dart` đã gọi
  `ConsentForm.loadAndShowConsentFormIfRequired`, nhưng message phải tạo trong
  AdMob → Privacy & messaging → (GDPR + **US states / ATT**). Bật cả **ATT
  explainer** trong UMP nếu dùng UMP để trigger ATT.
- [ ] 🟡 **App Tracking Transparency** — `NSUserTrackingUsageDescription` đã có
  ("Dùng để hiển thị quảng cáo phù hợp hơn với bạn."). Kiểm popup ATT **thật sự
  hiện** khi mở app lần đầu (không phải chỉ pre-prompt). Pre-prompt "stay free"
  không được có nút giống hệt hệ thống / gây hiểu nhầm (guideline 5.1.1(iv)).
- [ ] 🟡 Test bằng **AdMob test device ID** trên máy thật trước khi bật ID thật.
- [ ] 🟢 Liên kết AdMob ↔ App Store Connect (đo doanh thu).

## 4. In-App Purchase (App Store Connect — khác Play)

- [ ] 🔴 Tạo **8 sản phẩm** trong App Store Connect → Features → In-App Purchases,
  ĐÚNG product ID (giống Play):

  | ID | Loại App Store | Ghi chú |
  |---|---|---|
  | `boba_gems_small` / `_medium` / `_large` | Consumable | gói 💎 |
  | `boba_remove_ads` | Non-Consumable | gỡ QC |
  | `boba_starter_pack` | Non-Consumable | 1 lần |
  | `boba_double_income` | Non-Consumable | x2 thu nhập vĩnh viễn |
  | `boba_piggy` | Consumable | đập heo |
  | `boba_vip30` | Consumable | ⚠️ "VIP 30 ngày" — Apple **có thể** yêu cầu đổi sang **Auto-Renewable Subscription**. Consumable không tự gia hạn thì được, nhưng chuẩn bị lý do (giống battle-pass mùa). |

- [ ] 🔴 Mỗi sản phẩm: **Reference Name**, **Price** (chọn tier), **Display Name**
  + **Description** cho từng ngôn ngữ (vi/en/es/pt/id/th), **Review screenshot**
  (ảnh chụp màn mua trong app — Apple bắt buộc, thiếu là reject).
- [ ] 🔴 **StoreKit config / Sandbox tester** — tạo Sandbox Apple ID trong ASC →
  Users and Access → Sandbox → Testers. Test mua + **Khôi phục mua hàng** trên
  TestFlight/Sandbox.
- [ ] 🔴 **Paid Apps agreement** — App Store Connect → Agreements, Tax, and
  Banking: ký "Paid Applications" + điền thuế + ngân hàng (không ký → IAP không
  bán được).
- [ ] 🟡 **Verify receipt server-side** — hiện client-only
  (`real_iap_service.dart`), dễ giả mạo. iOS dùng App Store Server API /
  `verifyReceipt`. Nên làm trước khi doanh thu lớn.
- [ ] 🟡 **Giá theo vùng** — hạ tier cho VN/ID/BR/TH (App Store tự đề xuất theo
  base price, kiểm lại).

## 5. App Privacy (nhãn dinh dưỡng) + tracking

- [ ] 🔴 **App Privacy** trong App Store Connect (bắt buộc, khai trước khi nộp):
  - **Identifiers → Device ID**: Có, dùng cho **Third-Party Advertising** +
    **Tracking**.
  - **Usage Data → Product Interaction**: Có (AdMob analytics).
  - **Diagnostics → Crash / Performance**: nếu SDK ads gửi.
  - **Purchases → Purchase History**: Có (IAP).
  - **"Used for tracking"**: **YES** (có ATT + ads cá nhân hóa).
  - Không thu thập: tên, email, vị trí chính xác, danh bạ, ảnh.
- [ ] 🟡 Đối chiếu khai báo với PrivacyInfo.xcprivacy + Data safety form bên Play
  (phải nhất quán).

## 6. Phân loại độ tuổi & nội dung

- [ ] 🔴 **Age Rating questionnaire** (ASC — bản mới 2025: 4+/9+/13+/16+/18+):
  - Simulated Gambling: **None** — "Vòng quay may mắn" chỉ cho tiền/💎 trong game,
    miễn phí/theo QC, không mua lượt quay bằng tiền thật → không tính gambling.
    (Nếu Apple hỏi thêm: nêu rõ không có real-money stakes.)
  - Contests: None. Bạo lực/tình dục/ngôn từ: None.
  - **In-app purchases + ads**: khai Có.
  - Kết quả kỳ vọng: **4+** hoặc **9+** (do ads). Game khai **13+ General, KHÔNG
    child-directed** (khớp cấu hình hiện tại — xem SETUP.md mục 3).
- [ ] 🔴 **"Does your app contain loot boxes?"** → mô tả cơ chế ngẫu nhiên (vòng
  quay). Apple guideline 3.1.1: nếu có **IAP hộp ngẫu nhiên** phải công bố tỉ lệ
  — vòng quay KHÔNG bán bằng tiền thật nên không thuộc diện này, nhưng khai trung
  thực. `boba_piggy` (đập heo) tích theo thời gian, không ngẫu nhiên khi mua.

## 7. Assets & Store listing

- [ ] 🔴 **App Icon 1024×1024** (không alpha, không bo góc) —
  `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` đã có
  (flutter_launcher_icons + `remove_alpha_ios: true`). Kiểm không viền trắng.
- [ ] 🔴 **Screenshots** — App Store yêu cầu **theo kích thước thiết bị**:
  - **6.9"** (iPhone 16 Pro Max, 1320×2868) — bắt buộc.
  - **6.5"** (iPhone 8 Plus era, 1242×2688) — bắt buộc (hoặc để 6.9" tự scale
    tùy đợt, nhưng an toàn cứ nộp cả 2).
  - ~~13" iPad~~ — không cần (đã chốt iPhone-only, mục 0).
  - 3–10 ảnh mỗi cỡ. Ảnh Play hiện là 1080×2160 (2:1) → **KHÔNG hợp App Store**,
    phải chụp lại. Dùng simulator đúng model + `xcrun simctl io booted screenshot`.
  - Nội dung: home (matcha/caramel), cutscene cốt truyện, cửa hàng 💎, vòng quay,
    kho Sao, dark mode. Tiếng Việt.
- [ ] 🟡 **App Preview video** (tùy chọn, tăng chuyển đổi) — 15–30s, quay từ
  thiết bị/simulator.
- [ ] 🔴 **Name** ≤ 30, **Subtitle** ≤ 30, **Keywords** ≤ 100 (phẩy),
  **Promotional Text** ≤ 170, **Description** ≤ 4000 — dán từ
  [STORE_LISTING.md](STORE_LISTING.md) cho từng ngôn ngữ.
- [ ] 🔴 **Support URL** (bắt buộc) + **Marketing URL** (tùy chọn). Có thể dùng
  trang GitHub Pages đơn giản hoặc `mailto:`.
- [ ] 🟡 Nhờ **người bản ngữ soát** bản dịch listing + IAP description.

## 8. Legal

- [ ] 🔴 **Privacy Policy URL công khai** — có `privacy-policy.html` /
  `PRIVACY_POLICY.md`. Host (GitHub Pages `/docs` → dán URL vào ASC → App Privacy
  + AdMob). Dùng chung URL với Play.
- [ ] 🟡 **EULA** — mặc định Apple Standard EULA là đủ (không cần custom).

## 9. Build & upload

- [ ] 🔴 `flutter build ipa --release` (cần macOS + Xcode). Ra
  `build/ios/ipa/*.ipa` + Xcode archive.
- [ ] 🔴 Upload: **Xcode → Window → Organizer → Distribute App → App Store
  Connect**, HOẶC app **Transporter** (Mac App Store) với file `.ipa`.
- [ ] 🟡 Chờ **"Processing"** trong ASC (10–60 phút) → build hiện ở TestFlight.
- [ ] 🟡 Nếu bị **email cảnh báo** (ITMS-xxxx) về privacy manifest / SDK ký thiếu
  → sửa theo hướng dẫn rồi bump build, upload lại.

## 10. TestFlight (khuyên trước Production)

- [ ] 🟡 **Internal testing** — thêm tối đa 100 thành viên team, không cần Apple
  duyệt, test ngay.
- [ ] 🟢 **External testing** — cần Apple review (1 lần, ~1 ngày) → mời tối đa
  10.000 người qua link công khai.
- [ ] 🔴 Trên TestFlight: chơi end-to-end, **mua thử cả 8 IAP + Khôi phục**,
  xem **QC thưởng** trao đúng, đổi **6 ngôn ngữ** không vỡ layout, **dark mode**,
  lifecycle (offline/kill-save), **cutscene cốt truyện + sự kiện đối thủ**.

## 11. Nộp duyệt (Submit for Review)

- [ ] 🔴 Điền đủ: build, screenshots (mọi cỡ bắt buộc), listing mọi ngôn ngữ,
  App Privacy, Age Rating, giá + Availability (quốc gia), IAP kèm build.
- [ ] 🔴 **App Review Information**:
  - Sign-in: **không cần** (no account).
  - **Notes for Reviewer**: nêu rõ — game idle offline, có QC thưởng (rewarded,
    không ép xem), IAP là vật phẩm ảo, "Vòng quay may mắn" chỉ thưởng tiền trong
    game (không bán lượt quay), ATT dùng cho ads cá nhân hóa. Nếu reviewer ở vùng
    không tải được QC test: QC có thể không hiện — thưởng vẫn trao (adFree path).
  - Contact: tên + email + phone.
- [ ] 🟡 **Version release**: chọn "Manually release" để chủ động, hoặc
  "Automatically after approval".
- [ ] 🟢 **Phased release** (7 ngày) để theo dõi crash trước khi 100%.

## 12. Sau phát hành

- [ ] 🟡 Theo dõi **App Store Connect → Analytics** (impressions, cài, chuyển
  đổi) + **Crashes** (Xcode Organizer / MetricKit).
- [ ] 🟡 Theo dõi doanh thu **ads (AdMob) + IAP (ASC)**; cân bằng lại kinh tế nếu
  cần (số cốt truyện/rival/perk hiện **chưa tune** — xem GAME_DESIGN §15–16).
- [ ] 🟢 Chuẩn bị bản cập nhật đầu (thường có feedback từ review hoặc user).

---

## Critical path (thứ tự nên làm)

1. Apple Developer Program + App ID (bật IAP) + tạo app ASC
2. Signing trong Xcode (Distribution cert + profile) + capability IAP
3. **PrivacyInfo.xcprivacy** + AdMob iOS App/Unit ID thật + SKAdNetwork list
4. Ký "Paid Apps" agreement + tạo 8 IAP + Sandbox tester
5. App Privacy + Age Rating + Support/Privacy URL
6. Screenshots đúng cỡ (6.9" + 6.5" [+ 13" iPad nếu Universal]) + listing
7. `flutter build ipa` → upload → TestFlight → test IAP/ads/ngôn ngữ
8. Submit for Review + Notes for Reviewer

> Ba thứ dễ bị reject nhất ở iOS: **thiếu PrivacyInfo.xcprivacy**, **thiếu review
> screenshot cho IAP**, và **ATT/pre-prompt gây hiểu nhầm**. Xử ba cái này kỹ.
