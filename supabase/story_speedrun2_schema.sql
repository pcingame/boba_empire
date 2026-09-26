-- Schema cho "Bảng xếp hạng tốc độ — Hồi 2" (hoàn thành Chương 28).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor →
-- Run. Idempotent. Độc lập với story_speedrun_schema.sql (bảng Hồi 1, mốc
-- Chương 18) và các schema khác — dán trước/sau đều được. KHÔNG đụng bảng/hàm
-- của Hồi 1 nên client đã phát hành không bị ảnh hưởng.
--
-- Cùng khuôn với story_speedrun_schema.sql: 1 MỐC MỘT LẦN cho mỗi người (khi
-- vừa xem xong Chương 28), không sửa lại được; không có anti-cheat (không có
-- Xu/Sao để làm giả có lợi, rủi ro thấp cho bảng xếp hạng vui) — chỉ chặn giá
-- trị <= 0 bằng CHECK. Thời gian = TỔNG giây thực tế từ lần đầu chơi tới lúc
-- xong Chương 28 (cùng cách đo với Hồi 1).
--
-- Danh tính: auth.uid() — bất kỳ phiên nào đang có (ẩn danh hoặc permanent).

create table if not exists story_speedrun2_entries (
  user_id           uuid primary key references auth.users(id) on delete cascade,
  nickname          text not null check (char_length(nickname) between 1 and 20),
  complete_seconds  bigint not null check (complete_seconds > 0),
  completed_at      timestamptz not null default now()
);

create index if not exists story_speedrun2_entries_time_idx
  on story_speedrun2_entries (complete_seconds asc);

alter table story_speedrun2_entries enable row level security;

-- Đọc: AI CŨNG được (kể cả anon) — bảng xếp hạng công khai.
drop policy if exists story_speedrun2_entries_select_all on story_speedrun2_entries;
create policy story_speedrun2_entries_select_all on story_speedrun2_entries
  for select
  to anon, authenticated
  using (true);

-- Ghi: CHỈ insert (không có policy update/delete). Lần nộp thứ 2 bị chặn kép:
-- RLS không có "for update" khớp và PRIMARY KEY (user_id) chặn insert trùng
-- khoá; client coi lỗi 23505 là no-op (xem StorySpeedrunRepository.submitCompletion).
drop policy if exists story_speedrun2_entries_insert_own on story_speedrun2_entries;
create policy story_speedrun2_entries_insert_own on story_speedrun2_entries
  for insert
  to authenticated
  with check (auth.uid() = user_id);

-- Top người hoàn thành nhanh nhất (top tuyệt đối, không "quanh hạng của bạn").
create or replace function story_speedrun2_top(p_limit integer default 50)
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
  from story_speedrun2_entries
  order by complete_seconds asc, completed_at asc
  limit p_limit;
$$;

grant execute on function story_speedrun2_top(integer) to anon, authenticated;
