-- Schema cho "Bảng xếp hạng Sự kiện" — mỗi dịp lễ (xem `festivals` trong
-- lib/core/accessories.dart) một bảng riêng, xếp theo ĐIỂM SỰ KIỆN
-- (lib/core/event_quests.dart: eventScore = chạm ly + 50 x (mèo Mưa vàng + khách VIP)).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor → Run.
-- Idempotent. Độc lập với các file schema khác.
--
-- Chống gian lận: client KHÔNG ghi thẳng vào bảng (không có policy insert/update).
-- Mọi lần nộp đi qua `event_leaderboard_submit` (security definer) kiểm:
--   1. dịp lễ có thật và đang diễn ra (giờ SERVER, không tin giờ máy),
--   2. điểm không vượt tốc độ tối đa hợp lý (event_score_per_hour x số giờ đã trôi),
--   3. điểm chỉ tăng (nộp bằng save cũ không đạp hạng).
--
-- ⚠️ Khi thêm/đổi dịp lễ trong Dart PHẢI sửa `event_leaderboard_window` ở đây
-- cho khớp — test/leaderboard/event_leaderboard_test.dart so khớp hai bên.

create table if not exists event_leaderboard_entries (
  festival_id text not null,
  user_id     uuid not null references auth.users(id) on delete cascade,
  nickname    text not null check (char_length(nickname) between 1 and 20),
  score       bigint not null check (score between 0 and 1000000000),
  updated_at  timestamptz not null default now(),
  primary key (festival_id, user_id)
);

create index if not exists event_leaderboard_entries_rank_idx
  on event_leaderboard_entries (festival_id, score desc, updated_at asc);

alter table event_leaderboard_entries enable row level security;

drop policy if exists event_leaderboard_select_all on event_leaderboard_entries;
create policy event_leaderboard_select_all on event_leaderboard_entries
  for select to anon, authenticated using (true);
-- Cố ý KHÔNG có policy insert/update/delete: chỉ RPC bên dưới được ghi.

-- Cửa sổ [start, end) (UTC) của từng dịp — khớp `festivals` trong Dart.
create or replace function event_leaderboard_window(p_festival text)
returns table (starts_at timestamptz, ends_at timestamptz)
language sql
immutable
as $$
  select s, e from (values
    ('halloween',  timestamptz '2026-10-24 00:00:00+00', timestamptz '2026-11-03 00:00:00+00'),
    ('christmas',  timestamptz '2026-12-18 00:00:00+00', timestamptz '2026-12-28 00:00:00+00'),
    ('new_year',   timestamptz '2026-12-28 00:00:00+00', timestamptz '2027-01-04 00:00:00+00'),
    ('tet',        timestamptz '2027-01-30 00:00:00+00', timestamptz '2027-02-10 00:00:00+00'),
    ('valentine',  timestamptz '2027-02-10 00:00:00+00', timestamptz '2027-02-16 00:00:00+00'),
    ('womens_day', timestamptz '2027-03-04 00:00:00+00', timestamptz '2027-03-10 00:00:00+00'),
    ('mid_autumn', timestamptz '2027-09-08 00:00:00+00', timestamptz '2027-09-18 00:00:00+00')
  ) as t(id, s, e)
  where id = p_festival;
$$;

-- Tốc độ điểm tối đa mỗi giờ (≈ 28 chạm/giây liên tục — người thật không tới).
create or replace function event_score_per_hour()
returns integer language sql immutable as $$ select 100000 $$;

create or replace function event_leaderboard_submit(
  p_festival text,
  p_nickname text,
  p_score    bigint
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_start timestamptz;
  v_end   timestamptz;
  v_hours numeric;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if p_score < 0 or char_length(coalesce(p_nickname, '')) not between 1 and 20 then
    raise exception 'invalid input';
  end if;

  select starts_at, ends_at into v_start, v_end
    from event_leaderboard_window(p_festival);
  if v_start is null then
    raise exception 'unknown festival';
  end if;
  if now() < v_start or now() >= v_end then
    raise exception 'festival not active';
  end if;

  v_hours := greatest(extract(epoch from (now() - v_start)) / 3600.0, 1);
  if p_score > ceil(v_hours * event_score_per_hour()) then
    raise exception 'score too high';
  end if;

  insert into event_leaderboard_entries (festival_id, user_id, nickname, score)
  values (p_festival, auth.uid(), p_nickname, p_score)
  on conflict (festival_id, user_id) do update
    set nickname   = excluded.nickname,
        score      = greatest(event_leaderboard_entries.score, excluded.score),
        updated_at = now();
end;
$$;

revoke all on function event_leaderboard_submit(text, text, bigint) from public;
grant execute on function event_leaderboard_submit(text, text, bigint) to authenticated;

create or replace function event_leaderboard_top(p_festival text, p_limit integer default 50)
returns table (
  user_id    uuid,
  nickname   text,
  score      bigint,
  updated_at timestamptz,
  rank       bigint
)
language sql
stable
as $$
  select user_id, nickname, score, updated_at,
         row_number() over (order by score desc, updated_at asc) as rank
  from event_leaderboard_entries
  where festival_id = p_festival
  order by score desc, updated_at asc
  limit least(p_limit, 100);
$$;

grant execute on function event_leaderboard_top(text, integer) to anon, authenticated;
