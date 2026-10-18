-- Thưởng cuối mùa BXH Thẻ Mùa: chụp top 10 mùa TRƯỚC (liên kết, XP>0), nhận một lần, đúng hạng, chặn lạ/khách.
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
select season_current_id() - 1 as prev \gset
-- Mùa trước: u1=900, u2=900 (u2 nộp sớm hơn → hạng 1), u3=500, u7 ẩn danh=4000 (loại), u8=0 (loại).
insert into season_leaderboard_entries (user_id, season_id, nickname, xp, updated_at) values
  ('00000000-0000-0000-0000-000000000001', :prev, 'A', 900, now() - interval '1 hour'),
  ('00000000-0000-0000-0000-000000000002', :prev, 'B', 900, now() - interval '2 hours'),
  ('00000000-0000-0000-0000-000000000003', :prev, 'C', 500, now()),
  ('00000000-0000-0000-0000-000000000007', :prev, 'Anon', 4000, now()),
  ('00000000-0000-0000-0000-000000000008', :prev, 'Zero', 0, now());
select chk('hằng số 💎: 1000/600/400, hạng 4-10 = 200, 11 = 0',
  season_reward_gems(1) = 1000 and season_reward_gems(2) = 600 and season_reward_gems(3) = 400
  and season_reward_gems(4) = 200 and season_reward_gems(10) = 200 and season_reward_gems(11) = 0);
select as_u(5);
select chk('người ngoài top: không có thưởng', jsonb_array_length(season_reward_status()) = 0);
reset role;
select chk('chụp đúng thứ tự B,A,C (loại ẩn danh/0 XP)',
  (select string_agg(nickname, ',' order by rank) from season_reward_snapshots where season_id = :prev) = 'B,A,C');
select as_u(2);
select chk('B thấy thưởng hạng 1 = 1000 chưa nhận',
  (season_reward_status()->0->>'rank')::int = 1 and (season_reward_status()->0->>'gems')::int = 1000
  and (season_reward_status()->0->>'claimed')::boolean = false);
select chk('B nhận 1000', season_reward_claim(:prev) = 1000);
select chk('nhận lần hai bị chặn', err_of(format('select season_reward_claim(%s)', :prev)) like '%already claimed%');
select chk('sau nhận: claimed = true', (season_reward_status()->0->>'claimed')::boolean);
select as_u(1);
select chk('A nhận 600 (hạng 2)', season_reward_claim(:prev) = 600);
select as_u(5);
select chk('người ngoài top không nhận được', err_of(format('select season_reward_claim(%s)', :prev)) like '%not found%');
select as_u(7);
select chk('ẩn danh (bị loại) không nhận được', err_of(format('select season_reward_claim(%s)', :prev)) like '%not found%');
select as_u(2);
select chk('mùa khác (hiện tại / xa) không nhận được',
  err_of(format('select season_reward_claim(%s)', :prev + 1)) like '%not found%'
  and err_of(format('select season_reward_claim(%s)', :prev - 1)) like '%not found%');
select as_u(0);
select chk('khách không gọi được', err_of('select season_reward_status()') like '%permission denied%');
select as_u(2);
select chk('client không chụp trực tiếp', err_of('select season_reward_snapshot()') like '%permission denied%');
select chk('không đọc thẳng bảng', err_of('select * from season_reward_snapshots') like '%permission denied%'
  and err_of('select * from season_reward_claims') like '%permission denied%');
\echo SEASON REWARD OK
