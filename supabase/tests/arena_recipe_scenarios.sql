-- PK công thức (Đấu Trường, dạng 'recipe'): chấm điểm đơn, ghép trận, nộp đơn, chốt sớm/chống gian lận.
-- Chạy bằng scripts/test_arena_recipe_sql.sh (Postgres tạm, giả lập auth/anon/authenticated).
-- Vector chấm điểm (recipe 1: Hồng trà khô 10g, Nước nóng 200ml, Bột kem béo 30g, Sữa đặc 15ml, Đường nước 20ml)
-- PHẢI trùng test/core/arena_recipe_score_test.dart.
\set ON_ERROR_STOP on
insert into auth.users values ('00000000-0000-0000-0000-000000000001'), ('00000000-0000-0000-0000-000000000002'), ('00000000-0000-0000-0000-000000000003');
-- Supabase cấp sẵn quyền bảng cho authenticated (RLS mới là hàng rào); DB tạm không có nên cấp giống vậy.
grant all on arena_queue, arena_matches, arena_actions to authenticated;
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

-- Nộp đơn "như người thật": lùi đồng hồ trận/log 1 giờ rồi mới nộp (hàm chặn tốc độ ≥ 1 giây/nguyên liệu).
create function sub(u int, m uuid, i int, n text[], v real[]) returns int language plpgsql security definer as $$
begin
  perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000' || u, true);
  update arena_matches set started_at = started_at - interval '1 hour' where id = m;
  update arena_actions set at = at - interval '1 hour' where match_id = m;
  return arena_submit_order(m, i, n, v);
end $$;
grant execute on function sub(int, uuid, int, text[], real[]) to authenticated;

-- ── Vector chấm điểm ──
create function sc(n text[], v real[]) returns int language sql security definer as $$ select arena_recipe_order_score(1, n, v) $$;
grant execute on function sc(text[], real[]) to authenticated;
select as_u(1);
select chk('đúng hết → 100', sc(array['Hồng trà khô','Nước nóng','Bột kem béo','Sữa đặc','Đường nước'], array[10,200,30,15,20]) = 100);
select chk('một thứ lệch 1 mức (10g→12g) → 90', sc(array['Hồng trà khô','Nước nóng','Bột kem béo','Sữa đặc','Đường nước'], array[12,200,30,15,20]) = 90);
select chk('thiếu một thứ → 80', sc(array['Hồng trà khô','Nước nóng','Bột kem béo','Sữa đặc'], array[10,200,30,15]) = 80);
select chk('đúng hết + một thứ thừa → 90', sc(array['Hồng trà khô','Nước nóng','Bột kem béo','Sữa đặc','Đường nước','Matcha'], array[10,200,30,15,20,5]) = 90);
select chk('một thứ lệch xa (10g→20g) → 80', sc(array['Hồng trà khô','Nước nóng','Bột kem béo','Sữa đặc','Đường nước'], array[20,200,30,15,20]) = 80);
select chk('rỗng → 0', sc(array[]::text[], array[]::real[]) = 0);
select chk('nộp trùng tên: lấy lần cuối → 20', sc(array['Hồng trà khô','Hồng trà khô'], array[20,10]) = 20);
select chk('lệch 0.5 + đúng + thừa, còn lại thiếu → 20', sc(array['Hồng trà khô','Nước nóng','Matcha'], array[12,200,5]) = 20);
select chk('205ml gần 200ml hơn 220ml → đúng', sc(array['Nước nóng'], array[205]) = 20);
select chk('toàn thừa không xuống dưới 0', sc(array['Matcha','Sữa tươi'], array[5,100]) = 0);

-- ── Ghép trận ──
select as_u(1);
select (arena_join_queue('recipe')).id is null as waiting \gset
select chk('người đầu phải chờ', :'waiting');
select as_u(2);
select (arena_join_queue('recipe')).id as mid \gset
reset role;
select chk('trận dạng recipe', (select mode = 'recipe' from arena_matches where id = :'mid'));
select chk('5 món KHÁC nhau, đều thuộc bảng món', (select cardinality(seq) = 5 and (select count(distinct x) from unnest(seq) x) = 5
  and not exists (select 1 from unnest(seq) x where x not in (select id from arena_recipes)) from arena_matches where id = :'mid'));
select chk('thời gian ~180 giây', (select ends_at - started_at between interval '179 seconds' and interval '181 seconds' from arena_matches where id = :'mid'));

-- ── Nộp đơn ──
select as_u(1);
select as_u(3);
select chk('không phải thành viên', err_of(format($f$select arena_submit_order(%L::uuid, 0, array['x'], array[1]::real[])$f$, :'mid')) like '%not a participant%');
select as_u(1);
select chk('nộp tức thì sau khi ghép (script) bị chối', err_of(format($f$select arena_submit_order(%L::uuid, 0, array['Hồng trà khô','Nước nóng'], array[10,200]::real[])$f$, :'mid')) like '%too fast%');
select chk('idx ngoài 0..4', err_of(format($f$select arena_submit_order(%L::uuid, 5, array['x'], array[1]::real[])$f$, :'mid')) like '%invalid order index%');
select chk('mảng lệch độ dài', err_of(format($f$select arena_submit_order(%L::uuid, 0, array['x','y'], array[1]::real[])$f$, :'mid')) like '%invalid order items%');
reset role;
-- ép món của đơn 0 và 1 thành recipe 1 để đối chiếu điểm
update arena_matches set seq = array[1,1,1,1,1]::smallint[] where id = :'mid';
select as_u(1);
select chk('nộp đơn 0 đúng hết → 100', sub(1, :'mid', 0, array['Hồng trà khô','Nước nóng','Bột kem béo','Sữa đặc','Đường nước'], array[10,200,30,15,20]) = 100);
select chk('nộp lại đơn 0 bị chối', err_of(format($f$select arena_submit_order(%L::uuid, 0, array['x'], array[1]::real[])$f$, :'mid')) like '%order already served%');
select chk('đơn 1 thiếu một thứ → 80', sub(1, :'mid', 1, array['Hồng trà khô','Nước nóng','Bột kem béo','Sữa đặc'], array[10,200,30,15]) = 80);
select chk('arena_submit_action không nhận serve/tap trong dạng recipe', err_of(format($f$select arena_submit_action(%L::uuid, 'tap')$f$, :'mid')) like '%only valid in tap mode%');
select chk('chốt sớm khi chưa xong bị chối', err_of(format($f$select arena_resolve_match(%L::uuid)$f$, :'mid')) like '%not finished yet%');
select as_u(2);
select chk('đối thủ thấy log của người kia', (select count(*) from arena_actions where match_id = :'mid' and kind = 'serve') = 2);
select chk('đối thủ đơn 0 đúng hết', sub(2, :'mid', 0, array['Hồng trà khô','Nước nóng','Bột kem béo','Sữa đặc','Đường nước'], array[10,200,30,15,20]) = 100);
select chk('client không ghi trực tiếp arena_actions', err_of($q$insert into arena_actions (match_id, player_id, kind, cell, score) select id, player_a, 'serve', 4, 100 from arena_matches limit 1$q$) like '%permission denied%' or err_of($q$insert into arena_actions (match_id, player_id, kind, cell, score) select id, player_a, 'serve', 4, 100 from arena_matches limit 1$q$) like '%row-level security%');
-- cả hai nộp đủ 5 đơn
select sub(2, :'mid', i, array['Hồng trà khô'], array[10]::real[]) from generate_series(1,4) i;
select as_u(1);
select sub(1, :'mid', i, array['Hồng trà khô','Nước nóng','Bột kem béo','Sữa đặc','Đường nước'], array[10,200,30,15,20]::real[]) from generate_series(2,4) i;
select chk('chốt sớm khi cả hai đủ 5 đơn', (select status = 'finished' from arena_resolve_match(:'mid')));
reset role;
select chk('điểm: A = 100+80+300 = 480, B = 100+4×20 = 180', (select winner = '00000000-0000-0000-0000-000000000001' and (case when player_a = '00000000-0000-0000-0000-000000000001' then (score_a, score_b) else (score_b, score_a) end) = (480::numeric, 180::numeric) from arena_matches where id = :'mid'));
select as_u(2);
select chk('nộp sau khi chốt bị chối', err_of(format($f$select arena_submit_order(%L::uuid, 0, array['x'], array[1]::real[])$f$, :'mid')) like '%match not active%');

-- ── Hết giờ: chốt theo điểm hiện có ──
select as_u(1);
select (arena_join_queue('recipe')).id is null as w2 \gset
select as_u(2);
select (arena_join_queue('recipe')).id as mid2 \gset
reset role;
update arena_matches set seq = array[1,1,1,1,1]::smallint[] where id = :'mid2';
select as_u(1);
select sub(1, :'mid2', 0, array['Hồng trà khô','Nước nóng','Bột kem béo','Sữa đặc','Đường nước'], array[10,200,30,15,20]::real[]);
reset role;
update arena_matches set ends_at = now() - interval '1 second' where id = :'mid2';
select as_u(2);
select chk('quá giờ không nộp được', err_of(format($f$select arena_submit_order(%L::uuid, 0, array['x'], array[1]::real[])$f$, :'mid2')) like '%match time is up%');
select chk('chốt khi hết giờ: người đã nộp thắng, tổng 100', (select winner = '00000000-0000-0000-0000-000000000001' and score_a + score_b = 100 from arena_resolve_match(:'mid2')));

-- ── Hòa ──
select as_u(1);
select (arena_join_queue('recipe')).id is null as w3 \gset
select as_u(2);
select (arena_join_queue('recipe')).id as mid3 \gset
reset role;
update arena_matches set ends_at = now() - interval '1 second' where id = :'mid3';
select as_u(1);
select chk('không ai nộp → hòa 0–0, winner null', (select winner is null and score_a = 0 and score_b = 0 from arena_resolve_match(:'mid3')));

-- ── Dạng tap/match3 không bị ảnh hưởng ──
select as_u(1);
select (arena_join_queue('tap')).id is null as w4 \gset
select as_u(2);
select (arena_join_queue('tap')).id as mid4 \gset
select chk('dạng tap vẫn ghép được, 60 giây', (select mode = 'tap' and ends_at - started_at < interval '61 seconds' from arena_matches where id = :'mid4'));
select chk('serve trong dạng tap bị chối', err_of(format($f$select arena_submit_order(%L::uuid, 0, array['x'], array[1]::real[])$f$, :'mid4')) like '%only valid in recipe mode%');

select 'ARENA RECIPE OK';
