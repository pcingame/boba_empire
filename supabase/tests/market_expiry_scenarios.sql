-- Hết hạn tin đăng Chợ (3 ngày): ẩn tin quá hạn, quét trả món về kho server, ack hai pha.
-- Chạy bằng scripts/test_market_sql.sh (Postgres tạm, giả lập auth/anon/authenticated).
\set ON_ERROR_STOP on
insert into auth.users values ('00000000-0000-0000-0000-000000000001'), ('00000000-0000-0000-0000-000000000002');
grant select on accessory_listings to anon, authenticated;
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

insert into accessory_server_ownership (user_id, accessory_id, copies) values ('00000000-0000-0000-0000-000000000001', 'x', 2);
insert into accessory_wallets (user_id, balance) values ('00000000-0000-0000-0000-000000000002', 100000);

select as_u(1);
select list_accessory('x', 100) as la \gset
select list_accessory('x', 200) as lb \gset
reset role;
select chk('hai tin đang bán, kho server hết món x', (select count(*) from accessory_server_ownership where accessory_id='x') = 0);
select as_u(0);
select chk('khách thấy 2 tin', (select count(*) from accessory_listings where status='active') = 2);
reset role;
update accessory_listings set created_at = now() - interval '4 days' where id = :'la';
select as_u(0);
select chk('tin quá hạn bị ẩn khỏi khách', (select count(*) from accessory_listings where status='active') = 1);
select as_u(2);
select chk('mua tin quá hạn bị từ chối', err_of(format('select buy_listing(%L::uuid)', :'la')) like '%listing_not_active%');
select as_u(1);
select chk('huỷ tin quá hạn bị từ chối (phải qua quét)', err_of(format('select cancel_listing(%L::uuid)', :'la')) like '%listing_not_active%');
select chk('expire_my_listings trả đúng tin đã hết hạn', (select count(*) from expire_my_listings()) = 1);
reset role;
select chk('món về kho server đúng 1 bản', (select copies from accessory_server_ownership where accessory_id='x') = 1);
select chk('tin đánh dấu expired, chưa ack', (select status = 'expired' and not seller_acked from accessory_listings where id = :'la'));
select as_u(1);
select chk('gọi lại vẫn trả (chưa ack)', (select count(*) from expire_my_listings()) = 1);
reset role;
select chk('kho server vẫn 1 bản (không trả thêm lần nữa)', (select copies from accessory_server_ownership where accessory_id='x') = 1);
select as_u(1);
select ack_expired_listings(array[:'la'::uuid]);
select chk('sau ack không còn trả', (select count(*) from expire_my_listings()) = 0);
select as_u(2);
select buy_listing(:'lb'::uuid);
select chk('mua tin còn hạn vẫn được', true);

reset role;
insert into accessory_server_ownership (user_id, accessory_id, copies) values ('00000000-0000-0000-0000-000000000001', 'y', 2);
select as_u(1);
select list_accessory('y', 10); select list_accessory('y', 20);
reset role;
update accessory_listings set created_at = now() - interval '5 days' where accessory_id = 'y';
select as_u(1);
select chk('hai tin cùng món hết hạn', (select count(*) from expire_my_listings() where accessory_id = 'y') = 2);
reset role;
select chk('trả đủ 2 bản', (select copies from accessory_server_ownership where accessory_id='y' and user_id='00000000-0000-0000-0000-000000000001') = 2);

select as_u(1);
select ack_expired_listings(array(select id from accessory_listings where accessory_id = 'y'));
select list_accessory('y', 30);
select chk('đăng lại món vừa hết hạn được', true);
select chk('client không gọi market_sweep trực tiếp', err_of('select market_sweep()') like '%permission denied%');
select as_u(0);
select chk('khách không gọi expire_my_listings', err_of('select * from expire_my_listings()') like '%permission denied%');
reset role;
-- Gia hạn tin đăng
select as_u(1);
select list_accessory('x', 300) as lx \gset
reset role;
update accessory_listings set created_at = now() - interval '2 days' where id = :'lx';
select as_u(2);
select chk('người khác không gia hạn được tin của mình', err_of(format('select extend_listing(%L::uuid)', :'lx')) like '%listing_not_extendable%');
select as_u(1);
select extend_listing(:'lx'::uuid);
reset role;
select chk('gia hạn đặt lại hạn về đủ 3 ngày', (select extended and created_at > now() - interval '1 minute' from accessory_listings where id = :'lx'));
select as_u(1);
select chk('gia hạn lần hai bị từ chối', err_of(format('select extend_listing(%L::uuid)', :'lx')) like '%listing_not_extendable%');
select as_u(0);
select chk('khách không gọi extend_listing', err_of(format('select extend_listing(%L::uuid)', :'lx')) like '%permission denied%');
reset role;
insert into accessory_server_ownership (user_id, accessory_id, copies) values ('00000000-0000-0000-0000-000000000001', 'x', 1)
  on conflict (user_id, accessory_id) do update set copies = accessory_server_ownership.copies + 1;
select as_u(1);
select list_accessory('x', 400) as ly \gset
reset role;
update accessory_listings set created_at = now() - interval '4 days' where id = :'ly';
select as_u(1);
select chk('tin đã quá hạn không gia hạn được', err_of(format('select extend_listing(%L::uuid)', :'ly')) like '%listing_not_extendable%');
reset role;
-- Vòng đời sau gia hạn: sống đủ hạn mới, rồi hết hạn bình thường và món về kho
reset role;
insert into accessory_server_ownership (user_id, accessory_id, copies) values ('00000000-0000-0000-0000-000000000001', 'x', 2)
  on conflict (user_id, accessory_id) do update set copies = accessory_server_ownership.copies + 2;
select as_u(1);
select list_accessory('x', 500) as lz \gset
reset role;
update accessory_listings set created_at = now() - interval '2 days 23 hours' where id = :'lz';
select as_u(1);
select extend_listing(:'lz'::uuid);
reset role;
update accessory_listings set created_at = now() - interval '2 days' where id = :'lz';
select as_u(0);
select chk('sau gia hạn + 2 ngày tin vẫn hiện', (select count(*) from accessory_listings where id = :'lz' and status = 'active') = 1);
select as_u(2);
select chk('tin đã gia hạn vẫn mua được', err_of(format('select buy_listing(%L::uuid)', :'lz')) = 'NO ERROR');
reset role;
select chk('mua xong tin đã bán', (select status = 'sold' from accessory_listings where id = :'lz'));
select as_u(1);
select list_accessory('x', 600) as lw \gset
select extend_listing(:'lw'::uuid);
reset role;
update accessory_listings set created_at = now() - interval '3 days 1 hour' where id = :'lw';
select as_u(1);
select chk('tin đã gia hạn rồi cũng hết hạn sau 3 ngày mới', (select count(*) from expire_my_listings() where id = :'lw') = 1);
select chk('hết hạn xong không gia hạn lại được', err_of(format('select extend_listing(%L::uuid)', :'lw')) like '%listing_not_extendable%');
select ack_expired_listings(array[:'lw'::uuid]);
reset role;
select chk('món về lại kho server sau hết hạn', (select copies >= 1 from accessory_server_ownership where user_id = '00000000-0000-0000-0000-000000000001' and accessory_id = 'x'));
select 'MARKET EXPIRY OK';
