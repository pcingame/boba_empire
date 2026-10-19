-- BXH Chi nhánh: chỉ tăng, chặn ẩn danh/khách/tên xấu, thứ tự (hoà: ai đạt trước xếp trên), trần. Chạy bằng scripts/test_lb_rewards_sql.sh.
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
select as_u(1); select submit_branch_levels('A', 40, 8);
select as_u(2); select submit_branch_levels('B', 90, 12);
select as_u(3); select submit_branch_levels('C', 40, 9);
select as_u(1); select submit_branch_levels('A', 10, 3);
select chk('chỉ tăng: nộp thấp hơn không hạ', (select total_levels from branch_leaderboard_top(10) where nickname = 'A') = 40);
select chk('opened cũng chỉ tăng', (select opened from branch_leaderboard_top(10) where nickname = 'A') = 8);
select submit_branch_levels('A', 60, 8);
select as_u(0);
select chk('thứ tự B(90), A(60), C(40)', (select string_agg(nickname, ',' order by rank) from branch_leaderboard_top(10)) = 'B,A,C');
select chk('khách không nộp được', err_of($$select submit_branch_levels('X', 10, 1)$$) like '%permission denied%');
select as_u(7);
select chk('ẩn danh bị chặn', err_of($$select submit_branch_levels('X', 10, 1)$$) like '%email link required%');
select as_u(4);
select chk('tên rỗng bị chặn', err_of($$select submit_branch_levels(' ', 10, 1)$$) like '%bad nickname%');
select submit_branch_levels('D', 99999, 9999);
select chk('trần 500 / 50', (select total_levels from branch_leaderboard_top(10) where nickname = 'D') = 500
                        and (select opened from branch_leaderboard_top(10) where nickname = 'D') = 50);
select submit_branch_levels('E', 0, 0);
select chk('0 cấp không vào bảng', (select count(*) from branch_leaderboard_top(10) where nickname = 'E') = 0);
select chk('không đọc thẳng bảng', err_of($$select * from branch_leaderboard_entries$$) like '%permission denied%');
\echo BRANCH LB OK
