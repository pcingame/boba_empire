-- Schema cho HỘI (Guild): lập/vào/rời hội, mục tiêu tuần chung, BXH hội, báo cáo.
-- Mọi hội đều hiện trong danh sách. Hội thường: vào ngay. Hội "cần duyệt"
-- (requires_approval): người chơi gửi yêu cầu, CHỦ HỘI duyệt/từ chối mới vào được.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor → Run.
-- Idempotent. Độc lập với các file schema khác.
--
-- Điểm đóng góp = điểm sự kiện (chạm ly + 50 x (mèo + VIP), xem
-- lib/core/event_quests.dart eventScore) cộng dồn THEO TUẦN (thứ Hai 00:00 UTC).
--
-- Bảo mật: mọi bảng bật RLS và KHÔNG có policy nào → client không đọc/ghi thẳng,
-- chỉ đi qua RPC security definer bên dưới (kiểm đăng nhập, quyền chủ hội, trần
-- tốc độ điểm, giới hạn thành viên). Chống lạm dụng nội dung do người dùng tạo
-- (App Store 1.2): lọc từ cấm tên hội, nút báo cáo, ≥3 người báo → ẩn khỏi danh
-- sách/BXH, chủ hội kick được.
--
-- ⚠️ Các hằng số dưới đây PHẢI khớp lib/core/guild.dart (test
-- test/guild/guild_sql_test.dart so khớp): giới hạn thành viên, mốc tuần,
-- điểm tối thiểu để nhận thưởng, trần điểm/giờ.

create table if not exists guilds (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 3 and 20),
  tag         text not null check (tag ~ '^[A-Za-z0-9]{2,4}$'),
  emoji       text not null check (char_length(emoji) between 1 and 8),
  owner_id    uuid not null,
  hidden      boolean not null default false,
  requires_approval boolean not null default false,
  created_at  timestamptz not null default now()
);
-- Bản đã deploy trước đó chưa có cột này.
alter table guilds add column if not exists requires_approval boolean not null default false;
create unique index if not exists guilds_name_lower_idx on guilds (lower(name));

create table if not exists guild_members (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  guild_id    uuid not null references guilds(id) on delete cascade,
  nickname    text not null check (char_length(nickname) between 1 and 20),
  joined_at   timestamptz not null default now(),
  -- Điểm tuần: reset khi sang tuần mới (so với `week`). `last_score` là điểm tuần
  -- CÁ NHÂN client báo lần gần nhất — chỉ phần TĂNG THÊM mới tính cho hội, nên
  -- người vào hội giữa tuần không mang điểm cũ theo.
  week        date not null default date '1970-01-05',
  week_points bigint not null default 0 check (week_points >= 0),
  last_score  bigint not null default 0 check (last_score >= 0)
);
create index if not exists guild_members_guild_idx on guild_members (guild_id);

create table if not exists guild_reward_claims (
  user_id   uuid not null references auth.users(id) on delete cascade,
  week      date not null,
  milestone integer not null,
  primary key (user_id, week, milestone)
);

create table if not exists guild_reports (
  guild_id    uuid not null references guilds(id) on delete cascade,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reason      text not null check (char_length(reason) <= 100),
  created_at  timestamptz not null default now(),
  primary key (guild_id, reporter_id)
);

-- Yêu cầu vào hội cần duyệt. Mỗi người chỉ có MỘT yêu cầu đang chờ (gửi sang hội
-- khác thì thay thế); `score` là điểm tuần lúc xin — làm mốc khi được duyệt, để
-- người mới không mang điểm cũ theo.
create table if not exists guild_join_requests (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  guild_id   uuid not null references guilds(id) on delete cascade,
  nickname   text not null check (char_length(nickname) between 1 and 20),
  score      bigint not null default 0 check (score >= 0),
  created_at timestamptz not null default now()
);
create index if not exists guild_join_requests_guild_idx on guild_join_requests (guild_id);

-- Dọn bản cũ đã deploy (có mã mời + hội riêng, đã gỡ): bỏ cột và các hàm cũ để
-- không còn overload cũ gọi được. Idempotent.
alter table guilds drop column if exists is_public;
alter table guilds drop column if exists invite_code;
drop function if exists guild_create(text, text, text, boolean, text, bigint);
drop function if exists guild_join(uuid, text, text, bigint);
drop function if exists guild_list_public(integer);
-- Đổi chữ ký / cột trả về → phải drop bản trước (create or replace không đổi được).
drop function if exists guild_create(text, text, text, text, bigint);
drop function if exists guild_list(integer);

alter table guilds              enable row level security;
alter table guild_members       enable row level security;
alter table guild_reward_claims enable row level security;
alter table guild_reports       enable row level security;
alter table guild_join_requests enable row level security;
-- Cố ý KHÔNG tạo policy: chỉ RPC security definer được đụng vào.

-- --- Hằng số --------------------------------------------------------------
create or replace function guild_max_members() returns integer
language sql immutable as $$ select 30 $$;

-- Mốc tuần của CẢ HỘI (tổng điểm): 1→10.000, 2→40.000, 3→120.000.
create or replace function guild_milestone_threshold(p_milestone integer)
returns bigint language sql immutable as $$
  select case p_milestone when 1 then 10000 when 2 then 40000 when 3 then 120000 end::bigint
$$;

-- Điểm cá nhân tối thiểu trong tuần để được nhận thưởng mốc (chống ăn theo).
create or replace function guild_min_points_to_claim() returns integer
language sql immutable as $$ select 300 $$;

-- Trần điểm/giờ (≈ 28 chạm/giây liên tục) — cùng mức BXH sự kiện.
-- Số yêu cầu chờ duyệt tối đa mỗi hội (chống spam làm ngập chủ hội).
create or replace function guild_max_requests() returns integer
language sql immutable as $$ select 30 $$;

create or replace function guild_score_per_hour() returns integer
language sql immutable as $$ select 100000 $$;

create or replace function guild_current_week() returns date
language sql stable as $$
  select date_trunc('week', now() at time zone 'utc')::date
$$;

-- Lọc từ cấm cơ bản + chống giả mạo ban quản trị. Chuẩn hoá: thường, bỏ khoảng
-- trắng/ký tự đặc biệt. ponytail: danh sách ngắn, mở rộng khi có báo cáo.
create or replace function guild_text_ok(p_text text) returns boolean
language plpgsql immutable as $$
declare
  v text := regexp_replace(lower(coalesce(p_text, '')), '[^a-z0-9à-ỹ]', '', 'g');
  w text;
begin
  foreach w in array array[
    'fuck','shit','bitch','porn','nigg','cunt','admin','moderator','support',
    'cặc','lồn','buồi','địt','đụ','đéo','vcl','dkm','clgt'
  ] loop
    if position(w in v) > 0 then return false; end if;
  end loop;
  return true;
end;
$$;

create or replace function guild_week_total(p_guild uuid) returns bigint
language sql stable as $$
  select coalesce(sum(week_points), 0)::bigint
  from guild_members
  where guild_id = p_guild and week = guild_current_week()
$$;

-- --- RPC ------------------------------------------------------------------
create or replace function guild_create(
  p_name text, p_tag text, p_emoji text, p_requires_approval boolean,
  p_nickname text, p_score bigint
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_name text := btrim(coalesce(p_name, ''));
  v_id uuid;
  v_week date := guild_current_week();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from guild_members where user_id = v_uid) then
    raise exception 'already in guild';
  end if;
  if char_length(v_name) not between 3 and 20
     or p_tag !~ '^[A-Za-z0-9]{2,4}$'
     or char_length(coalesce(p_nickname, '')) not between 1 and 20
     or not guild_text_ok(v_name) or not guild_text_ok(p_tag)
     or not guild_text_ok(p_nickname) then
    raise exception 'invalid name';
  end if;

  begin
    insert into guilds (name, tag, emoji, owner_id, requires_approval)
    values (v_name, upper(p_tag), p_emoji, v_uid, coalesce(p_requires_approval, false))
    returning id into v_id;
  exception when unique_violation then
    raise exception 'name taken';
  end;

  insert into guild_members (user_id, guild_id, nickname, week, last_score)
  values (v_uid, v_id, p_nickname, v_week, greatest(coalesce(p_score, 0), 0));
  delete from guild_join_requests where user_id = v_uid;
  return v_id;
end;
$$;

create or replace function guild_join(
  p_guild uuid, p_nickname text, p_score bigint
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_g guilds%rowtype;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from guild_members where user_id = v_uid) then
    raise exception 'already in guild';
  end if;
  if char_length(coalesce(p_nickname, '')) not between 1 and 20
     or not guild_text_ok(p_nickname) then
    raise exception 'invalid name';
  end if;

  select * into v_g from guilds where id = p_guild and not hidden for update;
  if not found then raise exception 'not found'; end if;
  if v_g.requires_approval then raise exception 'approval required'; end if;

  if (select count(*) from guild_members where guild_id = v_g.id)
       >= guild_max_members() then
    raise exception 'guild full';
  end if;

  insert into guild_members (user_id, guild_id, nickname, week, last_score)
  values (v_uid, v_g.id, p_nickname, guild_current_week(),
          greatest(coalesce(p_score, 0), 0));
  delete from guild_join_requests where user_id = v_uid;
  return v_g.id;
end;
$$;

-- Xin vào hội cần duyệt. Gửi sang hội khác thì thay yêu cầu cũ.
create or replace function guild_request_join(
  p_guild uuid, p_nickname text, p_score bigint
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_g guilds%rowtype;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from guild_members where user_id = v_uid) then
    raise exception 'already in guild';
  end if;
  if char_length(coalesce(p_nickname, '')) not between 1 and 20
     or not guild_text_ok(p_nickname) then
    raise exception 'invalid name';
  end if;
  select * into v_g from guilds where id = p_guild and not hidden for update;
  if not found then raise exception 'not found'; end if;
  if not v_g.requires_approval then raise exception 'no approval needed'; end if;
  if (select count(*) from guild_join_requests
        where guild_id = v_g.id and user_id <> v_uid) >= guild_max_requests() then
    raise exception 'too many requests';
  end if;
  insert into guild_join_requests (user_id, guild_id, nickname, score)
  values (v_uid, v_g.id, p_nickname, greatest(coalesce(p_score, 0), 0))
  on conflict (user_id) do update
    set guild_id = excluded.guild_id, nickname = excluded.nickname,
        score = excluded.score, created_at = now();
end;
$$;

create or replace function guild_cancel_request() returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  delete from guild_join_requests where user_id = auth.uid();
end;
$$;

-- Chủ hội duyệt (p_accept = true) hoặc từ chối yêu cầu của p_user.
create or replace function guild_respond_request(p_user uuid, p_accept boolean)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_g guilds%rowtype;
  v_r guild_join_requests%rowtype;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select g.* into v_g from guilds g where g.owner_id = v_uid for update;
  if not found then raise exception 'not owner'; end if;
  select * into v_r from guild_join_requests
    where user_id = p_user and guild_id = v_g.id;
  if not found then raise exception 'not found'; end if;

  if not coalesce(p_accept, false) then
    delete from guild_join_requests where user_id = p_user;
    return;
  end if;
  if exists (select 1 from guild_members where user_id = p_user) then
    delete from guild_join_requests where user_id = p_user;  -- đã vào hội khác: bỏ yêu cầu cũ
    return;
  end if;
  if (select count(*) from guild_members where guild_id = v_g.id)
       >= guild_max_members() then
    raise exception 'guild full';
  end if;
  insert into guild_members (user_id, guild_id, nickname, week, last_score)
  values (p_user, v_g.id, v_r.nickname, guild_current_week(), v_r.score);
  delete from guild_join_requests where user_id = p_user;
end;
$$;

create or replace function guild_leave() returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_gid uuid;
  v_next uuid;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  delete from guild_members where user_id = v_uid returning guild_id into v_gid;
  if v_gid is null then return; end if;
  select user_id into v_next from guild_members
    where guild_id = v_gid order by joined_at asc limit 1;
  if v_next is null then
    delete from guilds where id = v_gid;           -- hội trống → xoá
  else
    update guilds set owner_id = v_next
      where id = v_gid and owner_id = v_uid;       -- chủ rời → người cũ nhất kế nhiệm
  end if;
end;
$$;

create or replace function guild_kick(p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_gid uuid;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_user = v_uid then raise exception 'cannot kick self'; end if;
  select guild_id into v_gid from guild_members m
    join guilds g on g.id = m.guild_id
    where m.user_id = v_uid and g.owner_id = v_uid;
  if v_gid is null then raise exception 'not owner'; end if;
  delete from guild_members where user_id = p_user and guild_id = v_gid;
end;
$$;

-- Client báo điểm tuần CÁ NHÂN tích luỹ; hội chỉ nhận phần tăng thêm.
create or replace function guild_submit_score(p_score bigint) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_m guild_members%rowtype;
  v_week date := guild_current_week();
  v_hours numeric;
  v_base bigint;
  v_last bigint;
  v_pts bigint;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_score is null or p_score < 0 then raise exception 'invalid input'; end if;
  select * into v_m from guild_members where user_id = v_uid for update;
  if not found then raise exception 'not in guild'; end if;

  v_hours := greatest(
    extract(epoch from (now() - (v_week::timestamp at time zone 'utc'))) / 3600.0, 1);
  if p_score > ceil(v_hours * guild_score_per_hour()) then
    raise exception 'score too high';
  end if;

  if v_m.week = v_week then
    v_last := v_m.last_score; v_pts := v_m.week_points;
  else
    v_last := 0; v_pts := 0;                        -- sang tuần mới → reset
  end if;
  v_base := greatest(v_last, p_score);
  update guild_members
    set week = v_week,
        week_points = v_pts + greatest(p_score - v_last, 0),
        last_score = v_base
    where user_id = v_uid;
end;
$$;

create or replace function guild_my() returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_g guilds%rowtype;
  v_week date := guild_current_week();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select g.* into v_g from guilds g
    join guild_members m on m.guild_id = g.id where m.user_id = v_uid;
  if not found then return null; end if;
  return jsonb_build_object(
    'guild', jsonb_build_object(
      'id', v_g.id, 'name', v_g.name, 'tag', v_g.tag, 'emoji', v_g.emoji,
      'owner_id', v_g.owner_id, 'requires_approval', v_g.requires_approval),
    'week', v_week,
    'total', guild_week_total(v_g.id),
    'claimed', coalesce((select jsonb_agg(milestone order by milestone)
       from guild_reward_claims where user_id = v_uid and week = v_week), '[]'::jsonb),
    'members', coalesce((select jsonb_agg(jsonb_build_object(
         'user_id', m.user_id, 'nickname', m.nickname,
         'points', case when m.week = v_week then m.week_points else 0 end)
         order by (case when m.week = v_week then m.week_points else 0 end) desc,
                  m.joined_at asc)
       from guild_members m where m.guild_id = v_g.id), '[]'::jsonb),
    -- Chỉ chủ hội thấy danh sách yêu cầu.
    'requests', case when v_g.owner_id = v_uid then coalesce((
         select jsonb_agg(jsonb_build_object('user_id', r.user_id,
                'nickname', r.nickname) order by r.created_at asc)
         from guild_join_requests r where r.guild_id = v_g.id), '[]'::jsonb)
       else '[]'::jsonb end);
end;
$$;

create or replace function guild_list(p_limit integer default 30)
returns table (id uuid, name text, tag text, emoji text,
               member_count bigint, week_total bigint,
               requires_approval boolean, requested boolean)
language sql stable security definer set search_path = public as $$
  select g.id, g.name, g.tag, g.emoji,
         (select count(*) from guild_members m where m.guild_id = g.id),
         guild_week_total(g.id),
         g.requires_approval,
         exists (select 1 from guild_join_requests r
                 where r.guild_id = g.id and r.user_id = auth.uid())
  from guilds g
  where not g.hidden
    and (select count(*) from guild_members m where m.guild_id = g.id)
        < guild_max_members()
  order by 6 desc, 5 desc, g.created_at asc
  limit least(p_limit, 50)
$$;

create or replace function guild_leaderboard(p_limit integer default 50)
returns table (rank bigint, id uuid, name text, tag text, emoji text,
               member_count bigint, week_total bigint)
language sql stable security definer set search_path = public as $$
  select row_number() over (order by t.total desc, g.created_at asc),
         g.id, g.name, g.tag, g.emoji,
         (select count(*) from guild_members m where m.guild_id = g.id),
         t.total
  from guilds g
  cross join lateral (select guild_week_total(g.id) as total) t
  where not g.hidden and t.total > 0
  order by 1
  limit least(p_limit, 100)
$$;

create or replace function guild_report(p_guild uuid, p_reason text) returns void
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if not exists (select 1 from guilds where id = p_guild) then
    raise exception 'not found';
  end if;
  if exists (select 1 from guild_members
             where user_id = v_uid and guild_id = p_guild) then
    raise exception 'cannot report own guild';
  end if;
  insert into guild_reports (guild_id, reporter_id, reason)
  values (p_guild, v_uid, left(coalesce(p_reason, ''), 100))
  on conflict do nothing;
  if (select count(*) from guild_reports where guild_id = p_guild) >= 3 then
    update guilds set hidden = true where id = p_guild;
  end if;
end;
$$;

create or replace function guild_claim_reward(p_milestone integer) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_m guild_members%rowtype;
  v_week date := guild_current_week();
  v_need bigint := guild_milestone_threshold(p_milestone);
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if v_need is null then raise exception 'invalid milestone'; end if;
  select * into v_m from guild_members where user_id = v_uid;
  if not found then raise exception 'not in guild'; end if;
  if guild_week_total(v_m.guild_id) < v_need then
    raise exception 'milestone not reached';
  end if;
  if v_m.week <> v_week or v_m.week_points < guild_min_points_to_claim() then
    raise exception 'not enough contribution';
  end if;
  begin
    insert into guild_reward_claims (user_id, week, milestone)
    values (v_uid, v_week, p_milestone);
  exception when unique_violation then
    raise exception 'already claimed';
  end;
end;
$$;

-- Quyền: chỉ người đã đăng nhập (kể cả ẩn danh) gọi được RPC.
do $$
declare f text;
begin
  foreach f in array array[
    'guild_create(text,text,text,boolean,text,bigint)',
    'guild_join(uuid,text,bigint)',
    'guild_request_join(uuid,text,bigint)', 'guild_cancel_request()',
    'guild_respond_request(uuid,boolean)',
    'guild_leave()', 'guild_kick(uuid)', 'guild_submit_score(bigint)',
    'guild_my()', 'guild_list(integer)', 'guild_leaderboard(integer)',
    'guild_report(uuid,text)', 'guild_claim_reward(integer)'
  ] loop
    execute format('revoke all on function %s from public', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;
