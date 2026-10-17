-- Kịch bản test cho guild_dungeon_schema.sql (chạy qua scripts/test_dungeon_sql.sh).
create or replace function t_as(p_uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', coalesce(p_uid::text, ''), false);
  if p_uid is null then set role anon; else set role authenticated; end if;
end $$;
create or replace function t_err(p_sql text, p_msg text) returns void language plpgsql as $$
begin
  begin execute p_sql;
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
  if p_got is distinct from p_want then raise exception '% : nhận % muốn %', p_label, p_got, p_want; end if;
end $$;
grant execute on function t_as(uuid), t_err(text,text), t_eq(text,anyelement,anyelement) to authenticated, anon;
grant select, update, insert, delete on all tables in schema public to authenticated;

reset role;
insert into auth.users select ('00000000-0000-0000-0000-0000000000' || lpad(i::text, 2, '0'))::uuid
  from generate_series(1, 20) i on conflict do nothing;
create or replace function u(i int) returns uuid language sql immutable as
$$ select ('00000000-0000-0000-0000-0000000000' || lpad(i::text, 2, '0'))::uuid $$;
grant execute on function u(int) to authenticated, anon;

-- Hội 4 người (u1 chủ, u2..u4): ngưỡng ải 1 = 4 × (1500 chạm, 21600 giây, 25 điểm) = 6000 / 86400 / 100.
select t_as(u(1));
select guild_create('Dungeon Club', 'dc', '🧋', false, 'A', 0) as g \gset
select t_as(u(2)); select guild_join(:'g'::uuid, 'B', 0);
select t_as(u(3)); select guild_join(:'g'::uuid, 'C', 0);
select t_as(u(4)); select guild_join(:'g'::uuid, 'D', 0);
-- Cho các thành viên vào hội từ TRƯỚC đầu tuần (để tính từ 0) và cho tuần đã trôi 3 ngày: trần báo đủ lớn.
reset role;
update guild_members set joined_at = guild_current_week()::timestamp at time zone 'utc' - interval '1 day';

select t_as(u(1));
select t_eq('chưa có thanh nào', (guild_dungeon_state()->'bars'->>'tap')::int, 0);
select t_eq('ngưỡng ải 1 chạm', (guild_dungeon_state()->'targets'->0->>'tap')::int, 6000);
select t_eq('ngưỡng ải 1 offline', (guild_dungeon_state()->'targets'->0->>'off')::int, 86400);
select t_eq('ngưỡng ải 1 công thức', (guild_dungeon_state()->'targets'->0->>'rec')::int, 100);
select t_eq('ngưỡng ải 3 chạm = ×4', (guild_dungeon_state()->'targets'->2->>'tap')::int, 24000);
select t_eq('chưa qua ải nào', (guild_dungeon_state()->>'cleared')::int, 0);
select t_eq('không có vai', guild_dungeon_state()->>'role', null);

-- Vai trò: chọn tự do, đổi đúng 1 lần.
select t_err($$select guild_dungeon_set_role('xyz')$$, 'invalid role');
select guild_dungeon_set_role('tap');
select guild_dungeon_set_role('tap');                       -- trùng vai: không tính là đổi
select guild_dungeon_set_role('rec');                       -- đổi lần 1
select t_err($$select guild_dungeon_set_role('off')$$, 'role locked');
select t_eq('vai hiện tại', guild_dungeon_state()->>'role', 'rec');
select guild_dungeon_set_role('rec');                       -- giữ nguyên vẫn được
select t_as(u(57)); select t_err($$select guild_dungeon_set_role('tap')$$, 'not in guild');
select t_as(u(2)); select guild_dungeon_set_role('tap');
select t_as(u(3)); select guild_dungeon_set_role('off');

-- Báo điểm: chặn số sai / vượt trần theo giờ.
select t_as(u(1));
select t_err($$select guild_dungeon_submit(-1, 0, 0)$$, 'invalid input');
select t_err($$select guild_dungeon_submit(99999999, 0, 0)$$, 'score too high');
select t_err($$select guild_dungeon_submit(0, 99999999, 0)$$, 'score too high');
select t_err($$select guild_dungeon_submit(0, 0, 99999999)$$, 'score too high');
select t_as(u(57)); select t_err($$select guild_dungeon_submit(1, 1, 1)$$, 'not in guild');
select t_as(null); select t_err($$select guild_dungeon_submit(1, 1, 1)$$, 'permission denied');

-- Nhân vai ×1.5: u2 (vai chạm) 2000 chạm → 3000; offline 1000s (ngoài vai) → 1000.
-- (đầu tuần có thể mới vài giờ → đẩy mốc tuần lùi để trần không chặn)
reset role;
update guild_dungeon_members set week = week;  -- (no-op, bảng còn trống)
select t_as(u(2));
select guild_dungeon_submit(100, 100, 1);
select t_eq('chạm ×1.5', (guild_dungeon_state()->'mine'->>'tap')::int, 150);
select t_eq('offline ×1', (guild_dungeon_state()->'mine'->>'off')::int, 100);
select guild_dungeon_submit(100, 100, 1);                    -- gửi lại y nguyên: không cộng thêm
select t_eq('không cộng trùng', (guild_dungeon_state()->'mine'->>'tap')::int, 150);
select guild_dungeon_submit(50, 50, 0);                      -- số nhỏ hơn: không trừ
select t_eq('không giảm', (guild_dungeon_state()->'mine'->>'tap')::int, 150);
select guild_dungeon_submit(200, 100, 1);
select t_eq('phần tăng +100 chạm → +150', (guild_dungeon_state()->'mine'->>'tap')::int, 300);

-- Ải chỉ qua khi CẢ BA thanh đầy: đặt thẳng số liệu (tuần đã đủ lớn để bỏ qua trần báo).
reset role;
delete from guild_dungeon_members;
insert into guild_dungeon_members (user_id, guild_id, week, tap, off, rec) values
  (u(1), :'g'::uuid, guild_current_week(), 0, 0, 100),
  (u(2), :'g'::uuid, guild_current_week(), 6000, 0, 0),
  (u(3), :'g'::uuid, guild_current_week(), 0, 86399, 0);
select t_as(u(1));
select t_eq('thiếu 1 giây offline → chưa qua', (guild_dungeon_state()->>'cleared')::int, 0);
select t_err($$select guild_dungeon_claim(1)$$, 'stage not cleared');
reset role;
update guild_dungeon_members set off = 86400 where user_id = u(3);
select t_as(u(1));
select t_eq('đủ ba thanh → qua ải 1', (guild_dungeon_state()->>'cleared')::int, 1);
select t_err($$select guild_dungeon_claim(2)$$, 'stage not cleared');
select t_err($$select guild_dungeon_claim(0)$$, 'invalid tier');
select t_err($$select guild_dungeon_claim(4)$$, 'invalid tier');
-- Người không đóng góp (u4) không được nhận; người đóng góp nhận 1 lần, ví Xu Hội +100.
select t_as(u(4));
select t_err($$select guild_dungeon_claim(1)$$, 'not enough contribution');
select t_as(u(1));
select coalesce((guild_my()->>'wallet')::int, 0) as w1 \gset
select t_eq('thưởng ải 1: 0 💎', (guild_dungeon_claim(1)->>'gems')::int, 0);
select t_eq('ví +100', (guild_my()->>'wallet')::int, :w1 + 100);
select t_err($$select guild_dungeon_claim(1)$$, 'already claimed');
select t_eq('claimed [1]', guild_dungeon_state()->'claimed', '[1]'::jsonb);
-- Ải 3: 💎 + rương.
reset role;
update guild_dungeon_members set tap = 24000, off = 345600, rec = 400 where user_id = u(2);
select t_as(u(1));
select t_eq('qua cả 3 ải', (guild_dungeon_state()->>'cleared')::int, 3);
select t_eq('ải 3: 100 💎', (guild_dungeon_claim(3)->>'gems')::int, 100);
select t_eq('ải 3: có rương', (guild_dungeon_claim(2)->>'chest')::boolean, false);

-- Bảng đóng góp: đủ 4 người, người nhiều nhất đứng đầu.
select t_eq('bảng 4 người', jsonb_array_length(guild_dungeon_state()->'board'), 4);
select t_eq('đứng đầu là u2', guild_dungeon_state()->'board'->0->>'nickname', 'B');
-- Hàm nội bộ không gọi được từ client.
select t_err(format($$select guild_dungeon_target(%L::uuid, 'tap', 1)$$, :'g'), 'permission denied');
select t_err(format($$select guild_dungeon_cleared(%L::uuid, guild_current_week())$$, :'g'), 'permission denied');

-- Bậc Boss 2 → ngưỡng ×1.5.
reset role;
insert into guild_week_totals (guild_id, week, total) values
  (:'g'::uuid, guild_current_week() - 7, 130000), (:'g'::uuid, guild_current_week() - 14, 130000);
select t_as(u(1));
select t_eq('bậc 2 → ngưỡng ải 1 chạm ×1.5', (guild_dungeon_state()->'targets'->0->>'tap')::int, 9000);

-- Vào hội giữa tuần: mốc đầu là điểm xuất phát (không mang phần làm trước khi vào).
reset role;
update guild_members set joined_at = now() where user_id = u(4);
select t_as(u(4));
select guild_dungeon_submit(500, 500, 5);
select t_eq('lần báo đầu không tính', (guild_dungeon_state()->'mine'->>'tap')::int, 0);
select guild_dungeon_submit(600, 500, 5);
select t_eq('phần tăng sau đó tính', (guild_dungeon_state()->'mine'->>'tap')::int, 100);

select 'ALL DUNGEON SQL SCENARIOS PASSED' as result;
