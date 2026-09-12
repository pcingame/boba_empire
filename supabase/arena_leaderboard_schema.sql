-- Schema cho "Bảng xếp hạng PK" — xếp hạng thắng/thua Đấu Trường (Arena PvP),
-- gộp trên TOÀN BỘ người chơi. Độc lập với arena_schema.sql (dán sau file đó,
-- không sửa gì trong file đó) và với leaderboard_schema.sql/
-- story_speedrun_schema.sql — dán trước/sau đều được.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor → Run.
-- Idempotent (dùng "if not exists"/"or replace").
--
-- Khác leaderboard_entries (điểm số do CLIENT tự báo, cần trigger chống gian
-- lận riêng): thắng/thua/số trận ở đây được TÍNH THẲNG từ arena_matches.winner
-- — cột này do arena_resolve_match() (security definer, arena_schema.sql) tự
-- chốt trên server, replay lại log hành động thật (arena_compute_score).
-- Client không có cách nào tự sửa số thắng/thua của mình → KHÔNG cần trigger
-- chống gian lận như leaderboard_entries.
--
-- Tên hiển thị: TÁCH RIÊNG khỏi arena_matches, giữ đúng triết lý "không có
-- policy ghi trực tiếp" của Đấu Trường (xem đầu arena_schema.sql) — client chỉ
-- gọi arena_set_nickname(), không upsert thẳng bảng như leaderboard_entries.
-- Dùng CHUNG tên với Bảng xếp hạng chính/Tốc độ hoàn thành (key
-- 'leaderboard_nickname' phía Flutter) — không hỏi lại người chơi đã đặt tên
-- rồi.

create table if not exists arena_nicknames (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  nickname   text not null check (char_length(nickname) between 1 and 20),
  updated_at timestamptz not null default now()
);

alter table arena_nicknames enable row level security;
-- Không có policy nào cho client (giống các bảng khác của Đấu Trường) — chỉ
-- đọc/ghi qua các hàm security definer bên dưới.

create or replace function arena_set_nickname(p_nickname text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'not authenticated';
  end if;
  if p_nickname is null or char_length(trim(p_nickname)) not between 1 and 20 then
    raise exception 'nickname phải dài 1-20 ký tự';
  end if;
  insert into arena_nicknames (user_id, nickname, updated_at)
  values (me, trim(p_nickname), now())
  on conflict (user_id) do update
    set nickname = excluded.nickname, updated_at = excluded.updated_at;
end;
$$;

grant execute on function arena_set_nickname(text) to authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- Xếp hạng: THẮNG NHIỀU NHẤT trước (không phải tỉ lệ thắng %) — tỉ lệ thắng
-- trần trụi bị lệch nặng lúc ít trận (thắng 1/1 = 100%, đứng trên người thắng
-- 40/50). Xếp theo tổng số trận thắng, hoà thì ai ít trận hơn (hiệu suất cao
-- hơn) đứng trên — không cộng thêm ngưỡng "tối thiểu N trận" để giữ đơn giản,
-- MVP không cần cấu hình thêm. Có thể đổi lại nếu sau này thấy tỉ lệ thắng
-- (kèm ngưỡng số trận) phù hợp hơn khi có nhiều người chơi thật.
--
-- SECURITY DEFINER: arena_matches chỉ cho SELECT đúng 2 người trong trận
-- (arena_matches_select_own, arena_schema.sql) — hàm này cần đọc TOÀN BỘ
-- bảng để gộp thắng/thua của mọi người, phải bỏ qua RLS đó.
--
-- Giống leaderboard_around_me: trả về [p_window] người TRÊN + chính bạn +
-- [p_window] người DƯỚI theo hạng. Nếu bạn CHƯA có trận nào (không nằm trong
-- kết quả gộp), trả về top (2×p_window + 1) thay vào đó — vẫn xem được bảng
-- xếp hạng dù chưa từng đấu.
create or replace function arena_leaderboard_around_me(p_window integer default 5)
returns table (
  user_id  uuid,
  nickname text,
  wins     bigint,
  losses   bigint,
  matches  bigint,
  rank     bigint
)
language sql
stable
security definer
set search_path = public
as $$
  with stats as (
    select player_id,
           count(*) filter (where won) as wins,
           count(*) filter (where not won) as losses,
           count(*) as matches
    from (
      select player_a as player_id, (winner = player_a) as won
        from arena_matches where status = 'finished'
      union all
      select player_b as player_id, (winner = player_b) as won
        from arena_matches where status = 'finished'
    ) per_player
    group by player_id
  ),
  ranked as (
    select
      s.player_id as user_id,
      coalesce(n.nickname, '???') as nickname,
      s.wins, s.losses, s.matches,
      row_number() over (order by s.wins desc, s.matches asc, s.player_id) as rank
    from stats s
    left join arena_nicknames n on n.user_id = s.player_id
  ),
  my_rank as (
    select rank from ranked where user_id = auth.uid()
  )
  select r.user_id, r.nickname, r.wins, r.losses, r.matches, r.rank
  from ranked r
  where case
    when exists (select 1 from my_rank)
      then r.rank between (select rank from my_rank) - p_window
                       and (select rank from my_rank) + p_window
    else r.rank <= (2 * p_window + 1)
  end
  order by r.rank;
$$;

grant execute on function arena_leaderboard_around_me(integer) to authenticated;
