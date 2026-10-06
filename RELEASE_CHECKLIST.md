# RELEASE CHECKLIST — đẩy Boba Empire lên store

Danh sách việc để phát hành. Ưu tiên **Android (Google Play)** trước; việc riêng
**iOS / App Store** ở [IOS_APP_STORE_CHECKLIST.md](IOS_APP_STORE_CHECKLIST.md).
Xem chi tiết ads/IAP ở [SETUP.md](SETUP.md), nội dung listing ở
[STORE_LISTING.md](STORE_LISTING.md).

Ký hiệu: 🔴 chặn phát hành · 🟡 nên làm · 🟢 tùy chọn/sau.

---

## 0. Chặn phát hành — phát hiện trong repo (làm trước tiên)

- [x] 🔴 **Đổi applicationId** → `com.pcingame.bobaempire` (đã đổi cả namespace +
  di chuyển MainActivity, build APK verify OK). ⚠️ ĐỪNG đổi lại sau khi phát hành.
- [x] 🔴 **Tạo keystore ký release** — ĐÃ XONG: keystore tại
  `C:/Users/24h/keys/boba-upload.jks` (alias `upload`), `android/key.properties`
  đã điền (gitignore). Verify: `.aab` ký bằng `CN=Doan Thanh Phuong` (không phải
  debug). ⚠️ Backup file .jks + nhớ mật khẩu; bật Play App Signing khi tạo app.
- [x] 🔴 **Icon app thật** — cốc trà sữa cute, nền kem (assets/icon/, sinh bằng
  scripts/make_icon.py). Đã chạy flutter_launcher_icons → mipmap + adaptive icon.
- [x] 🟡 **Đổi label app** → `Boba Empire` (đã sửa AndroidManifest).
- [x] 🔴 **Thay AdMob TEST ID → ID thật** (xem SETUP.md mục 1). Bấm QC thật
  trên test unit = vi phạm chính sách. ✅ Android + ✅ iOS: App ID thật trong
  AndroidManifest (`~2417193584`) và Info.plist (`~3516109108`); rewarded +
  banner unit thật trong `ad_config.dart`, tách debug=test/release=thật.

---

## 1. Chuẩn bị code / build

- [x] 🟡 Đặt `version:` trong `pubspec.yaml` cho lần phát hành — hiện
  **`1.0.4+7`** (2026-09-29). App Store đang live `1.0.3` (từ 2026-09-27).
  Mỗi lần nộp phải tăng build number. Ghi chú "Có gì mới" 6 ngôn ngữ đã soạn
  sẵn ở [RELEASE_NOTES.md](RELEASE_NOTES.md).
- [ ] 🟡 Kiểm tra `targetSdk` đạt yêu cầu Play hiện hành (Google bắt buộc target
  API mới trong ~1 năm gần nhất). Đang dùng `flutter.targetSdkVersion` — chạy
  `flutter build appbundle` sẽ báo nếu thiếu.
- [x] 🟡 `flutter analyze` sạch + `flutter test` xanh — **582/582**
  (2026-09-29). 2 cảnh báo `avoid_print` còn lại nằm ở `server/`, không vào app.
- [ ] 🟢 Cân nhắc `flutter_launcher_icons` + `flutter_native_splash` để sinh
  icon/splash mọi độ phân giải từ 1 file.
- [ ] 🟢 Bật R8/shrink (mặc định có ở release) — kiểm APK size hợp lý.

## 2. Tài khoản & console

- [ ] 🔴 Đăng ký **Google Play Console** (phí $25 một lần).
- [ ] 🔴 Tạo app trong Play Console, chọn **Game**, miễn phí.
- [ ] 🟢 (iOS) Apple Developer Program ($99/năm) nếu định lên App Store.

## 3. AdMob (xem SETUP.md mục 1)

- [~] 🔴 Tạo tài khoản AdMob + app (✅ Android xong; iOS chưa).
- [~] 🔴 Tạo **Rewarded ad unit**, thay ID thật vào `lib/ads/ad_config.dart` +
  manifest + Info.plist. ✅ Android xong; ❌ iOS còn test.
- [ ] 🔴 Cấu hình **UMP / GDPR message** trong AdMob (Privacy & messaging) —
  code đã gọi ConsentForm, nhưng message phải tạo trong console.
- [ ] 🟡 Test bằng **test device ID** trước khi bật ID thật.
- [ ] 🟡 Liên kết AdMob ↔ Play Console (đo lường doanh thu).

## 4. In-app purchase (xem SETUP.md mục 2)

8 product ID cần khớp: `boba_gems_small/medium/large`, `boba_remove_ads`,
`boba_starter_pack`, `boba_double_income` (x2 thu nhập vĩnh viễn,
non-consumable, ~$2.99), `boba_piggy` (đập heo, **consumable**, ~$1.99),
`boba_vip30` (VIP Pass 30 ngày, **consumable**, ~$4.99). Giá gốc theo mục
"Giá đề xuất".

- [x] 🔴 **iOS (App Store Connect):** tạo đủ 8 product — xong 2026-09-29,
  xác nhận qua ảnh chụp console: cả 8/8 **Approved**, product ID khớp
  đúng `iap_products.dart`. ⚠️ CHƯA XÁC NHẬN: giá theo vùng đã bật chưa.
- [ ] 🔴 **Android (Play Console):** tạo đủ 8 product — CHƯA làm, đợi
  Play Store được publish (mục 9).
- [ ] 🔴 Bật giá **theo vùng** (hạ cho ID/BR/TH/VN — SETUP.md) — cả 2 nền
  tảng.
- [ ] 🔴 Upload 1 build lên **internal testing** (Play) — IAP chỉ chạy với
  app đã ký & cài qua Play.
- [x] 🔴 **Sandbox tester (iOS)** — tạo xong 2026-09-30, mua thử thật qua
  Cửa hàng 💎 (boba_gems_small/starter_pack/gems_large), 💎 cộng đúng.
- [ ] 🔴 **License testers (Play)** — chưa làm, đợi Play publish.
- [x] 🟡 **Verify receipt server-side** — **ĐÃ DEPLOY THẬT VÀ XÁC THỰC
  THÀNH CÔNG**, không còn là code chưa kiểm chứng:
  - 2026-09-30: tạo khoá App Store Server API thật (Key ID `4X2ARF43Q4`),
    test qua server cục bộ + đường hầm cloudflared trước — 6/6 yêu cầu
    `200`, 💎 cộng đúng.
  - 2026-09-30: **deploy thật lên Cloud Run**
    (`bobaempire-1f372`/`asia-southeast1`, cùng project Firebase sẵn có),
    khoá riêng App Store lưu ở **Secret Manager** (không phải biến môi
    trường trần). URL:
    `https://boba-receipt-server-411559711815.asia-southeast1.run.app`.
    Build app trỏ thẳng vào URL này, mua Sandbox lại lần nữa — 4/4 yêu cầu
    `200`, ~1.4-1.6s/yêu cầu (đúng round-trip thật tới Apple), 💎 cộng
    đúng. **Đã set Budget Alert $1** trên billing account phòng phát sinh
    phí ngoài dự kiến.
  - App Store Server API (không phải `verifyReceipt` cũ) đã xác nhận hoạt
    động đúng với plugin StoreKit 2 đang dùng, cả cục bộ lẫn trên Cloud Run.

  - [x] **Chặn phát lại consumable — BỀN, đã xác nhận 2026-09-30.** Chạy
    `iap_replay_schema.sql` xong, service role key lưu Secret Manager
    (không phải biến môi trường trần), Cloud Run redeploy → log xác nhận
    `replay=SupabaseReplayStore` (không còn `InMemoryReplayStore`). Kiểm
    trực tiếp ràng buộc UNIQUE trên bảng thật: ghi 1 dòng → `201`, ghi lại
    ĐÚNG (source, transaction_id) đó → `409` (bị chặn đúng), đã dọn dòng
    test. An toàn dù service scale nhiều instance (`--max-instances=2`).

  ⚠️ Còn lại trước khi mở cho người dùng thật (KHÔNG phải test):
  - [ ] Tạo service account Play (quyền *View financial data*) — lấy JSON,
    thêm biến `PLAY_SERVICE_ACCOUNT_JSON`/`ANDROID_PACKAGE_NAME` khi Play
    publish.
  - [ ] Build app **bản release** (không phải debug) với
    `--dart-define=IAP_VERIFY_ENDPOINT=https://boba-receipt-server-411559711815.asia-southeast1.run.app/verify`
    trước khi nộp store — bản debug hiện tại trỏ đúng URL này nhưng chỉ
    dùng để test.

## 5. Assets & store listing

- [x] 🔴 **Icon** 512×512 (Play) + adaptive icon Android — có
  `assets/icon/playstore_icon_512.png` (upload lên Play) + adaptive icon đã sinh.
- [x] 🔴 **Feature graphic** 1024×500 (Play bắt buộc) — `assets/store/feature_graphic.png`
  (sinh bằng scripts/make_feature.py).
- [x] 🔴 **Screenshot** — 6 ảnh 1080×2160 (2:1, hợp lệ Play, đã bỏ status bar)
  ở `assets/store/screenshots/`: home sáng, điểm danh, cửa hàng 💎, kho Sao,
  thành tựu, home tối. Chụp từ máy thật, tiếng Việt, UI claymorphic mới (font
  Baloo 2 + màu theo stage). Chụp lại bằng seed+adb khi UI đổi.
- [x] 🔴 **Screenshot iPad** — 36 ảnh (6 màn × 6 ngôn ngữ) ở
  `assets/store/screenshots/ipad/`, 2064×2752 (đúng cỡ iPad 13" App Store đòi).
  Sinh lại bằng `./scripts/shoot.sh <udid> all` khi UI đổi — KHÔNG chụp tay.
  ⚠️ Bắt buộc từ bản có iPad trở đi: App Store Connect chặn nộp app universal
  nếu thiếu bộ ảnh iPad.
- [ ] 🔴 **Store listing** (tên/mô tả ngắn/mô tả đầy đủ) — dán từ
  STORE_LISTING.md, cho từng ngôn ngữ (vi/en/pt/es/id/th).
- [ ] 🟡 Nhờ **người bản ngữ soát** bản dịch in-app + listing.
- [ ] 🟢 Video trailer (tăng chuyển đổi, không bắt buộc).

## 6. Chính sách & pháp lý

- [~] 🔴 **Privacy Policy** (URL công khai) — bắt buộc vì có ads + IAP. NỘI DUNG
  XONG: `PRIVACY_POLICY.md` + `docs/privacy-policy.html` (song ngữ Việt–Anh, dev
  pcingame, liên hệ phuongtdoan2008@gmail.com). CÒN LẠI: host lấy URL (bật GitHub
  Pages cho /docs → https://pcingame.github.io/boba_empire/privacy-policy.html)
  rồi dán URL vào Play Console (App content → Privacy policy) + AdMob.
- [ ] 🔴 **Data safety form** (Play): khai AdMob thu thập Ad ID, v.v.
- [ ] 🔴 **Target audience & content**: khai **13+** (General, KHÔNG child-directed
  — đúng cấu hình hiện tại; xem SETUP.md mục 3).
- [ ] 🔴 **Ads declaration**: có quảng cáo → "Yes".
- [ ] 🔴 **Content rating** (bảng câu hỏi IARC trong Play Console).
- [ ] 🟡 (iOS) App Privacy + `NSUserTrackingUsageDescription` (đã có trong plist).

## 7. Ký & build release {#6-ký--build-release}

- [x] 🔴 Tạo keystore → `C:/Users/24h/keys/boba-upload.jks` (alias `upload`).
- [x] 🔴 `android/key.properties` đã điền (gitignore) — verify `.aab` ký bằng
  key thật (`CN=Doan Thanh Phuong`).
- [x] 🔴 `signingConfigs.release` trong `build.gradle.kts` đã đọc từ
  key.properties (có file → ký release, không → debug). Không cần sửa gradle nữa.
- [ ] 🔴 Bật **Play App Signing** khi tạo app (Google giữ khóa ký cuối; bạn giữ
  upload key).
- [x] 🔴 Build bundle: `flutter build appbundle --release` → `.aab` (ký release
  OK; rebuild lại khi bump version/đổi asset).
- [ ] 🟢 (iOS) `flutter build ipa` (cần macOS + Xcode + chứng chỉ).
  - **Lệnh chuẩn (từ 1.0.8):** `flutter build ipa --release --export-options-plist=ios/ExportOptions.plist --dart-define=IAP_VERIFY_ENDPOINT=https://boba-receipt-server-411559711815.asia-southeast1.run.app/verify`
    — `ios/ExportOptions.plist` tắt `uploadSymbols` + `manageAppVersionAndBuildNumber` để ipa "trơn".
  - ⚠️ **1.0.8 (21): Transporter báo "Processing failed"** với ipa mặc định của Flutter (có thư mục `Symbols/`,
    Xcode tự quản build number); **Xcode Organizer → Validate App → Distribute thì thành công**. Chưa xác định
    được nguyên nhân (không có email lý do). Cảnh báo "Upload Symbols Failed … GoogleMobileAds/UserMessagingPlatform"
    là BÌNH THƯỜNG (Google không kèm dSYM), không phải lỗi.
  - **Trước khi dán ipa vào Transporter:** mở `build/ios/archive/Runner.xcarchive` → Organizer → **Validate App**
    (không upload gì, báo lỗi `ITMS-…` cụ thể). Hoặc Transporter bấm **Verify** trước **Deliver**. Nếu vẫn "Processing
    failed" thì xem email Apple (cả Spam) lấy mã lỗi; cách chắc chắn nhất là Organizer → Distribute App.

## 7b. Schema Supabase (chỉ khi bản nộp có đổi SQL)

- [x] 🔴 **1.0.4:** `supabase/leaderboard_schema.sql` — cột `prestige_stars`
  bigint → `numeric`. Đã chạy 2026-09-29, verify bằng REST: 0 hàng còn kẹt
  `9223372036854775807`, 77 hàng đã dựng lại (giá trị lớn nhất 2,14e32 — bigint
  không chứa nổi ⇒ cột đúng là numeric).
- ⚠️ Quy tắc: schema phải chạy **TRƯỚC** khi bản mới lên store. Ngược lại thì
  client gửi số kiểu mới mà server còn kiểu cũ → Postgres từ chối, người chơi
  cuối tuyến không nộp được điểm.

## 8. Test trước khi phát hành

- [ ] 🔴 Cài **bản release đã ký** lên thiết bị Android thật, chơi thử end-to-end.
- [ ] 🔴 Test **mua IAP thật** qua license tester (cả 5 product + Khôi phục).
- [ ] 🔴 Test **quảng cáo thưởng** hiển thị + trao thưởng (test device ID).
- [ ] 🟡 Test **đổi ngôn ngữ máy** (6 ngôn ngữ) không vỡ layout.
- [ ] 🟡 Test **dark mode** trên máy thật.
- [ ] 🟡 Test lifecycle: thoát app → mở lại nhận tiền offline; kill app → save.
- [ ] 🟢 Chạy qua **Play Console → Pre-launch report** (test tự động nhiều máy).

## 9. Phát hành

- [ ] 🟡 Internal testing → Closed testing (Play yêu cầu 1 giai đoạn test kín với
  vài tester trước Production đối với tài khoản cá nhân mới).
- [ ] 🔴 Điền đủ **Main store listing + Content rating + Data safety + Target
  audience + Ads** (Play chặn nếu thiếu).
- [ ] 🔴 Tạo **Production release**, upload `.aab`/`.ipa`, dán release notes
  từ [RELEASE_NOTES.md](RELEASE_NOTES.md) (đã soạn 6 ngôn ngữ, đều < 500 ký tự
  nên dùng chung được cho cả Play lẫn App Store).
- [ ] 🟡 Chọn **quốc gia phát hành** (ưu tiên VN + 5 thị trường đã localize).
- [ ] 🟢 Chọn **staged rollout** (vd 20%) để theo dõi crash trước khi 100%.
- [ ] 🟡 Sau phát hành: theo dõi **Crashlytics/ANR, doanh thu ads/IAP, retention**;
  cân bằng lại kinh tế nếu cần.

---

## Ước lượng đường tới hạn (critical path)

1. Đổi applicationId + label + icon → 2. Tạo keystore + signing → 3. AdMob/IAP ID
thật + tạo product → 4. Privacy policy + các form Play → 5. Screenshot + listing →
6. Build `.aab` ký release → 7. Internal/closed test → 8. Production.

> Điểm dễ quên nhất: **verify receipt server-side** (bảo mật IAP) và **giá theo
> vùng** cho thị trường tier-2 — hai thứ ảnh hưởng trực tiếp doanh thu.
