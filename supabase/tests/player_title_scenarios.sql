-- Danh hiệu hồ sơ: chọn/đổi/bỏ, whitelist, chặn ẩn danh/khách, tra theo tên. Chạy bằng scripts/test_lb_rewards_sql.sh.
\set ON_ERROR_STOP on
create or replace function as_u(n int) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', case when n = 0 then '' else '00000000-0000-0000-0000-00000000000' || n end, false);
  execute case when n = 0 then 'set role anon' else 'set role authenticated' end;
end $$;
create or replace function err_of(q text) returns text language plpgsql as $$
begin execute q; return 'NO ERROR'; exception when others then return sqlerrm; end $$;
create or replace function chk(name text, ok boolean) returns void language plpgsql as $$
begin if not ok then raise exception 'FAIL: %', name; end if; raise notice 'ok: %', name; end $$;
grant execute on function as_u(int), err_of(text), chk(text, boolean) to anon, authenticated;
reset role;
select chk('u1 (liên kết, tên A trên BXH thu nhập) tồn tại',
  (select count(*) from leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000001' and nickname = 'A') = 1);
select as_u(1);
select set_player_title('legend');
select chk('chọn xong tra theo tên (không phân biệt hoa thường)', player_title('a') = 'legend');
select chk('danh hiệu lạ bị chặn', err_of($$select set_player_title('hack')$$) like '%invalid title%');
select set_player_title('vip');
select chk('đổi danh hiệu', player_title('A') = 'vip');
select as_u(0);
select chk('khách xem được danh hiệu', player_title('A') = 'vip');
select chk('khách không đặt được', err_of($$select set_player_title('vip')$$) like '%permission denied%');
select chk('tên không ai dùng → rỗng', player_title('Nobody') = '');
select as_u(7);
select chk('tài khoản ẩn danh bị chặn', err_of($$select set_player_title('vip')$$) like '%not linked%');
select as_u(1);
select set_player_title('');
select chk('bỏ danh hiệu → rỗng', player_title('A') = '');
select as_u(2);
select chk('không đọc thẳng bảng', err_of($$select * from player_titles$$) like '%permission denied%');
\echo PLAYER TITLE OK
