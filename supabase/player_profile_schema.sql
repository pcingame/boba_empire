-- Hồ sơ công khai của người chơi cho trang web (?player=<tên>): hạng + điểm ở 5 BXH cá nhân.
-- Chỉ trả những gì BXH công khai đã hiện (tên → hạng/điểm), KHÔNG trả user_id.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase SQL Editor → Run. Idempotent. Chạy SAU
-- leaderboard_schema, m3_leaderboard_schema, accessory_leaderboard_schema, story_speedrun_schema
-- và accessory_market_schema (cần đủ 5 bảng điểm).
--
-- Tên không duy nhất: trùng tên thì lấy hạng CAO NHẤT của tên đó ở mỗi bảng. So khớp không phân
-- biệt hoa thường; đồng hạng/xếp theo đúng thứ tự của hàm *_top tương ứng.

create or replace function player_profile(p_nickname text)
returns table (board text, rank bigint, value numeric)
language sql
stable
security definer
set search_path = public
as $$
  with q as (
    select lower(btrim(p_nickname)) as n
    where char_length(btrim(p_nickname)) between 1 and 20
  ),
  income as (
    select 'income'::text as board, r.rank, r.v as value from (
      select nickname, row_number() over (order by lifetime_earnings desc, updated_at asc) as rank,
             lifetime_earnings::numeric as v
      from leaderboard_entries) r, q
    where lower(r.nickname) = q.n order by r.rank limit 1
  ),
  pearls as (
    select 'pearls'::text, r.rank, r.v from (
      select nickname, row_number() over (order by stars desc, updated_at asc) as rank,
             stars::numeric as v
      from m3_leaderboard_entries) r, q
    where lower(r.nickname) = q.n order by r.rank limit 1
  ),
  collection as (
    select 'collection'::text, r.rank, r.v from (
      select nickname, row_number() over (order by owned_count desc, updated_at asc) as rank,
             owned_count::numeric as v
      from accessory_leaderboard_entries) r, q
    where lower(r.nickname) = q.n order by r.rank limit 1
  ),
  speed as (
    select 'speed'::text, r.rank, r.v from (
      select nickname, row_number() over (order by complete_seconds asc, completed_at asc) as rank,
             complete_seconds::numeric as v
      from story_speedrun_entries) r, q
    where lower(r.nickname) = q.n order by r.rank limit 1
  ),
  vip as (
    select 'vip'::text, r.rank, r.v from (
      select nickname, row_number() over (order by vip_exp desc, updated_at asc) as rank,
             vip_exp::numeric as v
      from vip_leaderboard_entries) r, q
    where lower(r.nickname) = q.n order by r.rank limit 1
  )
  select * from income union all select * from pearls union all select * from collection
  union all select * from speed union all select * from vip;
$$;

grant execute on function player_profile(text) to anon, authenticated;
