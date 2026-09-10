-- Schema cho chế độ "Đấu Trường" (Arena PvP) — xem PROPOSAL_ARENA_PVP.md.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor →
-- Run. Idempotent (dùng "if not exists"/"or replace") nên chạy lại nhiều lần
-- vẫn an toàn.
--
-- Nguyên tắc bảo mật: client KHÔNG được insert/update/delete trực tiếp vào
-- bất kỳ bảng nào ở đây (chỉ có policy SELECT). Mọi thay đổi trạng thái đi
-- qua các function "security definer" bên dưới — function chạy với quyền
-- chủ sở hữu (bỏ qua RLS), còn client chỉ gọi qua `.rpc(...)`.
--
-- ⚠️ Giá mốc nâng cấp (20 / 80 / 200) và luật ×2 tapValue mỗi mốc phải khớp
-- với `lib/arena/arena_rules.dart` phía Flutter — đổi một bên thì đổi cả hai.

create extension if not exists pgcrypto;

-- ─────────────────────────────────────────────────────────────────────────
-- Bảng
-- ─────────────────────────────────────────────────────────────────────────

create table if not exists arena_queue (
  player_id  uuid primary key references auth.users(id) on delete cascade,
  joined_at  timestamptz not null default now()
);

create table if not exists arena_matches (
  id          uuid primary key default gen_random_uuid(),
  player_a    uuid not null references auth.users(id) on delete cascade,
  player_b    uuid not null references auth.users(id) on delete cascade,
  status      text not null default 'active' check (status in ('active', 'finished')),
  started_at  timestamptz not null default now(),
  ends_at     timestamptz not null default (now() + interval '60 seconds'),
  score_a     numeric not null default 0,
  score_b     numeric not null default 0,
  winner      uuid references auth.users(id),
  created_at  timestamptz not null default now()
);

create table if not exists arena_actions (
  id         bigint generated always as identity primary key,
  match_id   uuid not null references arena_matches(id) on delete cascade,
  player_id  uuid not null references auth.users(id) on delete cascade,
  kind       text not null check (kind in ('tap', 'buy_tier_1', 'buy_tier_2', 'buy_tier_3')),
  at         timestamptz not null default now()
);

create index if not exists arena_actions_match_idx on arena_actions (match_id);

-- ─────────────────────────────────────────────────────────────────────────
-- RLS — chỉ đọc, đúng phạm vi của mình / trận của mình. Không có policy ghi
-- nào cho client (insert/update/delete) — mọi ghi đi qua function bên dưới.
-- ─────────────────────────────────────────────────────────────────────────

alter table arena_queue enable row level security;
alter table arena_matches enable row level security;
alter table arena_actions enable row level security;

drop policy if exists arena_queue_select_own on arena_queue;
create policy arena_queue_select_own on arena_queue
  for select using (player_id = auth.uid());

drop policy if exists arena_matches_select_own on arena_matches;
create policy arena_matches_select_own on arena_matches
  for select using (auth.uid() in (player_a, player_b));

-- Cho phép người tham gia trận thấy TOÀN BỘ log hành động của trận (kể cả của
-- đối thủ) — cần để client tự tính điểm đối thủ theo thời gian thực bằng
-- `arena_rules.dart` mà không cần lộ endpoint riêng.
drop policy if exists arena_actions_select_match on arena_actions;
create policy arena_actions_select_match on arena_actions
  for select using (
    exists (
      select 1 from arena_matches m
      where m.id = arena_actions.match_id
        and auth.uid() in (m.player_a, m.player_b)
    )
  );

-- ─────────────────────────────────────────────────────────────────────────
-- Luật tính điểm (khớp arena_rules.dart) — dùng chung cho check lúc mua mốc
-- và lúc chốt trận, tránh 2 nơi tính lệch nhau.
-- ─────────────────────────────────────────────────────────────────────────

create or replace function arena_compute_score(p_match_id uuid, p_player uuid)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  a record;
  tap_value numeric := 1;
  money numeric := 0;
begin
  for a in
    select kind from arena_actions
    where match_id = p_match_id and player_id = p_player
    order by at, id
  loop
    if a.kind = 'tap' then
      money := money + tap_value;
    elsif a.kind = 'buy_tier_1' and money >= 20 then
      money := money - 20; tap_value := tap_value * 2;
    elsif a.kind = 'buy_tier_2' and money >= 80 then
      money := money - 80; tap_value := tap_value * 2;
    elsif a.kind = 'buy_tier_3' and money >= 200 then
      money := money - 200; tap_value := tap_value * 2;
    end if;
    -- Hành động không đủ tiền tại thời điểm replay (lẽ ra đã bị chặn lúc
    -- submit) bị bỏ qua thay vì làm hỏng cả phép tính — xem ghi chú CLAUDE.md
    -- "không giả định, không crash vì 1 dòng log bất thường".
  end loop;
  return money;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- Ghép trận: idempotent — gọi lại nhiều lần vẫn an toàn (client poll ~2s/lần
-- tới khi có match). Xem PROPOSAL_ARENA_PVP.md §10 cho lý do không dùng
-- pg_cron/Edge Function riêng.
-- ─────────────────────────────────────────────────────────────────────────

create or replace function arena_join_queue()
returns arena_matches
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  opponent uuid;
  m arena_matches;
  sa numeric;
  sb numeric;
begin
  if me is null then
    raise exception 'not authenticated';
  end if;

  -- Đã có trận active? trả lại luôn (kể cả trận vừa được người khác ghép hộ
  -- mình — xem giải thích race condition trong PROPOSAL) — NHƯNG chỉ nếu
  -- trận đó còn thời gian thật. Nếu `ends_at` đã qua mà chưa ai chốt (VD cả
  -- 2 bên thoát app giữa trận), tự chốt nó ở đây rồi rơi xuống ghép trận MỚI
  -- — tránh kẹt người chơi trong 1 trận ma mỗi lần họ mở lại Đấu Trường.
  select * into m from arena_matches
    where status = 'active' and me in (player_a, player_b)
    order by created_at desc limit 1;
  if found then
    if m.ends_at > now() then
      return m;
    end if;
    sa := arena_compute_score(m.id, m.player_a);
    sb := arena_compute_score(m.id, m.player_b);
    update arena_matches set
      status = 'finished',
      score_a = sa,
      score_b = sb,
      winner = case when sa > sb then m.player_a
                    when sb > sa then m.player_b
                    else null end
    where id = m.id;
    -- không return — rơi xuống logic ghép trận mới bên dưới.
  end if;

  insert into arena_queue (player_id) values (me)
    on conflict (player_id) do nothing;

  select player_id into opponent from arena_queue
    where player_id <> me
    order by joined_at
    for update skip locked
    limit 1;

  if opponent is null then
    return null; -- vẫn đang chờ, client tự gọi lại sau
  end if;

  delete from arena_queue where player_id in (me, opponent);

  insert into arena_matches (player_a, player_b) values (me, opponent)
  returning * into m;

  return m;
end;
$$;

grant execute on function arena_join_queue() to authenticated;

-- Rời hàng đợi (bấm "huỷ" lúc đang chờ ghép).
create or replace function arena_leave_queue()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from arena_queue where player_id = auth.uid();
end;
$$;

grant execute on function arena_leave_queue() to authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- Ghi hành động trong trận — nơi DUY NHẤT client được phép tạo dữ liệu.
-- ─────────────────────────────────────────────────────────────────────────

create or replace function arena_submit_action(p_match_id uuid, p_kind text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  m arena_matches;
  recent_taps int;
  needed numeric;
  already_bought boolean;
begin
  if me is null then
    raise exception 'not authenticated';
  end if;

  select * into m from arena_matches where id = p_match_id for update;
  if not found then
    raise exception 'match not found';
  end if;
  if me not in (m.player_a, m.player_b) then
    raise exception 'not a participant';
  end if;
  if m.status <> 'active' then
    raise exception 'match not active';
  end if;
  if now() >= m.ends_at then
    raise exception 'match time is up';
  end if;

  if p_kind = 'tap' then
    -- Rate-limit thô (chặn bot/script đơn giản, không phải chống cheat cấp cao).
    select count(*) into recent_taps from arena_actions
      where match_id = p_match_id and player_id = me
        and kind = 'tap' and at > now() - interval '1 second';
    if recent_taps >= 12 then
      raise exception 'rate limited';
    end if;

  elsif p_kind in ('buy_tier_1', 'buy_tier_2', 'buy_tier_3') then
    select exists(
      select 1 from arena_actions
      where match_id = p_match_id and player_id = me and kind = p_kind
    ) into already_bought;
    if already_bought then
      raise exception 'tier already bought';
    end if;

    needed := case p_kind
      when 'buy_tier_1' then 20
      when 'buy_tier_2' then 80
      when 'buy_tier_3' then 200
    end;
    if arena_compute_score(p_match_id, me) < needed then
      raise exception 'not enough score for %', p_kind;
    end if;

  else
    raise exception 'unknown action kind: %', p_kind;
  end if;

  insert into arena_actions (match_id, player_id, kind) values (p_match_id, me, p_kind);
end;
$$;

grant execute on function arena_submit_action(uuid, text) to authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- Chốt trận — idempotent, ai gọi trước cũng được (cả 2 client đều tự gọi khi
-- đồng hồ về 0, không cần cron).
-- ─────────────────────────────────────────────────────────────────────────

create or replace function arena_resolve_match(p_match_id uuid)
returns arena_matches
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  m arena_matches;
  sa numeric;
  sb numeric;
begin
  select * into m from arena_matches where id = p_match_id for update;
  if not found then
    raise exception 'match not found';
  end if;
  if me not in (m.player_a, m.player_b) then
    raise exception 'not a participant';
  end if;
  if m.status = 'finished' then
    return m; -- đã chốt rồi, trả lại kết quả cũ thay vì lỗi
  end if;
  if now() < m.ends_at then
    raise exception 'match not finished yet';
  end if;

  sa := arena_compute_score(p_match_id, m.player_a);
  sb := arena_compute_score(p_match_id, m.player_b);

  update arena_matches set
    status = 'finished',
    score_a = sa,
    score_b = sb,
    winner = case when sa > sb then m.player_a
                  when sb > sa then m.player_b
                  else null end
  where id = p_match_id
  returning * into m;

  return m;
end;
$$;

grant execute on function arena_resolve_match(uuid) to authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- Realtime: client dùng `.stream()` (Postgres Changes) để theo dõi
-- `arena_actions` trực tiếp — cần bảng này nằm trong publication
-- `supabase_realtime`. Khối dưới idempotent (bỏ qua nếu đã bật sẵn).
-- ─────────────────────────────────────────────────────────────────────────

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'arena_actions'
  ) then
    alter publication supabase_realtime add table arena_actions;
  end if;
end $$;

-- ─────────────────────────────────────────────────────────────────────────
-- ⚠️ 1 BƯỚC KHÔNG LÀM ĐƯỢC BẰNG SQL — bật thủ công trong Dashboard:
-- Authentication → Sign In / Providers → bật "Allow anonymous sign-ins".
-- Thiếu bước này thì `signInAnonymously()` phía app sẽ báo lỗi và không vào
-- được Đấu Trường (xem ArenaRepository.ensureSignedIn).
-- ─────────────────────────────────────────────────────────────────────────
