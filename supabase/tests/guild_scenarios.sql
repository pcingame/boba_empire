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

-- ===== 13. Lịch sử tuần, chuỗi, BXH trung bình/chuỗi =====================
reset role;
select t_as(u(80));
select guild_create('Streak Club', 'sk', '🔥', false, 'Boss', 0) as gs \gset
select guild_my()->>'week' as wk \gset
reset role;
-- Chưa có lịch sử, chưa đủ điểm → chuỗi 0.
select t_eq('chuỗi ban đầu = 0', guild_streak(:'gs'::uuid), 0);
-- Ba tuần liền trước đều đủ 3 mốc (≥ 120.000) → chuỗi 3 (tuần này chưa đạt).
insert into guild_week_totals (guild_id, week, total) values
  (:'gs'::uuid, :'wk'::date - 7, 130000), (:'gs'::uuid, :'wk'::date - 14, 120000),
  (:'gs'::uuid, :'wk'::date - 21, 999999);
select t_eq('3 tuần liền đạt → chuỗi 3', guild_streak(:'gs'::uuid), 3);
-- Tuần này đạt thêm → 4.
update guild_members set week_points = 125000 where user_id = u(80);
select t_eq('thêm tuần này đạt → 4', guild_streak(:'gs'::uuid), 4);
-- Đứt chuỗi ở tuần -14 (119.999 < 120.000): tuần này + tuần trước = 2.
update guild_week_totals set total = 119999 where guild_id = :'gs'::uuid and week = :'wk'::date - 14;
select t_eq('đứt ở tuần -14 → chuỗi 2', guild_streak(:'gs'::uuid), 2);
-- Tuần này chưa đạt nhưng tuần trước đạt → chuỗi tính từ tuần trước (1).
update guild_members set week_points = 100 where user_id = u(80);
select t_eq('tuần này chưa đạt, tuần trước đạt → 1', guild_streak(:'gs'::uuid), 1);
update guild_week_totals set total = 100 where guild_id = :'gs'::uuid and week = :'wk'::date - 7;
select t_eq('không tuần nào đạt → 0', guild_streak(:'gs'::uuid), 0);

-- Ghi lịch sử khi thành viên sang tuần mới.
update guild_week_totals set total = 0 where guild_id = :'gs'::uuid;
update guild_members set week = :'wk'::date - 7, week_points = 5000, last_score = 5000
  where user_id = u(80);
select t_as(u(80));
select guild_submit_score(5100);   -- sang tuần mới: điểm tuần cũ vào lịch sử
reset role;
select t_eq('lịch sử tuần cũ có 5000',
  (select total from guild_week_totals where guild_id = :'gs'::uuid and week = :'wk'::date - 7), 5000::bigint);
select t_eq('tổng tuần cũ = lịch sử', guild_total_of(:'gs'::uuid, :'wk'::date - 7), 5000::bigint);
select t_eq('hàng thành viên đã sang tuần mới', (select week from guild_members where user_id = u(80)), :'wk'::date);

-- Thành viên rời giữa tuần: điểm họ đóng góp vẫn tính cho hội (vào lịch sử).
select t_as(u(81)); select guild_join(:'gs'::uuid, 'Mem1', 0);
reset role;
update guild_members set week_points = 7000 where user_id = u(81);
select t_eq('trước khi rời: 5100 + 7000', guild_week_total(:'gs'::uuid), 12100::bigint);
select t_as(u(81)); select guild_leave();
reset role;
select t_eq('sau khi rời điểm vẫn tính', guild_week_total(:'gs'::uuid), 12100::bigint);
-- Bị kick cũng vậy.
select t_as(u(82)); select guild_join(:'gs'::uuid, 'Mem2', 0);
reset role;
update guild_members set week_points = 3000 where user_id = u(82);
select t_as(u(80)); select guild_kick(u(82));
reset role;
select t_eq('bị kick điểm vẫn tính', guild_week_total(:'gs'::uuid), 15100::bigint);

-- BXH trung bình/người: chỉ hội ≥ 5 người, xếp theo trung bình.
select t_as(u(83)); select guild_create('Big Avg', 'ba', '🅰️', false, 'B1', 0) as g_big \gset
select t_as(u(84)); select guild_create('Small Four', 'sf', '🅱️', false, 'S1', 0) as g_small \gset
select t_as(u(85)); select guild_create('Wide Five', 'wf', '🅾️', false, 'W1', 0) as g_wide \gset
reset role;
insert into guild_members (user_id, guild_id, nickname, week, week_points)
  select u(i), :'g_big'::uuid, 'b' || i, :'wk'::date, 0 from generate_series(86, 89) i;
insert into guild_members (user_id, guild_id, nickname, week, week_points)
  select u(i), :'g_wide'::uuid, 'w' || i, :'wk'::date, 0 from generate_series(90, 98) i;
insert into guild_members (user_id, guild_id, nickname, week, week_points)
  select u(i), :'g_small'::uuid, 's' || i, :'wk'::date, 0 from generate_series(99, 99) i;
update guild_members set week_points = 50000 where user_id = u(83);   -- Big Avg: 5 người, 50k → 10k/người
update guild_members set week_points = 90000 where user_id = u(85);   -- Wide: 10 người, 90k → 9k/người
update guild_members set week_points = 400000 where user_id = u(84);  -- Small: 2 người, 400k → bị loại (<5 người)
select t_as(u(70));
select t_eq('avg: Small Four (2 người) không lên bảng',
  (select count(*) from guild_leaderboard_avg(100) where name = 'Small Four'), 0::bigint);
select t_eq('avg: Big Avg hạng trên Wide Five',
  (select rank from guild_leaderboard_avg(100) where name = 'Big Avg')
  < (select rank from guild_leaderboard_avg(100) where name = 'Wide Five'), true);
select t_eq('avg: giá trị trung bình đúng',
  (select avg_points from guild_leaderboard_avg(100) where name = 'Big Avg'), 10000::bigint);
select t_eq('BXH tổng vẫn xếp theo tổng: Small (400k) trên Big (50k)',
  (select rank from guild_leaderboard(100) where name = 'Small Four')
  < (select rank from guild_leaderboard(100) where name = 'Big Avg'), true);
-- BXH chuỗi: chỉ hội có chuỗi > 0.
reset role;
insert into guild_week_totals (guild_id, week, total) values
  (:'g_big'::uuid, :'wk'::date - 7, 130000), (:'g_wide'::uuid, :'wk'::date - 7, 130000),
  (:'g_wide'::uuid, :'wk'::date - 14, 130000);
select t_as(u(70));
select t_eq('chuỗi: Wide (2 tuần) hạng 1', (select name from guild_leaderboard_streak(10) where rank = 1), 'Wide Five');
-- Small Four đã đạt đủ 3 mốc TUẦN NÀY (400k) → chuỗi 1; Big Avg chuỗi 1 (tuần trước) nhưng ít điểm hơn.
select t_eq('chuỗi hòa 1: tổng tuần cao hơn xếp trước (Small 400k)',
  (select name from guild_leaderboard_streak(10) where rank = 2), 'Small Four');
select t_eq('chuỗi: Big Avg hạng 3', (select name from guild_leaderboard_streak(10) where rank = 3), 'Big Avg');
select t_eq('chuỗi: hội chưa có chuỗi không lên bảng',
  (select count(*) from guild_leaderboard_streak(100) where name = 'Streak Club'), 0::bigint);
select t_eq('guild_my báo chuỗi', (select (guild_my()->>'streak')::int from (select t_as(u(90))) _), 2);

-- ===== 14. Xu Hội: nạp 💎, nhiệm vụ tuần, cửa hàng, buff =================
reset role;
select t_as(u(70));   -- chủ Private Club (đang trong hội)
select t_err($$select guild_donate(0)$$, 'invalid amount');
select t_err($$select guild_donate(-5)$$, 'invalid amount');
select t_err($$select guild_donate(1001)$$, 'invalid amount');
select guild_donate(600) as bal1 \gset
select t_eq('nạp 600 → 600 Xu', :'bal1'::bigint, 600::bigint);
select t_err($$select guild_donate(500)$$, 'daily limit');       -- 600 + 500 > 1000
select guild_donate(400) as bal2 \gset
select t_eq('nạp thêm 400 → 1000 Xu', :'bal2'::bigint, 1000::bigint);
select t_err($$select guild_donate(1)$$, 'daily limit');
select t_eq('guild_my báo đã nạp hôm nay', (guild_my()->>'donated_today')::int, 1000);
select t_eq('guild_my báo ví', (guild_my()->>'wallet')::bigint, 1000::bigint);
-- Chưa ở hội thì không nạp được.
select t_as(u(41)); select t_err($$select guild_donate(10)$$, 'not in guild');

-- Nhiệm vụ tuần theo điểm đóng góp cá nhân.
select t_as(u(70));
select t_err($$select guild_claim_quest(9)$$, 'invalid tier');
select t_err($$select guild_claim_quest(1)$$, 'not enough contribution');
reset role;
update guild_members set week = guild_current_week(), week_points = 5000 where user_id = u(70);
select t_as(u(70));
select guild_claim_quest(1) as q1 \gset
select t_eq('nhiệm vụ 1: +100 → 1100', :'q1'::bigint, 1100::bigint);
select t_err($$select guild_claim_quest(1)$$, 'already claimed');
select guild_claim_quest(2) as q2 \gset
select t_eq('nhiệm vụ 2: +200 → 1300', :'q2'::bigint, 1300::bigint);
select t_err($$select guild_claim_quest(3)$$, 'not enough contribution');
select t_eq('guild_my liệt kê nhiệm vụ đã nhận', (guild_my()->'quests_claimed')::text, '[1, 2]');
-- Điểm của TUẦN CŨ không dùng được.
reset role;
update guild_members set week = guild_current_week() - 7, week_points = 99999 where user_id = u(70);
select t_as(u(70));
select t_err($$select guild_claim_quest(3)$$, 'not enough contribution');
reset role;
update guild_members set week = guild_current_week(), week_points = 5000 where user_id = u(70);

-- Cửa hàng phụ kiện.
select t_as(u(70));
select t_err($$select guild_buy_item('nope')$$, 'invalid item');
select t_err($$select guild_buy_item('guild_dragon')$$, 'not enough coins');   -- 4000 > 1300
select guild_buy_item('guild_flag') as b1 \gset
select t_eq('mua cờ 500 → 800', :'b1'::bigint, 800::bigint);
select t_err($$select guild_buy_item('guild_flag')$$, 'already owned');
select t_eq('guild_my liệt kê món đã đổi', (guild_my()->'owned_items')::text, '["guild_flag"]');
select t_as(u(42)); select t_err($$select guild_buy_item('guild_flag')$$, 'not in guild');

-- Buff cả hội.
select t_as(u(70));
select guild_buy_buff() as bf1 \gset
select t_eq('buff 800 Xu → ví 0', :'bf1'::bigint, 0::bigint);
select t_eq('buff ~24h', ((guild_my()->>'buff_seconds')::int between 86300 and 86400), true);
select t_eq('guild_buff_seconds khớp', (guild_buff_seconds() between 86300 and 86400), true);
select t_err($$select guild_buy_buff()$$, 'not enough coins');
reset role;
update guild_coin_wallets set balance = 5000 where user_id = u(70);
select t_as(u(70));
select guild_buy_buff();
select t_eq('mua lần 2 → ~48h', ((guild_my()->>'buff_seconds')::int between 172700 and 172800), true);
select t_err($$select guild_buy_buff()$$, 'buff maxed');
-- Thành viên khác trong hội thấy buff; người ngoài hội thì không.
select t_as(u(71));
select t_eq('thành viên khác hưởng buff', (guild_buff_seconds() > 100000), true);
select t_as(u(41));
select t_eq('người không ở hội: buff 0', guild_buff_seconds(), 0);
-- Hết hạn → 0.
reset role;
update guilds set buff_until = now() - interval '1 minute' where id = :'gp'::uuid;
select t_as(u(70));
select t_eq('buff hết hạn → 0', guild_buff_seconds(), 0);
-- Ví giữ nguyên khi rời hội; rời rồi thì không mua được.
select guild_leave();
reset role;
select t_eq('rời hội: ví Xu Hội vẫn còn', (select balance from guild_coin_wallets where user_id = u(70)), 4200::bigint);
select t_as(u(70));
select t_err($$select guild_buy_item('guild_castle')$$, 'not in guild');
select t_err($$select guild_buy_buff()$$, 'not in guild');
select t_err($$select guild_donate(10)$$, 'not in guild');

-- ===== 15. Bảo mật mục mới ================================================
select t_as(u(70));
select t_err($$select guild_log_week(gen_random_uuid(), current_date, 999999)$$, 'permission denied');
select t_eq('không đọc thẳng ví', (select count(*) from guild_coin_wallets), 0::bigint);
select t_eq('không đọc thẳng lịch sử', (select count(*) from guild_week_totals), 0::bigint);
select t_eq('không đọc thẳng vật phẩm đã mua', (select count(*) from guild_purchases), 0::bigint);
select t_as(null);
select t_err($$select guild_donate(10)$$, 'permission denied');
select t_err($$select guild_buy_buff()$$, 'permission denied');
select t_err($$select guild_leaderboard_avg(5)$$, 'permission denied');
select t_err($$select guild_leaderboard_streak(5)$$, 'permission denied');
reset role;

-- ===== 16. Chat hội ======================================================
select t_as(u(60));
select guild_create('Chat Club', 'cc', '💬', false, 'Own', 0) as gc \gset
select t_as(u(61)); select guild_join(:'gc'::uuid, 'Mem', 0);
select guild_chat_post('  xin chào cả nhà  ');
select t_eq('tin đã cắt khoảng trắng', guild_chat_list(10)->'messages'->0->>'body', 'xin chào cả nhà');
select t_eq('tin mang tên thành viên', guild_chat_list(10)->'messages'->0->>'nickname', 'Mem');
select t_err($$select guild_chat_post('')$$, 'invalid input');
select t_err($$select guild_chat_post(repeat('a', 201))$$, 'invalid input');
select t_err($$select guild_chat_post('đồ f u c k')$$, 'text blocked');
-- Chống spam: 3 tin/10 giây (đã có 1 tin).
select guild_chat_post('2'); select guild_chat_post('3');
select t_err($$select guild_chat_post('4')$$, 'chat rate limited');
-- Người ngoài hội không đọc/ghi được.
select t_as(u(62));
select t_err($$select guild_chat_list(10)$$, 'not found');
select t_err($$select guild_chat_post('hi')$$, 'not found');
-- Xoá: không xoá được tin hội khác; thành viên chỉ xoá tin của mình, chủ xoá được mọi tin.
select t_as(u(61));
select (guild_chat_list(10)->'messages'->0->>'id')::bigint as mid \gset
select t_as(u(60));
select guild_chat_post('thông báo của chủ');
select (guild_chat_list(10)->'messages'->0->>'id')::bigint as oid \gset
select t_as(u(61));
select t_err(format($$select guild_chat_delete(%s)$$, :'oid'), 'not found');
select t_err(format($$select guild_chat_pin(%s)$$, :'oid'), 'not owner');
select guild_chat_delete(:'mid'::bigint);
select t_as(u(60));
select guild_chat_pin(:'oid'::bigint);
select t_eq('có tin ghim', guild_chat_list(10)->'pinned'->>'body', 'thông báo của chủ');
select t_eq('tin của thành viên đã xoá', jsonb_array_length(guild_chat_list(10)->'messages'), 3);
select guild_chat_pin(null);
select t_eq('bỏ ghim', guild_chat_list(10)->'pinned', 'null'::jsonb);
select guild_chat_delete(:'oid'::bigint);
-- Giới hạn 200 tin/hội.
reset role;
insert into guild_messages (guild_id, user_id, nickname, body, created_at)
  select :'gc'::uuid, u(61), 'Mem', 'm' || i, now() - interval '1 hour'
  from generate_series(1, 230) i;
select t_as(u(61)); select guild_chat_post('mới');
reset role;
select t_eq('giữ đúng 200 tin', (select count(*) from guild_messages where guild_id = :'gc'::uuid), 200::bigint);
-- Bảo mật: không đọc thẳng bảng, khách (anon) bị chặn.
select t_as(u(61));
select t_eq('không đọc thẳng tin nhắn', (select count(*) from guild_messages), 0::bigint);
select t_as(null);
select t_err($$select guild_chat_list(10)$$, 'permission denied');
select t_err($$select guild_chat_post('hi')$$, 'permission denied');
reset role;

-- ===== 17. Chat hội: ca biên =============================================
-- Hai hội riêng biệt: tin/ghim/xoá không xuyên hội.
select t_as(u(63)); select guild_create('Chat Two', 'c2', '🗨', false, 'Own2', 0) as gd \gset
select guild_chat_post('tin hội hai');
select (guild_chat_list(10)->'messages'->0->>'id')::bigint as did \gset
select t_as(u(60));
select t_err(format($$select guild_chat_pin(%s)$$, :'did'), 'not found');
select t_err(format($$select guild_chat_delete(%s)$$, :'did'), 'not found');
select t_eq('chủ hội này không thấy tin hội kia', (select count(*) from jsonb_array_elements(guild_chat_list(100)->'messages') m where m->>'body' = 'tin hội hai'), 0::bigint);
-- Biên nội dung: null, toàn khoảng trắng, đúng 200 ký tự, emoji tính theo ký tự.
select t_err($$select guild_chat_post(null)$$, 'invalid input');
select t_err($$select guild_chat_post(E'  \n\t ')$$, 'invalid input');
select t_err($$select guild_chat_post(E'\u200b\u200b')$$, 'invalid input');
select guild_chat_post(E'\n\t dòng giữa \n');
select t_eq('cắt cả xuống dòng/tab hai đầu', guild_chat_list(1)->'messages'->0->>'body', 'dòng giữa');
reset role; delete from guild_messages where user_id = u(60); select t_as(u(60));
reset role; delete from guild_messages where user_id = u(60); select t_as(u(60));
select guild_chat_post(repeat('a', 200));
reset role; delete from guild_messages where user_id = u(60); select t_as(u(60));
select guild_chat_post(repeat('🧋', 200));
reset role; delete from guild_messages where user_id = u(60); select t_as(u(60));
select t_err($$select guild_chat_post(repeat('🧋', 201))$$, 'invalid input');
-- p_limit: kẹp 1..100; null dùng mặc định.
reset role;
insert into guild_messages (guild_id, user_id, nickname, body, created_at)
  select :'gc'::uuid, u(61), 'Mem', 'k' || i, now() - interval '1 hour' from generate_series(1, 150) i;
select t_as(u(60));
select t_eq('limit 0 → 1', jsonb_array_length(guild_chat_list(0)->'messages'), 1);
select t_eq('limit 9999 → 100', jsonb_array_length(guild_chat_list(9999)->'messages'), 100);
select t_eq('limit null → 50', jsonb_array_length(guild_chat_list(null)->'messages'), 50);
select t_eq('mới nhất đứng đầu', (guild_chat_list(3)->'messages'->0->>'id')::bigint >= (guild_chat_list(3)->'messages'->1->>'id')::bigint, true);
-- Bị kick / rời hội → mất quyền đọc & ghi; tin cũ vẫn ở lại cho hội.
select t_as(u(60));
select guild_kick(u(61));
select t_as(u(61));
select t_err($$select guild_chat_list(10)$$, 'not found');
select t_err($$select guild_chat_post('còn nói được không')$$, 'not found');
select t_err($$select guild_chat_delete(1)$$, 'not found');
-- Xoá tin đang ghim → hết ghim, không lỗi.
select t_as(u(60));
select guild_chat_post('sẽ bị xoá') ;
select (guild_chat_list(1)->'messages'->0->>'id')::bigint as pid \gset
select guild_chat_pin(:'pid'::bigint);
select guild_chat_delete(:'pid'::bigint);
select t_eq('xoá tin ghim → pinned null', guild_chat_list(10)->'pinned', 'null'::jsonb);
-- Ghim tin không tồn tại: lỗi và KHÔNG làm mất ghim cũ? (giao dịch hoàn tác cả hàm).
select guild_chat_post('ghim thật');
select (guild_chat_list(1)->'messages'->0->>'id')::bigint as qid \gset
select guild_chat_pin(:'qid'::bigint);
select t_err($$select guild_chat_pin(999999999)$$, 'not found');
select t_eq('ghim cũ còn nguyên sau lần ghim lỗi', guild_chat_list(10)->'pinned'->>'body', 'ghim thật');
reset role;

-- ===== 18. Báo cáo tin nhắn ==============================================
-- Hội riêng: chủ u(64) + 3 thành viên u(65..67)? (67 đã dùng) → dùng u(64), u(65), u(66), u(68), u(69).
select t_as(u(64)); select guild_create('Report Club', 'rc', '🚨', false, 'RO', 0) as gr \gset
select t_as(u(65)); select guild_join(:'gr'::uuid, 'M1', 0);
select t_as(u(66)); select guild_join(:'gr'::uuid, 'M2', 0);
select t_as(u(68)); select guild_join(:'gr'::uuid, 'M3', 0);
select t_as(u(69)); select guild_join(:'gr'::uuid, 'Bad', 0);
select guild_chat_post('tin xấu');
select (guild_chat_list(1)->'messages'->0->>'id')::bigint as bid \gset
select t_err(format($$select guild_chat_report(%s)$$, :'bid'), 'invalid input');
select t_as(u(64));
select guild_chat_pin(:'bid'::bigint);
-- Người ngoài hội / tin không tồn tại.
select t_as(u(62));
select t_err(format($$select guild_chat_report(%s)$$, :'bid'), 'not found');
-- Thành viên của HỘI KHÁC (chủ Chat Two) cũng không báo cáo được tin hội này.
select t_as(u(63));
select t_err(format($$select guild_chat_report(%s)$$, :'bid'), 'not found');
select t_as(u(62));
select t_as(u(65));
select t_err($$select guild_chat_report(999999999)$$, 'not found');
-- Báo cáo lần 1: chỉ người báo cáo hết thấy; người khác vẫn thấy. Báo lại không cộng thêm.
select guild_chat_report(:'bid'::bigint);
select guild_chat_report(:'bid'::bigint);
select t_eq('người báo cáo không còn thấy tin', (select count(*) from jsonb_array_elements(guild_chat_list(50)->'messages') m where (m->>'id')::bigint = :'bid'::bigint), 0::bigint);
select t_eq('người báo cáo không thấy cả tin ghim', guild_chat_list(50)->'pinned', 'null'::jsonb);
select t_as(u(66));
select t_eq('người khác vẫn thấy (mới 1 báo cáo)', (select count(*) from jsonb_array_elements(guild_chat_list(50)->'messages') m where (m->>'id')::bigint = :'bid'::bigint), 1::bigint);
select t_eq('và vẫn thấy ghim', guild_chat_list(50)->'pinned'->>'body', 'tin xấu');
reset role;
select t_eq('báo lặp chỉ tính 1', (select count(*) from guild_message_reports where message_id = :'bid'::bigint), 1::bigint);
-- Báo cáo thứ 2, 3 → ẩn với cả hội và gỡ ghim.
select t_as(u(66)); select guild_chat_report(:'bid'::bigint);
select t_as(u(68));
select t_eq('2 báo cáo: chưa ẩn', (select count(*) from jsonb_array_elements(guild_chat_list(50)->'messages') m where (m->>'id')::bigint = :'bid'::bigint), 1::bigint);
select guild_chat_report(:'bid'::bigint);
select t_as(u(64));
select t_eq('3 báo cáo: ẩn với chủ hội', (select count(*) from jsonb_array_elements(guild_chat_list(50)->'messages') m where (m->>'id')::bigint = :'bid'::bigint), 0::bigint);
select t_eq('ẩn → gỡ ghim', guild_chat_list(50)->'pinned', 'null'::jsonb);
select t_err(format($$select guild_chat_pin(%s)$$, :'bid'), 'not found');
-- Bảo mật: không đọc thẳng bảng báo cáo; khách bị chặn.
select t_eq('không đọc thẳng báo cáo', (select count(*) from guild_message_reports), 0::bigint);
select t_as(null);
select t_err(format($$select guild_chat_report(%s)$$, :'bid'), 'permission denied');
reset role;

-- ===== 19. chat_latest trong guild_my (chấm "chưa đọc") ==================
-- Hội "Chat Two" (u(63) chủ): chưa có tin ẩn/báo cáo nào ngoài 1 tin đầu.
select t_as(u(63));
select t_eq('chat_latest = id tin mới nhất', (guild_my()->>'chat_latest')::bigint, (guild_chat_list(1)->'messages'->0->>'id')::bigint);
select guild_chat_post('tin mới hơn');
select t_eq('đăng thêm → chat_latest tăng', (guild_my()->>'chat_latest')::bigint, (guild_chat_list(1)->'messages'->0->>'id')::bigint);
-- Hội chưa có tin → 0.
select t_as(u(71)); select guild_leave();
select guild_create('Empty Chat', 'ec', '🫥', false, 'E', 0);
select t_eq('hội chưa có tin → 0', (guild_my()->>'chat_latest')::bigint, 0::bigint);
-- Tin mình đã báo cáo không tính (không báo "chưa đọc" vì tin mình không còn thấy).
select t_as(u(64));
select guild_chat_post('tin của chủ');
select (guild_chat_list(1)->'messages'->0->>'id')::bigint as lid \gset
select t_eq('chủ thấy chat_latest là tin vừa đăng', (guild_my()->>'chat_latest')::bigint, :'lid'::bigint);
select t_as(u(65));
select t_eq('thành viên cũng thấy', (guild_my()->>'chat_latest')::bigint, :'lid'::bigint);
select guild_chat_report(:'lid'::bigint);
select t_eq('đã báo cáo → chat_latest lùi về tin trước', (guild_my()->>'chat_latest')::bigint < :'lid'::bigint, true);
select t_as(u(66));
select t_eq('người khác chưa báo vẫn thấy tin đó', (guild_my()->>'chat_latest')::bigint, :'lid'::bigint);
reset role;

select 'ALL GUILD SQL SCENARIOS PASSED' as result;
