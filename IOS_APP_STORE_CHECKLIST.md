# IOS APP STORE CHECKLIST — đẩy Boba Empire lên App Store

Bổ sung cho [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) (Play Store). Chỉ liệt kê
việc **riêng iOS** hoặc khác Android. Nội dung listing: [STORE_LISTING.md](STORE_LISTING.md).
Ads/IAP chi tiết: [SETUP.md](SETUP.md).

Ký hiệu: 🔴 chặn nộp/duyệt · 🟡 nên làm · 🟢 tùy chọn.
Trạng thái: `[ ]` chưa · `[~]` một phần · `[x]` xong.

---

## 0. Chặn nộp — phát hiện trong repo (làm trước)

- [x] 🔴 **PrivacyInfo.xcprivacy** — đã thêm (`ios/Runner/PrivacyInfo.xcprivacy`,
  đăng ký vào target Runner, verify có mặt trong `.app` build ra). Nội dung ở
  mục 2.5 — vẫn nên đối chiếu domain tracking với tài liệu AdMob mới nhất.
- [x] 🔴 **GADApplicationIdentifier** — đã thay ID thật
  (`ca-app-pub-9748541552219348~3516109108`) trong `ios/Runner/Info.plist`.
- [x] 🔴 **Rewarded unit iOS** — đã thay ID thật
  (`ca-app-pub-9748541552219348/7263782428`) trong `lib/ads/ad_config.dart`.
- [x] 🟡 **iPhone-only** (đã quyết định) — `TARGETED_DEVICE_FAMILY = "1"` (3 chỗ
  trong `project.pbxproj`) + bỏ `UISupportedInterfaceOrientations~ipad` khỏi
  Info.plist. Khỏi cần screenshot/test iPad nữa.
- [x] 🟢 **ITSAppUsesNonExemptEncryption = false** — đã thêm vào Info.plist (app
  chỉ dùng HTTPS chuẩn → miễn khai export compliance mỗi lần nộp).

---

## 1. Tài khoản & App Store Connect

- [ ] 🔴 **Apple Developer Program** — $99/năm, cần duyệt 24–48h. (Cá nhân hay
  Organization đều được; game này đang ký team `P3MPHWPJ62`.)
- [x] 🔴 **App ID** `com.pcingame.bobaempire` trong Certificates, IDs & Profiles
  → capability **In-App Purchase** đã bật.
- [x] 🔴 Tạo app trong **App Store Connect**: Platform iOS, tên `Đế Chế Trà Sữa`,
  primary language Vietnamese, bundle ID `com.pcingame.bobaempire`.
- [ ] 🟡 **App Store Connect API key** (nếu muốn upload bằng CI/Transporter CLI
  thay vì Xcode Organizer).

## 2. Cấu hình Xcode project

- [x] 🔴 **Signing** — `Automatically manage signing` bật, Team `Phuong Doan
  Thanh (P3MPHWPJ62)`, Bundle ID `com.pcingame.bobaempire`, provisioning profile
  Xcode Managed. (Certificate hiện là Apple Development — Xcode sẽ tự tạo Apple
  Distribution certificate lúc **Archive** cho App Store, không cần làm tay.)
- [x] 🔴 **Capability: In-App Purchase** — đã thêm trong Signing & Capabilities,
  không còn cảnh báo.
- [ ] 🟡 **Version / build** — `pubspec.yaml` đang `1.0.0+1`. Info.plist đọc
  `$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)` từ đây. ⚠️ pbxproj có
  hardcode `MARKETING_VERSION = 1.0` / `CURRENT_PROJECT_VERSION = 1` ở vài config
  — kiểm archive hiện đúng `1.0.0 (1)`; mỗi lần nộp phải **tăng build number**
  (`1.0.0+2`…), không được trùng.
- [ ] 🟡 **Bỏ NSAllowsArbitraryLoads nếu có** — Info.plist hiện KHÔNG có ATS
  ngoại lệ (tốt).
- [x] 🔴 **SKAdNetworkItems** — đã thêm đủ 50 ID từ trang chính thức Google
  (`developers.google.com/admob/ios/ios14`). Nên đối chiếu lại 1 lần trước khi
  nộp bản chính thức (Google có thể cập nhật thêm ID mới theo thời gian).
- [ ] 🟡 **Launch screen** — `LaunchScreen.storyboard`. Đảm bảo không giống
  splash/quảng cáo (Apple guideline 2.3.x); nền đơn giản + logo là được.

### 2.5. PrivacyInfo.xcprivacy — ✅ đã có

`ios/Runner/PrivacyInfo.xcprivacy` đã tạo + đăng ký vào target Runner (đã build
thử, xác nhận có trong `.app`). Nội dung hiện tại (AdMob + ATT + shared_preferences):

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

- [x] 🔴 Tạo **app iOS** trong AdMob (khác app Android) → lấy **App ID iOS**,
  thay vào `GADApplicationIdentifier` (Info.plist).
- [x] 🔴 Tạo **Rewarded ad unit iOS** → thay `_iosRewardedProd` trong
  `lib/ads/ad_config.dart`.
- [x] 🔴 **UMP / GDPR consent message** — đã tạo + publish trong AdMob → Privacy
  & messaging cho cả app Android + iOS:
  - **European regulations** (GDPR/EEA+UK+Switzerland) — template mặc định của
    Google, Privacy policy URL = `https://pcingame.github.io/boba_empire/privacy-policy.html`.
  - **US state regulations** (CCPA/CPRA) — template "My data preferences" mặc định.
  - **IDFA explainer** (chỉ app iOS) — pre-prompt "Our app wants to stay free
    for you" + nút "Continue" (không trùng nút hệ thống → an toàn guideline
    5.1.1(iv)), trigger popup ATT thật của iOS sau khi user bấm Continue.
- [ ] 🟡 **Verify trên máy thật/TestFlight** — xoá app cài lại, xem đúng thứ tự:
  GDPR message (nếu ở EEA) → IDFA explainer → popup ATT hệ thống thật (không
  chỉ dừng ở pre-prompt). `NSUserTrackingUsageDescription` đã có sẵn trong
  Info.plist.
- [ ] 🟡 Test bằng **AdMob test device ID** trên máy thật trước khi bật ID thật.
- [ ] 🟢 Liên kết AdMob ↔ App Store Connect (đo doanh thu).

## 4. In-App Purchase (App Store Connect — khác Play)

- [x] 🔴 Tạo **8 sản phẩm** trong App Store Connect → In-App Purchases — xong,
  ĐÚNG product ID (giống Play):

  | ID | Loại App Store | Ghi chú |
  |---|---|---|
  | `boba_gems_small` / `_medium` / `_large` | Consumable | gói 💎 |
  | `boba_remove_ads` | Non-Consumable | gỡ QC |
  | `boba_starter_pack` | Non-Consumable | 1 lần |
  | `boba_double_income` | Non-Consumable | x2 thu nhập vĩnh viễn |
  | `boba_piggy` | Consumable | đập heo |
  | `boba_vip30` | Consumable | ⚠️ "VIP 30 ngày" — Apple **có thể** yêu cầu đổi sang **Auto-Renewable Subscription**. Consumable không tự gia hạn thì được, nhưng chuẩn bị lý do (giống battle-pass mùa). |

- [x] 🔴 Mỗi sản phẩm: **Reference Name**, **Price**, **Display Name** +
  **Description** (tiếng Việt), **Review screenshot** — đã điền đủ cho cả 8
  sản phẩm, đều "Ready for Review". Lưu ý: Description IAP không nhận emoji,
  giới hạn ~55 ký tự — dùng chữ thuần + dấu tiếng Việt bình thường.
  ⚠️ Còn thiếu: **Description cho en/es/pt/id/th** (mới chỉ có vi) — nên bổ
  sung trước khi nhắm tới các thị trường đó, không bắt buộc để submit.
- [x] 🔴 **Sandbox tester** — đã tạo `phuongtdoan2008+test1@gmail.com` (Vietnam)
  trong Users and Access → Sandbox → Testers.
- [ ] 🟡 Test mua + **Khôi phục mua hàng** trên TestFlight/thiết bị thật (đăng
  nhập sandbox account trong Settings → App Store → Sandbox Account, hoặc
  đăng nhập ngay khi popup mua hàng hiện ra trong app).
- [x] 🔴 **Paid Apps agreement** — **Active** (Bank Account "Doan Thanh Phuong
  (2012)" VND/USD cũng Active). Đủ điều kiện tạo + bán IAP.
- [ ] 🟡 **Verify receipt server-side** — hiện client-only
  (`real_iap_service.dart`), dễ giả mạo. iOS dùng App Store Server API /
  `verifyReceipt`. Nên làm trước khi doanh thu lớn.
- [ ] 🟡 **Giá theo vùng** — hạ tier cho VN/ID/BR/TH (App Store tự đề xuất theo
  base price, kiểm lại).

## 5. App Privacy (nhãn dinh dưỡng) + tracking

- [x] 🔴 **App Privacy** trong App Store Connect — đã publish:
  - **Identifiers → Device ID**: Third-Party Advertising + Tracking purposes.
  - **Purchases → Purchase History**: App Functionality.
  - **Usage Data → Product Interaction**: Analytics.
  - Không khai thêm gì khác (không có Diagnostics/Crash SDK, không Contact
    Info/Location/Contacts/Photos — khớp đúng code, không có Firebase/Analytics
    package nào ngoài AdMob).
- [ ] 🟡 Đối chiếu khai báo với PrivacyInfo.xcprivacy + Data safety form bên Play
  (phải nhất quán).

## 6. Phân loại độ tuổi & nội dung

- [x] 🔴 **Age Rating questionnaire** (ASC — bản mới 2025, 7 bước) — đã hoàn tất:
  - In-App Controls (Parental Controls, Age Assurance): No.
  - Unrestricted Web Access / UGC / Social Media / Messaging: No. Advertising: Yes.
  - Mature Themes / Sexuality / Violence: None cho tất cả.
  - Simulated Gambling: **None** — vòng quay may mắn (`lib/ui/wheel_dialog.dart`)
    chỉ 1 lượt free/ngày hoặc xem QC để quay thêm, không tốn coin/gem/tiền thật
    → không có "wagering". Contests: None (không có leaderboard). Gambling
    (tiền thật) / Loot Boxes: No.
  - **Kết quả: 4+**. Age Category Override: Not Applicable (không chọn "Made
    for Kids" — khớp AdMob non-child-directed).

## 7. Assets & Store listing

- [ ] 🔴 **App Icon 1024×1024** (không alpha, không bo góc) —
  `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` đã có
  (flutter_launcher_icons + `remove_alpha_ios: true`). Kiểm không viền trắng.
- [x] 🔴 **Screenshots** — ASC "Prepare for Submission" chỉ yêu cầu 1 khung cỡ
  **1242×2688** (6.5"). Đã chụp đủ **10 ảnh** tiếng Việt bằng simulator
  "iPhone 11 Pro Max (6.5in)" (`xcrun simctl io <udid> screenshot`), lưu ở
  `assets/store/screenshots_ios/6.5in/`: home sáng, vòng quay may mắn, cửa
  hàng 💎, nhượng quyền/kho Sao, home dark mode, thành tựu, cách chơi, cốt
  truyện, dialog "Kiếm thêm", home stage 2 (theme xanh). Còn phải **kéo thả
  vào ASC** (chưa upload).
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

- [x] 🔴 `flutter build ipa --release` — thành công, `build/ios/ipa/*.ipa`
  (24.1MB), archive tại `build/ios/archive/Runner.xcarchive` (188.9MB). Cảnh báo
  không chặn: "Launch image is default placeholder" — app dùng
  `LaunchScreen.storyboard` riêng nên không ảnh hưởng thực tế, có thể bỏ qua.
- [x] 🔴 Upload qua **Apple Transporter app** — thành công (`UPLOAD SUCCEEDED
  with no errors`, 24MB, ~12.5s). Build ID `9cfa620c-...`, trạng thái server:
  **PROCESSING**.
- [ ] 🟡 Chờ **"Processing"** xong trong ASC (10–60 phút) → build hiện ở
  TestFlight. Kiểm lại tab TestFlight trong ASC.
- [ ] 🟡 Nếu bị **email cảnh báo** (ITMS-xxxx) về privacy manifest / SDK ký thiếu
  → sửa theo hướng dẫn rồi bump build, upload lại.
- [x] Build 1 (version 1.0.0) đã qua Processing → trạng thái **"Ready to
  Submit"** trong TestFlight.

## 10. TestFlight (khuyên trước Production)

- [x] 🟡 **Internal testing** — đã tạo group "Internal", thêm tester
  `phuongtdoan2008@gmail.com` (Account Holder), cài thành công build 1.0.0
  trên iPhone 15 Pro thật qua TestFlight.
- [ ] 🟢 **External testing** — cần Apple review (1 lần, ~1 ngày) → mời tối đa
  10.000 người qua link công khai.
- [~] 🟡 Trên TestFlight: **bỏ qua** (quyết định của dev, chấp nhận rủi ro Apple
  reviewer có thể gặp bug IAP lúc duyệt → reject nếu có lỗi). Nên test sau khi
  build được duyệt, trước khi release rộng.

## 11. Nộp duyệt (Submit for Review)

- [x] 🔴 Điền đủ: build, screenshots, listing (vi), App Privacy + Privacy Policy
  URL, Age Rating, Price tier (Free), Category (Games), Content Rights, 8 IAP
  kèm build.
- [x] 🔴 **App Review Information** — Sign-in: No. Notes for Reviewer đã điền
  (idle offline, rewarded ads không ép xem, IAP vật phẩm ảo, vòng quay không
  bán bằng tiền thật). Contact info đã điền.
- [x] **Đã "Add for Review" thành công — trạng thái "Waiting for Review".**
- [x] 🔴 **ITMS-91064 (rejected)** — `PrivacyInfo.xcprivacy` khai
  `NSPrivacyTracking=true` nhưng `NSPrivacyTrackingDomains` rỗng → không nhất
  quán. Fix: app-level không tự gọi network tới domain tracking (AdMob SDK tự
  có manifest riêng cho việc đó) → đổi `NSPrivacyTracking` thành `false`. Build
  `1.0.0+2` đã build + upload thành công (`UPLOAD SUCCEEDED`), đang PROCESSING.
- [x] 🔴 Build 2 hết Processing → "remove this version from review" → đổi
  chọn build 2 → **"Add for Review"** lại → trạng thái **"Waiting for
  Review"**. Đã nộp lại thành công.
- [ ] 🟡 **Version release**: kiểm đã chọn "Manually release" hay "Automatically
  after approval" — xem lại nếu muốn đổi trước khi được duyệt.
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

---

## Lưu ý quan trọng (đúc kết từ lần nộp thực tế, 2026-09)

- **Screenshot size**: ASC hiện chỉ bắt khung **6.5" (1242×2688)** cho "Prepare
  for Submission" — không cần 6.9" nữa (kiểm lại tiêu đề khung upload mỗi lần
  vì Apple có thể đổi yêu cầu theo thời gian). Chụp bằng simulator
  `iPhone 11 Pro Max` + `xcrun simctl io <udid> screenshot`. Đủ 3-10 ảnh, không
  cần đúng 10 — nhưng nếu ASC báo "cần 10" thì làm đủ.
- **Support URL / Marketing URL / Promotional Text / Description / Keywords**:
  nằm ở trang **App Store → "1.0 Prepare for Submission"** (version cụ thể),
  KHÔNG nằm ở "App Information" (trang đó chỉ có tên app, bundle ID, category,
  age rating, content rights).
- **Promotional Text / IAP Description không nhận emoji và dấu gạch ngang dài
  "—"** → dùng chữ thuần + dấu câu cơ bản (dấu tiếng Việt có dấu vẫn được).
  IAP Description giới hạn ngắn (~45-55 ký tự tuỳ thời điểm).
- **Copyright field** cũng có thể từ chối ký tự `©` — dùng dạng chữ
  `2026 Tên Bạn` thay vì `© 2026 Tên Bạn`.
- **Paid Apps Agreement** cần làm theo đúng thứ tự: **Legal Entity** → **DSA
  trader compliance** (Business → Compliance, bắt buộc nếu bán ở EU) → ký
  **Paid Apps Agreement** → điền **Bank Account** + **Tax Forms** (W-8BEN cho
  cá nhân ngoài Mỹ + "Certificate of Foreign Status" — 2 form riêng biệt, cả 2
  phải Active). Bank Account "Processing" vài phút tới vài ngày mới Active.
- **Nộp 8 IAP cùng bản build đầu tiên**: KHÔNG dùng nút "Submit for Review"
  riêng lẻ trên từng sản phẩm khi app chưa có bản build nào (báo lỗi "Unable to
  Submit — add an app version"). Cách đúng: gắn build vào version trước, rồi
  vào **Monetization → In-App Purchases** → tick chọn tất cả → **Add for
  Review** (nút này tự gộp vào submission của version hiện tại).
- **"Add for Review" của app version** sẽ liệt kê rõ **tất cả field còn thiếu**
  (Privacy Policy URL trong App Privacy, Copyright, Content Rights Information,
  Price tier trong Pricing, Primary Category) — cứ bấm thử để ASC tự chỉ ra,
  đỡ phải đoán.
- **Content Rights Information**: chọn "No, it does not contain/show/access
  third-party content" nếu asset (hình, âm thanh) là tự làm/mua bản quyền,
  không phải nội dung xin phép bên thứ ba.
- **In-App Purchase capability trong Xcode**: chỉ cần bật ở App ID
  (developer.apple.com) là đủ để code chạy; Xcode có thể không hiện khối
  riêng trong Signing & Capabilities ngay lập tức, nhưng khi Archive xong,
  `project.pbxproj` sẽ tự link thêm `StoreKit.framework` — đó là bằng chứng
  capability đã được áp dụng đúng.
- **Simulator không test được mua IAP thật** — `loadPrices()` trả rỗng nên nút
  mua tự ẩn (xem `lib/ui/gem_shop.dart`). Phải dùng **Sandbox tester** trên
  thiết bị thật hoặc TestFlight để thấy nút mua + test luồng StoreKit.
- **SKAdNetwork list** lấy qua công cụ fetch tự động có rủi ro nhỏ sai lệch —
  nên đối chiếu lại 1 lần thủ công với trang Google trước khi nộp bản chính
  thức, vì danh sách có thể được cập nhật thêm theo thời gian.
- **ITMS-91064 (Invalid tracking information)** — Apple reject build vì
  `PrivacyInfo.xcprivacy` khai `NSPrivacyTracking = true` nhưng
  `NSPrivacyTrackingDomains` rỗng (2 trường này phải nhất quán trong CÙNG 1
  manifest). Vì app không tự gọi network tới domain tracking nào — mọi
  request quảng cáo/tracking nằm trong SDK Google Mobile Ads (SDK đó tự có
  manifest riêng khai domain của chính nó, Apple gộp mọi manifest lại khi
  build) — nên **app-level phải khai `NSPrivacyTracking = false`**, không phải
  thêm domain giả vào cho đủ. Đây là lỗi dễ mắc nếu copy template có sẵn
  `NSPrivacyTracking=true` mà không thực sự điền domain.
- **Sau khi build bị reject (ITMS-xxxx qua email)**: sửa lỗi → **tăng build
  number** trong `pubspec.yaml` (vd `1.0.0+1` → `1.0.0+2`, Apple không nhận
  build trùng số) → `flutter build ipa --release` → upload lại qua Transporter.
  Chờ build mới hết **Processing** (nhận mail TestFlight báo "ready to test")
  → quay lại trang version, bấm link **"remove this version from review"**
  (banner xanh) để mở khoá chỉnh sửa → đổi mục **Build** sang build mới →
  bấm lại **"Add for Review"**. Không cần điền lại metadata/screenshots/IAP,
  chỉ cần đổi build.
