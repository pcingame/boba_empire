# Boba Empire — Receipt verify server (skeleton)

Backend xác thực biên nhận IAP để chống giả mạo mua hàng client-only. App gọi
`POST /verify`; server đối chiếu với Google Play / App Store rồi trả phán quyết.

## Hợp đồng HTTP

`POST /verify`

```json
// request
{ "productId": "boba_gems_small", "source": "google_play", "verificationData": "<token|receipt>" }
// response
{ "valid": true }
```

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
  -d '{"productId":"boba_gems_small","source":"google_play","verificationData":"x"}'
# {"valid":true}
```

Trỏ app vào server khi build:

```bash
flutter run --dart-define=IAP_VERIFY_ENDPOINT=http://10.0.2.2:8080/verify
# (10.0.2.2 = localhost của máy host nhìn từ Android emulator)
```

## Bật xác thực thật (prod)

Đặt `VERIFY_MODE=prod` và các biến môi trường tương ứng:

| Biến | Dùng cho | Lấy ở đâu |
|------|----------|-----------|
| `PLAY_SERVICE_ACCOUNT_JSON` | Google Play | Service account JSON (quyền *View financial data*), dán cả nội dung |
| `ANDROID_PACKAGE_NAME` | Google Play | `com.pcingame.bobaempire` |
| `APPSTORE_SHARED_SECRET` | App Store | App Store Connect → App → *App-Specific Shared Secret* |

Khung gọi API thật nằm ở `lib/verifier.dart` (`PlayVerifier`, `AppStoreVerifier`)
kèm các `TODO(prod)`. Việc CÒN THIẾU trước khi coi là production-ready:

- **Chống replay**: lưu `orderId` (Play) / `transaction_id` (Apple) đã trao vào
  DB, từ chối nếu đã dùng — nếu không, một biên nhận hợp lệ có thể phát lại.
- **Play consumable**: sau khi xác thực nên `acknowledge`/`consume` qua API.
- **StoreKit 2**: receipt là JWS → dùng App Store Server API thay `verifyReceipt`
  (endpoint này đang bị Apple khai tử dần).
- Xác thực `packageName`/`bundleId` và `productId` khớp app thật.

## Deploy (gợi ý: Cloud Run)

```bash
# Dockerfile tối thiểu dựa trên dart:stable; hoặc `gcloud run deploy --source .`
```

Sau khi deploy, đặt `IAP_VERIFY_ENDPOINT=https://<service>/verify` khi build app.
