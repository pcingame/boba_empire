-- Danh hiệu hồ sơ: người chơi chọn 1 danh hiệu (mở khoá ở client từ tiến độ) để hiện trên hồ sơ công khai.
-- Thuần trang trí nên server chỉ kiểm whitelist id + tài khoản đã liên kết email (không ẩn danh).
-- Khớp lib/core/titles.dart (test so khớp). Dán TOÀN BỘ vào Supabase SQL Editor → Run. Idempotent.
-- Chạy SAU leaderboard_schema (tra user theo tên ở leaderboard_entries).

create table if not exists player_titles (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  title_id   text not null,
  updated_at timestamptz not null default now()
);
alter table player_titles enable row level security;
-- Không policy: chỉ RPC security definer.

create or replace function set_player_title(p_id text) returns void
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from auth.users where id = v_uid and is_anonymous) then raise exception 'not linked'; end if;
  if p_id = '' then
    delete from player_titles where user_id = v_uid;
    return;
  end if;
  if p_id not in ('tycoon', 'mogul', 'legend', 'timewalker', 'stargazer', 'collector', 'vip') then
    raise exception 'invalid title';
  end if;
  insert into player_titles (user_id, title_id) values (v_uid, p_id)
  on conflict (user_id) do update set title_id = excluded.title_id, updated_at = now();
end;
$$;

-- Danh hiệu của người có tên này ('' nếu không có). Tên trùng: lấy người có thu nhập cao nhất đã chọn danh hiệu.
create or replace function player_title(p_nickname text) returns text
language sql stable security definer set search_path = public as $$
  select coalesce((
    select t.title_id from leaderboard_entries e join player_titles t on t.user_id = e.user_id
     where lower(e.nickname) = lower(btrim(p_nickname))
     order by e.lifetime_earnings desc limit 1), '')
$$;

revoke all on function set_player_title(text) from public, anon;
grant execute on function set_player_title(text) to authenticated;
grant execute on function player_title(text) to anon, authenticated;
