-- Bảng xếp hạng Chi nhánh: xếp theo TỔNG CẤP mọi chi nhánh (client tự khai, chỉ tăng; hiện tối đa 17 nơi × cấp 10 = 170,
-- trần 500 để thêm thành phố không phải sửa). Chỉ tài khoản liên kết email mới nộp được. Hoà: ai đạt trước xếp trên.
-- Dán TOÀN BỘ vào SQL Editor → Run. Idempotent.

create table if not exists branch_leaderboard_entries (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  nickname     text    not null check (char_length(nickname) between 1 and 20),
  total_levels integer not null check (total_levels between 0 and 500),
  opened       integer not null check (opened between 0 and 50),
  updated_at   timestamptz not null default now()
);
alter table branch_leaderboard_entries enable row level security;
-- Không policy: chỉ RPC security definer.
create index if not exists branch_leaderboard_levels_idx on branch_leaderboard_entries (total_levels desc, updated_at asc);

create or replace function submit_branch_levels(p_nickname text, p_total integer, p_opened integer) returns void
language plpgsql security definer set search_path = public as $$
declare v_name text := btrim(coalesce(p_nickname, ''));
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from auth.users where id = auth.uid() and is_anonymous) then raise exception 'email link required'; end if;
  if p_total is null or p_total <= 0 then return; end if;
  if char_length(v_name) not between 1 and 20 then raise exception 'bad nickname'; end if;
  insert into branch_leaderboard_entries (user_id, nickname, total_levels, opened)
  values (auth.uid(), v_name, least(p_total, 500), least(greatest(coalesce(p_opened, 0), 0), 50))
  on conflict (user_id) do update
    set nickname = excluded.nickname,
        updated_at = case when excluded.total_levels > branch_leaderboard_entries.total_levels then now()
                          else branch_leaderboard_entries.updated_at end,
        total_levels = greatest(branch_leaderboard_entries.total_levels, excluded.total_levels),
        opened = greatest(branch_leaderboard_entries.opened, excluded.opened);
end;
$$;

create or replace function branch_leaderboard_top(p_limit integer default 50)
returns table (user_id uuid, nickname text, total_levels integer, opened integer, rank bigint)
language sql stable security definer set search_path = public as $$
  select e.user_id, e.nickname, e.total_levels, e.opened,
         row_number() over (order by e.total_levels desc, e.updated_at asc) as rank
    from branch_leaderboard_entries e
   order by rank
   limit least(greatest(p_limit, 1), 100)
$$;

revoke all on function submit_branch_levels(text, integer, integer) from public, anon;
grant execute on function submit_branch_levels(text, integer, integer) to authenticated;
grant execute on function branch_leaderboard_top(integer) to anon, authenticated;
