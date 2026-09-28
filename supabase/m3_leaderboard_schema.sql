-- Schema cho "Bảng xếp hạng Trân Châu Rơi" — xếp theo TỔNG SAO của Hành trình
-- (chơi đơn), không phải điểm một màn.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor → Run.
-- Idempotent. Độc lập với các file schema khác, dán trước/sau đều được.
--
-- Vì sao xếp theo TỔNG SAO chứ không theo điểm cao nhất một màn: bàn cờ mỗi màn
-- là TẤT ĐỊNH (ai cũng gặp đúng bàn đó — xem Match3Level.seed), nên "điểm cao
-- nhất" chỉ đo được ai chịu khó chơi lại một màn nhiều lần. Tổng sao đo đúng
-- thứ người chơi thực sự đi được, và có trần rõ ràng nên kiểm tra được.
--
-- Khác story_speedrun (1 mốc, nộp đúng 1 lần): sao TĂNG DẦN theo thời gian nên
-- bảng này cho phép UPDATE hàng của chính mình (upsert mỗi lần mở trang).

create table if not exists m3_leaderboard_entries (
  user_id        uuid primary key references auth.users(id) on delete cascade,
  nickname       text not null check (char_length(nickname) between 1 and 20),
  -- Trần 1500 = 3 sao x 500 màn (trần trên của Balance.m3LevelCount khai báo
  -- trong remote_balance.dart). Không dùng 180 = 3 x 60 vì số màn tune được
  -- qua Remote Config; đặt sát quá là chặn nhầm người chơi thật sau này.
  stars          integer not null check (stars between 0 and 1500),
  levels_cleared integer not null check (levels_cleared between 0 and 500),
  updated_at     timestamptz not null default now(),
  -- Bất biến của luật chơi: mỗi màn tối đa 3 sao, nên tổng sao không bao giờ
  -- vượt 3 lần số màn đã qua. Chặn kiểu gian lận "1 màn, 900 sao".
  constraint m3_stars_le_3x_levels check (stars <= levels_cleared * 3)
);

create index if not exists m3_leaderboard_entries_stars_idx
  on m3_leaderboard_entries (stars desc, updated_at asc);

alter table m3_leaderboard_entries enable row level security;

-- Đọc: ai cũng được, kể cả chưa đăng nhập — bảng xếp hạng công khai.
drop policy if exists m3_leaderboard_select_all on m3_leaderboard_entries;
create policy m3_leaderboard_select_all on m3_leaderboard_entries
  for select to anon, authenticated using (true);

-- Ghi: chỉ hàng của chính mình.
drop policy if exists m3_leaderboard_insert_own on m3_leaderboard_entries;
create policy m3_leaderboard_insert_own on m3_leaderboard_entries
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists m3_leaderboard_update_own on m3_leaderboard_entries;
create policy m3_leaderboard_update_own on m3_leaderboard_entries
  for update to authenticated using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Sao chỉ được TĂNG. Không có trigger này thì ai đó lỡ chơi bằng save cũ (hoặc
-- xoá app chơi lại) sẽ tự đạp hạng của chính mình xuống.
create or replace function m3_leaderboard_no_downgrade()
returns trigger
language plpgsql
as $$
begin
  if new.stars < old.stars then
    new.stars := old.stars;
    new.levels_cleared := greatest(old.levels_cleared, new.levels_cleared);
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists m3_leaderboard_no_downgrade_trg on m3_leaderboard_entries;
create trigger m3_leaderboard_no_downgrade_trg
  before update on m3_leaderboard_entries
  for each row execute function m3_leaderboard_no_downgrade();

-- Top người nhiều sao nhất. Dùng top tuyệt đối (không phải "quanh hạng của
-- bạn"): số người chơi chế độ này ít hơn nhiều tổng người chơi, và người chưa
-- chơi thì vốn không có hàng nào để "quanh".
create or replace function m3_leaderboard_top(p_limit integer default 50)
returns table (
  user_id        uuid,
  nickname       text,
  stars          integer,
  levels_cleared integer,
  updated_at     timestamptz,
  rank           bigint
)
language sql
stable
as $$
  select user_id, nickname, stars, levels_cleared, updated_at,
         row_number() over (order by stars desc, updated_at asc) as rank
  from m3_leaderboard_entries
  order by stars desc, updated_at asc
  limit p_limit;
$$;

grant execute on function m3_leaderboard_top(integer) to anon, authenticated;
