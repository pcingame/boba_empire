# ĐỀ XUẤT — Bảng xếp hạng

> Trạng thái: **đã code xong, chờ deploy SQL**. Item #5 trong
> [[known-issues-backlog]] — bước tiếp theo tự nhiên sau Đấu Trường, dùng
> chung hạ tầng Supabase đã có.

## 1. Thiết kế

Khác hẳn 3 bảng kia:
- **Ai cũng đọc được** (kể cả chưa đăng nhập) — đúng mục đích công khai của
  bảng xếp hạng. Chỉ RLS write bị giới hạn (mỗi người chỉ ghi đúng hàng
  của mình), select thì mở cho `anon` + `authenticated`.
- **Dùng chung phiên hiện có** — không bắt tài khoản riêng. Nếu chưa có
  phiên nào (chưa chơi Đấu Trường, chưa liên kết Cloud Save), tự đăng nhập
  ẩn danh khi mở Bảng xếp hạng lần đầu — giống hệt cách Đấu Trường làm.
- **"Quanh hạng của bạn", KHÔNG PHẢI top tuyệt đối** — lúc còn ít người
  chơi thật, top 50 gần như chắc chắn không có tên bạn, nhìn toàn số không
  liên quan thì nản. Hàm SQL `leaderboard_around_me(p_window)` (window
  function `row_number()`) trả về đúng [window] người trên + chính bạn +
  [window] người dưới, kèm sẵn hạng thật — 1 query duy nhất, không cần
  client tự ghép nhiều lượt gọi hay tự đếm hạng.
- **Xếp theo `lifetime_earnings`** (Xu cả đời) — số liệu đã có sẵn, tăng
  đơn điệu, không cần tính gì thêm.

## 2. Tên hiển thị (nickname)

Không dùng email/user id thật lên bảng công khai (rò rỉ riêng tư với người
đã liên kết Cloud Save). Người chơi tự đặt tên hiển thị, lưu cache local
(SharedPreferences) — **luôn gửi kèm tên ở MỌI lần nộp điểm**, kể cả cập
nhật: cột `nickname` là `NOT NULL`, và upsert của Postgres vẫn kiểm ràng
buộc NOT NULL trên hàng đề xuất dù cuối cùng là UPDATE do đụng khoá chính —
bỏ tên ra khỏi payload cập nhật sẽ lỗi. Gửi kèm mọi lần là đơn giản và chắc
chắn nhất, không cần phân biệt "chèn mới" / "cập nhật".

## 3. Chống gian lận — mức tối thiểu, không phải Olympic bảo mật

- RLS chặn ghi vào hàng của người khác (như mọi bảng khác ở đây).
- Cột kiểu `numeric` (không phải `double precision`) — Postgres từ chối
  thẳng giá trị Infinity/NaN, và Dart `jsonEncode` cũng KHÔNG serialize
  được các giá trị đó (ném lỗi trước khi kịp gửi request) — 2 lớp chặn free
  cho đúng lớp bug vừa gặp (tràn số).
- CHECK constraint chặn số âm.
- **KHÔNG** verify số liệu nộp lên có khớp thực tế hay không (client có thể
  sửa save rồi nộp số giả) — đây thuần là tính năng khoe khoang, không có
  phần thưởng kinh tế thật gắn theo (khác Đấu Trường), nên chấp nhận rủi ro
  này để giữ đơn giản, đúng tinh thần "cheap addition" đã đề ra ban đầu.

## 4. Khi nào nộp điểm

KHÔNG nối vào `saveNow()` (sẽ ghi liên tục mỗi ~10s, không cần thiết cho
thứ chỉ xem thỉnh thoảng). Chỉ nộp khi người chơi **mở** màn Bảng xếp hạng
— vừa đủ để số liệu hiển thị (kể cả của người khác) luôn mới khi họ chủ
động vào xem.

## 5. Việc cần làm thủ công

Dán `supabase/leaderboard_schema.sql` vào SQL Editor — độc lập hoàn toàn
với 3 file schema kia.

## 6. Việc CHƯA làm

- Không có season/reset định kỳ — xếp hạng cộng dồn vĩnh viễn theo
  `lifetime_earnings` (không reset khi prestige, đúng ý nghĩa "cả đời").
- Không lọc/kiểm duyệt tên hiển thị (không có bộ lọc từ ngữ) — chấp nhận
  rủi ro nhỏ ở quy mô hiện tại, làm sau nếu thành vấn đề thật.
