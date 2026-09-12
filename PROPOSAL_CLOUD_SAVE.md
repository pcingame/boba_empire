# ĐỀ XUẤT — Đồng bộ đám mây (Cloud Save qua Email OTP)

> Trạng thái: **đã code xong, chờ deploy SQL + test**. Đối chiếu
> [`GAME_DESIGN.md`](GAME_DESIGN.md) §14 mục 6 ("Save local-only... gỡ app =
> mất sạch") — đây là bản vá cho đúng rủi ro đó.

## 1. Vấn đề & lựa chọn

Save hiện tại chỉ nằm trong `SharedPreferences` (1 blob JSON, xem
`lib/data/game_storage.dart`) — gỡ app hoặc đổi máy là mất sạch, kể cả tiến
trình đã mua bằng IAP thật.

Đã cân nhắc 3 hướng (xem lịch sử trao đổi):
1. **Play Games Services / Game Center** — chuẩn nhất nhưng cần liên kết
   Google Play Console + cấu hình App Store Connect, nhiều giấy tờ.
2. **Supabase + Sign in with Google/Apple** — nhẹ hơn nhưng vẫn cần bật
   "Sign in with Apple" ở Apple Developer.
3. **Supabase + Email OTP (đã chọn)** — không cần giấy tờ App Store/Google
   Console nào cả. Người chơi gõ email → nhận mã 6 số → gõ vào app → có tài
   khoản permanent, gỡ app/đổi máy chỉ cần gõ lại đúng email.

## 2. Kiến trúc

Dùng CHUNG project Supabase đã dựng cho Đấu Trường (`lib/arena/`), nhưng
**tách bảng, tách luồng auth, không phụ thuộc nhau**:
- Đấu Trường: đăng nhập ẩn danh (`signInAnonymously`), bảng `arena_*`.
- Cloud save: đăng nhập bằng email OTP (`signInWithOtp` + `verifyOTP`), bảng
  `player_saves` — 1 hàng/người chơi, đơn giản hơn Đấu Trường nên dùng RLS
  trực tiếp trên bảng, KHÔNG cần hàm RPC "security definer" (không có tranh
  chấp giữa nhiều người chơi cần trọng tài).

```
GameController.saveNow()  ──►  GameStorage (local, luôn chạy trước)
        │
        └──► CloudSaveRepository.push()  (no-op nếu chưa liên kết / Supabase
              lỗi — KHÔNG BAO GIỜ được phép làm hỏng save local)
```

## 3. Luồng liên kết (UI: Cài đặt → "Đồng bộ đám mây")

1. Nhập email → `signInWithOtp` → Supabase gửi mã 6 số qua email.
2. Nhập mã → `verifyOTP` → phiên hiện tại (kể cả đang ẩn danh từ Đấu Trường)
   chuyển thành tài khoản permanent gắn email đó.
3. Kiểm tra cloud đã có save chưa (`pull()`):
   - Chưa có / gần giống save máy này (chênh `lifetimeEarnings` < 1%) → đẩy
     luôn save máy này lên, không hỏi gì thêm.
   - Có và khác biệt rõ → hỏi **"Khôi phục từ cloud"** (ghi đè máy này) hay
     **"Giữ máy này"** (ghi đè cloud). KHÔNG BAO GIỜ tự ý chọn hộ.
4. Từ đó, mỗi lần `saveNow()` (rất thường xuyên — auto-save 10s + sau mỗi
   hành động) tự đẩy lên cloud, không cần người chơi làm gì thêm.

**Cố tình đơn giản hoá:** không tự động PULL khi mở app (dù đã liên kết từ
trước) — chỉ pull đúng 1 lần ngay sau khi xác thực mã ở bước 3. Đồng bộ
1 CHIỀU (máy → cloud) sau đó. Tránh rủi ro app tự âm thầm ghi đè save máy
đang chơi bằng bản cũ hơn trên cloud.

## 4. Chống crash khi Supabase lỗi/chưa init

`GameController.saveNow()` là **điểm gọi save DUY NHẤT** của toàn app (mọi
hành động — mua, chạm, prestige... — đều đi qua đây). Test hiện có build
`GameController` thẳng qua `ProviderScope`, không qua `main()`, nên
`Supabase.initialize()` chưa từng chạy trong test. Nếu `saveNow()` đụng
`Supabase.instance` mà không phòng thủ → **toàn bộ test suite vỡ** (đã xảy ra
thật lúc code, tự phát hiện và vá trước khi giao).

Vá: `GameController._cloudSave` là getter lazy + tự bắt lỗi
(`try { Supabase.instance.client } catch (_) { return null; }`) — Supabase
chưa init (test) hay lỗi bất kỳ lúc nào → cloud sync âm thầm tắt, save local
vẫn chạy bình thường. Nguyên tắc: **đồng bộ cloud là tiện ích cộng thêm,
không bao giờ được phép chặn/làm hỏng luồng lưu game chính.**

## 5. Việc cần làm thủ công (không code được)

- Dán `supabase/cloud_save_schema.sql` vào Supabase SQL Editor (độc lập với
  `arena_schema.sql`, dán trước/sau đều được).
- Dashboard → Authentication → Emails → Email Templates → "Magic Link" →
  thêm biến `{{ .Token }}` vào nội dung (mặc định chỉ có link, app cần mã số
  để người chơi gõ tay — không dùng deep link).

## 6. Việc CHƯA làm (ghi lại để khỏi quên)

- Chưa merge dữ liệu 2 chiều (VD chơi song song 2 máy) — chỉ có "chọn 1 bên
  ghi đè bên kia" lúc phát hiện xung đột. Đủ cho use-case chính (1 người chơi
  nhiều máy, KHÔNG đồng thời).
- Chưa giới hạn tần suất push (đẩy theo đúng nhịp `saveNow()`, ~10s/lần khi
  đang chơi) — đủ rẻ ở quy mô nhỏ, cân nhắc throttle riêng nếu chi phí
  Supabase đáng kể sau này.

**ĐÃ SỬA (2026-09-12):** trước đây xung đột chỉ được kiểm tra ĐÚNG 1 LẦN lúc
liên kết — mọi lần lưu nền sau đó (`saveNow()`, ~10s/lần) ghi đè cloud MÙ,
không kiểm tra gì. Máy A chơi → liên kết → tự đẩy save liên tục; máy B (cùng
email) liên kết sau, được hỏi 1 lần, rồi CŨNG tự đẩy liên tục; nếu người
chơi quay lại máy A, máy A không hề biết máy B đã tiến bộ hơn — lần lưu nền
kế tiếp của máy A âm thầm ghi đè mất tiến trình của máy B. Đã sửa bằng
optimistic concurrency: cột `version` mới trên `player_saves` (server tự
tăng mỗi lần UPDATE qua trigger), mỗi lần `saveNow()` đẩy save kèm "tôi
tưởng version hiện tại là N" (`CloudSaveRepository.pushIfCurrent`) — ghi chỉ
thành công nếu đúng; sai thì đánh dấu `cloudConflictPending` (lưu cục bộ,
tách khỏi `GameState` — xem `GameStorage.saveCloudVersion`/
`saveCloudConflictPending`) thay vì ghi đè, và dialog Đồng bộ đám mây tự
kiểm tra lại + hỏi người chơi (tái dùng đúng UI xung đột đã có) ở lần mở kế
tiếp. Vẫn CHƯA merge 2 chiều (bullet đầu ở trên) — chỉ là phát hiện xung đột
đúng lúc thay vì chỉ 1 lần, để người chơi tự chọn bên nào giữ.
