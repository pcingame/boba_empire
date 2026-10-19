-- Boss Thế Giới: sát thương theo phần tăng, trần báo cáo, máu tự cân theo tuần trước, mốc thưởng, nhận một lần, chặn ẩn danh/khách.
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
-- Boss tuần chỉ xuất hiện Chủ Nhật; để các kịch bản dưới chạy được mọi ngày, giả lập "đang mở từ đầu tuần" (kịch bản cuối thử đóng).
create or replace function wb_fight_open() returns boolean language sql stable as $$ select true $$;
create or replace function wb_fight_start(p_week date) returns timestamptz language sql immutable as $$ select p_week::timestamp at time zone 'utc' $$;
reset role;
insert into auth.users (id, is_anonymous) select uid_of(i), false from generate_series(1, 4) i;
insert into auth.users (id, is_anonymous) values (uid_of(9), true);
insert into leaderboard_entries (user_id, nickname, lifetime_earnings, stage) values (uid_of(1), 'An', 1, 1), (uid_of(2), 'Binh', 1, 1);

select as_u(1);
select world_boss_submit(1000, 3000, 10);   -- 1000 + 100 + 400 = 1500
select chk('sát thương = chạm + offline/30 + 40×công thức', (world_boss_state()->>'mine')::bigint = 1500);
select world_boss_submit(1000, 3000, 10);
select chk('báo lại cùng số không cộng thêm', (world_boss_state()->>'mine')::bigint = 1500);
select world_boss_submit(1500, 3000, 10);
select chk('chỉ phần tăng được tính (+500)', (world_boss_state()->>'mine')::bigint = 2000);
select world_boss_submit(100, 0, 0);
select chk('báo số nhỏ hơn không trừ', (world_boss_state()->>'mine')::bigint = 2000);
select chk('báo số ảo bị chặn', err_of('select world_boss_submit(999999999, 0, 0)') like '%score too high%');
select chk('số âm bị chặn', err_of('select world_boss_submit(-1, 0, 0)') like '%invalid input%');
select chk('máu tuần đầu = 150000', (world_boss_state()->>'hp')::bigint = 150000);
select chk('boss index trong 0..7', (world_boss_state()->>'boss')::int between 0 and 7);

select as_u(2); select world_boss_submit(500, 0, 0);
select chk('2 người: tổng 2500, 2 người chơi', (world_boss_state()->>'damage')::bigint = 2500 and (world_boss_state()->>'players')::int = 2);
select chk('bảng xếp hạng đúng thứ tự + tên', world_boss_state()->'board'->0->>'nickname' = 'An' and world_boss_state()->'board'->1->>'nickname' = 'Binh');
select chk('hạng của Binh = 2', (world_boss_state()->>'rank')::int = 2);

-- mốc thưởng
select chk('chưa phá mốc 1 → chưa nhận', err_of('select world_boss_claim(1)') like '%phase not reached%');
reset role;
insert into world_boss_hits (user_id, week, damage) values (uid_of(3), guild_current_week(), 30000);
select as_u(2);
select chk('tổng 32500 ≥ 20% (30000) → nhận mốc 1', world_boss_claim(1)->>'gems' = '50');
select chk('nhận lại bị chặn', err_of('select world_boss_claim(1)') like '%already claimed%');
select chk('mốc 2 chưa tới (40% = 60000)', err_of('select world_boss_claim(2)') like '%phase not reached%');
select chk('mốc lạ bị chặn', err_of('select world_boss_claim(6)') like '%invalid phase%');
select as_u(4);
select chk('chưa đánh gì không nhận được (dưới 100 sát thương)', err_of('select world_boss_claim(1)') like '%not enough damage%');
reset role;
update world_boss_hits set damage = 150000 where user_id = uid_of(3);
select as_u(2);
select chk('hạ boss: mốc 5 có rương', world_boss_claim(5)->>'chest' = 'true' and world_boss_claim(4)->>'gems' = '180');

-- máu tuần sau tự cân theo tuần trước (chạy bằng quyền cao nhất vì hàm nội bộ bị thu hồi)
reset role;
select chk('máu tuần sau = 1.1 × tổng tuần này (152500 → 167750)', wb_hp(guild_current_week() + 7) = 167750);
select chk('tuần không ai đánh → máu tuần kế về mức sàn 150000', wb_hp(guild_current_week() + 14) = 150000);
insert into world_boss_weeks (week, hp) values (guild_current_week() - 21, 200000);
insert into world_boss_hits (user_id, week, damage) values (uid_of(1), guild_current_week() - 21, 10000000);
select chk('trần tăng: tổng ảo 10M chỉ nâng tối đa 3× máu cũ ×1.1 = 660000', wb_hp(guild_current_week() - 14) = 660000);

-- khách / ẩn danh / đọc thẳng bảng
select as_u(0);
select chk('khách không gọi được', err_of('select world_boss_state()') like '%permission denied%');
select as_u(9);
select chk('ẩn danh bị chặn', err_of('select world_boss_state()') like '%email link required%');
select as_u(1);
select chk('không đọc thẳng bảng', err_of('select * from world_boss_hits') like '%permission denied%');
select chk('không gọi hàm nội bộ', err_of('select wb_hp(current_date)') like '%permission denied%');

-- Tự động đánh: mua một lần/tuần, sát thương tăng theo giờ tới hết tuần, vào tổng/xếp hạng/mốc, hiệu lực chặn gian lận
reset role;
insert into auth.users (id, is_anonymous) values (uid_of(5), false);
select as_u(5);
select chk('mua tự động đánh lần đầu = true', world_boss_buy_auto() = true);
select chk('mua lần hai cùng tuần = false (không trừ 💎 hai lần)', world_boss_buy_auto() = false);
select chk('state báo auto bật + tốc độ', (world_boss_state()->>'auto')::boolean and (world_boss_state()->>'auto_per_hour')::int = 25);
select chk('vừa mua chưa có sát thương', (world_boss_state()->>'mine')::bigint = 0);
reset role;
update world_boss_auto set since = now() - interval '10 hours' where user_id = uid_of(5);
select as_u(5);
select chk('10 giờ × 25 = 250 sát thương (offline, không cần mở app)', (world_boss_state()->>'mine')::bigint between 250 and 251);
select chk('có tên trên bảng dù chưa đánh tay', exists (select 1 from jsonb_array_elements(world_boss_state()->'board') b where (b->>'damage')::bigint between 250 and 251));
select chk('đủ 100 sát thương để nhận mốc', err_of('select world_boss_claim(1)') not like '%not enough damage%');
reset role;
update world_boss_auto set since = now() - interval '1000 days' where user_id = uid_of(5);
select chk('trần: không tích quá hết tuần (≤ 7×24×25 = 4200)', (select dmg from wb_damages(guild_current_week()) where user_id = uid_of(5)) <= 4200);
select as_u(0);
select chk('khách không mua được', err_of('select world_boss_buy_auto()') like '%permission denied%');
select as_u(9);
select chk('ẩn danh không mua được', err_of('select world_boss_buy_auto()') like '%email link required%');

-- Xem quảng cáo: +120 sát thương, 5 lần/ngày, cộng dồn với đánh tay
reset role;
insert into auth.users (id, is_anonymous) values (uid_of(6), false);
select as_u(6);
select chk('đầu ngày còn 5 lượt quảng cáo', (world_boss_state()->>'ad_left')::int = 5);
select chk('xem 1 quảng cáo → còn 4 lượt, +120 sát thương', world_boss_ad_strike() = 4 and (world_boss_state()->>'mine')::bigint = 120);
select world_boss_submit(100, 0, 0);
select chk('cộng dồn với đánh tay (120 + 100)', (world_boss_state()->>'mine')::bigint = 220);
select world_boss_ad_strike(); select world_boss_ad_strike(); select world_boss_ad_strike();
select chk('lượt thứ 5 → còn 0', world_boss_ad_strike() = 0 and (world_boss_state()->>'ad_left')::int = 0);
select chk('lượt thứ 6 bị chặn', err_of('select world_boss_ad_strike()') like '%ad limit%');
select chk('5 quảng cáo = 600 + 100 sát thương', (world_boss_state()->>'mine')::bigint = 700);
select as_u(0);
select chk('khách không xem được', err_of('select world_boss_ad_strike()') like '%permission denied%');
select as_u(9);
select chk('ẩn danh bị chặn', err_of('select world_boss_ad_strike()') like '%email link required%');

-- Boss NGÀY: cùng nguồn sát thương, máu/mốc riêng, nhận riêng
reset role;
insert into auth.users (id, is_anonymous) values (uid_of(7), false);
select as_u(7);
select chk('boss ngày có máu tối thiểu 20000', (world_boss_state()->'daily'->>'hp')::bigint = 20000);
select world_boss_submit(300, 0, 0);
select chk('đánh tay cộng cả boss tuần và boss ngày', (world_boss_state()->>'mine')::bigint = 300 and (world_boss_state()->'daily'->>'mine')::bigint = 300);
select world_boss_ad_strike();
select chk('quảng cáo cộng cả hai (+120)', (world_boss_state()->'daily'->>'mine')::bigint = 420 and (world_boss_state()->>'mine')::bigint = 420);
select chk('bảng boss ngày có tên', world_boss_state()->'daily'->'board'->0->>'nickname' is not null);
select chk('chưa phá mốc ngày → chưa nhận', err_of('select world_boss_day_claim(1)') like '%phase not reached%');
reset role;
insert into world_boss_day_hits (user_id, day, damage) values (uid_of(1), (now() at time zone 'utc')::date, 5000)
  on conflict (user_id, day) do update set damage = 5000;
select as_u(7);
select chk('tổng ngày ≥ 20% → nhận mốc 1 (0 💎)', world_boss_day_claim(1)->>'gems' = '0');
select chk('nhận lại bị chặn', err_of('select world_boss_day_claim(1)') like '%already claimed%');
select chk('mốc 2 chưa tới', err_of('select world_boss_day_claim(2)') like '%phase not reached%');
reset role;
update world_boss_day_hits set damage = 30000 where user_id = uid_of(1);
select as_u(7);
select chk('hạ boss ngày: mốc 5 = 10 💎', world_boss_day_claim(5)->>'gems' = '10');
select as_u(4);
select chk('chưa có sát thương ngày (<30) thì không nhận được dù mốc đã phá', err_of('select world_boss_day_claim(2)') like '%not enough damage%');
reset role;
select chk('tự động đánh chỉ tính phần rơi vào hôm nay (≤ 24 giờ × 25 = 600)',
  (select dmg from wb_day_damages((now() at time zone 'utc')::date) where user_id = uid_of(5)) <= 600);
select chk('máu boss ngày hôm sau theo hôm nay (1.1×)', wb_day_hp((now() at time zone 'utc')::date + 1) >= 20000);
select as_u(0);
select chk('khách không nhận boss ngày', err_of('select world_boss_day_claim(1)') like '%permission denied%');
-- Boss tuần ĐÓNG (không phải Chủ Nhật): đánh ngày thường chỉ đẩy mốc + tính cho boss ngày, không vào boss tuần.
reset role;
create or replace function wb_fight_open() returns boolean language sql stable as $$ select false $$;
insert into auth.users (id, is_anonymous) values (uid_of(8), false);
select as_u(8);
select world_boss_submit(400, 0, 0);
select chk('đóng: không cộng vào boss tuần', (world_boss_state()->>'mine')::bigint = 0 and (world_boss_state()->>'open')::boolean = false);
select chk('đóng: vẫn cộng vào boss ngày', (world_boss_state()->'daily'->>'mine')::bigint = 400);
select world_boss_ad_strike();
select chk('đóng: quảng cáo chỉ cộng boss ngày', (world_boss_state()->>'mine')::bigint = 0 and (world_boss_state()->'daily'->>'mine')::bigint = 520);
reset role;
create or replace function wb_fight_open() returns boolean language sql stable as $$ select true $$;
select as_u(8);
select world_boss_submit(400, 0, 0);
select chk('mở lại: phần đã báo lúc đóng KHÔNG dồn vào Chủ Nhật', (world_boss_state()->>'mine')::bigint = 0);
select world_boss_submit(500, 0, 0);
select chk('mở: chỉ phần tăng mới (+100) tính', (world_boss_state()->>'mine')::bigint = 100);
reset role;
create or replace function wb_fight_start(p_week date) returns timestamptz language sql immutable as $$ select (p_week + 6)::timestamp at time zone 'utc' $$;
select chk('cửa sổ thật = đúng Chủ Nhật: tuần cũ tự động đánh = 24×25 = 600',
  wb_auto_damage(now() - interval '1000 days', (guild_current_week() - 14)) = 600);
\echo WORLD BOSS OK
