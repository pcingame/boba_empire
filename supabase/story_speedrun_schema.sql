-- Schema cho "Bảng xếp hạng tốc độ hoàn thành cốt truyện" (18 chương).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor →
-- Run. Idempotent. Độc lập với arena_schema.sql/cloud_save_schema.sql/
-- analytics_schema.sql/leaderboard_schema.sql — dán trước/sau đều được.
--
-- Khác leaderboard_schema.sql (điểm số cập nhật liên tục, upsert mỗi lần mở
-- trang): đây là 1 MỐC MỘT LẦN — mỗi người chỉ nộp đúng 1 lần (khi vừa xem
-- xong Chương 18), không sửa lại được sau đó. Không cần trigger chống gian
-- lận phức tạp như leaderboard_schema.sql (không có Xu/Sao để làm giả cho
-- có lợi — sửa complete_seconds chỉ tự làm mình trông "nhanh" hơn giả tạo,
-- rủi ro thấp cho 1 bảng xếp hạng vui, không ảnh hưởng kinh tế chính); vẫn
-- chặn giá trị âm/bằng 0 bằng CHECK constraint cho chắc.
--
-- Danh tính: dùng auth.uid() — bất kỳ phiên nào đang có (ẩn danh từ Đấu
-- Trường, hoặc permanent từ Đồng bộ đám mây) đều nộp được, không bắt buộc
-- phải link email riêng.

create table if not exists story_speedrun_entries (
  user_id           uuid primary key references auth.users(id) on delete cascade,
  nickname          text not null check (char_length(nickname) between 1 and 20),
  complete_seconds  bigint not null check (complete_seconds > 0),
  completed_at      timestamptz not null default now()
);

create index if not exists story_speedrun_entries_time_idx
  on story_speedrun_entries (complete_seconds asc);

alter table story_speedrun_entries enable row level security;

-- Đọc: AI CŨNG được — kể cả chưa đăng nhập (anon) — bảng xếp hạng công khai.
drop policy if exists story_speedrun_entries_select_all on story_speedrun_entries;
create policy story_speedrun_entries_select_all on story_speedrun_entries
  for select
  to anon, authenticated
  using (true);

-- Ghi: CHỈ insert (không có policy update/delete) — mỗi người 1 lần duy
-- nhất; lần nộp thứ 2 trở đi bị chặn kép: RLS không có "for update" nào
-- khớp, và PRIMARY KEY (user_id) chặn insert trùng khoá. Client coi lỗi
-- trùng khoá (23505) là no-op, không phải lỗi thật — xem
-- StorySpeedrunRepository.submitCompletion().
drop policy if exists story_speedrun_entries_insert_own on story_speedrun_entries;
create policy story_speedrun_entries_insert_own on story_speedrun_entries
  for insert
  to authenticated
  with check (auth.uid() = user_id);

-- Top người hoàn thành nhanh nhất — KHÔNG dùng kiểu "quanh hạng của bạn"
-- như leaderboard_around_me: số người hoàn thành cốt truyện chắc chắn ít
-- hơn nhiều tổng số người chơi (top tuyệt đối vẫn có ý nghĩa), và người
-- CHƯA hoàn thành thì vốn không có hàng nào để "quanh" cả.
create or replace function story_speedrun_top(p_limit integer default 50)
returns table (
  user_id           uuid,
  nickname          text,
  complete_seconds  bigint,
  completed_at      timestamptz,
  rank              bigint
)
language sql
stable
as $$
  select user_id, nickname, complete_seconds, completed_at,
         row_number() over (order by complete_seconds asc, completed_at asc) as rank
  from story_speedrun_entries
  order by complete_seconds asc, completed_at asc
  limit p_limit;
$$;

grant execute on function story_speedrun_top(integer) to anon, authenticated;
