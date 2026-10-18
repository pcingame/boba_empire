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
