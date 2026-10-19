-- Gộp các schema MỚI/ĐỔI cho bản 1.0.12 (ngoài all_1.0.11.sql). Idempotent. Dán cả file vào Supabase SQL Editor rồi Run.

-- ===== friends_schema.sql =====
-- Bạn bè: tìm theo biệt danh, lời mời → chấp nhận, danh sách, BXH bạn bè (thu nhập / XP Thẻ Mùa / đơn hoàn hảo) và quà mỗi ngày.
-- Chỉ tài khoản liên kết email dùng được (cả hai phía). Tối đa 50 bạn, 30 lời mời đang chờ. Dán TOÀN BỘ vào SQL Editor → Run. Idempotent.
-- Chạy SAU leaderboard_schema, season_leaderboard_schema, recipe_order_leaderboard_schema, arena_leaderboard_schema, guild_schema (đọc biệt danh/điểm).

create table if not exists friend_requests (
  from_user  uuid not null references auth.users(id) on delete cascade,
  to_user    uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (from_user, to_user),
  check (from_user <> to_user)
);
create index if not exists friend_requests_to_idx on friend_requests (to_user);

-- Mỗi cặp một hàng, user_a < user_b.
create table if not exists friendships (
  user_a     uuid not null references auth.users(id) on delete cascade,
  user_b     uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_a, user_b),
  check (user_a < user_b)
);
create index if not exists friendships_b_idx on friendships (user_b);

-- Một quà/ngày (UTC)/bạn. Người nhận gom bằng friend_gift_claim (quà quá 7 ngày hết hạn).
create table if not exists friend_gifts (
  from_user  uuid not null references auth.users(id) on delete cascade,
  to_user    uuid not null references auth.users(id) on delete cascade,
  day        date not null,
  claimed    boolean not null default false,
  primary key (from_user, to_user, day)
);
create index if not exists friend_gifts_to_idx on friend_gifts (to_user, claimed);

alter table friend_requests enable row level security;
alter table friendships enable row level security;
alter table friend_gifts enable row level security;
-- Không policy: chỉ RPC security definer.

create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

create or replace function friend_require_linked() returns uuid
language plpgsql stable security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if not is_linked_user() then raise exception 'email link required'; end if;
  return auth.uid();
end;
$$;

create or replace function friend_count(p_uid uuid) returns integer
language sql stable security definer set search_path = public as $$
  select count(*)::integer from friendships where user_a = p_uid or user_b = p_uid
$$;

create or replace function friend_are(p_x uuid, p_y uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from friendships where user_a = least(p_x, p_y) and user_b = greatest(p_x, p_y))
$$;

-- Biệt danh hiển thị của một người: lấy từ các bảng xếp hạng/hội (mới nhất trước).
create or replace function friend_nick(p_uid uuid) returns text
language sql stable security definer set search_path = public as $$
  select n from (
    select nickname as n, updated_at as t from leaderboard_entries where user_id = p_uid
    union all select nickname, updated_at from season_leaderboard_entries where user_id = p_uid
    union all select nickname, updated_at from arena_nicknames where user_id = p_uid
    union all select nickname, joined_at from guild_members where user_id = p_uid
  ) x order by t desc limit 1
$$;

-- Tìm theo biệt danh (không phân biệt hoa thường, khớp CHÍNH XÁC): tối đa 8 người, kèm giai đoạn để phân biệt trùng tên.
create or replace function friend_search(p_nickname text)
returns table (user_id uuid, nickname text, stage integer)
language plpgsql stable security definer set search_path = public as $$
declare me uuid := friend_require_linked(); q text := lower(btrim(coalesce(p_nickname, '')));
begin
  if char_length(q) not between 1 and 20 then return; end if;
  return query
    select c.uid, friend_nick(c.uid), coalesce((select e.stage from leaderboard_entries e where e.user_id = c.uid), 1)
      from (
        select l.user_id as uid from leaderboard_entries l where lower(l.nickname) = q
        union select s.user_id from season_leaderboard_entries s where lower(s.nickname) = q
        union select a.user_id from arena_nicknames a where lower(a.nickname) = q
        union select g.user_id from guild_members g where lower(g.nickname) = q
      ) c
      join auth.users u on u.id = c.uid and not u.is_anonymous
     where c.uid <> me
     order by 3 desc
     limit 8;
end;
$$;

-- Gửi lời mời. Nếu họ đã mời mình → thành bạn luôn. Trả 'sent' | 'accepted' | 'already'.
create or replace function friend_request(p_to uuid) returns text
language plpgsql security definer set search_path = public as $$
declare me uuid := friend_require_linked();
begin
  if p_to is null or p_to = me then raise exception 'bad target'; end if;
  if not exists (select 1 from auth.users u where u.id = p_to and not u.is_anonymous) then raise exception 'not found'; end if;
  if friend_are(me, p_to) then return 'already'; end if;
  if exists (select 1 from friend_requests where from_user = p_to and to_user = me) then
    return friend_respond(p_to, true);
  end if;
  if (select count(*) from friend_requests where from_user = me) >= 30 then raise exception 'too many requests'; end if;
  insert into friend_requests (from_user, to_user) values (me, p_to) on conflict do nothing;
  return 'sent';
end;
$$;

-- Trả lời lời mời của p_from. Trả 'accepted' | 'declined'.
create or replace function friend_respond(p_from uuid, p_accept boolean) returns text
language plpgsql security definer set search_path = public as $$
declare me uuid := friend_require_linked();
begin
  if not exists (select 1 from friend_requests where from_user = p_from and to_user = me) then raise exception 'not found'; end if;
  delete from friend_requests where from_user = p_from and to_user = me;
  if not p_accept then return 'declined'; end if;
  if friend_count(me) >= 50 or friend_count(p_from) >= 50 then raise exception 'friend limit'; end if;
  insert into friendships (user_a, user_b) values (least(me, p_from), greatest(me, p_from)) on conflict do nothing;
  return 'accepted';
end;
$$;

create or replace function friend_remove(p_friend uuid) returns void
language plpgsql security definer set search_path = public as $$
declare me uuid := friend_require_linked();
begin
  delete from friendships where user_a = least(me, p_friend) and user_b = greatest(me, p_friend);
  delete from friend_requests where (from_user = me and to_user = p_friend) or (from_user = p_friend and to_user = me);
end;
$$;

-- Tất cả cho trang Bạn bè trong MỘT lần gọi: bạn (kèm số liệu BXH + trạng thái quà), lời mời đến, bản thân (để xếp BXH).
create or replace function friend_overview() returns jsonb
language plpgsql security definer set search_path = public as $$
declare me uuid := friend_require_linked(); v_today date := (now() at time zone 'utc')::date; v_season integer := season_current_id();
begin
  return jsonb_build_object(
    'me', jsonb_build_object(
      'income', coalesce((select lifetime_earnings from leaderboard_entries where user_id = me), 0),
      'season_xp', coalesce((select xp from season_leaderboard_entries where user_id = me and season_id = v_season), 0),
      'orders', coalesce((select perfected from recipe_order_leaderboard_entries where user_id = me), 0)),
    'friends', coalesce((
      select jsonb_agg(jsonb_build_object(
        'user_id', f.fid, 'nickname', coalesce(friend_nick(f.fid), '???'),
        'stage', coalesce((select e.stage from leaderboard_entries e where e.user_id = f.fid), 1),
        'income', coalesce((select e.lifetime_earnings from leaderboard_entries e where e.user_id = f.fid), 0),
        'season_xp', coalesce((select s.xp from season_leaderboard_entries s where s.user_id = f.fid and s.season_id = v_season), 0),
        'orders', coalesce((select r.perfected from recipe_order_leaderboard_entries r where r.user_id = f.fid), 0),
        'gift_sent', exists (select 1 from friend_gifts g where g.from_user = me and g.to_user = f.fid and g.day = v_today)
      ) order by f.since desc)
      from (select case when user_a = me then user_b else user_a end as fid, created_at as since
              from friendships where user_a = me or user_b = me) f), '[]'::jsonb),
    'incoming', coalesce((
      select jsonb_agg(jsonb_build_object('user_id', r.from_user, 'nickname', coalesce(friend_nick(r.from_user), '???'))
                       order by r.created_at desc)
        from friend_requests r where r.to_user = me), '[]'::jsonb),
    'gifts_waiting', (select count(*) from friend_gifts g where g.to_user = me and not g.claimed and g.day >= v_today - 7),
    'raids_left', greatest(raid_per_day() - (select count(*) from friend_raids r where r.attacker = me and r.day = v_today), 0),
    'defense_waiting', (select count(*) from friend_raids r where r.defender = me and not r.win and not r.defense_claimed and r.day >= v_today - 7),
    'raid_log', coalesce((
      select jsonb_agg(jsonb_build_object('nickname', coalesce(friend_nick(t.attacker), '???'), 'win', t.win, 'day', t.day)
                       order by t.created_at desc)
        from (select attacker, win, day, created_at from friend_raids where defender = me
               order by created_at desc limit 10) t), '[]'::jsonb)
  );
end;
$$;

-- Tặng quà hôm nay cho bạn (một lần/ngày/bạn). Phần thưởng cộng ở app sau khi server xác nhận.
create or replace function friend_gift_send(p_to uuid) returns void
language plpgsql security definer set search_path = public as $$
declare me uuid := friend_require_linked();
begin
  if not friend_are(me, p_to) then raise exception 'not friends'; end if;
  begin
    insert into friend_gifts (from_user, to_user, day) values (me, p_to, (now() at time zone 'utc')::date);
  exception when unique_violation then
    raise exception 'already sent';
  end;
end;
$$;

-- Gom mọi quà chưa nhận (trong 7 ngày) của mình; trả số quà. Mỗi quà chỉ nhận được một lần.
create or replace function friend_gift_claim() returns integer
language plpgsql security definer set search_path = public as $$
declare me uuid := friend_require_linked(); n integer;
begin
  with c as (
    update friend_gifts g set claimed = true
     where g.to_user = me and not g.claimed and g.day >= (now() at time zone 'utc')::date - 7
       and exists (select 1 from friendships f where f.user_a = least(g.from_user, me) and f.user_b = greatest(g.from_user, me))
    returning 1)
  select count(*)::integer into n from c;
  return n;
end;
$$;

-- Quán của tôi: phụ kiện đang trưng bày (thuần trang trí). Client đẩy lên khi đổi trưng bày; server chỉ kiểm dạng id và số lượng
-- (danh mục nằm ở app; id lạ từ bản mới hơn bị app cũ bỏ qua). Chỉ bạn bè xem được qua friend_shop.
create table if not exists shop_displays (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  equipped   text[] not null default '{}',
  updated_at timestamptz not null default now()
);
alter table shop_displays add column if not exists power integer not null default 0 check (power between 0 and 1000);
alter table shop_displays enable row level security;
-- Không policy: chỉ RPC security definer.

-- p_power: "sức mạnh quán" do app tính từ món trưng bày + giai đoạn (dùng cho Đột kích); server chỉ kẹp 0..1000.
drop function if exists set_shop_display(text[]);
create or replace function set_shop_display(p_equipped text[], p_power integer default 0) returns void
language plpgsql security definer set search_path = public as $$
declare me uuid := friend_require_linked(); e text;
begin
  if p_equipped is null or coalesce(array_length(p_equipped, 1), 0) > 6 then raise exception 'bad display'; end if;
  foreach e in array p_equipped loop
    if e is null or e !~ '^[a-z0-9_]{1,40}$' then raise exception 'bad display'; end if;
  end loop;
  insert into shop_displays (user_id, equipped, power) values (me, p_equipped, least(greatest(coalesce(p_power, 0), 0), 1000))
  on conflict (user_id) do update set equipped = excluded.equipped, power = excluded.power, updated_at = now();
end;
$$;

-- Ghé thăm quán một người bạn: giai đoạn (cảnh quán), phụ kiện đang trưng bày và số liệu. Chỉ với bạn bè.
create or replace function friend_shop(p_friend uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare me uuid := friend_require_linked(); v_season integer := season_current_id();
begin
  if not friend_are(me, p_friend) then raise exception 'not friends'; end if;
  return jsonb_build_object(
    'nickname', coalesce(friend_nick(p_friend), '???'),
    'stage', coalesce((select e.stage from leaderboard_entries e where e.user_id = p_friend), 1),
    'income', coalesce((select e.lifetime_earnings from leaderboard_entries e where e.user_id = p_friend), 0),
    'season_xp', coalesce((select s.xp from season_leaderboard_entries s where s.user_id = p_friend and s.season_id = v_season), 0),
    'orders', coalesce((select r.perfected from recipe_order_leaderboard_entries r where r.user_id = p_friend), 0),
    'equipped', to_jsonb(coalesce((select d.equipped from shop_displays d where d.user_id = p_friend), '{}'::text[])),
    'power', coalesce((select d.power from shop_displays d where d.user_id = p_friend), 0));
end;
$$;

-- Đột kích quán bạn: gửi "đội đột kích" sang quán một người bạn. Kết quả quyết định ở server theo sức mạnh quán hai bên
-- (+ may rủi); KHÔNG ai mất Xu — thắng thì kẻ đột kích nhận thưởng, bị chặn thì người phòng thủ nhận thưởng phòng thủ.
-- Giới hạn: 3 lượt/ngày (UTC), mỗi bạn 1 lượt/ngày. Thưởng (số giây thu nhập) do app cấp SAU khi server xác nhận.
create table if not exists friend_raids (
  id              bigserial primary key,
  attacker        uuid not null references auth.users(id) on delete cascade,
  defender        uuid not null references auth.users(id) on delete cascade,
  day             date not null,
  win             boolean not null,
  defense_claimed boolean not null default false,
  created_at      timestamptz not null default now(),
  unique (attacker, defender, day)
);
create index if not exists friend_raids_defender_idx on friend_raids (defender, created_at desc);
alter table friend_raids enable row level security;

create or replace function raid_per_day() returns integer language sql immutable as $$ select 3 $$;
-- Xác suất kẻ đột kích thắng: 50% khi ngang sức; chênh lệch cả hai chiều, kẹp 15%..85%.
create or replace function raid_win_chance(p_attack integer, p_defense integer) returns numeric
language sql immutable as $$
  select least(0.85, greatest(0.15,
    0.5 + (p_attack - p_defense)::numeric / (2 * greatest(p_attack, p_defense, 1))))
$$;

-- Lõi quyết định: tách khỏi friend_raid để test truyền p_roll cố định (client KHÔNG gọi được).
create or replace function friend_raid_do(p_attacker uuid, p_target uuid, p_roll double precision) returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_day date := (now() at time zone 'utc')::date; v_ap integer; v_dp integer; v_chance numeric; v_win boolean;
begin
  if p_attacker = p_target then raise exception 'bad target'; end if;
  if not friend_are(p_attacker, p_target) then raise exception 'not friends'; end if;
  if (select count(*) from friend_raids where attacker = p_attacker and day = v_day) >= raid_per_day() then
    raise exception 'raid limit';
  end if;
  v_ap := coalesce((select power from shop_displays where user_id = p_attacker), 0);
  v_dp := coalesce((select power from shop_displays where user_id = p_target), 0);
  v_chance := raid_win_chance(v_ap, v_dp);
  v_win := p_roll < v_chance;
  begin
    insert into friend_raids (attacker, defender, day, win) values (p_attacker, p_target, v_day, v_win);
  exception when unique_violation then
    raise exception 'already raided';
  end;
  return jsonb_build_object('win', v_win, 'chance', v_chance, 'attack', v_ap, 'defense', v_dp);
end;
$$;

create or replace function friend_raid(p_target uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare me uuid := friend_require_linked();
begin
  return friend_raid_do(me, p_target, random());
end;
$$;

-- Gom thưởng phòng thủ (các lượt đột kích vào quán mình mà BỊ CHẶN, trong 7 ngày); trả số lượt.
create or replace function friend_raid_claim() returns integer
language plpgsql security definer set search_path = public as $$
declare me uuid := friend_require_linked(); n integer;
begin
  with c as (
    update friend_raids r set defense_claimed = true
     where r.defender = me and not r.win and not r.defense_claimed
       and r.day >= (now() at time zone 'utc')::date - 7
    returning 1)
  select count(*)::integer into n from c;
  return n;
end;
$$;

revoke all on function friend_require_linked(), friend_count(uuid), friend_are(uuid, uuid), friend_nick(uuid),
  friend_raid_do(uuid, uuid, double precision) from public, anon, authenticated;
revoke all on function friend_search(text), friend_request(uuid), friend_respond(uuid, boolean), friend_remove(uuid),
  friend_overview(), friend_gift_send(uuid), friend_gift_claim(), set_shop_display(text[], integer), friend_shop(uuid), friend_raid(uuid), friend_raid_claim() from public, anon;
grant execute on function friend_search(text), friend_request(uuid), friend_respond(uuid, boolean), friend_remove(uuid),
  friend_overview(), friend_gift_send(uuid), friend_gift_claim(), set_shop_display(text[], integer), friend_shop(uuid), friend_raid(uuid), friend_raid_claim() to authenticated;

-- ===== player_gender_schema.sql =====
-- Giới tính hồ sơ (tuỳ chọn, người chơi tự chọn, hiện trên hồ sơ công khai): male | female | other. Không chọn = không lưu gì.
-- Chỉ tài khoản đã liên kết email. Chạy SAU leaderboard_schema (tra user theo tên). Dán TOÀN BỘ vào SQL Editor → Run. Idempotent.

create table if not exists player_genders (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  gender     text not null check (gender in ('male', 'female', 'other')),
  updated_at timestamptz not null default now()
);
alter table player_genders enable row level security;
-- Không policy: chỉ RPC security definer.

-- p_gender '' = bỏ (xoá hàng).
create or replace function set_player_gender(p_gender text) returns void
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from auth.users where id = v_uid and is_anonymous) then raise exception 'not linked'; end if;
  if p_gender = '' then
    delete from player_genders where user_id = v_uid;
    return;
  end if;
  if p_gender not in ('male', 'female', 'other') then raise exception 'invalid gender'; end if;
  insert into player_genders (user_id, gender) values (v_uid, p_gender)
  on conflict (user_id) do update set gender = excluded.gender, updated_at = now();
end;
$$;

-- Giới tính của người có tên này ('' nếu không công khai). Tên trùng: lấy người có thu nhập cao nhất đã chọn.
create or replace function player_gender(p_nickname text) returns text
language sql stable security definer set search_path = public as $$
  select coalesce((
    select g.gender from leaderboard_entries e join player_genders g on g.user_id = e.user_id
     where lower(e.nickname) = lower(btrim(p_nickname))
     order by e.lifetime_earnings desc limit 1), '')
$$;

revoke all on function set_player_gender(text) from public, anon;
grant execute on function set_player_gender(text) to authenticated;
grant execute on function player_gender(text) to anon, authenticated;

-- ===== world_boss_schema.sql =====
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

-- ===== branch_leaderboard_schema.sql =====
-- Bảng xếp hạng Chi nhánh: xếp theo TỔNG CẤP mọi chi nhánh (client tự khai, chỉ tăng; hiện tối đa 17 nơi × cấp 10 = 170,
-- trần 500 để thêm thành phố không phải sửa). Chỉ tài khoản liên kết email mới nộp được. Hoà: ai đạt trước xếp trên.
-- Dán TOÀN BỘ vào SQL Editor → Run. Idempotent.

create table if not exists branch_leaderboard_entries (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  nickname     text    not null check (char_length(nickname) between 1 and 20),
  total_levels integer not null check (total_levels between 0 and 500),
  opened       integer not null check (opened between 0 and 50),
  updated_at   timestamptz not null default now()
);
alter table branch_leaderboard_entries enable row level security;
-- Không policy: chỉ RPC security definer.
create index if not exists branch_leaderboard_levels_idx on branch_leaderboard_entries (total_levels desc, updated_at asc);

create or replace function submit_branch_levels(p_nickname text, p_total integer, p_opened integer) returns void
language plpgsql security definer set search_path = public as $$
declare v_name text := btrim(coalesce(p_nickname, ''));
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from auth.users where id = auth.uid() and is_anonymous) then raise exception 'email link required'; end if;
  if p_total is null or p_total <= 0 then return; end if;
  if char_length(v_name) not between 1 and 20 then raise exception 'bad nickname'; end if;
  insert into branch_leaderboard_entries (user_id, nickname, total_levels, opened)
  values (auth.uid(), v_name, least(p_total, 500), least(greatest(coalesce(p_opened, 0), 0), 50))
  on conflict (user_id) do update
    set nickname = excluded.nickname,
        updated_at = case when excluded.total_levels > branch_leaderboard_entries.total_levels then now()
                          else branch_leaderboard_entries.updated_at end,
        total_levels = greatest(branch_leaderboard_entries.total_levels, excluded.total_levels),
        opened = greatest(branch_leaderboard_entries.opened, excluded.opened);
end;
$$;

create or replace function branch_leaderboard_top(p_limit integer default 50)
returns table (user_id uuid, nickname text, total_levels integer, opened integer, rank bigint)
language sql stable security definer set search_path = public as $$
  select e.user_id, e.nickname, e.total_levels, e.opened,
         row_number() over (order by e.total_levels desc, e.updated_at asc) as rank
    from branch_leaderboard_entries e
   order by rank
   limit least(greatest(p_limit, 1), 100)
$$;

revoke all on function submit_branch_levels(text, integer, integer) from public, anon;
grant execute on function submit_branch_levels(text, integer, integer) to authenticated;
grant execute on function branch_leaderboard_top(integer) to anon, authenticated;

-- ===== arena_leaderboard_schema.sql =====
-- Schema cho "Bảng xếp hạng PK" — xếp hạng thắng/thua Đấu Trường (Arena PvP),
-- gộp trên TOÀN BỘ người chơi. Độc lập với arena_schema.sql (dán sau file đó,
-- không sửa gì trong file đó) và với leaderboard_schema.sql/
-- story_speedrun_schema.sql — dán trước/sau đều được.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor → Run.
-- Idempotent (dùng "if not exists"/"or replace").
--
-- Khác leaderboard_entries (điểm số do CLIENT tự báo, cần trigger chống gian
-- lận riêng): thắng/thua/số trận ở đây được TÍNH THẲNG từ arena_matches.winner
-- — cột này do arena_resolve_match() (security definer, arena_schema.sql) tự
-- chốt trên server, replay lại log hành động thật (arena_compute_score).
-- Client không có cách nào tự sửa số thắng/thua của mình → KHÔNG cần trigger
-- chống gian lận như leaderboard_entries.
--
-- Tên hiển thị: TÁCH RIÊNG khỏi arena_matches, giữ đúng triết lý "không có
-- policy ghi trực tiếp" của Đấu Trường (xem đầu arena_schema.sql) — client chỉ
-- gọi arena_set_nickname(), không upsert thẳng bảng như leaderboard_entries.
-- Dùng CHUNG tên với Bảng xếp hạng chính/Tốc độ hoàn thành (key
-- 'leaderboard_nickname' phía Flutter) — không hỏi lại người chơi đã đặt tên
-- rồi.

-- Cột do arena_schema.sql thêm; khai lại ở đây để file này chạy độc lập thứ tự nào cũng được.
alter table arena_matches add column if not exists ghost boolean not null default false;

create table if not exists arena_nicknames (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  nickname   text not null check (char_length(nickname) between 1 and 20),
  updated_at timestamptz not null default now()
);

alter table arena_nicknames enable row level security;
-- Không có policy nào cho client (giống các bảng khác của Đấu Trường) — chỉ
-- đọc/ghi qua các hàm security definer bên dưới.

create or replace function arena_set_nickname(p_nickname text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'not authenticated';
  end if;
  if p_nickname is null or char_length(trim(p_nickname)) not between 1 and 20 then
    raise exception 'nickname phải dài 1-20 ký tự';
  end if;
  insert into arena_nicknames (user_id, nickname, updated_at)
  values (me, trim(p_nickname), now())
  on conflict (user_id) do update
    set nickname = excluded.nickname, updated_at = excluded.updated_at;
end;
$$;

grant execute on function arena_set_nickname(text) to authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- Xếp hạng: THẮNG NHIỀU NHẤT trước (không phải tỉ lệ thắng %) — tỉ lệ thắng
-- trần trụi bị lệch nặng lúc ít trận (thắng 1/1 = 100%, đứng trên người thắng
-- 40/50). Xếp theo tổng số trận thắng, hoà thì ai ít trận hơn (hiệu suất cao
-- hơn) đứng trên — không cộng thêm ngưỡng "tối thiểu N trận" để giữ đơn giản,
-- MVP không cần cấu hình thêm. Có thể đổi lại nếu sau này thấy tỉ lệ thắng
-- (kèm ngưỡng số trận) phù hợp hơn khi có nhiều người chơi thật.
--
-- SECURITY DEFINER: arena_matches chỉ cho SELECT đúng 2 người trong trận
-- (arena_matches_select_own, arena_schema.sql) — hàm này cần đọc TOÀN BỘ
-- bảng để gộp thắng/thua của mọi người, phải bỏ qua RLS đó.
--
-- Giống leaderboard_around_me: trả về [p_window] người TRÊN + chính bạn +
-- [p_window] người DƯỚI theo hạng. Nếu bạn CHƯA có trận nào (không nằm trong
-- kết quả gộp), trả về top (2×p_window + 1) thay vào đó — vẫn xem được bảng
-- xếp hạng dù chưa từng đấu.
create or replace function arena_leaderboard_around_me(p_window integer default 5)
returns table (
  user_id  uuid,
  nickname text,
  wins     bigint,
  losses   bigint,
  matches  bigint,
  rank     bigint
)
language sql
stable
security definer
set search_path = public
as $$
  with stats as (
    select player_id,
           count(*) filter (where won) as wins,
           count(*) filter (where not won) as losses,
           count(*) as matches
    from (
      select player_a as player_id, (winner = player_a) as won
        from arena_matches where status = 'finished' and not ghost
      union all
      select player_b as player_id, (winner = player_b) as won
        from arena_matches where status = 'finished' and not ghost
    ) per_player
    group by player_id
  ),
  ranked as (
    select
      s.player_id as user_id,
      coalesce(n.nickname, '???') as nickname,
      s.wins, s.losses, s.matches,
      row_number() over (order by s.wins desc, s.matches asc, s.player_id) as rank
    from stats s
    left join arena_nicknames n on n.user_id = s.player_id
  ),
  my_rank as (
    select rank from ranked where user_id = auth.uid()
  )
  select r.user_id, r.nickname, r.wins, r.losses, r.matches, r.rank
  from ranked r
  where case
    when exists (select 1 from my_rank)
      then r.rank between (select rank from my_rank) - p_window
                       and (select rank from my_rank) + p_window
    else r.rank <= (2 * p_window + 1)
  end
  order by r.rank;
$$;

grant execute on function arena_leaderboard_around_me(integer) to authenticated;

-- Bảng top công khai cho trang web (anon đọc được): cùng cách xếp hạng như trên, KHÔNG trả user_id.
create or replace function arena_leaderboard_top(p_limit integer default 20)
returns table (
  nickname text,
  wins     bigint,
  losses   bigint,
  matches  bigint,
  rank     bigint
)
language sql
stable
security definer
set search_path = public
as $$
  with stats as (
    select player_id,
           count(*) filter (where won) as wins,
           count(*) filter (where not won) as losses,
           count(*) as matches
    from (
      select player_a as player_id, (winner = player_a) as won
        from arena_matches where status = 'finished' and not ghost
      union all
      select player_b as player_id, (winner = player_b) as won
        from arena_matches where status = 'finished' and not ghost
    ) per_player
    group by player_id
  )
  select coalesce(n.nickname, '???') as nickname, s.wins, s.losses, s.matches,
         row_number() over (order by s.wins desc, s.matches asc, s.player_id) as rank
  from stats s
  left join arena_nicknames n on n.user_id = s.player_id
  order by rank
  limit least(greatest(coalesce(p_limit, 20), 1), 100);
$$;

grant execute on function arena_leaderboard_top(integer) to anon, authenticated;
