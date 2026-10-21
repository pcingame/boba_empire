-- Đấu giá cuối tuần: cửa sổ đặt giá, giá tối thiểu/bước giá, hoàn 💎 khi bị vượt, nhận món sau khi kết thúc, quyền.
-- Chạy bằng scripts/test_auction_sql.sh.
\set ON_ERROR_STOP on
create function as_u(n int) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', case when n = 0 then '' else '00000000-0000-0000-0000-00000000000' || n end, false);
  execute case when n = 0 then 'set role anon' else 'set role authenticated' end;
end $$;
grant execute on function as_u(int) to anon, authenticated;
create function err_of(q text) returns text language plpgsql as $$
begin execute q; return 'NO ERROR'; exception when others then return sqlerrm; end $$;
grant execute on function err_of(text) to anon, authenticated;
create function chk(name text, ok boolean) returns void language plpgsql as $$
begin if not ok then raise exception 'FAIL: %', name; end if; raise notice 'ok: %', name; end $$;
grant execute on function chk(text, boolean) to anon, authenticated;

create table leaderboard_entries (user_id uuid primary key, nickname text);
insert into auth.users (id, is_anonymous) select ('00000000-0000-0000-0000-00000000000' || i)::uuid, i = 4 from generate_series(1, 4) i;
insert into leaderboard_entries values ('00000000-0000-0000-0000-000000000001', 'An'), ('00000000-0000-0000-0000-000000000002', 'Binh');

-- Giả lập đồng hồ: thứ 4 2026-10-21 (ngoài cửa sổ) → thứ 7 2026-10-24 (trong) → thứ 3 2026-10-27 (đã kết thúc).
create table clock (t timestamptz);
insert into clock values ('2026-10-21 12:00+00');
create or replace function auction_now() returns timestamptz language sql stable as $$ select t from clock $$;

select as_u(1);
select chk('thứ 4: chưa mở', (auction_current()->>'open')::boolean = false);
select chk('món xoay vòng có giá trị', auction_current()->>'item_id' like 'season_%');
select chk('thứ 4: đặt giá bị từ chối', err_of($$select auction_bid(100)$$) like '%auction_closed%');
select as_u(4);
select chk('ẩn danh không vào được', err_of($$select auction_current()$$) like '%email link required%');
select as_u(0);
select chk('khách không gọi được', err_of($$select auction_bid(100)$$) like '%permission denied%');
reset role;
update clock set t = '2026-10-24 10:00+00';

select as_u(1);
select chk('thứ 7: mở', (auction_current()->>'open')::boolean);
select chk('giá đầu tối thiểu 100', err_of($$select auction_bid(99)$$) like '%bid_too_low%');
select chk('vượt trần', err_of($$select auction_bid(20001)$$) like '%invalid_bid%');
select auction_bid(100);
select chk('u1 dẫn đầu', (auction_current()->>'top_is_me')::boolean and (auction_current()->>'top_bid')::int = 100
  and auction_current()->>'top_nick' = 'An');
select chk('bước giá +10', (auction_current()->>'next_min')::int = 110);
select as_u(2);
select chk('không vượt đủ bước', err_of($$select auction_bid(109)$$) like '%bid_too_low%');
select auction_bid(200);
select as_u(1);
select chk('u1 được hoàn 100', (auction_collect()->'refunds'->0->>'gems')::int = 100 and jsonb_array_length(auction_collect()->'refunds') = 1);
select chk('u1 chưa có món', jsonb_array_length(auction_collect()->'won') = 0);
select auction_bid(300); -- u1 giành lại, u2 được hoàn 200
select as_u(2);
select chk('u2 được hoàn 200', (auction_collect()->'refunds'->0->>'gems')::int = 200);
select as_u(1);
select auction_bid(400); -- tự nâng giá: khoản 300 của chính mình hoàn lại
select chk('tự nâng giá được hoàn khoản cũ', (select sum((e->>'gems')::int) from jsonb_array_elements(auction_collect()->'refunds') e) = 400);
select auction_ack(array(select (e->>'id')::uuid from jsonb_array_elements(auction_collect()->'refunds') e), array[]::date[]);
select chk('ack hoàn xong còn trống', jsonb_array_length(auction_collect()->'refunds') = 0);
select chk('chưa kết thúc: chưa nhận món', jsonb_array_length(auction_collect()->'won') = 0);

reset role;
update clock set t = '2026-10-27 01:00+00';
select as_u(2);
select chk('hết giờ: không đặt giá', err_of($$select auction_bid(500)$$) like '%auction_closed%');
select as_u(1);
select chk('u1 thắng: nhận 1 món', jsonb_array_length(auction_collect()->'won') = 1
  and auction_collect()->'won'->0->>'item_id' like 'season_%');
select auction_ack(array[]::uuid[], array[(auction_collect()->'won'->0->>'week')::date]);
select chk('đã ack món', jsonb_array_length(auction_collect()->'won') = 0);
select as_u(2);
select chk('người thua không có món', jsonb_array_length(auction_collect()->'won') = 0);
do $$ begin raise notice 'AUCTION OK'; end $$;
