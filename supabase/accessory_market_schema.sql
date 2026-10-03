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

-- Số bản sao sở hữu (≥ 1 khi còn hàng; hàng bị xoá khi về 0). Rớt trùng cho
-- bản dư bán được ở Chợ mà vẫn giữ món sưu tập.
alter table accessory_server_ownership
  add column if not exists copies integer not null default 1;

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

-- Ghi nhận số bản sao người chơi đang có: idempotent (chỉ NÂNG, không hạ —
-- hạ chỉ qua list_accessory), nên vừa dùng được lúc rớt vừa dùng để đối chiếu
-- khi mở Chợ. Client tự khai số bản — cùng mức tin cậy với register_accessory_drop.
create or replace function register_accessory_copies(p_accessory_id text, p_copies integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_copies < 1 or p_copies > 999 then
    raise exception 'invalid_copies';
  end if;
  insert into accessory_server_ownership (user_id, accessory_id, copies)
  values (auth.uid(), p_accessory_id, p_copies)
  on conflict (user_id, accessory_id) do update
    set copies = greatest(accessory_server_ownership.copies, excluded.copies);
end;
$$;

grant execute on function register_accessory_copies(text, integer) to authenticated;

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
  v_left integer;
begin
  if p_price < 1 or p_price > 100000 then
    raise exception 'invalid_price';
  end if;

  update accessory_server_ownership set copies = copies - 1
  where user_id = auth.uid() and accessory_id = p_accessory_id
  returning copies into v_left;

  if not found then
    raise exception 'not_owned';
  end if;
  if v_left <= 0 then
    delete from accessory_server_ownership
    where user_id = auth.uid() and accessory_id = p_accessory_id;
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
  on conflict (user_id, accessory_id) do update
    set copies = accessory_server_ownership.copies + 1;
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
  v_fee bigint;
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

  -- Phí sàn 1%, làm tròn lên, tối thiểu 1 Xu Chợ (số nguyên, không qua float).
  -- Người mua trả đúng giá niêm yết; người bán nhận giá - phí.
  v_fee := greatest(1, (v_price + 99) / 100);

  update accessory_wallets set balance = balance - v_price where user_id = v_buyer;
  update accessory_wallets set balance = balance + (v_price - v_fee) where user_id = v_seller;

  update accessory_listings
  set status = 'sold', resolved_at = now()
  where id = p_listing_id;

  insert into accessory_server_ownership (user_id, accessory_id)
  values (v_buyer, v_accessory)
  on conflict (user_id, accessory_id) do update
    set copies = accessory_server_ownership.copies + 1;

  insert into accessory_market_trades (listing_id, buyer_id, seller_id, accessory_id, price)
  values (p_listing_id, v_buyer, v_seller, v_accessory, v_price);
end;
$$;

grant execute on function buy_listing(uuid) to authenticated;

-- Nạp Xu Chợ bằng Xu/💎 — MỘT CHIỀU: chỉ cộng ví người gọi, không có RPC ngược
-- và không đụng Xu/💎 cục bộ (client tự trừ SAU khi RPC này thành công).
create or replace function credit_market_coins(p_amount bigint)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  if p_amount is null or p_amount < 1 or p_amount > 100000 then
    raise exception 'invalid_amount';
  end if;

  insert into accessory_wallets (user_id, balance) values (auth.uid(), p_amount)
  on conflict (user_id) do update set balance = accessory_wallets.balance + p_amount;
end;
$$;

revoke execute on function credit_market_coins(bigint) from public, anon;
grant execute on function credit_market_coins(bigint) to authenticated;

-- Giao dịch gần nhất, ẩn danh (không lộ id người mua/bán) — cho dải "Vừa bán".
-- RLS của accessory_market_trades chỉ cho đọc giao dịch của chính mình nên
-- phải qua security definer; chỉ trả 3 cột an toàn.
create or replace function recent_market_trades(p_limit integer default 10)
returns table (accessory_id text, price bigint, traded_at timestamptz)
language sql
stable
security definer
set search_path = public
as $$
  select accessory_id, price, traded_at
  from accessory_market_trades
  order by traded_at desc
  limit least(greatest(p_limit, 1), 20);
$$;

grant execute on function recent_market_trades(integer) to anon, authenticated;

-- "Thương gia tuần": người bán được nhiều giao dịch nhất 7 ngày qua (hoà →
-- tổng giá cao hơn → ai bán sớm hơn). Chỉ trả user_id — bảng xếp hạng Sưu tập
-- vốn đã công khai user_id. Phí sàn 1% khiến 2 tài khoản bán qua lại để
-- cày danh hiệu này mất Xu Chợ mỗi vòng; đây chỉ là danh hiệu, không thưởng.
create or replace function market_weekly_top_seller()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select seller_id
  from accessory_market_trades
  where traded_at > now() - interval '7 days'
  group by seller_id
  order by count(*) desc, sum(price) desc, min(traded_at) asc
  limit 1;
$$;

grant execute on function market_weekly_top_seller() to anon, authenticated;

-- Token FCM để đẩy "món của bạn đã bán được" (xem
-- supabase/functions/notify-market-sale). Không có policy nào cho client —
-- chỉ ghi qua RPC dưới, chỉ đọc bằng service role trong Edge Function.
create table if not exists push_tokens (
  token       text primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  platform    text not null,
  locale      text not null default 'en',
  updated_at  timestamptz not null default now()
);

create index if not exists push_tokens_user_idx on push_tokens (user_id);

alter table push_tokens enable row level security;

-- Token thuộc về máy: cài lại app (user ẩn danh mới) thì token chuyển chủ.
create or replace function register_push_token(p_token text, p_platform text, p_locale text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  if char_length(p_token) not between 20 and 4096 then
    raise exception 'invalid_token';
  end if;

  insert into push_tokens (token, user_id, platform, locale)
  values (p_token, auth.uid(), p_platform, left(p_locale, 8))
  on conflict (token) do update
    set user_id = auth.uid(), platform = excluded.platform,
        locale = excluded.locale, updated_at = now();
end;
$$;

grant execute on function register_push_token(text, text, text) to authenticated;

-- Realtime: trang Chợ lắng nghe thay đổi của accessory_listings (đăng/bán/huỷ)
-- để tự làm mới, khỏi phải thoát ra vào lại. Cần bảng nằm trong publication
-- `supabase_realtime` (idempotent, bỏ qua nếu đã bật). RLS vẫn áp dụng cho
-- sự kiện: policy select_all ở trên cho mọi người đọc nên ai cũng nhận được.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'accessory_listings'
  ) then
    alter publication supabase_realtime add table accessory_listings;
  end if;
end $$;

-- ─────────────────────────────────────────────────────────────────────────
-- Huy hiệu bảng xếp hạng ("flair"): 1 phụ kiện hiển thị cạnh tên người chơi.
-- Một bảng riêng thay vì thêm cột vào 6 bảng xếp hạng. Ghi CHỈ qua
-- set_accessory_flair (kiểm tra sở hữu thật trong accessory_server_ownership).
-- Đọc qua accessory_flairs: chỉ trả huy hiệu mà chủ nhân VẪN còn sở hữu (bán
-- hết bản cuối thì tự biến mất, khỏi phải dọn trong list_accessory).
-- ─────────────────────────────────────────────────────────────────────────
create table if not exists accessory_flair (
  user_id       uuid primary key references auth.users(id) on delete cascade,
  accessory_id  text not null,
  updated_at    timestamptz not null default now()
);

alter table accessory_flair enable row level security;
-- Không policy nào: client chỉ đi qua 2 RPC bên dưới.

-- p_accessory_id null = gỡ huy hiệu.
create or replace function set_accessory_flair(p_accessory_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if p_accessory_id is null then
    delete from accessory_flair where user_id = auth.uid();
    return;
  end if;
  if not exists (
    select 1 from accessory_server_ownership
    where user_id = auth.uid() and accessory_id = p_accessory_id
  ) then
    raise exception 'not owned';
  end if;
  insert into accessory_flair (user_id, accessory_id)
  values (auth.uid(), p_accessory_id)
  on conflict (user_id) do update
    set accessory_id = excluded.accessory_id, updated_at = now();
end;
$$;

grant execute on function set_accessory_flair(text) to authenticated;

create or replace function accessory_flairs(p_user_ids uuid[])
returns table (user_id uuid, accessory_id text)
language sql
stable
security definer
set search_path = public
as $$
  select f.user_id, f.accessory_id
  from accessory_flair f
  where f.user_id = any (p_user_ids[1:100])
    and exists (
      select 1 from accessory_server_ownership o
      where o.user_id = f.user_id and o.accessory_id = f.accessory_id
    );
$$;

grant execute on function accessory_flairs(uuid[]) to anon, authenticated;
