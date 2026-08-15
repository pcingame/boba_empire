# RELEASE CHECKLIST — đẩy Boba Empire lên store

Danh sách việc để phát hành. Ưu tiên **Android (Google Play)** trước; ghi chú iOS
ở cuối. Xem chi tiết ads/IAP ở [SETUP.md](SETUP.md), nội dung listing ở
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
- [~] 🔴 **Thay AdMob TEST ID → ID thật** (3 chỗ, xem SETUP.md mục 1). Bấm QC
  thật trên test unit = vi phạm chính sách. ✅ Android xong (App ID manifest +
  rewarded unit trong ad_config, tách debug=test/release=thật). ❌ iOS Info.plist
  còn test — chỉ cần khi phát hành iOS.

---

## 1. Chuẩn bị code / build

- [ ] 🟡 Đặt `version:` trong `pubspec.yaml` cho lần phát hành (hiện `1.0.0+1`).
  Mỗi lần nộp phải tăng build number (`+2`, `+3`...).
- [ ] 🟡 Kiểm tra `targetSdk` đạt yêu cầu Play hiện hành (Google bắt buộc target
  API mới trong ~1 năm gần nhất). Đang dùng `flutter.targetSdkVersion` — chạy
  `flutter build appbundle` sẽ báo nếu thiếu.
- [ ] 🟡 `flutter analyze` sạch + `flutter test` xanh (hiện 132/132).
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

- [ ] 🔴 Tạo **5 product** đúng ID: `boba_gems_small/medium/large`,
  `boba_remove_ads`, `boba_starter_pack`. Đặt giá theo mục "Giá đề xuất".
- [ ] 🔴 Bật giá **theo vùng** (hạ cho ID/BR/TH/VN — SETUP.md).
- [ ] 🔴 Upload 1 build lên **internal testing** (IAP chỉ chạy với app đã ký &
  cài qua Play).
- [ ] 🔴 Thêm **License testers** để mua thử không mất tiền.
- [ ] 🟡 **Verify receipt server-side** trước khi bán thật (hiện client-only, dễ
  bị giả mạo — điểm chèn trong `real_iap_service.dart`).

## 5. Assets & store listing

- [x] 🔴 **Icon** 512×512 (Play) + adaptive icon Android — có
  `assets/icon/playstore_icon_512.png` (upload lên Play) + adaptive icon đã sinh.
- [x] 🔴 **Feature graphic** 1024×500 (Play bắt buộc) — `assets/store/feature_graphic.png`
  (sinh bằng scripts/make_feature.py).
- [x] 🔴 **Screenshot** — 6 ảnh 1080×2160 (2:1, hợp lệ Play, đã bỏ status bar)
  ở `assets/store/screenshots/`: home sáng, điểm danh, cửa hàng 💎, kho Sao,
  thành tựu, home tối. Chụp từ máy thật, tiếng Việt, UI claymorphic mới (font
  Fredoka + màu theo stage). Chụp lại bằng seed+adb khi UI đổi.
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
- [ ] 🔴 Tạo **Production release**, upload `.aab`, viết release notes.
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
