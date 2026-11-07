# Thiết lập nạp tiền chuyển khoản (SePay) — bản Android APK

Bản Android tự phát hành (package `com.game.pc.boba`) không có Google Play Billing, nên nạp tiền bằng
chuyển khoản ngân hàng. iOS vẫn dùng StoreKit, không liên quan file này.

## Luồng hoạt động

1. Người chơi bấm mua → app gọi `bank_create_order(product)` → server tạo đơn, mã `BExxxxxxxx`.
2. App hiện QR VietQR đã điền sẵn số tiền + nội dung chuyển khoản = mã đơn.
3. Người chơi chuyển khoản → ngân hàng báo SePay → SePay gọi webhook
   `supabase/functions/sepay-webhook` → `bank_mark_paid()` đánh dấu đơn đã trả
   (chỉ khi đủ tiền; mỗi giao dịch chỉ dùng một lần).
4. App (khi mở + hỏi lại mỗi 5 giây trong lúc hộp QR mở) gọi `bank_my_paid()` → trao hàng →
   `bank_ack()`. Hai pha: tắt app giữa chừng không mất hàng.

Code: `lib/iap/bank_iap_service.dart`, `lib/iap/bank_config.dart`, `lib/ui/bank_order_dialog.dart`.
SQL: `supabase/bank_orders_schema.sql` (test cục bộ: `scripts/test_bank_sql.sh`).

## Thông tin cố định

| Mục | Giá trị |
|---|---|
| Supabase project ref | `orphyhtnaaqfglytffkn` |
| Webhook URL | `https://orphyhtnaaqfglytffkn.supabase.co/functions/v1/sepay-webhook` |
| Secret | `SEPAY_API_KEY` — lưu ở `~/keys/sepay_api_key.txt`, **không commit** |

## Các bước thiết lập

### 1. Chốt giá
Giá VND hiện là ước lượng. Đổi giá phải sửa **cả hai** nơi (có test so khớp):
- bảng `bank_prices` trong `supabase/bank_orders_schema.sql`
- `bankPriceVnd` trong `lib/iap/bank_config.dart`

### 2. Chạy SQL
Dán toàn bộ `supabase/bank_orders_schema.sql` vào Supabase SQL Editor → Run.
Chạy lại nhiều lần được (đổi giá thì chạy lại).

### 3. Tạo secret + deploy webhook
```sh
openssl rand -hex 32 > ~/keys/sepay_api_key.txt && chmod 600 ~/keys/sepay_api_key.txt
supabase secrets set SEPAY_API_KEY=$(cat ~/keys/sepay_api_key.txt) --project-ref orphyhtnaaqfglytffkn
supabase functions deploy sepay-webhook --no-verify-jwt --project-ref orphyhtnaaqfglytffkn
```
`--no-verify-jwt` là bắt buộc (SePay không gửi JWT Supabase; webhook tự kiểm header API Key).

### 4. Cấu hình SePay (my.sepay.vn)
1. Đăng ký → ở câu "Bạn cần gì từ SePay?" chọn **Chỉ cần chia sẻ biến động số dư**
   (KHÔNG cần Cổng thanh toán — app tự tạo QR).
2. Liên kết tài khoản ngân hàng nhận tiền.
3. Tích hợp → **Webhooks** → Thêm mới:
   - URL: webhook URL ở bảng trên
   - Chứng thực: **API Key**, dán nội dung `~/keys/sepay_api_key.txt`
     (SePay gửi header `Authorization: Apikey <key>`)
   - Chỉ gọi khi **có tiền vào**

### 5. Build APK
Thông tin tài khoản nhận tiền truyền lúc build (thiếu một trong ba thì cửa hàng ẩn nút mua):
```sh
flutter build apk --release \
  --dart-define=BANK_ID=MB \
  --dart-define=BANK_ACCOUNT=<số tài khoản> \
  --dart-define=BANK_NAME="TEN CHU TK KHONG DAU"
```
`BANK_ID` = mã/BIN ngân hàng theo VietQR (https://api.vietqr.io/v2/banks).
Ký bằng keystore `android/keys/boba-apk.jks` (đọc qua `android/key.properties`, cả hai không commit).

### 6. Thử thật
Mua gói rẻ nhất bằng tiền thật: QR đúng số tiền + mã đơn → chuyển khoản → app nhận hàng trong vài giây.
Kiểm tra log webhook ở Supabase Dashboard → Edge Functions → `sepay-webhook` → Logs.

## Xử lý sự cố

| Triệu chứng | Nguyên nhân thường gặp |
|---|---|
| Webhook trả 401 | API Key trên SePay khác `SEPAY_API_KEY` |
| Webhook trả 500 "not configured" | Chưa đặt secret `SEPAY_API_KEY` |
| Kết quả `no_code` | Người chơi sửa/xoá nội dung chuyển khoản → đối chiếu tay theo số tiền + giờ |
| Kết quả `short` | Chuyển thiếu tiền → đơn vẫn chờ, xử lý tay |
| Kết quả `unknown` | Mã đơn không tồn tại (gõ sai) |
| Đã trả nhưng app chưa nhận | Mở lại app (app tự hỏi `bank_my_paid` khi mở) |

## Còn để ngỏ
- Hộp QR chỉ có tiếng Việt.
- Không có duyệt tay trong app cho đơn `no_code`/`short` — xử lý qua SQL Editor.
