-- Schema cho "Chợ Phụ kiện" — xem PROPOSAL_ACCESSORY_MARKET.md.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor →
-- Run. Idempotent, độc lập với các schema khác (accessory_leaderboard_schema.sql
-- vẫn giữ nguyên, không đụng nhau) — dán trước/sau đều được.
--
-- ⚠️ Khác PROPOSAL §4 (bản phác thảo đầu): đã thêm RPC register_accessory_drop
-- và bỏ bảng accessory_server_ownership khỏi vai trò "nguồn id món được phép
-- đăng bán tự do" — xem lý do ở ngay phía dưới.

-- ─────────────────────────────────────────────────────────────────────────
-- Vì sao cần register_accessory_drop (không có trong phác thảo PROPOSAL ban
-- đầu): list_accessory phải verify người gọi THẬT SỰ sở hữu món trước khi
-- cho đăng bán — nhưng GĐ1 (Kho phụ kiện) chưa từng đồng bộ ownedAccessories
-- lên server, nó chỉ sống trong save JSON local. Không có bước này thì
-- list_accessory phải tin suông lời client "tôi sở hữu món X" — 2 tài khoản
-- thông đồng (A đăng bán id bất kỳ, kể cả chưa từng rớt → B mua) có thể bơm
-- phụ kiện giả cho nhau, phá vỡ ý nghĩa bảng xếp hạng Sưu tập (tính cả món
-- đang đăng bán, xem §9.3).
--
-- Giải pháp: accessory_server_ownership chỉ được ghi qua register_accessory_drop
-- (gọi lúc claimDailyBonus rớt món MỚI, xem accessories_test.dart/game_controller.dart)
-- hoặc lúc buy_listing (người mua). KHÔNG ai được tự ý "tự nhận" sở hữu 1 id
-- tuỳ ý qua list_accessory nữa — list_accessory giờ CHỈ cho đăng bán món đã
-- có mặt trong accessory_server_ownership từ trước.
--
-- Rủi ro còn sót: người chơi có thể sửa tay save local để THÊM id giả vào
-- ownedAccessories rồi gọi register_accessory_drop cho id đó — nhưng đây
-- không phải lỗ hổng MỚI, nó là mức tin cậy game đã chấp nhận sẵn cho TOÀN
-- BỘ kinh tế (Xu/💎/stage cũng sửa tay được, không có lớp nào chặn) — khác
-- hẳn lỗ hổng "2 tài khoản thông đồng, không cần sửa save" mà thiếu RPC này
-- sẽ mở ra. Chấp nhận được, nhất quán với mức rủi ro hiện tại của toàn game.
-- ─────────────────────────────────────────────────────────────────────────

-- Số dư Xu Chợ, KHÔNG liên thông Xu/💎 thật (xem PROPOSAL §0). Không có
-- policy insert/update cho client — tạo lười (upsert) ngay trong RPC lúc
-- cần, không cần bước "mở ví" riêng.
create table if not exists accessory_wallets (
  user_id  uuid primary key references auth.users(id) on delete cascade,
  balance  bigint not null default 0 check (balance >= 0)
);

alter table accessory_wallets enable row level security;

drop policy if exists accessory_wallets_select_own on accessory_wallets;
create policy accessory_wallets_select_own on accessory_wallets
  for select to authenticated using (auth.uid() = user_id);

-- Ai đang sở hữu món nào, theo xác nhận của SERVER (không phải client tự
-- khai) — chỉ ghi qua register_accessory_drop/buy_listing/list_accessory/
-- cancel_listing bên dưới, không có policy insert/update trực tiếp.
create table if not exists accessory_server_ownership (
  user_id       uuid not null references auth.users(id) on delete cascade,
  accessory_id  text not null,
  granted_at    timestamptz not null default now(),
  primary key (user_id, accessory_id)
);

alter table accessory_server_ownership enable row level security;

drop policy if exists accessory_server_ownership_select_own on accessory_server_ownership;
create policy accessory_server_ownership_select_own on accessory_server_ownership
  for select to authenticated using (auth.uid() = user_id);

create table if not exists accessory_listings (
  id            uuid primary key default gen_random_uuid(),
  seller_id     uuid not null references auth.users(id),
  accessory_id  text not null,
  -- Giá tự do, chỉ chặn biên rộng (xem PROPOSAL §9.1) — không khung theo độ hiếm.
  price         bigint not null check (price between 1 and 100000),
  status        text not null default 'active', -- active|sold|cancelled
  created_at    timestamptz not null default now(),
  resolved_at   timestamptz
);

create index if not exists accessory_listings_active_idx
  on accessory_listings (status, created_at desc);
create index if not exists accessory_listings_seller_idx
  on accessory_listings (seller_id, status);

alter table accessory_listings enable row level security;

-- Đọc: AI CŨNG được, kể cả chưa đăng nhập — chợ công khai (xem đang bán gì).
drop policy if exists accessory_listings_select_all on accessory_listings;
create policy accessory_listings_select_all on accessory_listings
  for select to anon, authenticated using (true);
-- Không có policy insert/update cho client — chỉ qua RPC bên dưới.

create table if not exists accessory_market_trades (
  id            bigint generated always as identity primary key,
  listing_id    uuid not null references accessory_listings(id),
  buyer_id      uuid not null references auth.users(id),
  seller_id     uuid not null references auth.users(id),
  accessory_id  text not null,
  price         bigint not null,
  traded_at     timestamptz not null default now()
);

create index if not exists accessory_market_trades_buyer_idx
  on accessory_market_trades (buyer_id, traded_at desc);
create index if not exists accessory_market_trades_seller_idx
  on accessory_market_trades (seller_id, traded_at desc);

alter table accessory_market_trades enable row level security;

-- Đọc: chỉ giao dịch của chính mình (mua HOẶC bán).
drop policy if exists accessory_market_trades_select_own on accessory_market_trades;
create policy accessory_market_trades_select_own on accessory_market_trades
  for select to authenticated
  using (auth.uid() = buyer_id or auth.uid() = seller_id);

-- ─────────────────────────────────────────────────────────────────────────
-- RPC (security definer — đường ghi DUY NHẤT, RLS chặn hết insert/update
-- thẳng từ client ở các bảng trên).
-- ─────────────────────────────────────────────────────────────────────────

-- Ghi nhận 1 món vừa rớt hợp lệ (gọi lúc claimDailyBonus rớt món MỚI) HOẶC
-- dùng để "đối chiếu lần đầu" khi người chơi mở Chợ lần đầu, bù đăng ký cho
-- những món họ đã có từ trước khi Chợ ra đời (xem ghi chú đầu file). An
-- toàn gọi lại nhiều lần (idempotent).
create or replace function register_accessory_drop(p_accessory_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into accessory_server_ownership (user_id, accessory_id)
  values (auth.uid(), p_accessory_id)
  on conflict (user_id, accessory_id) do nothing;
end;
$$;

grant execute on function register_accessory_drop(text) to authenticated;

-- Đăng bán — CHỈ cho đăng món đã có trong accessory_server_ownership của
-- chính mình (xem lý do ở đầu file). Xoá khỏi bảng sở hữu ngay (món "rời
-- khỏi tay" người bán trong lúc đang rao) để không đăng được 2 lần.
create or replace function list_accessory(p_accessory_id text, p_price bigint)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_listing_id uuid;
begin
  if p_price < 1 or p_price > 100000 then
    raise exception 'invalid_price';
  end if;

  delete from accessory_server_ownership
  where user_id = auth.uid() and accessory_id = p_accessory_id;

  if not found then
    raise exception 'not_owned';
  end if;

  insert into accessory_listings (seller_id, accessory_id, price)
  values (auth.uid(), p_accessory_id, p_price)
  returning id into v_listing_id;

  return v_listing_id;
end;
$$;

grant execute on function list_accessory(text, bigint) to authenticated;

-- Huỷ đăng — trả món lại accessory_server_ownership cho người bán.
create or replace function cancel_listing(p_listing_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seller uuid;
  v_accessory text;
begin
  select seller_id, accessory_id into v_seller, v_accessory
  from accessory_listings
  where id = p_listing_id and status = 'active'
  for update;

  if not found then
    raise exception 'listing_not_active';
  end if;
  if v_seller <> auth.uid() then
    raise exception 'not_your_listing';
  end if;

  update accessory_listings
  set status = 'cancelled', resolved_at = now()
  where id = p_listing_id;

  insert into accessory_server_ownership (user_id, accessory_id)
  values (v_seller, v_accessory)
  on conflict (user_id, accessory_id) do nothing;
end;
$$;

grant execute on function cancel_listing(uuid) to authenticated;

-- Mua — 1 transaction, khoá hàng listing trước khi đổi gì (chặn 2 người
-- mua cùng lúc 1 listing — bài học từ pushIfCurrent/optimistic concurrency
-- ở Cloud Save). Chặn tự mua chính mình dù không có lợi kinh tế thật (Xu
-- Chợ không đổi ra giá trị thật — xem PROPOSAL §0) vì vẫn làm nhiễu
-- accessory_market_trades (vd thao túng cảm giác "món hot").
create or replace function buy_listing(p_listing_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seller uuid;
  v_accessory text;
  v_price bigint;
  v_buyer uuid := auth.uid();
  v_balance bigint;
begin
  select seller_id, accessory_id, price into v_seller, v_accessory, v_price
  from accessory_listings
  where id = p_listing_id and status = 'active'
  for update;

  if not found then
    raise exception 'listing_not_active';
  end if;
  if v_seller = v_buyer then
    raise exception 'cannot_buy_own_listing';
  end if;

  -- Ví có thể chưa tồn tại (chưa từng bán/mua gì) — tạo lười với 0.
  insert into accessory_wallets (user_id, balance) values (v_buyer, 0)
  on conflict (user_id) do nothing;
  insert into accessory_wallets (user_id, balance) values (v_seller, 0)
  on conflict (user_id) do nothing;

  select balance into v_balance from accessory_wallets
  where user_id = v_buyer for update;
  if v_balance < v_price then
    raise exception 'insufficient_balance';
  end if;

  update accessory_wallets set balance = balance - v_price where user_id = v_buyer;
  update accessory_wallets set balance = balance + v_price where user_id = v_seller;

  update accessory_listings
  set status = 'sold', resolved_at = now()
  where id = p_listing_id;

  insert into accessory_server_ownership (user_id, accessory_id)
  values (v_buyer, v_accessory)
  on conflict (user_id, accessory_id) do nothing;

  insert into accessory_market_trades (listing_id, buyer_id, seller_id, accessory_id, price)
  values (p_listing_id, v_buyer, v_seller, v_accessory, v_price);
end;
$$;

grant execute on function buy_listing(uuid) to authenticated;
