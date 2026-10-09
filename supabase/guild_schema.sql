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

-- Buff thu nhập cả hội (mua bằng Xu Hội), hết hạn lúc buff_until.
alter table guilds add column if not exists buff_until timestamptz;

-- Lịch sử điểm theo tuần: phần điểm của thành viên được GHI VÀO ĐÂY khi họ sang
-- tuần mới (guild_submit_score) hoặc rời/bị kick, trước khi hàng của họ bị đặt lại/
-- xoá. Tổng một tuần quá khứ = bảng này + các hàng thành viên còn nằm ở tuần đó
-- (xem guild_total_of). Dùng để tính chuỗi tuần đạt đủ 3 mốc.
create table if not exists guild_week_totals (
  guild_id uuid not null references guilds(id) on delete cascade,
  week     date not null,
  total    bigint not null default 0 check (total >= 0),
  primary key (guild_id, week)
);

-- Ví "Xu Hội" cá nhân (theo người chơi, giữ nguyên khi đổi hội).
create table if not exists guild_coin_wallets (
  user_id uuid primary key references auth.users(id) on delete cascade,
  balance bigint not null default 0 check (balance >= 0)
);

-- Số 💎 đã nạp mỗi ngày (UTC) — để giới hạn nạp.
create table if not exists guild_donations (
  user_id uuid not null references auth.users(id) on delete cascade,
  day     date not null,
  gems    integer not null default 0 check (gems >= 0),
  primary key (user_id, day)
);

-- Nhiệm vụ hội hàng tuần đã nhận thưởng.
create table if not exists guild_quest_claims (
  user_id uuid not null references auth.users(id) on delete cascade,
  week    date not null,
  tier    integer not null,
  primary key (user_id, week, tier)
);

-- Vật phẩm đã đổi (mỗi món một lần/người) — cũng là nguồn khôi phục khi mất save.
create table if not exists guild_purchases (
  user_id    uuid not null references auth.users(id) on delete cascade,
  item_id    text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, item_id)
);

-- Dọn bản cũ đã deploy (có mã mời + hội riêng, đã gỡ): bỏ cột và các hàm cũ để
-- không còn overload cũ gọi được. Idempotent.
-- Chat hội: tin ngắn, giữ 200 tin gần nhất mỗi hội; chủ hội ghim 1 tin làm thông báo.
create table if not exists guild_messages (
  id         bigserial primary key,
  guild_id   uuid not null references guilds(id) on delete cascade,
  user_id    uuid not null,
  nickname   text not null,
  body       text not null check (char_length(body) between 1 and 200),
  pinned     boolean not null default false,
  created_at timestamptz not null default now()
);
-- Bản đã deploy trước đó chưa có cột này: tin bị ≥3 thành viên báo cáo thì ẩn.
alter table guild_messages add column if not exists hidden boolean not null default false;
create table if not exists guild_message_reports (
  message_id  bigint not null references guild_messages(id) on delete cascade,
  reporter_id uuid not null,
  created_at  timestamptz not null default now(),
  primary key (message_id, reporter_id)
);
create index if not exists guild_messages_guild_idx on guild_messages (guild_id, id desc);

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
alter table guild_week_totals   enable row level security;
alter table guild_coin_wallets  enable row level security;
alter table guild_donations     enable row level security;
alter table guild_quest_claims  enable row level security;
alter table guild_purchases     enable row level security;
alter table guild_messages      enable row level security;
alter table guild_message_reports enable row level security;
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

-- BXH "trung bình/người": chỉ hội đủ người mới lên bảng (chống lập hội 1 người).
create or replace function guild_avg_min_members() returns integer
language sql immutable as $$ select 5 $$;

-- Xu Hội: nạp 💎 (1 💎 = 1 Xu Hội, tối đa 1000 💎/ngày/người), nhiệm vụ tuần theo
-- điểm đóng góp cá nhân (1.000/5.000/20.000 điểm → 100/200/400 Xu Hội).
create or replace function guild_donate_daily_cap() returns integer
language sql immutable as $$ select 1000 $$;
create or replace function guild_coins_per_gem() returns integer
language sql immutable as $$ select 1 $$;
create or replace function guild_quest_need(p_tier integer) returns bigint
language sql immutable as $$
  select case p_tier when 1 then 1000 when 2 then 5000 when 3 then 20000 end::bigint
$$;
create or replace function guild_quest_reward(p_tier integer) returns integer
language sql immutable as $$
  select case p_tier when 1 then 100 when 2 then 200 when 3 then 400 end
$$;

-- Cửa hàng hội: phụ kiện độc quyền (giá Xu Hội) + buff thu nhập cả hội.
create or replace function guild_item_price(p_item text) returns integer
language sql immutable as $$
  select case p_item
    when 'guild_flag' then 500
    when 'guild_castle' then 1500
    when 'guild_wolf' then 1500
    when 'guild_dragon' then 4000
    when 'guild_fox' then 800
    when 'guild_tiger' then 1000
    when 'guild_shark' then 2500
    when 'guild_trex' then 6000
    when 'guild_boar' then 600
    when 'guild_bear' then 1200
    when 'guild_scorpion' then 2000
    when 'guild_moai' then 3000
  end
$$;
create or replace function guild_buff_price() returns integer
language sql immutable as $$ select 800 $$;
create or replace function guild_buff_hours() returns integer
language sql immutable as $$ select 24 $$;
-- Buff còn lại không được vượt mức này khi mua thêm (chặn dồn buff vô hạn).
create or replace function guild_buff_max_hours() returns integer
language sql immutable as $$ select 48 $$;

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

-- Tổng điểm của hội trong tuần [p_week]: phần đã ghi lịch sử + các thành viên còn
-- nằm ở tuần đó. Gồm cả điểm của người đã rời hội trong tuần (họ đã đóng góp).
create or replace function guild_total_of(p_guild uuid, p_week date) returns bigint
language sql stable as $$
  select (coalesce((select total from guild_week_totals
                      where guild_id = p_guild and week = p_week), 0)
        + coalesce((select sum(week_points) from guild_members
                      where guild_id = p_guild and week = p_week), 0))::bigint
$$;

create or replace function guild_week_total(p_guild uuid) returns bigint
language sql stable as $$ select guild_total_of(p_guild, guild_current_week()) $$;

-- Ghi điểm của một hàng thành viên vào lịch sử (gọi TRƯỚC khi đặt lại/xoá hàng).
create or replace function guild_log_week(p_guild uuid, p_week date, p_points bigint)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_points is null or p_points <= 0 then return; end if;
  insert into guild_week_totals (guild_id, week, total)
  values (p_guild, p_week, p_points)
  on conflict (guild_id, week) do update
    set total = guild_week_totals.total + excluded.total;
end;
$$;

-- Chuỗi tuần liên tiếp đạt ĐỦ 3 mốc (tổng ≥ mốc cao nhất). Tuần hiện tại tính nếu
-- đã đạt; chưa đạt thì chuỗi tính từ tuần trước. Tối đa 52 tuần.
-- ponytail: vòng lặp theo tuần cho từng hội; nếu BXH chuỗi thành nút thắt thì
-- chuyển thành cột tính sẵn khi chốt tuần.
create or replace function guild_streak(p_guild uuid) returns integer
language plpgsql stable as $$
declare
  v_need bigint := guild_milestone_threshold(3);
  v_w date := guild_current_week();
  v_n integer := 0;
begin
  if guild_total_of(p_guild, v_w) >= v_need then v_n := 1; end if;
  v_w := v_w - 7;
  while v_n < 52 and guild_total_of(p_guild, v_w) >= v_need loop
    v_n := v_n + 1;
    v_w := v_w - 7;
  end loop;
  return v_n;
end;
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
  v_wk date;
  v_pts bigint;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  delete from guild_members where user_id = v_uid
    returning guild_id, week, week_points into v_gid, v_wk, v_pts;
  if v_gid is null then return; end if;
  perform guild_log_week(v_gid, v_wk, v_pts);       -- điểm đã đóng góp vẫn thuộc hội
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
  v_wk date;
  v_pts bigint;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_user = v_uid then raise exception 'cannot kick self'; end if;
  select guild_id into v_gid from guild_members m
    join guilds g on g.id = m.guild_id
    where m.user_id = v_uid and g.owner_id = v_uid;
  if v_gid is null then raise exception 'not owner'; end if;
  delete from guild_members where user_id = p_user and guild_id = v_gid
    returning week, week_points into v_wk, v_pts;
  perform guild_log_week(v_gid, v_wk, v_pts);
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
    perform guild_log_week(v_m.guild_id, v_m.week, v_m.week_points);
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
    'streak', guild_streak(v_g.id),
    'buff_seconds', greatest(
        extract(epoch from (coalesce(v_g.buff_until, now()) - now()))::integer, 0),
    'wallet', coalesce((select balance from guild_coin_wallets
                          where user_id = v_uid), 0),
    'quests_claimed', coalesce((select jsonb_agg(tier order by tier)
       from guild_quest_claims where user_id = v_uid and week = v_week), '[]'::jsonb),
    'owned_items', coalesce((select jsonb_agg(item_id order by item_id)
       from guild_purchases where user_id = v_uid), '[]'::jsonb),
    'donated_today', coalesce((select gems from guild_donations
       where user_id = v_uid and day = (now() at time zone 'utc')::date), 0),
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

-- --- BXH phụ: trung bình/người & chuỗi tuần ---------------------------------
create or replace function guild_leaderboard_avg(p_limit integer default 50)
returns table (rank bigint, id uuid, name text, tag text, emoji text,
               member_count bigint, week_total bigint, avg_points bigint)
language sql stable security definer set search_path = public as $$
  select row_number() over (order by s.avg desc, s.total desc, s.created_at asc),
         s.id, s.name, s.tag, s.emoji, s.cnt, s.total, s.avg
  from (
    select g.id, g.name, g.tag, g.emoji, g.created_at,
           (select count(*) from guild_members m where m.guild_id = g.id) as cnt,
           guild_week_total(g.id) as total,
           (guild_week_total(g.id) / greatest(
              (select count(*) from guild_members m where m.guild_id = g.id), 1))::bigint
             as avg
    from guilds g
    where not g.hidden
  ) s
  where s.cnt >= guild_avg_min_members() and s.total > 0
  order by 1
  limit least(p_limit, 100)
$$;

create or replace function guild_leaderboard_streak(p_limit integer default 50)
returns table (rank bigint, id uuid, name text, tag text, emoji text,
               member_count bigint, week_total bigint, streak integer)
language sql stable security definer set search_path = public as $$
  select row_number() over (order by s.streak desc, s.total desc, s.created_at asc),
         s.id, s.name, s.tag, s.emoji, s.cnt, s.total, s.streak
  from (
    select g.id, g.name, g.tag, g.emoji, g.created_at,
           (select count(*) from guild_members m where m.guild_id = g.id) as cnt,
           guild_week_total(g.id) as total,
           guild_streak(g.id) as streak
    from guilds g
    where not g.hidden
  ) s
  where s.streak > 0
  order by 1
  limit least(p_limit, 100)
$$;

-- --- Xu Hội: nạp 💎, nhiệm vụ tuần, cửa hàng, buff -----------------------------
-- Client chỉ trừ 💎 cục bộ SAU KHI RPC thành công (cùng quy ước phí tạo hội).
create or replace function guild_donate(p_gems integer) returns bigint
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_day date := (now() at time zone 'utc')::date;
  v_today integer;
  v_bal bigint;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if not exists (select 1 from guild_members where user_id = v_uid) then
    raise exception 'not in guild';
  end if;
  if p_gems is null or p_gems < 1 or p_gems > guild_donate_daily_cap() then
    raise exception 'invalid amount';
  end if;
  insert into guild_donations (user_id, day, gems) values (v_uid, v_day, 0)
    on conflict do nothing;
  select gems into v_today from guild_donations
    where user_id = v_uid and day = v_day for update;
  if v_today + p_gems > guild_donate_daily_cap() then
    raise exception 'daily limit';
  end if;
  update guild_donations set gems = gems + p_gems
    where user_id = v_uid and day = v_day;
  insert into guild_coin_wallets (user_id, balance)
    values (v_uid, p_gems::bigint * guild_coins_per_gem())
    on conflict (user_id) do update
      set balance = guild_coin_wallets.balance + excluded.balance
    returning balance into v_bal;
  return v_bal;
end;
$$;

create or replace function guild_claim_quest(p_tier integer) returns bigint
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_m guild_members%rowtype;
  v_week date := guild_current_week();
  v_need bigint := guild_quest_need(p_tier);
  v_bal bigint;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if v_need is null then raise exception 'invalid tier'; end if;
  select * into v_m from guild_members where user_id = v_uid;
  if not found then raise exception 'not in guild'; end if;
  if v_m.week <> v_week or v_m.week_points < v_need then
    raise exception 'not enough contribution';
  end if;
  begin
    insert into guild_quest_claims (user_id, week, tier) values (v_uid, v_week, p_tier);
  exception when unique_violation then
    raise exception 'already claimed';
  end;
  insert into guild_coin_wallets (user_id, balance)
    values (v_uid, guild_quest_reward(p_tier))
    on conflict (user_id) do update
      set balance = guild_coin_wallets.balance + excluded.balance
    returning balance into v_bal;
  return v_bal;
end;
$$;

create or replace function guild_buy_item(p_item text) returns bigint
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_price integer := guild_item_price(p_item);
  v_bal bigint;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if v_price is null then raise exception 'invalid item'; end if;
  if not exists (select 1 from guild_members where user_id = v_uid) then
    raise exception 'not in guild';
  end if;
  if exists (select 1 from guild_purchases
             where user_id = v_uid and item_id = p_item) then
    raise exception 'already owned';
  end if;
  select balance into v_bal from guild_coin_wallets
    where user_id = v_uid for update;
  if coalesce(v_bal, 0) < v_price then raise exception 'not enough coins'; end if;
  update guild_coin_wallets set balance = balance - v_price
    where user_id = v_uid returning balance into v_bal;
  insert into guild_purchases (user_id, item_id) values (v_uid, p_item);
  return v_bal;
end;
$$;

-- Mua buff thu nhập cho CẢ HỘI (ai trong hội cũng hưởng khi buff còn hạn).
create or replace function guild_buy_buff() returns bigint
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_g guilds%rowtype;
  v_bal bigint;
  v_from timestamptz;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select g.* into v_g from guilds g
    join guild_members m on m.guild_id = g.id where m.user_id = v_uid for update of g;
  if not found then raise exception 'not in guild'; end if;
  v_from := greatest(coalesce(v_g.buff_until, now()), now());
  if v_from > now() + make_interval(hours => guild_buff_max_hours() - guild_buff_hours())
  then
    raise exception 'buff maxed';
  end if;
  select balance into v_bal from guild_coin_wallets
    where user_id = v_uid for update;
  if coalesce(v_bal, 0) < guild_buff_price() then
    raise exception 'not enough coins';
  end if;
  update guild_coin_wallets set balance = balance - guild_buff_price()
    where user_id = v_uid returning balance into v_bal;
  update guilds set buff_until = v_from + make_interval(hours => guild_buff_hours())
    where id = v_g.id;
  return v_bal;
end;
$$;

-- Giây buff còn lại của hội mình (0 nếu không có/không ở hội) — client gọi nhẹ khi
-- mở app để áp buff mà không cần mở màn Hội.
create or replace function guild_buff_seconds() returns integer
language plpgsql stable security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_until timestamptz;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select g.buff_until into v_until from guilds g
    join guild_members m on m.guild_id = g.id where m.user_id = v_uid;
  return greatest(extract(epoch from (coalesce(v_until, now()) - now()))::integer, 0);
end;
$$;

-- Chat hội. Chỉ thành viên đọc/ghi. Chống spam: tối đa 3 tin/10 giây/người; lọc từ cấm
-- như tên hội. ponytail: không realtime — client kéo-để-tải + tải lại sau khi gửi.
create or replace function guild_chat_post(p_body text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_gid uuid;
  v_nick text;
  -- Cắt MỌI khoảng trắng (cả xuống dòng/tab) và ký tự rộng-0, không chỉ dấu cách.
  v_body text := regexp_replace(coalesce(p_body, ''),
    '^[[:space:]' || chr(8203) || ']+|[[:space:]' || chr(8203) || ']+$', '', 'g');
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select guild_id, nickname into v_gid, v_nick from guild_members where user_id = v_uid;
  if v_gid is null then raise exception 'not found'; end if;
  if char_length(v_body) not between 1 and 200 then raise exception 'invalid input'; end if;
  if not guild_text_ok(v_body) then raise exception 'text blocked'; end if;
  if (select count(*) from guild_messages
        where user_id = v_uid and created_at > now() - interval '10 seconds') >= 3 then
    raise exception 'chat rate limited';
  end if;
  insert into guild_messages (guild_id, user_id, nickname, body)
  values (v_gid, v_uid, v_nick, v_body);
  delete from guild_messages where guild_id = v_gid and id <=
    (select id from guild_messages where guild_id = v_gid
       order by id desc offset 200 limit 1);
end;
$$;

create or replace function guild_chat_list(p_limit integer default 50) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_gid uuid;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select guild_id into v_gid from guild_members where user_id = v_uid;
  if v_gid is null then raise exception 'not found'; end if;
  return jsonb_build_object(
    'pinned', (select jsonb_build_object('id', id, 'user_id', user_id,
        'nickname', nickname, 'body', body, 'created_at', created_at)
        from guild_messages where guild_id = v_gid and pinned and not hidden
          and not exists (select 1 from guild_message_reports r
                            where r.message_id = guild_messages.id and r.reporter_id = v_uid)
        order by id desc limit 1),
    'messages', coalesce((select jsonb_agg(m order by (m->>'id')::bigint desc) from (
        select jsonb_build_object('id', id, 'user_id', user_id, 'nickname', nickname,
               'body', body, 'created_at', created_at) as m
        from guild_messages where guild_id = v_gid and not hidden
          and not exists (select 1 from guild_message_reports r
                            where r.message_id = guild_messages.id and r.reporter_id = v_uid)
        order by id desc limit least(greatest(coalesce(p_limit, 50), 1), 100)) s),
      '[]'::jsonb));
end;
$$;

-- Xoá: tác giả hoặc chủ hội.
create or replace function guild_chat_delete(p_id bigint) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_gid uuid;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select guild_id into v_gid from guild_members where user_id = v_uid;
  if v_gid is null then raise exception 'not found'; end if;
  delete from guild_messages m where m.id = p_id and m.guild_id = v_gid
    and (m.user_id = v_uid
         or exists (select 1 from guilds g where g.id = v_gid and g.owner_id = v_uid));
  if not found then raise exception 'not found'; end if;
end;
$$;

-- Ghim: chỉ chủ hội; p_id null = bỏ ghim. Mỗi hội chỉ 1 tin ghim.
create or replace function guild_chat_pin(p_id bigint) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_gid uuid;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select m.guild_id into v_gid from guild_members m
    join guilds g on g.id = m.guild_id
    where m.user_id = v_uid and g.owner_id = v_uid;
  if v_gid is null then raise exception 'not owner'; end if;
  update guild_messages set pinned = false where guild_id = v_gid and pinned;
  if p_id is not null then
    update guild_messages set pinned = true
      where id = p_id and guild_id = v_gid and not hidden;
    if not found then raise exception 'not found'; end if;
  end if;
end;
$$;

-- Báo cáo tin: chỉ thành viên cùng hội, không báo cáo tin của mình; mỗi người 1 lần/tin.
-- Đủ 3 người báo cáo → tin bị ẩn với cả hội; người báo cáo không còn thấy tin đó.
create or replace function guild_chat_report(p_id bigint) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_gid uuid;
  v_author uuid;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select guild_id into v_gid from guild_members where user_id = v_uid;
  if v_gid is null then raise exception 'not found'; end if;
  select user_id into v_author from guild_messages where id = p_id and guild_id = v_gid;
  if not found then raise exception 'not found'; end if;
  if v_author = v_uid then raise exception 'invalid input'; end if;
  insert into guild_message_reports (message_id, reporter_id) values (p_id, v_uid)
    on conflict do nothing;
  if (select count(*) from guild_message_reports where message_id = p_id) >= 3 then
    update guild_messages set hidden = true, pinned = false where id = p_id;
  end if;
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
    'guild_report(uuid,text)', 'guild_claim_reward(integer)',
    'guild_leaderboard_avg(integer)', 'guild_leaderboard_streak(integer)',
    'guild_donate(integer)', 'guild_claim_quest(integer)',
    'guild_buy_item(text)', 'guild_buy_buff()', 'guild_buff_seconds()',
    'guild_chat_post(text)', 'guild_chat_list(integer)',
    'guild_chat_delete(bigint)', 'guild_chat_pin(bigint)',
    'guild_chat_report(bigint)'
  ] loop
    execute format('revoke all on function %s from public', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- Hàm nội bộ: client KHÔNG được gọi trực tiếp (Supabase mặc định cấp execute cho
-- anon/authenticated với hàm mới nên phải thu hồi rõ ràng) — nếu không ai cũng
-- ghi được lịch sử điểm tuần của hội để nâng chuỗi.
revoke all on function guild_log_week(uuid, date, bigint)
  from public, anon, authenticated;
