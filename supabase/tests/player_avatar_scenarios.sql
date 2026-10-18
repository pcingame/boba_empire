-- Avatar: cấp khoá, thay (trả khoá cũ), xoá, ẩn, chủ khoá, chặn ẩn danh/khách. Chạy bằng scripts/test_lb_rewards_sql.sh.
-- (Policy Storage không test được ở Postgres tạm — kiểm tay trên Supabase thật.)
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
select as_u(1);
select new_avatar_key()->>'key' as k1 \gset
select chk('đổi khoá lần hai trả khoá cũ = k1', (select new_avatar_key()->>'old') = :'k1');
select chk('tra theo tên (không phân biệt hoa thường) trả khoá hiện tại', player_avatar('a') <> '' and player_avatar('a') <> :'k1');
select chk('chủ khoá', avatar_key_owned(player_avatar('A') || '.jpg') and not avatar_key_owned(:'k1' || '.jpg') and not avatar_key_owned('x.jpg'));
select chk('khoá cũ xoá được (prev_key), khoá lạ thì không', avatar_key_deletable(:'k1' || '.jpg') and not avatar_key_deletable('x.jpg'));
select as_u(2);
select chk('người khác không là chủ khoá của u1', not avatar_key_owned(player_avatar('A') || '.jpg'));
select as_u(0);
select chk('khách tra được', player_avatar('A') <> '');
select chk('khách không cấp khoá được', err_of($$select new_avatar_key()$$) like '%permission denied%');
select as_u(7);
select chk('ẩn danh bị chặn', err_of($$select new_avatar_key()$$) like '%not linked%');
reset role;
update player_avatars set hidden = true where user_id = '00000000-0000-0000-0000-000000000001';
select chk('bị ẩn → rỗng', player_avatar('A') = '');
update player_avatars set hidden = false where user_id = '00000000-0000-0000-0000-000000000001';
select as_u(1);
select chk('xoá trả khoá cũ', clear_avatar() is not null);
select chk('xoá xong → rỗng', player_avatar('A') = '');
select as_u(2);
select chk('không đọc thẳng bảng', err_of($$select * from player_avatars$$) like '%permission denied%');
-- Báo cáo: u1 có ảnh; u2,u3,u4 báo cáo; u7 ẩn danh/khách bị chặn; tự báo cáo chặn; trùng không tính hai lần.
select as_u(1); select new_avatar_key();
select chk('tự báo cáo bị chặn', err_of($$select report_avatar('A')$$) like '%own avatar%');
select as_u(2);
select chk('báo cáo 1 → chưa ẩn', report_avatar('A') = false);
select chk('báo cáo lặp cùng người không tính thêm', report_avatar('a') = false);
select chk('tên không có ảnh → not found', err_of($$select report_avatar('Nobody')$$) like '%not found%');
select as_u(3);
select chk('báo cáo 2 → chưa ẩn', report_avatar('A') = false);
select chk('ảnh vẫn hiện', player_avatar('A') <> '');
select as_u(7);
select chk('ẩn danh không báo cáo được', err_of($$select report_avatar('A')$$) like '%not linked%');
select as_u(0);
select chk('khách không báo cáo được', err_of($$select report_avatar('A')$$) like '%permission denied%');
select as_u(4);
select chk('báo cáo 3 → ẩn', report_avatar('A') = true);
select chk('ảnh bị ẩn khỏi tra cứu công khai', player_avatar('A') = '');
select as_u(5);
select chk('ảnh đã ẩn: báo cáo thêm → not found', err_of($$select report_avatar('A')$$) like '%not found%');
select as_u(1);
select new_avatar_key();
select chk('đổi ảnh mới → hết ẩn, báo cáo cũ không tính', player_avatar('A') <> '');
select as_u(5);
select chk('ảnh mới cần đủ 3 báo cáo mới', report_avatar('A') = false);
select as_u(2);
select chk('không đọc thẳng bảng báo cáo', err_of($$select * from avatar_reports$$) like '%permission denied%');
\echo PLAYER AVATAR OK
