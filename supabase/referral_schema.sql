-- "Mời bạn" (referral): mỗi người có một mã; bạn mới nhập mã MỘT lần để nhận 💎, người mời nhận 💎
-- khi bạn đó đạt giai đoạn đủ cao. Chỉ tài khoản ĐÃ liên kết email (không ẩn danh) mới dùng được —
-- tăng chi phí tạo tài khoản ảo để cày. Hằng số khớp lib/referral/referral_repository.dart
-- (test/referral/referral_sql_test.dart so khớp).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor → Run. Idempotent, độc lập
-- với các file schema khác. Giai đoạn do client tự khai (làm giả được); trần số lời mời chặn thiệt hại.

create or replace function referral_invitee_reward() returns integer
language sql immutable as $$ select 100 $$;
create or replace function referral_inviter_reward() returns integer
language sql immutable as $$ select 100 $$;
create or replace function referral_max_invites() returns integer
language sql immutable as $$ select 20 $$;
create or replace function referral_stage_needed() returns integer
language sql immutable as $$ select 3 $$;

-- JWT của Supabase có claim is_anonymous (true với đăng nhập ẩn danh).
create or replace function referral_is_real_user() returns boolean
language sql stable as $$
  select coalesce(
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'is_anonymous')::boolean,
    false) = false
$$;

create table if not exists referral_codes (
  user_id  uuid primary key references auth.users(id) on delete cascade,
  code     text not null unique check (code ~ '^[A-Z0-9]{6}$')
);

create table if not exists referrals (
  invitee_id      uuid primary key references auth.users(id) on delete cascade,
  inviter_id      uuid not null references auth.users(id) on delete cascade,
  created_at      timestamptz not null default now(),
  stage_reached   boolean not null default false,
  inviter_claimed boolean not null default false,
  check (invitee_id <> inviter_id)
);
create index if not exists referrals_inviter_idx on referrals (inviter_id);

alter table referral_codes enable row level security;
alter table referrals enable row level security;
-- Không policy nào: mọi truy cập qua RPC security definer.

-- Mã của tôi (tạo lần đầu gọi). Bảng chữ không có O/0/I/1 để khỏi đọc nhầm.
create or replace function referral_my_code() returns text
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_code text;
  v_alpha constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_try integer := 0;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if not referral_is_real_user() then raise exception 'email required'; end if;
  select code into v_code from referral_codes where user_id = v_uid;
  if v_code is not null then return v_code; end if;
  loop
    v_try := v_try + 1;
    v_code := '';
    for i in 1..6 loop
      v_code := v_code || substr(v_alpha, 1 + floor(random() * length(v_alpha))::integer, 1);
    end loop;
    begin
      insert into referral_codes (user_id, code) values (v_uid, v_code);
      return v_code;
    exception when unique_violation then
      -- Trùng mã (hoặc hai lần gọi song song của cùng người): thử đọc lại rồi mới sinh mã khác.
      select code into v_code from referral_codes where user_id = v_uid;
      if v_code is not null then return v_code; end if;
      if v_try > 20 then raise exception 'try again'; end if;
    end;
  end loop;
end;
$$;

-- Nhập mã của người mời (mỗi tài khoản một lần). Trả số 💎 người nhập được nhận.
create or replace function referral_redeem(p_code text) returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_inviter uuid;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if not referral_is_real_user() then raise exception 'email required'; end if;
  select user_id into v_inviter from referral_codes
    where code = upper(btrim(coalesce(p_code, '')));
  if v_inviter is null then raise exception 'not found'; end if;
  if v_inviter = v_uid then raise exception 'invalid code'; end if;
  -- Không cho hai người tự mời nhau (mỗi người nhận thưởng của người kia).
  if exists (select 1 from referrals where invitee_id = v_inviter and inviter_id = v_uid) then
    raise exception 'invalid code';
  end if;
  if (select count(*) from referrals where inviter_id = v_inviter) >= referral_max_invites() then
    raise exception 'inviter full';
  end if;
  begin
    insert into referrals (invitee_id, inviter_id) values (v_uid, v_inviter);
  exception when unique_violation then
    raise exception 'already redeemed';
  end;
  return referral_invitee_reward();
end;
$$;

-- Bạn được mời báo giai đoạn hiện tại; đủ [referral_stage_needed] thì người mời nhận được thưởng.
create or replace function referral_report_stage(p_stage integer) returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if p_stage is not null and p_stage >= referral_stage_needed() then
    update referrals set stage_reached = true where invitee_id = auth.uid();
  end if;
end;
$$;

create or replace function referral_status() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_invited integer;
  v_reached integer;
  v_claimable integer;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if not referral_is_real_user() then raise exception 'email required'; end if;
  select count(*), count(*) filter (where stage_reached),
         count(*) filter (where stage_reached and not inviter_claimed)
    into v_invited, v_reached, v_claimable
    from referrals where inviter_id = v_uid;
  return jsonb_build_object(
    'code', (select code from referral_codes where user_id = v_uid),
    'invited', v_invited,
    'reached', v_reached,
    'claimable', v_claimable,
    'redeemed', exists (select 1 from referrals where invitee_id = v_uid));
end;
$$;

-- Người mời nhận thưởng cho mọi bạn đã đạt giai đoạn mà chưa nhận. Trả tổng 💎.
create or replace function referral_claim() returns integer
language plpgsql security definer set search_path = public as $$
declare v_n integer;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if not referral_is_real_user() then raise exception 'email required'; end if;
  with u as (
    update referrals set inviter_claimed = true
      where inviter_id = auth.uid() and stage_reached and not inviter_claimed
      returning 1)
  select count(*) into v_n from u;
  if v_n = 0 then raise exception 'nothing to claim'; end if;
  return v_n * referral_inviter_reward();
end;
$$;

do $$
declare f text;
begin
  foreach f in array array[
    'referral_my_code()', 'referral_redeem(text)', 'referral_report_stage(integer)',
    'referral_status()', 'referral_claim()'
  ] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;
