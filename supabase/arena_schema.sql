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
--
-- ⚠️ Dạng 'blocks' (Xếp khối): bảng khối, kích thước 10x20 và bảng điểm 1/3/5/8
-- phải khớp `lib/arena/block_rules.dart`. Vector vàng dùng chung 2 phía ở cuối file.

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

-- Dạng PK (2026-09-26): 'tap' = đua chạm (mặc định, cũ), 'blocks' = Xếp khối.
-- `seq` = chuỗi khối chung của trận blocks (mỗi số 0..6 = I,O,T,S,Z,J,L); khối
-- thứ n của mỗi người chơi là seq[n]. `rot`/`col` chỉ dùng cho hành động 'drop'.
alter table arena_queue   add column if not exists mode text not null default 'tap';
alter table arena_matches add column if not exists mode text not null default 'tap';
alter table arena_matches add column if not exists seq  smallint[];
alter table arena_actions add column if not exists rot  smallint;
alter table arena_actions add column if not exists col  smallint;

-- check của `kind` là ràng buộc không tên khi tạo bảng → tên tự sinh mặc định.
alter table arena_actions drop constraint if exists arena_actions_kind_check;
alter table arena_actions add constraint arena_actions_kind_check
  check (kind in ('tap', 'buy_tier_1', 'buy_tier_2', 'buy_tier_3', 'drop'));

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

-- ─────────────────────────────────────────────────────────────────────────
-- Dạng 'blocks' (Xếp khối) — khớp lib/arena/block_rules.dart.
-- Không có trọng lực theo thời gian: mỗi hành động 'drop' = (rot, col); khối
-- rơi thẳng xuống điểm thấp nhất. Bảng = 20 số nguyên 10-bit (hàng 1 ở TRÊN
-- cùng), bit x = cột x. Bảng hướng xoay được SINH TỪ block_rules.dart.
-- ─────────────────────────────────────────────────────────────────────────

-- Bề ngang từng hướng, chỉ số = piece*4 + rot (0..27).
create or replace function arena_blocks_width_of(p_idx int)
returns int
language sql
immutable
as $$
  select (('[4,1,4,1,2,2,2,2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,2]'::jsonb) ->> p_idx)::int;
$$;

create or replace function arena_blocks_fits(p_board int[], p_shape jsonb, p_col int, p_top int)
returns boolean
language plpgsql
immutable
as $$
declare
  h int := jsonb_array_length(p_shape);
  i int;
begin
  if p_top + h > 20 then
    return false;
  end if;
  for i in 0..h - 1 loop
    if (p_board[p_top + i + 1] & ((p_shape ->> i)::int << p_col)) <> 0 then
      return false;
    end if;
  end loop;
  return true;
end;
$$;

-- Hàm THUẦN (không đọc bảng) để có thể test trực tiếp bằng vector vàng.
create or replace function arena_blocks_replay(p_seq smallint[], p_rots int[], p_cols int[])
returns int
language plpgsql
immutable
set search_path = public
as $$
declare
  shapes constant jsonb := '[[15],[1,1,1,1],[15],[1,1,1,1],[3,3],[3,3],[3,3],[3,3],[2,7],[1,3,1],[7,2],[2,3,2],[6,3],[1,3,2],[6,3],[1,3,2],[3,6],[2,3,1],[3,6],[2,3,1],[1,7],[3,1,1],[7,4],[2,2,3],[4,7],[1,1,3],[7,1],[3,2,2]]';
  board int[] := array_fill(0, array[20]);
  kept int[];
  score int := 0;
  total int := coalesce(array_length(p_rots, 1), 0);
  seqlen int := coalesce(array_length(p_seq, 1), 0);
  idx int;
  sh jsonb;
  h int;
  w int;
  c int;
  top int;
  i int;
  r int;
  cleared int;
  n int;
begin
  for n in 1..least(total, seqlen) loop
    -- Hành động sai (thiếu rot/col, ngoài biên) vẫn TIÊU một khối nhưng không
    -- có tác dụng — khớp block_rules.dart.
    if p_rots[n] is null or p_cols[n] is null
       or p_rots[n] not between 0 and 3
       or p_seq[n] not between 0 and 6 then
      continue;
    end if;
    idx := p_seq[n] * 4 + p_rots[n];
    sh := shapes -> idx;
    h := jsonb_array_length(sh);
    w := arena_blocks_width_of(idx);
    c := p_cols[n];
    if c < 0 or c > 10 - w then
      continue;
    end if;

    -- Không đặt được ngay hàng trên cùng = tràn: ngừng ghi điểm.
    if not arena_blocks_fits(board, sh, c, 0) then
      exit;
    end if;
    top := 0;
    while arena_blocks_fits(board, sh, c, top + 1) loop
      top := top + 1;
    end loop;

    for i in 0..h - 1 loop
      board[top + i + 1] := board[top + i + 1] | ((sh ->> i)::int << c);
    end loop;

    kept := '{}';
    cleared := 0;
    for r in 1..20 loop
      if board[r] = 1023 then
        cleared := cleared + 1;
      else
        kept := kept || board[r];
      end if;
    end loop;
    if cleared > 0 then
      board := array_fill(0, array[cleared]) || kept;
      score := score + (array[0, 1, 3, 5, 8])[cleared + 1];
    end if;
  end loop;
  return score;
end;
$$;

grant execute on function arena_blocks_replay(smallint[], int[], int[]) to authenticated;

create or replace function arena_compute_score_blocks(p_match_id uuid, p_player uuid)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  seqarr smallint[];
  rots int[];
  cols int[];
begin
  select seq into seqarr from arena_matches where id = p_match_id;
  select coalesce(array_agg(rot::int order by at, id), '{}'),
         coalesce(array_agg(col::int order by at, id), '{}')
    into rots, cols
    from arena_actions
    where match_id = p_match_id and player_id = p_player and kind = 'drop';
  return arena_blocks_replay(seqarr, rots, cols);
end;
$$;

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
  m_mode text;
begin
  select mode into m_mode from arena_matches where id = p_match_id;
  if m_mode = 'blocks' then
    return arena_compute_score_blocks(p_match_id, p_player);
  end if;

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

-- Đổi chữ ký hàm: bỏ bản không tham số để lời gọi `arena_join_queue()` của client
-- cũ (không truyền p_mode) rơi vào bản mới qua giá trị mặc định 'tap', thay vì
-- mơ hồ giữa 2 overload.
drop function if exists arena_join_queue();

create or replace function arena_join_queue(p_mode text default 'tap')
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
  if p_mode not in ('tap', 'blocks') then
    raise exception 'unknown mode: %', p_mode;
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

  -- Đổi dạng khi đang có dòng chờ cũ → cập nhật dạng (joined_at giữ nguyên).
  insert into arena_queue (player_id, mode) values (me, p_mode)
    on conflict (player_id) do update set mode = excluded.mode;

  select player_id into opponent from arena_queue
    where player_id <> me and mode = p_mode
    order by joined_at
    for update skip locked
    limit 1;

  if opponent is null then
    return null; -- vẫn đang chờ, client tự gọi lại sau
  end if;

  delete from arena_queue where player_id in (me, opponent);

  if p_mode = 'blocks' then
    insert into arena_matches (player_a, player_b, mode, seq)
      values (me, opponent, 'blocks',
              array(select floor(random() * 7)::smallint from generate_series(1, 300)))
      returning * into m;
  else
    insert into arena_matches (player_a, player_b) values (me, opponent)
    returning * into m;
  end if;

  return m;
end;
$$;

grant execute on function arena_join_queue(text) to authenticated;

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

-- Đổi chữ ký (thêm p_rot/p_col): bỏ bản cũ để client cũ (chỉ truyền
-- p_match_id, p_kind) rơi vào bản mới qua giá trị mặc định null.
drop function if exists arena_submit_action(uuid, text);

create or replace function arena_submit_action(
  p_match_id uuid,
  p_kind text,
  p_rot int default null,
  p_col int default null
)
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
  my_drops int;
  next_piece int;
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

  if p_kind = 'drop' then
    if m.mode <> 'blocks' then
      raise exception 'drop is only valid in blocks mode';
    end if;
    if p_rot is null or p_col is null or p_rot not between 0 and 3 then
      raise exception 'invalid drop';
    end if;

    -- Rate-limit thô: người thật khó thả quá ~5 khối/giây.
    select count(*) into recent_taps from arena_actions
      where match_id = p_match_id and player_id = me
        and kind = 'drop' and at > now() - interval '1 second';
    if recent_taps >= 5 then
      raise exception 'rate limited';
    end if;

    select count(*) into my_drops from arena_actions
      where match_id = p_match_id and player_id = me and kind = 'drop';
    if my_drops >= coalesce(array_length(m.seq, 1), 0) then
      raise exception 'no more pieces';
    end if;
    next_piece := m.seq[my_drops + 1];
    if p_col < 0 or p_col > 10 - arena_blocks_width_of(next_piece * 4 + p_rot) then
      raise exception 'column out of range';
    end if;

    insert into arena_actions (match_id, player_id, kind, rot, col)
      values (p_match_id, me, 'drop', p_rot, p_col);
    return;
  end if;

  if m.mode <> 'tap' then
    raise exception 'tap/buy actions are only valid in tap mode';
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

grant execute on function arena_submit_action(uuid, text, int, int) to authenticated;

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

-- ─────────────────────────────────────────────────────────────────────────
-- Vector vàng dạng 'blocks' — PHẢI cho kết quả giống `block_rules_test.dart`.
-- Chạy trong SQL Editor để kiểm tra luật SQL không lệch luật Dart:
--
--   -- (a) 10 khối I dọc ở cột 0..9 xoá 4 hàng cùng lúc  => 8
--   select arena_blocks_replay(
--     array_fill(0::smallint, array[300]),
--     array_fill(1, array[10]),
--     array[0,1,2,3,4,5,6,7,8,9]);
--
--   -- (b) I ngang cột 0, I ngang cột 4, O cột 8 lấp đầy đáy => 1
--   select arena_blocks_replay('{0,0,1}'::smallint[], '{0,0,0}', '{0,4,8}');
--
--   -- (c) 6 khối I dọc chồng một cột => tràn, ngừng tính => 0
--   select arena_blocks_replay(
--     array_fill(0::smallint, array[300]),
--     array_fill(1, array[15]),
--     array[0,0,0,0,0,0,1,2,3,4,5,6,7,8,9]);
-- ─────────────────────────────────────────────────────────────────────────
