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
-- Danh tính: dùng auth.uid() — bất kỳ phiên nào đang có (ẩn danh từ Đấu
-- Trường, hoặc permanent từ Đồng bộ đám mây) đều nộp được điểm, không bắt
-- buộc phải link email riêng cho bảng xếp hạng.

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
alter table leaderboard_entries
  alter column prestige_stars type bigint;

create index if not exists leaderboard_entries_lifetime_idx
  on leaderboard_entries (lifetime_earnings desc);

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
  with check (auth.uid() = user_id);

drop policy if exists leaderboard_entries_update_own on leaderboard_entries;
create policy leaderboard_entries_update_own on leaderboard_entries
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

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
create or replace function leaderboard_entries_validate()
returns trigger
language plpgsql
as $$
declare
  elapsed_seconds double precision;
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

  -- (2) Trần tuyệt đối cho LẦN NỘP ĐẦU TIÊN (không có mốc nào để so sánh
  -- theo thời gian) — rất rộng rãi, chỉ chặn số bịa kiểu "gửi thẳng 1e100"
  -- chứ không nhằm giới hạn người chơi thật giỏi.
  if new.lifetime_earnings > 1e50 then
    raise exception 'lifetime_earnings vượt xa mức có thể đạt được';
  end if;

  -- (3) Trần tăng trưởng GIỮA 2 LẦN NỘP theo thời gian thực trôi qua —
  -- không áp dụng cho lần nộp đầu (đã có check (2) ở trên; người chơi có
  -- thể đã tích luỹ rất nhiều TRƯỚC KHI lần đầu mở Bảng xếp hạng, không
  -- phải gian lận). Trần trung bình 1e19 Xu/giây kể từ lần nộp trước —
  -- rộng hơn hẳn thu nhập tối đa lý thuyết ở cấp trần (xem
  -- Balance.maxGeneratorLevel/milestoneStep) nhân mọi hệ số nhân "có
  -- trần" đã biết (mốc vàng, VIP/IAP/quảng cáo x2, Golden Rush x3...) —
  -- chỉ KHÔNG tính hệ số Sao (bonusPerStar) vì bản thân nó tăng không
  -- giới hạn theo thời gian thật, nên không thể có 1 trần "đúng tuyệt đối
  -- mãi mãi" cho riêng chỉ số này.
  if TG_OP = 'UPDATE' and new.lifetime_earnings > old.lifetime_earnings then
    elapsed_seconds := greatest(extract(epoch from (now() - old.updated_at)), 1);
    if (new.lifetime_earnings - old.lifetime_earnings) > 1e19 * elapsed_seconds then
      raise exception 'lifetime_earnings tăng bất thường trong khoảng thời gian quá ngắn';
    end if;
  end if;

  return new;
end;
$$;

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

-- drop trước vì đổi kiểu trả về (prestige_stars integer -> bigint):
-- `create or replace function` từ chối đổi return type của hàm đã tồn tại.
drop function if exists leaderboard_around_me(integer);

create or replace function leaderboard_around_me(p_window integer default 5)
returns table (
  user_id           uuid,
  nickname          text,
  lifetime_earnings numeric,
  prestige_stars    bigint,
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
