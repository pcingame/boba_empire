# DOMAIN_TODO — gắn bobaempiregame.com vào GitHub Pages

Ghi lại 2026-09-28 để làm tiếp, không cần hỏi lại từ đầu.

> **Tự kiểm:** `bash scripts/check_domain.sh` — in ra từng bước còn thiếu gì,
> chạy lại bao nhiêu lần cũng được trong lúc chờ DNS lan.
>
> **Trạng thái 2026-09-28 (đo thật):** DNS xong, `https://bobaempiregame.com`
> trả 200 và chứng chỉ hợp lệ, email forwarding xong.
> **Còn đúng một việc:** đổi CNAME `www` → `pcingame.github.io.` (xem dưới).

## Đã xong
- [x] Mua domain `bobaempiregame.com` (Namecheap).
- [x] Verify domain trên Resend (DKIM + 2 CNAME SPF `rsend`/`send`).
- [x] Đổi Supabase Auth SMTP sang Resend — **test gửi OTP tới Gmail ngoài đã
      thành công**.
- [x] Dựng `docs/index.html` (landing page) + `docs/CNAME` chứa
      `bobaempiregame.com`, đã commit + push (`1b25145`).
      `docs/privacy-policy.html` đã có link quay lại trang chủ.

## Còn lại — làm ở Namecheap (Advanced DNS, tab domain `bobaempiregame.com`)
1. **Xóa** dòng "URL Redirect Record" (Host `@`) — parking mặc định của
   Namecheap, xung đột với bước 2.
2. **Thêm 4 A Record**, Host `@`, mỗi dòng 1 IP:
   - `185.199.108.153`
   - `185.199.109.153`
   - `185.199.110.153`
   - `185.199.111.153`
3. **CNAME `www`** — ⚠️ ĐANG SAI: đang trỏ về `bobaempiregame.com.`, phải sửa
   thành **`pcingame.github.io.`** (có dấu chấm cuối).

   Trỏ về chính domain gốc thì trang vẫn chạy (301 về gốc qua HTTP), NHƯNG
   GitHub không xác minh được `www` nên **không đưa nó vào chứng chỉ HTTPS** —
   ai gõ `https://www.bobaempiregame.com` sẽ gặp cảnh báo bảo mật của trình
   duyệt. Đo được ngày 2026-09-28:
   `SSL: no alternative certificate subject name matches target host name`.

   Sửa xong GitHub tự cấp lại chứng chỉ gồm cả `www` (mất tới ~1 giờ).
4. ~~Bật **Email Forwarding**~~ ✅ ĐÃ XONG — kiểm 2026-09-28 bằng
   `bash scripts/check_domain.sh`, domain đã có MX của Namecheap
   (`eforward1..5.registrar-servers.com`). Chỉ còn tự gửi thử một mail tới
   `support@bobaempiregame.com` xem có về hộp thư Gmail không.

## Còn lại — làm trên GitHub
5. Repo `pcingame/boba_empire` → **Settings → Pages** → mục Custom domain nên
   tự nhận `bobaempiregame.com` (nhờ file `docs/CNAME`); nếu chưa thấy thì gõ
   tay + Save.
6. Đợi DNS lan truyền (vài phút–vài giờ) rồi bật **Enforce HTTPS** khi hết mờ.

## Kiểm tra cuối
- Mở `https://bobaempiregame.com` và `https://bobaempiregame.com/privacy-policy.html`
  — phải load được trang vừa dựng.
- Gửi thử mail tới `support@bobaempiregame.com`, xem có về Gmail không.

## Việc phụ, không gấp
- Nút "🍎 App Store (sắp có)" trong `docs/index.html` đang là placeholder —
  khi app lên App Store thật, sửa link `<a class="soon" href="#">` thành
  `https://apps.apple.com/app/id<APP_ID>` (bỏ luôn class `soon`).
- URL cũ `https://pcingame.github.io/boba_empire/privacy-policy.html` (đang
  khai ở Google Play/AdMob) sẽ tự redirect sang domain mới sau khi DNS xong —
  không cần sửa gì ở Play Console/AdMob, không ảnh hưởng app-ads.txt hay
  Marketing URL (khác repo GitHub Pages, xem
  [[admob-verification-pending]] trong memory).
- Xóa file này (`DOMAIN_TODO.md`) sau khi làm xong hết, không cần giữ lại
  trong repo.
