-- ÉP LIÊN KẾT EMAIL Ở SERVER cho các bảng xếp hạng cũ: tài khoản ẩn danh không ghi được (insert/update/RPC),
-- tài khoản đã liên kết thì ghi bình thường. Chạy bằng scripts/test_lb_rewards_sql.sh (cùng DB tạm).
\set ON_ERROR_STOP on
create function k_as(n int) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', case when n = 0 then '' else '00000000-0000-0000-0000-000000000' || lpad(n::text, 3, '0') end, false);
  execute case when n = 0 then 'set role anon' else 'set role authenticated' end;
end $$;
grant execute on function k_as(int) to anon, authenticated;
create function k_err(q text) returns text language plpgsql as $$
begin execute q; return 'NO ERROR'; exception when others then return sqlerrm; end $$;
grant execute on function k_err(text) to anon, authenticated;
create function k_rows(q text) returns bigint language plpgsql as $$
declare n bigint; begin execute q; get diagnostics n = row_count; return n; end $$;
grant execute on function k_rows(text) to anon, authenticated;
create function k_chk(name text, ok boolean) returns void language plpgsql as $$
begin if not ok then raise exception 'FAIL: %', name; end if; raise notice 'ok: %', name; end $$;
grant execute on function k_chk(text, boolean) to anon, authenticated;

grant all on leaderboard_entries, m3_leaderboard_entries, accessory_leaderboard_entries, recipe_leaderboard_entries,
  story_speedrun_entries, story_speedrun2_entries, story_speedrun3_entries, story_speedrun4_entries,
  vip_leaderboard_entries, event_leaderboard_entries to anon, authenticated;

-- 301 = ẩn danh (có sẵn hàng cũ ở các bảng cập nhật được), 302 = đã liên kết, 303 = đã liên kết (hạng 1 bảng thu nhập).
insert into auth.users (id, is_anonymous) values
  ('00000000-0000-0000-0000-000000000301', true),
  ('00000000-0000-0000-0000-000000000302', false),
  ('00000000-0000-0000-0000-000000000303', false),
  ('00000000-0000-0000-0000-000000000304', true);  -- ẩn danh CHƯA có hàng nào: kiểm policy INSERT thuần (không qua nhánh UPDATE)
delete from leaderboard_entries where user_id in ('00000000-0000-0000-0000-000000000301','00000000-0000-0000-0000-000000000302','00000000-0000-0000-0000-000000000303');
insert into leaderboard_entries (user_id, nickname, lifetime_earnings) values ('00000000-0000-0000-0000-000000000301', 'Anon', 1000);
insert into m3_leaderboard_entries (user_id, nickname, stars, levels_cleared) values ('00000000-0000-0000-0000-000000000301', 'Anon', 5, 2);
insert into accessory_leaderboard_entries (user_id, nickname, owned_count) values ('00000000-0000-0000-0000-000000000301', 'Anon', 3);
insert into recipe_leaderboard_entries (user_id, nickname, mastered) values ('00000000-0000-0000-0000-000000000301', 'Anon', 2);

-- ===== 1. Bảng ghi bằng policy: leaderboard (thu nhập), m3 (Trân Châu), accessory (sưu tập), recipe (thợ pha chế) =====
select k_as(301);
select k_chk('ẩn danh KHÔNG sửa được hàng cũ của mình — thu nhập', k_rows($$update leaderboard_entries set lifetime_earnings = 5000 where user_id = '00000000-0000-0000-0000-000000000301'$$) = 0);
select k_chk('ẩn danh KHÔNG sửa được — Trân Châu', k_rows($$update m3_leaderboard_entries set stars = 99 where user_id = '00000000-0000-0000-0000-000000000301'$$) = 0);
select k_chk('ẩn danh KHÔNG sửa được — Sưu tập', k_rows($$update accessory_leaderboard_entries set owned_count = 50 where user_id = '00000000-0000-0000-0000-000000000301'$$) = 0);
select k_chk('ẩn danh KHÔNG sửa được — Thợ pha chế', k_rows($$update recipe_leaderboard_entries set mastered = 50 where user_id = '00000000-0000-0000-0000-000000000301'$$) = 0);
reset role;
select k_chk('hàng cũ của ẩn danh nguyên vẹn', (select lifetime_earnings from leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000301') = 1000
  and (select stars from m3_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000301') = 5
  and (select owned_count from accessory_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000301') = 3
  and (select mastered from recipe_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000301') = 2);

select k_as(301);
select k_chk('ẩn danh KHÔNG thêm được hàng — thu nhập', k_err($$insert into leaderboard_entries (user_id, nickname, lifetime_earnings) values ('00000000-0000-0000-0000-000000000301', 'A2', 1) on conflict (user_id) do update set lifetime_earnings = 1$$) like '%row-level security%');
select k_chk('ẩn danh KHÔNG thêm được — Trân Châu', k_err($$insert into m3_leaderboard_entries (user_id, nickname, stars, levels_cleared) values ('00000000-0000-0000-0000-000000000301', 'A2', 1, 1) on conflict (user_id) do update set stars = 1$$) like '%row-level security%');
select k_chk('ẩn danh KHÔNG thêm được — Sưu tập', k_err($$insert into accessory_leaderboard_entries (user_id, nickname, owned_count) values ('00000000-0000-0000-0000-000000000301', 'A2', 1) on conflict (user_id) do update set owned_count = 1$$) like '%row-level security%');
select k_chk('ẩn danh KHÔNG thêm được — Thợ pha chế', k_err($$insert into recipe_leaderboard_entries (user_id, nickname, mastered) values ('00000000-0000-0000-0000-000000000301', 'A2', 1) on conflict (user_id) do update set mastered = 1$$) like '%row-level security%');

select k_as(304);
select k_chk('ẩn danh mới KHÔNG chèn được hàng — thu nhập', k_err($$insert into leaderboard_entries (user_id, nickname, lifetime_earnings) values ('00000000-0000-0000-0000-000000000304', 'N', 1)$$) like '%row-level security%');
select k_chk('ẩn danh mới KHÔNG chèn được — Trân Châu', k_err($$insert into m3_leaderboard_entries (user_id, nickname, stars, levels_cleared) values ('00000000-0000-0000-0000-000000000304', 'N', 1, 1)$$) like '%row-level security%');
select k_chk('ẩn danh mới KHÔNG chèn được — Sưu tập', k_err($$insert into accessory_leaderboard_entries (user_id, nickname, owned_count) values ('00000000-0000-0000-0000-000000000304', 'N', 1)$$) like '%row-level security%');
select k_chk('ẩn danh mới KHÔNG chèn được — Thợ pha chế', k_err($$insert into recipe_leaderboard_entries (user_id, nickname, mastered) values ('00000000-0000-0000-0000-000000000304', 'N', 1)$$) like '%row-level security%');
select k_as(302);
insert into leaderboard_entries (user_id, nickname, lifetime_earnings) values ('00000000-0000-0000-0000-000000000302', 'Linked', 10);
insert into m3_leaderboard_entries (user_id, nickname, stars, levels_cleared) values ('00000000-0000-0000-0000-000000000302', 'Linked', 1, 2);
insert into accessory_leaderboard_entries (user_id, nickname, owned_count) values ('00000000-0000-0000-0000-000000000302', 'Linked', 1);
insert into recipe_leaderboard_entries (user_id, nickname, mastered) values ('00000000-0000-0000-0000-000000000302', 'Linked', 1);
update leaderboard_entries set lifetime_earnings = 20 where user_id = '00000000-0000-0000-0000-000000000302';
update m3_leaderboard_entries set stars = 4 where user_id = '00000000-0000-0000-0000-000000000302';
update accessory_leaderboard_entries set owned_count = 4 where user_id = '00000000-0000-0000-0000-000000000302';
update recipe_leaderboard_entries set mastered = 4 where user_id = '00000000-0000-0000-0000-000000000302';
select k_chk('đã liên kết: thêm + sửa hàng của mình ở cả 4 bảng',
  (select lifetime_earnings from leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000302') = 20
  and (select stars from m3_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000302') = 4
  and (select owned_count from accessory_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000302') = 4
  and (select mastered from recipe_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000302') = 4);
select k_chk('đã liên kết vẫn KHÔNG ghi hộ người khác', k_err($$insert into leaderboard_entries (user_id, nickname, lifetime_earnings) values ('00000000-0000-0000-0000-000000000301', 'Hijack', 1)$$) like '%row-level security%');
select k_as(0);
select k_chk('bảng vẫn đọc công khai cho anon', (select count(*) from leaderboard_entries) >= 2);
reset role;

-- ===== 2. Phá đảo Hồi 1-4: chỉ insert =====
select k_as(301);
select k_chk('ẩn danh KHÔNG nộp Phá đảo Hồi 1', k_err($$insert into story_speedrun_entries (user_id, nickname, complete_seconds) values ('00000000-0000-0000-0000-000000000301', 'Anon', 100)$$) like '%row-level security%');
select k_chk('ẩn danh KHÔNG nộp Phá đảo Hồi 2', k_err($$insert into story_speedrun2_entries (user_id, nickname, complete_seconds) values ('00000000-0000-0000-0000-000000000301', 'Anon', 100)$$) like '%row-level security%');
select k_chk('ẩn danh KHÔNG nộp Phá đảo Hồi 3', k_err($$insert into story_speedrun3_entries (user_id, nickname, complete_seconds) values ('00000000-0000-0000-0000-000000000301', 'Anon', 100)$$) like '%row-level security%');
select k_chk('ẩn danh KHÔNG nộp Phá đảo Hồi 4', k_err($$insert into story_speedrun4_entries (user_id, nickname, complete_seconds) values ('00000000-0000-0000-0000-000000000301', 'Anon', 100)$$) like '%row-level security%');
select k_as(302);
insert into story_speedrun_entries (user_id, nickname, complete_seconds) values ('00000000-0000-0000-0000-000000000302', 'Linked', 100);
insert into story_speedrun2_entries (user_id, nickname, complete_seconds) values ('00000000-0000-0000-0000-000000000302', 'Linked', 100);
insert into story_speedrun3_entries (user_id, nickname, complete_seconds) values ('00000000-0000-0000-0000-000000000302', 'Linked', 100);
insert into story_speedrun4_entries (user_id, nickname, complete_seconds) values ('00000000-0000-0000-0000-000000000302', 'Linked', 100);
select k_chk('đã liên kết nộp được Phá đảo cả 4 hồi', (select count(*) from story_speedrun_entries where user_id = '00000000-0000-0000-0000-000000000302') = 1
  and (select count(*) from story_speedrun4_entries where user_id = '00000000-0000-0000-0000-000000000302') = 1);
select k_chk('nộp lần hai vẫn bị chặn (1 lần/người)', k_err($$insert into story_speedrun_entries (user_id, nickname, complete_seconds) values ('00000000-0000-0000-0000-000000000302', 'Linked', 1)$$) like '%duplicate key%');
reset role;

-- ===== 3. RPC: VIP + Sự kiện =====
select k_as(301);
select k_chk('ẩn danh KHÔNG nộp VIP', k_err($$select submit_vip_exp('Anon', 600)$$) like '%email link required%');
select k_chk('ẩn danh KHÔNG nộp Sự kiện (chặn trước mọi kiểm tra khác)', k_err($$select event_leaderboard_submit('halloween', 'Anon', 1)$$) like '%email link required%');
select k_as(302);
select submit_vip_exp('Linked', 600);
select k_chk('đã liên kết nộp VIP được', (select vip_exp from vip_leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000302') = 600);
select k_chk('đã liên kết qua cổng Sự kiện (lỗi còn lại là lỗi nghiệp vụ, không phải email)',
  k_err($$select event_leaderboard_submit('khong_co_dip_nay', 'Linked', 1)$$) like '%unknown festival%');
reset role;

-- ===== 4. Thưởng hạng cũ leaderboard_claim_reward =====
update leaderboard_entries set lifetime_earnings = 1e9 where user_id = '00000000-0000-0000-0000-000000000301';
select k_as(301);
select k_chk('ẩn danh hạng 1 KHÔNG nhận thưởng bảng thu nhập', leaderboard_claim_reward() = 0);
select k_as(302);
reset role;
update leaderboard_entries set lifetime_earnings = 2e9 where user_id = '00000000-0000-0000-0000-000000000302';
select k_as(302);
select k_chk('đã liên kết hạng 1 nhận 100💎', leaderboard_claim_reward() = 100);
reset role;
select k_chk('ẩn danh không bị đánh dấu đã nhận', (select last_reward_claimed_at is null from leaderboard_entries where user_id = '00000000-0000-0000-0000-000000000301'));

select 'LINKED ENFORCE OK';
