-- Bảng chặn phát lại (replay) giao dịch IAP consumable — xem
-- server/lib/replay_store.dart. Chỉ 1 dòng/giao dịch, mục đích DUY NHẤT là
-- ràng buộc UNIQUE trên (source, transaction_id).
--
-- Cách deploy: dán TOÀN BỘ file này vào Supabase Dashboard → SQL Editor →
-- Run. Idempotent. Độc lập với các schema khác.
--
-- KHÔNG dùng anon key — chỉ receipt server (server/) ghi bằng SERVICE ROLE
-- KEY, không phải publishable key nhúng trong app. Bảng KHÔNG có policy nào
-- cho anon/authenticated (cả đọc lẫn ghi) — RLS bật nhưng để trống là chặn
-- hết, đúng ý: đây là sổ sách nội bộ của server, không ai qua app đọc/ghi
-- được, kể cả đọc lại giao dịch của chính mình.
--
-- ⚠️ SERVICE ROLE KEY là bí mật server — TUYỆT ĐỐI không nhúng vào app hay
-- commit vào repo (đặt qua biến môi trường SUPABASE_SERVICE_ROLE_KEY khi
-- deploy server, xem server/README.md).

create table if not exists iap_redeemed_receipts (
  source          text not null check (source in ('google_play', 'app_store')),
  transaction_id  text not null,
  product_id      text not null,
  redeemed_at     timestamptz not null default now(),
  primary key (source, transaction_id)
);

alter table iap_redeemed_receipts enable row level security;
-- Cố ý KHÔNG có policy nào — RLS bật + không policy = chặn hết cho
-- anon/authenticated. Service role key bỏ qua RLS hoàn toàn, không cần
-- policy riêng cho nó.
