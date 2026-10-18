-- Avatar ảnh của người chơi (hiện trên trang hồ sơ của mình và hồ sơ công khai).
-- Ảnh nằm ở Supabase Storage, bucket công khai 'avatars', tên file = <khoá ngẫu nhiên>.jpg (KHÔNG lộ user_id).
-- Luồng: client gọi new_avatar_key() (server cấp khoá + ghi nhận của ai) → upload <khoá>.jpg (policy Storage chỉ cho đúng
-- chủ khoá, ≤100KB, chỉ JPEG) → hiện bằng URL công khai. Tra avatar người khác theo tên bằng player_avatar(tên).
-- Chỉ tài khoản liên kết email. Báo cáo: report_avatar(tên); đủ 3 người báo cáo khác nhau cho CÙNG một ảnh → tự ẩn (hidden)
-- chờ duyệt. Duyệt tay: select * from avatar_reports ...; gỡ: update player_avatars set hidden = true where user_id = '...';
-- bỏ ẩn: set hidden = false. Người bị ẩn đổi ảnh mới thì hết ẩn (báo cáo gắn với từng ảnh).
-- Dán TOÀN BỘ vào Supabase SQL Editor → Run. Idempotent. Chạy SAU leaderboard_schema (tra tên ở leaderboard_entries).

create table if not exists player_avatars (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  key        uuid not null,
  prev_key   uuid,
  hidden     boolean not null default false,
  updated_at timestamptz not null default now()
);
alter table player_avatars add column if not exists prev_key uuid;
alter table player_avatars enable row level security;
-- Không policy cho client: chỉ RPC security definer (và policy Storage bên dưới, tự đọc bảng qua hàm).

-- Cấp khoá mới cho ảnh sắp tải lên; trả về khoá cũ (client xoá file cũ sau khi tải xong) hoặc null.
create or replace function new_avatar_key() returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_old uuid; v_new uuid := gen_random_uuid();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from auth.users where id = v_uid and is_anonymous) then raise exception 'not linked'; end if;
  select key into v_old from player_avatars where user_id = v_uid;
  insert into player_avatars (user_id, key) values (v_uid, v_new)
  on conflict (user_id) do update
    set key = excluded.key, prev_key = player_avatars.key, hidden = false, updated_at = now();
  return jsonb_build_object('key', v_new, 'old', v_old);
end;
$$;

create or replace function clear_avatar() returns uuid
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_old uuid;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  delete from player_avatars where user_id = v_uid returning key into v_old;
  return v_old;
end;
$$;

-- Khoá avatar công khai của người có tên này ('' nếu không có/bị ẩn). Tên trùng: lấy người thu nhập cao nhất có avatar.
create or replace function player_avatar(p_nickname text) returns text
language sql stable security definer set search_path = public as $$
  select coalesce((
    select a.key::text from leaderboard_entries e join player_avatars a on a.user_id = e.user_id
     where lower(e.nickname) = lower(btrim(p_nickname)) and not a.hidden
     order by e.lifetime_earnings desc limit 1), '')
$$;

-- Chủ sở hữu khoá? (dùng cho policy Storage; security definer vì client không đọc được player_avatars.)
create or replace function avatar_key_owned(p_name text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from player_avatars a
                  where a.user_id = auth.uid() and a.key::text || '.jpg' = p_name)
$$;

-- Được xoá file này? (khoá hiện tại hoặc khoá ngay trước — client xoá ảnh cũ SAU khi đã đổi khoá.)
create or replace function avatar_key_deletable(p_name text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from player_avatars a
                  where a.user_id = auth.uid()
                    and (a.key::text || '.jpg' = p_name or a.prev_key::text || '.jpg' = p_name))
$$;
grant execute on function avatar_key_deletable(text) to authenticated;

revoke all on function new_avatar_key() from public, anon;
revoke all on function clear_avatar() from public, anon;
grant execute on function new_avatar_key() to authenticated;
grant execute on function clear_avatar() to authenticated;
grant execute on function player_avatar(text) to anon, authenticated;
grant execute on function avatar_key_owned(text) to authenticated;

-- Storage (bỏ qua nếu môi trường không có Storage, vd Postgres tạm khi test).
do $$
begin
  if to_regclass('storage.objects') is null then return; end if;
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('avatars', 'avatars', true, 102400, array['image/jpeg'])
  on conflict (id) do update set public = true, file_size_limit = 102400, allowed_mime_types = array['image/jpeg'];
  drop policy if exists avatars_insert_own on storage.objects;
  create policy avatars_insert_own on storage.objects for insert to authenticated
    with check (bucket_id = 'avatars' and avatar_key_owned(name));
  drop policy if exists avatars_delete_own on storage.objects;
  create policy avatars_delete_own on storage.objects for delete to authenticated
    using (bucket_id = 'avatars' and avatar_key_deletable(name));
end $$;

-- Báo cáo ảnh vi phạm. Server tự tra ảnh hiện tại của người có tên đó (client không chỉ định khoá tuỳ ý).
create table if not exists avatar_reports (
  reporter   uuid not null references auth.users(id) on delete cascade,
  key        uuid not null,
  created_at timestamptz not null default now(),
  primary key (reporter, key)
);
alter table avatar_reports enable row level security;
-- Không policy: chỉ RPC.

-- Số người báo cáo khác nhau để tự ẩn ảnh (chờ duyệt).
create or replace function avatar_report_threshold() returns integer
language sql immutable as $$ select 3 $$;

-- Trả true nếu ảnh vừa bị ẩn do đủ báo cáo.
create or replace function report_avatar(p_nickname text) returns boolean
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_owner uuid; v_key uuid; v_n integer;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from auth.users where id = v_uid and is_anonymous) then raise exception 'not linked'; end if;
  select a.user_id, a.key into v_owner, v_key
    from leaderboard_entries e join player_avatars a on a.user_id = e.user_id
   where lower(e.nickname) = lower(btrim(p_nickname)) and not a.hidden
   order by e.lifetime_earnings desc limit 1;
  if v_key is null then raise exception 'not found'; end if;
  if v_owner = v_uid then raise exception 'own avatar'; end if;
  insert into avatar_reports (reporter, key) values (v_uid, v_key) on conflict do nothing;
  select count(*) into v_n from avatar_reports where key = v_key;
  if v_n >= avatar_report_threshold() then
    update player_avatars set hidden = true where user_id = v_owner and key = v_key;
    return true;
  end if;
  return false;
end;
$$;
revoke all on function report_avatar(text) from public, anon;
grant execute on function report_avatar(text) to authenticated;
