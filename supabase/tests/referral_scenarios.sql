-- Kịch bản test cho referral_schema.sql trên Postgres THUẦN (xem scripts/test_referral_sql.sh).
create or replace function u(n integer) returns uuid language sql immutable as
  $$ select ('00000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid $$;

-- Đóng vai người dùng thật (p_anon=false) hoặc đăng nhập ẩn danh (p_anon=true).
create or replace function t_as(p_uid uuid, p_anon boolean default false) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', coalesce(p_uid::text, ''), false);
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_uid, 'is_anonymous', p_anon)::text, false);
  if p_uid is null then set role anon; else set role authenticated; end if;
end $$;

create or replace function t_err(p_sql text, p_msg text) returns void language plpgsql as $$
begin
  begin execute p_sql;
  exception when others then
    if position(p_msg in sqlerrm) = 0 then
      raise exception 'lỗi sai: muốn "%" nhưng nhận "%" (sql: %)', p_msg, sqlerrm, p_sql;
    end if;
    return;
  end;
  raise exception 'KỲ VỌNG lỗi "%" nhưng chạy thành công: %', p_msg, p_sql;
end $$;

create or replace function t_eq(p_label text, p_got anyelement, p_want anyelement)
returns void language plpgsql as $$
begin
  if p_got is distinct from p_want then
    raise exception '% : nhận % muốn %', p_label, p_got, p_want;
  end if;
end $$;

insert into auth.users select u(n) from generate_series(1, 30) n;


-- Mã của tôi: 6 ký tự đúng bảng chữ, ổn định giữa các lần gọi, mỗi người một mã.
select t_as(u(1));
select t_eq('mã 6 ký tự hợp lệ', referral_my_code() ~ '^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{6}$', true);
select t_eq('mã ổn định', referral_my_code(), referral_my_code());
select t_as(u(2));
select referral_my_code();
reset role;
select t_eq('mỗi người một mã', (select count(distinct code) from referral_codes), 2::bigint);

-- Tài khoản ẩn danh không dùng được.
select t_as(u(3), true);
select t_err($$select referral_my_code()$$, 'email required');
select t_err($$select referral_redeem('ABCDEF')$$, 'email required');
select t_err($$select referral_status()$$, 'email required');
select t_err($$select referral_claim()$$, 'email required');

-- Nhập mã.
reset role;
select code as c1 from referral_codes where user_id = u(1) \gset
select t_as(u(4));
select t_eq('nhập mã đúng → 100 💎', referral_redeem(:'c1'), 100);
select t_err(format($$select referral_redeem(%L)$$, :'c1'), 'already redeemed');
select t_eq('không phân biệt hoa/thường và khoảng trắng', referral_status()->>'redeemed', 'true');
select t_as(u(5));
select t_eq('nhập mã chữ thường + khoảng trắng vẫn nhận', referral_redeem(' ' || lower(:'c1') || ' '), 100);
select t_err($$select referral_redeem('ZZZZZZ')$$, 'not found');
select t_as(u(1));
select t_err(format($$select referral_redeem(%L)$$, :'c1'), 'invalid code');          -- mã của chính mình
-- Không cho hai người tự mời nhau: u1 là người mời của u4 thì u1 không nhập được mã của u4.
select t_as(u(4));
select referral_my_code();
reset role;
select code as c4 from referral_codes where user_id = u(4) \gset
select t_as(u(1));
select t_err(format($$select referral_redeem(%L)$$, :'c4'), 'invalid code');

-- Người mời chỉ nhận thưởng khi bạn đạt giai đoạn.
select t_eq('chưa ai đạt: claimable = 0', (referral_status()->>'claimable')::int, 0);
select t_err($$select referral_claim()$$, 'nothing to claim');
select t_as(u(4));
select referral_report_stage(2);                                                          -- chưa đủ
select t_as(u(1));
select t_eq('giai đoạn 2 chưa đủ', (referral_status()->>'reached')::int, 0);
select t_as(u(4)); select referral_report_stage(3);
select t_as(u(1));
select t_eq('đã mời 2 người', (referral_status()->>'invited')::int, 2);
select t_eq('1 người đạt', (referral_status()->>'reached')::int, 1);
select t_eq('nhận thưởng 100 💎', referral_claim(), 100);
select t_err($$select referral_claim()$$, 'nothing to claim');                          -- không nhận lại
select t_as(u(5)); select referral_report_stage(9);
select t_as(u(1));
select t_eq('người thứ 2 đạt → nhận tiếp 100', referral_claim(), 100);
-- Người không phải bạn được mời báo giai đoạn: không ảnh hưởng ai.
select t_as(u(20)); select referral_report_stage(99);

-- Trần số lời mời: 20.
reset role;
select code as c2 from referral_codes where user_id = u(2) \gset
-- 20 người lần lượt nhập mã của u2 (u1..u5 không dùng): u6..u25.
select t_as(u(6)); select referral_redeem(:'c2');
select t_as(u(7)); select referral_redeem(:'c2');
select t_as(u(8)); select referral_redeem(:'c2');
select t_as(u(9)); select referral_redeem(:'c2');
select t_as(u(10)); select referral_redeem(:'c2');
select t_as(u(11)); select referral_redeem(:'c2');
select t_as(u(12)); select referral_redeem(:'c2');
select t_as(u(13)); select referral_redeem(:'c2');
select t_as(u(14)); select referral_redeem(:'c2');
select t_as(u(15)); select referral_redeem(:'c2');
select t_as(u(16)); select referral_redeem(:'c2');
select t_as(u(17)); select referral_redeem(:'c2');
select t_as(u(18)); select referral_redeem(:'c2');
select t_as(u(19)); select referral_redeem(:'c2');
select t_as(u(20)); select referral_redeem(:'c2');
select t_as(u(21)); select referral_redeem(:'c2');
select t_as(u(22)); select referral_redeem(:'c2');
select t_as(u(23)); select referral_redeem(:'c2');
select t_as(u(24)); select referral_redeem(:'c2');
select t_as(u(25)); select referral_redeem(:'c2');
select t_as(u(27));
select t_err(format($$select referral_redeem(%L)$$, :'c2'), 'inviter full');

-- Bảo mật: không đọc thẳng bảng, khách chưa đăng nhập không gọi được.
select t_as(u(1));
-- Đọc thẳng bảng phải bị chặn: Supabase thật (RLS, không policy) trả 0 hàng, DB thuần báo thiếu quyền.
do $$ begin
  if exists (select 1 from referrals) then raise exception 'ĐỌC ĐƯỢC referrals'; end if;
exception when insufficient_privilege then null; end $$;
do $$ begin
  if exists (select 1 from referral_codes) then raise exception 'ĐỌC ĐƯỢC referral_codes'; end if;
exception when insufficient_privilege then null; end $$;
select t_as(null);
select t_err($$select referral_my_code()$$, 'permission denied');
select t_err($$select referral_redeem('ABCDEF')$$, 'permission denied');
reset role;

select 'ALL REFERRAL SQL SCENARIOS PASSED' as result;
