# Tech Stack

Liệt kê những gì THẬT SỰ đang chạy — không phải danh sách mong muốn. Cập nhật
tại chỗ khi thêm/bỏ một thành phần, đừng để lệch với `pubspec.yaml`.

## Client — Flutter/Dart

- **Flutter** (SDK `^3.10.4`), build cho **Android + iOS** (desktop/web chạy
  được để phát triển — ads/IAP dùng bản giả lập, không có SDK thật).
- **State**: `flutter_riverpod` (bản 3, `Notifier`/`NotifierProvider`,
  `.select()`) — một `GameController` tick 1 giây phát ra `GameSnapshot` bất
  biến, UI chỉ đọc qua `.select()` để tránh rebuild thừa.
- **Lưu cục bộ**: `shared_preferences` (autosave ~10s, JSON).
- **i18n**: `flutter_localizations` + codegen từ ARB
  (`lib/l10n/app_*.arb` → `l10n.yaml`) — 6 ngôn ngữ: vi (gốc)/en/es/id/pt/th.
- **Hoạt hình/âm thanh**: `lottie` (hoạt hình vector), `flame_audio` (SFX).
- **Thông báo cục bộ**: `flutter_local_notifications` + `timezone` — nhắc
  quay lại (kho offline đầy, ngày mới, vắng 3/7 ngày), không cần server đẩy.
- **Nhắc cập nhật app**: `upgrader` (so version với store, tự hỏi có nâng cấp).

## Quảng cáo & mua hàng

- **`google_mobile_ads`** (AdMob) — banner (Trân Châu Rơi) + rewarded
  (+5 nước đi, x2 thưởng). UMP consent (GDPR/EEA) gọi qua `AdBootstrap`, không
  chặn frame đầu.
- **`in_app_purchase`** (qua `in_app_purchase_storekit` bản StoreKit 2 trên
  iOS) — 8 sản phẩm (`lib/iap/iap_products.dart`): 3 gói 💎, gỡ QC, x2 thu
  nhập, đập heo, VIP Pass, gói khởi động. Xác thực biên nhận qua backend
  riêng (xem "Backend xác thực IAP" bên dưới) — KHÔNG phải chỉ tin client.

## Backend — Firebase

Project chung: **`bobaempire-1f372`** (cũng chính là project Google Cloud bên
dưới — 2 mặt của 1 project).

- **Crashlytics** — báo crash, dSYM tự upload qua Run Script build phase
  (SPM không tự thêm như CocoaPods, xem `crashlytics-dsym-spm-path` memory).
- **Remote Config** — MỘT tham số JSON gộp (`boba_remote_config`, xem
  `lib/data/remote_balance.dart`) chỉnh 25 hằng số cân bằng + sự kiện giới
  hạn thời gian mà không cần nộp bản mới. Không dùng Firebase Analytics/FCM
  dù project có bật sẵn các API đó.

## Backend — Supabase (Postgres + Auth + REST, project `orphyhtnaaqfglytffkn`)

Client gọi thẳng qua `supabase_flutter`, không qua server trung gian (trừ
IAP). RLS bật ở mọi bảng, một số cho đọc công khai (bảng xếp hạng), một số
không cho ai đọc qua API ngoài chủ project (analytics, chặn phát lại IAP).

| Schema (`supabase/*.sql`) | Dùng cho |
|---|---|
| `arena_schema.sql` | Đấu Trường PvP 1v1 — replay verify server-side (`arena_compute_score`), match3 (`arena_m3_*`) |
| `arena_leaderboard_schema.sql` | Bảng xếp hạng tỉ lệ thắng Đấu Trường |
| `leaderboard_schema.sql` | Bảng xếp hạng chính (Xu cả đời + Sao) |
| `m3_leaderboard_schema.sql` | Bảng xếp hạng Trân Châu Rơi (tổng sao) |
| `story_speedrun_schema.sql` / `story_speedrun2_schema.sql` | Tốc độ hoàn thành cốt truyện Hồi 1 (Ch.18) / Hồi 2 (Ch.28) |
| `cloud_save_schema.sql` | Đồng bộ save qua email (Magic Link/OTP), optimistic concurrency (cột `version`) |
| `analytics_schema.sql` | Sự kiện chơi nhẹ (session length, phễu tiến trình) — ghi bằng `device_id`, không cần đăng nhập |
| `iap_replay_schema.sql` | Chặn phát lại giao dịch IAP consumable (UNIQUE constraint), chỉ server đọc/ghi |

**Auth**: `signInAnonymously()` cho Đấu Trường (không cần tài khoản permanent),
`signInWithOtp()` cho Cloud Save (email OTP, SMTP qua Resend). Gmail SMTP mặc
định của Supabase KHÔNG dùng (bị defer, xem `gmail-smtp-otp-deferral` memory).

## Backend — server xác thực IAP (`server/`, Dart thuần)

Không dùng Flutter — package Dart server-side riêng, deploy tách biệt.

- **`shelf`/`shelf_router`** — HTTP server, 1 endpoint `POST /verify`.
- **`googleapis_auth`** — service account JWT flow, gọi Google Play Developer
  API (`purchases.products.get/acknowledge/consume`).
- **`dart_jsonwebtoken`** — ký JWT ES256 gọi **App Store Server API**
  (`api.storekit.itunes.apple.com/inApps/v1/transactions/{id}`) — KHÔNG dùng
  `verifyReceipt` (StoreKit 1) cũ, đã xác nhận hỏng với JWS StoreKit 2 mà
  plugin hiện tại gửi lên.
- Chặn phát lại consumable qua bảng Supabase riêng (`iap_replay_schema.sql`),
  ghi bằng **service_role key** (bỏ qua RLS — bí mật server, không nhúng vào
  app).

## Hạ tầng & deploy

- **Google Cloud Run** (`asia-southeast1`, project `bobaempire-1f372`) — chạy
  server xác thực IAP, build từ `server/Dockerfile` (2 giai đoạn, `dart:stable`
  compile AOT) qua **Cloud Build** (`gcloud run deploy --source .`, không cần
  Docker cài cục bộ). Sống tại
  `boba-receipt-server-411559711815.asia-southeast1.run.app`.
- **Secret Manager** — khoá riêng App Store Server API + Supabase service_role
  key, không phải biến môi trường trần.
- **GitHub Pages** — landing page tĩnh (`bobaempiregame.com`), domain qua
  Namecheap.

## Phân phối

- **App Store Connect** — live (`1.0.3`), IAP 8/8 product Approved, đang chờ
  duyệt `1.0.4`.
- **Google Play Console** — CHƯA publish (kể cả closed testing).

## Test & tooling

- `flutter test` (80 file, 620+ ca, không cần thiết bị) + `flutter analyze`.
- `integration_test` — chụp ảnh màn hình store tự động (`scripts/shoot.sh`,
  6 ngôn ngữ × 6 màn), test bố cục iPad thật trên máy ảo.
- `dart test` riêng cho `server/` (30 ca, mock HTTP, khoá EC test tự sinh).
- **Python** (`scripts/make_*.py`) — sinh icon/feature graphic/cảnh nền từ
  code, không phải asset vẽ tay.
- **Shell** (`scripts/*.sh`) — kiểm domain/DNS, chụp ảnh store.

## Cố tình KHÔNG dùng

- **CocoaPods** — Firebase tích hợp qua Swift Package Manager (bẫy: SPM không
  tự thêm build phase upload dSYM như CocoaPods, xem memory liên quan).
- **Firebase Analytics/FCM** — API có bật sẵn trên project nhưng không wire
  vào code; analytics tự viết nhẹ qua Supabase thay thế.
- **Docker cục bộ** — deploy qua Cloud Build đọc thẳng `Dockerfile`, không
  cần daemon Docker chạy trên máy dev.
