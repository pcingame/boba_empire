-- Schema cho "Thử thách hằng ngày" của trò Pha theo đơn (lib/ui/recipe_order_page.dart, chế độ daily).
-- Mỗi ngày (UTC) mọi người chơi làm cùng 3 đơn (đề cố định theo ngày, xem buildDailyOrders); điểm 0..300.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor → Run. Idempotent. Không phụ thuộc file nào
-- khác (tự có is_linked_user, giống recipe_order_leaderboard_schema.sql).
--
-- Mỗi (người, ngày) đúng MỘT hàng và KHÔNG sửa được: chỉ có policy INSERT (không UPDATE/DELETE) nên điểm đã nộp
-- là bất biến; app nộp bằng upsert ... DO NOTHING nên nộp lại không lỗi. Ngày do SERVER tự đặt (default), client
-- không chọn được ⇒ không nộp điểm vào ngày khác. Ghi chỉ cho tài khoản đã LIÊN KẾT email.
--
-- ⚠️ Chống gian lận: điểm do client tự khai (kẹp 0..300). Bảng chỉ để vui/thi đua, thưởng thật chỉ là 💎 nhỏ cố định.

create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

-- Ngày hiện tại (số ngày kể từ epoch, UTC) — cùng cách tính dayIndex() ở app.
create or replace function recipe_daily_today() returns integer
language sql stable as $$ select floor(extract(epoch from now()) / 86400)::integer $$;

create table if not exists recipe_daily_scores (
  user_id    uuid not null references auth.users(id) on delete cascade,
  day        integer not null default recipe_daily_today(),
  nickname   text not null check (char_length(nickname) between 1 and 20),
  score      integer not null check (score between 0 and 300),
  updated_at timestamptz not null default now(),
  primary key (user_id, day)
);

create index if not exists recipe_daily_scores_idx on recipe_daily_scores (day, score desc, updated_at asc);

alter table recipe_daily_scores enable row level security;

drop policy if exists recipe_daily_select_all on recipe_daily_scores;
create policy recipe_daily_select_all on recipe_daily_scores
  for select to anon, authenticated using (true);

-- Chỉ INSERT hàng của mình, đúng ngày hôm nay của server, đã liên kết email. Cố ý KHÔNG có UPDATE/DELETE.
drop policy if exists recipe_daily_insert_own on recipe_daily_scores;
create policy recipe_daily_insert_own on recipe_daily_scores
  for insert to authenticated
  with check (auth.uid() = user_id and day = recipe_daily_today() and is_linked_user());

-- Top của HÔM NAY (ngày server). Hoà thì ai nộp sớm hơn xếp trên.
create or replace function recipe_daily_top(p_limit integer default 50)
returns table (
  user_id    uuid,
  nickname   text,
  score      integer,
  updated_at timestamptz,
  rank       bigint
)
language sql
stable
as $$
  select user_id, nickname, score, updated_at,
         row_number() over (order by score desc, updated_at asc) as rank
  from recipe_daily_scores
  where day = recipe_daily_today()
  order by score desc, updated_at asc
  limit least(coalesce(p_limit, 50), 100);
$$;

grant execute on function recipe_daily_top(integer) to anon, authenticated;
