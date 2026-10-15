-- Schema cho "Bảng xếp hạng Thợ pha chế" — xếp theo SỐ MÓN CÔNG THỨC ĐÃ TỪNG ĐẠT BẬC "THẠO"
-- (xem lib/core/recipe_mastery.dart: recipeMasteredEver, đếm theo `best` nên chỉ tăng).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor → Run. Idempotent. Chạy TRƯỚC
-- leaderboard_rewards_schema.sql (bảng này là nguồn của bảng thưởng "recipes").
--
-- Cùng khuôn accessory_leaderboard_schema.sql: số lượng TĂNG DẦN theo thời gian nên cho UPDATE hàng của
-- chính mình (upsert mỗi lần mở trang), có trigger chặn hạ cấp.
--
-- ⚠️ Chống gian lận: giá trị do client tự khai (như các bảng khác). Ràng buộc có thể kiểm: 0..100 (số món
-- trong danh mục), chỉ tăng. Chưa kiểm được "đạt Thạo mất ≥ 4 ngày" ở server vì không biết ngày người
-- chơi bắt đầu luyện; chỉ tài khoản đã liên kết email mới được vào ảnh chụp thưởng tuần (xem
-- leaderboard_rewards_schema.sql).

create table if not exists recipe_leaderboard_entries (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  nickname   text not null check (char_length(nickname) between 1 and 20),
  -- Trần 100 = số món trong assets/recipes/recipes.json (đã có sẵn cả 5 nhóm, mở dần từng nhóm).
  mastered   integer not null check (mastered between 0 and 100),
  updated_at timestamptz not null default now()
);

create index if not exists recipe_leaderboard_entries_idx
  on recipe_leaderboard_entries (mastered desc, updated_at asc);

-- Tài khoản hiện tại đã liên kết email (không ẩn danh)? security definer vì vai trò authenticated không
-- đọc được auth.users. ÉP Ở SERVER (không chỉ ở app): ai ghi vào bảng này phải đã liên kết email. Định nghĩa
-- giống hệt ở mọi schema cần nó (create or replace) nên chạy file nào trước cũng được.
create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

alter table recipe_leaderboard_entries enable row level security;

-- Đọc: ai cũng được, kể cả chưa đăng nhập — bảng xếp hạng công khai.
drop policy if exists recipe_leaderboard_select_all on recipe_leaderboard_entries;
create policy recipe_leaderboard_select_all on recipe_leaderboard_entries
  for select to anon, authenticated using (true);

-- Ghi: chỉ hàng của chính mình.
drop policy if exists recipe_leaderboard_insert_own on recipe_leaderboard_entries;
create policy recipe_leaderboard_insert_own on recipe_leaderboard_entries
  for insert to authenticated with check (auth.uid() = user_id and is_linked_user());

drop policy if exists recipe_leaderboard_update_own on recipe_leaderboard_entries;
create policy recipe_leaderboard_update_own on recipe_leaderboard_entries
  for update to authenticated using (auth.uid() = user_id and is_linked_user())
  with check (auth.uid() = user_id and is_linked_user());

-- mastered chỉ được TĂNG — chặn tự đạp hạng khi chơi lại bằng save cũ.
create or replace function recipe_leaderboard_no_downgrade()
returns trigger
language plpgsql
as $$
begin
  if new.mastered < old.mastered then
    new.mastered := old.mastered;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists recipe_leaderboard_no_downgrade_trg on recipe_leaderboard_entries;
create trigger recipe_leaderboard_no_downgrade_trg
  before update on recipe_leaderboard_entries
  for each row execute function recipe_leaderboard_no_downgrade();

-- Top người thạo nhiều món nhất (top tuyệt đối). Hoà thì ai nộp sớm hơn xếp trên.
create or replace function recipe_leaderboard_top(p_limit integer default 50)
returns table (
  user_id    uuid,
  nickname   text,
  mastered   integer,
  updated_at timestamptz,
  rank       bigint
)
language sql
stable
as $$
  select user_id, nickname, mastered, updated_at,
         row_number() over (order by mastered desc, updated_at asc) as rank
  from recipe_leaderboard_entries
  order by mastered desc, updated_at asc
  limit least(coalesce(p_limit, 50), 100);
$$;

grant execute on function recipe_leaderboard_top(integer) to anon, authenticated;
