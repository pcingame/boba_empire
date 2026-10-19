-- Bạn bè: tìm theo tên, mời/chấp nhận, mời chéo = thành bạn, giới hạn, quà một lần/ngày/bạn, gom quà, BXH, chặn ẩn danh/khách.
-- Chạy bằng scripts/test_friends_sql.sh.
\set ON_ERROR_STOP on
create or replace function as_u(n int) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', case when n = 0 then '' else '00000000-0000-0000-0000-' || lpad(n::text, 12, '0') end, false);
  execute case when n = 0 then 'set role anon' else 'set role authenticated' end;
end $$;
create or replace function uid_of(n int) returns uuid language sql as $$ select ('00000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid $$;
create or replace function err_of(q text) returns text language plpgsql as $$
begin execute q; return 'NO ERROR'; exception when others then return sqlerrm; end $$;
create or replace function chk(name text, ok boolean) returns void language plpgsql as $$
begin if not ok then raise exception 'FAIL: %', name; end if; raise notice 'ok: %', name; end $$;
grant execute on function as_u(int), uid_of(int), err_of(text), chk(text, boolean) to anon, authenticated;
reset role;
-- 1..5 liên kết; 9 ẩn danh
insert into auth.users (id, is_anonymous) select uid_of(i), false from generate_series(1, 5) i;
insert into auth.users (id, is_anonymous) values (uid_of(9), true);
insert into leaderboard_entries (user_id, nickname, lifetime_earnings, stage) values
  (uid_of(1), 'An', 1000, 3), (uid_of(2), 'Binh', 5000, 7), (uid_of(3), 'Binh', 10, 1), (uid_of(4), 'Chi', 300, 2);
select season_current_id() as sid \gset
insert into season_leaderboard_entries (user_id, season_id, nickname, xp) values (uid_of(2), :sid, 'Binh', 700), (uid_of(1), :sid, 'An', 200);

select as_u(1);
select chk('tìm không phân biệt hoa thường, trùng tên → 2 kết quả, giai đoạn cao trước',
  (select string_agg(stage::text, ',') from friend_search('bInH')) = '7,1');
select chk('không tự tìm thấy mình', (select count(*) from friend_search('An')) = 0);
select chk('tìm tên không có → rỗng', (select count(*) from friend_search('Zzz')) = 0);
select chk('mời người ẩn danh bị chặn', err_of(format('select friend_request(%L)', uid_of(9))) like '%not found%');
select chk('tự mời mình bị chặn', err_of(format('select friend_request(%L)', uid_of(1))) like '%bad target%');
select chk('mời Binh(2)', friend_request(uid_of(2)) = 'sent');
select chk('mời lại không nhân đôi', friend_request(uid_of(2)) = 'sent');
reset role;
select chk('chỉ 1 hàng lời mời', (select count(*) from friend_requests) = 1);
select as_u(1);

select as_u(2);
select chk('Binh thấy 1 lời mời từ An', (select jsonb_array_length(friend_overview()->'incoming')) = 1
  and friend_overview()->'incoming'->0->>'nickname' = 'An');
select chk('chấp nhận', friend_respond(uid_of(1), true) = 'accepted');
select chk('hết lời mời', (select jsonb_array_length(friend_overview()->'incoming')) = 0);
select chk('trả lời lời mời không tồn tại bị chặn', err_of(format('select friend_respond(%L, true)', uid_of(1))) like '%not found%');

-- mời chéo: 3 mời 4, 4 mời 3 → thành bạn luôn
select as_u(3); select friend_request(uid_of(4));
select as_u(4);
select chk('mời chéo thành bạn', friend_request(uid_of(3)) = 'accepted');
select chk('đã là bạn → already', friend_request(uid_of(3)) = 'already');

-- từ chối
select as_u(5); select friend_request(uid_of(1));
select as_u(1);
select chk('từ chối', friend_respond(uid_of(5), false) = 'declined' and jsonb_array_length(friend_overview()->'friends') = 1);

-- tổng quan: An thấy Binh với số liệu
select as_u(1);
select chk('An có 1 bạn là Binh, thu nhập/xp/stage đúng',
  friend_overview()->'friends'->0->>'nickname' = 'Binh'
  and (friend_overview()->'friends'->0->>'income')::numeric = 5000
  and (friend_overview()->'friends'->0->>'season_xp')::int = 700
  and (friend_overview()->'friends'->0->>'stage')::int = 7);
select chk('me.income của An', (friend_overview()->'me'->>'income')::numeric = 1000);

-- quà
select chk('chưa kết bạn không tặng được', err_of(format('select friend_gift_send(%L)', uid_of(4))) like '%not friends%');
select friend_gift_send(uid_of(2));
select chk('tặng lần hai trong ngày bị chặn', err_of(format('select friend_gift_send(%L)', uid_of(2))) like '%already sent%');
select chk('gift_sent = true', (friend_overview()->'friends'->0->>'gift_sent')::boolean);
select as_u(2);
select chk('Binh có 1 quà chờ', (friend_overview()->>'gifts_waiting')::int = 1);
select chk('gom quà = 1', friend_gift_claim() = 1);
select chk('gom lại = 0 (một lần)', friend_gift_claim() = 0);
reset role;
-- quà quá 7 ngày hết hạn; quà từ người đã huỷ bạn không nhận được
insert into friend_gifts (from_user, to_user, day) values (uid_of(1), uid_of(2), current_date - 9);
select as_u(2);
select chk('quà cũ >7 ngày không nhận', friend_gift_claim() = 0);
select as_u(1); select friend_gift_send(uid_of(2)) where false;
reset role;
update friend_gifts set claimed = false where to_user = uid_of(2) and day = (now() at time zone 'utc')::date;
select as_u(1); select friend_remove(uid_of(2));
select as_u(2);
select chk('huỷ bạn → quà chưa nhận của người cũ không còn nhận được', friend_gift_claim() = 0);
select chk('huỷ bạn → danh sách rỗng', jsonb_array_length(friend_overview()->'friends') = 0);

-- giới hạn
reset role;
insert into auth.users (id, is_anonymous) select uid_of(100 + i), false from generate_series(1, 31) i;
select as_u(1);
select friend_request(uid_of(100 + i)) from generate_series(1, 30) i;
select chk('31 lời mời đang chờ bị chặn', err_of(format('select friend_request(%L)', uid_of(131))) like '%too many requests%');
reset role;
insert into auth.users (id, is_anonymous) select uid_of(200 + i), false from generate_series(1, 50) i;
insert into friendships (user_a, user_b) select least(uid_of(2), uid_of(200 + i)), greatest(uid_of(2), uid_of(200 + i)) from generate_series(1, 50) i;
insert into friend_requests (from_user, to_user) values (uid_of(3), uid_of(2));
select as_u(2);
select chk('đủ 50 bạn thì không nhận thêm', err_of(format('select friend_respond(%L, true)', uid_of(3))) like '%friend limit%');

-- khách / ẩn danh / đọc thẳng bảng
select as_u(0);
select chk('khách không gọi được', err_of('select friend_overview()') like '%permission denied%');
select as_u(9);
select chk('ẩn danh bị chặn', err_of('select friend_overview()') like '%email link required%');
select chk('không đọc thẳng bảng', err_of('select * from friendships') like '%permission denied%');

-- ghé thăm quán: chỉ bạn bè, trưng bày được lưu, id/số lượng sai bị chặn
reset role;
delete from friendships; delete from friend_requests;
insert into friendships (user_a, user_b) values (uid_of(1), uid_of(2));
select as_u(2); select set_shop_display(array['boba_a', 'cup_2']);
select as_u(1);
select chk('bạn xem quán: stage, thu nhập, trưng bày',
  friend_shop(uid_of(2))->>'nickname' = 'Binh' and (friend_shop(uid_of(2))->>'stage')::int = 7
  and (friend_shop(uid_of(2))->>'income')::numeric = 5000
  and friend_shop(uid_of(2))->'equipped' = '["boba_a","cup_2"]'::jsonb);
select chk('người lạ không xem được quán', err_of(format('select friend_shop(%L)', uid_of(4))) like '%not friends%');
select chk('trưng bày đủ 2 món', (select count(*) from jsonb_array_elements(friend_shop(uid_of(2))->'equipped')) = 2);
select as_u(2);
select chk('id sai dạng bị chặn', err_of($$select set_shop_display(array['Bad Id'])$$) like '%bad display%');
select chk('quá 6 món bị chặn', err_of($$select set_shop_display(array['a','b','c','d','e','f','g'])$$) like '%bad display%');
select set_shop_display('{}');
select as_u(1);
select chk('gỡ hết trưng bày → rỗng', jsonb_array_length(friend_shop(uid_of(2))->'equipped') = 0);
select as_u(0);
select chk('khách không đặt trưng bày', err_of($$select set_shop_display('{}')$$) like '%permission denied%');
select as_u(2);
select chk('không đọc thẳng shop_displays', err_of('select * from shop_displays') like '%permission denied%');
\echo FRIENDS OK
