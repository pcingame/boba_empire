-- Trao đổi vật phẩm ở Chợ: "đổi món X lấy món Y" giữa hai người, không qua Xu Chợ (góp ý người chơi: "thêm
-- tính năng trao đổi vật phẩm", "Chợ toàn vô hạn xu").
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase SQL Editor → Run. Idempotent. Chạy SAU
-- accessory_market_schema.sql (dùng bảng accessory_server_ownership và hằng số market_listing_days()).
-- KHÔNG đụng bảng/hàm cũ.
--
-- Luồng (cùng khuôn đăng bán): người đăng đưa món X vào "ký quỹ" (rời accessory_server_ownership ngay lúc
-- đăng) và nói muốn món Y. Người khác đang có Y bấm nhận → MỘT transaction: Y từ người nhận sang người đăng,
-- X từ ký quỹ sang người nhận. Đề nghị sống tối đa market_listing_days() ngày rồi hết hạn (món về kho server
-- người đăng). Máy người đăng chưa biết đề nghị đã xong/hết hạn → swap_collect() trả danh sách món cần thêm
-- vào kho cục bộ, thêm xong gọi swap_ack() (hai pha, giống expire_my_listings: app tắt giữa chừng không mất món).
--
-- Mức tin cậy như phần còn lại của Chợ: số bản sao do client tự khai (register_accessory_copies).

create table if not exists accessory_swaps (
  id            uuid primary key default gen_random_uuid(),
  seller_id     uuid not null references auth.users(id),
  give_id       text not null check (char_length(give_id) between 1 and 64),
  want_id       text not null check (char_length(want_id) between 1 and 64 and want_id <> give_id),
  status        text not null default 'open', -- open|done|cancelled|expired
  taker_id      uuid references auth.users(id),
  created_at    timestamptz not null default now(),
  resolved_at   timestamptz,
  -- false: server đã chuyển món (nhận Y / trả lại X) nhưng máy người đăng chưa thêm vào kho cục bộ.
  seller_acked  boolean not null default true
);
create index if not exists accessory_swaps_open_idx on accessory_swaps (status, created_at desc);
create index if not exists accessory_swaps_seller_idx on accessory_swaps (seller_id, status);

alter table accessory_swaps enable row level security;

-- Đọc: người đã đăng nhập; đề nghị quá hạn chưa được quét cũng bị ẩn (xem market_listing_days()).
drop policy if exists accessory_swaps_select on accessory_swaps;
create policy accessory_swaps_select on accessory_swaps
  for select to authenticated
  using (status <> 'open' or created_at > now() - make_interval(days => market_listing_days()));
-- Không policy insert/update/delete: chỉ qua RPC.

-- Mỗi người mở tối đa chừng này đề nghị cùng lúc (chống spam danh sách).
create or replace function swap_max_open() returns integer
language sql immutable as $$ select 5 $$;

-- Trả mọi món ký quỹ của đề nghị quá hạn về kho server người đăng, gộp theo (người, món) để
-- ON CONFLICT không đụng một hàng hai lần. [p_seller] null = mọi người. Nội bộ (revoke cuối file).
create or replace function swap_sweep(p_seller uuid default null) returns void
language plpgsql security definer set search_path = public as $$
begin
  with e as (
    update accessory_swaps
       set status = 'expired', resolved_at = now(), seller_acked = false
     where status = 'open'
       and created_at <= now() - make_interval(days => market_listing_days())
       and (p_seller is null or seller_id = p_seller)
    returning seller_id, give_id
  ), g as (
    select seller_id, give_id, count(*)::integer as n from e group by seller_id, give_id
  )
  insert into accessory_server_ownership (user_id, accessory_id, copies)
  select seller_id, give_id, n from g
  on conflict (user_id, accessory_id) do update
    set copies = accessory_server_ownership.copies + excluded.copies;
end;
$$;

-- Tạo đề nghị: ký quỹ món [p_give] (phải có trong kho server của mình), muốn món [p_want].
create or replace function swap_create(p_give text, p_want text) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_left integer;
  v_id uuid;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_give is null or p_want is null or p_give = p_want
     or char_length(p_give) not between 1 and 64 or char_length(p_want) not between 1 and 64 then
    raise exception 'invalid_swap';
  end if;

  perform swap_sweep(v_uid);
  if (select count(*) from accessory_swaps where seller_id = v_uid and status = 'open') >= swap_max_open() then
    raise exception 'too_many_swaps';
  end if;

  update accessory_server_ownership set copies = copies - 1
   where user_id = v_uid and accessory_id = p_give
  returning copies into v_left;
  if not found then raise exception 'not_owned'; end if;
  if v_left <= 0 then
    delete from accessory_server_ownership where user_id = v_uid and accessory_id = p_give;
  end if;

  insert into accessory_swaps (seller_id, give_id, want_id) values (v_uid, p_give, p_want)
  returning id into v_id;
  return v_id;
end;
$$;

-- Huỷ đề nghị còn hiệu lực của mình: trả món ký quỹ về kho server (client tự thêm lại cục bộ).
create or replace function swap_cancel(p_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_seller uuid;
  v_give text;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select seller_id, give_id into v_seller, v_give from accessory_swaps
   where id = p_id and status = 'open'
     and created_at > now() - make_interval(days => market_listing_days())
   for update;
  if not found then raise exception 'swap_not_open'; end if;
  if v_seller <> v_uid then raise exception 'not_your_swap'; end if;
  update accessory_swaps set status = 'cancelled', resolved_at = now() where id = p_id;
  insert into accessory_server_ownership (user_id, accessory_id) values (v_seller, v_give)
  on conflict (user_id, accessory_id) do update
    set copies = accessory_server_ownership.copies + 1;
end;
$$;

-- Nhận đề nghị: người nhận phải CÓ món người đăng muốn. MỘT transaction, khoá hàng đề nghị trước khi
-- đổi gì (chặn hai người nhận cùng lúc). Người đăng nhận món muốn (máy họ thêm lại qua swap_collect).
create or replace function swap_accept(p_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_seller uuid;
  v_give text;
  v_want text;
  v_left integer;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select seller_id, give_id, want_id into v_seller, v_give, v_want from accessory_swaps
   where id = p_id and status = 'open'
     and created_at > now() - make_interval(days => market_listing_days())
   for update;
  if not found then raise exception 'swap_not_open'; end if;
  if v_seller = v_uid then raise exception 'cannot_accept_own_swap'; end if;

  update accessory_server_ownership set copies = copies - 1
   where user_id = v_uid and accessory_id = v_want
  returning copies into v_left;
  if not found then raise exception 'not_owned_want'; end if;
  if v_left <= 0 then
    delete from accessory_server_ownership where user_id = v_uid and accessory_id = v_want;
  end if;

  insert into accessory_server_ownership (user_id, accessory_id) values (v_seller, v_want)
  on conflict (user_id, accessory_id) do update
    set copies = accessory_server_ownership.copies + 1;
  insert into accessory_server_ownership (user_id, accessory_id) values (v_uid, v_give)
  on conflict (user_id, accessory_id) do update
    set copies = accessory_server_ownership.copies + 1;

  update accessory_swaps
     set status = 'done', taker_id = v_uid, resolved_at = now(), seller_acked = false
   where id = p_id;
end;
$$;

-- Người đăng mở Chợ: quét đề nghị quá hạn của mình rồi trả các món MÁY CHƯA thêm vào kho cục bộ:
-- done → thêm [want_id] (món đổi được); expired → thêm [give_id] (món ký quỹ được trả lại).
create or replace function swap_collect()
returns table (id uuid, status text, give_id text, want_id text)
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  perform swap_sweep(auth.uid());
  return query
    select s.id, s.status, s.give_id, s.want_id from accessory_swaps s
     where s.seller_id = auth.uid() and s.status in ('done', 'expired') and not s.seller_acked
     order by s.resolved_at;
end;
$$;

-- Máy đã thêm các món trên vào kho cục bộ → đánh dấu để lần sau không trả lại.
create or replace function swap_ack(p_ids uuid[]) returns void
language sql security definer set search_path = public as $$
  update accessory_swaps set seller_acked = true
   where seller_id = auth.uid() and status in ('done', 'expired') and id = any (p_ids);
$$;

-- Quyền: chỉ người đã đăng nhập; hàm quét nội bộ khoá hẳn.
revoke all on function swap_create(text, text) from public, anon;
revoke all on function swap_cancel(uuid) from public, anon;
revoke all on function swap_accept(uuid) from public, anon;
revoke all on function swap_collect() from public, anon;
revoke all on function swap_ack(uuid[]) from public, anon;
grant execute on function swap_create(text, text) to authenticated;
grant execute on function swap_cancel(uuid) to authenticated;
grant execute on function swap_accept(uuid) to authenticated;
grant execute on function swap_collect() to authenticated;
grant execute on function swap_ack(uuid[]) to authenticated;
revoke all on function swap_sweep(uuid) from public, anon, authenticated;
