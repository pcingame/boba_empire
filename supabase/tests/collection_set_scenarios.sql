-- Mốc sưu tập theo bộ: nhận đúng khi đủ bộ, chặn thiếu món / nhận lặp / bộ lạ, tính cả món đang rao.
-- Chạy bằng scripts/test_market_sql.sh.
\set ON_ERROR_STOP on
insert into auth.users values ('00000000-0000-0000-0000-000000000001'), ('00000000-0000-0000-0000-000000000002') on conflict do nothing;
grant select on accessory_listings to anon, authenticated;
create or replace function as_u(n int) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', case when n = 0 then '' else '00000000-0000-0000-0000-00000000000' || n end, false);
  execute case when n = 0 then 'set role anon' else 'set role authenticated' end;
end $$;
grant execute on function as_u(int) to anon, authenticated;
create or replace function err_of(q text) returns text language plpgsql as $$
begin execute q; return 'NO ERROR'; exception when others then return sqlerrm; end $$;
grant execute on function err_of(text) to anon, authenticated;
create or replace function chk(name text, ok boolean) returns void language plpgsql as $$
begin if not ok then raise exception 'FAIL: %', name; end if; raise notice 'ok: %', name; end $$;
grant execute on function chk(text, boolean) to anon, authenticated;


reset role;
insert into accessory_wallets (user_id, balance) values ('00000000-0000-0000-0000-000000000002', 0) on conflict (user_id) do update set balance = 0;
-- User 1 có đủ huyền thoại trừ 1 món; user 2 có đủ huyền thoại.
insert into accessory_server_ownership (user_id, accessory_id, copies)
select '00000000-0000-0000-0000-000000000001', accessory_id, 1 from accessory_set_members
where set_id = 'rarity_legendary' and accessory_id <> (select min(accessory_id) from accessory_set_members where set_id = 'rarity_legendary');
insert into accessory_server_ownership (user_id, accessory_id, copies)
select '00000000-0000-0000-0000-000000000002', accessory_id, 1 from accessory_set_members where set_id = 'rarity_legendary';
select chk('bộ huyền thoại 9 món, 8 bộ x 160 hàng', (select count(*) from accessory_set_members where set_id='rarity_legendary') = 9
  and (select count(*) from accessory_set_members) = 320);
select as_u(1);
select chk('thiếu 1 món → not_reached', err_of($$select claim_collection_set('rarity_legendary')$$) like '%not_reached%');
select chk('bộ lạ → invalid_set', err_of($$select claim_collection_set('nope')$$) like '%invalid_set%');
select as_u(2);
select chk('đủ bộ → 150 Xu Chợ', claim_collection_set('rarity_legendary') = 150);
select chk('nhận lặp bị chặn', err_of($$select claim_collection_set('rarity_legendary')$$) like '%already_claimed%');
reset role;
select chk('ví cộng đúng 150', (select balance from accessory_wallets where user_id='00000000-0000-0000-0000-000000000002') = 150);
-- Món cuối đang rao bán vẫn tính.
reset role;
select min(accessory_id) as lid from accessory_set_members where set_id='rarity_legendary' \gset
insert into accessory_server_ownership (user_id, accessory_id, copies)
select '00000000-0000-0000-0000-000000000001', min(accessory_id), 1 from accessory_set_members where set_id='rarity_legendary';
select as_u(1);
select list_accessory(:'lid', 100) as lx \gset
select chk('món đang rao vẫn tính vào bộ → 150', claim_collection_set('rarity_legendary') = 150);
select as_u(0);
select chk('khách chưa đăng nhập bị chặn', err_of($$select claim_collection_set('rarity_legendary')$$) like '%authenticated%' or err_of($$select claim_collection_set('rarity_legendary')$$) like '%permission%');
-- Chạy lại schema (idempotent): không nhân đôi hàng bộ, không mất lượt đã nhận.
reset role;
select chk('mỗi bộ đúng kích thước (9/30/46/75 + 4 họ cộng 160)',
  (select count(*) from accessory_set_members where set_id like 'rarity_%') = 160
  and (select count(*) from accessory_set_members where set_id like 'family_%') = 160
  and (select count(distinct accessory_id) from accessory_set_members where set_id like 'family_%') = 160);
-- Cả 8 bộ nhận được một lần, tổng đúng 2850; client không gọi được bảng trực tiếp.
insert into accessory_server_ownership (user_id, accessory_id, copies)
select '00000000-0000-0000-0000-000000000002', accessory_id, 1 from accessory_set_members
on conflict (user_id, accessory_id) do nothing;
select as_u(2);
select chk('đọc thẳng bảng bộ bị chặn', err_of($$select * from accessory_set_members$$) like '%permission denied%');
select chk('đọc thẳng bảng đã nhận bị chặn', err_of($$select * from accessory_set_claims$$) like '%permission denied%');
select chk('7 bộ còn lại nhận đúng tổng 2700',
  (select sum(claim_collection_set(x)) from unnest(array['rarity_epic','rarity_rare','rarity_common','family_tap','family_income','family_offline','family_discount']) x) = 2700);
select chk('nhận lại bộ bất kỳ đều bị chặn', err_of($$select claim_collection_set('family_tap')$$) like '%already_claimed%');
reset role;
select chk('ví user 2 = 150 + 2700', (select balance from accessory_wallets where user_id='00000000-0000-0000-0000-000000000002') = 2850);
select chk('8 dòng đã nhận của user 2', (select count(*) from accessory_set_claims where user_id='00000000-0000-0000-0000-000000000002') = 8);
\echo COLLECTION SET OK
