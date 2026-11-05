-- Kịch bản nạp chuyển khoản. Chạy bởi scripts/test_bank_sql.sh.
insert into auth.users (id) values ('00000000-0000-0000-0000-00000000000a'), ('00000000-0000-0000-0000-00000000000b');

do $$
declare
  a uuid := '00000000-0000-0000-0000-00000000000a';
  b uuid := '00000000-0000-0000-0000-00000000000b';
  o1 json; o2 json; code text; n int;
begin
  perform set_config('request.jwt.claim.sub', a::text, false);
  o1 := bank_create_order('boba_gems_small');
  assert (o1->>'amount')::int = 20000, 'giá lấy từ server';
  o2 := bank_create_order('boba_gems_small');
  assert o1->>'code' = o2->>'code', 'cùng sản phẩm trong 30 phút dùng lại đơn';
  begin perform bank_create_order('khong_co'); assert false, 'sản phẩm lạ phải lỗi';
  exception when others then assert sqlerrm = 'unknown_product', sqlerrm; end;
  code := o1->>'code';
  assert code ~ '^BE[0-9A-F]{8}$', 'định dạng mã ' || code;

  -- webhook (service role)
  assert bank_mark_paid(code, 10000, 'tx1') = 'short', 'thiếu tiền không trao';
  assert bank_mark_paid('BEZZZZZZZZ', 20000, 'tx0') = 'unknown';
  assert (select count(*) from bank_my_paid()) = 0, 'chưa paid';
  assert bank_mark_paid(lower(code), 25000, 'tx2') = 'paid', 'dư tiền vẫn nhận, mã không phân biệt hoa thường';
  assert bank_mark_paid(code, 20000, 'tx3') = 'already', 'webhook lặp không trả hai lần';

  -- người khác không thấy / không ack được đơn của a
  perform set_config('request.jwt.claim.sub', b::text, false);
  assert (select count(*) from bank_my_paid()) = 0, 'b không thấy đơn của a';
  perform bank_ack(array[code]);
  assert bank_order_status(code) is null, 'b không đọc được trạng thái đơn của a';

  perform set_config('request.jwt.claim.sub', a::text, false);
  assert (select count(*) from bank_my_paid()) = 1, 'a thấy 1 đơn paid';
  assert bank_order_status(code) = 'paid';
  perform bank_ack(array[code]);
  perform bank_ack(array[code]);
  assert (select count(*) from bank_my_paid()) = 0, 'ack xong hết';
  assert bank_order_status(code) = 'delivered';

  -- chống spam đơn pending
  for n in 1..10 loop
    insert into bank_orders (code, user_id, product_id, amount_vnd)
    values ('BESPAM' || lpad(n::text, 4, '0'), a, 'boba_vip30', 100000);
  end loop;
  begin perform bank_create_order('boba_remove_ads'); assert false, 'quá nhiều đơn pending';
  exception when others then assert sqlerrm = 'too_many_pending', sqlerrm; end;

  raise notice 'BANK OK';
end $$;
