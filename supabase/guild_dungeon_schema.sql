-- Phó bản Hội hàng tuần: cả hội phối hợp theo VAI TRÒ (không PvP). Chạy SAU guild_schema.sql.
-- Xem PROPOSAL_GUILD_DUNGEON.md. Hằng số khớp lib/core/guild_dungeon.dart (test so khớp);
-- mọi con số là ước lượng chưa playtest.
--
-- 3 thanh cộng dồn trong tuần: tap (lần chạm) · off (giây offline) · rec (điểm Công thức/Pha theo đơn/
-- Ghép 3). Ải k qua khi CẢ BA thanh ≥ ngưỡng ải k (dư thanh này không bù thanh kia). Ngưỡng =
-- đơn vị × max(số thành viên, 3) × hệ số ải × (1 + 25% × bậc Boss). Mỗi người chọn 1 vai/tuần
-- (đổi 1 lần): đóng góp đúng vai ×1.5 (tính lúc báo, không hồi tố).

create or replace function guild_dungeon_unit(p_kind text) returns bigint
language sql immutable as $$
  select case p_kind when 'tap' then 1500 when 'off' then 21600 when 'rec' then 25 end::bigint
$$;
create or replace function guild_dungeon_stage_mult(p_stage integer) returns integer
language sql immutable as $$ select case p_stage when 1 then 1 when 2 then 2 when 3 then 4 end $$;
create or replace function guild_dungeon_min_members() returns integer
language sql immutable as $$ select 3 $$;
-- Trần báo cáo mỗi giờ trôi qua trong tuần (off: không thể offline quá thời gian đã trôi).
create or replace function guild_dungeon_cap_per_hour(p_kind text) returns bigint
language sql immutable as $$
  select case p_kind when 'tap' then 40000 when 'off' then 3600 when 'rec' then 600 end::bigint
$$;
-- Mức đóng góp tối thiểu (đã nhân vai) để nhận thưởng ải: đạt MỘT trong ba.
create or replace function guild_dungeon_min_tap() returns integer language sql immutable as $$ select 200 $$;
create or replace function guild_dungeon_min_off() returns integer language sql immutable as $$ select 1800 $$;
create or replace function guild_dungeon_min_rec() returns integer language sql immutable as $$ select 5 $$;
create or replace function guild_dungeon_reward_coins(p_stage integer) returns integer
language sql immutable as $$ select case p_stage when 1 then 100 when 2 then 200 when 3 then 300 end $$;
create or replace function guild_dungeon_reward_gems(p_stage integer) returns integer
language sql immutable as $$ select case p_stage when 3 then 100 else 0 end $$;

create table if not exists guild_dungeon_roles (
  user_id uuid not null references auth.users(id) on delete cascade,
  week    date not null,
  role    text not null check (role in ('tap', 'off', 'rec')),
  changes integer not null default 0,
  primary key (user_id, week)
);
alter table guild_dungeon_roles enable row level security;

create table if not exists guild_dungeon_members (
  user_id  uuid not null references auth.users(id) on delete cascade,
  guild_id uuid not null references guilds(id) on delete cascade,
  week     date not null,
  -- Tổng luỹ kế client báo lần gần nhất (chỉ phần TĂNG mới tính)…
  last_tap bigint not null default 0 check (last_tap >= 0),
  last_off bigint not null default 0 check (last_off >= 0),
  last_rec bigint not null default 0 check (last_rec >= 0),
  -- …và phần đã đóng góp cho hội (đã nhân hệ số vai).
  tap bigint not null default 0 check (tap >= 0),
  off bigint not null default 0 check (off >= 0),
  rec bigint not null default 0 check (rec >= 0),
  primary key (user_id, guild_id, week)
);
create index if not exists guild_dungeon_members_guild_idx on guild_dungeon_members (guild_id, week);
alter table guild_dungeon_members enable row level security;

create table if not exists guild_dungeon_claims (
  user_id uuid not null references auth.users(id) on delete cascade,
  week    date not null,
  stage   integer not null check (stage between 1 and 3),
  primary key (user_id, week, stage)
);
alter table guild_dungeon_claims enable row level security;
-- Không policy nào: mọi truy cập qua RPC security definer.

-- Ngưỡng của thanh [p_kind] ở ải [p_stage] cho hội [p_guild].
create or replace function guild_dungeon_target(p_guild uuid, p_kind text, p_stage integer) returns bigint
language sql stable as $$
  select ceil(guild_dungeon_unit(p_kind)::numeric
              * greatest((select count(*) from guild_members m where m.guild_id = p_guild),
                         guild_dungeon_min_members())
              * guild_dungeon_stage_mult(p_stage)
              * (100 + 25 * guild_boss_tier(p_guild)) / 100)::bigint
$$;

-- Số ải đã qua (0..3) của hội trong tuần.
create or replace function guild_dungeon_cleared(p_guild uuid, p_week date) returns integer
language sql stable as $$
  with t as (
    select coalesce(sum(tap), 0) as tap, coalesce(sum(off), 0) as off, coalesce(sum(rec), 0) as rec
      from guild_dungeon_members where guild_id = p_guild and week = p_week)
  select count(*)::integer from generate_series(1, 3) s, t
   where t.tap >= guild_dungeon_target(p_guild, 'tap', s)
     and t.off >= guild_dungeon_target(p_guild, 'off', s)
     and t.rec >= guild_dungeon_target(p_guild, 'rec', s)
$$;

create or replace function guild_dungeon_set_role(p_role text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_week date := guild_current_week();
  v_r guild_dungeon_roles%rowtype;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_role is null or p_role not in ('tap', 'off', 'rec') then raise exception 'invalid role'; end if;
  if not exists (select 1 from guild_members where user_id = v_uid) then
    raise exception 'not in guild';
  end if;
  select * into v_r from guild_dungeon_roles where user_id = v_uid and week = v_week for update;
  if not found then
    insert into guild_dungeon_roles (user_id, week, role) values (v_uid, v_week, p_role);
  elsif v_r.role <> p_role then
    if v_r.changes >= 1 then raise exception 'role locked'; end if;
    update guild_dungeon_roles set role = p_role, changes = changes + 1
      where user_id = v_uid and week = v_week;
  end if;
end;
$$;

-- Báo tổng luỹ kế TRONG TUẦN của máy này. Lần đầu trong tuần ở hội này: vào hội trước đầu tuần →
-- tính từ 0; vào giữa tuần → mốc đầu là điểm xuất phát (không mang phần làm trước khi vào).
create or replace function guild_dungeon_submit(p_tap bigint, p_off bigint, p_rec bigint) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_m guild_members%rowtype;
  v_week date := guild_current_week();
  v_hours numeric;
  v_d guild_dungeon_members%rowtype;
  v_role text;
  v_dt bigint; v_do bigint; v_dr bigint;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_tap is null or p_off is null or p_rec is null or p_tap < 0 or p_off < 0 or p_rec < 0 then
    raise exception 'invalid input';
  end if;
  select * into v_m from guild_members where user_id = v_uid;
  if not found then raise exception 'not in guild'; end if;
  v_hours := greatest(
    extract(epoch from (now() - (v_week::timestamp at time zone 'utc'))) / 3600.0, 1);
  if p_tap > ceil(v_hours * guild_dungeon_cap_per_hour('tap'))
     or p_off > ceil(v_hours * guild_dungeon_cap_per_hour('off'))
     or p_rec > ceil(v_hours * guild_dungeon_cap_per_hour('rec')) then
    raise exception 'score too high';
  end if;
  select * into v_d from guild_dungeon_members
    where user_id = v_uid and guild_id = v_m.guild_id and week = v_week for update;
  if not found then
    if (v_m.joined_at at time zone 'utc')::date > v_week then
      insert into guild_dungeon_members (user_id, guild_id, week, last_tap, last_off, last_rec)
        values (v_uid, v_m.guild_id, v_week, p_tap, p_off, p_rec);
    else
      insert into guild_dungeon_members (user_id, guild_id, week) values (v_uid, v_m.guild_id, v_week);
    end if;
    select * into v_d from guild_dungeon_members
      where user_id = v_uid and guild_id = v_m.guild_id and week = v_week for update;
  end if;
  select role into v_role from guild_dungeon_roles where user_id = v_uid and week = v_week;
  v_dt := greatest(p_tap - v_d.last_tap, 0);
  v_do := greatest(p_off - v_d.last_off, 0);
  v_dr := greatest(p_rec - v_d.last_rec, 0);
  if v_role = 'tap' then v_dt := v_dt * 3 / 2; end if;
  if v_role = 'off' then v_do := v_do * 3 / 2; end if;
  if v_role = 'rec' then v_dr := v_dr * 3 / 2; end if;
  update guild_dungeon_members
     set last_tap = greatest(last_tap, p_tap), last_off = greatest(last_off, p_off),
         last_rec = greatest(last_rec, p_rec),
         tap = tap + v_dt, off = off + v_do, rec = rec + v_dr
   where user_id = v_uid and guild_id = v_m.guild_id and week = v_week;
end;
$$;

create or replace function guild_dungeon_state() returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_m guild_members%rowtype;
  v_week date := guild_current_week();
  v_bar record;
  v_my guild_dungeon_members%rowtype;
  v_role guild_dungeon_roles%rowtype;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select * into v_m from guild_members where user_id = v_uid;
  if not found then return null; end if;
  select coalesce(sum(tap), 0) as tap, coalesce(sum(off), 0) as off, coalesce(sum(rec), 0) as rec
    into v_bar from guild_dungeon_members where guild_id = v_m.guild_id and week = v_week;
  select * into v_my from guild_dungeon_members
    where user_id = v_uid and guild_id = v_m.guild_id and week = v_week;
  select * into v_role from guild_dungeon_roles where user_id = v_uid and week = v_week;
  return jsonb_build_object(
    'tier', guild_boss_tier(v_m.guild_id),
    'role', v_role.role,
    'role_changes', coalesce(v_role.changes, 0),
    'bars', jsonb_build_object('tap', v_bar.tap, 'off', v_bar.off, 'rec', v_bar.rec),
    'targets', (select jsonb_agg(jsonb_build_object(
        'tap', guild_dungeon_target(v_m.guild_id, 'tap', s),
        'off', guild_dungeon_target(v_m.guild_id, 'off', s),
        'rec', guild_dungeon_target(v_m.guild_id, 'rec', s)) order by s)
      from generate_series(1, 3) s),
    'cleared', guild_dungeon_cleared(v_m.guild_id, v_week),
    'claimed', coalesce((select jsonb_agg(c.stage order by c.stage) from guild_dungeon_claims c
                          where c.user_id = v_uid and c.week = v_week), '[]'::jsonb),
    'mine', jsonb_build_object('tap', coalesce(v_my.tap, 0), 'off', coalesce(v_my.off, 0),
                               'rec', coalesce(v_my.rec, 0)),
    'board', coalesce((
      select jsonb_agg(jsonb_build_object(
          'user_id', m.user_id, 'nickname', m.nickname, 'role', r.role,
          'tap', coalesce(d.tap, 0), 'off', coalesce(d.off, 0), 'rec', coalesce(d.rec, 0))
        order by coalesce(d.tap, 0) + coalesce(d.off, 0) + coalesce(d.rec, 0) desc, m.nickname)
      from guild_members m
      left join guild_dungeon_members d
        on d.user_id = m.user_id and d.guild_id = m.guild_id and d.week = v_week
      left join guild_dungeon_roles r on r.user_id = m.user_id and r.week = v_week
      where m.guild_id = v_m.guild_id), '[]'::jsonb));
end;
$$;

-- Nhận thưởng ải [p_stage]: Xu Hội cộng ở server; 💎 + rương phụ kiện do client cấp SAU khi OK.
create or replace function guild_dungeon_claim(p_stage integer) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_m guild_members%rowtype;
  v_week date := guild_current_week();
  v_d guild_dungeon_members%rowtype;
  v_coins integer;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_stage is null or p_stage < 1 or p_stage > 3 then raise exception 'invalid tier'; end if;
  select * into v_m from guild_members where user_id = v_uid;
  if not found then raise exception 'not in guild'; end if;
  if guild_dungeon_cleared(v_m.guild_id, v_week) < p_stage then
    raise exception 'stage not cleared';
  end if;
  select * into v_d from guild_dungeon_members
    where user_id = v_uid and guild_id = v_m.guild_id and week = v_week;
  if not found or not (v_d.tap >= guild_dungeon_min_tap() or v_d.off >= guild_dungeon_min_off()
                       or v_d.rec >= guild_dungeon_min_rec()) then
    raise exception 'not enough contribution';
  end if;
  begin
    insert into guild_dungeon_claims (user_id, week, stage) values (v_uid, v_week, p_stage);
  exception when unique_violation then
    raise exception 'already claimed';
  end;
  v_coins := guild_dungeon_reward_coins(p_stage);
  insert into guild_coin_wallets (user_id, balance) values (v_uid, v_coins)
    on conflict (user_id) do update
      set balance = guild_coin_wallets.balance + excluded.balance;
  return jsonb_build_object('gems', guild_dungeon_reward_gems(p_stage), 'coins', v_coins,
                            'chest', p_stage = 3);
end;
$$;

do $$
declare f text;
begin
  foreach f in array array[
    'guild_dungeon_set_role(text)', 'guild_dungeon_submit(bigint,bigint,bigint)',
    'guild_dungeon_state()', 'guild_dungeon_claim(integer)'
  ] loop
    execute format('revoke all on function %s from public', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- Hàm nội bộ nhận guild tuỳ ý → không cho client gọi (lộ số liệu hội khác).
revoke all on function guild_dungeon_target(uuid, text, integer) from public, anon, authenticated;
revoke all on function guild_dungeon_cleared(uuid, date) from public, anon, authenticated;
