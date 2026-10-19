-- Giới tính hồ sơ (tuỳ chọn, người chơi tự chọn, hiện trên hồ sơ công khai): male | female | other. Không chọn = không lưu gì.
-- Chỉ tài khoản đã liên kết email. Chạy SAU leaderboard_schema (tra user theo tên). Dán TOÀN BỘ vào SQL Editor → Run. Idempotent.

create table if not exists player_genders (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  gender     text not null check (gender in ('male', 'female', 'other')),
  updated_at timestamptz not null default now()
);
alter table player_genders enable row level security;
-- Không policy: chỉ RPC security definer.

-- p_gender '' = bỏ (xoá hàng).
create or replace function set_player_gender(p_gender text) returns void
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from auth.users where id = v_uid and is_anonymous) then raise exception 'not linked'; end if;
  if p_gender = '' then
    delete from player_genders where user_id = v_uid;
    return;
  end if;
  if p_gender not in ('male', 'female', 'other') then raise exception 'invalid gender'; end if;
  insert into player_genders (user_id, gender) values (v_uid, p_gender)
  on conflict (user_id) do update set gender = excluded.gender, updated_at = now();
end;
$$;

-- Giới tính của người có tên này ('' nếu không công khai). Tên trùng: lấy người có thu nhập cao nhất đã chọn.
create or replace function player_gender(p_nickname text) returns text
language sql stable security definer set search_path = public as $$
  select coalesce((
    select g.gender from leaderboard_entries e join player_genders g on g.user_id = e.user_id
     where lower(e.nickname) = lower(btrim(p_nickname))
     order by e.lifetime_earnings desc limit 1), '')
$$;

revoke all on function set_player_gender(text) from public, anon;
grant execute on function set_player_gender(text) to authenticated;
grant execute on function player_gender(text) to anon, authenticated;
