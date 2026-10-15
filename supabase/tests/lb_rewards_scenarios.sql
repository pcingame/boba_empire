-- Thưởng top BXH theo tuần: chụp top 3 (đúng thứ tự, loại ẩn danh/0 điểm), nhận một lần, hết hạn, quyền.
-- Chạy bằng scripts/test_lb_rewards_sql.sh.
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

insert into auth.users (id, is_anonymous) values
  ('00000000-0000-0000-0000-000000000001', false), ('00000000-0000-0000-0000-000000000002', false),
  ('00000000-0000-0000-0000-000000000003', false), ('00000000-0000-0000-0000-000000000004', false),
  ('00000000-0000-0000-0000-000000000005', false), ('00000000-0000-0000-0000-000000000006', false),
  ('00000000-0000-0000-0000-000000000007', true),  ('00000000-0000-0000-0000-000000000008', false);

-- Thu nhập: u1 và u2 hoà 1000 (u1 nộp sớm hơn → hạng 1); u3 500; u4 400; u7 ẩn danh 9999; u8 điểm 0.
insert into leaderboard_entries (user_id, nickname, lifetime_earnings, updated_at) values
  ('00000000-0000-0000-0000-000000000001', 'A', 1000, now() - interval '3 hours'),
  ('00000000-0000-0000-0000-000000000002', 'B', 1000, now() - interval '2 hours'),
  ('00000000-0000-0000-0000-000000000003', 'C', 500,  now()),
  ('00000000-0000-0000-0000-000000000004', 'D', 400,  now()),
  ('00000000-0000-0000-0000-000000000007', 'Anon', 9999, now()),
  ('00000000-0000-0000-0000-000000000008', 'Zero', 0, now());
insert into m3_leaderboard_entries (user_id, nickname, stars, levels_cleared) values
  ('00000000-0000-0000-0000-000000000004', 'D', 30, 10), ('00000000-0000-0000-0000-000000000001', 'A', 12, 5);
insert into accessory_leaderboard_entries (user_id, nickname, owned_count) values
  ('00000000-0000-0000-0000-000000000002', 'B', 100), ('00000000-0000-0000-0000-000000000003', 'C', 80);
insert into vip_leaderboard_entries (user_id, nickname, vip_exp) values
  ('00000000-0000-0000-0000-000000000003', 'C', 5000), ('00000000-0000-0000-0000-000000000001', 'A', 3000);

-- Thợ pha chế: B và C hoà 12 (B nộp sớm hơn → hạng 1); D 5; A 3 (hạng 4: ngoài top); u7 ẩn danh 50; u8 0 món.
insert into recipe_leaderboard_entries (user_id, nickname, mastered, updated_at) values
  ('00000000-0000-0000-0000-000000000002', 'B', 12, now() - interval '2 hours'),
  ('00000000-0000-0000-0000-000000000003', 'C', 12, now() - interval '1 hour'),
  ('00000000-0000-0000-0000-000000000004', 'D', 5,  now()),
  ('00000000-0000-0000-0000-000000000001', 'A', 3,  now()),
  ('00000000-0000-0000-0000-000000000007', 'Anon', 50, now()),
  ('00000000-0000-0000-0000-000000000008', 'Zero', 0, now());

-- Pha theo đơn: C 9; B và D hoà 4 (B nộp sớm hơn → hạng 2); u7 ẩn danh 77; u8 0 món. A không có mặt.
insert into recipe_order_leaderboard_entries (user_id, nickname, perfected, updated_at) values
  ('00000000-0000-0000-0000-000000000003', 'C', 9, now()),
  ('00000000-0000-0000-0000-000000000002', 'B', 4, now() - interval '2 hours'),
  ('00000000-0000-0000-0000-000000000004', 'D', 4, now() - interval '1 hour'),
  ('00000000-0000-0000-0000-000000000007', 'Anon', 77, now()),
  ('00000000-0000-0000-0000-000000000008', 'Zero', 0, now());

select chk('hằng số thưởng 300/200/100, hạng ngoài top = 0',
  lb_reward_gems(1) = 300 and lb_reward_gems(2) = 200 and lb_reward_gems(3) = 100 and lb_reward_gems(4) = 0);

-- Người không có thưởng gọi trạng thái: [] (và kích hoạt chụp).
select as_u(5);
select chk('người ngoài top: không có thưởng', jsonb_array_length(lb_reward_status()) = 0);
reset role;
select chk('thu nhập top 1-2-3 = A, B, C (hoà → nộp sớm hơn xếp trên; loại ẩn danh và 0 điểm)',
  (select string_agg(nickname, ',' order by rank) from lb_reward_snapshots where board = 'income') = 'A,B,C');
select chk('Ghép 3: D rồi A', (select string_agg(nickname, ',' order by rank) from lb_reward_snapshots where board = 'pearls') = 'D,A');
select chk('Sưu tập: B rồi C', (select string_agg(nickname, ',' order by rank) from lb_reward_snapshots where board = 'collection') = 'B,C');
select chk('Thợ pha chế: B, C, D (hoà → nộp sớm hơn xếp trên; loại ẩn danh, 0 món, và A hạng 4)',
  (select string_agg(nickname, ',' order by rank) from lb_reward_snapshots where board = 'recipes') = 'B,C,D');
select chk('Pha theo đơn: C, B, D (hoà → nộp sớm hơn xếp trên; loại ẩn danh và 0 món)',
  (select string_agg(nickname, ',' order by rank) from lb_reward_snapshots where board = 'orders') = 'C,B,D');
select chk('VIP: C rồi A', (select string_agg(nickname, ',' order by rank) from lb_reward_snapshots where board = 'vip') = 'C,A');
select count(*) as n0 from lb_reward_snapshots \gset
select week as w from lb_reward_snapshots limit 1 \gset

-- Chụp một lần mỗi tuần: gọi lại + đổi điểm sau đó không làm đổi ảnh chụp.
update leaderboard_entries set lifetime_earnings = 99999 where user_id = '00000000-0000-0000-0000-000000000004';
select as_u(5); select lb_reward_status();
reset role;
select chk('chụp idempotent, không bị điểm đổi sau đó làm lệch', (select count(*) from lb_reward_snapshots) = :n0
  and (select string_agg(nickname, ',' order by rank) from lb_reward_snapshots where board = 'income') = 'A,B,C');

-- Trạng thái của A: top 1 thu nhập (300), Ghép 3 hạng 2 (200), VIP hạng 2 (200).
select as_u(1);
select chk('A thấy 3 phần thưởng chưa nhận', jsonb_array_length(lb_reward_status()) = 3
  and not exists (select 1 from jsonb_array_elements(lb_reward_status()) e where (e->>'claimed')::boolean));
select chk('A: thu nhập hạng 1 = 300💎', (select (e->>'gems')::int from jsonb_array_elements(lb_reward_status()) e where e->>'board' = 'income') = 300);
select chk('nhận thu nhập trả đúng 300', lb_reward_claim(:'w', 'income') = 300);
select chk('nhận lần hai bị chặn', err_of(format('select lb_reward_claim(%L, ''income'')', :'w')) like '%already claimed%');
select chk('sau khi nhận: claimed = true', (select (e->>'claimed')::boolean from jsonb_array_elements(lb_reward_status()) e where e->>'board' = 'income'));
select chk('nhận bảng khác độc lập (Ghép 3 hạng 2 = 200)', lb_reward_claim(:'w', 'pearls') = 200);
select chk('nhận bảng mình KHÔNG có trong top bị từ chối', err_of(format('select lb_reward_claim(%L, ''collection'')', :'w')) like '%not found%');
select chk('A (hạng 4 Thợ pha chế) không nhận được', err_of(format('select lb_reward_claim(%L, ''recipes'')', :'w')) like '%not found%');
select as_u(2); select chk('B Thợ pha chế hạng 1 = 300', lb_reward_claim(:'w', 'recipes') = 300);
select chk('B nhận Thợ pha chế lần hai bị chặn', err_of(format('select lb_reward_claim(%L, ''recipes'')', :'w')) like '%already claimed%');
select as_u(4); select chk('D Thợ pha chế hạng 3 = 100', lb_reward_claim(:'w', 'recipes') = 100);
select as_u(3); select chk('C Pha theo đơn hạng 1 = 300', lb_reward_claim(:'w', 'orders') = 300);
select chk('C nhận Pha theo đơn lần hai bị chặn', err_of(format('select lb_reward_claim(%L, ''orders'')', :'w')) like '%already claimed%');
select as_u(1); select chk('A (không có trong bảng Pha theo đơn) không nhận được', err_of(format('select lb_reward_claim(%L, ''orders'')', :'w')) like '%not found%');
select as_u(2); select chk('B thu nhập hạng 2 = 200', lb_reward_claim(:'w', 'income') = 200);
select as_u(3); select chk('C thu nhập hạng 3 = 100', lb_reward_claim(:'w', 'income') = 100);
select as_u(4); select chk('D (hạng 4 thu nhập) không nhận được', err_of(format('select lb_reward_claim(%L, ''income'')', :'w')) like '%not found%');
select as_u(7); select chk('tài khoản ẩn danh không có thưởng', err_of(format('select lb_reward_claim(%L, ''income'')', :'w')) like '%not found%');
select chk('tuần sai bị từ chối', err_of($$select lb_reward_claim('2020-01-06', 'income')$$) like '%not found%');
select chk('bảng lạ bị từ chối', err_of(format('select lb_reward_claim(%L, ''speed'')', :'w')) like '%not found%');

-- Hết hạn: ảnh chụp cũ hơn 2 tuần không còn nhận được.
reset role;
update lb_reward_snapshots set week = week - 21;
select as_u(2);
select chk('quá hạn: trạng thái không còn thấy', jsonb_array_length(lb_reward_status()) = 0 or
  not exists (select 1 from jsonb_array_elements(lb_reward_status()) e where (e->>'week')::date < current_date - 14));
select chk('quá hạn: không nhận được', err_of(format('select lb_reward_claim(%L, ''income'')', (:'w'::date - 21))) like '%not found%');

-- Bảo mật.
select as_u(0);
select chk('khách (anon) không gọi được', err_of('select lb_reward_status()') like '%permission denied%');
select as_u(1);
select chk('client không gọi chụp trực tiếp', err_of('select lb_reward_snapshot()') like '%permission denied%');
select chk('không đọc được bảng thưởng', err_of('select * from lb_reward_snapshots') like '%permission denied%');
reset role;
select 'LB REWARDS OK';
