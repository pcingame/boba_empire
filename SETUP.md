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

**Test trên máy thật với bản release mà không bơm traffic vào tài khoản:**
đăng ký máy của bạn làm *test device* — máy đó nhận quảng cáo test dù build
release đang dùng unit id thật:

```
flutter run --release --dart-define=ADMOB_TEST_DEVICES=<id1>,<id2>
```

Device ID lấy từ log SDK ở lần chạy đầu (Android logcat: *"setTestDeviceIds"*;
iOS console: *"To get test ads on this device, set testDeviceIds"*). Tài khoản
AdMob mới mà ít thiết bị lặp lại một máy rất dễ bị đưa vào **Limited ad
serving** (fill rate tụt, Google tự review lại theo thời gian) — nên đừng test
ads bằng unit id thật trên máy mình.

⚠️ **Không phát hành khi còn TEST ID** — bấm quảng cáo thật trên test unit là vi
phạm chính sách; nhưng dùng ID thật khi phát triển cũng dễ bị khoá. Chỉ đổi sang
ID thật ở bản release.

---

## 2. In-app purchase (mua bằng tiền thật)

Product ID phải **khớp** hằng trong `lib/iap/iap_products.dart`:

| Product ID          | Loại            | Trao gì (`Balance`)         |
| ------------------- | --------------- | --------------------------- |
| `boba_gems_small`   | Consumable      | +`iapGemsSmall` (100) 💎     |
| `boba_gems_medium`  | Consumable      | +`iapGemsMedium` (600) 💎    |
| `boba_gems_large`   | Consumable      | +`iapGemsLarge` (1300) 💎    |
| `boba_remove_ads`   | Non-consumable  | bật `adsRemoved`            |
| `boba_starter_pack` | Non-consumable  | +`iapStarterGems` (300) 💎, một lần |

### Android (Play Console)
1. Tạo app, **Monetize → Products → In-app products / Subscriptions**, thêm 5
   product với đúng ID trên, đặt giá (xem [Giá đề xuất](#gia-de-xuat)).
2. Upload một bản build (internal testing) — IAP chỉ hoạt động với app đã ký &
   đúng applicationId, cài qua Play.
3. Thêm **License testers** (Play Console → Setup → License testing) để mua thử
   không mất tiền.

### iOS (App Store Connect)
1. Tạo 5 In-App Purchase với cùng product ID, điền metadata + giá.
2. Test bằng **Sandbox tester**.

### Giá đề xuất {#gia-de-xuat}

App **miễn phí** (free-to-play + ads + IAP). Mốc giá gốc (USD):

| Product | Giá gốc | Vai trò |
| --- | --- | --- |
| `boba_starter_pack` | **$0.99** | "Mồi" chuyển đổi lần mua đầu — rẻ, giá trị rõ (300 💎). |
| `boba_gems_small` | **$0.99–$1.99** | Gói gems nhỏ nhất (100 💎). |
| `boba_gems_medium` | **$4.99** | 600 💎 (đã tính bonus theo giá). |
| `boba_gems_large` | **$9.99** | 1300 💎 (bonus cao hơn → đẩy lên gói to). |
| `boba_remove_ads` | **$2.99** (hoặc $1.99) | Trụ doanh thu ổn định nhất ở game casual. |

**Giá theo vùng (quan trọng với tier-2):** cả Play lẫn App Store cho đặt giá từng
nước. ĐỪNG để chỉ quy đổi tỷ giá — **hạ giá ở thị trường sức mua thấp**
(Indonesia/Brazil/Thái/Việt) thì chuyển đổi tốt hơn. Lấy giá gợi ý local của
store làm mốc rồi **giảm ~20–40%**, làm tròn số đẹp. Tham khảo (remove-ads /
starter): 🇮🇩 ~Rp 39.000 / Rp 9.000 · 🇧🇷 ~R$ 9,90 / R$ 2,90 · 🇹🇭 ~฿69 / ฿19 ·
🇻🇳 ~49.000đ / 15.000đ.

**Neo giá:** bonus % gems tăng dần theo bậc (600 ở $4.99 "lời" hơn 100 ở $0.99)
để đẩy người chơi lên gói cao. Chỉnh số 💎 mỗi bậc ở `Balance.iapGems*`.

### ⚠️ Xác thực biên nhận (bảo mật)
Đã có **skeleton backend** ở `server/` (Dart shelf) và wiring client sẵn:
`RealIapService` gọi `ReceiptVerifier` TRƯỚC khi trao thưởng
(`lib/iap/real_iap_service.dart` → `_onPurchases`).

- Mặc định `NoopReceiptVerifier` (client-only như cũ) khi chưa cấu hình endpoint.
- Bật xác thực server: build app với
  `--dart-define=IAP_VERIFY_ENDPOINT=https://<server>/verify` → dùng
  `HttpReceiptVerifier`. Chính sách **fail-open**: chỉ chặn khi server trả
  `200 {"valid": false}`; lỗi mạng/timeout vẫn trao (ưu tiên người mua thật).
- Server: `server/README.md` hướng dẫn chạy dev (`VERIFY_MODE=dev` chấp nhận mọi
  biên nhận để test wiring) và bật prod (Google Play / App Store) qua biến môi
  trường. Việc CÒN THIẾU cho production: chống replay (lưu orderId/transaction_id
  đã trao), acknowledge/consume Play, chuyển App Store Server API cho StoreKit 2.

---

### Banner (Hành trình Ghép 3)

Banner chỉ hiện ở tab **Ghép 3** (danh sách màn + màn chơi), KHÔNG hiện trong
Đấu Trường (trận 60 giây, chạm nhầm là thua) và tự ẩn khi người chơi đã mua
"Gỡ quảng cáo" hoặc đang VIP.

1. AdMob → app Android và app iOS → tạo **Banner ad unit** cho mỗi bên.
   - ✅ iOS: xong 2026-09-28 (`.../7009859888`, app id `~3516109108`).
   - ✅ Android: xong 2026-09-28 (`.../6714171401`, app id `~2417193584`).
2. Điền vào `lib/ads/ad_config.dart` → `_androidBannerProd`, `_iosBannerProd`.
   **Để rỗng là bản release KHÔNG hiện banner** — cố tình như vậy, an toàn hơn
   nhiều so với lỡ phát hành kèm test id (Google coi là vi phạm).
   ⚠️ Dán nhầm **App ID** (có dấu `~`) vào chỗ **unit id** (có dấu `/`) là lỗi
   im lặng: quảng cáo không bao giờ tải mà chẳng báo gì. Có test khoá việc này.
3. Bản debug luôn dùng test id, không cần làm gì.
4. **Tần suất làm mới: 90 giây** (chốt 2026-09-28). Đặt trong console, KHÔNG có
   trong code — AdMob → Apps → chọn app → Ad units → chọn banner unit → Edit →
   *Automatic refresh* → 90 seconds. Phải đặt cho **cả hai** app (Android và
   iOS); mặc định của unit mới là 60 giây.
   - [ ] Android `.../6714171401`
   - [ ] iOS `.../7009859888`

   App KHÔNG tự tải lại banner bằng timer (tự gọi lại liên tục bị Google tính là
   invalid traffic) — mỗi lần mở màn chỉ tải 1 lần, còn nhịp làm mới sau đó do
   AdMob quyết định theo thiết lập trên.

⚠️ Mọi chỗ đụng SDK quảng cáo phải chờ `AdBootstrap.ready` (Future của lần init
do `main()` gán). Gọi sớm hơn thì kênh nền tảng trả null và **im lặng** thất bại
— đã gặp: mở thẳng vào tab Ghép 3 lúc app vừa mở thì banner không bao giờ hiện
cả phiên, không có log lỗi nào.

## 2b. Firebase Remote Config (tune số không cần nộp bản mới)

12 nút vặn cân bằng có thể ghi đè từ console — tên tham số trên console **đúng
bằng tên field** trong `lib/core/balance.dart`, khoảng hợp lệ khai báo ở
`lib/data/remote_balance.dart` (gõ ngoài khoảng thì app BỎ QUA, giữ số biên dịch
sẵn — cố tình như vậy để một số 0 gõ nhầm không phá save người chơi).

1. Firebase Console → project của app → **Remote Config** → *Create configuration*.
2. Thêm tham số, kiểu **Number**, tên lấy từ danh sách dưới. Không cần thêm đủ —
   thiếu cái nào thì cái đó dùng giá trị trong app.
3. *Publish changes*. App lấy bản mới ở lần mở kế tiếp (cache 1 giờ), và áp ngay
   trong phiên đó.

| Tham số | Đang là | Khoảng hợp lệ | Ảnh hưởng |
|---|---|---|---|
| `prestigeK` | 0.02 | 0.001 – 0.05 | Tốc độ tích Sao. **Trần 0.05 là ràng buộc của trigger chống gian lận trên Supabase** — vượt là mọi người chơi bị server từ chối |
| `milestoneStep` | 50 | 5 – 500 | Bao nhiêu cấp thì nguồn thu ×2. Công thức tăng nhanh nhất cả game |
| `milestoneFactor` | 2.0 | 1.1 – 5 | Hệ số mỗi mốc |
| `bonusPerStar` | 0.02 | 0.0001 – 1 | +% thu nhập mỗi Sao |
| `milestoneGlobalBonus` | 0.03 | 0 – 1 | +% thu nhập toàn cục mỗi "mốc vàng" |
| `maxOfflineSeconds` | 28800 | 1800 – 604800 | Trần tiền offline (giây) |
| `catSpawnMinMs` / `catSpawnMaxMs` | 180000 / 300000 | 10s – 60p | Nhịp mèo Mưa vàng |
| `vipSpawnMinMs` / `vipSpawnMaxMs` | 240000 / 420000 | 10s – 60p | Nhịp khách VIP |
| `dailyQuestRewardGems` | 8 | 0 – 200 | 💎/nhiệm vụ ngày |
| `dailyQuestBonusGems` | 15 | 0 – 500 | 💎 thưởng xong cả 3 |
| `m3Moves` | 20 | 5 – 200 | Số nước mỗi màn Ghép 3 |
| `m3TargetBase` | 900 | 50 – 100000 | Mục tiêu 1★ của màn 1 |
| `m3TargetGrowth` | 1.12 | 1.0 – 1.5 | Mục tiêu tăng bao nhiêu mỗi màn |
| `m3LevelCount` | 60 | 1 – 500 | Tổng số màn (màn sinh bằng công thức) |
| `m3ThreeStarGems` | 3 | 0 – 100 | 💎 thưởng lần đầu đạt 3★ một màn |
| `m3Star2Mult` | 1.25 | 1.0 – 5 | Mốc 2★ = bội này của mục tiêu 1★ |
| `m3Star3Mult` | 1.6 | 1.0 – 10 | Mốc 3★ = bội này của mục tiêu 1★ |
| `m3CollectEvery` | 3 | 0 – 20 | Cứ mấy màn thì có 1 màn "thu thập" (0 = tắt) |
| `m3CollectBase` | 12 | 3 – 500 | Số ô cần thu ở màn thu thập đầu tiên |
| `m3CollectGrowth` | 1.1 | 1.0 – 1.3 | Số ô cần thu tăng bao nhiêu mỗi màn thu thập |

Chưa bật Remote Config trên console cũng không sao: fetch lỗi thì app giữ nguyên
số biên dịch sẵn (có log `RemoteBalance`).

## 2c. Thông báo nhắc quay lại

Không cần console nào cả — thông báo **cục bộ** (`lib/notify/reminders.dart`),
đặt lịch lúc app chuyển nền, xoá khi mở lại. Hai mốc: kho Xu offline đầy, và
sang ngày mới (dời sang 10 giờ sáng giờ máy nếu nửa đêm UTC rơi vào đêm).

- Quyền hỏi ở **lần quay lại app đầu tiên**, không hỏi lúc mở app lần đầu (màn
  mở app đã có ATT + form đồng ý quảng cáo).
- Android cần `isCoreLibraryDesugaringEnabled` + 2 receiver trong manifest — đã
  cấu hình sẵn. Dùng alarm KHÔNG chính xác (cửa sổ ±1h) để khỏi phải xin quyền
  `SCHEDULE_EXACT_ALARM`; nhắc trễ vài chục phút không ảnh hưởng gì.
- iOS: chưa cho quyền thì hệ thống **im lặng bỏ qua** lịch hẹn (đã kiểm trên
  simulator) — nên đừng bỏ bước xin quyền.

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
