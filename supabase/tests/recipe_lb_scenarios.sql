-- Bảng xếp hạng Thợ pha chế: ràng buộc 0..100, chỉ tăng, chỉ sửa hàng của mình, top đúng thứ tự, quyền.
-- Chạy bằng scripts/test_lb_rewards_sql.sh (cùng DB tạm, sau kịch bản thưởng).
\set ON_ERROR_STOP on
create function r_as(n int) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', case when n = 0 then '' else '00000000-0000-0000-0000-0000000001' || lpad(n::text, 2, '0') end, false);
  execute case when n = 0 then 'set role anon' else 'set role authenticated' end;
end $$;
grant execute on function r_as(int) to anon, authenticated;
create function r_err(q text) returns text language plpgsql as $$
begin execute q; return 'NO ERROR'; exception when others then return sqlerrm; end $$;
grant execute on function r_err(text) to anon, authenticated;
create function r_chk(name text, ok boolean) returns void language plpgsql as $$
begin if not ok then raise exception 'FAIL: %', name; end if; raise notice 'ok: %', name; end $$;
grant execute on function r_chk(text, boolean) to anon, authenticated;

-- Supabase mặc định cấp mọi quyền bảng cho anon/authenticated; RLS mới là thứ chặn. DB tạm không có nên cấp ở đây.
grant all on recipe_leaderboard_entries to anon, authenticated;
delete from recipe_leaderboard_entries;  -- cùng DB với kịch bản thưởng: bắt đầu từ bảng trống

insert into auth.users (id, is_anonymous) select ('00000000-0000-0000-0000-0000000001' || lpad(i::text, 2, '0'))::uuid, false from generate_series(1, 6) i;

-- Ghi: chỉ hàng của mình, đúng ràng buộc.
select r_as(1);
insert into recipe_leaderboard_entries (user_id, nickname, mastered) values ('00000000-0000-0000-0000-000000000101', 'P1', 5);
select r_chk('tự thêm hàng của mình', (select mastered from recipe_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000101') = 5);
select r_chk('không thêm hàng cho người khác', r_err($$insert into recipe_leaderboard_entries (user_id, nickname, mastered) values ('00000000-0000-0000-0000-000000000102', 'X', 1)$$) like '%row-level security%');
select r_chk('không âm', r_err($$insert into recipe_leaderboard_entries (user_id, nickname, mastered) values ('00000000-0000-0000-0000-000000000101', 'P1', -1) on conflict (user_id) do update set mastered = -1$$) like '%check%');
select r_chk('không vượt 100', r_err($$update recipe_leaderboard_entries set mastered = 101$$) like '%check%');
select r_chk('tên 1..20 ký tự', r_err($$update recipe_leaderboard_entries set nickname = ''$$) like '%check%'
  and r_err($$update recipe_leaderboard_entries set nickname = repeat('x', 21)$$) like '%check%');

-- Chỉ tăng: hạ xuống bị giữ nguyên; tăng được; updated_at đổi.
update recipe_leaderboard_entries set mastered = 2 where user_id = '00000000-0000-0000-0000-000000000101';
select r_chk('hạ 5 → 2: vẫn 5', (select mastered from recipe_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000101') = 5);
update recipe_leaderboard_entries set mastered = 9 where user_id = '00000000-0000-0000-0000-000000000101';
select r_chk('tăng 5 → 9: được', (select mastered from recipe_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000101') = 9);
-- upsert như app làm (nickname luôn kèm).
insert into recipe_leaderboard_entries (user_id, nickname, mastered) values ('00000000-0000-0000-0000-000000000101', 'P1', 7)
  on conflict (user_id) do update set nickname = excluded.nickname, mastered = excluded.mastered;
select r_chk('upsert với số thấp hơn không hạ điểm', (select mastered from recipe_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000101') = 9);

-- Không sửa được hàng người khác.
select r_as(2);
insert into recipe_leaderboard_entries (user_id, nickname, mastered) values ('00000000-0000-0000-0000-000000000102', 'P2', 9);
update recipe_leaderboard_entries set mastered = 100 where user_id = '00000000-0000-0000-0000-000000000101';
select r_chk('không đẩy điểm người khác', (select mastered from recipe_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000101') = 9);
delete from recipe_leaderboard_entries;  -- RLS không có policy delete ⇒ 0 hàng bị xoá, không lỗi
select r_chk('không xoá được (không có policy delete)', (select count(*) from recipe_leaderboard_entries) = 2);

-- Top: điểm giảm dần, hoà → nộp sớm hơn xếp trên; trần 100 hàng; khách đọc được.
reset role;
insert into recipe_leaderboard_entries (user_id, nickname, mastered, updated_at) values
  ('00000000-0000-0000-0000-000000000103', 'P3', 20, now() - interval '5 hours'),
  ('00000000-0000-0000-0000-000000000104', 'P4', 9, now() - interval '9 hours');
select r_as(0);
select r_chk('khách đọc được top', (select count(*) from recipe_leaderboard_top(50)) = 4);
select r_chk('thứ tự: P3(20) rồi hoà 9 theo nộp sớm: P4, P1, P2',
  (select string_agg(nickname, ',' order by rank) from recipe_leaderboard_top(50)) = 'P3,P4,P1,P2');
select r_chk('p_limit nhỏ cắt đúng', (select count(*) from recipe_leaderboard_top(2)) = 2);
select r_chk('p_limit lớn bị kẹp 100 (không đọc vô hạn)', (select count(*) from recipe_leaderboard_top(100000)) = 4);
select r_chk('khách không ghi được (RLS)', r_err($$insert into recipe_leaderboard_entries (user_id, nickname, mastered) values ('00000000-0000-0000-0000-000000000105', 'Z', 1)$$) like '%row-level security%');
reset role;
select 'RECIPE LB OK';

-- ===== Bảng Pha theo đơn: cùng kịch bản như trên + ép email ở server (is_linked_user). =====
-- Người dùng 01..06 đã tạo ở kịch bản trước (liên kết). Thêm người ẩn danh 07.
-- Supabase mặc định cấp mọi quyền bảng cho anon/authenticated; RLS mới là thứ chặn. DB tạm không có nên cấp ở đây.
grant all on recipe_order_leaderboard_entries to anon, authenticated;
delete from recipe_order_leaderboard_entries;  -- cùng DB với kịch bản thưởng: bắt đầu từ bảng trống


-- Ghi: chỉ hàng của mình, đúng ràng buộc.
reset role;
insert into auth.users (id, is_anonymous) values ('00000000-0000-0000-0000-000000000107', true) on conflict do nothing;
select r_as(7);
select r_chk('ẩn danh KHÔNG ghi được', r_err($$insert into recipe_order_leaderboard_entries (user_id, nickname, perfected) values ('00000000-0000-0000-0000-000000000107', 'Anon', 3)$$) like '%row-level security%');
select r_chk('ẩn danh không thành hàng nào', (select count(*) from recipe_order_leaderboard_entries) = 0);
select r_as(1);
insert into recipe_order_leaderboard_entries (user_id, nickname, perfected) values ('00000000-0000-0000-0000-000000000101', 'P1', 5);
select r_chk('tự thêm hàng của mình', (select perfected from recipe_order_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000101') = 5);
select r_chk('không thêm hàng cho người khác', r_err($$insert into recipe_order_leaderboard_entries (user_id, nickname, perfected) values ('00000000-0000-0000-0000-000000000102', 'X', 1)$$) like '%row-level security%');
select r_chk('không âm', r_err($$insert into recipe_order_leaderboard_entries (user_id, nickname, perfected) values ('00000000-0000-0000-0000-000000000101', 'P1', -1) on conflict (user_id) do update set perfected = -1$$) like '%check%');
select r_chk('không vượt 100', r_err($$update recipe_order_leaderboard_entries set perfected = 101$$) like '%check%');
select r_chk('tên 1..20 ký tự', r_err($$update recipe_order_leaderboard_entries set nickname = ''$$) like '%check%'
  and r_err($$update recipe_order_leaderboard_entries set nickname = repeat('x', 21)$$) like '%check%');

-- Chỉ tăng: hạ xuống bị giữ nguyên; tăng được; updated_at đổi.
update recipe_order_leaderboard_entries set perfected = 2 where user_id = '00000000-0000-0000-0000-000000000101';
select r_chk('hạ 5 → 2: vẫn 5', (select perfected from recipe_order_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000101') = 5);
update recipe_order_leaderboard_entries set perfected = 9 where user_id = '00000000-0000-0000-0000-000000000101';
select r_chk('tăng 5 → 9: được', (select perfected from recipe_order_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000101') = 9);
-- upsert như app làm (nickname luôn kèm).
insert into recipe_order_leaderboard_entries (user_id, nickname, perfected) values ('00000000-0000-0000-0000-000000000101', 'P1', 7)
  on conflict (user_id) do update set nickname = excluded.nickname, perfected = excluded.perfected;
select r_chk('upsert với số thấp hơn không hạ điểm', (select perfected from recipe_order_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000101') = 9);

-- Không sửa được hàng người khác.
select r_as(2);
insert into recipe_order_leaderboard_entries (user_id, nickname, perfected) values ('00000000-0000-0000-0000-000000000102', 'P2', 9);
update recipe_order_leaderboard_entries set perfected = 100 where user_id = '00000000-0000-0000-0000-000000000101';
select r_chk('không đẩy điểm người khác', (select perfected from recipe_order_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000101') = 9);
delete from recipe_order_leaderboard_entries;  -- RLS không có policy delete ⇒ 0 hàng bị xoá, không lỗi
select r_chk('không xoá được (không có policy delete)', (select count(*) from recipe_order_leaderboard_entries) = 2);

-- Top: điểm giảm dần, hoà → nộp sớm hơn xếp trên; trần 100 hàng; khách đọc được.
reset role;
insert into recipe_order_leaderboard_entries (user_id, nickname, perfected, updated_at) values
  ('00000000-0000-0000-0000-000000000103', 'P3', 20, now() - interval '5 hours'),
  ('00000000-0000-0000-0000-000000000104', 'P4', 9, now() - interval '9 hours');
select r_as(0);
select r_chk('khách đọc được top', (select count(*) from recipe_order_leaderboard_top(50)) = 4);
select r_chk('thứ tự: P3(20) rồi hoà 9 theo nộp sớm: P4, P1, P2',
  (select string_agg(nickname, ',' order by rank) from recipe_order_leaderboard_top(50)) = 'P3,P4,P1,P2');
select r_chk('p_limit nhỏ cắt đúng', (select count(*) from recipe_order_leaderboard_top(2)) = 2);
select r_chk('p_limit lớn bị kẹp 100 (không đọc vô hạn)', (select count(*) from recipe_order_leaderboard_top(100000)) = 4);
select r_chk('khách không ghi được (RLS)', r_err($$insert into recipe_order_leaderboard_entries (user_id, nickname, perfected) values ('00000000-0000-0000-0000-000000000105', 'Z', 1)$$) like '%row-level security%');
reset role;
select 'RECIPE ORDER LB OK';
