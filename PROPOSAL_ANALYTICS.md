# ĐỀ XUẤT — Analytics nhẹ để tune balance bằng dữ liệu thật

> Trạng thái: **đã code xong, chờ deploy SQL**. Không phải để "cân bằng
> lại số liệu" ngay — đây là bước THU THẬP dữ liệu thật trước, đối chiếu
> [[known-issues-backlog]] mục 3 và `GAME_DESIGN.md` §15 (mọi hằng số hiện
> là ước lượng, chưa playtest).

## 1. Vì sao không sửa số ngay hôm nay

Mọi lần "cân bằng lại" trước giờ đều là đoán (xem memory
`mechanics-rework-needs-playtest`). Đoán rồi lại đoán tiếp không giải quyết
được gì — cần nhìn hành vi chơi THẬT trước: session dài bao lâu, người chơi
bỏ cuộc ở giai đoạn nào, bao lâu mới prestige lần đầu. Việc hôm nay chỉ là
dựng đường ống thu thập — quay lại tune số sau khi có dữ liệu vài ngày/tuần.

## 2. Vì sao KHÔNG dùng chung auth với Đấu Trường/Cloud Save

Game hiện chạy offline hoàn toàn — mở app không cần mạng. Nếu bắt MỌI
người chơi đăng nhập (kể cả ẩn danh) chỉ để ghi analytics, mỗi lần mở app
sẽ cần 1 round-trip mạng, phá vỡ đúng điểm mạnh đó. Nên:

- Không auth. Ghi thẳng bằng `apikey` publishable (giống đọc bảng công
  khai), không có phiên đăng nhập nào.
- Định danh máy bằng `device_id` sinh ngẫu nhiên cục bộ (lưu
  SharedPreferences, không phải Supabase auth user, không liên quan gì tới
  Arena/cloud save).
- **Best-effort tuyệt đối**: mọi lỗi mạng/Supabase bị nuốt, không bao giờ
  ảnh hưởng gameplay hay chặn save local (xem
  `lib/data/analytics_repository.dart`).

## 3. Sự kiện ghi lại (tối thiểu, đúng thứ cần để trả lời 2 câu hỏi)

| Sự kiện | Khi nào | Dữ liệu kèm |
|---|---|---|
| `session_start` | Mở app (`GameController.build()`) | stage, prestigeStars, lifetimeEarnings |
| `session_end` | App chuyển nền (paused/hidden) | seconds (thời lượng session) |
| `stage_reached` | Mở giai đoạn mới thành công | stage |
| `prestige` | Nhượng quyền thành công | starsGained, totalStars |

Không track hành động lẻ tẻ (tap, buy...) — quá nhiều, không cần thiết cho
2 câu hỏi "session dài bao lâu" / "rớt ở đâu".

## 4. RLS — chỉ GHI, không ai ĐỌC qua API công khai

Khác `arena_schema.sql`/`cloud_save_schema.sql` (RLS theo `auth.uid()`),
bảng này cho phép insert từ role `anon` (không cần đăng nhập) nhưng KHÔNG
có policy select nào — không ai (kể cả người vừa ghi) đọc lại được qua API
công khai. Chỉ bạn (chủ project) đọc qua Dashboard/SQL Editor.

## 5. Việc cần làm thủ công

Dán `supabase/analytics_schema.sql` vào SQL Editor — độc lập hoàn toàn với
2 file schema kia, không cần bật gì thêm (không cần SMTP, không cần
anonymous sign-in).

## 6. Sau vài ngày/tuần có dữ liệu, xem bằng gì

3 câu SQL mẫu ở cuối `analytics_schema.sql` (thời lượng session trung
bình, phễu theo giai đoạn, thời gian tới prestige đầu tiên). Quay lại đây
khi có đủ mẫu để bắt đầu tune — đừng tune sớm khi mẫu còn quá ít (vài chục
session đầu chưa nói lên gì).
