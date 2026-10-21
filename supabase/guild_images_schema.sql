-- Ảnh trong chat Hội: bucket Storage công khai 'guild-images' (≤350KB, chỉ JPEG) + policy tải lên.
-- Luồng: client gọi guild_image_new_key() (guild_schema.sql; chỉ thành viên hội, ≤5 khoá/phút) → upload <khoá>.jpg → guild_chat_post(body, khoá).
-- Policy chỉ cho tải đúng file của khoá MÌNH đã xin và chưa gắn vào tin nào. Tên file là uuid ngẫu nhiên (không đoán được).
-- Tin chứa ảnh bị báo cáo/ẩn thì ảnh không còn hiện trong app; file mồ côi vài trăm KB: dọn tay trong Storage nếu cần.
-- Dán TOÀN BỘ vào Supabase SQL Editor → Run SAU guild_schema.sql. Idempotent.

-- Policy Storage: chỉ tải lên đúng file <khoá>.jpg của khoá mình đã xin và chưa dùng.
create or replace function guild_image_key_owned(p_name text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from guild_image_keys k
                  where k.user_id = auth.uid() and not k.used and k.key::text || '.jpg' = p_name)
$$;
grant execute on function guild_image_key_owned(text) to authenticated;

do $$
begin
  if to_regclass('storage.objects') is null then return; end if;
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('guild-images', 'guild-images', true, 358400, array['image/jpeg'])
  on conflict (id) do update set public = true, file_size_limit = 358400, allowed_mime_types = array['image/jpeg'];
  drop policy if exists guild_images_insert_own on storage.objects;
  create policy guild_images_insert_own on storage.objects for insert to authenticated
    with check (bucket_id = 'guild-images' and guild_image_key_owned(name));
end $$;
