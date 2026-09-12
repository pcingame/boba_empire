-- Schema cho Bảng xếp hạng — xem PROPOSAL_LEADERBOARD.md.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor →
-- Run. Idempotent. Độc lập với arena_schema.sql/cloud_save_schema.sql/
-- analytics_schema.sql — dán trước/sau đều được, không đụng bảng nào khác.
--
-- Khác cloud_save_schema.sql (chỉ chủ mới đọc được hàng của mình): bảng
-- này CỐ Ý cho phép AI CŨNG đọc được TOÀN BỘ hàng — đó chính là mục đích
-- (bảng xếp hạng công khai). Ghi thì vẫn chỉ được ghi đúng hàng của mình
-- (giống cloud_save_schema.sql).
--
-- Danh tính: dùng auth.uid() — bất kỳ phiên nào đang có (ẩn danh từ Đấu
-- Trường, hoặc permanent từ Đồng bộ đám mây) đều nộp được điểm, không bắt
-- buộc phải link email riêng cho bảng xếp hạng.

create table if not exists leaderboard_entries (
  user_id          uuid primary key references auth.users(id) on delete cascade,
  nickname         text not null check (char_length(nickname) between 1 and 20),
  lifetime_earnings numeric not null default 0 check (lifetime_earnings >= 0),
  prestige_stars   bigint not null default 0 check (prestige_stars >= 0),
  stage            integer not null default 1 check (stage >= 1),
  updated_at       timestamptz not null default now()
);

-- 2026-09-12: prestige_stars từng là `integer` (int4, trần ~2,14 tỷ) — bug
-- thật gặp trên máy: save có ~16,6 tỷ Sao (từ trước khi Balance.prestigeK
-- được giảm) khiến MỌI lần nộp điểm bị Postgres từ chối
-- ("value out of range for type integer"), app luôn rơi vào màn lỗi. Đổi
-- sang bigint (int8, trần ~9,2 tỷ tỷ) khớp kiểu int 64-bit của Dart.
-- ALTER an toàn để chạy lại trên bảng đã tồn tại (CREATE TABLE IF NOT EXISTS
-- ở trên không tự đổi kiểu cột cũ).
alter table leaderboard_entries
  alter column prestige_stars type bigint;

create index if not exists leaderboard_entries_lifetime_idx
  on leaderboard_entries (lifetime_earnings desc);

alter table leaderboard_entries enable row level security;

-- Đọc: AI CŨNG được — kể cả chưa đăng nhập (anon) — bảng xếp hạng là công khai.
drop policy if exists leaderboard_entries_select_all on leaderboard_entries;
create policy leaderboard_entries_select_all on leaderboard_entries
  for select
  to anon, authenticated
  using (true);

-- Ghi: chỉ đúng hàng của chính mình.
drop policy if exists leaderboard_entries_insert_own on leaderboard_entries;
create policy leaderboard_entries_insert_own on leaderboard_entries
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists leaderboard_entries_update_own on leaderboard_entries;
create policy leaderboard_entries_update_own on leaderboard_entries
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Server tự đóng dấu updated_at (không tin đồng hồ client), giống
-- cloud_save_schema.sql.
create or replace function leaderboard_entries_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists leaderboard_entries_set_updated_at on leaderboard_entries;
create trigger leaderboard_entries_set_updated_at
  before insert or update on leaderboard_entries
  for each row execute function leaderboard_entries_set_updated_at();

-- ─────────────────────────────────────────────────────────────────────────
-- "Quanh hạng của bạn": top 50 tuyệt đối gần như chắc chắn không có tên
-- bạn (chưa nhiều người chơi thật) — nhìn 1 danh sách toàn số khổng lồ
-- không liên quan gì tới mình thì nản, không tạo động lực. Trả về
-- [p_window] người TRÊN + chính bạn + [p_window] người DƯỚI, đã kèm sẵn
-- hạng (rank) — 1 câu query bằng window function, rẻ hơn nhiều so với
-- client tự ghép nhiều lượt gọi.
--
-- KHÔNG cần security definer: bảng đã cho phép SELECT công khai
-- (`leaderboard_entries_select_all` ở trên), hàm này chỉ đóng gói lại
-- logic xếp hạng, chạy đúng quyền người gọi là đủ.
-- ─────────────────────────────────────────────────────────────────────────

-- drop trước vì đổi kiểu trả về (prestige_stars integer -> bigint):
-- `create or replace function` từ chối đổi return type của hàm đã tồn tại.
drop function if exists leaderboard_around_me(integer);

create or replace function leaderboard_around_me(p_window integer default 5)
returns table (
  user_id           uuid,
  nickname          text,
  lifetime_earnings numeric,
  prestige_stars    bigint,
  stage             integer,
  rank              bigint
)
language sql
stable
as $$
  with ranked as (
    select
      e.user_id, e.nickname, e.lifetime_earnings, e.prestige_stars, e.stage,
      row_number() over (order by e.lifetime_earnings desc) as rank
    from leaderboard_entries e
  ),
  me as (
    select r.rank from ranked r where r.user_id = auth.uid()
  )
  select ranked.user_id, ranked.nickname, ranked.lifetime_earnings,
         ranked.prestige_stars, ranked.stage, ranked.rank
  from ranked, me
  where ranked.rank between me.rank - p_window and me.rank + p_window
  order by ranked.rank;
$$;

grant execute on function leaderboard_around_me(integer) to authenticated;
