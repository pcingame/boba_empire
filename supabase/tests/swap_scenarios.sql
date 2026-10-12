-- Trao đổi vật phẩm: ký quỹ, nhận (hai chiều), huỷ, hết hạn + quét, ack hai pha, giới hạn, quyền.
-- Chạy bằng scripts/test_swap_sql.sh.
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
create function copies_of(u int, a text) returns integer language sql as $$
  select coalesce((select copies from accessory_server_ownership
                    where user_id = ('00000000-0000-0000-0000-00000000000' || u)::uuid and accessory_id = a), 0) $$;

insert into auth.users (id) select ('00000000-0000-0000-0000-00000000000' || i)::uuid from generate_series(1, 4) i;
-- u1 có x2 + z1 (z để thử giới hạn); u2 có y1.
insert into accessory_server_ownership (user_id, accessory_id, copies) values
  ('00000000-0000-0000-0000-000000000001', 'x', 2), ('00000000-0000-0000-0000-000000000001', 'z', 9),
  ('00000000-0000-0000-0000-000000000002', 'y', 1);

-- Supabase cấp sẵn quyền select cho authenticated (RLS mới là hàng rào) — giả lập để thử chính sách đọc.
grant select on accessory_swaps to authenticated;

-- ===== Tạo + ký quỹ
select as_u(1);
select swap_create('x', 'y') as s1 \gset
reset role;
select chk('ký quỹ: x còn 1 bản ở kho server', copies_of(1, 'x') = 1);
select as_u(1);
select chk('không đổi món lấy chính nó', err_of($$select swap_create('x', 'x')$$) like '%invalid_swap%');
select chk('không có món để đổi', err_of($$select swap_create('khong_co', 'y')$$) like '%not_owned%');
select chk('tên rỗng bị từ chối', err_of($$select swap_create('', 'y')$$) like '%invalid_swap%');
select as_u(0);
select chk('khách không gọi được', err_of($$select swap_create('x', 'y')$$) like '%permission denied%');

-- ===== Nhận
select as_u(1);
select chk('không tự nhận đề nghị của mình', err_of(format('select swap_accept(%L::uuid)', :'s1')) like '%cannot_accept_own_swap%');
select as_u(3);
select chk('người không có món y không nhận được', err_of(format('select swap_accept(%L::uuid)', :'s1')) like '%not_owned_want%');
reset role;
select chk('nhận hỏng không đổi gì: x vẫn ký quỹ', copies_of(1, 'x') = 1 and copies_of(3, 'x') = 0);
select as_u(2);
select swap_accept(:'s1'::uuid);
reset role;
select chk('người nhận mất y, được x', copies_of(2, 'y') = 0 and copies_of(2, 'x') = 1);
select chk('người đăng được y (kho server)', copies_of(1, 'y') = 1);
select chk('đề nghị done + taker + chưa ack', (select status = 'done' and taker_id = '00000000-0000-0000-0000-000000000002'
  and not seller_acked from accessory_swaps where id = :'s1'));
select as_u(2);
select chk('nhận lần hai bị chặn (đã xong)', err_of(format('select swap_accept(%L::uuid)', :'s1')) like '%swap_not_open%');

-- ===== Người đăng thu về hai pha
select as_u(1);
select chk('swap_collect trả món cần thêm cục bộ (done → want y)',
  (select count(*) from swap_collect() where status = 'done' and want_id = 'y') = 1);
select chk('gọi lại vẫn trả (chưa ack)', (select count(*) from swap_collect()) = 1);
select swap_ack(array[:'s1'::uuid]);
select chk('ack xong không trả nữa', (select count(*) from swap_collect()) = 0);
reset role;
select chk('collect/ack không đổi kho server', copies_of(1, 'y') = 1);

-- ===== Huỷ: trả món về kho
select as_u(1);
select swap_create('x', 'q') as s2 \gset
reset role;
select chk('ký quỹ lần 2: x = 0', copies_of(1, 'x') = 0);
select as_u(2);
select chk('người khác không huỷ được', err_of(format('select swap_cancel(%L::uuid)', :'s2')) like '%not_your_swap%');
select as_u(1);
select swap_cancel(:'s2'::uuid);
reset role;
select chk('huỷ trả x về kho', copies_of(1, 'x') = 1);
select as_u(1);
select chk('huỷ lần hai bị chặn', err_of(format('select swap_cancel(%L::uuid)', :'s2')) like '%swap_not_open%');

-- ===== Hết hạn: ẩn + quét trả món + collect
select swap_create('x', 'q') as s3 \gset
reset role;
update accessory_swaps set created_at = now() - interval '4 days' where id = :'s3';
select as_u(2);
select chk('đề nghị quá hạn không nhận được', err_of(format('select swap_accept(%L::uuid)', :'s3')) like '%swap_not_open%');
select chk('đề nghị quá hạn bị ẩn khỏi danh sách (chính sách đọc)', (select count(*) from accessory_swaps where id = :'s3') = 0);
select chk('đề nghị còn hạn thì thấy', (select count(*) from accessory_swaps where status = 'done') = 1);
reset role;
select chk('quá hạn chưa quét: x vẫn ký quỹ', copies_of(1, 'x') = 0);
select as_u(1);
select chk('swap_collect: expired → trả lại give x',
  (select count(*) from swap_collect() where status = 'expired' and give_id = 'x') = 1);
reset role;
select chk('quét trả x về kho server', copies_of(1, 'x') = 1);
select as_u(1);
select swap_ack(array[:'s3'::uuid]);
select chk('ack xong sạch', (select count(*) from swap_collect()) = 0);

-- ===== Giới hạn số đề nghị mở
select swap_create('z', 'a1'); select swap_create('z', 'a2'); select swap_create('z', 'a3');
select swap_create('z', 'a4'); select swap_create('z', 'a5');
select chk('quá giới hạn 5 đề nghị mở', err_of($$select swap_create('z', 'a6')$$) like '%too_many_swaps%');

-- ===== Hai đề nghị cùng món hết hạn một lượt (ON CONFLICT không đụng một hàng hai lần)
reset role;
update accessory_swaps set created_at = now() - interval '5 days' where give_id = 'z';
select as_u(1);
select chk('5 đề nghị cùng món hết hạn: collect đủ 5', (select count(*) from swap_collect() where give_id = 'z') = 5);
reset role;
select chk('trả đủ 5 bản z (9 ban đầu)', copies_of(1, 'z') = 9);

-- ===== Bảo mật
select as_u(1);
select chk('client không gọi swap_sweep', err_of('select swap_sweep()') like '%permission denied%');
select as_u(0);
select chk('khách không đọc được', err_of('select * from accessory_swaps') like '%permission denied%');
reset role;
select 'SWAP OK';
