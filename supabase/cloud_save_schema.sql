-- Schema cho "Đồng bộ đám mây" (cloud save qua email OTP) — xem
-- PROPOSAL_CLOUD_SAVE.md.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor →
-- Run. Idempotent, an toàn chạy lại nhiều lần. Độc lập với
-- `arena_schema.sql` (bảng khác, không đụng nhau) — dán trước/sau đều được.
--
-- Đơn giản hơn arena_schema.sql: đây là dữ liệu 1-chủ-1-hàng (mỗi người chơi
-- chỉ đọc/ghi ĐÚNG hàng của chính mình), nên dùng thẳng RLS trên bảng, không
-- cần hàm RPC "security definer" như Đấu Trường (không có logic tranh chấp
-- giữa nhiều người chơi cần trọng tài ở giữa).
--
-- ⚠️ BƯỚC THỦ CÔNG BẮT BUỘC (không làm bằng SQL được) — xem cuối file.

create table if not exists player_saves (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  data        jsonb not null,
  updated_at  timestamptz not null default now(),
  version     bigint not null default 1
);

-- 2026-09-12: thêm version — cần cho fix "đồng bộ 1 chiều, không phát hiện
-- xung đột sau lần đầu liên kết" (xem known-issues-backlog memory, mục 7).
-- ALTER an toàn để chạy lại trên bảng đã tồn tại (CREATE TABLE IF NOT EXISTS
-- ở trên không tự thêm cột mới).
alter table player_saves
  add column if not exists version bigint not null default 1;

alter table player_saves enable row level security;

drop policy if exists player_saves_select_own on player_saves;
create policy player_saves_select_own on player_saves
  for select using (auth.uid() = user_id);

drop policy if exists player_saves_insert_own on player_saves;
create policy player_saves_insert_own on player_saves
  for insert with check (auth.uid() = user_id);

drop policy if exists player_saves_update_own on player_saves;
create policy player_saves_update_own on player_saves
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- `updated_at` do SERVER tự đóng dấu mỗi lần ghi (không tin đồng hồ máy
-- khách) — dùng để so sánh "save nào mới hơn" khi có xung đột giữa máy hiện
-- tại và cloud lúc khôi phục.
--
-- `version` (2026-09-12) do SERVER tự tăng mỗi lần UPDATE (không tăng lúc
-- INSERT lần đầu — hàng mới giữ mặc định 1) — dùng cho optimistic
-- concurrency: client đẩy save kèm "tôi tưởng version hiện tại là N", ghi
-- chỉ thành công nếu N khớp version thật trên server (xem
-- CloudSaveRepository.pushIfCurrent()). Đây chính là cơ chế phát hiện xung
-- đột SAU lần liên kết đầu tiên — trước đây chỉ kiểm tra xung đột đúng 1
-- lần lúc liên kết, các lần lưu sau đó ghi đè mù không kiểm tra gì cả.
create or replace function player_saves_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  if TG_OP = 'UPDATE' then
    new.version := old.version + 1;
  end if;
  return new;
end;
$$;

drop trigger if exists player_saves_set_updated_at on player_saves;
create trigger player_saves_set_updated_at
  before insert or update on player_saves
  for each row execute function player_saves_set_updated_at();

-- ─────────────────────────────────────────────────────────────────────────
-- ⚠️ 1 BƯỚC KHÔNG LÀM ĐƯỢC BẰNG SQL — bật thủ công trong Dashboard:
--
-- Authentication → Emails → Email Templates → chọn "Magic Link" (đây là
-- template Supabase dùng chung cho signInWithOtp qua email). Mặc định chỉ có
-- link xác nhận ({{ .ConfirmationURL }}) — app KHÔNG dùng link (không mở deep
-- link), mà bắt người chơi gõ tay 1 mã 6 số. PHẢI thêm biến {{ .Token }} vào
-- nội dung email, ví dụ chèn thêm dòng:
--
--     Mã xác nhận của bạn: {{ .Token }}
--
-- Thiếu bước này thì email gửi tới người chơi sẽ không có mã số nào để họ
-- gõ vào app.
-- ─────────────────────────────────────────────────────────────────────────
