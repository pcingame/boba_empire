# Boba Empire — Receipt verify server

Backend xác thực biên nhận IAP để chống giả mạo mua hàng client-only. App gọi
`POST /verify`; server đối chiếu với Google Play / App Store rồi trả phán quyết.

**2026-09-29:** không còn là skeleton — xác thực App Store/Play thật + chặn
phát lại + acknowledge/consume Play đều đã viết xong và có test (`dart test`,
30 ca). Còn lại 100% là việc CẤU HÌNH (credential, deploy), không phải code —
xem "Bật xác thực thật" bên dưới.

## Hợp đồng HTTP

`POST /verify`

```json
// request
{
  "productId": "boba_gems_small",
  "source": "google_play",
  "verificationData": "<token|JWS>",
  "kind": "consumable"
}
// response
{ "valid": true }
```

`kind`: `"consumable"` hoặc `"non_consumable"` — khớp `IapProduct.kind` phía
app (`lib/iap/iap_products.dart`). Quyết định 2 việc:
- Play: gọi `acknowledge` (non-consumable) hay `consume` (consumable) —
  **bắt buộc**, Play tự hoàn tiền sau ~3 ngày nếu không gọi.
- Chặn phát lại: CHỈ áp cho `consumable` (phát lại = cộng 💎 hai lần, mất
  tiền thật). `non_consumable` được phép gửi lại đúng id cũ — đó là luồng
  "Khôi phục giao dịch mua" hợp lệ khi đổi máy, không phải gian lận.

Client (`lib/iap/http_receipt_verifier.dart`) chỉ CHẶN trao thưởng khi nhận
`200 {"valid": false}`. Mọi lỗi khác (≠200, timeout) → fail-open (vẫn trao).

## Chạy local (dev)

```bash
cd server
dart pub get
dart run bin/server.dart        # http://localhost:8080, VERIFY_MODE=dev
```

`VERIFY_MODE=dev` (mặc định) dùng `DevVerifier` — **chấp nhận mọi biên nhận**,
chỉ để test wiring. Test nhanh:

```bash
curl -s localhost:8080/verify -H 'content-type: application/json' \
  -d '{"productId":"boba_gems_small","source":"google_play","verificationData":"x","kind":"consumable"}'
# {"valid":true}
```

Chạy test: `dart test` (30 ca, không cần credential thật — dùng khoá EC test
tạo riêng cho test, xem `test/fixtures/README.md`).

Trỏ app vào server khi build:

```bash
flutter run --dart-define=IAP_VERIFY_ENDPOINT=http://10.0.2.2:8080/verify
# (10.0.2.2 = localhost của máy host nhìn từ Android emulator)
```

## Bật xác thực thật (prod)

Đặt `VERIFY_MODE=prod` và các biến môi trường:

| Biến | Dùng cho | Lấy ở đâu |
|------|----------|-----------|
| `PLAY_SERVICE_ACCOUNT_JSON` | Google Play | Service account JSON (quyền *View financial data*), dán cả nội dung |
| `ANDROID_PACKAGE_NAME` | Google Play | `com.pcingame.bobaempire` |
| `APPSTORE_KEY_ID` | App Store | App Store Connect → Users and Access → Integrations → khoá "In-App Purchase"/"App Store Server API" |
| `APPSTORE_ISSUER_ID` | App Store | Cùng trang Integrations, phía trên danh sách khoá |
| `APPSTORE_BUNDLE_ID` | App Store | `com.pcingame.bobaempire` |
| `APPSTORE_PRIVATE_KEY` | App Store | Nội dung file `.p8` tải về LÚC TẠO KHOÁ (chỉ tải được 1 lần) — dán cả khối `-----BEGIN PRIVATE KEY-----...` |
| `SUPABASE_URL` | Chặn phát lại | `https://orphyhtnaaqfglytffkn.supabase.co` (project hiện có) |
| `SUPABASE_SERVICE_ROLE_KEY` | Chặn phát lại | Supabase Dashboard → Project Settings → API → **service_role** (⚠️ KHÔNG phải publishable key app đang dùng — key này bỏ qua RLS hoàn toàn, tuyệt đối không nhúng vào app/commit vào repo) |

⚠️ **`APPSTORE_SHARED_SECRET` KHÔNG CÒN DÙNG** (đổi tên/thay thế hoàn toàn ở
bản này) — đó là bí mật cho endpoint `verifyReceipt` (StoreKit 1) cũ. Server
giờ xác thực qua **App Store Server API** vì `in_app_purchase_storekit`
(≥0.3, xem `pubspec.lock` phía app) gửi lên JWS ký bởi StoreKit 2, không phải
base64 receipt mà `verifyReceipt` hiểu — endpoint cũ sẽ trả lỗi định dạng cho
MỌI giao dịch thật với bản plugin đang dùng.

**Trước khi bật `VERIFY_MODE=prod` lần đầu:** dán
`supabase/iap_replay_schema.sql` vào Supabase SQL Editor (tạo bảng
`iap_redeemed_receipts` — chặn phát lại consumable). Thiếu `SUPABASE_URL`/
`SUPABASE_SERVICE_ROLE_KEY` server vẫn chạy được nhưng dùng bộ nhớ tạm
(`InMemoryReplayStore`, log cảnh báo lúc khởi động) — mất tác dụng chặn phát
lại nếu deploy nhiều instance hoặc restart.

## Deploy (gợi ý: Cloud Run)

```bash
# Dockerfile tối thiểu dựa trên dart:stable; hoặc `gcloud run deploy --source .`
```

Sau khi deploy, đặt `IAP_VERIFY_ENDPOINT=https://<service>/verify` khi build app.
