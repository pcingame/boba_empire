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

alter table accessory_leaderboard_entries enable row level security;

-- Đọc: ai cũng được, kể cả chưa đăng nhập — bảng xếp hạng công khai.
drop policy if exists accessory_leaderboard_select_all on accessory_leaderboard_entries;
create policy accessory_leaderboard_select_all on accessory_leaderboard_entries
  for select to anon, authenticated using (true);

-- Ghi: chỉ hàng của chính mình.
drop policy if exists accessory_leaderboard_insert_own on accessory_leaderboard_entries;
create policy accessory_leaderboard_insert_own on accessory_leaderboard_entries
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists accessory_leaderboard_update_own on accessory_leaderboard_entries;
create policy accessory_leaderboard_update_own on accessory_leaderboard_entries
  for update to authenticated using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

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
