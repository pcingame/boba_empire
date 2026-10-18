-- BXH Thẻ Mùa: nộp chỉ tăng, chỉ mùa hiện tại, chặn ẩn danh/khách/tên xấu, thứ tự (hoà: ai nộp sớm xếp trên), trần.
-- Chạy bằng scripts/test_lb_rewards_sql.sh.
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
select season_current_id() as sid \gset
select as_u(1); select submit_season_xp('A', :sid, 500);
select as_u(2); select submit_season_xp('B', :sid, 900);
select as_u(3); select submit_season_xp('C', :sid, 500);
select as_u(1); select submit_season_xp('A', :sid, 300);
select chk('chỉ tăng: nộp thấp hơn không hạ XP', (select xp from season_leaderboard_top(10) where nickname = 'A') = 500);
select submit_season_xp('A', :sid, 600);
select as_u(0);
select chk('thứ tự B(900), A(600), C(500)', (select string_agg(nickname, ',' order by rank) from season_leaderboard_top(10)) = 'B,A,C');
select chk('khách không nộp được', err_of(format('select submit_season_xp(''X'', %s, 10)', :sid)) like '%permission denied%');
select as_u(7);
select chk('ẩn danh bị chặn', err_of(format('select submit_season_xp(''X'', %s, 10)', :sid)) like '%email link required%');
select as_u(4);
select submit_season_xp('D', :sid - 1, 4000);
select submit_season_xp('D', :sid + 1, 4000);
select chk('mùa cũ/mùa tương lai bị bỏ qua', (select count(*) from season_leaderboard_top(10) where nickname = 'D') = 0);
select chk('tên rỗng bị chặn', err_of(format('select submit_season_xp('' '', %s, 10)', :sid)) like '%bad nickname%');
select submit_season_xp('D', :sid, 99999);
select chk('trần 4200', (select xp from season_leaderboard_top(10) where nickname = 'D') = 4200);
select chk('không đọc thẳng bảng', err_of($$select * from season_leaderboard_entries$$) like '%permission denied%');
\echo SEASON LB OK
