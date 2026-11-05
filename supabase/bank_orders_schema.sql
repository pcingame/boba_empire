-- Nạp tiền bằng chuyển khoản ngân hàng (bản Android tải APK, không có Google Play Billing).
-- Luồng: app gọi bank_create_order(product) → hiện QR VietQR kèm MÃ ĐƠN làm nội dung chuyển khoản →
-- SePay (hoặc Casso) đọc giao dịch ngân hàng, gọi webhook (supabase/functions/sepay-webhook) → bank_mark_paid()
-- đổi đơn sang 'paid' → app hỏi bank_my_paid() rồi trao hàng và gọi bank_ack() (hai pha như auction_collect:
-- tắt app giữa chừng không mất hàng).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase SQL Editor → Run. Idempotent. Không đụng bảng/hàm cũ.
-- GIÁ Ở ĐÂY LÀ NGUỒN SỰ THẬT (client chỉ hiển thị) — phải khớp `bankPriceVnd` trong lib/iap/bank_config.dart
-- (test/iap/bank_price_sql_test.dart so khớp). Giá hiện tại là ƯỚC LƯỢNG, chỉnh trước khi mở bán.

create table if not exists bank_prices (
  product_id text primary key,
  amount_vnd integer not null check (amount_vnd > 0)
);
alter table bank_prices enable row level security;
-- Không policy: chỉ hàm security definer đọc được.

insert into bank_prices (product_id, amount_vnd) values
  ('boba_gems_small', 20000),
  ('boba_gems_medium', 100000),
  ('boba_gems_large', 200000),
  ('boba_gems_huge', 300000),
  ('boba_gems_mega', 400000),
  ('boba_remove_ads', 60000),
  ('boba_double_income', 100000),
  ('boba_piggy', 40000),
  ('boba_vip30', 100000),
  ('boba_starter_pack', 40000),
  ('boba_cold_storage', 60000),
  ('boba_combo_noads_x2', 120000)
on conflict (product_id) do update set amount_vnd = excluded.amount_vnd;

create table if not exists bank_orders (
  code        text primary key,                      -- 'BE' + 8 ký tự, là nội dung chuyển khoản
  user_id     uuid not null references auth.users(id),
  product_id  text not null references bank_prices(product_id),
  amount_vnd  integer not null,
  status      text not null default 'pending' check (status in ('pending', 'paid', 'delivered')),
  bank_tx_id  text unique,                           -- id giao dịch của SePay: chống webhook gọi lặp
  created_at  timestamptz not null default now(),
  paid_at     timestamptz
);
alter table bank_orders enable row level security;
create index if not exists bank_orders_user_idx on bank_orders (user_id, status);

-- Tạo đơn. Còn đơn pending cùng sản phẩm trong 30 phút thì dùng lại (bấm mua nhiều lần không đẻ đơn rác).
create or replace function bank_create_order(p_product text)
returns json
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_amount integer;
  v_code text;
  v_row bank_orders;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  select amount_vnd into v_amount from bank_prices where product_id = p_product;
  if v_amount is null then raise exception 'unknown_product'; end if;

  select * into v_row from bank_orders
   where user_id = v_user and product_id = p_product and status = 'pending'
     and created_at > now() - interval '30 minutes'
   order by created_at desc limit 1;
  if found then
    return json_build_object('code', v_row.code, 'amount', v_row.amount_vnd);
  end if;

  if (select count(*) from bank_orders
       where user_id = v_user and status = 'pending' and created_at > now() - interval '1 day') >= 10 then
    raise exception 'too_many_pending';
  end if;

  loop
    v_code := 'BE' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 8));
    exit when not exists (select 1 from bank_orders where code = v_code);
  end loop;
  insert into bank_orders (code, user_id, product_id, amount_vnd)
  values (v_code, v_user, p_product, v_amount);
  return json_build_object('code', v_code, 'amount', v_amount);
end $$;

-- Các đơn ĐÃ THANH TOÁN nhưng chưa trao hàng của chính mình.
create or replace function bank_my_paid()
returns table (code text, product_id text)
language sql stable security definer set search_path = public as $$
  select code, product_id from bank_orders
   where user_id = auth.uid() and status = 'paid' order by paid_at;
$$;

-- Máy trao hàng xong thì báo; idempotent.
create or replace function bank_ack(p_codes text[])
returns void
language sql security definer set search_path = public as $$
  update bank_orders set status = 'delivered'
   where user_id = auth.uid() and status = 'paid' and code = any(p_codes);
$$;

-- Trạng thái một đơn (để hộp QR tự đóng khi tiền về).
create or replace function bank_order_status(p_code text)
returns text
language sql stable security definer set search_path = public as $$
  select status from bank_orders where code = p_code and user_id = auth.uid();
$$;

-- CHỈ webhook (service role) gọi. Trả 'paid' | 'already' | 'unknown' | 'short' (chuyển thiếu tiền).
-- Chuyển DƯ vẫn nhận (trao đúng 1 món); chuyển THIẾU thì không trao, admin xử lý tay.
create or replace function bank_mark_paid(p_code text, p_amount integer, p_tx text)
returns text
language plpgsql security definer set search_path = public as $$
declare v_row bank_orders;
begin
  select * into v_row from bank_orders where code = upper(p_code) for update;
  if not found then return 'unknown'; end if;
  if v_row.status <> 'pending' then return 'already'; end if;
  if p_amount < v_row.amount_vnd then return 'short'; end if;
  update bank_orders set status = 'paid', paid_at = now(), bank_tx_id = p_tx where code = v_row.code;
  return 'paid';
exception when unique_violation then
  return 'already';
end $$;

revoke all on function bank_create_order(text) from public, anon;
revoke all on function bank_my_paid() from public, anon;
revoke all on function bank_ack(text[]) from public, anon;
revoke all on function bank_order_status(text) from public, anon;
revoke all on function bank_mark_paid(text, integer, text) from public, anon, authenticated;
grant execute on function bank_create_order(text) to authenticated;
grant execute on function bank_my_paid() to authenticated;
grant execute on function bank_ack(text[]) to authenticated;
grant execute on function bank_order_status(text) to authenticated;
