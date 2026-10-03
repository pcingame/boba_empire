-- Thay cho "Database Webhooks" trên Dashboard (giao diện mới ẩn mục này):
-- 2 trigger gọi Edge Function notify-market-sale bằng pg_net, payload cùng
-- dạng webhook ({type, table, record}). ĐỔI '<WEBHOOK_SECRET>' thành đúng giá
-- trị đã `supabase secrets set WEBHOOK_SECRET=...` rồi chạy trong SQL Editor.
-- Idempotent; chạy lại để đổi secret. Secret nằm trong thân hàm (chỉ owner
-- đọc được) — đừng commit giá trị thật.

create extension if not exists pg_net;

create or replace function notify_market_push()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform net.http_post(
    url := 'https://orphyhtnaaqfglytffkn.supabase.co/functions/v1/notify-market-sale',
    body := jsonb_build_object(
      'type', 'INSERT', 'table', TG_TABLE_NAME, 'record', to_jsonb(NEW)),
    headers := jsonb_build_object(
      'content-type', 'application/json',
      'x-webhook-secret', '<WEBHOOK_SECRET>')
  );
  return null; -- lỗi mạng không được làm hỏng giao dịch/đăng bán
exception when others then
  return null;
end;
$$;

drop trigger if exists market_push_trade on accessory_market_trades;
create trigger market_push_trade
  after insert on accessory_market_trades
  for each row execute function notify_market_push();

drop trigger if exists market_push_listing on accessory_listings;
create trigger market_push_listing
  after insert on accessory_listings
  for each row execute function notify_market_push();
