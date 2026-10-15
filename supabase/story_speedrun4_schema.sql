-- Schema cho "Bảng xếp hạng tốc độ — Hồi 4" (hoàn thành Chương 46).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor →
-- Run. Idempotent. Độc lập với story_speedrun_schema.sql (Hồi 1, Chương 18), story_speedrun2_schema.sql (Hồi 2, Chương 28)
-- và story_speedrun3_schema.sql (Hồi 3, Chương 36) — dán trước/sau đều được.
-- KHÔNG đụng bảng/hàm của hai hồi trước nên client đã phát hành không bị
-- ảnh hưởng.
--
-- Cùng khuôn với story_speedrun2_schema.sql: 1 MỐC MỘT LẦN cho mỗi người (khi
-- vừa xem xong Chương 46), không sửa lại được; không có anti-cheat (không có
-- Xu/Sao để làm giả có lợi, rủi ro thấp cho bảng xếp hạng vui) — chỉ chặn giá
-- trị <= 0 bằng CHECK. Thời gian = TỔNG giây thực tế từ lần đầu chơi tới lúc
-- xong Chương 46 (cùng cách đo với Hồi 1/2).
--
-- Danh tính: auth.uid() — bất kỳ phiên nào đang có (ẩn danh hoặc permanent).

create table if not exists story_speedrun4_entries (
  user_id           uuid primary key references auth.users(id) on delete cascade,
  nickname          text not null check (char_length(nickname) between 1 and 20),
  complete_seconds  bigint not null check (complete_seconds > 0),
  completed_at      timestamptz not null default now()
);

create index if not exists story_speedrun4_entries_time_idx
  on story_speedrun4_entries (complete_seconds asc);

-- Tài khoản hiện tại đã liên kết email (không ẩn danh)? security definer vì vai trò authenticated không
-- đọc được auth.users. ÉP Ở SERVER (không chỉ ở app): ai ghi vào bảng này phải đã liên kết email. Định nghĩa
-- giống hệt ở mọi schema cần nó (create or replace) nên chạy file nào trước cũng được.
create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

alter table story_speedrun4_entries enable row level security;

-- Đọc: AI CŨNG được (kể cả anon) — bảng xếp hạng công khai.
drop policy if exists story_speedrun4_entries_select_all on story_speedrun4_entries;
create policy story_speedrun4_entries_select_all on story_speedrun4_entries
  for select
  to anon, authenticated
  using (true);

-- Ghi: CHỈ insert (không có policy update/delete). Lần nộp thứ 2 bị chặn kép:
-- RLS không có "for update" khớp và PRIMARY KEY (user_id) chặn insert trùng
-- khoá; client coi lỗi 23505 là no-op (xem StorySpeedrunRepository.submitCompletion).
drop policy if exists story_speedrun4_entries_insert_own on story_speedrun4_entries;
create policy story_speedrun4_entries_insert_own on story_speedrun4_entries
  for insert
  to authenticated
  with check (auth.uid() = user_id and is_linked_user());

-- Top người hoàn thành nhanh nhất (top tuyệt đối, không "quanh hạng của bạn").
create or replace function story_speedrun4_top(p_limit integer default 50)
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
  from story_speedrun4_entries
  order by complete_seconds asc, completed_at asc
  limit p_limit;
$$;

grant execute on function story_speedrun4_top(integer) to anon, authenticated;
