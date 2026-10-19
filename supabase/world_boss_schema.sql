-- Boss Thế Giới: mỗi tuần MỘT boss (chỉ xuất hiện Chủ Nhật UTC) cho cả server cùng đánh (thanh máu chung). Sát thương đổi từ bộ đếm tuần của app
-- (chạm / giây offline / điểm Công thức, cùng bộ đếm Phó bản). Thưởng theo 5 mốc cộng đồng (20/40/60/80/100% máu).
-- Máu tuần = max(225000, 1.1 × tổng sát thương tuần trước, nhưng không quá 3× máu tuần trước) → tự cân theo số người chơi.
-- Hằng số khớp lib/core/world_boss.dart (test so khớp); mọi con số là ước lượng chưa playtest.
-- Chạy SAU leaderboard_schema + guild_schema (dùng guild_current_week, tên từ leaderboard_entries). Idempotent.

create or replace function wb_base_hp() returns bigint language sql immutable as $$ select 225000::bigint $$;
-- 1 sát thương / lần chạm · 1 / 30 giây offline · 40 / điểm Công thức.
create or replace function wb_dmg_per_tap() returns integer language sql immutable as $$ select 1 $$;
create or replace function wb_off_seconds_per_dmg() returns integer language sql immutable as $$ select 30 $$;
create or replace function wb_dmg_per_rec() returns integer language sql immutable as $$ select 40 $$;
-- Trần báo cáo mỗi giờ trôi qua trong tuần (chặn báo số ảo; off không thể vượt thời gian đã trôi).
create or replace function wb_cap_tap_per_hour() returns bigint language sql immutable as $$ select 20000::bigint $$;
create or replace function wb_cap_off_per_hour() returns bigint language sql immutable as $$ select 3600::bigint $$;
create or replace function wb_cap_rec_per_hour() returns bigint language sql immutable as $$ select 400::bigint $$;
create or replace function wb_min_damage_to_claim() returns integer language sql immutable as $$ select 100 $$;
-- Tự động đánh (mua bằng 💎 ở app, hiệu lực tới hết tuần): server tự cộng sát thương theo thời gian, KHÔNG cần mở app.
create or replace function wb_auto_per_hour() returns integer language sql immutable as $$ select 25 $$;
-- Xem quảng cáo → +120 sát thương, tối đa 5 lần/ngày (UTC). Server không thấy được quảng cáo có xem thật không nên chỉ giới hạn theo ngày.
create or replace function wb_ad_damage() returns integer language sql immutable as $$ select 120 $$;
create or replace function wb_ad_per_day() returns integer language sql immutable as $$ select 10 $$;
-- Boss NGÀY (nhỏ, đổi mỗi ngày UTC): cùng nguồn sát thương với boss tuần (mỗi lần báo / xem quảng cáo / tự động đánh cộng cho cả hai).
-- Máu = max(30000, 1.1 × min(tổng ngày trước, 3 × máu ngày trước)). 5 mốc 20%; 💎 chỉ ở mốc cuối; Xu (giây thu nhập) do app cấp.
create or replace function wb_day_base_hp() returns bigint language sql immutable as $$ select 30000::bigint $$;
create or replace function wb_day_min_damage_to_claim() returns integer language sql immutable as $$ select 30 $$;
create or replace function wb_day_phase_gems(p_phase integer) returns integer
language sql immutable as $$ select case p_phase when 5 then 10 else 0 end $$;
-- Boss TUẦN chỉ xuất hiện vào CHỦ NHẬT (UTC): chỉ sát thương báo/xem QC/tự động đánh trong ngày đó mới tính cho nó (boss ngày thì
-- vẫn tính mọi ngày). Bù lại thưởng nhiều: 💎 ở đây + Xu (giây thu nhập, app cấp) + rương ở mốc cuối.
create or replace function wb_phase_gems(p_phase integer) returns integer
language sql immutable as $$ select case p_phase when 1 then 50 when 2 then 80 when 3 then 120 when 4 then 180 when 5 then 300 end $$;
-- Thời điểm boss tuần xuất hiện (0h UTC Chủ Nhật của tuần [p_week]) và boss có đang xuất hiện không.
create or replace function wb_fight_start(p_week date) returns timestamptz
language sql immutable as $$ select (p_week + 6)::timestamp at time zone 'utc' $$;
create or replace function wb_fight_open() returns boolean
language sql stable as $$ select now() >= wb_fight_start(guild_current_week()) $$;

create table if not exists world_boss_weeks (
  week date primary key,
  hp   bigint not null check (hp > 0)
);
alter table world_boss_weeks enable row level security;

create table if not exists world_boss_hits (
  user_id  uuid not null references auth.users(id) on delete cascade,
  week     date not null,
  last_tap bigint not null default 0 check (last_tap >= 0),
  last_off bigint not null default 0 check (last_off >= 0),
  last_rec bigint not null default 0 check (last_rec >= 0),
  damage   bigint not null default 0 check (damage >= 0),
  primary key (user_id, week)
);
create index if not exists world_boss_hits_week_idx on world_boss_hits (week, damage desc);
alter table world_boss_hits enable row level security;

create table if not exists world_boss_auto (
  user_id uuid not null references auth.users(id) on delete cascade,
  week    date not null,
  since   timestamptz not null default now(),
  primary key (user_id, week)
);
alter table world_boss_auto enable row level security;

create table if not exists world_boss_ads (
  user_id uuid not null references auth.users(id) on delete cascade,
  day     date not null,
  n       integer not null default 0 check (n >= 0),
  primary key (user_id, day)
);
alter table world_boss_ads enable row level security;

create table if not exists world_boss_days (
  day date primary key,
  hp  bigint not null check (hp > 0)
);
alter table world_boss_days enable row level security;

create table if not exists world_boss_day_hits (
  user_id uuid not null references auth.users(id) on delete cascade,
  day     date not null,
  damage  bigint not null default 0 check (damage >= 0),
  primary key (user_id, day)
);
create index if not exists world_boss_day_hits_day_idx on world_boss_day_hits (day, damage desc);
alter table world_boss_day_hits enable row level security;

create table if not exists world_boss_day_claims (
  user_id uuid not null references auth.users(id) on delete cascade,
  day     date not null,
  phase   integer not null check (phase between 1 and 5),
  primary key (user_id, day, phase)
);
alter table world_boss_day_claims enable row level security;

create table if not exists world_boss_claims (
  user_id uuid not null references auth.users(id) on delete cascade,
  week    date not null,
  phase   integer not null check (phase between 1 and 5),
  primary key (user_id, week, phase)
);
alter table world_boss_claims enable row level security;
-- Không policy nào: mọi truy cập qua RPC security definer.

-- Sát thương tự động của một lượt mua: từ lúc mua (hoặc lúc boss xuất hiện) tới hết tuần (hoặc bây giờ), × tốc độ mỗi giờ.
create or replace function wb_auto_damage(p_since timestamptz, p_week date) returns bigint
language sql stable strict as $$
  select floor(greatest(extract(epoch from (least(now(), ((p_week + 7)::timestamp at time zone 'utc'))
                                              - greatest(p_since, wb_fight_start(p_week)))), 0)
               / 3600.0 * wb_auto_per_hour())::bigint
$$;

-- Sát thương của mọi người trong tuần = đánh tay (hits) + tự động (auto).
create or replace function wb_damages(p_week date) returns table (user_id uuid, dmg bigint)
language sql stable security definer set search_path = public as $$
  select coalesce(h.user_id, a.user_id),
         coalesce(h.damage, 0) + coalesce(wb_auto_damage(a.since, p_week), 0)
    from (select * from world_boss_hits where week = p_week) h
    full join (select * from world_boss_auto where week = p_week) a on a.user_id = h.user_id
$$;

create or replace function wb_total(p_week date) returns bigint
language sql stable security definer set search_path = public as $$
  select coalesce(sum(dmg), 0)::bigint from wb_damages(p_week)
$$;

-- Máu của tuần [p_week]: tạo lần đầu có người hỏi, rồi cố định.
create or replace function wb_hp(p_week date) returns bigint
language plpgsql security definer set search_path = public as $$
declare v bigint; v_prev_hp bigint; v_prev_total bigint;
begin
  select hp into v from world_boss_weeks where week = p_week;
  if found then return v; end if;
  select hp into v_prev_hp from world_boss_weeks where week = p_week - 7;
  v_prev_total := wb_total(p_week - 7);
  v := wb_base_hp();
  if v_prev_hp is not null then
    v := greatest(v, ceil(least(v_prev_total, v_prev_hp * 3) * 1.1)::bigint);
  end if;
  insert into world_boss_weeks (week, hp) values (p_week, v) on conflict (week) do nothing;
  select hp into v from world_boss_weeks where week = p_week;
  return v;
end;
$$;

-- Tự động đánh trong khoảng [p_start, p_end) của một lượt mua (cho boss ngày).
create or replace function wb_auto_damage_range(p_since timestamptz, p_start timestamptz, p_end timestamptz) returns bigint
language sql stable strict as $$
  select floor(greatest(extract(epoch from (least(now(), p_end) - greatest(p_since, p_start))), 0)
               / 3600.0 * wb_auto_per_hour())::bigint
$$;

create or replace function wb_day_start(p_day date) returns timestamptz
language sql immutable as $$ select p_day::timestamp at time zone 'utc' $$;

-- Sát thương của mọi người trong NGÀY = đánh tay/quảng cáo (day_hits) + tự động đánh rơi vào ngày đó.
create or replace function wb_day_damages(p_day date) returns table (user_id uuid, dmg bigint)
language sql stable security definer set search_path = public as $$
  select coalesce(h.user_id, a.user_id),
         coalesce(h.damage, 0) + coalesce(wb_auto_damage_range(a.since, wb_day_start(p_day), wb_day_start(p_day + 1)), 0)
    from (select * from world_boss_day_hits where day = p_day) h
    full join (select * from world_boss_auto where week = date_trunc('week', p_day::timestamp)::date) a on a.user_id = h.user_id
$$;

create or replace function wb_day_total(p_day date) returns bigint
language sql stable security definer set search_path = public as $$
  select coalesce(sum(dmg), 0)::bigint from wb_day_damages(p_day)
$$;

create or replace function wb_day_hp(p_day date) returns bigint
language plpgsql security definer set search_path = public as $$
declare v bigint; v_prev_hp bigint; v_prev_total bigint;
begin
  select hp into v from world_boss_days where day = p_day;
  if found then return v; end if;
  select hp into v_prev_hp from world_boss_days where day = p_day - 1;
  v_prev_total := wb_day_total(p_day - 1);
  v := wb_day_base_hp();
  if v_prev_hp is not null then
    v := greatest(v, ceil(least(v_prev_total, v_prev_hp * 3) * 1.1)::bigint);
  end if;
  insert into world_boss_days (day, hp) values (p_day, v) on conflict (day) do nothing;
  select hp into v from world_boss_days where day = p_day;
  return v;
end;
$$;

-- Cộng [p_dmg] vào boss ngày hôm nay của [p_uid].
create or replace function wb_day_add(p_uid uuid, p_dmg bigint) returns void
language plpgsql security definer set search_path = public as $$
declare v_day date := (now() at time zone 'utc')::date;
begin
  perform wb_day_hp(v_day);
  insert into world_boss_day_hits (user_id, day, damage) values (p_uid, v_day, greatest(p_dmg, 0))
  on conflict (user_id, day) do update set damage = world_boss_day_hits.damage + greatest(p_dmg, 0);
end;
$$;

create or replace function wb_nick(p_uid uuid) returns text
language sql stable security definer set search_path = public as $$
  select coalesce((select nickname from leaderboard_entries where user_id = p_uid), '???')
$$;

create or replace function wb_require_linked() returns uuid
language plpgsql stable security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from auth.users where id = v_uid and is_anonymous) then raise exception 'email link required'; end if;
  return v_uid;
end;
$$;

-- Báo tổng luỹ kế TRONG TUẦN của máy này; chỉ phần TĂNG so với lần báo trước mới thành sát thương.
create or replace function world_boss_submit(p_tap bigint, p_off bigint, p_rec bigint) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := wb_require_linked();
  v_week date := guild_current_week();
  v_hours numeric;
  v_h world_boss_hits%rowtype;
  v_dmg bigint;
begin
  if p_tap is null or p_off is null or p_rec is null or p_tap < 0 or p_off < 0 or p_rec < 0 then
    raise exception 'invalid input';
  end if;
  v_hours := greatest(extract(epoch from (now() - (v_week::timestamp at time zone 'utc'))) / 3600.0, 1);
  if p_tap > ceil(v_hours * wb_cap_tap_per_hour()) or p_off > ceil(v_hours * wb_cap_off_per_hour())
     or p_rec > ceil(v_hours * wb_cap_rec_per_hour()) then
    raise exception 'score too high';
  end if;
  perform wb_hp(v_week);
  insert into world_boss_hits (user_id, week) values (v_uid, v_week) on conflict do nothing;
  select * into v_h from world_boss_hits where user_id = v_uid and week = v_week for update;
  v_dmg := greatest(p_tap - v_h.last_tap, 0) * wb_dmg_per_tap()
         + (greatest(p_off - v_h.last_off, 0) / wb_off_seconds_per_dmg())
         + greatest(p_rec - v_h.last_rec, 0) * wb_dmg_per_rec();
  update world_boss_hits
     set last_tap = greatest(last_tap, p_tap), last_off = greatest(last_off, p_off),
         last_rec = greatest(last_rec, p_rec), damage = damage + case when wb_fight_open() then v_dmg else 0 end
   where user_id = v_uid and week = v_week;
  perform wb_day_add(v_uid, v_dmg);
end;
$$;

-- Trạng thái boss ngày (nhúng trong world_boss_state).
create or replace function wb_day_state(p_uid uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_day date := (now() at time zone 'utc')::date;
  v_hp bigint := wb_day_hp(v_day);
  v_mine bigint := coalesce((select dmg from wb_day_damages(v_day) where user_id = p_uid), 0);
begin
  return jsonb_build_object(
    'boss', 0,
    'hp', v_hp,
    'damage', wb_day_total(v_day),
    'mine', v_mine,
    'rank', case when v_mine > 0 then (select count(*) + 1 from wb_day_damages(v_day) where dmg > v_mine) end,
    'players', (select count(*) from wb_day_damages(v_day) where dmg > 0),
    'ends_at', extract(epoch from wb_day_start(v_day + 1))::bigint,
    'claimed', coalesce((select jsonb_agg(phase order by phase) from world_boss_day_claims where user_id = p_uid and day = v_day), '[]'::jsonb),
    'board', coalesce((
      select jsonb_agg(jsonb_build_object('nickname', wb_nick(t.user_id), 'damage', t.dmg) order by t.dmg desc, t.user_id)
        from (select user_id, dmg from wb_day_damages(v_day) where dmg > 0 order by dmg desc, user_id limit 20) t), '[]'::jsonb));
end;
$$;

create or replace function world_boss_state() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := wb_require_linked();
  v_week date := guild_current_week();
  v_hp bigint := wb_hp(v_week);
  v_total bigint := wb_total(v_week);
  v_mine bigint := coalesce((select dmg from wb_damages(v_week) where user_id = v_uid), 0);
begin
  return jsonb_build_object(
    'boss', (((v_week - date '2024-01-01') / 7) % 8),
    'hp', v_hp,
    'damage', v_total,
    'mine', v_mine,
    'rank', case when v_mine > 0 then
      (select count(*) + 1 from wb_damages(v_week) where dmg > v_mine) end,
    'players', (select count(*) from wb_damages(v_week) where dmg > 0),
    'auto', exists (select 1 from world_boss_auto where user_id = v_uid and week = v_week),
    'auto_per_hour', wb_auto_per_hour(),
    'daily', wb_day_state(v_uid),
    'open', wb_fight_open(),
    'starts_at', extract(epoch from wb_fight_start(v_week))::bigint,
    'ad_left', greatest(wb_ad_per_day() - coalesce((select n from world_boss_ads where user_id = v_uid and day = (now() at time zone 'utc')::date), 0), 0),
    'ends_at', extract(epoch from ((v_week + 7)::timestamp at time zone 'utc'))::bigint,
    'claimed', coalesce((select jsonb_agg(phase order by phase) from world_boss_claims
                          where user_id = v_uid and week = v_week), '[]'::jsonb),
    'board', coalesce((
      select jsonb_agg(jsonb_build_object('nickname', wb_nick(t.user_id), 'damage', t.dmg) order by t.dmg desc, t.user_id)
        from (select user_id, dmg from wb_damages(v_week) where dmg > 0
               order by dmg desc, user_id limit 20) t), '[]'::jsonb));
end;
$$;

-- Nhận thưởng mốc [p_phase] (1..5): mốc phải đã phá (tổng ≥ p_phase × 20% máu) và bạn có ≥ 100 sát thương.
-- 💎 + rương (mốc 5) do app cấp SAU khi server xác nhận.
create or replace function world_boss_claim(p_phase integer) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := wb_require_linked();
  v_week date := guild_current_week();
  v_hp bigint := wb_hp(v_week);
  v_mine bigint;
begin
  if p_phase is null or p_phase < 1 or p_phase > 5 then raise exception 'invalid phase'; end if;
  if wb_total(v_week) * 5 < v_hp * p_phase then raise exception 'phase not reached'; end if;
  select dmg into v_mine from wb_damages(v_week) where user_id = v_uid;
  if coalesce(v_mine, 0) < wb_min_damage_to_claim() then raise exception 'not enough damage'; end if;
  begin
    insert into world_boss_claims (user_id, week, phase) values (v_uid, v_week, p_phase);
  exception when unique_violation then
    raise exception 'already claimed';
  end;
  return jsonb_build_object('gems', wb_phase_gems(p_phase), 'chest', p_phase = 5);
end;
$$;

-- Nhận thưởng mốc [p_phase] của boss NGÀY: mốc đã phá + bạn có ≥ 30 sát thương. Xu do app cấp; 💎 chỉ mốc 5.
create or replace function world_boss_day_claim(p_phase integer) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := wb_require_linked();
  v_day date := (now() at time zone 'utc')::date;
  v_hp bigint := wb_day_hp(v_day);
  v_mine bigint;
begin
  if p_phase is null or p_phase < 1 or p_phase > 5 then raise exception 'invalid phase'; end if;
  if wb_day_total(v_day) * 5 < v_hp * p_phase then raise exception 'phase not reached'; end if;
  select dmg into v_mine from wb_day_damages(v_day) where user_id = v_uid;
  if coalesce(v_mine, 0) < wb_day_min_damage_to_claim() then raise exception 'not enough damage'; end if;
  begin
    insert into world_boss_day_claims (user_id, day, phase) values (v_uid, v_day, p_phase);
  exception when unique_violation then
    raise exception 'already claimed';
  end;
  return jsonb_build_object('gems', wb_day_phase_gems(p_phase));
end;
$$;

-- Bật Tự động đánh cho tuần này (idempotent: đã bật thì không làm gì, trả false). Ai bật cũng được: 💎 trừ ở app SAU khi
-- server trả true (điểm yếu đã biết: server không thấy ví 💎 — hậu quả chỉ là tự động đánh miễn phí, tốc độ thấp).
create or replace function world_boss_buy_auto() returns boolean
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := wb_require_linked(); v_week date := guild_current_week(); n integer;
begin
  perform wb_hp(v_week);
  insert into world_boss_auto (user_id, week) values (v_uid, v_week) on conflict do nothing;
  get diagnostics n = row_count;
  return n > 0;
end;
$$;

-- Một lần xem quảng cáo xong: cộng sát thương cố định, tối đa wb_ad_per_day() lần/ngày. Trả số lượt còn lại hôm nay.
create or replace function world_boss_ad_strike() returns integer
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := wb_require_linked(); v_week date := guild_current_week(); v_day date := (now() at time zone 'utc')::date; v_n integer;
begin
  perform wb_hp(v_week);
  insert into world_boss_ads (user_id, day) values (v_uid, v_day) on conflict do nothing;
  update world_boss_ads set n = n + 1 where user_id = v_uid and day = v_day and n < wb_ad_per_day() returning n into v_n;
  if v_n is null then raise exception 'ad limit'; end if;
  if wb_fight_open() then
    insert into world_boss_hits (user_id, week, damage) values (v_uid, v_week, wb_ad_damage())
    on conflict (user_id, week) do update set damage = world_boss_hits.damage + wb_ad_damage();
  end if;
  perform wb_day_add(v_uid, wb_ad_damage());
  return wb_ad_per_day() - v_n;
end;
$$;

revoke all on function wb_total(date), wb_hp(date), wb_nick(uuid), wb_require_linked(), wb_damages(date), wb_auto_damage(timestamptz, date),
  wb_auto_damage_range(timestamptz, timestamptz, timestamptz), wb_day_start(date), wb_day_damages(date), wb_day_total(date), wb_day_hp(date),
  wb_day_add(uuid, bigint), wb_day_state(uuid), wb_fight_start(date), wb_fight_open() from public, anon, authenticated;
revoke all on function world_boss_submit(bigint, bigint, bigint), world_boss_state(), world_boss_claim(integer), world_boss_buy_auto(), world_boss_ad_strike(), world_boss_day_claim(integer) from public, anon;
grant execute on function world_boss_submit(bigint, bigint, bigint), world_boss_state(), world_boss_claim(integer), world_boss_buy_auto(), world_boss_ad_strike(), world_boss_day_claim(integer) to authenticated;
