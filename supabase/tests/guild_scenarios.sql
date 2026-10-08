-- Kịch bản test cho guild_schema.sql chạy trên Postgres THUẦN (không cần Supabase).
-- Chạy: scripts/test_guild_sql.sh  (dựng DB tạm, giả lập auth.users/auth.uid()).
-- Mọi assert sai → RAISE EXCEPTION → psql thoát lỗi (ON_ERROR_STOP).

create or replace function t_as(p_uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', coalesce(p_uid::text, ''), false);
  if p_uid is null then set role anon; else set role authenticated; end if;
end $$;

-- Chạy một câu lệnh và kỳ vọng nó ném lỗi chứa p_msg.
create or replace function t_err(p_sql text, p_msg text) returns void language plpgsql as $$
begin
  begin
    execute p_sql;
  exception when others then
    if position(p_msg in sqlerrm) = 0 then
      raise exception 'lỗi sai: muốn "%" nhưng nhận "%" (sql: %)', p_msg, sqlerrm, p_sql;
    end if;
    return;
  end;
  raise exception 'KỲ VỌNG lỗi "%" nhưng chạy thành công: %', p_msg, p_sql;
end $$;

create or replace function t_eq(p_label text, p_got anyelement, p_want anyelement)
returns void language plpgsql as $$
begin
  if p_got is distinct from p_want then
    raise exception '% : nhận % muốn %', p_label, p_got, p_want;
  end if;
end $$;

grant execute on function t_as(uuid), t_err(text,text), t_eq(text,anyelement,anyelement)
  to authenticated, anon;
grant select, update, insert, delete on all tables in schema public to authenticated;
-- (giống Supabase: authenticated có quyền bảng, RLS không policy → 0 hàng)

reset role;
insert into auth.users select ('00000000-0000-0000-0000-0000000000' || lpad(i::text, 2, '0'))::uuid
  from generate_series(1, 99) i on conflict do nothing;

create or replace function u(i int) returns uuid language sql immutable as
$$ select ('00000000-0000-0000-0000-0000000000' || lpad(i::text, 2, '0'))::uuid $$;
grant execute on function u(int) to authenticated, anon;

-- ===== 1. Tạo hội + validate ============================================
select t_as(u(1));
select guild_create('Boba Club', 'bb', '🧋', false, 'Alice', 0) as g1 \gset
select t_eq('chủ hội trong guild_my', (guild_my()->'guild'->>'name'), 'Boba Club');
select t_eq('tag viết hoa', (guild_my()->'guild'->>'tag'), 'BB');
select t_err($$select guild_create('Another', 'zz', '🧋', false, 'Alice', 0)$$, 'already in guild');
select t_as(u(2));
select t_err($$select guild_create('boba club', 'zz', '🧋', false, 'Bob', 0)$$, 'name taken');
select t_err($$select guild_create('Fuck Club', 'zz', '🧋', false, 'Bob', 0)$$, 'invalid name');
select t_err($$select guild_create('F u c k', 'zz', '🧋', false, 'Bob', 0)$$, 'invalid name');
select t_err($$select guild_create('Ok Name', 'a', '🧋', false, 'Bob', 0)$$, 'invalid name');
select t_err($$select guild_create('Ok Name', 'toolong', '🧋', false, 'Bob', 0)$$, 'invalid name');
select t_err($$select guild_create('ab', 'zz', '🧋', false, 'Bob', 0)$$, 'invalid name');
select t_err($$select guild_create('Admin Team', 'zz', '🧋', false, 'Bob', 0)$$, 'invalid name');
select t_err($$select guild_create('Fine Name', 'zz', '🧋', false, 'Cặc', 0)$$, 'invalid name');

-- ===== 2. Tham gia =======================================================
select guild_join(:'g1'::uuid, 'Bob', 0);
select t_err(format($$select guild_join(%L::uuid, 'Bob', 0)$$, :'g1'), 'already in guild');
select t_as(u(3));
select t_err($$select guild_join(gen_random_uuid(), 'Cy', 0)$$, 'not found');
select t_eq('chưa có hội → guild_my null', guild_my() is null, true);
select guild_join(:'g1'::uuid, 'Cy', 0);
select t_eq('Cy vào hội công khai', guild_my()->'guild'->>'name', 'Boba Club');
select t_eq('hội công khai có trong danh sách',
  (select count(*) from guild_list(50) where id = :'g1'::uuid), 1::bigint);
select guild_leave();
select t_eq('rời hội → guild_my null', guild_my() is null, true);

-- ===== 3. Giới hạn thành viên 30 =========================================
select t_as(u(5));
select guild_create('Full House', 'fh', '🏠', false, 'x', 0) as g3 \gset
reset role;
insert into guild_members (user_id, guild_id, nickname)
  select u(i), :'g3'::uuid, 'm' || i from generate_series(10, 38) i;  -- + chủ = 30
select t_eq('đủ 30', (select count(*) from guild_members where guild_id = :'g3'::uuid), 30::bigint);
select t_as(u(3));
select t_err(format($$select guild_join(%L::uuid, 'Cy', 0)$$, :'g3'), 'guild full');
select t_eq('hội đầy không còn trong danh sách công khai',
  (select count(*) from guild_list(50) where id = :'g3'::uuid), 0::bigint);
reset role;
delete from guild_members where guild_id = :'g3'::uuid and user_id <> u(5);
-- Có chỗ trống lại → vào được.
select t_as(u(3));
select guild_join(:'g3'::uuid, 'Cy', 0);
select guild_leave();

-- ===== 4. Điểm tuần ======================================================
select t_as(u(2));  -- Bob (đã trong g1)
select guild_submit_score(500);
select t_eq('tổng sau 500', (guild_my()->>'total')::bigint, 500::bigint);
select guild_submit_score(500);
select t_eq('nộp lại 500 không cộng đôi', (guild_my()->>'total')::bigint, 500::bigint);
select guild_submit_score(800);
select t_eq('800 → +300', (guild_my()->>'total')::bigint, 800::bigint);
select guild_submit_score(100);   -- save cũ / điểm giảm: không trừ
select t_eq('điểm giảm không trừ', (guild_my()->>'total')::bigint, 800::bigint);
select guild_submit_score(800);
select t_eq('sau giảm nộp lại 800 không cộng', (guild_my()->>'total')::bigint, 800::bigint);
select t_err($$select guild_submit_score(99999999)$$, 'score too high');
select t_err($$select guild_submit_score(-1)$$, 'invalid input');
select t_as(u(6));
select t_err($$select guild_submit_score(10)$$, 'not in guild');
-- Người vào giữa tuần KHÔNG mang điểm cũ: join với baseline 5000.
select guild_join(:'g1'::uuid, 'Eve', 5000);
select guild_submit_score(5000);
select t_eq('baseline 5000 → 0 điểm', (guild_my()->>'total')::bigint, 800::bigint);
select guild_submit_score(5300);
select t_eq('+300 sau baseline', (guild_my()->>'total')::bigint, 1100::bigint);
select t_eq('Eve đóng góp 300',
  (select (m->>'points')::bigint from jsonb_array_elements(guild_my()->'members') m
    where m->>'nickname' = 'Eve'), 300::bigint);

-- ===== 5. Sang tuần mới reset ============================================
reset role;
update guild_members set week = week - 7 where user_id = u(6);
select t_as(u(6));
select t_eq('tuần cũ không tính vào tổng', (guild_my()->>'total')::bigint, 800::bigint);
select guild_submit_score(5300);  -- last_score reset về 0 → tuần mới tính +5300? (xem ghi chú)
select t_eq('sang tuần: điểm tuần mới = toàn bộ điểm báo (client cũng reset)',
  (select (m->>'points')::bigint from jsonb_array_elements(guild_my()->'members') m
    where m->>'nickname' = 'Eve'), 5300::bigint);
reset role;
update guild_members set week_points = 300, last_score = 5300 where user_id = u(6);  -- trả lại

-- ===== 6. Nhận thưởng mốc ================================================
select t_as(u(2));
select t_err($$select guild_claim_reward(1)$$, 'milestone not reached');
select t_err($$select guild_claim_reward(9)$$, 'invalid milestone');
reset role;
update guild_members set week_points = 9300 where user_id = u(1);   -- tổng ≥ 10000
select t_as(u(2));
select guild_claim_reward(1);
select t_eq('claim ghi nhận', (guild_my()->'claimed')::text, '[1]');
select t_err($$select guild_claim_reward(1)$$, 'already claimed');
select t_err($$select guild_claim_reward(2)$$, 'milestone not reached');
-- Người ít đóng góp (<300) không được nhận.
select t_as(u(7));
select guild_join(:'g1'::uuid, 'Gus', 0);
select guild_submit_score(100);
select t_err($$select guild_claim_reward(1)$$, 'not enough contribution');
select t_as(u(1));
select guild_claim_reward(1);   -- chủ hội đóng góp 9300 → được

-- ===== 7. Kick ===========================================================
select t_as(u(7));
select t_err(format($$select guild_kick(%L::uuid)$$, u(2)), 'not owner');
select t_as(u(1));
select t_err(format($$select guild_kick(%L::uuid)$$, u(1)), 'cannot kick self');
select guild_kick(u(7));
select t_as(u(7));
select t_eq('bị kick → không còn hội', guild_my() is null, true);

-- ===== 8. Rời hội / chuyển chủ / xoá hội trống ===========================
select t_as(u(1));
select guild_leave();                              -- chủ rời
reset role;
select t_eq('chủ mới = người vào sớm nhất còn lại (Bob)',
  (select owner_id from guilds where id = :'g1'::uuid), u(2));
select t_as(u(2)); select guild_leave();
select t_as(u(6)); select guild_leave();
reset role;
select t_eq('hội trống bị xoá', (select count(*) from guilds where id = :'g1'::uuid), 0::bigint);

-- ===== 9. Báo cáo → ẩn ===================================================
select t_as(u(8));
select guild_create('Spam Guild', 'sp', '💣', false, 'Spammer', 0) as g4 \gset
select t_err(format($$select guild_report(%L::uuid, 'x')$$, :'g4'), 'cannot report own guild');
select t_as(u(9));  select guild_report(:'g4'::uuid, 'spam');
select guild_report(:'g4'::uuid, 'spam lần 2');   -- trùng người báo: bỏ qua
reset role;
select t_eq('1 người báo (kể cả trùng) → chưa ẩn',
  (select hidden from guilds where id = :'g4'::uuid), false);
select t_as(u(10)); select guild_report(:'g4'::uuid, 'spam');
select t_as(u(11)); select guild_report(:'g4'::uuid, 'spam');
reset role;
select t_eq('3 người báo → ẩn', (select hidden from guilds where id = :'g4'::uuid), true);
select t_as(u(12));
select t_eq('hội ẩn khỏi danh sách', (select count(*) from guild_list(50) where id = :'g4'::uuid), 0::bigint);
select t_err(format($$select guild_join(%L::uuid, 'Z', 0)$$, :'g4'), 'not found');
select t_err($$select guild_report(gen_random_uuid(), 'x')$$, 'not found');

-- ===== 10. BXH hội =======================================================
reset role;
select t_as(u(13)); select guild_create('Alpha', 'al', '🅰️', false, 'A', 0) as ga \gset
select t_as(u(14)); select guild_create('Beta', 'be', '🅱️', false, 'B', 0) as gb \gset
reset role;
update guild_members set week_points = 700 where user_id = u(13);
update guild_members set week_points = 900 where user_id = u(14);
select t_as(u(15));
select t_eq('BXH: Beta hạng 1', (select name from guild_leaderboard(10) where rank = 1), 'Beta');
select t_eq('BXH: Alpha hạng 2', (select name from guild_leaderboard(10) where rank = 2), 'Alpha');
select t_eq('hội 0 điểm / ẩn không lên BXH',
  (select count(*) from guild_leaderboard(100) where name = 'Spam Guild'), 0::bigint);
select t_eq('giới hạn limit', (select count(*) from guild_leaderboard(1)), 1::bigint);

-- ===== 11. Truy cập trái phép ============================================
select t_as(null);                                  -- chưa đăng nhập (anon)
select t_err($$select guild_my()$$, 'permission denied');
select t_err($$select guild_list(5)$$, 'permission denied');
select t_as(u(15));
select t_eq('không đọc thẳng bảng (RLS)', (select count(*) from guild_members), 0::bigint);
select t_err($$insert into guilds (name, tag, emoji, owner_id)
  values ('Hack', 'hk', 'x', gen_random_uuid())$$, 'row-level security');
do $$ declare n int; begin
  update guilds set hidden = false;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'RLS để client UPDATE trực tiếp % hàng', n; end if;
  delete from guild_members;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'RLS để client DELETE trực tiếp % hàng', n; end if;
end $$;
reset role;

-- ===== 12. Hội cần duyệt =================================================
reset role;
select t_as(u(70));
select guild_create('Private Club', 'pv', '🔒', true, 'Owner', 0) as gp \gset
select t_as(u(71));
select t_err(format($$select guild_join(%L::uuid, 'Req', 0)$$, :'gp'), 'approval required');
select t_err(format($$select guild_request_join(%L::uuid, 'F u c k', 0)$$, :'gp'), 'invalid name');
select guild_request_join(:'gp'::uuid, 'Req1', 4000);
select t_eq('danh sách thấy yêu cầu của mình',
  (select requested from guild_list(50) where id = :'gp'::uuid), true);
select t_eq('danh sách báo hội cần duyệt',
  (select requires_approval from guild_list(50) where id = :'gp'::uuid), true);
select t_eq('chưa phải thành viên', guild_my() is null, true);
select t_as(u(72));
select t_eq('người khác không thấy là đã yêu cầu',
  (select requested from guild_list(50) where id = :'gp'::uuid), false);
select t_err(format($$select guild_respond_request(%L::uuid, true)$$, u(71)), 'not owner');
-- Hội thường không dùng được đường xin duyệt.
select guild_create('Open Club', 'op', '🟢', false, 'OpenOwner', 0) as go \gset
select t_as(u(73));
select t_err(format($$select guild_request_join(%L::uuid, 'X', 0)$$, :'go'), 'no approval needed');
select t_err(format($$select guild_request_join(%L::uuid, 'X', 0)$$, gen_random_uuid()), 'not found');
-- Chủ hội thấy yêu cầu, thành viên thường thì không.
select t_as(u(70));
select t_eq('chủ hội thấy 1 yêu cầu', jsonb_array_length(guild_my()->'requests'), 1);
select t_eq('yêu cầu có đúng người xin',
  (guild_my()->'requests'->0->>'nickname'), 'Req1');
select t_err(format($$select guild_respond_request(%L::uuid, true)$$, u(99)), 'not found');
-- Từ chối: người xin không vào, yêu cầu biến mất, xin lại được.
select guild_respond_request(u(71), false);
select t_eq('từ chối → hết yêu cầu', jsonb_array_length(guild_my()->'requests'), 0);
select t_as(u(71)); select t_eq('vẫn chưa vào hội', guild_my() is null, true);
select guild_request_join(:'gp'::uuid, 'Req1', 4000);
-- Duyệt: vào hội, mang mốc điểm lúc xin (4000) nên chưa có điểm đóng góp.
select t_as(u(70));
select guild_respond_request(u(71), true);
select t_eq('duyệt → hết yêu cầu', jsonb_array_length(guild_my()->'requests'), 0);
select t_as(u(71));
select t_eq('đã là thành viên', guild_my()->'guild'->>'name', 'Private Club');
select guild_submit_score(4000);
select t_eq('mốc điểm lúc xin: không mang điểm cũ', (guild_my()->>'total')::bigint, 0::bigint);
-- Đang có yêu cầu chờ: chủ hội thấy, thành viên thường KHÔNG thấy.
select t_as(u(78));
select guild_request_join(:'gp'::uuid, 'Pending', 0);
select t_as(u(71));
select t_eq('thành viên thường không thấy yêu cầu (đang có 1 chờ)',
  jsonb_array_length(guild_my()->'requests'), 0);
select t_as(u(70));
select t_eq('chủ hội thấy yêu cầu đang chờ', jsonb_array_length(guild_my()->'requests'), 1);
select t_as(u(78));
select guild_cancel_request();
-- Hủy yêu cầu + gửi sang hội khác thì thay yêu cầu cũ.
select t_as(u(74));
select guild_request_join(:'gp'::uuid, 'Four', 0);
select guild_cancel_request();
select t_as(u(70));
select t_eq('hủy → chủ hội không còn thấy', jsonb_array_length(guild_my()->'requests'), 0);
select t_as(u(75));
select guild_create('Second Priv', 'sp', '🔐', true, 'O2', 0) as gp2 \gset
select t_as(u(74));
select guild_request_join(:'gp'::uuid, 'Four', 0);
select guild_request_join(:'gp2'::uuid, 'Four', 0);
reset role;
select t_eq('chỉ còn 1 yêu cầu đang chờ (thay thế)',
  (select count(*) from guild_join_requests where user_id = u(74)), 1::bigint);
select t_eq('yêu cầu chuyển sang hội mới',
  (select guild_id from guild_join_requests where user_id = u(74)), :'gp2'::uuid);
-- Vào/tạo hội thì yêu cầu tự xoá.
select t_as(u(74));
select guild_join(:'go'::uuid, 'Four', 0);
reset role;
select t_eq('vào hội khác → yêu cầu cũ bị xoá',
  (select count(*) from guild_join_requests where user_id = u(74)), 0::bigint);
-- Hội đầy: không duyệt thêm được, yêu cầu vẫn còn.
select t_as(u(76));
select guild_request_join(:'gp'::uuid, 'Late', 0);
reset role;
insert into guild_members (user_id, guild_id, nickname)
  select u(i), :'gp'::uuid, 'f' || i from generate_series(40, 67) i;  -- + 2 sẵn có = 30
select t_eq('hội đã 30 người',
  (select count(*) from guild_members where guild_id = :'gp'::uuid), 30::bigint);
select t_as(u(70));
select t_err(format($$select guild_respond_request(%L::uuid, true)$$, u(76)), 'guild full');
select t_eq('đầy: yêu cầu vẫn giữ', jsonb_array_length(guild_my()->'requests'), 1);
-- Giới hạn số yêu cầu chờ duyệt mỗi hội.
reset role;
delete from guild_members where guild_id = :'gp'::uuid and user_id between u(40) and u(67);
delete from guild_join_requests;
insert into guild_join_requests (user_id, guild_id, nickname)
  select u(i), :'gp'::uuid, 'r' || i from generate_series(40, 69) i;   -- 30 yêu cầu
select t_as(u(77));
select t_err(format($$select guild_request_join(%L::uuid, 'Over', 0)$$, :'gp'), 'too many requests');
-- Chặn truy cập trái phép.
select t_as(null);
select t_err($$select guild_cancel_request()$$, 'permission denied');
select t_err(format($$select guild_respond_request(%L::uuid, true)$$, u(1)), 'permission denied');
select t_as(u(77));
select t_eq('không đọc thẳng bảng yêu cầu', (select count(*) from guild_join_requests), 0::bigint);
reset role;

select 'ALL GUILD SQL SCENARIOS PASSED' as result;
