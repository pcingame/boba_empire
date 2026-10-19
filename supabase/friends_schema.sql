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
