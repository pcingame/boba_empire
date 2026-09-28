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
-- ⚠️ Dạng 'match3' (Ghép 3): bảng 8x8, 5 loại, thứ tự rơi/bù ô và bảng điểm phải
-- khớp `lib/arena/match3_rules.dart`. Vector vàng dùng chung 2 phía ở cuối file.

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

-- Dạng PK (2026-09-26): 'tap' = đua chạm (mặc định, cũ), 'match3' = Ghép 3.
-- `seq` = chuỗi ngẫu nhiên chung của trận match3 (mỗi số 0..4 = loại ô): 64 số
-- đầu là bảng đầu, phần còn lại là luồng bù ô của mỗi người chơi.
-- `cell`/`dir` chỉ dùng cho hành động 'swap' (ô 0..63; dir 0 = đổi với ô phải,
-- 1 = ô dưới). `rot`/`col` + kind 'drop' là di sản của bản Xếp khối (Tetris) đã bỏ.
alter table arena_queue   add column if not exists mode text not null default 'tap';
alter table arena_matches add column if not exists mode text not null default 'tap';
alter table arena_matches add column if not exists seq  smallint[];
alter table arena_actions add column if not exists rot  smallint;
alter table arena_actions add column if not exists col  smallint;
alter table arena_actions add column if not exists cell smallint;
alter table arena_actions add column if not exists dir  smallint;

-- check của `kind` là ràng buộc không tên khi tạo bảng → tên tự sinh mặc định.
alter table arena_actions drop constraint if exists arena_actions_kind_check;
alter table arena_actions add constraint arena_actions_kind_check
  check (kind in ('tap', 'buy_tier_1', 'buy_tier_2', 'buy_tier_3', 'drop', 'swap'));

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

-- Dạng Tetris cũ đã bỏ — dọn hàm còn sót (idempotent).
drop function if exists arena_compute_score_blocks(uuid, uuid);
drop function if exists arena_blocks_replay(smallint[], int[], int[]);
drop function if exists arena_blocks_fits(int[], jsonb, int, int);
drop function if exists arena_blocks_width_of(int);

-- ─────────────────────────────────────────────────────────────────────────
-- Dạng 'match3' (Ghép 3) — khớp lib/arena/match3_rules.dart.
-- Bảng 8x8 = mảng 64 số (ô r*8+c ở phần tử r*8+c+1; hàng 0 ở TRÊN), loại 0..4,
-- -1 = ô trống. Hành động 'swap' (cell, dir) đổi ô với hàng xóm phải/dưới; chỉ
-- có hiệu lực nếu tạo dãy >= 3 cùng loại. Dây chuyền: xoá dãy → rơi → bù (cột
-- trái→phải, trong cột từ trên xuống, lấy seq[refill mod len]); điểm mỗi ô xoá =
-- 10 × số bước dây chuyền. Tối đa 150 nước đầu mỗi người.
-- ─────────────────────────────────────────────────────────────────────────

create or replace function arena_m3_marks(b int[])
returns boolean[]
language plpgsql
immutable
as $$
declare
  marked boolean[] := array_fill(false, array[64]);
  r int;
  c int;
  s int;
  k int;
begin
  for r in 0..7 loop
    s := 0;
    for c in 1..8 loop
      if c < 8 and b[r * 8 + c + 1] <> -1 and b[r * 8 + c + 1] = b[r * 8 + s + 1] then
        continue;
      end if;
      if c - s >= 3 and b[r * 8 + s + 1] <> -1 then
        for k in s..c - 1 loop
          marked[r * 8 + k + 1] := true;
        end loop;
      end if;
      s := c;
    end loop;
  end loop;
  for c in 0..7 loop
    s := 0;
    for r in 1..8 loop
      if r < 8 and b[r * 8 + c + 1] <> -1 and b[r * 8 + c + 1] = b[s * 8 + c + 1] then
        continue;
      end if;
      if r - s >= 3 and b[s * 8 + c + 1] <> -1 then
        for k in s..r - 1 loop
          marked[k * 8 + c + 1] := true;
        end loop;
      end if;
      s := r;
    end loop;
  end loop;
  return marked;
end;
$$;

-- Hàm THUẦN (không đọc bảng) để test trực tiếp bằng vector vàng + fuzz.
-- Còn nước đi hợp lệ nào không: thử đổi mọi ô với hàng xóm phải/dưới.
-- Soi gương `Match3Board.hasAnyMove` trong lib/arena/match3_rules.dart.
create or replace function arena_m3_has_move(b int[])
returns boolean
language plpgsql
immutable
set search_path = public
as $$
declare
  i int; other int; v int; tmp int[]; marked boolean[];
begin
  for i in 0..63 loop
    for v in 0..1 loop
      if v = 0 then
        if i % 8 = 7 then continue; end if;
        other := i + 1;
      else
        if i / 8 = 7 then continue; end if;
        other := i + 8;
      end if;
      if b[i + 1] = b[other + 1] then continue; end if;
      tmp := b;
      tmp[i + 1] := b[other + 1];
      tmp[other + 1] := b[i + 1];
      marked := arena_m3_marks(tmp);
      if true = any(marked) then
        return true;
      end if;
    end loop;
  end loop;
  return false;
end;
$$;

grant execute on function arena_m3_has_move(int[]) to authenticated;

-- Xáo lại bàn khi hết nước đi: dựng bàn mới từ phần chuỗi CHƯA dùng, theo đúng
-- luật bảng đầu (không để sẵn dãy 3), thử tối đa 20 lần tới khi có nước đi.
-- Soi gương `Match3Board.reshuffle` trong lib/arena/match3_rules.dart — lệch
-- một ô là bàn client khác bàn server và mọi nước sau bị chấm sai.
create or replace function arena_m3_shuffle(
  b int[], p_seq smallint[], refill int,
  out nb int[], out nrefill int)
language plpgsql
immutable
set search_path = public
as $$
declare
  seqlen int := coalesce(array_length(p_seq, 1), 0);
  t int; i int; r int; c int; v int;
begin
  nb := b;
  nrefill := refill;
  if seqlen = 0 then
    return;
  end if;
  for t in 1..20 loop
    for i in 0..63 loop
      r := i / 8;
      c := i % 8;
      v := p_seq[(nrefill % seqlen) + 1] % 5;
      nrefill := nrefill + 1;
      while (c >= 2 and nb[i] = v and nb[i - 1] = v)
         or (r >= 2 and nb[i - 7] = v and nb[i - 15] = v) loop
        v := (v + 1) % 5;
      end loop;
      nb[i + 1] := v;
    end loop;
    exit when arena_m3_has_move(nb);
  end loop;
end;
$$;

grant execute on function arena_m3_shuffle(int[], smallint[], int) to authenticated;

create or replace function arena_m3_replay(p_seq smallint[], p_cells int[], p_dirs int[])
returns int
language plpgsql
immutable
set search_path = public
as $$
declare
  seqlen int := coalesce(array_length(p_seq, 1), 0);
  total int := coalesce(array_length(p_cells, 1), 0);
  b int[] := array_fill(0, array[64]);
  saved int[];
  marked boolean[];
  empties int[] := array_fill(0, array[8]);
  refill int := 64;
  score int := 0;
  i int;
  r int;
  c int;
  n int;
  t int;
  v int;
  k int;
  w int;
  other int;
  step int;
  cnt int;
begin
  if seqlen = 0 then
    return 0;
  end if;

  -- Bảng đầu: tránh bộ 3 sẵn có bằng cách tăng loại +1 (mod 5).
  for i in 0..63 loop
    r := i / 8;
    c := i % 8;
    t := p_seq[(i % seqlen) + 1] % 5;
    while (c >= 2 and b[i] = t and b[i - 1] = t)
       or (r >= 2 and b[i - 7] = t and b[i - 15] = t) loop
      t := (t + 1) % 5;
    end loop;
    b[i + 1] := t;
  end loop;

  for n in 1..least(total, 150) loop
    -- Nước sai (thiếu cell/dir, ngoài bảng, hai ô cùng loại, không tạo match)
    -- bị bỏ qua — khớp match3_rules.dart.
    if p_cells[n] is null or p_dirs[n] is null
       or p_cells[n] not between 0 and 63
       or p_dirs[n] not between 0 and 1 then
      continue;
    end if;
    i := p_cells[n];
    if p_dirs[n] = 0 then
      if i % 8 = 7 then continue; end if;
      other := i + 1;
    else
      if i / 8 = 7 then continue; end if;
      other := i + 8;
    end if;
    if b[i + 1] = b[other + 1] then
      continue;
    end if;

    saved := b;
    v := b[i + 1];
    b[i + 1] := b[other + 1];
    b[other + 1] := v;
    marked := arena_m3_marks(b);
    if not (true = any(marked)) then
      b := saved;
      continue;
    end if;

    step := 1;
    loop
      marked := arena_m3_marks(b);
      cnt := 0;
      for k in 1..64 loop
        if marked[k] then
          cnt := cnt + 1;
          b[k] := -1;
        end if;
      end loop;
      exit when cnt = 0;
      score := score + cnt * 10 * step;

      -- Rơi: mỗi cột dồn xuống đáy, giữ thứ tự.
      for c in 0..7 loop
        w := 7;
        for r in reverse 7..0 loop
          v := b[r * 8 + c + 1];
          if v <> -1 then
            b[w * 8 + c + 1] := v;
            w := w - 1;
          end if;
        end loop;
        empties[c + 1] := w + 1;
        for r in 0..w loop
          b[r * 8 + c + 1] := -1;
        end loop;
      end loop;

      -- Bù: cột trái→phải, trong cột từ trên xuống.
      for c in 0..7 loop
        for r in 0..empties[c + 1] - 1 loop
          b[r * 8 + c + 1] := p_seq[(refill % seqlen) + 1] % 5;
          refill := refill + 1;
        end loop;
      end loop;
      step := step + 1;
    end loop;

    -- Hết nước đi thì xáo ngay trong nước này — khớp `trySwap` ở Dart, nơi
    -- cũng gọi reshuffle() ở đúng vị trí này.
    if not arena_m3_has_move(b) then
      select nb, nrefill into b, refill
      from arena_m3_shuffle(b, p_seq, refill);
    end if;
  end loop;
  return score;
end;
$$;

grant execute on function arena_m3_replay(smallint[], int[], int[]) to authenticated;

create or replace function arena_compute_score_match3(p_match_id uuid, p_player uuid)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  seqarr smallint[];
  cells int[];
  dirs int[];
begin
  select seq into seqarr from arena_matches where id = p_match_id;
  select coalesce(array_agg(cell::int order by at, id), '{}'),
         coalesce(array_agg(dir::int order by at, id), '{}')
    into cells, dirs
    from arena_actions
    where match_id = p_match_id and player_id = p_player and kind = 'swap';
  return arena_m3_replay(seqarr, cells, dirs);
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
  if m_mode = 'match3' then
    return arena_compute_score_match3(p_match_id, p_player);
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
  if p_mode not in ('tap', 'match3') then
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

  if p_mode = 'match3' then
    insert into arena_matches (player_a, player_b, mode, seq)
      values (me, opponent, 'match3',
              array(select floor(random() * 5)::smallint from generate_series(1, 2000)))
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

-- Đổi chữ ký (thêm p_cell/p_dir): bỏ các bản cũ để client cũ (chỉ truyền
-- p_match_id, p_kind) rơi vào bản mới qua giá trị mặc định null. Bản (uuid, text,
-- int, int) là của Xếp khối (p_rot/p_col) — cùng kiểu tham số nhưng khác tên nên
-- `create or replace` không đè được, phải drop.
drop function if exists arena_submit_action(uuid, text);
drop function if exists arena_submit_action(uuid, text, int, int);

create or replace function arena_submit_action(
  p_match_id uuid,
  p_kind text,
  p_cell int default null,
  p_dir int default null
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
  my_swaps int;
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

  if p_kind = 'swap' then
    if m.mode <> 'match3' then
      raise exception 'swap is only valid in match3 mode';
    end if;
    if p_cell is null or p_dir is null
       or p_cell not between 0 and 63 or p_dir not between 0 and 1
       or (p_dir = 0 and p_cell % 8 = 7) or (p_dir = 1 and p_cell >= 56) then
      raise exception 'invalid swap';
    end if;

    -- Rate-limit thô: người thật khó đi quá ~4 nước/giây (còn hoạt ảnh nữa).
    select count(*) into recent_taps from arena_actions
      where match_id = p_match_id and player_id = me
        and kind = 'swap' and at > now() - interval '1 second';
    if recent_taps >= 4 then
      raise exception 'rate limited';
    end if;

    -- Không replay lúc nộp (sẽ O(n²)): nước vô hiệu chỉ bị replay bỏ qua nên
    -- không giúp gian lận; trần số nước khớp `arena_m3_replay`.
    select count(*) into my_swaps from arena_actions
      where match_id = p_match_id and player_id = me and kind = 'swap';
    if my_swaps >= 150 then
      raise exception 'move limit reached';
    end if;

    insert into arena_actions (match_id, player_id, kind, cell, dir)
      values (p_match_id, me, 'swap', p_cell, p_dir);
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
-- Vector vàng dạng 'match3' — PHẢI cho kết quả giống `match3_rules_test.dart`.
-- Chuỗi LCG hạt giống 12345 (cùng công thức với test Dart). Chạy trong SQL Editor:
--
--   with recursive g(i, x) as (
--     select 1, ((12345::bigint * 1103515245 + 12345) & 2147483647)
--     union all
--     select i + 1, (x * 1103515245 + 12345) & 2147483647 from g where i < 2000
--   )
--   select arena_m3_replay(
--     array(select ((x >> 16) % 5)::smallint from g order by i),
--     array[2,2,9,1,2,2,13,17,3,0,11,8,0,2,10,4,1,11,1,2,10,9,2,0,11],
--     array[0,1,1,0,0,1,0,1,1,0,1,1,0,0,1,1,1,0,1,1,1,1,1,0,0]);
--   -- kỳ vọng: 1260
-- ─────────────────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────────────────
-- Vector vàng cho `arena_m3_shuffle` — PHẢI khớp `Match3Board.reshuffle` ở
-- Dart (test `match3_rules_test.dart`). Đầu vào: bàn BÍ (lát gạch 2x2, không
-- dãy 3 và không nước đi nào), cùng chuỗi LCG 12345, refill = 64 (bằng đúng
-- số ô của bảng đầu). Chạy trong SQL Editor:
--
--   with recursive g(i, x) as (
--     select 1, ((12345::bigint * 1103515245 + 12345) & 2147483647)
--     union all
--     select i + 1, (x * 1103515245 + 12345) & 2147483647 from g where i < 2000
--   )
--   select nb from arena_m3_shuffle(
--     array[
--     0,1,0,1,0,1,0,1,2,3,2,3,2,3,2,3,
--     0,1,0,1,0,1,0,1,2,3,2,3,2,3,2,3,
--     0,1,0,1,0,1,0,1,2,3,2,3,2,3,2,3,
--     0,1,0,1,0,1,0,1,2,3,2,3,2,3,2,3
--     ],
--     array(select ((x >> 16) % 5)::smallint from g order by i),
--     64);
--   -- kỳ vọng nb:
--     [
--     0,0,3,4,2,3,1,4,3,0,0,2,1,1,4,1,
--     2,2,0,3,4,1,0,3,0,3,2,4,1,2,4,4,
--     0,1,4,4,3,1,2,1,1,2,4,0,2,4,4,0,
--     4,4,1,1,3,2,2,3,2,3,3,1,4,3,4,1
--     ]
--   -- và: select arena_m3_has_move(nb) → true
-- ─────────────────────────────────────────────────────────────────────────
