-- Bảng xếp hạng Thẻ Mùa: xếp theo XP mùa của MÙA HIỆN TẠI (client tự khai, chỉ tăng, trần = 28 ngày × 150 XP).
-- Id mùa = số ngày UTC từ epoch / 28, khớp seasonIdFor ở lib/core/season.dart (test so khớp). Bảng tự "reset" mỗi mùa
-- vì mỗi mùa là một tập hàng riêng. Chỉ tài khoản liên kết email mới nộp được. Dán TOÀN BỘ vào SQL Editor → Run. Idempotent.

create table if not exists season_leaderboard_entries (
  user_id    uuid    not null references auth.users(id) on delete cascade,
  season_id  integer not null,
  nickname   text    not null check (char_length(nickname) between 1 and 20),
  xp         integer not null check (xp between 0 and 4200),
  updated_at timestamptz not null default now(),
  primary key (user_id, season_id)
);
alter table season_leaderboard_entries enable row level security;
-- Không policy: chỉ RPC security definer.
create index if not exists season_leaderboard_xp_idx on season_leaderboard_entries (season_id, xp desc, updated_at asc);

create or replace function season_current_id() returns integer
language sql stable as $$ select (floor(extract(epoch from now()) / 86400)::integer) / 28 $$;

create or replace function submit_season_xp(p_nickname text, p_season integer, p_xp integer) returns void
language plpgsql security definer set search_path = public as $$
declare v_name text := btrim(coalesce(p_nickname, ''));
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from auth.users where id = auth.uid() and is_anonymous) then raise exception 'email link required'; end if;
  if p_season is distinct from season_current_id() then return; end if;  -- chỉ mùa hiện tại
  if p_xp is null or p_xp <= 0 then return; end if;
  if char_length(v_name) not between 1 and 20 then raise exception 'bad nickname'; end if;
  insert into season_leaderboard_entries (user_id, season_id, nickname, xp)
  values (auth.uid(), p_season, v_name, least(p_xp, 4200))
  on conflict (user_id, season_id) do update
    set nickname = excluded.nickname,
        updated_at = case when excluded.xp > season_leaderboard_entries.xp then now() else season_leaderboard_entries.updated_at end,
        xp = greatest(season_leaderboard_entries.xp, excluded.xp);
end;
$$;

create or replace function season_leaderboard_top(p_limit integer default 50)
returns table (user_id uuid, nickname text, xp integer, rank bigint)
language sql stable security definer set search_path = public as $$
  select e.user_id, e.nickname, e.xp,
         row_number() over (order by e.xp desc, e.updated_at asc) as rank
    from season_leaderboard_entries e
   where e.season_id = season_current_id()
   order by rank
   limit least(greatest(p_limit, 1), 100)
$$;

revoke all on function submit_season_xp(text, integer, integer) from public, anon;
grant execute on function submit_season_xp(text, integer, integer) to authenticated;
grant execute on function season_leaderboard_top(integer) to anon, authenticated;

-- ── Thưởng cuối mùa ────────────────────────────────────────────────────────────────────────────────
-- Top 10 XP của mùa VỪA KẾT THÚC nhận 💎 (hạng 1/2/3 = 1000/600/400, 4-10 = 200). Chụp lười như thưởng BXH tuần: lần đầu
-- có người gọi season_reward_status() trong mùa mới thì server chụp top 10 của mùa trước (chỉ tài khoản liên kết email,
-- XP > 0). Nhận được trong suốt mùa hiện tại (28 ngày), MỘT lần cho mỗi mùa. Muốn chốt đúng giây: pg_cron gọi season_reward_snapshot().
create table if not exists season_reward_snapshots (
  season_id integer not null,
  rank      integer not null check (rank between 1 and 10),
  user_id   uuid    not null references auth.users(id) on delete cascade,
  nickname  text    not null,
  xp        integer not null,
  primary key (season_id, rank)
);
create index if not exists season_reward_snapshots_user_idx on season_reward_snapshots (user_id, season_id);
create table if not exists season_reward_claims (
  user_id    uuid    not null references auth.users(id) on delete cascade,
  season_id  integer not null,
  gems       integer not null,
  claimed_at timestamptz not null default now(),
  primary key (user_id, season_id)
);
alter table season_reward_snapshots enable row level security;
alter table season_reward_claims enable row level security;
-- Không policy: chỉ RPC security definer.

-- 💎 theo hạng. Khớp lib/core/season.dart (test so khớp).
create or replace function season_reward_gems(p_rank integer) returns integer
language sql immutable as $$
  select case p_rank when 1 then 1000 when 2 then 600 when 3 then 400 when 4 then 200 when 5 then 200
                     when 6 then 200 when 7 then 200 when 8 then 200 when 9 then 200 when 10 then 200 else 0 end
$$;

create or replace function season_reward_snapshot() returns void
language plpgsql security definer set search_path = public as $$
declare v_prev integer := season_current_id() - 1;
begin
  perform pg_advisory_xact_lock(hashtext('season_reward_snapshot'));
  if exists (select 1 from season_reward_snapshots where season_id = v_prev) then return; end if;
  insert into season_reward_snapshots (season_id, rank, user_id, nickname, xp)
  select v_prev, r.rn, r.user_id, r.nickname, r.xp from (
    select e.user_id, e.nickname, e.xp,
           row_number() over (order by e.xp desc, e.updated_at asc)::integer as rn
      from season_leaderboard_entries e join auth.users u on u.id = e.user_id
     where e.season_id = v_prev and e.xp > 0 and not u.is_anonymous) r
  where r.rn <= 10;
end;
$$;

-- Thưởng của mình ở mùa trước: [{season, rank, gems, claimed}] (rỗng nếu không có). Gọi hàm này kích hoạt việc chụp.
create or replace function season_reward_status() returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  perform season_reward_snapshot();
  return coalesce((
    select jsonb_agg(jsonb_build_object('season', s.season_id, 'rank', s.rank,
             'gems', season_reward_gems(s.rank),
             'claimed', exists (select 1 from season_reward_claims c where c.user_id = v_uid and c.season_id = s.season_id)))
      from season_reward_snapshots s
     where s.user_id = v_uid and s.season_id = season_current_id() - 1), '[]'::jsonb);
end;
$$;

create or replace function season_reward_claim(p_season integer) returns integer
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_rank integer; v_gems integer;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select s.rank into v_rank from season_reward_snapshots s
   where s.season_id = p_season and s.user_id = v_uid and s.season_id = season_current_id() - 1;
  if v_rank is null then raise exception 'not found'; end if;
  v_gems := season_reward_gems(v_rank);
  begin
    insert into season_reward_claims (user_id, season_id, gems) values (v_uid, p_season, v_gems);
  exception when unique_violation then
    raise exception 'already claimed';
  end;
  return v_gems;
end;
$$;

revoke all on function season_reward_snapshot() from public, anon, authenticated;
revoke all on function season_reward_status() from public, anon;
revoke all on function season_reward_claim(integer) from public, anon;
grant execute on function season_reward_status() to authenticated;
grant execute on function season_reward_claim(integer) to authenticated;
