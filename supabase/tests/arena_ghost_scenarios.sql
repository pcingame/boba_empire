-- Trận "bóng ma" Đấu Trường: chờ >12s thì đấu lại bản ghi trận cũ (sao chép hành động, dịch mốc thời gian).
-- Chạy bằng scripts/test_arena_recipe_sql.sh.
\set ON_ERROR_STOP on
insert into auth.users values ('00000000-0000-0000-0000-000000000004') on conflict do nothing;
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
delete from arena_queue; delete from arena_actions; delete from arena_matches;
-- Bản gốc đã kết thúc: user 1 chạm 10 lần (đủ điều kiện), user 2 chỉ 2 lần (quá ít → không thành bóng ma).
insert into arena_matches (id, player_a, player_b, status, started_at, ends_at, score_a, score_b, mode)
  values ('aaaaaaaa-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002',
          'finished', now() - interval '2 hours', now() - interval '2 hours' + interval '60 seconds', 10, 2, 'tap');
insert into arena_actions (match_id, player_id, kind, at)
  select 'aaaaaaaa-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'tap', now() - interval '2 hours' + (i || ' seconds')::interval
  from generate_series(1, 10) i;
insert into arena_actions (match_id, player_id, kind, at)
  select 'aaaaaaaa-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'tap', now() - interval '2 hours' + (i || ' seconds')::interval
  from generate_series(1, 2) i;

-- Chưa chờ đủ 12 giây → vẫn chờ.
select as_u(3);
select (arena_join_queue('tap')).id is null as waiting \gset
select chk('mới vào hàng: chờ, chưa có bóng ma', :'waiting');
reset role;
update arena_queue set joined_at = now() - interval '13 seconds' where player_id = '00000000-0000-0000-0000-000000000003';
-- Dạng không có bản ghi nào → vẫn chờ dù đã quá 12 giây.
select as_u(3);
select (arena_join_queue('match3')).id is null as waiting3 \gset
select chk('không có bản ghi cùng dạng: tiếp tục chờ', :'waiting3');
reset role;
update arena_queue set joined_at = now() - interval '13 seconds' where player_id = '00000000-0000-0000-0000-000000000003';
select as_u(3);
select (arena_join_queue('tap')).id as gid \gset
reset role;
select chk('quá 12 giây: ghép bóng ma', (select ghost and mode = 'tap' and player_a = '00000000-0000-0000-0000-000000000003' from arena_matches where id = :'gid'));
select chk('bóng ma là user 1 (user 2 quá ít hành động)', (select player_b = '00000000-0000-0000-0000-000000000001' from arena_matches where id = :'gid'));
select chk('đã rời hàng đợi', not exists (select 1 from arena_queue where player_id = '00000000-0000-0000-0000-000000000003'));
select chk('sao chép đủ 10 hành động của chủ bản ghi, không của người khác',
  (select count(*) = 10 and bool_and(player_id = '00000000-0000-0000-0000-000000000001') from arena_actions where match_id = :'gid'));
select chk('mốc thời gian dịch: từ bắt đầu trận mới, giữ nguyên khoảng cách 1s',
  (select abs(extract(epoch from min(a.at) - m.started_at) - 1) < 0.5 and abs(extract(epoch from max(a.at) - m.started_at) - 10) < 0.5
   from arena_actions a join arena_matches m on m.id = a.match_id where a.match_id = :'gid' group by m.started_at));
select chk('điểm bóng ma khớp bản gốc (10)', arena_compute_score(:'gid', '00000000-0000-0000-0000-000000000001') = 10);

-- Chủ bản ghi không bị kẹt trong trận của người khác, cũng không ghi được vào đó.
select as_u(1);
select (arena_join_queue('tap')).id is null as owner_waits \gset
select chk('chủ bản ghi vào hàng bình thường (không bị trả trận bóng ma)', :'owner_waits');
select chk('chủ bản ghi không ghi được vào trận bóng ma', err_of(format($$select arena_submit_action(%L::uuid, 'tap')$$, :'gid')) like '%not a participant%');
select arena_leave_queue();
-- Người thật chơi và chốt trận.
select as_u(3);
select arena_submit_action(:'gid'::uuid, 'tap');
reset role;
update arena_matches set ends_at = now() - interval '1 second' where id = :'gid';
select as_u(3);
select chk('chốt trận: bóng ma 10, người chơi 1', (select score_b = 10 and score_a = 1 and winner = player_b from arena_resolve_match(:'gid')));
reset role;
\echo ARENA GHOST OK
