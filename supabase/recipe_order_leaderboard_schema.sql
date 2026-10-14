-- Schema cho "Bảng xếp hạng Pha theo đơn" (trò công thức, chế độ kéo-thả) — xếp theo SỐ MÓN ĐÃ TỪNG PHA
-- HOÀN HẢO mà KHÔNG xem công thức mẫu (bậc Quen trở lên, không dùng gợi ý quảng cáo) — xem
-- lib/ui/recipe_order_page.dart và GameState.recipeOrderPerfect.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor → Run. Idempotent. Không phụ thuộc
-- file nào khác. Cùng khuôn recipe_leaderboard_schema.sql (số lượng chỉ tăng ⇒ cho UPDATE hàng của mình,
-- trigger chặn hạ cấp).
--
-- Khác các bảng cũ: GHI chỉ cho tài khoản đã LIÊN KẾT email (không ẩn danh) — ép ở server chứ không chỉ ở
-- app (hàm is_linked_user bên dưới). Các bảng cũ mới chỉ chặn ở app.
--
-- ⚠️ Chống gian lận: giá trị do client tự khai. Ràng buộc kiểm được: 0..100 (số món trong danh mục), chỉ tăng.

-- Tài khoản hiện tại đã liên kết email (không ẩn danh)? security definer vì vai trò authenticated không
-- đọc được auth.users.
create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

create table if not exists recipe_order_leaderboard_entries (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  nickname   text not null check (char_length(nickname) between 1 and 20),
  perfected  integer not null check (perfected between 0 and 100),
  updated_at timestamptz not null default now()
);

create index if not exists recipe_order_leaderboard_entries_idx
  on recipe_order_leaderboard_entries (perfected desc, updated_at asc);

alter table recipe_order_leaderboard_entries enable row level security;

-- Đọc: ai cũng được — bảng xếp hạng công khai (app vẫn chỉ mở cho người đã liên kết).
drop policy if exists recipe_order_lb_select_all on recipe_order_leaderboard_entries;
create policy recipe_order_lb_select_all on recipe_order_leaderboard_entries
  for select to anon, authenticated using (true);

-- Ghi: chỉ hàng của chính mình VÀ đã liên kết email.
drop policy if exists recipe_order_lb_insert_own on recipe_order_leaderboard_entries;
create policy recipe_order_lb_insert_own on recipe_order_leaderboard_entries
  for insert to authenticated with check (auth.uid() = user_id and is_linked_user());

drop policy if exists recipe_order_lb_update_own on recipe_order_leaderboard_entries;
create policy recipe_order_lb_update_own on recipe_order_leaderboard_entries
  for update to authenticated using (auth.uid() = user_id and is_linked_user())
  with check (auth.uid() = user_id and is_linked_user());

-- perfected chỉ được TĂNG — chặn tự đạp hạng khi chơi lại bằng save cũ.
create or replace function recipe_order_lb_no_downgrade()
returns trigger
language plpgsql
as $$
begin
  if new.perfected < old.perfected then
    new.perfected := old.perfected;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists recipe_order_lb_no_downgrade_trg on recipe_order_leaderboard_entries;
create trigger recipe_order_lb_no_downgrade_trg
  before update on recipe_order_leaderboard_entries
  for each row execute function recipe_order_lb_no_downgrade();

-- Top tuyệt đối. Hoà thì ai nộp sớm hơn xếp trên.
create or replace function recipe_order_leaderboard_top(p_limit integer default 50)
returns table (
  user_id    uuid,
  nickname   text,
  perfected  integer,
  updated_at timestamptz,
  rank       bigint
)
language sql
stable
as $$
  select user_id, nickname, perfected, updated_at,
         row_number() over (order by perfected desc, updated_at asc) as rank
  from recipe_order_leaderboard_entries
  order by perfected desc, updated_at asc
  limit least(coalesce(p_limit, 50), 100);
$$;

grant execute on function recipe_order_leaderboard_top(integer) to anon, authenticated;
