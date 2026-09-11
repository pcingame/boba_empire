-- Schema cho analytics nhẹ (session length, phễu tiến trình, tần suất
-- prestige) — xem PROPOSAL_ANALYTICS.md.
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor →
-- Run. Idempotent. Độc lập với arena_schema.sql/cloud_save_schema.sql —
-- dán trước/sau đều được, không đụng bảng nào khác.
--
-- KHÔNG dùng auth — client ghi bằng apikey publishable thẳng, không có
-- phiên đăng nhập nào (xem lib/data/analytics_repository.dart). Vì vậy RLS
-- ở đây khác kiểu với 2 bảng kia: cho phép role `anon` GHI (insert), nhưng
-- KHÔNG có policy nào cho ĐỌC — không ai qua API công khai đọc được bảng
-- này, kể cả đọc lại đúng dòng mình vừa ghi. Bạn (chủ project) tự đọc qua
-- Dashboard → Table Editor / SQL Editor (kết nối đó có quyền admin, không
-- đi qua RLS).

create table if not exists analytics_events (
  id          bigint generated always as identity primary key,
  device_id   text not null,
  event       text not null,
  props       jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

create index if not exists analytics_events_device_idx
  on analytics_events (device_id);
create index if not exists analytics_events_event_idx
  on analytics_events (event);
create index if not exists analytics_events_created_idx
  on analytics_events (created_at);

alter table analytics_events enable row level security;

drop policy if exists analytics_events_insert_anyone on analytics_events;
create policy analytics_events_insert_anyone on analytics_events
  for insert
  to anon, authenticated
  with check (true);

-- ─────────────────────────────────────────────────────────────────────────
-- Vài câu SQL tham khảo để xem số liệu sau này (chạy trong SQL Editor):
--
-- Thời lượng session trung bình/trung vị (giây):
--   select avg((props->>'seconds')::numeric), percentile_cont(0.5)
--     within group (order by (props->>'seconds')::numeric)
--   from analytics_events where event = 'session_end';
--
-- Phễu: bao nhiêu máy từng đạt mỗi giai đoạn:
--   select props->>'stage' as stage, count(distinct device_id)
--   from analytics_events where event = 'stage_reached'
--   group by 1 order by 1;
--
-- Bao nhiêu máy từng prestige, trung bình mất bao lâu (giây) từ sự kiện ĐẦU
-- TIÊN ghi nhận của máy đó tới lần prestige đầu tiên (không cần app tự lưu
-- "cài lúc nào" — suy ra thẳng từ created_at của chính các sự kiện):
--   with first_seen as (
--     select device_id, min(created_at) as t0
--     from analytics_events group by device_id
--   ), first_prestige as (
--     select device_id, min(created_at) as t1
--     from analytics_events where event = 'prestige' group by device_id
--   )
--   select count(*), avg(extract(epoch from (t1 - t0)))
--   from first_seen join first_prestige using (device_id);
-- ─────────────────────────────────────────────────────────────────────────
