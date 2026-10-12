-- Hồ sơ công khai của người chơi cho trang web (?player=<tên>): hạng + điểm ở 5 BXH cá nhân,
-- cộng 1 dòng 'guild' (hạng + điểm tuần của hội đang ở; cột label = tên hội) nếu hội có trên BXH Hội.
-- Chỉ trả những gì BXH công khai đã hiện (tên → hạng/điểm), KHÔNG trả user_id.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase SQL Editor → Run. Idempotent. Chạy SAU
-- leaderboard_schema, m3_leaderboard_schema, accessory_leaderboard_schema, story_speedrun_schema
-- và accessory_market_schema (cần đủ 5 bảng điểm) và guild_schema (dòng hội).
--
-- Tên không duy nhất: trùng tên thì lấy hạng CAO NHẤT của tên đó ở mỗi bảng. So khớp không phân
-- biệt hoa thường; đồng hạng/xếp theo đúng thứ tự của hàm *_top tương ứng.

-- Thêm cột label → đổi kiểu trả về nên phải drop hàm cũ trước (create or replace không đổi được).
drop function if exists player_profile(text);
create function player_profile(p_nickname text)
returns table (board text, rank bigint, value numeric, label text)
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
  ),
  -- Hội đang ở (cùng điều kiện hiện của guild_leaderboard: không bị ẩn, điểm tuần > 0). Tên
  -- trùng thì lấy hội có hạng cao nhất.
  guild as (
    select 'guild'::text, r.rank, r.total::numeric,
           r.emoji || ' ' || r.name || ' [' || r.tag || ']'
    from (
      select row_number() over (order by t.total desc, g.created_at asc) as rank,
             g.id, g.name, g.tag, g.emoji, t.total
      from guilds g
      cross join lateral (select guild_week_total(g.id) as total) t
      where not g.hidden and t.total > 0) r
    join guild_members m on m.guild_id = r.id, q
    where lower(m.nickname) = q.n order by r.rank limit 1
  )
  select x.*, null::text from income x
  union all select x.*, null::text from pearls x
  union all select x.*, null::text from collection x
  union all select x.*, null::text from speed x
  union all select x.*, null::text from vip x
  union all select x.* from guild x;
$$;

grant execute on function player_profile(text) to anon, authenticated;
