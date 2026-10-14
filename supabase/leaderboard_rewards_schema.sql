-- Thưởng top bảng xếp hạng theo tuần (góp ý người chơi: "thưởng cho top 1,2,3 BXH").
-- Năm bảng TÍCH LŨY: income (Thu nhập), pearls (Trân Châu Rơi), collection (Sưu tập), vip, recipes (Thợ pha chế). Mỗi tuần
-- (thứ Hai 00:00 UTC) top 3 của mỗi bảng nhận 300 / 200 / 100 💎 — nhận MỘT LẦN cho mỗi (tuần, bảng).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase SQL Editor → Run. Idempotent. Chạy SAU
-- leaderboard_schema, m3_leaderboard_schema, accessory_leaderboard_schema, recipe_leaderboard_schema và
-- accessory_market_schema (bảng vip_leaderboard_entries nằm ở đó). KHÔNG đụng bảng/hàm cũ.
--
-- Cách tính: KHÔNG cần cron. Lần đầu có người gọi lb_reward_status() trong tuần mới thì server chụp top 3
-- hiện tại của từng bảng và gắn nhãn tuần đó ("bảng xếp hạng chốt đầu tuần"); ai nằm trong ảnh chụp thì
-- nhận được trong tuần đó và tuần kế (hết hạn sau 2 tuần). Muốn chốt đúng 00:00 thứ Hai, bật pg_cron:
--   select cron.schedule('lb-rewards-snapshot', '0 0 * * 1', 'select lb_reward_snapshot()');
--
-- Chống gian lận: điểm trên các bảng do client tự khai, nên chỉ tài khoản đã LIÊN KẾT email (không ẩn
-- danh) và điểm > 0 mới được vào ảnh chụp. Hạng/điểm cùng thứ tự với bảng công khai (xem
-- player_profile_schema.sql): điểm giảm dần, hoà thì ai nộp sớm hơn (updated_at) xếp trên.

create table if not exists lb_reward_snapshots (
  week      date    not null,
  board     text    not null,
  rank      integer not null check (rank between 1 and 3),
  user_id   uuid    not null references auth.users(id) on delete cascade,
  nickname  text    not null,
  value     numeric not null,
  primary key (week, board, rank)
);
create index if not exists lb_reward_snapshots_user_idx on lb_reward_snapshots (user_id, week);

create table if not exists lb_reward_claims (
  user_id    uuid    not null references auth.users(id) on delete cascade,
  week       date    not null,
  board      text    not null,
  gems       integer not null,
  claimed_at timestamptz not null default now(),
  primary key (user_id, week, board)
);

-- Bảng đã tạo từ khi còn 4 bảng có CHECK cũ: bỏ rồi tạo lại với bảng 'recipes' (idempotent).
alter table lb_reward_snapshots drop constraint if exists lb_reward_snapshots_board_check;
alter table lb_reward_snapshots add constraint lb_reward_snapshots_board_check
  check (board in ('income', 'pearls', 'collection', 'vip', 'recipes'));

alter table lb_reward_snapshots enable row level security;
alter table lb_reward_claims    enable row level security;
-- Cố ý KHÔNG tạo policy: chỉ RPC security definer được đụng vào.

create or replace function lb_reward_week() returns date
language sql stable as $$ select date_trunc('week', now() at time zone 'utc')::date $$;

-- 💎 theo hạng. Khớp lib/core/lb_rewards.dart (test so khớp).
create or replace function lb_reward_gems(p_rank integer) returns integer
language sql immutable as $$
  select case p_rank when 1 then 300 when 2 then 200 when 3 then 100 else 0 end
$$;

-- Thưởng còn nhận được trong bao nhiêu tuần kể từ tuần chụp (tuần chụp + tuần kế).
create or replace function lb_reward_valid_weeks() returns integer
language sql immutable as $$ select 2 $$;

-- Chụp top 3 từng bảng cho tuần hiện tại nếu CHƯA có (idempotent; khoá để hai người gọi cùng lúc
-- không chụp hai lần). Nội bộ — client không gọi trực tiếp.
create or replace function lb_reward_snapshot() returns void
language plpgsql security definer set search_path = public as $$
declare
  v_week date := lb_reward_week();
begin
  perform pg_advisory_xact_lock(hashtext('lb_reward_snapshot'));
  if exists (select 1 from lb_reward_snapshots where week = v_week) then return; end if;

  insert into lb_reward_snapshots (week, board, rank, user_id, nickname, value)
  select v_week, b.board, b.rn, b.user_id, b.nickname, b.v from (
    select 'income'::text as board, r.user_id, r.nickname, r.v,
           row_number() over (order by r.v desc, r.updated_at asc)::integer as rn
      from (select e.user_id, e.nickname, e.lifetime_earnings::numeric as v, e.updated_at
              from leaderboard_entries e join auth.users u on u.id = e.user_id
             where not u.is_anonymous and e.lifetime_earnings > 0) r
  ) b where b.rn <= 3
  union all
  select v_week, b.board, b.rn, b.user_id, b.nickname, b.v from (
    select 'pearls'::text as board, r.user_id, r.nickname, r.v,
           row_number() over (order by r.v desc, r.updated_at asc)::integer as rn
      from (select e.user_id, e.nickname, e.stars::numeric as v, e.updated_at
              from m3_leaderboard_entries e join auth.users u on u.id = e.user_id
             where not u.is_anonymous and e.stars > 0) r
  ) b where b.rn <= 3
  union all
  select v_week, b.board, b.rn, b.user_id, b.nickname, b.v from (
    select 'collection'::text as board, r.user_id, r.nickname, r.v,
           row_number() over (order by r.v desc, r.updated_at asc)::integer as rn
      from (select e.user_id, e.nickname, e.owned_count::numeric as v, e.updated_at
              from accessory_leaderboard_entries e join auth.users u on u.id = e.user_id
             where not u.is_anonymous and e.owned_count > 0) r
  ) b where b.rn <= 3
  union all
  select v_week, b.board, b.rn, b.user_id, b.nickname, b.v from (
    select 'vip'::text as board, r.user_id, r.nickname, r.v,
           row_number() over (order by r.v desc, r.updated_at asc)::integer as rn
      from (select e.user_id, e.nickname, e.vip_exp::numeric as v, e.updated_at
              from vip_leaderboard_entries e join auth.users u on u.id = e.user_id
             where not u.is_anonymous and e.vip_exp > 0) r
  ) b where b.rn <= 3
  union all
  select v_week, b.board, b.rn, b.user_id, b.nickname, b.v from (
    select 'recipes'::text as board, r.user_id, r.nickname, r.v,
           row_number() over (order by r.v desc, r.updated_at asc)::integer as rn
      from (select e.user_id, e.nickname, e.mastered::numeric as v, e.updated_at
              from recipe_leaderboard_entries e join auth.users u on u.id = e.user_id
             where not u.is_anonymous and e.mastered > 0) r
  ) b where b.rn <= 3;
end;
$$;

-- Thưởng của MÌNH còn trong hạn: [{week, board, rank, gems, claimed}], mới nhất trước. Gọi hàm này cũng
-- kích hoạt việc chụp của tuần mới (xem đầu file).
create or replace function lb_reward_status() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  perform lb_reward_snapshot();
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'week', s.week, 'board', s.board, 'rank', s.rank,
             'gems', lb_reward_gems(s.rank),
             'claimed', exists (select 1 from lb_reward_claims c
                                  where c.user_id = v_uid and c.week = s.week and c.board = s.board))
           order by s.week desc, s.board, s.rank)
      from lb_reward_snapshots s
     where s.user_id = v_uid
       and s.week > lb_reward_week() - 7 * lb_reward_valid_weeks()), '[]'::jsonb);
end;
$$;

-- Nhận thưởng của (tuần, bảng): phải đúng người trong ảnh chụp, còn hạn, chưa nhận. Trả về số 💎;
-- client cộng 💎 cục bộ SAU khi hàm này thành công (cùng khuôn rương Boss của Hội).
create or replace function lb_reward_claim(p_week date, p_board text) returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_rank integer;
  v_gems integer;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select s.rank into v_rank from lb_reward_snapshots s
   where s.week = p_week and s.board = p_board and s.user_id = v_uid
     and s.week > lb_reward_week() - 7 * lb_reward_valid_weeks();
  if v_rank is null then raise exception 'not found'; end if;
  v_gems := lb_reward_gems(v_rank);
  begin
    insert into lb_reward_claims (user_id, week, board, gems) values (v_uid, p_week, p_board, v_gems);
  exception when unique_violation then
    raise exception 'already claimed';
  end;
  return v_gems;
end;
$$;

-- Quyền: chỉ người đã đăng nhập gọi được RPC; hàm nội bộ khoá hẳn.
revoke all on function lb_reward_status() from public, anon;
revoke all on function lb_reward_claim(date, text) from public, anon;
grant execute on function lb_reward_status() to authenticated;
grant execute on function lb_reward_claim(date, text) to authenticated;
revoke all on function lb_reward_snapshot() from public, anon, authenticated;
