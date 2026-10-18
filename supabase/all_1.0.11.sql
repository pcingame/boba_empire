-- Gộp các schema cho bản 1.0.11. Idempotent. Dán cả file vào Supabase SQL Editor rồi Run.

-- ===== leaderboard_schema.sql =====
-- Schema cho Bảng xếp hạng — xem PROPOSAL_LEADERBOARD.md.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor →
-- Run. Idempotent. Độc lập với arena_schema.sql/cloud_save_schema.sql/
-- analytics_schema.sql — dán trước/sau đều được, không đụng bảng nào khác.
--
-- Khác cloud_save_schema.sql (chỉ chủ mới đọc được hàng của mình): bảng
-- này CỐ Ý cho phép AI CŨNG đọc được TOÀN BỘ hàng — đó chính là mục đích
-- (bảng xếp hạng công khai). Ghi thì vẫn chỉ được ghi đúng hàng của mình
-- (giống cloud_save_schema.sql).
--
-- Danh tính: dùng auth.uid(). TỪ 2026-10-15 chỉ tài khoản đã LIÊN KẾT email (không ẩn danh) mới ghi được
-- (is_linked_user ở dưới) — trước đó mọi phiên kể cả ẩn danh đều nộp được.

create table if not exists leaderboard_entries (
  user_id          uuid primary key references auth.users(id) on delete cascade,
  nickname         text not null check (char_length(nickname) between 1 and 20),
  lifetime_earnings numeric not null default 0 check (lifetime_earnings >= 0),
  prestige_stars   bigint not null default 0 check (prestige_stars >= 0),
  stage            integer not null default 1 check (stage >= 1),
  updated_at       timestamptz not null default now()
);

-- 2026-09-12: prestige_stars từng là `integer` (int4, trần ~2,14 tỷ) — bug
-- thật gặp trên máy: save có ~16,6 tỷ Sao (từ trước khi Balance.prestigeK
-- được giảm) khiến MỌI lần nộp điểm bị Postgres từ chối
-- ("value out of range for type integer"), app luôn rơi vào màn lỗi. Đổi
-- sang bigint (int8, trần ~9,2 tỷ tỷ) khớp kiểu int 64-bit của Dart.
-- ALTER an toàn để chạy lại trên bảng đã tồn tại (CREATE TABLE IF NOT EXISTS
-- ở trên không tự đổi kiểu cột cũ).
--
-- 2026-09-29: bigint CŨNG KHÔNG ĐỦ — cùng một lớp lỗi, lần thứ hai. Sao =
-- k·√lifetime, mà lifetime cuối tuyến đo được trên bảng này đã 1,15e68 → Sao
-- thật ~2e32, vượt xa trần int8 (9,2e18). Phía Dart `.floor()` kẹp im lặng ở
-- int64max nên 77/1184 hàng nộp lên đúng bằng 9223372036854775807 và xếp hạng
-- bằng nhau hết. Đổi sang `numeric` (cùng kiểu với lifetime_earnings, không có
-- trần) và đổi luôn kiểu trong app (GameState.prestigeStars giờ là double).
alter table leaderboard_entries
  alter column prestige_stars type numeric;

create index if not exists leaderboard_entries_lifetime_idx
  on leaderboard_entries (lifetime_earnings desc);

-- Tài khoản hiện tại đã liên kết email (không ẩn danh)? security definer vì vai trò authenticated không
-- đọc được auth.users. ÉP Ở SERVER (không chỉ ở app): ai ghi vào bảng này phải đã liên kết email. Định nghĩa
-- giống hệt ở mọi schema cần nó (create or replace) nên chạy file nào trước cũng được.
create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

alter table leaderboard_entries enable row level security;

-- Đọc: AI CŨNG được — kể cả chưa đăng nhập (anon) — bảng xếp hạng là công khai.
drop policy if exists leaderboard_entries_select_all on leaderboard_entries;
create policy leaderboard_entries_select_all on leaderboard_entries
  for select
  to anon, authenticated
  using (true);

-- Ghi: chỉ đúng hàng của chính mình.
drop policy if exists leaderboard_entries_insert_own on leaderboard_entries;
create policy leaderboard_entries_insert_own on leaderboard_entries
  for insert
  to authenticated
  with check (auth.uid() = user_id and is_linked_user());

drop policy if exists leaderboard_entries_update_own on leaderboard_entries;
create policy leaderboard_entries_update_own on leaderboard_entries
  for update
  to authenticated
  using (auth.uid() = user_id and is_linked_user())
  with check (auth.uid() = user_id and is_linked_user());

-- ─────────────────────────────────────────────────────────────────────────
-- Chống gian lận (2026-09-12): điểm số vốn do CLIENT tự báo, chỉ có RLS
-- kiểm tra "đúng hàng của mình" chứ không kiểm tra SỐ có hợp lý không — ai
-- đó có thể sửa số rồi gửi thẳng lên REST API để leo top (verify được
-- bằng chính curl trong lúc debug bug "vượt trần integer"). Đây là kiểm
-- tra HEURISTIC hợp lý, KHÔNG PHẢI xác thực toán học chặt chẽ như
-- arena_compute_score (Đấu Trường re-play lại log hành động) — nền kinh tế
-- chính (offline earning, IAP, boost...) phức tạp hơn nhiều so với 1 trận
-- Đấu Trường 60 giây, mô phỏng lại đầy đủ trên server không đáng công cho
-- 1 bảng xếp hạng phụ. Mục tiêu chỉ là chặn kiểu gian lận rẻ tiền nhất
-- (tự sửa số gửi lên), chấp nhận rủi ro hiếm gặp báo lỗi nhầm cho người
-- chơi hợp lệ tiến bộ cực nhanh — họ chỉ cần thử nộp lại sau, không bị
-- cấm vĩnh viễn.
--
-- BỎ check "trần tăng trưởng theo thời gian thực trôi qua" (2026-09-12,
-- từng có ở đây, bug thật gặp lại NGAY TRÊN SAVE THẬT của người dùng — báo
-- "Không tải được bảng xếp hạng" liên tục): check đó giả định lifetime_
-- earnings chỉ tăng theo NHỊP LIÊN TỤC (Xu/giây × giây thực trôi qua từ lần
-- nộp trước), nhưng game có `buyGemTimeSkip()` (nút "Tua nhanh" ở Cửa hàng
-- 💎, xem lib/core/simulation.dart) — cộng NGAY LẬP TỨC
-- Balance.gemTimeSkipSeconds (4 giờ) giây sản xuất, KHÔNG GIỚI HẠN số lần
-- mua liên tiếp (chỉ tốn 💎, không có trần/ngày). Một người chơi hợp lệ
-- gom 💎 rồi mua nhiều lần liền tay (y hệt tình huống dev tự test) có thể
-- cộng dồn hàng chục/hàng trăm giờ sản xuất vào lifetime_earnings chỉ
-- trong vài GIÂY THỰC — không có hằng số trần nào vừa đủ rộng để cho phép
-- việc này vừa đủ hẹp để còn ý nghĩa chống gian lận (mua thêm vài lần nữa
-- là lại vượt bất kỳ trần nào). Giữ lại check (1)+(2) — đó là bất biến
-- TOÁN HỌC không phụ thuộc thời gian, không bị phá bởi bất kỳ cách chơi
-- hợp lệ nào (kể cả tua nhanh dồn dập).
create or replace function leaderboard_entries_validate()
returns trigger
language plpgsql
as $$
begin
  -- (1) Bất biến ĐÚNG theo công thức game — không phải suy đoán, xem
  -- starsForLifetimeEarnings() trong lib/core/economy.dart: tổng Sao không
  -- bao giờ vượt quá floor(k * sqrt(lifetime_earnings)).
  --
  -- QUAN TRỌNG: dùng k=0.05 (giá trị GỐC/CAO NHẤT Balance.prestigeK từng
  -- có, trước khi giảm xuống 0.02 ngày 2026-09-12 để làm chậm tốc độ tích
  -- Sao) — KHÔNG dùng giá trị hiện tại. Người chơi cũ đã tích Sao dưới
  -- công thức k cũ (cao hơn) vẫn hợp lệ; nếu dùng k=0.02 làm ngưỡng sẽ
  -- chặn NHẦM chính những save đó (đã xác minh: save thật ~16,6 tỷ Sao của
  -- người dùng suýt bị chặn nhầm nếu dùng k hiện tại). Nếu sau này
  -- Balance.prestigeK từng tăng vượt 0.05, phải nâng hằng số này theo.
  if new.prestige_stars > floor(0.05 * sqrt(new.lifetime_earnings)) then
    raise exception 'prestige_stars vượt quá mức tối đa có thể có với lifetime_earnings này';
  end if;

  -- (2) Trần tuyệt đối — rất rộng rãi, chỉ chặn số bịa chứ không nhằm giới
  -- hạn người chơi thật giỏi (kể cả tua nhanh dồn dập nhiều lần).
  --
  -- 1e100 = Balance.economyOverflowGuardCap (lib/core/balance.dart), tức
  -- KHÔNG thể có số thật nào vượt — trước đây là 1e50, nhưng giai đoạn 13-18
  -- (mở rộng thế giới 2026-09-26) mở khoá ở 5e25..5e35 nên người chơi cuối
  -- tuyến có thể vượt 1e50 và sẽ bị chặn nhầm khi gửi lần đầu. Đổi hằng số
  -- này thì phải xem lại economyOverflowGuardCap và ngược lại.
  if new.lifetime_earnings > 1e100 then
    raise exception 'lifetime_earnings vượt xa mức có thể đạt được';
  end if;

  return new;
end;
$$;

-- Chữa 77 hàng đã bị kẹp trần trước khi sửa (2026-09-29): số Sao của họ đã
-- MẤT thông tin (mọi giá trị ≥ 9,2e18 đều bị ghi thành đúng int64max). Nhưng
-- lifetime_earnings thì vẫn đúng, mà Sao = floor(k·√lifetime) — dựng lại được
-- bằng chính công thức game (k = 0.02 = Balance.prestigeK hiện tại).
--
-- Đây là ƯỚC LƯỢNG TRẦN TRÊN: đúng bằng số Sao họ có NẾU đã Nhượng quyền hết
-- phần tích được. Lần nộp điểm kế tiếp từ app (mở bảng xếp hạng) sẽ ghi đè
-- bằng số thật — mục đích ở đây chỉ là để họ không hiện 0 ⭐ trong lúc chờ.
-- Không xoá cả hàng vì sẽ mất nickname. Chỉ đụng đúng các hàng bị kẹp.
update leaderboard_entries
  set prestige_stars = floor(0.02 * sqrt(lifetime_earnings))
  where prestige_stars >= 9223372036854775807;

drop trigger if exists leaderboard_entries_validate on leaderboard_entries;
create trigger leaderboard_entries_validate
  before insert or update on leaderboard_entries
  for each row execute function leaderboard_entries_validate();

-- Server tự đóng dấu updated_at (không tin đồng hồ client), giống
-- cloud_save_schema.sql.
create or replace function leaderboard_entries_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists leaderboard_entries_set_updated_at on leaderboard_entries;
create trigger leaderboard_entries_set_updated_at
  before insert or update on leaderboard_entries
  for each row execute function leaderboard_entries_set_updated_at();

-- ─────────────────────────────────────────────────────────────────────────
-- "Quanh hạng của bạn": top 50 tuyệt đối gần như chắc chắn không có tên
-- bạn (chưa nhiều người chơi thật) — nhìn 1 danh sách toàn số khổng lồ
-- không liên quan gì tới mình thì nản, không tạo động lực. Trả về
-- [p_window] người TRÊN + chính bạn + [p_window] người DƯỚI, đã kèm sẵn
-- hạng (rank) — 1 câu query bằng window function, rẻ hơn nhiều so với
-- client tự ghép nhiều lượt gọi.
--
-- KHÔNG cần security definer: bảng đã cho phép SELECT công khai
-- (`leaderboard_entries_select_all` ở trên), hàm này chỉ đóng gói lại
-- logic xếp hạng, chạy đúng quyền người gọi là đủ.
-- ─────────────────────────────────────────────────────────────────────────

-- drop trước vì đổi kiểu trả về (prestige_stars integer -> bigint ->
-- numeric 2026-09-29): `create or replace function` từ chối đổi return type
-- của hàm đã tồn tại.
drop function if exists leaderboard_around_me(integer);

create or replace function leaderboard_around_me(p_window integer default 5)
returns table (
  user_id           uuid,
  nickname          text,
  lifetime_earnings numeric,
  prestige_stars    numeric,
  stage             integer,
  rank              bigint
)
language sql
stable
as $$
  with ranked as (
    select
      e.user_id, e.nickname, e.lifetime_earnings, e.prestige_stars, e.stage,
      row_number() over (order by e.lifetime_earnings desc) as rank
    from leaderboard_entries e
  ),
  me as (
    select r.rank from ranked r where r.user_id = auth.uid()
  )
  select ranked.user_id, ranked.nickname, ranked.lifetime_earnings,
         ranked.prestige_stars, ranked.stage, ranked.rank
  from ranked, me
  where ranked.rank between me.rank - p_window and me.rank + p_window
  order by ranked.rank;
$$;

grant execute on function leaderboard_around_me(integer) to authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- Thưởng Kim Cương cho top hạng (2026-09-12) — không gắn với "mùa/tuần"
-- (leaderboard này không reset định kỳ, xem known-issues-backlog memory):
-- thay vì thưởng 1 lần rồi thôi (dần vô nghĩa vì top luôn là cùng vài
-- người), đây là thưởng LẶP LẠI mỗi [reward_cooldown] giờ NẾU vẫn còn giữ
-- hạng đủ cao lúc kiểm tra — top giữ hạng càng lâu thì nhận càng nhiều lần,
-- nhưng phải quay lại đúng nhịp thay vì nhận 1 lần xong bỏ quên.
--
-- KHÔNG cần security definer: bảng đã cho SELECT công khai, và policy
-- update-own-row đã cho phép tự ghi last_reward_claimed_at của chính mình
-- — hàm chạy đúng quyền người gọi là đủ, không cần bypass RLS.
alter table leaderboard_entries
  add column if not exists last_reward_claimed_at timestamptz;

-- Trả về số Kim Cương vừa nhận (0 nếu chưa đủ điều kiện: chưa từng nộp
-- điểm, hạng chưa đủ cao, hoặc còn trong 24h kể từ lần nhận trước). Bậc
-- thưởng: hạng 1 = 100💎, hạng 2-3 = 50💎, hạng 4-10 = 20💎 — PHẢI khớp
-- Balance.leaderboardRewardTiers (lib/core/balance.dart, chỉ dùng để HIỂN
-- THỊ gợi ý trên UI, không phải nguồn thật cấp Kim Cương — đổi 1 bên thì
-- đổi cả hai).
create or replace function leaderboard_claim_reward()
returns integer
language plpgsql
as $$
declare
  my_rank bigint;
  last_claim timestamptz;
  reward integer;
begin
  select r.rank, e.last_reward_claimed_at into my_rank, last_claim
  from (
    select user_id, row_number() over (order by lifetime_earnings desc) as rank
    from leaderboard_entries
  ) r
  join leaderboard_entries e on e.user_id = r.user_id
  where r.user_id = auth.uid();

  if my_rank is null then
    return 0; -- chưa từng nộp điểm lên bảng xếp hạng
  end if;

  if not is_linked_user() then
    return 0; -- chưa liên kết email: không nhận thưởng bảng xếp hạng
  end if;

  if last_claim is not null and now() - last_claim < interval '24 hours' then
    return 0; -- còn trong thời gian chờ giữa 2 lần nhận
  end if;

  reward := case
    when my_rank = 1 then 100
    when my_rank between 2 and 3 then 50
    when my_rank between 4 and 10 then 20
    else 0
  end;

  if reward > 0 then
    update leaderboard_entries
      set last_reward_claimed_at = now()
      where user_id = auth.uid();
  end if;

  return reward;
end;
$$;

grant execute on function leaderboard_claim_reward() to authenticated;

-- ===== m3_leaderboard_schema.sql =====
-- Schema cho "Bảng xếp hạng Trân Châu Rơi" — xếp theo TỔNG SAO của Hành trình
-- (chơi đơn), không phải điểm một màn.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor → Run.
-- Idempotent. Độc lập với các file schema khác, dán trước/sau đều được.
--
-- Vì sao xếp theo TỔNG SAO chứ không theo điểm cao nhất một màn: bàn cờ mỗi màn
-- là TẤT ĐỊNH (ai cũng gặp đúng bàn đó — xem Match3Level.seed), nên "điểm cao
-- nhất" chỉ đo được ai chịu khó chơi lại một màn nhiều lần. Tổng sao đo đúng
-- thứ người chơi thực sự đi được, và có trần rõ ràng nên kiểm tra được.
--
-- Khác story_speedrun (1 mốc, nộp đúng 1 lần): sao TĂNG DẦN theo thời gian nên
-- bảng này cho phép UPDATE hàng của chính mình (upsert mỗi lần mở trang).

create table if not exists m3_leaderboard_entries (
  user_id        uuid primary key references auth.users(id) on delete cascade,
  nickname       text not null check (char_length(nickname) between 1 and 20),
  -- Trần 1500 = 3 sao x 500 màn (trần trên của Balance.m3LevelCount khai báo
  -- trong remote_balance.dart). Không dùng 180 = 3 x 60 vì số màn tune được
  -- qua Remote Config; đặt sát quá là chặn nhầm người chơi thật sau này.
  stars          integer not null check (stars between 0 and 1500),
  levels_cleared integer not null check (levels_cleared between 0 and 500),
  updated_at     timestamptz not null default now(),
  -- Bất biến của luật chơi: mỗi màn tối đa 3 sao, nên tổng sao không bao giờ
  -- vượt 3 lần số màn đã qua. Chặn kiểu gian lận "1 màn, 900 sao".
  constraint m3_stars_le_3x_levels check (stars <= levels_cleared * 3)
);

create index if not exists m3_leaderboard_entries_stars_idx
  on m3_leaderboard_entries (stars desc, updated_at asc);

-- Tài khoản hiện tại đã liên kết email (không ẩn danh)? security definer vì vai trò authenticated không
-- đọc được auth.users. ÉP Ở SERVER (không chỉ ở app): ai ghi vào bảng này phải đã liên kết email. Định nghĩa
-- giống hệt ở mọi schema cần nó (create or replace) nên chạy file nào trước cũng được.
create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

alter table m3_leaderboard_entries enable row level security;

-- Đọc: ai cũng được, kể cả chưa đăng nhập — bảng xếp hạng công khai.
drop policy if exists m3_leaderboard_select_all on m3_leaderboard_entries;
create policy m3_leaderboard_select_all on m3_leaderboard_entries
  for select to anon, authenticated using (true);

-- Ghi: chỉ hàng của chính mình.
drop policy if exists m3_leaderboard_insert_own on m3_leaderboard_entries;
create policy m3_leaderboard_insert_own on m3_leaderboard_entries
  for insert to authenticated with check (auth.uid() = user_id and is_linked_user());

drop policy if exists m3_leaderboard_update_own on m3_leaderboard_entries;
create policy m3_leaderboard_update_own on m3_leaderboard_entries
  for update to authenticated using (auth.uid() = user_id and is_linked_user())
  with check (auth.uid() = user_id and is_linked_user());

-- Sao chỉ được TĂNG. Không có trigger này thì ai đó lỡ chơi bằng save cũ (hoặc
-- xoá app chơi lại) sẽ tự đạp hạng của chính mình xuống.
create or replace function m3_leaderboard_no_downgrade()
returns trigger
language plpgsql
as $$
begin
  if new.stars < old.stars then
    new.stars := old.stars;
    new.levels_cleared := greatest(old.levels_cleared, new.levels_cleared);
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists m3_leaderboard_no_downgrade_trg on m3_leaderboard_entries;
create trigger m3_leaderboard_no_downgrade_trg
  before update on m3_leaderboard_entries
  for each row execute function m3_leaderboard_no_downgrade();

-- Top người nhiều sao nhất. Dùng top tuyệt đối (không phải "quanh hạng của
-- bạn"): số người chơi chế độ này ít hơn nhiều tổng người chơi, và người chưa
-- chơi thì vốn không có hàng nào để "quanh".
create or replace function m3_leaderboard_top(p_limit integer default 50)
returns table (
  user_id        uuid,
  nickname       text,
  stars          integer,
  levels_cleared integer,
  updated_at     timestamptz,
  rank           bigint
)
language sql
stable
as $$
  select user_id, nickname, stars, levels_cleared, updated_at,
         row_number() over (order by stars desc, updated_at asc) as rank
  from m3_leaderboard_entries
  order by stars desc, updated_at asc
  limit p_limit;
$$;

grant execute on function m3_leaderboard_top(integer) to anon, authenticated;

-- ===== accessory_leaderboard_schema.sql =====
-- Schema cho "Bảng xếp hạng Sưu tập" — xếp theo SỐ PHỤ KIỆN KHÁC NHAU đã có
-- (xem lib/core/accessories.dart).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor → Run.
-- Idempotent. Độc lập với các file schema khác, dán trước/sau đều được.
--
-- Cùng khuôn m3_leaderboard_schema.sql: owned_count TĂNG DẦN theo thời gian
-- (phụ kiện không mất được, chỉ có thêm — xem grantAccessory, không cho xoá)
-- nên cho phép UPDATE hàng của chính mình (upsert mỗi lần mở trang), và có
-- trigger chặn hạ cấp.

create table if not exists accessory_leaderboard_entries (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  nickname     text not null check (char_length(nickname) between 1 and 20),
  -- Trần = số phụ kiện tối đa trong danh mục (`accessories.dart`,
  -- `accessories.length`, hiện 160 + ~40 món độc quyền lễ hội/hội cũng được tính). Trần đặt 500 để mở rộng danh mục không phải
  -- sửa lại; ràng buộc cũ (50/200) được nâng bằng ALTER ở dưới cho bảng đã tồn tại.
  owned_count  integer not null check (owned_count between 0 and 500),
  updated_at   timestamptz not null default now()
);

-- Bảng đã tạo từ trước có CHECK ≤ 200: bỏ rồi tạo lại với trần 500 (idempotent).
alter table accessory_leaderboard_entries
  drop constraint if exists accessory_leaderboard_entries_owned_count_check;
alter table accessory_leaderboard_entries
  add constraint accessory_leaderboard_entries_owned_count_check
  check (owned_count between 0 and 500);

create index if not exists accessory_leaderboard_entries_count_idx
  on accessory_leaderboard_entries (owned_count desc, updated_at asc);

-- Tài khoản hiện tại đã liên kết email (không ẩn danh)? security definer vì vai trò authenticated không
-- đọc được auth.users. ÉP Ở SERVER (không chỉ ở app): ai ghi vào bảng này phải đã liên kết email. Định nghĩa
-- giống hệt ở mọi schema cần nó (create or replace) nên chạy file nào trước cũng được.
create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

alter table accessory_leaderboard_entries enable row level security;

-- Đọc: ai cũng được, kể cả chưa đăng nhập — bảng xếp hạng công khai.
drop policy if exists accessory_leaderboard_select_all on accessory_leaderboard_entries;
create policy accessory_leaderboard_select_all on accessory_leaderboard_entries
  for select to anon, authenticated using (true);

-- Ghi: chỉ hàng của chính mình.
drop policy if exists accessory_leaderboard_insert_own on accessory_leaderboard_entries;
create policy accessory_leaderboard_insert_own on accessory_leaderboard_entries
  for insert to authenticated with check (auth.uid() = user_id and is_linked_user());

drop policy if exists accessory_leaderboard_update_own on accessory_leaderboard_entries;
create policy accessory_leaderboard_update_own on accessory_leaderboard_entries
  for update to authenticated using (auth.uid() = user_id and is_linked_user())
  with check (auth.uid() = user_id and is_linked_user());

-- owned_count chỉ được TĂNG — chặn tự đạp hạng khi chơi lại bằng save cũ.
create or replace function accessory_leaderboard_no_downgrade()
returns trigger
language plpgsql
as $$
begin
  if new.owned_count < old.owned_count then
    new.owned_count := old.owned_count;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists accessory_leaderboard_no_downgrade_trg on accessory_leaderboard_entries;
create trigger accessory_leaderboard_no_downgrade_trg
  before update on accessory_leaderboard_entries
  for each row execute function accessory_leaderboard_no_downgrade();

-- Top người sưu tập nhiều nhất (top tuyệt đối, không "quanh hạng của bạn").
create or replace function accessory_leaderboard_top(p_limit integer default 50)
returns table (
  user_id      uuid,
  nickname     text,
  owned_count  integer,
  updated_at   timestamptz,
  rank         bigint
)
language sql
stable
as $$
  select user_id, nickname, owned_count, updated_at,
         row_number() over (order by owned_count desc, updated_at asc) as rank
  from accessory_leaderboard_entries
  order by owned_count desc, updated_at asc
  limit p_limit;
$$;

grant execute on function accessory_leaderboard_top(integer) to anon, authenticated;

-- ===== recipe_leaderboard_schema.sql =====
-- Schema cho "Bảng xếp hạng Thợ pha chế" — xếp theo SỐ MÓN CÔNG THỨC ĐÃ TỪNG ĐẠT BẬC "THẠO"
-- (xem lib/core/recipe_mastery.dart: recipeMasteredEver, đếm theo `best` nên chỉ tăng).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor → Run. Idempotent. Chạy TRƯỚC
-- leaderboard_rewards_schema.sql (bảng này là nguồn của bảng thưởng "recipes").
--
-- Cùng khuôn accessory_leaderboard_schema.sql: số lượng TĂNG DẦN theo thời gian nên cho UPDATE hàng của
-- chính mình (upsert mỗi lần mở trang), có trigger chặn hạ cấp.
--
-- ⚠️ Chống gian lận: giá trị do client tự khai (như các bảng khác). Ràng buộc có thể kiểm: 0..100 (số món
-- trong danh mục), chỉ tăng. Chưa kiểm được "đạt Thạo mất ≥ 4 ngày" ở server vì không biết ngày người
-- chơi bắt đầu luyện; chỉ tài khoản đã liên kết email mới được vào ảnh chụp thưởng tuần (xem
-- leaderboard_rewards_schema.sql).

create table if not exists recipe_leaderboard_entries (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  nickname   text not null check (char_length(nickname) between 1 and 20),
  -- Trần 100 = số món trong assets/recipes/recipes.json (đã có sẵn cả 5 nhóm, mở dần từng nhóm).
  mastered   integer not null check (mastered between 0 and 100),
  updated_at timestamptz not null default now()
);

create index if not exists recipe_leaderboard_entries_idx
  on recipe_leaderboard_entries (mastered desc, updated_at asc);

-- Tài khoản hiện tại đã liên kết email (không ẩn danh)? security definer vì vai trò authenticated không
-- đọc được auth.users. ÉP Ở SERVER (không chỉ ở app): ai ghi vào bảng này phải đã liên kết email. Định nghĩa
-- giống hệt ở mọi schema cần nó (create or replace) nên chạy file nào trước cũng được.
create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

alter table recipe_leaderboard_entries enable row level security;

-- Đọc: ai cũng được, kể cả chưa đăng nhập — bảng xếp hạng công khai.
drop policy if exists recipe_leaderboard_select_all on recipe_leaderboard_entries;
create policy recipe_leaderboard_select_all on recipe_leaderboard_entries
  for select to anon, authenticated using (true);

-- Ghi: chỉ hàng của chính mình.
drop policy if exists recipe_leaderboard_insert_own on recipe_leaderboard_entries;
create policy recipe_leaderboard_insert_own on recipe_leaderboard_entries
  for insert to authenticated with check (auth.uid() = user_id and is_linked_user());

drop policy if exists recipe_leaderboard_update_own on recipe_leaderboard_entries;
create policy recipe_leaderboard_update_own on recipe_leaderboard_entries
  for update to authenticated using (auth.uid() = user_id and is_linked_user())
  with check (auth.uid() = user_id and is_linked_user());

-- mastered chỉ được TĂNG — chặn tự đạp hạng khi chơi lại bằng save cũ.
create or replace function recipe_leaderboard_no_downgrade()
returns trigger
language plpgsql
as $$
begin
  if new.mastered < old.mastered then
    new.mastered := old.mastered;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists recipe_leaderboard_no_downgrade_trg on recipe_leaderboard_entries;
create trigger recipe_leaderboard_no_downgrade_trg
  before update on recipe_leaderboard_entries
  for each row execute function recipe_leaderboard_no_downgrade();

-- Top người thạo nhiều món nhất (top tuyệt đối). Hoà thì ai nộp sớm hơn xếp trên.
create or replace function recipe_leaderboard_top(p_limit integer default 50)
returns table (
  user_id    uuid,
  nickname   text,
  mastered   integer,
  updated_at timestamptz,
  rank       bigint
)
language sql
stable
as $$
  select user_id, nickname, mastered, updated_at,
         row_number() over (order by mastered desc, updated_at asc) as rank
  from recipe_leaderboard_entries
  order by mastered desc, updated_at asc
  limit least(coalesce(p_limit, 50), 100);
$$;

grant execute on function recipe_leaderboard_top(integer) to anon, authenticated;

-- ===== recipe_order_leaderboard_schema.sql =====
-- Schema cho "Bảng xếp hạng Pha theo đơn" (trò công thức, chế độ kéo-thả) — xếp theo SỐ MÓN ĐÃ TỪNG PHA
-- HOÀN HẢO mà KHÔNG xem công thức mẫu (bậc Quen trở lên, không dùng gợi ý quảng cáo) — xem
-- lib/ui/recipe_order_page.dart và GameState.recipeOrderPerfect.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor → Run. Idempotent. Không phụ thuộc
-- file nào khác. Cùng khuôn recipe_leaderboard_schema.sql (số lượng chỉ tăng ⇒ cho UPDATE hàng của mình,
-- trigger chặn hạ cấp).
--
-- Khác các bảng cũ: GHI chỉ cho tài khoản đã LIÊN KẾT email (không ẩn danh) — ép ở server chứ không chỉ ở
-- app (hàm is_linked_user bên dưới). Các bảng cũ mới chỉ chặn ở app.
--
-- ⚠️ Chống gian lận: giá trị do client tự khai. Ràng buộc kiểm được: 0..100 (số món trong danh mục), chỉ tăng.

-- Tài khoản hiện tại đã liên kết email (không ẩn danh)? security definer vì vai trò authenticated không
-- đọc được auth.users.
create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

create table if not exists recipe_order_leaderboard_entries (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  nickname   text not null check (char_length(nickname) between 1 and 20),
  perfected  integer not null check (perfected between 0 and 100),
  updated_at timestamptz not null default now()
);

create index if not exists recipe_order_leaderboard_entries_idx
  on recipe_order_leaderboard_entries (perfected desc, updated_at asc);

alter table recipe_order_leaderboard_entries enable row level security;

-- Đọc: ai cũng được — bảng xếp hạng công khai (app vẫn chỉ mở cho người đã liên kết).
drop policy if exists recipe_order_lb_select_all on recipe_order_leaderboard_entries;
create policy recipe_order_lb_select_all on recipe_order_leaderboard_entries
  for select to anon, authenticated using (true);

-- Ghi: chỉ hàng của chính mình VÀ đã liên kết email.
drop policy if exists recipe_order_lb_insert_own on recipe_order_leaderboard_entries;
create policy recipe_order_lb_insert_own on recipe_order_leaderboard_entries
  for insert to authenticated with check (auth.uid() = user_id and is_linked_user());

drop policy if exists recipe_order_lb_update_own on recipe_order_leaderboard_entries;
create policy recipe_order_lb_update_own on recipe_order_leaderboard_entries
  for update to authenticated using (auth.uid() = user_id and is_linked_user())
  with check (auth.uid() = user_id and is_linked_user());

-- perfected chỉ được TĂNG — chặn tự đạp hạng khi chơi lại bằng save cũ.
create or replace function recipe_order_lb_no_downgrade()
returns trigger
language plpgsql
as $$
begin
  if new.perfected < old.perfected then
    new.perfected := old.perfected;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists recipe_order_lb_no_downgrade_trg on recipe_order_leaderboard_entries;
create trigger recipe_order_lb_no_downgrade_trg
  before update on recipe_order_leaderboard_entries
  for each row execute function recipe_order_lb_no_downgrade();

-- Top tuyệt đối. Hoà thì ai nộp sớm hơn xếp trên.
create or replace function recipe_order_leaderboard_top(p_limit integer default 50)
returns table (
  user_id    uuid,
  nickname   text,
  perfected  integer,
  updated_at timestamptz,
  rank       bigint
)
language sql
stable
as $$
  select user_id, nickname, perfected, updated_at,
         row_number() over (order by perfected desc, updated_at asc) as rank
  from recipe_order_leaderboard_entries
  order by perfected desc, updated_at asc
  limit least(coalesce(p_limit, 50), 100);
$$;

grant execute on function recipe_order_leaderboard_top(integer) to anon, authenticated;

-- ===== recipe_daily_schema.sql =====
-- Schema cho "Thử thách hằng ngày" của trò Pha theo đơn (lib/ui/recipe_order_page.dart, chế độ daily).
-- Mỗi ngày (UTC) mọi người chơi làm cùng 3 đơn (đề cố định theo ngày, xem buildDailyOrders); điểm 0..300.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor → Run. Idempotent. Không phụ thuộc file nào
-- khác (tự có is_linked_user, giống recipe_order_leaderboard_schema.sql).
--
-- Mỗi (người, ngày) đúng MỘT hàng và KHÔNG sửa được: chỉ có policy INSERT (không UPDATE/DELETE) nên điểm đã nộp
-- là bất biến; app nộp bằng upsert ... DO NOTHING nên nộp lại không lỗi. Ngày do SERVER tự đặt (default), client
-- không chọn được ⇒ không nộp điểm vào ngày khác. Ghi chỉ cho tài khoản đã LIÊN KẾT email.
--
-- ⚠️ Chống gian lận: điểm do client tự khai (kẹp 0..300). Bảng chỉ để vui/thi đua, thưởng thật chỉ là 💎 nhỏ cố định.

create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

-- Ngày hiện tại (số ngày kể từ epoch, UTC) — cùng cách tính dayIndex() ở app.
create or replace function recipe_daily_today() returns integer
language sql stable as $$ select floor(extract(epoch from now()) / 86400)::integer $$;

create table if not exists recipe_daily_scores (
  user_id    uuid not null references auth.users(id) on delete cascade,
  day        integer not null default recipe_daily_today(),
  nickname   text not null check (char_length(nickname) between 1 and 20),
  score      integer not null check (score between 0 and 300),
  updated_at timestamptz not null default now(),
  primary key (user_id, day)
);

create index if not exists recipe_daily_scores_idx on recipe_daily_scores (day, score desc, updated_at asc);

alter table recipe_daily_scores enable row level security;

drop policy if exists recipe_daily_select_all on recipe_daily_scores;
create policy recipe_daily_select_all on recipe_daily_scores
  for select to anon, authenticated using (true);

-- Chỉ INSERT hàng của mình, đúng ngày hôm nay của server, đã liên kết email. Cố ý KHÔNG có UPDATE/DELETE.
drop policy if exists recipe_daily_insert_own on recipe_daily_scores;
create policy recipe_daily_insert_own on recipe_daily_scores
  for insert to authenticated
  with check (auth.uid() = user_id and day = recipe_daily_today() and is_linked_user());

-- Top của HÔM NAY (ngày server). Hoà thì ai nộp sớm hơn xếp trên.
create or replace function recipe_daily_top(p_limit integer default 50)
returns table (
  user_id    uuid,
  nickname   text,
  score      integer,
  updated_at timestamptz,
  rank       bigint
)
language sql
stable
as $$
  select user_id, nickname, score, updated_at,
         row_number() over (order by score desc, updated_at asc) as rank
  from recipe_daily_scores
  where day = recipe_daily_today()
  order by score desc, updated_at asc
  limit least(coalesce(p_limit, 50), 100);
$$;

grant execute on function recipe_daily_top(integer) to anon, authenticated;

-- ===== story_speedrun_schema.sql =====
-- Schema cho "Bảng xếp hạng tốc độ hoàn thành cốt truyện" (18 chương).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor →
-- Run. Idempotent. Độc lập với arena_schema.sql/cloud_save_schema.sql/
-- analytics_schema.sql/leaderboard_schema.sql — dán trước/sau đều được.
--
-- Khác leaderboard_schema.sql (điểm số cập nhật liên tục, upsert mỗi lần mở
-- trang): đây là 1 MỐC MỘT LẦN — mỗi người chỉ nộp đúng 1 lần (khi vừa xem
-- xong Chương 18), không sửa lại được sau đó. Không cần trigger chống gian
-- lận phức tạp như leaderboard_schema.sql (không có Xu/Sao để làm giả cho
-- có lợi — sửa complete_seconds chỉ tự làm mình trông "nhanh" hơn giả tạo,
-- rủi ro thấp cho 1 bảng xếp hạng vui, không ảnh hưởng kinh tế chính); vẫn
-- chặn giá trị âm/bằng 0 bằng CHECK constraint cho chắc.
--
-- Danh tính: dùng auth.uid() — bất kỳ phiên nào đang có (ẩn danh từ Đấu
-- Trường, hoặc permanent từ Đồng bộ đám mây) đều nộp được, không bắt buộc
-- phải link email riêng.

create table if not exists story_speedrun_entries (
  user_id           uuid primary key references auth.users(id) on delete cascade,
  nickname          text not null check (char_length(nickname) between 1 and 20),
  complete_seconds  bigint not null check (complete_seconds > 0),
  completed_at      timestamptz not null default now()
);

create index if not exists story_speedrun_entries_time_idx
  on story_speedrun_entries (complete_seconds asc);

-- Tài khoản hiện tại đã liên kết email (không ẩn danh)? security definer vì vai trò authenticated không
-- đọc được auth.users. ÉP Ở SERVER (không chỉ ở app): ai ghi vào bảng này phải đã liên kết email. Định nghĩa
-- giống hệt ở mọi schema cần nó (create or replace) nên chạy file nào trước cũng được.
create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

alter table story_speedrun_entries enable row level security;

-- Đọc: AI CŨNG được — kể cả chưa đăng nhập (anon) — bảng xếp hạng công khai.
drop policy if exists story_speedrun_entries_select_all on story_speedrun_entries;
create policy story_speedrun_entries_select_all on story_speedrun_entries
  for select
  to anon, authenticated
  using (true);

-- Ghi: CHỈ insert (không có policy update/delete) — mỗi người 1 lần duy
-- nhất; lần nộp thứ 2 trở đi bị chặn kép: RLS không có "for update" nào
-- khớp, và PRIMARY KEY (user_id) chặn insert trùng khoá. Client coi lỗi
-- trùng khoá (23505) là no-op, không phải lỗi thật — xem
-- StorySpeedrunRepository.submitCompletion().
drop policy if exists story_speedrun_entries_insert_own on story_speedrun_entries;
create policy story_speedrun_entries_insert_own on story_speedrun_entries
  for insert
  to authenticated
  with check (auth.uid() = user_id and is_linked_user());

-- Top người hoàn thành nhanh nhất — KHÔNG dùng kiểu "quanh hạng của bạn"
-- như leaderboard_around_me: số người hoàn thành cốt truyện chắc chắn ít
-- hơn nhiều tổng số người chơi (top tuyệt đối vẫn có ý nghĩa), và người
-- CHƯA hoàn thành thì vốn không có hàng nào để "quanh" cả.
create or replace function story_speedrun_top(p_limit integer default 50)
returns table (
  user_id           uuid,
  nickname          text,
  complete_seconds  bigint,
  completed_at      timestamptz,
  rank              bigint
)
language sql
stable
as $$
  select user_id, nickname, complete_seconds, completed_at,
         row_number() over (order by complete_seconds asc, completed_at asc) as rank
  from story_speedrun_entries
  order by complete_seconds asc, completed_at asc
  limit p_limit;
$$;

grant execute on function story_speedrun_top(integer) to anon, authenticated;

-- ===== story_speedrun2_schema.sql =====
-- Schema cho "Bảng xếp hạng tốc độ — Hồi 2" (hoàn thành Chương 28).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor →
-- Run. Idempotent. Độc lập với story_speedrun_schema.sql (bảng Hồi 1, mốc
-- Chương 18) và các schema khác — dán trước/sau đều được. KHÔNG đụng bảng/hàm
-- của Hồi 1 nên client đã phát hành không bị ảnh hưởng.
--
-- Cùng khuôn với story_speedrun_schema.sql: 1 MỐC MỘT LẦN cho mỗi người (khi
-- vừa xem xong Chương 28), không sửa lại được; không có anti-cheat (không có
-- Xu/Sao để làm giả có lợi, rủi ro thấp cho bảng xếp hạng vui) — chỉ chặn giá
-- trị <= 0 bằng CHECK. Thời gian = TỔNG giây thực tế từ lần đầu chơi tới lúc
-- xong Chương 28 (cùng cách đo với Hồi 1).
--
-- Danh tính: auth.uid() — bất kỳ phiên nào đang có (ẩn danh hoặc permanent).

create table if not exists story_speedrun2_entries (
  user_id           uuid primary key references auth.users(id) on delete cascade,
  nickname          text not null check (char_length(nickname) between 1 and 20),
  complete_seconds  bigint not null check (complete_seconds > 0),
  completed_at      timestamptz not null default now()
);

create index if not exists story_speedrun2_entries_time_idx
  on story_speedrun2_entries (complete_seconds asc);

-- Tài khoản hiện tại đã liên kết email (không ẩn danh)? security definer vì vai trò authenticated không
-- đọc được auth.users. ÉP Ở SERVER (không chỉ ở app): ai ghi vào bảng này phải đã liên kết email. Định nghĩa
-- giống hệt ở mọi schema cần nó (create or replace) nên chạy file nào trước cũng được.
create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

alter table story_speedrun2_entries enable row level security;

-- Đọc: AI CŨNG được (kể cả anon) — bảng xếp hạng công khai.
drop policy if exists story_speedrun2_entries_select_all on story_speedrun2_entries;
create policy story_speedrun2_entries_select_all on story_speedrun2_entries
  for select
  to anon, authenticated
  using (true);

-- Ghi: CHỈ insert (không có policy update/delete). Lần nộp thứ 2 bị chặn kép:
-- RLS không có "for update" khớp và PRIMARY KEY (user_id) chặn insert trùng
-- khoá; client coi lỗi 23505 là no-op (xem StorySpeedrunRepository.submitCompletion).
drop policy if exists story_speedrun2_entries_insert_own on story_speedrun2_entries;
create policy story_speedrun2_entries_insert_own on story_speedrun2_entries
  for insert
  to authenticated
  with check (auth.uid() = user_id and is_linked_user());

-- Top người hoàn thành nhanh nhất (top tuyệt đối, không "quanh hạng của bạn").
create or replace function story_speedrun2_top(p_limit integer default 50)
returns table (
  user_id           uuid,
  nickname          text,
  complete_seconds  bigint,
  completed_at      timestamptz,
  rank              bigint
)
language sql
stable
as $$
  select user_id, nickname, complete_seconds, completed_at,
         row_number() over (order by complete_seconds asc, completed_at asc) as rank
  from story_speedrun2_entries
  order by complete_seconds asc, completed_at asc
  limit p_limit;
$$;

grant execute on function story_speedrun2_top(integer) to anon, authenticated;

-- ===== story_speedrun3_schema.sql =====
-- Schema cho "Bảng xếp hạng tốc độ — Hồi 3" (hoàn thành Chương 34).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor →
-- Run. Idempotent. Độc lập với story_speedrun_schema.sql (Hồi 1, Chương 18)
-- và story_speedrun2_schema.sql (Hồi 2, Chương 28) — dán trước/sau đều được.
-- KHÔNG đụng bảng/hàm của hai hồi trước nên client đã phát hành không bị
-- ảnh hưởng.
--
-- Cùng khuôn với story_speedrun2_schema.sql: 1 MỐC MỘT LẦN cho mỗi người (khi
-- vừa xem xong Chương 34), không sửa lại được; không có anti-cheat (không có
-- Xu/Sao để làm giả có lợi, rủi ro thấp cho bảng xếp hạng vui) — chỉ chặn giá
-- trị <= 0 bằng CHECK. Thời gian = TỔNG giây thực tế từ lần đầu chơi tới lúc
-- xong Chương 34 (cùng cách đo với Hồi 1/2).
--
-- Danh tính: auth.uid() — bất kỳ phiên nào đang có (ẩn danh hoặc permanent).

create table if not exists story_speedrun3_entries (
  user_id           uuid primary key references auth.users(id) on delete cascade,
  nickname          text not null check (char_length(nickname) between 1 and 20),
  complete_seconds  bigint not null check (complete_seconds > 0),
  completed_at      timestamptz not null default now()
);

create index if not exists story_speedrun3_entries_time_idx
  on story_speedrun3_entries (complete_seconds asc);

-- Tài khoản hiện tại đã liên kết email (không ẩn danh)? security definer vì vai trò authenticated không
-- đọc được auth.users. ÉP Ở SERVER (không chỉ ở app): ai ghi vào bảng này phải đã liên kết email. Định nghĩa
-- giống hệt ở mọi schema cần nó (create or replace) nên chạy file nào trước cũng được.
create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

alter table story_speedrun3_entries enable row level security;

-- Đọc: AI CŨNG được (kể cả anon) — bảng xếp hạng công khai.
drop policy if exists story_speedrun3_entries_select_all on story_speedrun3_entries;
create policy story_speedrun3_entries_select_all on story_speedrun3_entries
  for select
  to anon, authenticated
  using (true);

-- Ghi: CHỈ insert (không có policy update/delete). Lần nộp thứ 2 bị chặn kép:
-- RLS không có "for update" khớp và PRIMARY KEY (user_id) chặn insert trùng
-- khoá; client coi lỗi 23505 là no-op (xem StorySpeedrunRepository.submitCompletion).
drop policy if exists story_speedrun3_entries_insert_own on story_speedrun3_entries;
create policy story_speedrun3_entries_insert_own on story_speedrun3_entries
  for insert
  to authenticated
  with check (auth.uid() = user_id and is_linked_user());

-- Top người hoàn thành nhanh nhất (top tuyệt đối, không "quanh hạng của bạn").
create or replace function story_speedrun3_top(p_limit integer default 50)
returns table (
  user_id           uuid,
  nickname          text,
  complete_seconds  bigint,
  completed_at      timestamptz,
  rank              bigint
)
language sql
stable
as $$
  select user_id, nickname, complete_seconds, completed_at,
         row_number() over (order by complete_seconds asc, completed_at asc) as rank
  from story_speedrun3_entries
  order by complete_seconds asc, completed_at asc
  limit p_limit;
$$;

grant execute on function story_speedrun3_top(integer) to anon, authenticated;

-- ===== story_speedrun4_schema.sql =====
-- Schema cho "Bảng xếp hạng tốc độ — Hồi 4" (hoàn thành Chương 46).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor →
-- Run. Idempotent. Độc lập với story_speedrun_schema.sql (Hồi 1, Chương 18), story_speedrun2_schema.sql (Hồi 2, Chương 28)
-- và story_speedrun3_schema.sql (Hồi 3, Chương 36) — dán trước/sau đều được.
-- KHÔNG đụng bảng/hàm của hai hồi trước nên client đã phát hành không bị
-- ảnh hưởng.
--
-- Cùng khuôn với story_speedrun2_schema.sql: 1 MỐC MỘT LẦN cho mỗi người (khi
-- vừa xem xong Chương 46), không sửa lại được; không có anti-cheat (không có
-- Xu/Sao để làm giả có lợi, rủi ro thấp cho bảng xếp hạng vui) — chỉ chặn giá
-- trị <= 0 bằng CHECK. Thời gian = TỔNG giây thực tế từ lần đầu chơi tới lúc
-- xong Chương 46 (cùng cách đo với Hồi 1/2).
--
-- Danh tính: auth.uid() — bất kỳ phiên nào đang có (ẩn danh hoặc permanent).

create table if not exists story_speedrun4_entries (
  user_id           uuid primary key references auth.users(id) on delete cascade,
  nickname          text not null check (char_length(nickname) between 1 and 20),
  complete_seconds  bigint not null check (complete_seconds > 0),
  completed_at      timestamptz not null default now()
);

create index if not exists story_speedrun4_entries_time_idx
  on story_speedrun4_entries (complete_seconds asc);

-- Tài khoản hiện tại đã liên kết email (không ẩn danh)? security definer vì vai trò authenticated không
-- đọc được auth.users. ÉP Ở SERVER (không chỉ ở app): ai ghi vào bảng này phải đã liên kết email. Định nghĩa
-- giống hệt ở mọi schema cần nó (create or replace) nên chạy file nào trước cũng được.
create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

alter table story_speedrun4_entries enable row level security;

-- Đọc: AI CŨNG được (kể cả anon) — bảng xếp hạng công khai.
drop policy if exists story_speedrun4_entries_select_all on story_speedrun4_entries;
create policy story_speedrun4_entries_select_all on story_speedrun4_entries
  for select
  to anon, authenticated
  using (true);

-- Ghi: CHỈ insert (không có policy update/delete). Lần nộp thứ 2 bị chặn kép:
-- RLS không có "for update" khớp và PRIMARY KEY (user_id) chặn insert trùng
-- khoá; client coi lỗi 23505 là no-op (xem StorySpeedrunRepository.submitCompletion).
drop policy if exists story_speedrun4_entries_insert_own on story_speedrun4_entries;
create policy story_speedrun4_entries_insert_own on story_speedrun4_entries
  for insert
  to authenticated
  with check (auth.uid() = user_id and is_linked_user());

-- Top người hoàn thành nhanh nhất (top tuyệt đối, không "quanh hạng của bạn").
create or replace function story_speedrun4_top(p_limit integer default 50)
returns table (
  user_id           uuid,
  nickname          text,
  complete_seconds  bigint,
  completed_at      timestamptz,
  rank              bigint
)
language sql
stable
as $$
  select user_id, nickname, complete_seconds, completed_at,
         row_number() over (order by complete_seconds asc, completed_at asc) as rank
  from story_speedrun4_entries
  order by complete_seconds asc, completed_at asc
  limit p_limit;
$$;

grant execute on function story_speedrun4_top(integer) to anon, authenticated;

-- ===== event_leaderboard_schema.sql =====
-- Schema cho "Bảng xếp hạng Sự kiện" — mỗi dịp lễ (xem `festivals` trong
-- lib/core/accessories.dart) một bảng riêng, xếp theo ĐIỂM SỰ KIỆN
-- (lib/core/event_quests.dart: eventScore = chạm ly + 50 x (mèo Mưa vàng + khách VIP)).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor → Run.
-- Idempotent. Độc lập với các file schema khác.
--
-- Chống gian lận: client KHÔNG ghi thẳng vào bảng (không có policy insert/update).
-- Mọi lần nộp đi qua `event_leaderboard_submit` (security definer) kiểm:
--   1. dịp lễ có thật và đang diễn ra (giờ SERVER, không tin giờ máy),
--   2. điểm không vượt tốc độ tối đa hợp lý (event_score_per_hour x số giờ đã trôi),
--   3. điểm chỉ tăng (nộp bằng save cũ không đạp hạng).
--
-- ⚠️ Khi thêm/đổi dịp lễ trong Dart PHẢI sửa `event_leaderboard_window` ở đây
-- cho khớp — test/leaderboard/event_leaderboard_test.dart so khớp hai bên.

create table if not exists event_leaderboard_entries (
  festival_id text not null,
  user_id     uuid not null references auth.users(id) on delete cascade,
  nickname    text not null check (char_length(nickname) between 1 and 20),
  score       bigint not null check (score between 0 and 1000000000),
  updated_at  timestamptz not null default now(),
  primary key (festival_id, user_id)
);

create index if not exists event_leaderboard_entries_rank_idx
  on event_leaderboard_entries (festival_id, score desc, updated_at asc);

alter table event_leaderboard_entries enable row level security;

drop policy if exists event_leaderboard_select_all on event_leaderboard_entries;
create policy event_leaderboard_select_all on event_leaderboard_entries
  for select to anon, authenticated using (true);
-- Cố ý KHÔNG có policy insert/update/delete: chỉ RPC bên dưới được ghi.

-- Cửa sổ [start, end) (UTC) của từng dịp — khớp `festivals` trong Dart.
create or replace function event_leaderboard_window(p_festival text)
returns table (starts_at timestamptz, ends_at timestamptz)
language sql
immutable
as $$
  select s, e from (values
    ('halloween',  timestamptz '2026-10-24 00:00:00+00', timestamptz '2026-11-03 00:00:00+00'),
    ('christmas',  timestamptz '2026-12-18 00:00:00+00', timestamptz '2026-12-28 00:00:00+00'),
    ('new_year',   timestamptz '2026-12-28 00:00:00+00', timestamptz '2027-01-04 00:00:00+00'),
    ('tet',        timestamptz '2027-01-30 00:00:00+00', timestamptz '2027-02-10 00:00:00+00'),
    ('valentine',  timestamptz '2027-02-10 00:00:00+00', timestamptz '2027-02-16 00:00:00+00'),
    ('womens_day', timestamptz '2027-03-04 00:00:00+00', timestamptz '2027-03-10 00:00:00+00'),
    ('mid_autumn', timestamptz '2027-09-08 00:00:00+00', timestamptz '2027-09-18 00:00:00+00')
  ) as t(id, s, e)
  where id = p_festival;
$$;

-- Tốc độ điểm tối đa mỗi giờ (≈ 28 chạm/giây liên tục — người thật không tới).
create or replace function event_score_per_hour()
returns integer language sql immutable as $$ select 100000 $$;

-- Tài khoản hiện tại đã liên kết email (không ẩn danh)? security definer vì vai trò authenticated không
-- đọc được auth.users. ÉP Ở SERVER (không chỉ ở app): ai ghi vào bảng này phải đã liên kết email. Định nghĩa
-- giống hệt ở mọi schema cần nó (create or replace) nên chạy file nào trước cũng được.
create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

create or replace function event_leaderboard_submit(
  p_festival text,
  p_nickname text,
  p_score    bigint
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_start timestamptz;
  v_end   timestamptz;
  v_hours numeric;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if not is_linked_user() then
    raise exception 'email link required';
  end if;
  if p_score < 0 or char_length(coalesce(p_nickname, '')) not between 1 and 20 then
    raise exception 'invalid input';
  end if;

  select starts_at, ends_at into v_start, v_end
    from event_leaderboard_window(p_festival);
  if v_start is null then
    raise exception 'unknown festival';
  end if;
  if now() < v_start or now() >= v_end then
    raise exception 'festival not active';
  end if;

  v_hours := greatest(extract(epoch from (now() - v_start)) / 3600.0, 1);
  if p_score > ceil(v_hours * event_score_per_hour()) then
    raise exception 'score too high';
  end if;

  insert into event_leaderboard_entries (festival_id, user_id, nickname, score)
  values (p_festival, auth.uid(), p_nickname, p_score)
  on conflict (festival_id, user_id) do update
    set nickname   = excluded.nickname,
        score      = greatest(event_leaderboard_entries.score, excluded.score),
        updated_at = now();
end;
$$;

revoke all on function event_leaderboard_submit(text, text, bigint) from public;
grant execute on function event_leaderboard_submit(text, text, bigint) to authenticated;

create or replace function event_leaderboard_top(p_festival text, p_limit integer default 50)
returns table (
  user_id    uuid,
  nickname   text,
  score      bigint,
  updated_at timestamptz,
  rank       bigint
)
language sql
stable
as $$
  select user_id, nickname, score, updated_at,
         row_number() over (order by score desc, updated_at asc) as rank
  from event_leaderboard_entries
  where festival_id = p_festival
  order by score desc, updated_at asc
  limit least(p_limit, 100);
$$;

grant execute on function event_leaderboard_top(text, integer) to anon, authenticated;

-- ===== accessory_market_schema.sql =====
-- Schema cho "Chợ Phụ kiện" — xem PROPOSAL_ACCESSORY_MARKET.md.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor →
-- Run. Idempotent, độc lập với các schema khác (accessory_leaderboard_schema.sql
-- vẫn giữ nguyên, không đụng nhau) — dán trước/sau đều được.
--
-- ⚠️ Khác PROPOSAL §4 (bản phác thảo đầu): đã thêm RPC register_accessory_drop
-- và bỏ bảng accessory_server_ownership khỏi vai trò "nguồn id món được phép
-- đăng bán tự do" — xem lý do ở ngay phía dưới.

-- ─────────────────────────────────────────────────────────────────────────
-- Vì sao cần register_accessory_drop (không có trong phác thảo PROPOSAL ban
-- đầu): list_accessory phải verify người gọi THẬT SỰ sở hữu món trước khi
-- cho đăng bán — nhưng GĐ1 (Kho phụ kiện) chưa từng đồng bộ ownedAccessories
-- lên server, nó chỉ sống trong save JSON local. Không có bước này thì
-- list_accessory phải tin suông lời client "tôi sở hữu món X" — 2 tài khoản
-- thông đồng (A đăng bán id bất kỳ, kể cả chưa từng rớt → B mua) có thể bơm
-- phụ kiện giả cho nhau, phá vỡ ý nghĩa bảng xếp hạng Sưu tập (tính cả món
-- đang đăng bán, xem §9.3).
--
-- Giải pháp: accessory_server_ownership chỉ được ghi qua register_accessory_drop
-- (gọi lúc claimDailyBonus rớt món MỚI, xem accessories_test.dart/game_controller.dart)
-- hoặc lúc buy_listing (người mua). KHÔNG ai được tự ý "tự nhận" sở hữu 1 id
-- tuỳ ý qua list_accessory nữa — list_accessory giờ CHỈ cho đăng bán món đã
-- có mặt trong accessory_server_ownership từ trước.
--
-- Rủi ro còn sót: người chơi có thể sửa tay save local để THÊM id giả vào
-- ownedAccessories rồi gọi register_accessory_drop cho id đó — nhưng đây
-- không phải lỗ hổng MỚI, nó là mức tin cậy game đã chấp nhận sẵn cho TOÀN
-- BỘ kinh tế (Xu/💎/stage cũng sửa tay được, không có lớp nào chặn) — khác
-- hẳn lỗ hổng "2 tài khoản thông đồng, không cần sửa save" mà thiếu RPC này
-- sẽ mở ra. Chấp nhận được, nhất quán với mức rủi ro hiện tại của toàn game.
-- ─────────────────────────────────────────────────────────────────────────

-- Số dư Xu Chợ, KHÔNG liên thông Xu/💎 thật (xem PROPOSAL §0). Không có
-- policy insert/update cho client — tạo lười (upsert) ngay trong RPC lúc
-- cần, không cần bước "mở ví" riêng.
create table if not exists accessory_wallets (
  user_id  uuid primary key references auth.users(id) on delete cascade,
  balance  bigint not null default 0 check (balance >= 0)
);

alter table accessory_wallets enable row level security;

drop policy if exists accessory_wallets_select_own on accessory_wallets;
create policy accessory_wallets_select_own on accessory_wallets
  for select to authenticated using (auth.uid() = user_id);

-- Ai đang sở hữu món nào, theo xác nhận của SERVER (không phải client tự
-- khai) — chỉ ghi qua register_accessory_drop/buy_listing/list_accessory/
-- cancel_listing bên dưới, không có policy insert/update trực tiếp.
create table if not exists accessory_server_ownership (
  user_id       uuid not null references auth.users(id) on delete cascade,
  accessory_id  text not null,
  granted_at    timestamptz not null default now(),
  primary key (user_id, accessory_id)
);

-- Số bản sao sở hữu (≥ 1 khi còn hàng; hàng bị xoá khi về 0). Rớt trùng cho
-- bản dư bán được ở Chợ mà vẫn giữ món sưu tập.
alter table accessory_server_ownership
  add column if not exists copies integer not null default 1;

alter table accessory_server_ownership enable row level security;

drop policy if exists accessory_server_ownership_select_own on accessory_server_ownership;
create policy accessory_server_ownership_select_own on accessory_server_ownership
  for select to authenticated using (auth.uid() = user_id);

create table if not exists accessory_listings (
  id            uuid primary key default gen_random_uuid(),
  seller_id     uuid not null references auth.users(id),
  accessory_id  text not null,
  -- Giá tự do, chỉ chặn biên rộng (xem PROPOSAL §9.1) — không khung theo độ hiếm.
  price         bigint not null check (price between 1 and 100000),
  status        text not null default 'active', -- active|sold|cancelled|expired
  created_at    timestamptz not null default now(),
  resolved_at   timestamptz
);

-- Tin đăng sống tối đa market_listing_days() ngày rồi hết hạn (status 'expired', món về kho người
-- bán). seller_acked = false: món đã về kho SERVER nhưng máy người bán chưa thêm lại vào kho cục bộ
-- (xem expire_my_listings/ack_expired_listings) — hai pha để app tắt giữa chừng không mất món.
alter table accessory_listings add column if not exists seller_acked boolean not null default true;
create or replace function market_listing_days() returns integer
language sql immutable as $$ select 3 $$;

create index if not exists accessory_listings_active_idx
  on accessory_listings (status, created_at desc);
create index if not exists accessory_listings_seller_idx
  on accessory_listings (seller_id, status);

alter table accessory_listings enable row level security;

-- Đọc: AI CŨNG được, kể cả chưa đăng nhập — chợ công khai (xem đang bán gì).
-- Tin đã quá hạn nhưng chưa được quét sang 'expired' cũng bị ẩn (client cũ không cần sửa gì).
drop policy if exists accessory_listings_select_all on accessory_listings;
create policy accessory_listings_select_all on accessory_listings
  for select to anon, authenticated
  using (status <> 'active' or created_at > now() - make_interval(days => market_listing_days()));
-- Không có policy insert/update cho client — chỉ qua RPC bên dưới.

create table if not exists accessory_market_trades (
  id            bigint generated always as identity primary key,
  listing_id    uuid not null references accessory_listings(id),
  buyer_id      uuid not null references auth.users(id),
  seller_id     uuid not null references auth.users(id),
  accessory_id  text not null,
  price         bigint not null,
  traded_at     timestamptz not null default now()
);

create index if not exists accessory_market_trades_buyer_idx
  on accessory_market_trades (buyer_id, traded_at desc);
create index if not exists accessory_market_trades_seller_idx
  on accessory_market_trades (seller_id, traded_at desc);

alter table accessory_market_trades enable row level security;

-- Đọc: chỉ giao dịch của chính mình (mua HOẶC bán).
drop policy if exists accessory_market_trades_select_own on accessory_market_trades;
create policy accessory_market_trades_select_own on accessory_market_trades
  for select to authenticated
  using (auth.uid() = buyer_id or auth.uid() = seller_id);

-- ─────────────────────────────────────────────────────────────────────────
-- RPC (security definer — đường ghi DUY NHẤT, RLS chặn hết insert/update
-- thẳng từ client ở các bảng trên).
-- ─────────────────────────────────────────────────────────────────────────

-- Ghi nhận 1 món vừa rớt hợp lệ (gọi lúc claimDailyBonus rớt món MỚI) HOẶC
-- dùng để "đối chiếu lần đầu" khi người chơi mở Chợ lần đầu, bù đăng ký cho
-- những món họ đã có từ trước khi Chợ ra đời (xem ghi chú đầu file). An
-- toàn gọi lại nhiều lần (idempotent).
create or replace function register_accessory_drop(p_accessory_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into accessory_server_ownership (user_id, accessory_id)
  values (auth.uid(), p_accessory_id)
  on conflict (user_id, accessory_id) do nothing;
end;
$$;

grant execute on function register_accessory_drop(text) to authenticated;

-- Ghi nhận số bản sao người chơi đang có: idempotent (chỉ NÂNG, không hạ —
-- hạ chỉ qua list_accessory), nên vừa dùng được lúc rớt vừa dùng để đối chiếu
-- khi mở Chợ. Client tự khai số bản — cùng mức tin cậy với register_accessory_drop.
create or replace function register_accessory_copies(p_accessory_id text, p_copies integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_copies < 1 or p_copies > 999 then
    raise exception 'invalid_copies';
  end if;
  insert into accessory_server_ownership (user_id, accessory_id, copies)
  values (auth.uid(), p_accessory_id, p_copies)
  on conflict (user_id, accessory_id) do update
    set copies = greatest(accessory_server_ownership.copies, excluded.copies);
end;
$$;

grant execute on function register_accessory_copies(text, integer) to authenticated;

-- Đăng bán — CHỈ cho đăng món đã có trong accessory_server_ownership của
-- chính mình (xem lý do ở đầu file). Xoá khỏi bảng sở hữu ngay (món "rời
-- khỏi tay" người bán trong lúc đang rao) để không đăng được 2 lần.
create or replace function list_accessory(p_accessory_id text, p_price bigint)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_listing_id uuid;
  v_left integer;
begin
  if p_price < 1 or p_price > 100000 then
    raise exception 'invalid_price';
  end if;

  -- Quét tin quá hạn của chính mình trước: món về kho server mới đăng lại được ngay.
  perform market_sweep(auth.uid());

  update accessory_server_ownership set copies = copies - 1
  where user_id = auth.uid() and accessory_id = p_accessory_id
  returning copies into v_left;

  if not found then
    raise exception 'not_owned';
  end if;
  if v_left <= 0 then
    delete from accessory_server_ownership
    where user_id = auth.uid() and accessory_id = p_accessory_id;
  end if;

  insert into accessory_listings (seller_id, accessory_id, price)
  values (auth.uid(), p_accessory_id, p_price)
  returning id into v_listing_id;

  return v_listing_id;
end;
$$;

grant execute on function list_accessory(text, bigint) to authenticated;

-- Quét tin quá hạn: đổi sang 'expired' và trả món về kho SERVER của người bán (gộp theo món để
-- ON CONFLICT không đụng một hàng hai lần). [p_seller] null = mọi người bán. Nội bộ — client
-- KHÔNG gọi trực tiếp (xem revoke cuối file); chạy lười khi có người đăng/mua/mở Chợ, hoặc theo
-- lịch nếu bật pg_cron: select cron.schedule('market-sweep', '*/30 * * * *', 'select market_sweep()').
create or replace function market_sweep(p_seller uuid default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  with e as (
    update accessory_listings
       set status = 'expired', resolved_at = now(), seller_acked = false
     where status = 'active'
       and created_at <= now() - make_interval(days => market_listing_days())
       and (p_seller is null or seller_id = p_seller)
    returning seller_id, accessory_id
  ), g as (
    select seller_id, accessory_id, count(*)::integer as n from e group by seller_id, accessory_id
  )
  insert into accessory_server_ownership (user_id, accessory_id, copies)
  select seller_id, accessory_id, n from g
  on conflict (user_id, accessory_id) do update
    set copies = accessory_server_ownership.copies + excluded.copies;
end;
$$;

-- Người bán mở Chợ: quét tin hết hạn của mình rồi trả danh sách món về kho mà máy chưa thêm lại.
create or replace function expire_my_listings()
returns table (id uuid, accessory_id text)
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  perform market_sweep(auth.uid());
  return query
    select l.id, l.accessory_id from accessory_listings l
     where l.seller_id = auth.uid() and l.status = 'expired' and not l.seller_acked
     order by l.resolved_at;
end;
$$;

-- Máy đã thêm các món trên vào kho cục bộ → đánh dấu để lần sau không trả lại.
create or replace function ack_expired_listings(p_ids uuid[])
returns void
language sql
security definer
set search_path = public
as $$
  update accessory_listings set seller_acked = true
   where seller_id = auth.uid() and status = 'expired' and id = any (p_ids);
$$;

revoke all on function expire_my_listings() from public, anon;
revoke all on function ack_expired_listings(uuid[]) from public, anon;
grant execute on function expire_my_listings() to authenticated;
grant execute on function ack_expired_listings(uuid[]) to authenticated;
revoke all on function market_sweep(uuid) from public, anon, authenticated;

-- Gia hạn tin đăng: người bán xem quảng cáo (client) để tin sống thêm market_listing_days() ngày.
-- Mỗi tin chỉ một lần; tin đã hết hạn thì không gia hạn được (món đã về kho qua quét).
-- Server không xác minh được quảng cáo — chấp nhận, vì lợi ích chỉ là thêm 3 ngày cho CHÍNH tin của mình.
alter table accessory_listings add column if not exists extended boolean not null default false;
create or replace function extend_listing(p_listing_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare v_n integer;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  update accessory_listings
     set created_at = now(), extended = true
   where id = p_listing_id and seller_id = auth.uid() and status = 'active' and not extended
     and created_at > now() - make_interval(days => market_listing_days());
  get diagnostics v_n = row_count;
  if v_n = 0 then raise exception 'listing_not_extendable'; end if;
end;
$$;
revoke all on function extend_listing(uuid) from public, anon;
grant execute on function extend_listing(uuid) to authenticated;

-- Huỷ đăng — trả món lại accessory_server_ownership cho người bán.
create or replace function cancel_listing(p_listing_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seller uuid;
  v_accessory text;
begin
  select seller_id, accessory_id into v_seller, v_accessory
  from accessory_listings
  where id = p_listing_id and status = 'active'
    and created_at > now() - make_interval(days => market_listing_days())
  for update;

  if not found then
    raise exception 'listing_not_active';
  end if;
  if v_seller <> auth.uid() then
    raise exception 'not_your_listing';
  end if;

  update accessory_listings
  set status = 'cancelled', resolved_at = now()
  where id = p_listing_id;

  insert into accessory_server_ownership (user_id, accessory_id)
  values (v_seller, v_accessory)
  on conflict (user_id, accessory_id) do update
    set copies = accessory_server_ownership.copies + 1;
end;
$$;

grant execute on function cancel_listing(uuid) to authenticated;

-- Mua — 1 transaction, khoá hàng listing trước khi đổi gì (chặn 2 người
-- mua cùng lúc 1 listing — bài học từ pushIfCurrent/optimistic concurrency
-- ở Cloud Save). Chặn tự mua chính mình dù không có lợi kinh tế thật (Xu
-- Chợ không đổi ra giá trị thật — xem PROPOSAL §0) vì vẫn làm nhiễu
-- accessory_market_trades (vd thao túng cảm giác "món hot").
-- Sự kiện cuối tuần: phí sàn 0% vào thứ 7 và Chủ nhật (UTC). PHẢI khớp
-- lib/core/market_fee.dart (marketFeeFree) và Edge Function notify-market-sale.
create or replace function market_fee_free()
returns boolean
language sql
stable
as $$
  select extract(isodow from (now() at time zone 'utc')) in (6, 7);
$$;

grant execute on function market_fee_free() to anon, authenticated;

create or replace function buy_listing(p_listing_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seller uuid;
  v_accessory text;
  v_price bigint;
  v_buyer uuid := auth.uid();
  v_balance bigint;
  v_fee bigint;
begin
  select seller_id, accessory_id, price into v_seller, v_accessory, v_price
  from accessory_listings
  where id = p_listing_id and status = 'active'
    and created_at > now() - make_interval(days => market_listing_days())
  for update;

  if not found then
    raise exception 'listing_not_active';
  end if;
  if v_seller = v_buyer then
    raise exception 'cannot_buy_own_listing';
  end if;

  -- Ví có thể chưa tồn tại (chưa từng bán/mua gì) — tạo lười với 0.
  insert into accessory_wallets (user_id, balance) values (v_buyer, 0)
  on conflict (user_id) do nothing;
  insert into accessory_wallets (user_id, balance) values (v_seller, 0)
  on conflict (user_id) do nothing;

  select balance into v_balance from accessory_wallets
  where user_id = v_buyer for update;
  if v_balance < v_price then
    raise exception 'insufficient_balance';
  end if;

  -- Phí sàn 1%, làm tròn lên, tối thiểu 1 Xu Chợ (số nguyên, không qua float).
  -- Người mua trả đúng giá niêm yết; người bán nhận giá - phí.
  -- Cuối tuần (thứ 7/CN theo UTC) MIỄN phí — xem market_fee_free().
  v_fee := case when market_fee_free() then 0
                else greatest(1, (v_price + 99) / 100) end;

  update accessory_wallets set balance = balance - v_price where user_id = v_buyer;
  update accessory_wallets set balance = balance + (v_price - v_fee) where user_id = v_seller;

  update accessory_listings
  set status = 'sold', resolved_at = now()
  where id = p_listing_id;

  insert into accessory_server_ownership (user_id, accessory_id)
  values (v_buyer, v_accessory)
  on conflict (user_id, accessory_id) do update
    set copies = accessory_server_ownership.copies + 1;

  insert into accessory_market_trades (listing_id, buyer_id, seller_id, accessory_id, price)
  values (p_listing_id, v_buyer, v_seller, v_accessory, v_price);
end;
$$;

grant execute on function buy_listing(uuid) to authenticated;

-- Nạp Xu Chợ bằng Xu/💎 — MỘT CHIỀU: chỉ cộng ví người gọi, không có RPC ngược
-- và không đụng Xu/💎 cục bộ (client tự trừ SAU khi RPC này thành công).
create or replace function credit_market_coins(p_amount bigint)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  if p_amount is null or p_amount < 1 or p_amount > 100000 then
    raise exception 'invalid_amount';
  end if;

  insert into accessory_wallets (user_id, balance) values (auth.uid(), p_amount)
  on conflict (user_id) do update set balance = accessory_wallets.balance + p_amount;
end;
$$;

revoke execute on function credit_market_coins(bigint) from public, anon;
grant execute on function credit_market_coins(bigint) to authenticated;

-- Giao dịch gần nhất, ẩn danh (không lộ id người mua/bán) — cho dải "Vừa bán".
-- RLS của accessory_market_trades chỉ cho đọc giao dịch của chính mình nên
-- phải qua security definer; chỉ trả 3 cột an toàn.
create or replace function recent_market_trades(p_limit integer default 10)
returns table (accessory_id text, price bigint, traded_at timestamptz)
language sql
stable
security definer
set search_path = public
as $$
  select accessory_id, price, traded_at
  from accessory_market_trades
  order by traded_at desc
  limit least(greatest(p_limit, 1), 20);
$$;

grant execute on function recent_market_trades(integer) to anon, authenticated;

-- "Thương gia tuần": người bán được nhiều giao dịch nhất 7 ngày qua (hoà →
-- tổng giá cao hơn → ai bán sớm hơn). Chỉ trả user_id — bảng xếp hạng Sưu tập
-- vốn đã công khai user_id. Phí sàn 1% khiến 2 tài khoản bán qua lại để
-- cày danh hiệu này mất Xu Chợ mỗi vòng; đây chỉ là danh hiệu, không thưởng.
create or replace function market_weekly_top_seller()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select seller_id
  from accessory_market_trades
  where traded_at > now() - interval '7 days'
  group by seller_id
  order by count(*) desc, sum(price) desc, min(traded_at) asc
  limit 1;
$$;

grant execute on function market_weekly_top_seller() to anon, authenticated;

-- Token FCM để đẩy "món của bạn đã bán được" (xem
-- supabase/functions/notify-market-sale). Không có policy nào cho client —
-- chỉ ghi qua RPC dưới, chỉ đọc bằng service role trong Edge Function.
create table if not exists push_tokens (
  token       text primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  platform    text not null,
  locale      text not null default 'en',
  updated_at  timestamptz not null default now()
);

create index if not exists push_tokens_user_idx on push_tokens (user_id);

alter table push_tokens enable row level security;

-- Token thuộc về máy: cài lại app (user ẩn danh mới) thì token chuyển chủ.
create or replace function register_push_token(p_token text, p_platform text, p_locale text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  if char_length(p_token) not between 20 and 4096 then
    raise exception 'invalid_token';
  end if;

  insert into push_tokens (token, user_id, platform, locale)
  values (p_token, auth.uid(), p_platform, left(p_locale, 8))
  on conflict (token) do update
    set user_id = auth.uid(), platform = excluded.platform,
        locale = excluded.locale, updated_at = now();
end;
$$;

grant execute on function register_push_token(text, text, text) to authenticated;

-- Realtime: trang Chợ lắng nghe thay đổi của accessory_listings (đăng/bán/huỷ)
-- để tự làm mới, khỏi phải thoát ra vào lại. Cần bảng nằm trong publication
-- `supabase_realtime` (idempotent, bỏ qua nếu đã bật). RLS vẫn áp dụng cho
-- sự kiện: policy select_all ở trên cho mọi người đọc nên ai cũng nhận được.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'accessory_listings'
  ) then
    alter publication supabase_realtime add table accessory_listings;
  end if;
end $$;

-- ─────────────────────────────────────────────────────────────────────────
-- Huy hiệu bảng xếp hạng ("flair"): 1 phụ kiện hiển thị cạnh tên người chơi.
-- Một bảng riêng thay vì thêm cột vào 6 bảng xếp hạng. Ghi CHỈ qua
-- set_accessory_flair (kiểm tra sở hữu thật trong accessory_server_ownership).
-- Đọc qua accessory_flairs: chỉ trả huy hiệu mà chủ nhân VẪN còn sở hữu (bán
-- hết bản cuối thì tự biến mất, khỏi phải dọn trong list_accessory).
-- ─────────────────────────────────────────────────────────────────────────
create table if not exists accessory_flair (
  user_id       uuid primary key references auth.users(id) on delete cascade,
  accessory_id  text not null,
  updated_at    timestamptz not null default now()
);

alter table accessory_flair enable row level security;
-- Không policy nào: client chỉ đi qua 2 RPC bên dưới.

-- p_accessory_id null = gỡ huy hiệu.
create or replace function set_accessory_flair(p_accessory_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if p_accessory_id is null then
    delete from accessory_flair where user_id = auth.uid();
    return;
  end if;
  if not exists (
    select 1 from accessory_server_ownership
    where user_id = auth.uid() and accessory_id = p_accessory_id
  ) then
    raise exception 'not owned';
  end if;
  insert into accessory_flair (user_id, accessory_id)
  values (auth.uid(), p_accessory_id)
  on conflict (user_id) do update
    set accessory_id = excluded.accessory_id, updated_at = now();
end;
$$;

grant execute on function set_accessory_flair(text) to authenticated;

-- Cấp VIP theo tổng nạp (IAP) — client tự khai (xem lib/core/topup.dart), CHỈ TĂNG,
-- trần 10. Hiện cạnh tên ở các bảng xếp hạng/Hội qua accessory_flairs bên dưới.
create table if not exists vip_level (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  level       smallint not null check (level between 1 and 10),
  updated_at  timestamptz not null default now()
);

-- Bảng đã tạo với trần 8: nâng lên 10 (idempotent).
alter table vip_level drop constraint if exists vip_level_level_check;
alter table vip_level add constraint vip_level_level_check
  check (level between 1 and 10);

-- Danh hiệu hiển thị do người chơi chọn: null = tự động (cấp cao nhất), 0 = ẩn, 1..level =
-- danh hiệu của cấp đó. Bảng đã tạo từ trước chưa có cột → add column if not exists.
alter table vip_level add column if not exists title smallint;
alter table vip_level drop constraint if exists vip_level_title_check;
alter table vip_level add constraint vip_level_title_check
  check (title is null or title between 0 and 10);

alter table vip_level enable row level security;
-- Không policy nào: client chỉ đi qua RPC.

create or replace function set_vip_level(p_level integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if p_level is null or p_level < 1 then
    return;
  end if;
  insert into vip_level (user_id, level)
  values (auth.uid(), least(p_level, 10))
  on conflict (user_id) do update
    set level = greatest(vip_level.level, excluded.level), updated_at = now();
end;
$$;

-- Chọn danh hiệu hiển thị: null/-1 = tự động, 0 = ẩn, 1..cấp hiện tại = danh hiệu cấp đó.
create or replace function set_vip_title(p_title integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare v_level integer;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  select level into v_level from vip_level where user_id = auth.uid();
  if v_level is null then
    return; -- chưa có cấp VIP thì chưa có gì để chọn
  end if;
  if p_title is not null and p_title <> -1 and (p_title < 0 or p_title > v_level) then
    raise exception 'invalid title';
  end if;
  update vip_level
    set title = case when p_title is null or p_title = -1 then null else p_title end,
        updated_at = now()
    where user_id = auth.uid();
end;
$$;

revoke all on function set_vip_title(integer) from public, anon;
grant execute on function set_vip_title(integer) to authenticated;

revoke all on function set_vip_level(integer) from public, anon;
grant execute on function set_vip_level(integer) to authenticated;

-- Bảng xếp hạng VIP (web): xếp theo VIP EXP, client tự khai (xem lib/core/topup.dart) —
-- CHỈ TĂNG. Cấp suy ra ở server từ mốc EXP; mảng mốc PHẢI khớp `topupTiers` bên Dart
-- (test/core/vip_sql_test.dart so khớp). Chỉ người đã đặt biệt danh mới có hàng.
create table if not exists vip_leaderboard_entries (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  nickname    text not null check (char_length(nickname) between 1 and 20),
  vip_exp     bigint not null check (vip_exp between 0 and 100000000),
  updated_at  timestamptz not null default now()
);

alter table vip_leaderboard_entries enable row level security;
-- Không policy nào: ghi/đọc chỉ qua RPC.

create index if not exists vip_leaderboard_entries_exp_idx
  on vip_leaderboard_entries (vip_exp desc, updated_at asc);

create or replace function vip_level_for_exp(p_exp bigint)
returns integer
language sql
immutable
as $$
  select count(*)::integer
  from unnest(array[500, 1500, 2400, 4800, 8000, 16000, 28000, 40000, 60000, 80000]::bigint[]) as t(m)
  where p_exp >= t.m;
$$;

-- Tài khoản hiện tại đã liên kết email (không ẩn danh)? security definer vì vai trò authenticated không
-- đọc được auth.users. ÉP Ở SERVER (không chỉ ở app): ai ghi vào bảng này phải đã liên kết email. Định nghĩa
-- giống hệt ở mọi schema cần nó (create or replace) nên chạy file nào trước cũng được.
create or replace function is_linked_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from auth.users u where u.id = auth.uid() and not u.is_anonymous)
$$;
revoke all on function is_linked_user() from public, anon;
grant execute on function is_linked_user() to authenticated;

create or replace function submit_vip_exp(p_nickname text, p_exp bigint)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare v_name text := btrim(coalesce(p_nickname, ''));
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if not is_linked_user() then
    raise exception 'email link required';
  end if;
  -- Chưa có cấp VIP thì không lên bảng.
  if p_exp is null or vip_level_for_exp(p_exp) < 1 then
    return;
  end if;
  if char_length(v_name) not between 1 and 20 then
    raise exception 'bad nickname';
  end if;
  insert into vip_leaderboard_entries (user_id, nickname, vip_exp)
  values (auth.uid(), v_name, least(p_exp, 100000000))
  on conflict (user_id) do update
    set nickname = excluded.nickname,
        updated_at = case when excluded.vip_exp > vip_leaderboard_entries.vip_exp
                          then now() else vip_leaderboard_entries.updated_at end,
        vip_exp = greatest(vip_leaderboard_entries.vip_exp, excluded.vip_exp);
end;
$$;

revoke all on function submit_vip_exp(text, bigint) from public, anon;
grant execute on function submit_vip_exp(text, bigint) to authenticated;

-- Hiện diện + thông báo online cho VIP từ cấp 5 (vipTitleMinLevel bên Dart; test khớp).
-- vip_ping (client gọi lúc mở app và mỗi vài phút) ghi last_seen; lần đầu trong 1 giờ
-- thì chèn một dòng vip_announcements → mọi client đang mở app nhận qua realtime và
-- hiện banner. "Online" = last_seen trong 5 phút gần nhất. Cấp lấy từ vip_level (client
-- tự khai, làm giả được — chỉ là banner/chấm xanh).
create table if not exists vip_presence (
  user_id         uuid primary key references auth.users(id) on delete cascade,
  last_seen       timestamptz not null default now(),
  last_announced  timestamptz
);

alter table vip_presence enable row level security;
-- Không policy nào: đọc/ghi chỉ qua RPC.

create table if not exists vip_announcements (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  nickname    text not null,
  level       smallint not null,
  created_at  timestamptz not null default now()
);

alter table vip_announcements enable row level security;
drop policy if exists vip_announcements_select_all on vip_announcements;
create policy vip_announcements_select_all on vip_announcements
  for select to anon, authenticated using (true);
grant select on vip_announcements to anon, authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'vip_announcements'
  ) then
    alter publication supabase_realtime add table vip_announcements;
  end if;
end $$;

-- Trả true nếu vừa phát thông báo (tối đa 1 lần/giờ/người).
create or replace function vip_ping(p_nickname text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text := btrim(coalesce(p_nickname, ''));
  v_level integer;
  v_last timestamptz;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  select level into v_level from vip_level where user_id = auth.uid();
  if v_level is null or v_level < 5 then
    return false;
  end if;
  if char_length(v_name) not between 1 and 20 then
    raise exception 'bad nickname';
  end if;
  insert into vip_presence (user_id, last_seen)
  values (auth.uid(), now())
  on conflict (user_id) do update set last_seen = now();
  select last_announced into v_last from vip_presence where user_id = auth.uid();
  if v_last is not null and v_last > now() - interval '1 hour' then
    return false;
  end if;
  update vip_presence set last_announced = now() where user_id = auth.uid();
  delete from vip_announcements where created_at < now() - interval '1 day';
  insert into vip_announcements (user_id, nickname, level)
  values (auth.uid(), v_name, v_level);
  return true;
end;
$$;

revoke all on function vip_ping(text) from public, anon;
grant execute on function vip_ping(text) to authenticated;

-- Đổi cột trả về (thêm user_id, online) → drop hàm cũ.
drop function if exists vip_leaderboard_top(integer);

create or replace function vip_leaderboard_top(p_limit integer default 50)
returns table (rank bigint, user_id uuid, nickname text, vip_exp bigint,
               level integer, online boolean)
language sql
stable
security definer
set search_path = public
as $$
  select row_number() over (order by e.vip_exp desc, e.updated_at asc),
         e.user_id, e.nickname, e.vip_exp, vip_level_for_exp(e.vip_exp),
         coalesce(p.last_seen > now() - interval '5 minutes', false)
         and vip_level_for_exp(e.vip_exp) >= 5
  from vip_leaderboard_entries e
  left join vip_presence p on p.user_id = e.user_id
  order by e.vip_exp desc, e.updated_at asc
  limit least(greatest(p_limit, 1), 100);
$$;

grant execute on function vip_leaderboard_top(integer) to anon, authenticated;

-- Đổi cột trả về → phải drop hàm cũ. Bản app cũ chỉ đọc user_id/accessory_id
-- (accessory_id có thể null với người chỉ có VIP → bỏ qua), nên vẫn tương thích.
-- Thêm cột online (VIP ≥ 5 đang hiện diện).
drop function if exists accessory_flairs(uuid[]);

create or replace function accessory_flairs(p_user_ids uuid[])
returns table (user_id uuid, accessory_id text, vip_level integer, online boolean,
               title_level integer)
language sql
stable
security definer
set search_path = public
as $$
  select u.id,
         f.accessory_id,
         v.level::integer,
         coalesce(p.last_seen > now() - interval '5 minutes', false)
           and coalesce(v.level, 0) >= 5,
         -- Danh hiệu đang hiển thị: tự động = cấp hiện tại; 0 = ẩn.
         case when v.level is null then null
              else coalesce(v.title, v.level)::integer end
  from unnest(p_user_ids[1:100]) as u(id)
  left join accessory_flair f
    on f.user_id = u.id
   and exists (
     select 1 from accessory_server_ownership o
     where o.user_id = f.user_id and o.accessory_id = f.accessory_id
   )
  left join vip_level v on v.user_id = u.id
  left join vip_presence p on p.user_id = u.id
  where f.accessory_id is not null or v.level is not null;
$$;

grant execute on function accessory_flairs(uuid[]) to anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- Gói Khởi Nghiệp Chợ: MỘT LẦN mỗi tài khoản — 1 phụ kiện Thường + 1 bản dư
-- (bán được) + 10 Xu Chợ, để người mới có thứ để bán/mua ngay.
-- Chống cày bằng danh tính ẩn danh mới: (1) chỉ mở khi có tiến độ thật
-- (giai đoạn ≥ 3 và ≥ 1 nhiệm vụ ngày đã nhận) — NHƯNG tiến độ do client tự
-- khai nên làm giả được, cùng mức tin cậy với register_accessory_drop; (2) một
-- lần/tài khoản (PK user_id); (3) trần TOÀN CỤC mỗi ngày để cày hàng loạt chỉ
-- rút được tối đa 500 gói/ngày × 10 Xu Chợ. Lỗi: already_claimed |
-- not_eligible | daily_cap.
-- ─────────────────────────────────────────────────────────────────────────
create table if not exists accessory_starter (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  claimed_at  timestamptz not null default now()
);

alter table accessory_starter enable row level security;
-- Không policy nào: chỉ ghi/đọc qua RPC.

create or replace function claim_starter_pack(
  p_accessory_id text, p_stage integer, p_quests integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if p_stage < 3 or p_quests < 1 then
    raise exception 'not_eligible';
  end if;
  if exists (select 1 from accessory_starter where user_id = auth.uid()) then
    raise exception 'already_claimed';
  end if;
  if (select count(*) from accessory_starter
      where claimed_at >= date_trunc('day', now())) >= 500 then
    raise exception 'daily_cap';
  end if;

  insert into accessory_starter (user_id) values (auth.uid());
  insert into accessory_server_ownership (user_id, accessory_id, copies)
  values (auth.uid(), p_accessory_id, 2)
  on conflict (user_id, accessory_id) do update
    set copies = accessory_server_ownership.copies + 2;
  insert into accessory_wallets (user_id, balance)
  values (auth.uid(), 10)
  on conflict (user_id) do update
    set balance = accessory_wallets.balance + 10;
end;
$$;

grant execute on function claim_starter_pack(text, integer, integer) to authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- Mốc sưu tập 10/25/40/50/80/100/120/140/160 món: thưởng Xu Chợ MỘT LẦN mỗi mốc. Server tự đếm
-- số món khác nhau (đang giữ + đang rao bán) nên client không khai khống số
-- lượng được — chỉ có thể bơm món giả qua register_accessory_drop (cùng mức
-- tin cậy cũ). Thưởng cố định, một chiều (Xu Chợ không đổi ra Xu/💎 thật),
-- tối đa 4570 Xu Chợ cả đời mỗi tài khoản. Lỗi: invalid_milestone |
-- not_reached | already_claimed.
-- ─────────────────────────────────────────────────────────────────────────
create table if not exists accessory_milestone_claims (
  user_id    uuid not null references auth.users(id) on delete cascade,
  milestone  integer not null,
  claimed_at timestamptz not null default now(),
  primary key (user_id, milestone)
);

alter table accessory_milestone_claims enable row level security;
-- Không policy nào: chỉ qua RPC.

create or replace function claim_collection_milestone(p_milestone integer)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_reward integer;
  v_owned integer;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  v_reward := case p_milestone
    when 10 then 20 when 25 then 50 when 40 then 100 when 50 then 200
    when 80 then 300 when 100 then 500 when 120 then 800
    when 140 then 1100 when 160 then 1500
    else null end;
  if v_reward is null then
    raise exception 'invalid_milestone';
  end if;
  select count(*) into v_owned from (
    select accessory_id from accessory_server_ownership where user_id = auth.uid()
    union
    select accessory_id from accessory_listings
      where seller_id = auth.uid() and status = 'active'
  ) t;
  if v_owned < p_milestone then
    raise exception 'not_reached';
  end if;
  if exists (select 1 from accessory_milestone_claims
             where user_id = auth.uid() and milestone = p_milestone) then
    raise exception 'already_claimed';
  end if;

  insert into accessory_milestone_claims (user_id, milestone)
  values (auth.uid(), p_milestone);
  insert into accessory_wallets (user_id, balance)
  values (auth.uid(), v_reward)
  on conflict (user_id) do update
    set balance = accessory_wallets.balance + v_reward;
  return v_reward;
end;
$$;

grant execute on function claim_collection_milestone(integer) to authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- Mốc sưu tập THEO BỘ: đủ mọi món của một bộ (4 độ hiếm + 4 họ buff, chỉ 160 món chính) thì nhận
-- Xu Chợ MỘT LẦN mỗi bộ. Server giữ danh sách món của bộ (accessory_set_members — SINH TỪ
-- lib/core/collection_sets.dart, test khớp) nên client không khai khống được. Một chiều, tối đa
-- 2850 Xu Chợ cả đời mỗi tài khoản. Lỗi: invalid_set | not_reached | already_claimed.
-- ─────────────────────────────────────────────────────────────────────────
create table if not exists accessory_set_members (
  set_id       text not null,
  accessory_id text not null,
  primary key (set_id, accessory_id)
);
alter table accessory_set_members enable row level security;
-- Không policy nào: chỉ đọc trong hàm security definer.

insert into accessory_set_members (set_id, accessory_id) values
    ('rarity_legendary','dragon'),
    ('rarity_legendary','phoenix'),
    ('rarity_legendary','galaxy'),
    ('rarity_legendary','kraken'),
    ('rarity_legendary','thunderbolt'),
    ('rarity_legendary','genie'),
    ('rarity_legendary','volcano'),
    ('rarity_legendary','mermaid'),
    ('rarity_legendary','eagle'),
    ('rarity_epic','crystal_ball'),
    ('rarity_epic','lantern'),
    ('rarity_epic','unicorn'),
    ('rarity_epic','magic_wand'),
    ('rarity_epic','trident'),
    ('rarity_epic','peacock'),
    ('rarity_epic','comet'),
    ('rarity_epic','butterfly'),
    ('rarity_epic','angel_wing'),
    ('rarity_epic','amphora'),
    ('rarity_epic','rainbow'),
    ('rarity_epic','fairy'),
    ('rarity_epic','disco_ball'),
    ('rarity_epic','shining_star'),
    ('rarity_epic','swan'),
    ('rarity_epic','flamingo'),
    ('rarity_epic','owl'),
    ('rarity_epic','whale'),
    ('rarity_epic','crown'),
    ('rarity_epic','circus_tent'),
    ('rarity_epic','pinata'),
    ('rarity_epic','castle'),
    ('rarity_epic','leopard'),
    ('rarity_epic','elephant'),
    ('rarity_epic','panda'),
    ('rarity_epic','giraffe'),
    ('rarity_epic','turtle'),
    ('rarity_epic','koala'),
    ('rarity_epic','penguin'),
    ('rarity_epic','sauropod'),
    ('rarity_rare','seashell'),
    ('rarity_rare','mask'),
    ('rarity_rare','drum'),
    ('rarity_rare','palette'),
    ('rarity_rare','key'),
    ('rarity_rare','diamond_stone'),
    ('rarity_rare','music_note'),
    ('rarity_rare','telescope'),
    ('rarity_rare','anchor'),
    ('rarity_rare','feather'),
    ('rarity_rare','hourglass'),
    ('rarity_rare','map'),
    ('rarity_rare','ring'),
    ('rarity_rare','compass'),
    ('rarity_rare','rocket'),
    ('rarity_rare','violin'),
    ('rarity_rare','scroll'),
    ('rarity_rare','microphone'),
    ('rarity_rare','lotus'),
    ('rarity_rare','jellyfish'),
    ('rarity_rare','camera'),
    ('rarity_rare','shield'),
    ('rarity_rare','guitar'),
    ('rarity_rare','trumpet'),
    ('rarity_rare','piano'),
    ('rarity_rare','saxophone'),
    ('rarity_rare','banjo'),
    ('rarity_rare','microscope'),
    ('rarity_rare','ringed_planet'),
    ('rarity_rare','crescent_moon'),
    ('rarity_rare','bow_arrow'),
    ('rarity_rare','mirror'),
    ('rarity_rare','ferris_wheel'),
    ('rarity_rare','carousel'),
    ('rarity_rare','puzzle'),
    ('rarity_rare','dice'),
    ('rarity_rare','chess_pawn'),
    ('rarity_rare','dart'),
    ('rarity_rare','bowling'),
    ('rarity_rare','yo_yo'),
    ('rarity_rare','roller_skate'),
    ('rarity_rare','skateboard'),
    ('rarity_rare','satellite'),
    ('rarity_rare','alembic'),
    ('rarity_rare','dna'),
    ('rarity_rare','trophy'),
    ('rarity_common','mint_leaf'),
    ('rarity_common','cupcake'),
    ('rarity_common','cookie'),
    ('rarity_common','potted_plant'),
    ('rarity_common','candle'),
    ('rarity_common','scarf'),
    ('rarity_common','kite'),
    ('rarity_common','cap'),
    ('rarity_common','balloon'),
    ('rarity_common','bowtie'),
    ('rarity_common','sunglasses'),
    ('rarity_common','umbrella'),
    ('rarity_common','teapot'),
    ('rarity_common','bell'),
    ('rarity_common','ribbon'),
    ('rarity_common','bookmark'),
    ('rarity_common','wind_chime'),
    ('rarity_common','clover'),
    ('rarity_common','bubble'),
    ('rarity_common','sticker'),
    ('rarity_common','yarn'),
    ('rarity_common','fan'),
    ('rarity_common','basket'),
    ('rarity_common','bead'),
    ('rarity_common','ladybug'),
    ('rarity_common','donut'),
    ('rarity_common','lollipop'),
    ('rarity_common','pretzel'),
    ('rarity_common','ice_cream'),
    ('rarity_common','strawberry'),
    ('rarity_common','cherry'),
    ('rarity_common','lemon'),
    ('rarity_common','peach'),
    ('rarity_common','popcorn'),
    ('rarity_common','honey_pot'),
    ('rarity_common','milk_glass'),
    ('rarity_common','tangerine'),
    ('rarity_common','chestnut'),
    ('rarity_common','maple_leaf'),
    ('rarity_common','ice_cube'),
    ('rarity_common','croissant'),
    ('rarity_common','pancakes'),
    ('rarity_common','waffle'),
    ('rarity_common','bagel'),
    ('rarity_common','cake_slice'),
    ('rarity_common','pie'),
    ('rarity_common','candy'),
    ('rarity_common','grapes'),
    ('rarity_common','watermelon'),
    ('rarity_common','pineapple'),
    ('rarity_common','mango'),
    ('rarity_common','kiwi'),
    ('rarity_common','banana'),
    ('rarity_common','apple'),
    ('rarity_common','teddy'),
    ('rarity_common','crayon'),
    ('rarity_common','bucket'),
    ('rarity_common','carrot'),
    ('rarity_common','corn'),
    ('rarity_common','tomato'),
    ('rarity_common','avocado'),
    ('rarity_common','coconut'),
    ('rarity_common','blueberries'),
    ('rarity_common','pear'),
    ('rarity_common','rice_ball'),
    ('rarity_common','dumpling'),
    ('rarity_common','sushi'),
    ('rarity_common','ramen'),
    ('rarity_common','taco'),
    ('rarity_common','pizza'),
    ('rarity_common','hot_dog'),
    ('rarity_common','fries'),
    ('rarity_common','egg'),
    ('rarity_common','bread'),
    ('rarity_common','butter'),
    ('family_tap','mint_leaf'),
    ('family_tap','candle'),
    ('family_tap','balloon'),
    ('family_tap','teapot'),
    ('family_tap','wind_chime'),
    ('family_tap','yarn'),
    ('family_tap','ladybug'),
    ('family_tap','ice_cream'),
    ('family_tap','peach'),
    ('family_tap','tangerine'),
    ('family_tap','croissant'),
    ('family_tap','cake_slice'),
    ('family_tap','watermelon'),
    ('family_tap','banana'),
    ('family_tap','bucket'),
    ('family_tap','avocado'),
    ('family_tap','rice_ball'),
    ('family_tap','taco'),
    ('family_tap','egg'),
    ('family_tap','seashell'),
    ('family_tap','key'),
    ('family_tap','anchor'),
    ('family_tap','ring'),
    ('family_tap','scroll'),
    ('family_tap','camera'),
    ('family_tap','piano'),
    ('family_tap','ringed_planet'),
    ('family_tap','ferris_wheel'),
    ('family_tap','chess_pawn'),
    ('family_tap','roller_skate'),
    ('family_tap','dna'),
    ('family_tap','crystal_ball'),
    ('family_tap','trident'),
    ('family_tap','angel_wing'),
    ('family_tap','disco_ball'),
    ('family_tap','owl'),
    ('family_tap','pinata'),
    ('family_tap','panda'),
    ('family_tap','penguin'),
    ('family_tap','dragon'),
    ('family_tap','thunderbolt'),
    ('family_tap','eagle'),
    ('family_income','cupcake'),
    ('family_income','scarf'),
    ('family_income','bowtie'),
    ('family_income','bell'),
    ('family_income','clover'),
    ('family_income','fan'),
    ('family_income','donut'),
    ('family_income','strawberry'),
    ('family_income','popcorn'),
    ('family_income','chestnut'),
    ('family_income','pancakes'),
    ('family_income','pie'),
    ('family_income','pineapple'),
    ('family_income','apple'),
    ('family_income','carrot'),
    ('family_income','coconut'),
    ('family_income','dumpling'),
    ('family_income','pizza'),
    ('family_income','bread'),
    ('family_income','mask'),
    ('family_income','diamond_stone'),
    ('family_income','feather'),
    ('family_income','compass'),
    ('family_income','microphone'),
    ('family_income','shield'),
    ('family_income','saxophone'),
    ('family_income','crescent_moon'),
    ('family_income','carousel'),
    ('family_income','dart'),
    ('family_income','skateboard'),
    ('family_income','trophy'),
    ('family_income','lantern'),
    ('family_income','peacock'),
    ('family_income','amphora'),
    ('family_income','shining_star'),
    ('family_income','whale'),
    ('family_income','castle'),
    ('family_income','giraffe'),
    ('family_income','sauropod'),
    ('family_income','phoenix'),
    ('family_income','genie'),
    ('family_offline','cookie'),
    ('family_offline','kite'),
    ('family_offline','sunglasses'),
    ('family_offline','ribbon'),
    ('family_offline','bubble'),
    ('family_offline','basket'),
    ('family_offline','lollipop'),
    ('family_offline','cherry'),
    ('family_offline','honey_pot'),
    ('family_offline','maple_leaf'),
    ('family_offline','waffle'),
    ('family_offline','candy'),
    ('family_offline','mango'),
    ('family_offline','teddy'),
    ('family_offline','corn'),
    ('family_offline','blueberries'),
    ('family_offline','sushi'),
    ('family_offline','hot_dog'),
    ('family_offline','butter'),
    ('family_offline','drum'),
    ('family_offline','music_note'),
    ('family_offline','hourglass'),
    ('family_offline','rocket'),
    ('family_offline','lotus'),
    ('family_offline','guitar'),
    ('family_offline','banjo'),
    ('family_offline','bow_arrow'),
    ('family_offline','puzzle'),
    ('family_offline','bowling'),
    ('family_offline','satellite'),
    ('family_offline','unicorn'),
    ('family_offline','comet'),
    ('family_offline','rainbow'),
    ('family_offline','swan'),
    ('family_offline','crown'),
    ('family_offline','leopard'),
    ('family_offline','turtle'),
    ('family_offline','galaxy'),
    ('family_offline','volcano'),
    ('family_discount','potted_plant'),
    ('family_discount','cap'),
    ('family_discount','umbrella'),
    ('family_discount','bookmark'),
    ('family_discount','sticker'),
    ('family_discount','bead'),
    ('family_discount','pretzel'),
    ('family_discount','lemon'),
    ('family_discount','milk_glass'),
    ('family_discount','ice_cube'),
    ('family_discount','bagel'),
    ('family_discount','grapes'),
    ('family_discount','kiwi'),
    ('family_discount','crayon'),
    ('family_discount','tomato'),
    ('family_discount','pear'),
    ('family_discount','ramen'),
    ('family_discount','fries'),
    ('family_discount','palette'),
    ('family_discount','telescope'),
    ('family_discount','map'),
    ('family_discount','violin'),
    ('family_discount','jellyfish'),
    ('family_discount','trumpet'),
    ('family_discount','microscope'),
    ('family_discount','mirror'),
    ('family_discount','dice'),
    ('family_discount','yo_yo'),
    ('family_discount','alembic'),
    ('family_discount','magic_wand'),
    ('family_discount','butterfly'),
    ('family_discount','fairy'),
    ('family_discount','flamingo'),
    ('family_discount','circus_tent'),
    ('family_discount','elephant'),
    ('family_discount','koala'),
    ('family_discount','kraken'),
    ('family_discount','mermaid')
on conflict do nothing;

create table if not exists accessory_set_claims (
  user_id    uuid not null references auth.users(id) on delete cascade,
  set_id     text not null,
  claimed_at timestamptz not null default now(),
  primary key (user_id, set_id)
);
alter table accessory_set_claims enable row level security;

create or replace function claim_collection_set(p_set text)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_reward integer;
  v_missing integer;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  v_reward := case p_set
    when 'rarity_legendary' then 150 when 'rarity_epic' then 300
    when 'rarity_rare' then 400 when 'rarity_common' then 400
    when 'family_tap' then 400 when 'family_income' then 400
    when 'family_offline' then 400 when 'family_discount' then 400
    else null end;
  if v_reward is null then
    raise exception 'invalid_set';
  end if;
  select count(*) into v_missing from accessory_set_members m
  where m.set_id = p_set
    and m.accessory_id not in (
      select accessory_id from accessory_server_ownership where user_id = auth.uid()
      union
      select accessory_id from accessory_listings
        where seller_id = auth.uid() and status = 'active');
  if v_missing > 0 then
    raise exception 'not_reached';
  end if;
  if exists (select 1 from accessory_set_claims where user_id = auth.uid() and set_id = p_set) then
    raise exception 'already_claimed';
  end if;

  insert into accessory_set_claims (user_id, set_id) values (auth.uid(), p_set);
  insert into accessory_wallets (user_id, balance)
  values (auth.uid(), v_reward)
  on conflict (user_id) do update
    set balance = accessory_wallets.balance + v_reward;
  return v_reward;
end;
$$;

grant execute on function claim_collection_set(text) to authenticated;

-- Giá tham khảo theo món, ẩn danh (không lộ id người mua/bán): giá khớp gần
-- nhất, giá rẻ nhất đang rao, và số giao dịch + giá TB 7 ngày. Trả đúng 1 hàng
-- (các cột có thể null nếu chưa có dữ liệu).
create or replace function accessory_price_stats(p_accessory_id text)
returns table (
  last_price bigint, lowest_active bigint, trades_7d integer, avg_7d bigint)
language sql
stable
security definer
set search_path = public
as $$
  select
    (select price from accessory_market_trades
       where accessory_id = p_accessory_id order by traded_at desc limit 1),
    (select min(price) from accessory_listings
       where accessory_id = p_accessory_id and status = 'active'
         and created_at > now() - make_interval(days => market_listing_days())),
    (select count(*)::integer from accessory_market_trades
       where accessory_id = p_accessory_id
         and traded_at > now() - interval '7 days'),
    (select round(avg(price))::bigint from accessory_market_trades
       where accessory_id = p_accessory_id
         and traded_at > now() - interval '7 days');
$$;

grant execute on function accessory_price_stats(text) to anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- Danh sách muốn có (wishlist): tối đa 10 món/người. Chỉ để Edge Function
-- notify-market-sale đẩy "món bạn muốn vừa được đăng bán" (webhook thứ 2, trên
-- accessory_listings INSERT — xem đầu file index.ts). Ghi qua RPC thay thế cả
-- danh sách; không có policy nào cho client, Edge Function đọc bằng service role.
-- ─────────────────────────────────────────────────────────────────────────
create table if not exists accessory_wishlist (
  user_id       uuid not null references auth.users(id) on delete cascade,
  accessory_id  text not null,
  primary key (user_id, accessory_id)
);

create index if not exists accessory_wishlist_item_idx
  on accessory_wishlist (accessory_id);

alter table accessory_wishlist enable row level security;

create or replace function set_accessory_wishlist(p_ids text[])
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if coalesce(array_length(p_ids, 1), 0) > 10 then
    raise exception 'too_many';
  end if;
  delete from accessory_wishlist where user_id = auth.uid();
  insert into accessory_wishlist (user_id, accessory_id)
  select auth.uid(), left(id, 64) from unnest(p_ids) as id
  on conflict do nothing;
end;
$$;

grant execute on function set_accessory_wishlist(text[]) to authenticated;

-- Xem bộ sưu tập của người khác từ bảng xếp hạng Sưu tập: chỉ trả id món (đang
-- giữ + đang rao bán — cùng cách đếm của bảng xếp hạng), không lộ gì khác.
-- user_id vốn đã công khai trên bảng xếp hạng.
create or replace function accessory_collection_of(p_user_id uuid)
returns table (accessory_id text)
language sql
stable
security definer
set search_path = public
as $$
  select o.accessory_id from accessory_server_ownership o
    where o.user_id = p_user_id
  union
  select l.accessory_id from accessory_listings l
    where l.seller_id = p_user_id and l.status = 'active';
$$;

grant execute on function accessory_collection_of(uuid) to anon, authenticated;

-- ===== leaderboard_rewards_schema.sql =====
-- Thưởng top bảng xếp hạng theo tuần (góp ý người chơi: "thưởng cho top 1,2,3 BXH").
-- Sáu bảng TÍCH LŨY: income (Thu nhập), pearls (Trân Châu Rơi), collection (Sưu tập), vip, recipes (Thợ pha chế),
-- orders (Pha theo đơn); cộng bảng 'daily' (Thử thách ngày): xếp theo TỔNG điểm thử thách của TUẦN TRƯỚC
-- (thứ Hai-Chủ nhật UTC), top 10 (các bảng kia chỉ top 3). Mỗi tuần
-- (thứ Hai 00:00 UTC) top 3 của mỗi bảng nhận 300 / 200 / 100 💎 — nhận MỘT LẦN cho mỗi (tuần, bảng). Riêng
-- 'daily': hạng 4-10 nhận 50 💎 (xem lb_reward_gems_for).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase SQL Editor → Run. Idempotent. Chạy SAU
-- leaderboard_schema, m3_leaderboard_schema, accessory_leaderboard_schema, recipe_leaderboard_schema,
-- recipe_order_leaderboard_schema, arena_schema (+ arena_leaderboard_schema) và accessory_market_schema (bảng vip_leaderboard_entries nằm ở đó). KHÔNG đụng bảng/hàm cũ.
--
-- Cách tính: KHÔNG cần cron. Lần đầu có người gọi lb_reward_status() trong tuần mới thì server chụp top 3
-- hiện tại của từng bảng và gắn nhãn tuần đó ("bảng xếp hạng chốt đầu tuần"); ai nằm trong ảnh chụp thì
-- nhận được trong tuần đó và tuần kế (hết hạn sau 2 tuần). Muốn chốt đúng 00:00 thứ Hai, bật pg_cron:
--   select cron.schedule('lb-rewards-snapshot', '0 0 * * 1', 'select lb_reward_snapshot()');
--
-- Chống gian lận: điểm trên các bảng do client tự khai, nên chỉ tài khoản đã LIÊN KẾT email (không ẩn
-- danh) và điểm > 0 mới được vào ảnh chụp. Hạng/điểm cùng thứ tự với bảng công khai (xem
-- player_profile_schema.sql): điểm giảm dần, hoà thì ai nộp sớm hơn (updated_at) xếp trên.

create table if not exists lb_reward_snapshots (
  week      date    not null,
  board     text    not null,
  rank      integer not null check (rank between 1 and 10),
  user_id   uuid    not null references auth.users(id) on delete cascade,
  nickname  text    not null,
  value     numeric not null,
  primary key (week, board, rank)
);
create index if not exists lb_reward_snapshots_user_idx on lb_reward_snapshots (user_id, week);

create table if not exists lb_reward_claims (
  user_id    uuid    not null references auth.users(id) on delete cascade,
  week       date    not null,
  board      text    not null,
  gems       integer not null,
  claimed_at timestamptz not null default now(),
  primary key (user_id, week, board)
);

-- Bảng đã tạo từ khi còn 4 bảng có CHECK cũ: bỏ rồi tạo lại với bảng 'recipes', 'orders' (idempotent).
alter table lb_reward_snapshots drop constraint if exists lb_reward_snapshots_board_check;
alter table lb_reward_snapshots add constraint lb_reward_snapshots_board_check
  check (board in ('income', 'pearls', 'collection', 'vip', 'recipes', 'orders', 'daily', 'arena'));
-- Bảng đã tạo khi hạng chỉ 1..3: nới lên 1..10 cho bảng 'daily' (idempotent).
alter table lb_reward_snapshots drop constraint if exists lb_reward_snapshots_rank_check;
alter table lb_reward_snapshots add constraint lb_reward_snapshots_rank_check check (rank between 1 and 10);

alter table lb_reward_snapshots enable row level security;
alter table lb_reward_claims    enable row level security;
-- Cố ý KHÔNG tạo policy: chỉ RPC security definer được đụng vào.

create or replace function lb_reward_week() returns date
language sql stable as $$ select date_trunc('week', now() at time zone 'utc')::date $$;

-- 💎 theo hạng. Khớp lib/core/lb_rewards.dart (test so khớp).
create or replace function lb_reward_gems(p_rank integer) returns integer
language sql immutable as $$
  select case p_rank when 1 then 300 when 2 then 200 when 3 then 100 else 0 end
$$;

-- 💎 theo (bảng, hạng): như lb_reward_gems, riêng bảng 'daily' hạng 4-10 nhận 50. Khớp lbRewardGemsForBoard (Dart).
create or replace function lb_reward_gems_for(p_board text, p_rank integer) returns integer
language sql immutable as $$
  select case when p_board = 'daily' and p_rank between 4 and 10 then 50
              when p_board = 'arena' and p_rank between 4 and 10 then 50
              else lb_reward_gems(p_rank) end
$$;

-- Thưởng còn nhận được trong bao nhiêu tuần kể từ tuần chụp (tuần chụp + tuần kế).
create or replace function lb_reward_valid_weeks() returns integer
language sql immutable as $$ select 2 $$;

-- Chụp top 3 từng bảng cho tuần hiện tại nếu CHƯA có (idempotent; khoá để hai người gọi cùng lúc
-- không chụp hai lần). Nội bộ — client không gọi trực tiếp.
create or replace function lb_reward_snapshot() returns void
language plpgsql security definer set search_path = public as $$
declare
  v_week date := lb_reward_week();
  v_to   integer := (lb_reward_week() - date '1970-01-01');  -- số ngày từ epoch của thứ Hai tuần này (= dayIndex ở app)
  v_from integer := (lb_reward_week() - date '1970-01-01') - 7;
begin
  perform pg_advisory_xact_lock(hashtext('lb_reward_snapshot'));
  if exists (select 1 from lb_reward_snapshots where week = v_week) then return; end if;

  insert into lb_reward_snapshots (week, board, rank, user_id, nickname, value)
  select v_week, b.board, b.rn, b.user_id, b.nickname, b.v from (
    select 'income'::text as board, r.user_id, r.nickname, r.v,
           row_number() over (order by r.v desc, r.updated_at asc)::integer as rn
      from (select e.user_id, e.nickname, e.lifetime_earnings::numeric as v, e.updated_at
              from leaderboard_entries e join auth.users u on u.id = e.user_id
             where not u.is_anonymous and e.lifetime_earnings > 0) r
  ) b where b.rn <= 3
  union all
  select v_week, b.board, b.rn, b.user_id, b.nickname, b.v from (
    select 'pearls'::text as board, r.user_id, r.nickname, r.v,
           row_number() over (order by r.v desc, r.updated_at asc)::integer as rn
      from (select e.user_id, e.nickname, e.stars::numeric as v, e.updated_at
              from m3_leaderboard_entries e join auth.users u on u.id = e.user_id
             where not u.is_anonymous and e.stars > 0) r
  ) b where b.rn <= 3
  union all
  select v_week, b.board, b.rn, b.user_id, b.nickname, b.v from (
    select 'collection'::text as board, r.user_id, r.nickname, r.v,
           row_number() over (order by r.v desc, r.updated_at asc)::integer as rn
      from (select e.user_id, e.nickname, e.owned_count::numeric as v, e.updated_at
              from accessory_leaderboard_entries e join auth.users u on u.id = e.user_id
             where not u.is_anonymous and e.owned_count > 0) r
  ) b where b.rn <= 3
  union all
  select v_week, b.board, b.rn, b.user_id, b.nickname, b.v from (
    select 'vip'::text as board, r.user_id, r.nickname, r.v,
           row_number() over (order by r.v desc, r.updated_at asc)::integer as rn
      from (select e.user_id, e.nickname, e.vip_exp::numeric as v, e.updated_at
              from vip_leaderboard_entries e join auth.users u on u.id = e.user_id
             where not u.is_anonymous and e.vip_exp > 0) r
  ) b where b.rn <= 3
  union all
  select v_week, b.board, b.rn, b.user_id, b.nickname, b.v from (
    select 'recipes'::text as board, r.user_id, r.nickname, r.v,
           row_number() over (order by r.v desc, r.updated_at asc)::integer as rn
      from (select e.user_id, e.nickname, e.mastered::numeric as v, e.updated_at
              from recipe_leaderboard_entries e join auth.users u on u.id = e.user_id
             where not u.is_anonymous and e.mastered > 0) r
  ) b where b.rn <= 3
  union all
  select v_week, b.board, b.rn, b.user_id, b.nickname, b.v from (
    select 'orders'::text as board, r.user_id, r.nickname, r.v,
           row_number() over (order by r.v desc, r.updated_at asc)::integer as rn
      from (select e.user_id, e.nickname, e.perfected::numeric as v, e.updated_at
              from recipe_order_leaderboard_entries e join auth.users u on u.id = e.user_id
             where not u.is_anonymous and e.perfected > 0) r
  ) b where b.rn <= 3
  union all
  select v_week, b.board, b.rn, b.user_id, b.nickname, b.v from (
    select 'daily'::text as board, r.user_id, r.nickname, r.v,
           row_number() over (order by r.v desc, r.last_at asc)::integer as rn
      from (select d.user_id, (array_agg(d.nickname order by d.day desc))[1] as nickname,
                   sum(d.score)::numeric as v, max(d.updated_at) as last_at
              from recipe_daily_scores d join auth.users u on u.id = d.user_id
             where not u.is_anonymous and d.day >= v_from and d.day < v_to
             group by d.user_id having sum(d.score) > 0) r
  ) b where b.rn <= 10
  union all
  -- Giải đấu Đấu Trường tuần: số TRẬN THẮNG THẬT (không tính trận bóng ma) của tuần trước, top 10. Chống đổi thắng:
  -- mỗi đối thủ chỉ tính tối đa 3 trận thắng/tuần.
  select v_week, b.board, b.rn, b.user_id, b.nickname, b.v from (
    select 'arena'::text as board, r.user_id, r.nickname, r.v,
           row_number() over (order by r.v desc, r.last_at asc)::integer as rn
      from (select w.winner as user_id, coalesce(n.nickname, '???') as nickname,
                   count(*)::numeric as v, max(w.started_at) as last_at
              from (select m.winner, m.started_at,
                           row_number() over (partition by m.winner,
                             case when m.winner = m.player_a then m.player_b else m.player_a end
                             order by m.started_at) as k
                      from arena_matches m
                     where m.status = 'finished' and not m.ghost and m.winner is not null
                       and m.started_at >= v_week::timestamptz - interval '7 days'
                       and m.started_at < v_week::timestamptz) w
              join auth.users u on u.id = w.winner
              left join arena_nicknames n on n.user_id = w.winner
             where w.k <= 3 and not u.is_anonymous
             group by w.winner, n.nickname) r
  ) b where b.rn <= 10;
end;
$$;

-- Thưởng của MÌNH còn trong hạn: [{week, board, rank, gems, claimed}], mới nhất trước. Gọi hàm này cũng
-- kích hoạt việc chụp của tuần mới (xem đầu file).
create or replace function lb_reward_status() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  perform lb_reward_snapshot();
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'week', s.week, 'board', s.board, 'rank', s.rank,
             'gems', lb_reward_gems_for(s.board, s.rank),
             'claimed', exists (select 1 from lb_reward_claims c
                                  where c.user_id = v_uid and c.week = s.week and c.board = s.board))
           order by s.week desc, s.board, s.rank)
      from lb_reward_snapshots s
     where s.user_id = v_uid
       and s.week > lb_reward_week() - 7 * lb_reward_valid_weeks()), '[]'::jsonb);
end;
$$;

-- Nhận thưởng của (tuần, bảng): phải đúng người trong ảnh chụp, còn hạn, chưa nhận. Trả về số 💎;
-- client cộng 💎 cục bộ SAU khi hàm này thành công (cùng khuôn rương Boss của Hội).
create or replace function lb_reward_claim(p_week date, p_board text) returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_rank integer;
  v_gems integer;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select s.rank into v_rank from lb_reward_snapshots s
   where s.week = p_week and s.board = p_board and s.user_id = v_uid
     and s.week > lb_reward_week() - 7 * lb_reward_valid_weeks();
  if v_rank is null then raise exception 'not found'; end if;
  v_gems := lb_reward_gems_for(p_board, v_rank);
  begin
    insert into lb_reward_claims (user_id, week, board, gems) values (v_uid, p_week, p_board, v_gems);
  exception when unique_violation then
    raise exception 'already claimed';
  end;
  return v_gems;
end;
$$;

-- Quyền: chỉ người đã đăng nhập gọi được RPC; hàm nội bộ khoá hẳn.
revoke all on function lb_reward_status() from public, anon;
revoke all on function lb_reward_claim(date, text) from public, anon;
grant execute on function lb_reward_status() to authenticated;
grant execute on function lb_reward_claim(date, text) to authenticated;
revoke all on function lb_reward_snapshot() from public, anon, authenticated;

-- ===== arena_schema.sql =====
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
-- Trận "bóng ma" (2026-10-18): chờ ghép quá 12 giây thì đấu lại bản ghi của một trận cũ. player_b là
-- chủ bản ghi (người thật, KHÔNG biết và không bị tính thắng/thua), hành động của họ được sao chép với
-- mốc thời gian dịch sang trận mới. Không vào bảng xếp hạng, không chiếm chỗ trận của chủ bản ghi.
alter table arena_matches add column if not exists ghost boolean not null default false;
alter table arena_actions add column if not exists rot  smallint;
alter table arena_actions add column if not exists col  smallint;
alter table arena_actions add column if not exists cell smallint;
alter table arena_actions add column if not exists dir  smallint;

-- check của `kind` là ràng buộc không tên khi tạo bảng → tên tự sinh mặc định.
alter table arena_actions drop constraint if exists arena_actions_kind_check;
alter table arena_actions add constraint arena_actions_kind_check
  check (kind in ('tap', 'buy_tier_1', 'buy_tier_2', 'buy_tier_3', 'drop', 'swap', 'serve'));

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


-- ─────────────────────────────────────────────────────────────────────────
-- Dạng 'recipe' (PK công thức, 2026-10-16): cả hai người pha CÙNG 5 đơn Pha theo đơn (server chọn
-- 5 món nhóm 1, lưu ở `arena_matches.seq`), mỗi đơn nộp MỘT lần qua `arena_submit_order`; server tự
-- chấm bằng `arena_recipe_order_score` (khớp `scoreOrder` ở lib/core/recipe_orders.dart: đúng lượng +1,
-- lệch 1 mức +0.5, thừa −0.5, chia số nguyên liệu, 0..100/đơn) rồi ghi vào `arena_actions.score`.
-- Điểm trận = tổng điểm 5 đơn (tối đa 500). Xong cả hai thì chốt sớm, không thì chờ hết 180 giây.
--
-- ⚠️ Danh sách món (nhóm 1 của assets/recipes/recipes.json) và hai bảng bước lượng
-- (`recipeGramSteps`/`recipeMlSteps` ở recipe_orders.dart) phải khớp bên dưới — có test Dart đối chiếu.
-- ─────────────────────────────────────────────────────────────────────────

create table if not exists arena_recipes (
  id          int primary key,
  ingredients jsonb not null
);
alter table arena_recipes enable row level security; -- không policy: client không đọc/ghi trực tiếp

insert into arena_recipes (id, ingredients) values
  (1, '[{"name": "Hồng trà khô", "qty": 10, "unit": "g"}, {"name": "Nước nóng", "qty": 200, "unit": "ml"}, {"name": "Bột kem béo", "qty": 30, "unit": "g"}, {"name": "Sữa đặc", "qty": 15, "unit": "ml"}, {"name": "Đường nước", "qty": 20, "unit": "ml"}]'::jsonb),
  (2, '[{"name": "Lục trà khô", "qty": 8, "unit": "g"}, {"name": "Nước nóng", "qty": 200, "unit": "ml"}, {"name": "Bột kem béo", "qty": 30, "unit": "g"}, {"name": "Sữa đặc", "qty": 15, "unit": "ml"}, {"name": "Đường nước", "qty": 20, "unit": "ml"}]'::jsonb),
  (3, '[{"name": "Ô long khô", "qty": 10, "unit": "g"}, {"name": "Nước nóng", "qty": 200, "unit": "ml"}, {"name": "Bột kem béo", "qty": 25, "unit": "g"}, {"name": "Sữa đặc", "qty": 15, "unit": "ml"}, {"name": "Đường nước", "qty": 20, "unit": "ml"}]'::jsonb),
  (4, '[{"name": "Trà Thái xanh", "qty": 12, "unit": "g"}, {"name": "Nước nóng", "qty": 200, "unit": "ml"}, {"name": "Sữa đặc", "qty": 25, "unit": "ml"}, {"name": "Sữa tươi", "qty": 50, "unit": "ml"}, {"name": "Đường nước", "qty": 10, "unit": "ml"}]'::jsonb),
  (5, '[{"name": "Trà Thái đỏ", "qty": 12, "unit": "g"}, {"name": "Nước nóng", "qty": 200, "unit": "ml"}, {"name": "Sữa đặc", "qty": 25, "unit": "ml"}, {"name": "Sữa tươi", "qty": 50, "unit": "ml"}, {"name": "Đường nước", "qty": 10, "unit": "ml"}]'::jsonb),
  (6, '[{"name": "Hồng trà khô", "qty": 10, "unit": "g"}, {"name": "Nước nóng", "qty": 200, "unit": "ml"}, {"name": "Sữa tươi", "qty": 100, "unit": "ml"}, {"name": "Đường đen", "qty": 25, "unit": "g"}, {"name": "Bột kem béo", "qty": 15, "unit": "g"}]'::jsonb),
  (7, '[{"name": "Hồng trà khô", "qty": 8, "unit": "g"}, {"name": "Nước nóng", "qty": 180, "unit": "ml"}, {"name": "Bột khoai môn", "qty": 25, "unit": "g"}, {"name": "Bột kem béo", "qty": 25, "unit": "g"}, {"name": "Đường nước", "qty": 15, "unit": "ml"}]'::jsonb),
  (8, '[{"name": "Matcha", "qty": 5, "unit": "g"}, {"name": "Hồng trà khô", "qty": 5, "unit": "g"}, {"name": "Nước nóng", "qty": 200, "unit": "ml"}, {"name": "Sữa tươi", "qty": 100, "unit": "ml"}, {"name": "Đường nước", "qty": 20, "unit": "ml"}]'::jsonb),
  (9, '[{"name": "Hồng trà khô", "qty": 8, "unit": "g"}, {"name": "Nước nóng", "qty": 180, "unit": "ml"}, {"name": "Bột cacao", "qty": 12, "unit": "g"}, {"name": "Bột kem béo", "qty": 25, "unit": "g"}, {"name": "Đường nước", "qty": 25, "unit": "ml"}]'::jsonb),
  (10, '[{"name": "Hồng trà khô", "qty": 10, "unit": "g"}, {"name": "Nước nóng", "qty": 200, "unit": "ml"}, {"name": "Sữa tươi", "qty": 80, "unit": "ml"}, {"name": "Syrup caramel", "qty": 25, "unit": "ml"}, {"name": "Bột kem béo", "qty": 20, "unit": "g"}]'::jsonb),
  (11, '[{"name": "Hồng trà khô", "qty": 10, "unit": "g"}, {"name": "Nước nóng", "qty": 200, "unit": "ml"}, {"name": "Sữa tươi", "qty": 80, "unit": "ml"}, {"name": "Mật ong", "qty": 20, "unit": "ml"}, {"name": "Bột kem béo", "qty": 20, "unit": "g"}]'::jsonb),
  (12, '[{"name": "Hồng trà khô", "qty": 8, "unit": "g"}, {"name": "Nước nóng", "qty": 180, "unit": "ml"}, {"name": "Sữa tươi", "qty": 100, "unit": "ml"}, {"name": "Syrup bạc hà", "qty": 15, "unit": "ml"}, {"name": "Bột kem béo", "qty": 20, "unit": "g"}]'::jsonb),
  (13, '[{"name": "Hồng trà khô", "qty": 8, "unit": "g"}, {"name": "Nước nóng", "qty": 180, "unit": "ml"}, {"name": "Sữa tươi", "qty": 100, "unit": "ml"}, {"name": "Syrup dâu", "qty": 25, "unit": "ml"}, {"name": "Bột kem béo", "qty": 20, "unit": "g"}]'::jsonb),
  (14, '[{"name": "Hồng trà khô", "qty": 8, "unit": "g"}, {"name": "Nước nóng", "qty": 180, "unit": "ml"}, {"name": "Sữa tươi", "qty": 100, "unit": "ml"}, {"name": "Syrup chuối", "qty": 20, "unit": "ml"}, {"name": "Bột kem béo", "qty": 20, "unit": "g"}]'::jsonb),
  (15, '[{"name": "Ô long khô", "qty": 8, "unit": "g"}, {"name": "Nước nóng", "qty": 180, "unit": "ml"}, {"name": "Nước cốt dừa", "qty": 50, "unit": "ml"}, {"name": "Sữa tươi", "qty": 60, "unit": "ml"}, {"name": "Đường nước", "qty": 20, "unit": "ml"}]'::jsonb),
  (16, '[{"name": "Hồng trà khô", "qty": 10, "unit": "g"}, {"name": "Nước nóng", "qty": 200, "unit": "ml"}, {"name": "Sữa hạnh nhân", "qty": 100, "unit": "ml"}, {"name": "Bột kem béo", "qty": 20, "unit": "g"}, {"name": "Đường nước", "qty": 15, "unit": "ml"}]'::jsonb),
  (17, '[{"name": "Hồng trà khô", "qty": 8, "unit": "g"}, {"name": "Nước nóng", "qty": 180, "unit": "ml"}, {"name": "Sữa tươi", "qty": 80, "unit": "ml"}, {"name": "Bột cacao", "qty": 10, "unit": "g"}, {"name": "Syrup bạc hà", "qty": 10, "unit": "ml"}]'::jsonb),
  (18, '[{"name": "Hồng trà khô", "qty": 10, "unit": "g"}, {"name": "Nước nóng", "qty": 200, "unit": "ml"}, {"name": "Bột kem béo", "qty": 25, "unit": "g"}, {"name": "Đường nước", "qty": 20, "unit": "ml"}, {"name": "Pudding trứng", "qty": 60, "unit": "g"}]'::jsonb),
  (19, '[{"name": "Hồng trà khô", "qty": 10, "unit": "g"}, {"name": "Nước nóng", "qty": 200, "unit": "ml"}, {"name": "Bột kem béo", "qty": 20, "unit": "g"}, {"name": "Đường nước", "qty": 15, "unit": "ml"}, {"name": "Kem cheese", "qty": 40, "unit": "g"}]'::jsonb),
  (20, '[{"name": "Hồng trà khô", "qty": 10, "unit": "g"}, {"name": "Nước nóng", "qty": 200, "unit": "ml"}, {"name": "Sữa tươi", "qty": 60, "unit": "ml"}, {"name": "Đường nước", "qty": 15, "unit": "ml"}, {"name": "Kem muối", "qty": 40, "unit": "g"}]'::jsonb)
on conflict (id) do update set ingredients = excluded.ingredients;

alter table arena_actions add column if not exists item_names text[];
alter table arena_actions add column if not exists item_vals  real[];
alter table arena_actions add column if not exists score      smallint;


-- Chỉ số mức lượng gần nhất (khớp `nearestStep`: hòa thì lấy mức THẤP hơn).
create or replace function arena_recipe_nearest(p_unit text, p_value numeric)
returns int
language sql
immutable
as $$
  select (t.i - 1)::int
  from unnest(
    case when p_unit = 'g'
      then array[1,2,3,4,5,6,7,8,9,10,12,15,20,25,30,35,40,45,50,60,70,80,90,100,120]::numeric[]
      else array[2,5,10,15,20,25,30,35,40,50,60,70,80,100,120,150,180,200,220,230,250,300]::numeric[]
    end
  ) with ordinality as t(s, i)
  order by abs(t.s - p_value), t.i
  limit 1
$$;

-- Điểm một đơn 0..100 (khớp `scoreOrder`; bậc Thạo ⇒ lệch 1 mức vẫn được 0.5, lệch xa 0).
create or replace function arena_recipe_order_score(p_recipe int, p_names text[], p_vals real[])
returns int
language plpgsql
stable
as $$
declare
  ings jsonb;
  ing jsonb;
  need int;
  pts numeric := 0;
  v numeric;
  d int;
  nm text;
begin
  select ingredients into ings from arena_recipes where id = p_recipe;
  if ings is null then
    return 0;
  end if;
  need := jsonb_array_length(ings);
  for ing in select * from jsonb_array_elements(ings) loop
    -- cùng một nguyên liệu nộp nhiều lần thì lấy lần CUỐI (khớp gradeOrder).
    select t.val into v
      from unnest(p_names, p_vals) with ordinality as t(n, val, o)
      where t.n = ing->>'name'
      order by t.o desc
      limit 1;
    if v is null then
      continue; -- thiếu
    end if;
    d := abs(arena_recipe_nearest(ing->>'unit', v) - arena_recipe_nearest(ing->>'unit', (ing->>'qty')::numeric));
    pts := pts + case when d = 0 then 1 when d = 1 then 0.5 else 0 end;
  end loop;
  -- nguyên liệu thừa (mỗi tên tính một lần)
  for nm in select distinct n from unnest(p_names) as n loop
    if not exists (select 1 from jsonb_array_elements(ings) e where e->>'name' = nm) then
      pts := pts - 0.5;
    end if;
  end loop;
  return least(100, greatest(0, round(100 * greatest(0, pts) / need)))::int;
end;
$$;

-- Hàm nội bộ: KHÔNG cấp execute cho client (chỉ các hàm security definer bên dưới gọi).
revoke all on function arena_recipe_order_score(int, text[], real[]) from public;

-- Nộp đơn thứ p_idx (0..4) của trận: MỖI đơn một lần, trong giờ. Trả điểm đơn vừa chấm.
create or replace function arena_submit_order(
  p_match_id uuid,
  p_idx int,
  p_names text[],
  p_vals real[]
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  m arena_matches;
  s int;
  last_at timestamptz;
begin
  if me is null then
    raise exception 'not authenticated';
  end if;
  select * into m from arena_matches where id = p_match_id for update;
  if not found then
    raise exception 'match not found';
  end if;
  if me not in (m.player_a, m.player_b) or (m.ghost and me = m.player_b) then
    raise exception 'not a participant';
  end if;
  if m.mode <> 'recipe' then
    raise exception 'orders are only valid in recipe mode';
  end if;
  if m.status <> 'active' then
    raise exception 'match not active';
  end if;
  if now() >= m.ends_at then
    raise exception 'match time is up';
  end if;
  if p_idx is null or p_idx not between 0 and 4 then
    raise exception 'invalid order index';
  end if;
  if p_names is null or p_vals is null
     or coalesce(array_length(p_names, 1), 0) <> coalesce(array_length(p_vals, 1), 0)
     or coalesce(array_length(p_names, 1), 0) > 16 then
    raise exception 'invalid order items';
  end if;
  if exists (select 1 from arena_actions
             where match_id = p_match_id and player_id = me and kind = 'serve' and cell = p_idx) then
    raise exception 'order already served';
  end if;

  -- Chống script: công thức là dữ liệu công khai nên nộp đáp án hoàn hảo tức thì là dễ. Người thật cần ít nhất
  -- ~1 giây cho mỗi nguyên liệu (chọn, đặt lượng, đổ) kể từ lúc bắt đầu trận hoặc đơn nộp trước đó.
  select greatest(m.started_at, coalesce(max(at), m.started_at)) into last_at
    from arena_actions where match_id = p_match_id and player_id = me and kind = 'serve';
  if now() - coalesce(last_at, m.started_at) < interval '1 second' * coalesce(array_length(p_names, 1), 0) then
    raise exception 'too fast';
  end if;

  s := arena_recipe_order_score(m.seq[p_idx + 1]::int, p_names, p_vals);
  insert into arena_actions (match_id, player_id, kind, cell, item_names, item_vals, score)
    values (p_match_id, me, 'serve', p_idx, p_names, p_vals, s);
  return s;
end;
$$;

grant execute on function arena_submit_order(uuid, int, text[], real[]) to authenticated;

create or replace function arena_compute_score_recipe(p_match_id uuid, p_player uuid)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(sum(arena_recipe_order_score(m.seq[a.cell + 1]::int, a.item_names, a.item_vals)), 0)
  from arena_actions a
  join arena_matches m on m.id = a.match_id
  where a.match_id = p_match_id and a.player_id = p_player and a.kind = 'serve'
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
  if m_mode = 'recipe' then
    return arena_compute_score_recipe(p_match_id, p_player);
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
  my_joined timestamptz;
  src record;
begin
  if me is null then
    raise exception 'not authenticated';
  end if;
  if p_mode not in ('tap', 'match3', 'recipe') then
    raise exception 'unknown mode: %', p_mode;
  end if;

  -- Đã có trận active? trả lại luôn (kể cả trận vừa được người khác ghép hộ
  -- mình — xem giải thích race condition trong PROPOSAL) — NHƯNG chỉ nếu
  -- trận đó còn thời gian thật. Nếu `ends_at` đã qua mà chưa ai chốt (VD cả
  -- 2 bên thoát app giữa trận), tự chốt nó ở đây rồi rơi xuống ghép trận MỚI
  -- — tránh kẹt người chơi trong 1 trận ma mỗi lần họ mở lại Đấu Trường.
  select * into m from arena_matches
    where status = 'active' and me in (player_a, player_b)
      and (not ghost or player_a = me) -- chủ bản ghi không bị kẹt trong trận bóng ma của người khác
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
    -- Chờ quá 12 giây (nhưng dòng chờ chưa cũ tới mức là dòng mồ côi) → đấu bóng ma nếu có bản ghi.
    select joined_at into my_joined from arena_queue where player_id = me;
    if my_joined <= now() - interval '12 seconds' and my_joined > now() - interval '5 minutes' then
      select s.id, g.pid, s.seq, s.ends_at - s.started_at as dur into src
      from arena_matches s
      cross join lateral (values (s.player_a), (s.player_b)) g(pid)
      where s.status = 'finished' and not s.ghost and s.mode = p_mode
        and s.created_at > now() - interval '30 days'
        and g.pid <> me
        and (select count(*) from arena_actions x where x.match_id = s.id and x.player_id = g.pid) >= 5
      order by random() limit 1;
      if found then
        delete from arena_queue where player_id = me;
        insert into arena_matches (player_a, player_b, mode, seq, ends_at, ghost)
          values (me, src.pid, p_mode, src.seq, now() + src.dur, true)
          returning * into m;
        -- Dịch mốc thời gian: hành động thứ n của bản gốc xảy ra sau (at - started_at gốc) giây kể từ khi trận mới bắt đầu.
        insert into arena_actions (match_id, player_id, kind, at, rot, col, cell, dir, item_names, item_vals, score)
          select m.id, x.player_id, x.kind, m.started_at + (x.at - o.started_at),
                 x.rot, x.col, x.cell, x.dir, x.item_names, x.item_vals, x.score
          from arena_actions x join arena_matches o on o.id = x.match_id
          where x.match_id = src.id and x.player_id = src.pid;
        return m;
      end if;
    end if;
    return null; -- vẫn đang chờ, client tự gọi lại sau
  end if;

  delete from arena_queue where player_id in (me, opponent);

  if p_mode = 'match3' then
    insert into arena_matches (player_a, player_b, mode, seq)
      values (me, opponent, 'match3',
              array(select floor(random() * 5)::smallint from generate_series(1, 2000)))
      returning * into m;
  elsif p_mode = 'recipe' then
    -- 5 món khác nhau của nhóm 1 (ai cũng đã mở), thời gian 180 giây cho cả 5 đơn.
    insert into arena_matches (player_a, player_b, mode, seq, ends_at)
      values (me, opponent, 'recipe',
              array(select id::smallint from arena_recipes order by random() limit 5),
              now() + interval '180 seconds')
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
  if me not in (m.player_a, m.player_b) or (m.ghost and me = m.player_b) then
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
  -- Dạng recipe: cả hai đã nộp đủ 5 đơn thì chốt sớm, khỏi chờ hết giờ.
  if now() < m.ends_at and not (
       m.mode = 'recipe'
       and (select count(*) from arena_actions where match_id = p_match_id and player_id = m.player_a and kind = 'serve') >= 5
       and (select count(*) from arena_actions where match_id = p_match_id and player_id = m.player_b and kind = 'serve') >= 5
     ) then
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

-- ===== guild_schema.sql =====
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
-- Sức chứa riêng của từng hội: mở đầu 20, chủ hội mua thêm +5 (tối đa 30).
alter table guilds add column if not exists max_members integer not null default 20;
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
-- Tên thành viên KHÔNG trùng trong cùng hội (không phân biệt hoa thường): tài khoản không liên kết
-- cài lại sẽ thành uid mới và vào lại hội với đúng tên cũ → hai dòng giống hệt nhau, không biết ai
-- là ai. Dữ liệu cũ đã trùng thì đổi tên người vào SAU thành "<tên>#2", "#3"… trước khi tạo chỉ mục
-- (idempotent: lần chạy sau không còn trùng nên không đổi gì).
update guild_members m
   set nickname = left(m.nickname, 16) || '#' || d.rn
  from (select user_id,
               row_number() over (partition by guild_id, lower(nickname)
                                  order by joined_at, user_id) as rn
          from guild_members) d
 where d.user_id = m.user_id and d.rn > 1;
create unique index if not exists guild_members_nick_idx
  on guild_members (guild_id, lower(nickname));
-- Vai trò: chủ hội là guilds.owner_id (không dùng cột này); phó hội = 'officer'.
alter table guild_members add column if not exists role text not null default 'member';
do $$ begin
  alter table guild_members add constraint guild_members_role_check
    check (role in ('member', 'officer'));
exception when duplicate_object then null; end $$;

-- Nhật ký hoạt động hội: giữ 50 sự kiện gần nhất mỗi hội (ghi qua guild_log_event).
create table if not exists guild_events (
  id         bigserial primary key,
  guild_id   uuid not null references guilds(id) on delete cascade,
  kind       text not null check (kind in
               ('joined','left','kicked','promoted','demoted','transferred')),
  actor      text not null,
  target     text,
  created_at timestamptz not null default now()
);
create index if not exists guild_events_guild_idx on guild_events (guild_id, id desc);

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
-- Quỹ hội tuần: phần thưởng chung đã nhận (mỗi người 1 lần/tuần).
create table if not exists guild_fund_claims (
  user_id    uuid not null references auth.users(id) on delete cascade,
  week       date not null,
  claimed_at timestamptz not null default now(),
  primary key (user_id, week)
);
-- Nhiệm vụ chung "cả hội cùng tham gia": thưởng đã nhận (mỗi người 1 lần/tuần).
create table if not exists guild_team_claims (
  user_id    uuid not null references auth.users(id) on delete cascade,
  week       date not null,
  claimed_at timestamptz not null default now(),
  primary key (user_id, week)
);
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
-- Reaction (emoji) vào tin chat: mỗi người bật/tắt từng emoji (tối đa 6 loại) trên mỗi tin.
create table if not exists guild_message_reactions (
  message_id bigint not null references guild_messages(id) on delete cascade,
  user_id    uuid not null,
  emoji      text not null,
  created_at timestamptz not null default now(),
  primary key (message_id, user_id, emoji)
);
create index if not exists guild_message_reactions_msg_idx on guild_message_reactions (message_id);

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
alter table guild_events        enable row level security;
alter table guild_fund_claims   enable row level security;
alter table guild_message_reactions enable row level security;
alter table guild_team_claims   enable row level security;
alter table guild_message_reports enable row level security;
-- Cố ý KHÔNG tạo policy: chỉ RPC security definer được đụng vào.

-- Hội cũ đã đông hơn 20 người thì giữ nguyên chỗ đang có (không đuổi ai).
update guilds g set max_members = least(30, (select count(*) from guild_members m where m.guild_id = g.id))
 where (select count(*) from guild_members m where m.guild_id = g.id) > g.max_members;

-- --- Hằng số --------------------------------------------------------------
create or replace function guild_max_members() returns integer
language sql immutable as $$ select 30 $$;

-- Sức chứa ban đầu / mỗi lần mở thêm; giá 💎 của lần mở thứ n (n=0: 20→25, n=1: 25→30).
create or replace function guild_base_members() returns integer
language sql immutable as $$ select 20 $$;
create or replace function guild_expand_step() returns integer
language sql immutable as $$ select 5 $$;
create or replace function guild_expand_cost(p_current integer) returns integer
language sql immutable as $$
  select case p_current when 20 then 1000 when 25 then 2000 end
$$;

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

-- Quỹ hội tuần: cả hội cùng nạp 💎 (guild_donate) tới mục tiêu = 100 💎 × số thành viên
-- (tối thiểu 500); đạt thì mỗi người đã góp ≥ 10 💎 nhận 200 Xu Hội. Khớp guild_shop.dart.
create or replace function guild_fund_per_member() returns integer
language sql immutable as $$ select 100 $$;
create or replace function guild_fund_min_target() returns integer
language sql immutable as $$ select 500 $$;
create or replace function guild_fund_reward() returns integer
language sql immutable as $$ select 200 $$;
create or replace function guild_fund_min_donation() returns integer
language sql immutable as $$ select 10 $$;
create or replace function guild_fund_target(p_members integer) returns bigint
language sql immutable as $$
  select greatest(guild_fund_min_target(), guild_fund_per_member() * greatest(p_members, 0))::bigint
$$;

-- 💎 mà [p_user] đã nạp trong tuần này KỂ TỪ ngày vào hội hiện tại (chống vào hội muộn
-- ăn theo phần đã nạp ở hội khác / nạp xong mới chuyển hội).
create or replace function guild_fund_donated(p_user uuid) returns bigint
language sql stable security definer set search_path = public as $$
  select coalesce(sum(d.gems), 0)::bigint
  from guild_members m
  join guild_donations d on d.user_id = m.user_id
  where m.user_id = p_user
    and d.day >= greatest(guild_current_week(), (m.joined_at at time zone 'utc')::date)
    and d.day < guild_current_week() + 7
$$;

create or replace function guild_fund_progress(p_guild uuid) returns bigint
language sql stable security definer set search_path = public as $$
  select coalesce(sum(guild_fund_donated(m.user_id)), 0)::bigint
  from guild_members m where m.guild_id = p_guild
$$;

-- Nhiệm vụ chung: một nửa hội (làm tròn lên, tối thiểu 2 người, tối đa cả hội) mỗi người đạt
-- ≥ 1000 điểm tuần thì ai đạt nhận 150 Xu Hội. Khớp guild_shop.dart (guildTeam*).
create or replace function guild_team_min_points() returns integer
language sql immutable as $$ select 1000 $$;
create or replace function guild_team_reward() returns integer
language sql immutable as $$ select 150 $$;
create or replace function guild_team_need(p_members integer) returns integer
language sql immutable as $$
  select least(greatest(p_members, 0), greatest(2, ceil(p_members / 2.0)::integer))
$$;
-- Số thành viên đã đạt mức tối thiểu tuần này.
create or replace function guild_team_active(p_guild uuid) returns integer
language sql stable security definer set search_path = public as $$
  select count(*)::integer from guild_members m
  where m.guild_id = p_guild and m.week = guild_current_week()
    and m.week_points >= guild_team_min_points()
$$;

-- Tối đa 3 phó hội mỗi hội (chủ hội không tính).
create or replace function guild_max_officers() returns integer
language sql immutable as $$ select 3 $$;

-- Ghi nhật ký (nội bộ — client KHÔNG gọi được, xem revoke cuối file).
create or replace function guild_log_event(
  p_guild uuid, p_kind text, p_actor text, p_target text
) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into guild_events (guild_id, kind, actor, target)
  values (p_guild, p_kind, p_actor, p_target);
  delete from guild_events where guild_id = p_guild and id <=
    (select id from guild_events where guild_id = p_guild
       order by id desc offset 50 limit 1);
end;
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
       >= v_g.max_members then
    raise exception 'guild full';
  end if;
  if exists (select 1 from guild_members
              where guild_id = v_g.id and lower(nickname) = lower(p_nickname)) then
    raise exception 'nickname taken';
  end if;

  insert into guild_members (user_id, guild_id, nickname, week, last_score)
  values (v_uid, v_g.id, p_nickname, guild_current_week(),
          greatest(coalesce(p_score, 0), 0));
  delete from guild_join_requests where user_id = v_uid;
  perform guild_log_event(v_g.id, 'joined', p_nickname, null);
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
  if exists (select 1 from guild_members
              where guild_id = v_g.id and lower(nickname) = lower(p_nickname)) then
    raise exception 'nickname taken';
  end if;
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
  -- Chủ hội hoặc phó hội duyệt đơn.
  select g.* into v_g from guilds g
    join guild_members m on m.guild_id = g.id and m.user_id = v_uid
    where g.owner_id = v_uid or m.role = 'officer' for update of g;
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
       >= v_g.max_members then
    raise exception 'guild full';
  end if;
  -- Có người cùng tên vào hội trong lúc đơn đang chờ: không duyệt được (chủ hội từ chối đơn).
  if exists (select 1 from guild_members
              where guild_id = v_g.id and lower(nickname) = lower(v_r.nickname)) then
    raise exception 'nickname taken';
  end if;
  insert into guild_members (user_id, guild_id, nickname, week, last_score)
  values (p_user, v_g.id, v_r.nickname, guild_current_week(), v_r.score);
  delete from guild_join_requests where user_id = p_user;
  perform guild_log_event(v_g.id, 'joined', v_r.nickname, null);
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
  v_nick text;
  v_next_nick text;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  delete from guild_members where user_id = v_uid
    returning guild_id, week, week_points, nickname into v_gid, v_wk, v_pts, v_nick;
  if v_gid is null then return; end if;
  perform guild_log_week(v_gid, v_wk, v_pts);       -- điểm đã đóng góp vẫn thuộc hội
  select user_id, nickname into v_next, v_next_nick from guild_members
    where guild_id = v_gid order by joined_at asc limit 1;
  if v_next is null then
    delete from guilds where id = v_gid;           -- hội trống → xoá
  else
    perform guild_log_event(v_gid, 'left', v_nick, null);
    update guilds set owner_id = v_next
      where id = v_gid and owner_id = v_uid;       -- chủ rời → người cũ nhất kế nhiệm
    if found then
      update guild_members set role = 'member' where user_id = v_next;
      perform guild_log_event(v_gid, 'transferred', v_nick, v_next_nick);
    end if;
  end if;
end;
$$;

create or replace function guild_kick(p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_gid uuid;
  v_owner uuid;
  v_role text;
  v_wk date;
  v_pts bigint;
  v_actor text;
  v_target text;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_user = v_uid then raise exception 'cannot kick self'; end if;
  select m.guild_id, g.owner_id, m.role, m.nickname into v_gid, v_owner, v_role, v_actor
    from guild_members m join guilds g on g.id = m.guild_id
    where m.user_id = v_uid;
  -- Chủ hội kick được mọi người; phó hội chỉ kick thành viên thường.
  if v_gid is null or (v_uid <> v_owner and v_role <> 'officer') then
    raise exception 'not owner';
  end if;
  if v_uid <> v_owner and (p_user = v_owner or exists (
       select 1 from guild_members where user_id = p_user and role = 'officer')) then
    raise exception 'not allowed';
  end if;
  delete from guild_members where user_id = p_user and guild_id = v_gid
    returning week, week_points, nickname into v_wk, v_pts, v_target;
  if not found then raise exception 'not found'; end if;
  perform guild_log_week(v_gid, v_wk, v_pts);
  perform guild_log_event(v_gid, 'kicked', v_actor, v_target);
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

-- --- Boss Hội hàng tuần ------------------------------------------------------------
-- Sát thương = tổng điểm tuần của cả hội (guild_week_total). HP boss = max(HP tối thiểu,
-- số thành viên × HP/người) × (1 + 25% × bậc), bậc = min(chuỗi tuần đủ 3 mốc, 4). Hạ boss thì mỗi
-- thành viên đủ điểm tối thiểu nhận rương: 💎 (client cộng sau khi server OK) + Xu Hội (server cộng
-- vào ví). Hằng số khớp lib/core/guild.dart (test so khớp). Con số là ước lượng chưa playtest.
create or replace function guild_boss_hp_per_member() returns integer
language sql immutable as $$ select 4000 $$;
create or replace function guild_boss_min_hp() returns integer
language sql immutable as $$ select 20000 $$;
create or replace function guild_boss_max_tier() returns integer
language sql immutable as $$ select 4 $$;
create or replace function guild_boss_reward_gems(p_tier integer) returns integer
language sql immutable as $$ select 100 + 50 * p_tier $$;
create or replace function guild_boss_reward_coins(p_tier integer) returns integer
language sql immutable as $$ select 100 + 100 * p_tier $$;

create table if not exists guild_boss_claims (
  user_id  uuid not null references auth.users(id) on delete cascade,
  week     date not null,
  primary key (user_id, week)
);
alter table guild_boss_claims enable row level security;
-- Không policy nào: mọi truy cập qua RPC security definer.

create or replace function guild_boss_tier(p_guild uuid) returns integer
language sql stable as $$ select least(guild_streak(p_guild), guild_boss_max_tier()) $$;

create or replace function guild_boss_hp(p_guild uuid) returns bigint
language sql stable as $$
  select (greatest(guild_boss_min_hp()::bigint,
                   (select count(*) from guild_members m where m.guild_id = p_guild)
                     * guild_boss_hp_per_member())
          * (100 + 25 * guild_boss_tier(p_guild)) / 100)::bigint
$$;

-- Nhận rương boss tuần này. Trả {gems, coins}; Xu Hội đã cộng vào ví ở server.
create or replace function guild_claim_boss() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_m guild_members%rowtype;
  v_week date := guild_current_week();
  v_tier integer;
  v_gems integer;
  v_coins integer;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select * into v_m from guild_members where user_id = v_uid;
  if not found then raise exception 'not in guild'; end if;
  if guild_week_total(v_m.guild_id) < guild_boss_hp(v_m.guild_id) then
    raise exception 'boss alive';
  end if;
  if v_m.week <> v_week or v_m.week_points < guild_min_points_to_claim() then
    raise exception 'not enough contribution';
  end if;
  begin
    insert into guild_boss_claims (user_id, week) values (v_uid, v_week);
  exception when unique_violation then
    raise exception 'already claimed';
  end;
  v_tier := guild_boss_tier(v_m.guild_id);
  v_gems := guild_boss_reward_gems(v_tier);
  v_coins := guild_boss_reward_coins(v_tier);
  insert into guild_coin_wallets (user_id, balance) values (v_uid, v_coins)
    on conflict (user_id) do update
      set balance = guild_coin_wallets.balance + excluded.balance;
  return jsonb_build_object('gems', v_gems, 'coins', v_coins);
end;
$$;

-- Thưởng thu nhập theo số thành viên VIP: mỗi thành viên có cấp VIP >= guild_vip_min_level()
-- cộng guild_vip_bonus_per_member() % thu nhập cho CẢ HỘI, trần guild_vip_bonus_cap() %. Hằng số khớp
-- lib/core/guild.dart (test so khớp). Cấp lấy từ vip_level (accessory_market_schema.sql; client tự
-- khai, làm giả được — trần thấp chặn thiệt hại). plpgsql để file chạy được khi chưa có bảng đó.
create or replace function guild_vip_bonus_per_member() returns integer
language sql immutable as $$ select 1 $$;
create or replace function guild_vip_bonus_cap() returns integer
language sql immutable as $$ select 5 $$;
create or replace function guild_vip_min_level() returns integer
language sql immutable as $$ select 5 $$;

create or replace function guild_vip_count(p_guild uuid) returns integer
language plpgsql stable security definer set search_path = public as $$
declare v integer;
begin
  select count(*) into v from guild_members m
    join vip_level l on l.user_id = m.user_id
    where m.guild_id = p_guild and l.level >= guild_vip_min_level();
  return v;
exception when undefined_table then
  return 0;
end
$$;

create or replace function guild_vip_bonus_pct(p_guild uuid) returns integer
language sql stable security definer set search_path = public as $$
  select least(guild_vip_count(p_guild) * guild_vip_bonus_per_member(), guild_vip_bonus_cap())
$$;

-- % thưởng của hội mình (nhẹ — gọi khi mở app cùng guild_buff_seconds). 0 nếu không ở hội.
create or replace function guild_vip_bonus() returns integer
language plpgsql stable security definer set search_path = public as $$
declare v_gid uuid;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  select guild_id into v_gid from guild_members where user_id = auth.uid();
  if v_gid is null then return 0; end if;
  return guild_vip_bonus_pct(v_gid);
end
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
      'owner_id', v_g.owner_id, 'requires_approval', v_g.requires_approval,
      'max_members', v_g.max_members),
    'week', v_week,
    -- Id tin mới nhất người này còn thấy (để client tính "chưa đọc").
    'chat_latest', coalesce((select max(m.id) from guild_messages m
        where m.guild_id = v_g.id and not m.hidden
          and not exists (select 1 from guild_message_reports r
                            where r.message_id = m.id and r.reporter_id = v_uid)), 0),
    'fund', jsonb_build_object(
        'progress', guild_fund_progress(v_g.id),
        'target', guild_fund_target((select count(*) from guild_members where guild_id = v_g.id)::integer),
        'mine', guild_fund_donated(v_uid),
        'claimed', exists (select 1 from guild_fund_claims c
                             where c.user_id = v_uid and c.week = v_week)),
    'team_claimed', exists (select 1 from guild_team_claims c
                             where c.user_id = v_uid and c.week = v_week),
    'total', guild_week_total(v_g.id),
    'streak', guild_streak(v_g.id),
    'boss', jsonb_build_object(
        'hp', guild_boss_hp(v_g.id),
        'tier', guild_boss_tier(v_g.id),
        'claimed', exists (select 1 from guild_boss_claims c
                             where c.user_id = v_uid and c.week = v_week)),
    'vip_members', guild_vip_count(v_g.id),
    'vip_bonus', guild_vip_bonus_pct(v_g.id),
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
         'role', case when m.user_id = v_g.owner_id then 'owner' else m.role end,
         'points', case when m.week = v_week then m.week_points else 0 end)
         order by (case when m.week = v_week then m.week_points else 0 end) desc,
                  m.joined_at asc)
       from guild_members m where m.guild_id = v_g.id), '[]'::jsonb),
    -- Chỉ chủ hội thấy danh sách yêu cầu.
    'requests', case when v_g.owner_id = v_uid or exists (
         select 1 from guild_members o where o.user_id = v_uid and o.role = 'officer')
       then coalesce((
         select jsonb_agg(jsonb_build_object('user_id', r.user_id,
                'nickname', r.nickname) order by r.created_at asc)
         from guild_join_requests r where r.guild_id = v_g.id), '[]'::jsonb)
       else '[]'::jsonb end);
end;
$$;

drop function if exists guild_list(integer);
create or replace function guild_list(p_limit integer default 30)
returns table (id uuid, name text, tag text, emoji text,
               member_count bigint, week_total bigint,
               requires_approval boolean, requested boolean, max_members integer)
language sql stable security definer set search_path = public as $$
  select g.id, g.name, g.tag, g.emoji,
         (select count(*) from guild_members m where m.guild_id = g.id),
         guild_week_total(g.id),
         g.requires_approval,
         exists (select 1 from guild_join_requests r
                 where r.guild_id = g.id and r.user_id = auth.uid()),
         g.max_members
  from guilds g
  where not g.hidden
    and (select count(*) from guild_members m where m.guild_id = g.id)
        < g.max_members
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

-- BXH Hội theo TỔNG VIP EXP của thành viên (lấy từ vip_leaderboard_entries, tạo bởi
-- accessory_market_schema.sql — chỉ tính thành viên đã đặt biệt danh và nộp EXP). plpgsql để
-- file này vẫn chạy được khi bảng đó chưa tồn tại (khi đó trả rỗng thay vì lỗi).
create or replace function guild_leaderboard_vip(p_limit integer default 50)
returns table (rank bigint, id uuid, name text, tag text, emoji text,
               member_count bigint, week_total bigint, vip_exp bigint)
language plpgsql stable security definer set search_path = public as $$
begin
  return query
  select row_number() over (order by s.vexp desc, s.created_at asc),
         s.gid, s.gname, s.gtag, s.gemoji, s.cnt, s.total, s.vexp
  from (
    select g.id as gid, g.name as gname, g.tag as gtag, g.emoji as gemoji, g.created_at,
           (select count(*) from guild_members m where m.guild_id = g.id) as cnt,
           guild_week_total(g.id) as total,
           coalesce((select sum(e.vip_exp)
                     from guild_members m2
                     join vip_leaderboard_entries e on e.user_id = m2.user_id
                     where m2.guild_id = g.id), 0)::bigint as vexp
    from guilds g
    where not g.hidden
  ) s
  where s.vexp > 0
  order by 1
  limit least(p_limit, 100);
exception when undefined_table then
  return;
end
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

-- Emoji được phép (khớp guildReactionEmojis ở lib/core/guild.dart; test so khớp).
create or replace function guild_reaction_ok(p_emoji text) returns boolean
language sql immutable as $$
  select p_emoji = any (array['👍', '❤️', '😂', '😮', '😢', '🎉'])
$$;

create or replace function guild_chat_list(p_limit integer default 50) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_gid uuid;
  v_lim integer := least(greatest(coalesce(p_limit, 50), 1), 100);
  v_out jsonb;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select guild_id into v_gid from guild_members where user_id = v_uid;
  if v_gid is null then raise exception 'not found'; end if;
  -- Một lượt duy nhất: chọn tin hiển thị (không ẩn, không bị MÌNH báo cáo) → N tin gần nhất + tin ghim → gom
  -- reaction của đúng các tin đó bằng MỘT truy vấn (trước đây gọi một hàm riêng cho từng tin).
  with vis as (
    select m.* from guild_messages m
     where m.guild_id = v_gid and not m.hidden
       and not exists (select 1 from guild_message_reports r
                        where r.message_id = m.id and r.reporter_id = v_uid)
  ), recent as (
    select * from vis order by id desc limit v_lim
  ), pin as (
    select * from vis where pinned order by id desc limit 1
  ), rx as (
    select g.message_id,
           jsonb_agg(jsonb_build_object('emoji', g.emoji, 'count', g.cnt, 'mine', g.mine)
                     order by g.first_at) as j
      from (select r.message_id, r.emoji, count(*) as cnt, bool_or(r.user_id = v_uid) as mine,
                   min(r.created_at) as first_at
              from guild_message_reactions r
             where r.message_id in (select id from recent union select id from pin)
             group by r.message_id, r.emoji) g
     group by g.message_id
  )
  select jsonb_build_object(
    'pinned', (select jsonb_build_object('id', p.id, 'user_id', p.user_id, 'nickname', p.nickname,
                      'body', p.body, 'created_at', p.created_at,
                      'reactions', coalesce(rx.j, '[]'::jsonb))
                 from pin p left join rx on rx.message_id = p.id),
    'messages', coalesce((select jsonb_agg(jsonb_build_object('id', r.id, 'user_id', r.user_id,
                      'nickname', r.nickname, 'body', r.body, 'created_at', r.created_at,
                      'reactions', coalesce(rx.j, '[]'::jsonb)) order by r.id desc)
                 from recent r left join rx on rx.message_id = r.id), '[]'::jsonb))
    into v_out;
  return v_out;
end;
$$;

-- Bật/tắt reaction [p_emoji] của mình trên tin [p_id] (cùng hội, tin chưa bị ẩn).
create or replace function guild_chat_react(p_id bigint, p_emoji text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_gid uuid;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if not coalesce(guild_reaction_ok(p_emoji), false) then raise exception 'invalid amount'; end if;
  select guild_id into v_gid from guild_members where user_id = v_uid;
  if v_gid is null then raise exception 'not found'; end if;
  if not exists (select 1 from guild_messages where id = p_id and guild_id = v_gid and not hidden) then
    raise exception 'not found';
  end if;
  delete from guild_message_reactions where message_id = p_id and user_id = v_uid and emoji = p_emoji;
  if not found then
    insert into guild_message_reactions (message_id, user_id, emoji) values (p_id, v_uid, p_emoji);
  end if;
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
         or exists (select 1 from guilds g where g.id = v_gid and g.owner_id = v_uid)
         or exists (select 1 from guild_members o
                      where o.user_id = v_uid and o.role = 'officer'));
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

-- Chủ hội bổ nhiệm / bãi nhiệm phó hội (tối đa guild_max_officers()).
create or replace function guild_set_officer(p_user uuid, p_on boolean) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_gid uuid;
  v_actor text;
  v_target text;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select m.guild_id, m.nickname into v_gid, v_actor from guild_members m
    join guilds g on g.id = m.guild_id
    where m.user_id = v_uid and g.owner_id = v_uid for update of g;
  if v_gid is null then raise exception 'not owner'; end if;
  if p_user = v_uid then raise exception 'invalid input'; end if;
  select nickname into v_target from guild_members
    where user_id = p_user and guild_id = v_gid;
  if not found then raise exception 'not found'; end if;
  if coalesce(p_on, false) then
    if (select count(*) from guild_members
          where guild_id = v_gid and role = 'officer' and user_id <> v_uid)
         >= guild_max_officers()
       and not exists (select 1 from guild_members
                         where user_id = p_user and role = 'officer') then
      raise exception 'too many officers';
    end if;
    update guild_members set role = 'officer' where user_id = p_user and role <> 'officer';
    if found then perform guild_log_event(v_gid, 'promoted', v_actor, v_target); end if;
  else
    update guild_members set role = 'member' where user_id = p_user and role <> 'member';
    if found then perform guild_log_event(v_gid, 'demoted', v_actor, v_target); end if;
  end if;
end;
$$;

-- Chủ hội nhường quyền cho thành viên khác; chủ cũ trở thành thành viên thường.
create or replace function guild_transfer_owner(p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_gid uuid;
  v_actor text;
  v_target text;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select m.guild_id, m.nickname into v_gid, v_actor from guild_members m
    join guilds g on g.id = m.guild_id
    where m.user_id = v_uid and g.owner_id = v_uid for update of g;
  if v_gid is null then raise exception 'not owner'; end if;
  if p_user = v_uid then raise exception 'invalid input'; end if;
  select nickname into v_target from guild_members
    where user_id = p_user and guild_id = v_gid;
  if not found then raise exception 'not found'; end if;
  update guilds set owner_id = p_user where id = v_gid;
  update guild_members set role = 'member' where user_id in (p_user, v_uid);
  perform guild_log_event(v_gid, 'transferred', v_actor, v_target);
end;
$$;

-- Chủ hội mở thêm chỗ: +5 mỗi lần (20→25→30). Client tự trừ 💎 SAU khi RPC thành công.
create or replace function guild_expand() returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_g guilds%rowtype;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select * into v_g from guilds where owner_id = v_uid for update;
  if not found then raise exception 'not owner'; end if;
  if v_g.max_members >= guild_max_members() then raise exception 'guild maxed'; end if;
  update guilds set max_members = v_g.max_members + guild_expand_step()
   where id = v_g.id returning max_members into v_g.max_members;
  return v_g.max_members;
end;
$$;

-- Nhật ký hoạt động (mới nhất trước) — chỉ thành viên đọc được.
create or replace function guild_activity(p_limit integer default 30) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_gid uuid;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select guild_id into v_gid from guild_members where user_id = v_uid;
  if v_gid is null then raise exception 'not found'; end if;
  return coalesce((select jsonb_agg(e order by (e->>'id')::bigint desc) from (
      select jsonb_build_object('id', id, 'kind', kind, 'actor', actor,
             'target', target, 'created_at', created_at) as e
      from guild_events where guild_id = v_gid
      order by id desc limit least(greatest(coalesce(p_limit, 30), 1), 50)) s),
    '[]'::jsonb);
end;
$$;

-- Nhận thưởng quỹ hội tuần: quỹ phải đạt mục tiêu và bạn đã góp đủ mức tối thiểu.
create or replace function guild_claim_fund() returns bigint
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_gid uuid;
  v_week date := guild_current_week();
  v_bal bigint;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select guild_id into v_gid from guild_members where user_id = v_uid;
  if v_gid is null then raise exception 'not in guild'; end if;
  if guild_fund_progress(v_gid) < guild_fund_target(
       (select count(*) from guild_members where guild_id = v_gid)::integer) then
    raise exception 'goal not reached';
  end if;
  if guild_fund_donated(v_uid) < guild_fund_min_donation() then
    raise exception 'fund donation too low';
  end if;
  begin
    insert into guild_fund_claims (user_id, week) values (v_uid, v_week);
  exception when unique_violation then
    raise exception 'already claimed';
  end;
  insert into guild_coin_wallets (user_id, balance)
    values (v_uid, guild_fund_reward())
    on conflict (user_id) do update
      set balance = guild_coin_wallets.balance + excluded.balance
    returning balance into v_bal;
  return v_bal;
end;
$$;

-- Nhận thưởng nhiệm vụ chung: đủ người đạt mức tối thiểu VÀ chính mình đạt mức đó.
create or replace function guild_claim_team() returns bigint
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_gid uuid;
  v_week date := guild_current_week();
  v_bal bigint;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select guild_id into v_gid from guild_members where user_id = v_uid;
  if v_gid is null then raise exception 'not in guild'; end if;
  if guild_team_active(v_gid) < guild_team_need(
       (select count(*) from guild_members where guild_id = v_gid)::integer) then
    raise exception 'team not reached';
  end if;
  if not exists (select 1 from guild_members m where m.user_id = v_uid
       and m.week = v_week and m.week_points >= guild_team_min_points()) then
    raise exception 'team points too low';
  end if;
  begin
    insert into guild_team_claims (user_id, week) values (v_uid, v_week);
  exception when unique_violation then
    raise exception 'already claimed';
  end;
  insert into guild_coin_wallets (user_id, balance)
    values (v_uid, guild_team_reward())
    on conflict (user_id) do update
      set balance = guild_coin_wallets.balance + excluded.balance
    returning balance into v_bal;
  return v_bal;
end;
$$;

-- Tặng 💎 giữa thành viên CÙNG hội. Hằng số khớp lib/guild/guild_repository.dart
-- (guildGiftAmounts, guildGiftSendDailyCap, guildGiftReceiveDailyCap, guildGiftExpireDays;
-- test/guild/guild_sql_test.dart so khớp). Người gửi bị trừ 💎 ở client SAU khi server OK;
-- người nhận cộng 💎 ở client SAU khi nhận thành công — client tự khai 💎 nên mức trần
-- ngày chặn thiệt hại nếu có người sửa save.
create or replace function guild_gift_amount_ok(p_amount integer) returns boolean
language sql immutable as $$ select p_amount in (10, 20, 50) $$;
create or replace function guild_gift_send_daily_cap() returns integer
language sql immutable as $$ select 100 $$;
create or replace function guild_gift_receive_daily_cap() returns integer
language sql immutable as $$ select 200 $$;
create or replace function guild_gift_expire_days() returns integer
language sql immutable as $$ select 7 $$;

create table if not exists guild_gifts (
  id          bigint generated always as identity primary key,
  guild_id    uuid not null references guilds(id) on delete cascade,
  from_user   uuid not null references auth.users(id) on delete cascade,
  to_user     uuid not null references auth.users(id) on delete cascade,
  amount      integer not null check (amount in (10, 20, 50)),
  created_at  timestamptz not null default now(),
  claimed_at  timestamptz
);
create index if not exists guild_gifts_to_idx on guild_gifts (to_user, claimed_at);
create index if not exists guild_gifts_from_day_idx on guild_gifts (from_user, created_at);
alter table guild_gifts enable row level security;
-- Không policy nào: mọi truy cập qua RPC security definer.

create or replace function guild_gift_send(p_to uuid, p_amount integer) returns bigint
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_gid uuid;
  v_day timestamptz := date_trunc('day', now() at time zone 'utc') at time zone 'utc';
  v_sent integer;
  v_recv integer;
  v_id bigint;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_to is null or p_to = v_uid or not guild_gift_amount_ok(p_amount) then
    raise exception 'invalid amount';
  end if;
  select guild_id into v_gid from guild_members where user_id = v_uid;
  if v_gid is null then raise exception 'not in guild'; end if;
  if not exists (select 1 from guild_members where user_id = p_to and guild_id = v_gid) then
    raise exception 'not found';
  end if;
  select coalesce(sum(amount), 0) into v_sent from guild_gifts
    where from_user = v_uid and created_at >= v_day;
  if v_sent + p_amount > guild_gift_send_daily_cap() then
    raise exception 'daily limit';
  end if;
  select coalesce(sum(amount), 0) into v_recv from guild_gifts
    where to_user = p_to and created_at >= v_day;
  if v_recv + p_amount > guild_gift_receive_daily_cap() then
    raise exception 'daily limit';
  end if;
  insert into guild_gifts (guild_id, from_user, to_user, amount)
  values (v_gid, v_uid, p_to, p_amount) returning id into v_id;
  return v_id;
end;
$$;

-- Quà chưa nhận, chưa hết hạn, mới nhất trước.
create or replace function guild_gift_inbox()
returns table (id bigint, from_nickname text, amount integer, created_at timestamptz)
language sql stable security definer set search_path = public as $$
  select g.id,
         coalesce((select m.nickname from guild_members m where m.user_id = g.from_user), '?'),
         g.amount, g.created_at
  from guild_gifts g
  where g.to_user = auth.uid()
    and g.claimed_at is null
    and g.created_at > now() - make_interval(days => guild_gift_expire_days())
  order by g.created_at desc
  limit 50
$$;

-- Nhận một món quà; trả số 💎. Mỗi quà nhận đúng một lần (update có điều kiện).
create or replace function guild_gift_claim(p_id bigint) returns integer
language plpgsql security definer set search_path = public as $$
declare v_amount integer;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  update guild_gifts set claimed_at = now()
    where id = p_id and to_user = auth.uid() and claimed_at is null
      and created_at > now() - make_interval(days => guild_gift_expire_days())
    returning amount into v_amount;
  if v_amount is null then raise exception 'already claimed'; end if;
  return v_amount;
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
    'guild_chat_report(bigint)', 'guild_set_officer(uuid,boolean)',
    'guild_transfer_owner(uuid)', 'guild_activity(integer)',
    'guild_claim_fund()', 'guild_gift_send(uuid,integer)',
    'guild_gift_inbox()', 'guild_gift_claim(bigint)', 'guild_leaderboard_vip(integer)',
    'guild_vip_bonus()', 'guild_claim_boss()', 'guild_claim_team()', 'guild_chat_react(bigint,text)', 'guild_expand()'
  ] loop
    execute format('revoke all on function %s from public', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- BXH Hội công khai cho trang web (khoá anon, chưa đăng nhập): chỉ tên/tag/emoji/
-- số thành viên/điểm tuần của hội không bị ẩn — cùng dữ liệu đã hiện trong app.
grant execute on function guild_leaderboard(integer) to anon;

-- Hàm nội bộ: client KHÔNG được gọi trực tiếp (Supabase mặc định cấp execute cho
-- anon/authenticated với hàm mới nên phải thu hồi rõ ràng) — nếu không ai cũng
-- ghi được lịch sử điểm tuần của hội để nâng chuỗi.
revoke all on function guild_log_week(uuid, date, bigint)
  from public, anon, authenticated;
revoke all on function guild_log_event(uuid, text, text, text)
  from public, anon, authenticated;
-- HP/bậc boss của hội tuỳ ý → không cho client gọi (lộ số liệu hội khác).
revoke all on function guild_boss_tier(uuid) from public, anon, authenticated;
revoke all on function guild_boss_hp(uuid) from public, anon, authenticated;
-- Đếm VIP của hội tuỳ ý → không cho client gọi (lộ số liệu hội khác).
revoke all on function guild_vip_count(uuid) from public, anon, authenticated;
revoke all on function guild_vip_bonus_pct(uuid) from public, anon, authenticated;
-- Hàm tính quỹ nhận user/guild tuỳ ý → không cho client gọi (lộ số liệu hội khác).
revoke all on function guild_fund_donated(uuid) from public, anon, authenticated;
revoke all on function guild_fund_progress(uuid) from public, anon, authenticated;
revoke all on function guild_team_active(uuid) from public, anon, authenticated;

-- ===== guild_dungeon_schema.sql =====
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

-- ===== season_leaderboard_schema.sql =====
-- Bảng xếp hạng Thẻ Mùa: xếp theo XP mùa của MÙA HIỆN TẠI (client tự khai, chỉ tăng, trần = 28 ngày × 150 XP).
-- Id mùa = số ngày UTC từ epoch / 28, khớp seasonIdFor ở lib/core/season.dart (test so khớp). Bảng tự "reset" mỗi mùa
-- vì mỗi mùa là một tập hàng riêng. Chỉ tài khoản liên kết email mới nộp được. Dán TOÀN BỘ vào SQL Editor → Run. Idempotent.

create table if not exists season_leaderboard_entries (
  user_id    uuid    not null references auth.users(id) on delete cascade,
  season_id  integer not null,
  nickname   text    not null check (char_length(nickname) between 1 and 20),
  xp         integer not null check (xp between 0 and 4200),
  updated_at timestamptz not null default now(),
  primary key (user_id, season_id)
);
alter table season_leaderboard_entries enable row level security;
-- Không policy: chỉ RPC security definer.
create index if not exists season_leaderboard_xp_idx on season_leaderboard_entries (season_id, xp desc, updated_at asc);

create or replace function season_current_id() returns integer
language sql stable as $$ select (floor(extract(epoch from now()) / 86400)::integer) / 28 $$;

create or replace function submit_season_xp(p_nickname text, p_season integer, p_xp integer) returns void
language plpgsql security definer set search_path = public as $$
declare v_name text := btrim(coalesce(p_nickname, ''));
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from auth.users where id = auth.uid() and is_anonymous) then raise exception 'email link required'; end if;
  if p_season is distinct from season_current_id() then return; end if;  -- chỉ mùa hiện tại
  if p_xp is null or p_xp <= 0 then return; end if;
  if char_length(v_name) not between 1 and 20 then raise exception 'bad nickname'; end if;
  insert into season_leaderboard_entries (user_id, season_id, nickname, xp)
  values (auth.uid(), p_season, v_name, least(p_xp, 4200))
  on conflict (user_id, season_id) do update
    set nickname = excluded.nickname,
        updated_at = case when excluded.xp > season_leaderboard_entries.xp then now() else season_leaderboard_entries.updated_at end,
        xp = greatest(season_leaderboard_entries.xp, excluded.xp);
end;
$$;

create or replace function season_leaderboard_top(p_limit integer default 50)
returns table (user_id uuid, nickname text, xp integer, rank bigint)
language sql stable security definer set search_path = public as $$
  select e.user_id, e.nickname, e.xp,
         row_number() over (order by e.xp desc, e.updated_at asc) as rank
    from season_leaderboard_entries e
   where e.season_id = season_current_id()
   order by rank
   limit least(greatest(p_limit, 1), 100)
$$;

revoke all on function submit_season_xp(text, integer, integer) from public, anon;
grant execute on function submit_season_xp(text, integer, integer) to authenticated;
grant execute on function season_leaderboard_top(integer) to anon, authenticated;

-- ── Thưởng cuối mùa ────────────────────────────────────────────────────────────────────────────────
-- Top 10 XP của mùa VỪA KẾT THÚC nhận 💎 (hạng 1/2/3 = 1000/600/400, 4-10 = 200). Chụp lười như thưởng BXH tuần: lần đầu
-- có người gọi season_reward_status() trong mùa mới thì server chụp top 10 của mùa trước (chỉ tài khoản liên kết email,
-- XP > 0). Nhận được trong suốt mùa hiện tại (28 ngày), MỘT lần cho mỗi mùa. Muốn chốt đúng giây: pg_cron gọi season_reward_snapshot().
create table if not exists season_reward_snapshots (
  season_id integer not null,
  rank      integer not null check (rank between 1 and 10),
  user_id   uuid    not null references auth.users(id) on delete cascade,
  nickname  text    not null,
  xp        integer not null,
  primary key (season_id, rank)
);
create index if not exists season_reward_snapshots_user_idx on season_reward_snapshots (user_id, season_id);
create table if not exists season_reward_claims (
  user_id    uuid    not null references auth.users(id) on delete cascade,
  season_id  integer not null,
  gems       integer not null,
  claimed_at timestamptz not null default now(),
  primary key (user_id, season_id)
);
alter table season_reward_snapshots enable row level security;
alter table season_reward_claims enable row level security;
-- Không policy: chỉ RPC security definer.

-- 💎 theo hạng. Khớp lib/core/season.dart (test so khớp).
create or replace function season_reward_gems(p_rank integer) returns integer
language sql immutable as $$
  select case p_rank when 1 then 1000 when 2 then 600 when 3 then 400 when 4 then 200 when 5 then 200
                     when 6 then 200 when 7 then 200 when 8 then 200 when 9 then 200 when 10 then 200 else 0 end
$$;

create or replace function season_reward_snapshot() returns void
language plpgsql security definer set search_path = public as $$
declare v_prev integer := season_current_id() - 1;
begin
  perform pg_advisory_xact_lock(hashtext('season_reward_snapshot'));
  if exists (select 1 from season_reward_snapshots where season_id = v_prev) then return; end if;
  insert into season_reward_snapshots (season_id, rank, user_id, nickname, xp)
  select v_prev, r.rn, r.user_id, r.nickname, r.xp from (
    select e.user_id, e.nickname, e.xp,
           row_number() over (order by e.xp desc, e.updated_at asc)::integer as rn
      from season_leaderboard_entries e join auth.users u on u.id = e.user_id
     where e.season_id = v_prev and e.xp > 0 and not u.is_anonymous) r
  where r.rn <= 10;
end;
$$;

-- Thưởng của mình ở mùa trước: [{season, rank, gems, claimed}] (rỗng nếu không có). Gọi hàm này kích hoạt việc chụp.
create or replace function season_reward_status() returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  perform season_reward_snapshot();
  return coalesce((
    select jsonb_agg(jsonb_build_object('season', s.season_id, 'rank', s.rank,
             'gems', season_reward_gems(s.rank),
             'claimed', exists (select 1 from season_reward_claims c where c.user_id = v_uid and c.season_id = s.season_id)))
      from season_reward_snapshots s
     where s.user_id = v_uid and s.season_id = season_current_id() - 1), '[]'::jsonb);
end;
$$;

create or replace function season_reward_claim(p_season integer) returns integer
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_rank integer; v_gems integer;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select s.rank into v_rank from season_reward_snapshots s
   where s.season_id = p_season and s.user_id = v_uid and s.season_id = season_current_id() - 1;
  if v_rank is null then raise exception 'not found'; end if;
  v_gems := season_reward_gems(v_rank);
  begin
    insert into season_reward_claims (user_id, season_id, gems) values (v_uid, p_season, v_gems);
  exception when unique_violation then
    raise exception 'already claimed';
  end;
  return v_gems;
end;
$$;

revoke all on function season_reward_snapshot() from public, anon, authenticated;
revoke all on function season_reward_status() from public, anon;
revoke all on function season_reward_claim(integer) from public, anon;
grant execute on function season_reward_status() to authenticated;
grant execute on function season_reward_claim(integer) to authenticated;

-- ===== player_title_schema.sql =====
-- Danh hiệu hồ sơ: người chơi chọn 1 danh hiệu (mở khoá ở client từ tiến độ) để hiện trên hồ sơ công khai.
-- Thuần trang trí nên server chỉ kiểm whitelist id + tài khoản đã liên kết email (không ẩn danh).
-- Khớp lib/core/titles.dart (test so khớp). Dán TOÀN BỘ vào Supabase SQL Editor → Run. Idempotent.
-- Chạy SAU leaderboard_schema (tra user theo tên ở leaderboard_entries).

create table if not exists player_titles (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  title_id   text not null,
  updated_at timestamptz not null default now()
);
alter table player_titles enable row level security;
-- Không policy: chỉ RPC security definer.

create or replace function set_player_title(p_id text) returns void
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from auth.users where id = v_uid and is_anonymous) then raise exception 'not linked'; end if;
  if p_id = '' then
    delete from player_titles where user_id = v_uid;
    return;
  end if;
  if p_id not in ('tycoon', 'mogul', 'legend', 'timewalker', 'stargazer', 'collector', 'vip', 'champion') then
    raise exception 'invalid title';
  end if;
  insert into player_titles (user_id, title_id) values (v_uid, p_id)
  on conflict (user_id) do update set title_id = excluded.title_id, updated_at = now();
end;
$$;

-- Danh hiệu của người có tên này ('' nếu không có). Tên trùng: lấy người có thu nhập cao nhất đã chọn danh hiệu.
create or replace function player_title(p_nickname text) returns text
language sql stable security definer set search_path = public as $$
  select coalesce((
    select t.title_id from leaderboard_entries e join player_titles t on t.user_id = e.user_id
     where lower(e.nickname) = lower(btrim(p_nickname))
     order by e.lifetime_earnings desc limit 1), '')
$$;

revoke all on function set_player_title(text) from public, anon;
grant execute on function set_player_title(text) to authenticated;
grant execute on function player_title(text) to anon, authenticated;

-- ===== player_avatar_schema.sql =====
-- Avatar ảnh của người chơi (hiện trên trang hồ sơ của mình và hồ sơ công khai).
-- Ảnh nằm ở Supabase Storage, bucket công khai 'avatars', tên file = <khoá ngẫu nhiên>.jpg (KHÔNG lộ user_id).
-- Luồng: client gọi new_avatar_key() (server cấp khoá + ghi nhận của ai) → upload <khoá>.jpg (policy Storage chỉ cho đúng
-- chủ khoá, ≤100KB, chỉ JPEG) → hiện bằng URL công khai. Tra avatar người khác theo tên bằng player_avatar(tên).
-- Chỉ tài khoản liên kết email. Báo cáo: report_avatar(tên); đủ 3 người báo cáo khác nhau cho CÙNG một ảnh → tự ẩn (hidden)
-- chờ duyệt. Duyệt tay: select * from avatar_reports ...; gỡ: update player_avatars set hidden = true where user_id = '...';
-- bỏ ẩn: set hidden = false. Người bị ẩn đổi ảnh mới thì hết ẩn (báo cáo gắn với từng ảnh).
-- Dán TOÀN BỘ vào Supabase SQL Editor → Run. Idempotent. Chạy SAU leaderboard_schema (tra tên ở leaderboard_entries).

create table if not exists player_avatars (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  key        uuid not null,
  prev_key   uuid,
  hidden     boolean not null default false,
  updated_at timestamptz not null default now()
);
alter table player_avatars add column if not exists prev_key uuid;
alter table player_avatars enable row level security;
-- Không policy cho client: chỉ RPC security definer (và policy Storage bên dưới, tự đọc bảng qua hàm).

-- Cấp khoá mới cho ảnh sắp tải lên; trả về khoá cũ (client xoá file cũ sau khi tải xong) hoặc null.
create or replace function new_avatar_key() returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_old uuid; v_new uuid := gen_random_uuid();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from auth.users where id = v_uid and is_anonymous) then raise exception 'not linked'; end if;
  select key into v_old from player_avatars where user_id = v_uid;
  insert into player_avatars (user_id, key) values (v_uid, v_new)
  on conflict (user_id) do update
    set key = excluded.key, prev_key = player_avatars.key, hidden = false, updated_at = now();
  return jsonb_build_object('key', v_new, 'old', v_old);
end;
$$;

create or replace function clear_avatar() returns uuid
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_old uuid;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  delete from player_avatars where user_id = v_uid returning key into v_old;
  return v_old;
end;
$$;

-- Khoá avatar công khai của người có tên này ('' nếu không có/bị ẩn). Tên trùng: lấy người thu nhập cao nhất có avatar.
create or replace function player_avatar(p_nickname text) returns text
language sql stable security definer set search_path = public as $$
  select coalesce((
    select a.key::text from leaderboard_entries e join player_avatars a on a.user_id = e.user_id
     where lower(e.nickname) = lower(btrim(p_nickname)) and not a.hidden
     order by e.lifetime_earnings desc limit 1), '')
$$;

-- Chủ sở hữu khoá? (dùng cho policy Storage; security definer vì client không đọc được player_avatars.)
create or replace function avatar_key_owned(p_name text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from player_avatars a
                  where a.user_id = auth.uid() and a.key::text || '.jpg' = p_name)
$$;

-- Được xoá file này? (khoá hiện tại hoặc khoá ngay trước — client xoá ảnh cũ SAU khi đã đổi khoá.)
create or replace function avatar_key_deletable(p_name text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from player_avatars a
                  where a.user_id = auth.uid()
                    and (a.key::text || '.jpg' = p_name or a.prev_key::text || '.jpg' = p_name))
$$;
grant execute on function avatar_key_deletable(text) to authenticated;

revoke all on function new_avatar_key() from public, anon;
revoke all on function clear_avatar() from public, anon;
grant execute on function new_avatar_key() to authenticated;
grant execute on function clear_avatar() to authenticated;
grant execute on function player_avatar(text) to anon, authenticated;
grant execute on function avatar_key_owned(text) to authenticated;

-- Storage (bỏ qua nếu môi trường không có Storage, vd Postgres tạm khi test).
do $$
begin
  if to_regclass('storage.objects') is null then return; end if;
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('avatars', 'avatars', true, 102400, array['image/jpeg'])
  on conflict (id) do update set public = true, file_size_limit = 102400, allowed_mime_types = array['image/jpeg'];
  drop policy if exists avatars_insert_own on storage.objects;
  create policy avatars_insert_own on storage.objects for insert to authenticated
    with check (bucket_id = 'avatars' and avatar_key_owned(name));
  drop policy if exists avatars_delete_own on storage.objects;
  create policy avatars_delete_own on storage.objects for delete to authenticated
    using (bucket_id = 'avatars' and avatar_key_deletable(name));
end $$;

-- Báo cáo ảnh vi phạm. Server tự tra ảnh hiện tại của người có tên đó (client không chỉ định khoá tuỳ ý).
create table if not exists avatar_reports (
  reporter   uuid not null references auth.users(id) on delete cascade,
  key        uuid not null,
  created_at timestamptz not null default now(),
  primary key (reporter, key)
);
alter table avatar_reports enable row level security;
-- Không policy: chỉ RPC.

-- Số người báo cáo khác nhau để tự ẩn ảnh (chờ duyệt).
create or replace function avatar_report_threshold() returns integer
language sql immutable as $$ select 3 $$;

-- Trả true nếu ảnh vừa bị ẩn do đủ báo cáo.
create or replace function report_avatar(p_nickname text) returns boolean
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_owner uuid; v_key uuid; v_n integer;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from auth.users where id = v_uid and is_anonymous) then raise exception 'not linked'; end if;
  select a.user_id, a.key into v_owner, v_key
    from leaderboard_entries e join player_avatars a on a.user_id = e.user_id
   where lower(e.nickname) = lower(btrim(p_nickname)) and not a.hidden
   order by e.lifetime_earnings desc limit 1;
  if v_key is null then raise exception 'not found'; end if;
  if v_owner = v_uid then raise exception 'own avatar'; end if;
  insert into avatar_reports (reporter, key) values (v_uid, v_key) on conflict do nothing;
  select count(*) into v_n from avatar_reports where key = v_key;
  if v_n >= avatar_report_threshold() then
    update player_avatars set hidden = true where user_id = v_owner and key = v_key;
    return true;
  end if;
  return false;
end;
$$;
revoke all on function report_avatar(text) from public, anon;
grant execute on function report_avatar(text) to authenticated;

-- ===== player_profile_schema.sql =====
-- Hồ sơ công khai của người chơi cho trang web (?player=<tên>): hạng + điểm ở 5 BXH cá nhân,
-- cộng 1 dòng 'guild' (hạng + điểm tuần của hội đang ở; cột label = tên hội) nếu hội có trên BXH Hội.
-- Chỉ trả những gì BXH công khai đã hiện (tên → hạng/điểm), KHÔNG trả user_id.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase SQL Editor → Run. Idempotent. Chạy SAU
-- leaderboard_schema, m3_leaderboard_schema, accessory_leaderboard_schema, story_speedrun_schema
-- và accessory_market_schema (cần đủ 5 bảng điểm) và guild_schema (dòng hội).
--
-- Tên không duy nhất: trùng tên thì lấy hạng CAO NHẤT của tên đó ở mỗi bảng. So khớp không phân
-- biệt hoa thường; đồng hạng/xếp theo đúng thứ tự của hàm *_top tương ứng.

-- Thêm cột label → đổi kiểu trả về nên phải drop hàm cũ trước (create or replace không đổi được).
drop function if exists player_profile(text);
create function player_profile(p_nickname text)
returns table (board text, rank bigint, value numeric, label text)
language sql
stable
security definer
set search_path = public
as $$
  with q as (
    select lower(btrim(p_nickname)) as n
    where char_length(btrim(p_nickname)) between 1 and 20
  ),
  income as (
    select 'income'::text as board, r.rank, r.v as value from (
      select nickname, row_number() over (order by lifetime_earnings desc, updated_at asc) as rank,
             lifetime_earnings::numeric as v
      from leaderboard_entries) r, q
    where lower(r.nickname) = q.n order by r.rank limit 1
  ),
  pearls as (
    select 'pearls'::text, r.rank, r.v from (
      select nickname, row_number() over (order by stars desc, updated_at asc) as rank,
             stars::numeric as v
      from m3_leaderboard_entries) r, q
    where lower(r.nickname) = q.n order by r.rank limit 1
  ),
  collection as (
    select 'collection'::text, r.rank, r.v from (
      select nickname, row_number() over (order by owned_count desc, updated_at asc) as rank,
             owned_count::numeric as v
      from accessory_leaderboard_entries) r, q
    where lower(r.nickname) = q.n order by r.rank limit 1
  ),
  speed as (
    select 'speed'::text, r.rank, r.v from (
      select nickname, row_number() over (order by complete_seconds asc, completed_at asc) as rank,
             complete_seconds::numeric as v
      from story_speedrun_entries) r, q
    where lower(r.nickname) = q.n order by r.rank limit 1
  ),
  vip as (
    select 'vip'::text, r.rank, r.v from (
      select nickname, row_number() over (order by vip_exp desc, updated_at asc) as rank,
             vip_exp::numeric as v
      from vip_leaderboard_entries) r, q
    where lower(r.nickname) = q.n order by r.rank limit 1
  ),
  -- Hội đang ở (cùng điều kiện hiện của guild_leaderboard: không bị ẩn, điểm tuần > 0). Tên
  -- trùng thì lấy hội có hạng cao nhất.
  guild as (
    select 'guild'::text, r.rank, r.total::numeric,
           r.emoji || ' ' || r.name || ' [' || r.tag || ']'
    from (
      select row_number() over (order by t.total desc, g.created_at asc) as rank,
             g.id, g.name, g.tag, g.emoji, t.total
      from guilds g
      cross join lateral (select guild_week_total(g.id) as total) t
      where not g.hidden and t.total > 0) r
    join guild_members m on m.guild_id = r.id, q
    where lower(m.nickname) = q.n order by r.rank limit 1
  )
  select x.*, null::text from income x
  union all select x.*, null::text from pearls x
  union all select x.*, null::text from collection x
  union all select x.*, null::text from speed x
  union all select x.*, null::text from vip x
  union all select x.* from guild x;
$$;

grant execute on function player_profile(text) to anon, authenticated;
