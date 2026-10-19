# Tech Stack

Liệt kê những gì THẬT SỰ đang chạy — không phải danh sách mong muốn. Cập nhật
tại chỗ khi thêm/bỏ một thành phần, đừng để lệch với `pubspec.yaml`.
(Rà soát lần cuối: 2026-10-20, app `1.0.11+25`.)

## Client — Flutter/Dart

- **Flutter** 3.47 (SDK Dart `^3.10.4`), build cho **Android + iOS** (iOS tối
  thiểu 15.0). Desktop/web chạy được để phát triển — ads/IAP dùng bản giả lập.
- **State**: `flutter_riverpod` (bản 3, `Notifier`/`NotifierProvider`,
  `.select()`) — một `GameController` tick 1 giây phát ra `GameSnapshot` bất
  biến, UI chỉ đọc qua `.select()` để tránh rebuild thừa. Lõi mô phỏng
  (`lib/core/`) là Dart thuần, không import Flutter → test không cần thiết bị.
- **Lưu cục bộ**: `shared_preferences` (autosave ~10s, JSON, có sanitize khi
  nạp save để chống giá trị hỏng/overflow).
- **i18n**: `flutter_localizations` + `gen-l10n` từ ARB (`lib/l10n/app_*.arb`,
  mẫu `app_vi.arb`) — **7 ngôn ngữ**: vi (gốc)/en/es/id/ko/pt/th.
- **Hoạt hình/UI**: `lottie` (vector), emoji + `CustomPaint` tự vẽ (bản đồ chi
  nhánh, bầu trời/ban đêm, máy bay), font **Baloo 2** + **Mitr** (Thái) đóng
  gói trong app, `font_awesome_flutter`. Hiệu ứng có mức chất lượng theo máy
  (`EffectsQuality`/`device_tier` qua `device_info_plus`) và tôn trọng "giảm
  chuyển động" của hệ điều hành.
- **Âm thanh**: `flame_audio` (SFX).
- **Thông báo**: `flutter_local_notifications` + `timezone` (nhắc cục bộ: kho
  offline đầy, ngày mới, vắng 3/7 ngày, công thức) và `firebase_messaging`
  (FCM đẩy "món bán được"/"món muốn có" — xem Edge Function bên dưới).
- **Tiện ích nền tảng**: `share_plus` (chia sẻ cốc/bộ sưu tập), `url_launcher`,
  `package_info_plus`, `image_picker` (ảnh đại diện), `upgrader` (nhắc cập nhật
  theo version store), `http`.

## Quảng cáo & mua hàng

- **`google_mobile_ads`** (AdMob) — banner + rewarded (+nước đi, x2 thưởng,
  đánh boss thêm, tự chạm…). UMP consent (GDPR/EEA) qua `AdBootstrap`, phải
  `await AdBootstrap.ready` trước khi đụng SDK.
- **`in_app_purchase`** (StoreKit 2 trên iOS) — **10 sản phẩm**
  (`lib/iap/iap_products.dart`): 5 gói 💎 (small/medium/large/huge/mega), gỡ
  QC, x2 thu nhập, đập heo, gói khởi động, Kho lạnh vĩnh viễn. Xác thực biên
  nhận qua backend riêng (mục dưới) — KHÔNG chỉ tin client.

## Backend — Firebase (project `bobaempire-1f372`)

- **Crashlytics** — báo crash, dSYM upload qua Run Script build phase (SPM
  không tự thêm như CocoaPods).
- **Remote Config** — MỘT tham số JSON gộp (`boba_remote_config`,
  `lib/data/remote_balance.dart`) chỉnh hằng số cân bằng + sự kiện giới hạn
  thời gian không cần nộp bản mới. Mẫu ở `remote_config_template.json`.
- **Cloud Messaging (FCM)** — CHỈ dùng đẩy thông báo Chợ Phụ kiện, gửi từ
  Supabase Edge Function. Không dùng Firebase Analytics.

## Backend — Supabase (Postgres + Auth + Storage + Realtime, project `orphyhtnaaqfglytffkn`)

Client gọi thẳng qua `supabase_flutter`, không qua server trung gian (trừ IAP).
Logic nhạy cảm nằm trong RPC `security definer` (kiểm tra quyền/anti-cheat ở
server, không tin client). RLS bật ở mọi bảng; bảng xếp hạng cho đọc công khai,
phần còn lại chỉ qua RPC. Mỗi tính năng một file `supabase/*.sql` (idempotent,
dán vào SQL Editor hoặc `scripts/deploy_supabase_sql.sh`); kịch bản kiểm thử
SQL ở `supabase/tests/` chạy trên Postgres tạm bằng `scripts/test_*_sql.sh`.

| Nhóm | Schema (`supabase/*.sql`) |
|---|---|
| Bảng xếp hạng | `leaderboard`, `m3_leaderboard`, `accessory_leaderboard`, `recipe_leaderboard`, `recipe_order_leaderboard`, `event_leaderboard`, `arena_leaderboard`, `season_leaderboard`, `branch_leaderboard`, `story_speedrun` (Hồi 1–4: `story_speedrun{,2,3,4}`), `leaderboard_rewards` (thưởng top tuần) |
| Thi đấu | `arena` (PvP 1v1, replay verify server-side, match3), `world_boss` (boss tuần/ngày cả server), `guild`, `guild_dungeon`, `recipe_daily` |
| Kinh tế/Chợ | `accessory_market` (chợ + hết hạn tin + bộ sưu tập), `accessory_swap` (đổi món), `market_push_triggers` |
| Xã hội/hồ sơ | `friends` (kết bạn, quà, ghé quán, đột kích), `player_profile`, `player_title`, `player_gender`, `player_avatar` (Storage bucket `avatars`), `referral` |
| Hạ tầng | `cloud_save` (đồng bộ save qua email, optimistic concurrency), `analytics` (sự kiện chơi nhẹ, không đăng nhập), `iap_replay` (chặn phát lại IAP, chỉ server) |

- **Auth**: `signInAnonymously()` cho khách; **bắt buộc liên kết email**
  (`signInWithOtp` / OTP) để dùng tính năng online (bảng xếp hạng, Chợ, Hội, Bạn
  bè…) — kiểm tra lặp ở server bằng `is_linked_user()`. SMTP qua **Resend**
  (Gmail SMTP mặc định bị defer, không dùng).
- **Realtime** (`postgres_changes`): chợ phụ kiện, thông báo VIP.
- **Edge Function** (`supabase/functions/notify-market-sale`, Deno/TypeScript)
  — Database Webhook gọi khi có giao dịch/niêm yết mới → gửi FCM (HTTP v1,
  service account lưu trong secret của function). Hiện có 6 ngôn ngữ thông
  báo (chưa có `ko`).
- **Công cụ quản trị**: `tools/admin.html` — trang tĩnh chạy cục bộ với
  `service_role` (cộng 💎, quản lý Hội/BXH, duyệt bảng). Khoá không nhúng vào
  app.

## Backend — server xác thực IAP (`server/`, Dart thuần)

Package Dart server-side riêng, deploy tách biệt (3 file test, mock HTTP).

- **`shelf`/`shelf_router`** — HTTP, endpoint `POST /verify`.
- **`googleapis_auth`** — service account → Google Play Developer API
  (`purchases.products.get/acknowledge/consume`).
- **`dart_jsonwebtoken`** — JWT ES256 gọi **App Store Server API**
  (`api.storekit.itunes.apple.com`) — KHÔNG dùng `verifyReceipt` (StoreKit 1)
  vì hỏng với JWS StoreKit 2.
- Chặn phát lại consumable qua bảng `iap_replay`, ghi bằng **service_role key**
  (bí mật server).

## Hạ tầng & deploy

- **Google Cloud Run** (`asia-southeast1`) — chạy server IAP, build từ
  `server/Dockerfile` (2 giai đoạn, `dart:stable` compile AOT) qua **Cloud
  Build** (`gcloud run deploy --source .`, không cần Docker cục bộ).
- **Secret Manager** — khoá App Store Server API + Supabase service_role.
- **GitHub Pages** — landing/guide/privacy tĩnh ở `docs/`, domain
  `bobaempiregame.com`.

## Phân phối

- Phiên bản `pubspec.yaml`: `1.0.11+25`. **App Store**: bản 1.0.9 đã live
  (2026-10-12), 1.0.10 đã nộp (2026-10-16); bản 1.0.11 chưa nộp iOS.
  **Google Play**: 1.0.11 đang duyệt production (2026-10-18). Tình trạng chi
  tiết: `RELEASE_NOTES.md`, `RELEASE_CHECKLIST.md`, `APP_REVIEW_NOTES_*.md`.
- Không có CI tự động; build/nộp thủ công (`flutter build`, Xcode Organizer /
  Transporter, Play Console).

## Test & tooling

- `flutter test` — ~255 file, ~3000 ca, không cần thiết bị (+ `flutter analyze`
  sạch). Cấu hình test (`test/flutter_test_config.dart`) tắt animation trang
  trí; bẫy phổ biến: `dart format` làm reflow đổi lint, test có ngẫu nhiên
  (giờ cao điểm) phải assert theo khoảng.
- `integration_test` — 8 file: chụp ảnh store tự động (`scripts/shoot.sh`), QA
  sweep, bố cục iPad, hiệu năng, video quảng bá, ảnh review IAP.
- `dart test` cho `server/`; kịch bản **SQL** trên Postgres tạm (Homebrew
  `postgresql@16`).
- **Python** (`scripts/make_*.py`) — sinh icon/feature graphic/cảnh nền/công
  thức từ code. **Shell** (`scripts/*.sh`) — kiểm domain/DNS, chụp ảnh store,
  deploy/test SQL.
- Tài liệu thiết kế: `GAME_DESIGN.md` (nguồn chuẩn cho luồng/hệ thống),
  `PROPOSAL_*.md`, `UI_PATTERNS.md`.

## Cố tình KHÔNG dùng

- **CocoaPods** — Firebase qua Swift Package Manager.
- **Firebase Analytics** — analytics tự viết nhẹ qua Supabase.
- **Server game riêng** — logic server nằm trong RPC Supabase, không có backend
  game tự dựng (chỉ có server xác thực IAP).
- **Docker cục bộ**, **CI/CD tự động** — deploy/nộp bản thủ công.
- **Impeller trên Android** — đã tắt ở manifest vì emoji bị vẽ trống trên một
  số máy Xiaomi (cờ opt-out sẽ bị Flutter gỡ → kiểm lại khi nâng Flutter).
