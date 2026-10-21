-- Đấu giá cuối tuần: mỗi tuần một món độc quyền (xoay vòng 8 món Thẻ Mùa); đặt giá bằng 💎 từ 00:00 thứ 6
-- đến 00:00 thứ 2 (UTC). Người trả cao nhất khi hết giờ nhận món; người bị vượt được hoàn 💎.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase SQL Editor → Run. Idempotent. Không đụng bảng/hàm cũ.
--
-- 💎 nằm trong save của máy nên server không giữ được; thay vào đó máy TRỪ 💎 trước rồi mới gọi auction_bid
-- (lỗi → máy tự hoàn). Khi bị vượt (hoặc chính mình nâng giá), server ghi một khoản hoàn vào auction_refunds;
-- máy lấy bằng auction_collect() rồi báo auction_ack() (hai pha như swap_collect: tắt app giữa chừng không mất).
-- Mức tin cậy như phần còn lại của game: số 💎 do client tự khai.

create table if not exists auctions (
  week        date primary key,                     -- thứ 2 (UTC) của tuần
  item_id     text not null,
  top_user    uuid references auth.users(id),
  top_bid     integer not null default 0,
  bid_count   integer not null default 0,
  winner_acked boolean not null default false
);
alter table auctions enable row level security;
-- Không policy: chỉ qua RPC.

create table if not exists auction_refunds (
  id       uuid primary key default gen_random_uuid(),
  user_id  uuid not null references auth.users(id),
  week     date not null,
  gems     integer not null check (gems > 0),
  acked    boolean not null default false
);
create index if not exists auction_refunds_user_idx on auction_refunds (user_id, acked);
alter table auction_refunds enable row level security;

-- Đồng hồ của đấu giá (tách ra để kịch bản test giả lập thời gian).
create or replace function auction_now() returns timestamptz language sql stable as $$ select now() $$;

create or replace function auction_week() returns date
language sql stable as $$ select date_trunc('week', auction_now() at time zone 'utc')::date $$;

create or replace function auction_item_for(p_week date) returns text
language sql immutable as $$
  select (array['season_sakura','season_paper_lantern','season_sunflower','season_island',
                'season_autumn_leaf','season_moon_view','season_snowflake','season_mountain'])
         [((p_week - date '2026-01-05') / 7) % 8 + 1]
$$;

create or replace function auction_min_bid() returns integer language sql immutable as $$ select 100 $$;
create or replace function auction_max_bid() returns integer language sql immutable as $$ select 20000 $$;

-- Giá thấp nhất cho lần đặt kế: lần đầu = auction_min_bid(), sau đó cao hơn giá hiện tại ≥10% (tối thiểu +10).
create or replace function auction_next_min(p_top integer) returns integer
language sql immutable as $$
  select case when p_top <= 0 then auction_min_bid() else p_top + greatest(10, (p_top + 9) / 10) end
$$;

create or replace function auction_require_linked() returns uuid
language plpgsql stable security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from auth.users where id = v_uid and is_anonymous) then raise exception 'email link required'; end if;
  return v_uid;
end;
$$;

-- Phiên đấu giá của tuần này (tạo lười). Mở cho mọi người đã liên kết email.
create or replace function auction_current() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auction_require_linked();
  v_week date := auction_week();
  a auctions%rowtype;
  v_start timestamptz := (v_week + 4)::timestamp at time zone 'utc';
  v_end   timestamptz := (v_week + 7)::timestamp at time zone 'utc';
begin
  insert into auctions (week, item_id) values (v_week, auction_item_for(v_week)) on conflict (week) do nothing;
  select * into a from auctions where week = v_week;
  return jsonb_build_object(
    'week', v_week, 'item_id', a.item_id,
    'starts_at', v_start, 'ends_at', v_end,
    'open', auction_now() >= v_start and auction_now() < v_end,
    'top_bid', a.top_bid, 'bid_count', a.bid_count,
    'top_is_me', a.top_user = v_uid,
    'top_nick', (select nickname from leaderboard_entries where user_id = a.top_user),
    'next_min', auction_next_min(a.top_bid),
    'max_bid', auction_max_bid());
end;
$$;

-- Đặt giá [p_gems] 💎 (tổng giá, không phải phần thêm). Máy đã trừ 💎 trước khi gọi.
create or replace function auction_bid(p_gems integer) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auction_require_linked();
  v_week date := auction_week();
  a auctions%rowtype;
begin
  if auction_now() < (v_week + 4)::timestamp at time zone 'utc' then raise exception 'auction_closed'; end if;
  insert into auctions (week, item_id) values (v_week, auction_item_for(v_week)) on conflict (week) do nothing;
  select * into a from auctions where week = v_week for update;
  if p_gems is null or p_gems > auction_max_bid() then raise exception 'invalid_bid'; end if;
  if p_gems < auction_next_min(a.top_bid) then raise exception 'bid_too_low'; end if;
  if a.top_user is not null then
    insert into auction_refunds (user_id, week, gems) values (a.top_user, v_week, a.top_bid);
  end if;
  update auctions set top_user = v_uid, top_bid = p_gems, bid_count = bid_count + 1 where week = v_week;
end;
$$;

-- Máy mở màn Đấu giá: các khoản hoàn chưa nhận + món thắng của tuần đã kết thúc chưa nhận.
create or replace function auction_collect() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auction_require_linked();
  v_refunds jsonb;
  v_won jsonb;
begin
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 'gems', gems) order by id), '[]') into v_refunds
    from auction_refunds where user_id = v_uid and not acked;
  select coalesce(jsonb_agg(jsonb_build_object('week', week, 'item_id', item_id, 'bid', top_bid) order by week), '[]') into v_won
    from auctions
   where top_user = v_uid and not winner_acked and (week + 7)::timestamp at time zone 'utc' <= auction_now();
  return jsonb_build_object('refunds', v_refunds, 'won', v_won);
end;
$$;

create or replace function auction_ack(p_refunds uuid[], p_weeks date[]) returns void
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auction_require_linked();
begin
  update auction_refunds set acked = true where user_id = v_uid and id = any (coalesce(p_refunds, '{}'));
  update auctions set winner_acked = true
   where top_user = v_uid and week = any (coalesce(p_weeks, '{}')) and (week + 7)::timestamp at time zone 'utc' <= auction_now();
end;
$$;

revoke all on function auction_current() from public, anon;
revoke all on function auction_bid(integer) from public, anon;
revoke all on function auction_collect() from public, anon;
revoke all on function auction_ack(uuid[], date[]) from public, anon;
grant execute on function auction_current() to authenticated;
grant execute on function auction_bid(integer) to authenticated;
grant execute on function auction_collect() to authenticated;
grant execute on function auction_ack(uuid[], date[]) to authenticated;
revoke all on function auction_require_linked() from public, anon, authenticated;
revoke all on function auction_now() from public, anon, authenticated;
