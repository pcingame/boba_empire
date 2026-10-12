#!/usr/bin/env bash
# Chạy kịch bản SQL guild trên Postgres tạm (cần `brew install postgresql@16`).
# Giả lập Supabase tối thiểu: schema auth (users, uid()) + role anon/authenticated.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
TMP="$(mktemp -d)"; PORT=54399
trap 'pg_ctl -D "$TMP/pg" stop >/dev/null 2>&1 || true; rm -rf "$TMP"' EXIT
initdb -D "$TMP/pg" -U postgres --auth=trust >/dev/null
pg_ctl -D "$TMP/pg" -o "-p $PORT -c unix_socket_directories=''" -l "$TMP/pg.log" start >/dev/null
for _ in $(seq 20); do psql -h 127.0.0.1 -p $PORT -U postgres -c 'select 1' >/dev/null 2>&1 && break; sleep 0.5; done
P() { psql -h 127.0.0.1 -p $PORT -U postgres -v ON_ERROR_STOP=1 -q "$@"; }
P <<'SQL'
create schema auth;
create table auth.users (id uuid primary key);
create function auth.uid() returns uuid language sql stable as
  $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
create role anon; create role authenticated;
grant usage on schema public, auth to anon, authenticated;
SQL
P -f supabase/guild_schema.sql >/dev/null 2>&1 || { P -f supabase/guild_schema.sql; exit 1; }
# Nâng cấp từ bản cũ (có mã mời/hội riêng): dựng lại dấu vết cũ rồi áp schema mới.
P -q <<'SQL'
alter table guilds add column is_public boolean not null default true,
                   add column invite_code text;
create function guild_join(uuid,text,text,bigint) returns uuid
  language sql as 'select null::uuid';
create function guild_list_public(integer) returns int language sql as 'select 1';
-- Bản trước khi có "cần duyệt": chữ ký/cột trả về khác.
create function guild_create(text,text,text,text,bigint) returns uuid
  language sql as 'select null::uuid';
drop function guild_list(integer);
create function guild_list(integer) returns int language sql as 'select 1';
alter table guilds drop column if exists requires_approval;
-- Dữ liệu cũ có tên trùng trong cùng hội (bản trước khi có chỉ mục tên duy nhất).
drop index guild_members_nick_idx;
insert into auth.users select ('ffffffff-0000-0000-0000-0000000000' || lpad(i::text, 2, '0'))::uuid
  from generate_series(1, 4) i;
insert into guilds (id, owner_id, name, tag, emoji)
  values ('eeeeeeee-0000-0000-0000-000000000001', 'ffffffff-0000-0000-0000-000000000001', 'DupClub', 'DC', '🧋');
insert into guild_members (user_id, guild_id, nickname, joined_at) values
  ('ffffffff-0000-0000-0000-000000000001', 'eeeeeeee-0000-0000-0000-000000000001', 'Bob', now() - interval '3 days'),
  ('ffffffff-0000-0000-0000-000000000002', 'eeeeeeee-0000-0000-0000-000000000001', 'bob', now() - interval '2 days'),
  ('ffffffff-0000-0000-0000-000000000003', 'eeeeeeee-0000-0000-0000-000000000001', 'BOB', now() - interval '1 day'),
  ('ffffffff-0000-0000-0000-000000000004', 'eeeeeeee-0000-0000-0000-000000000001', 'Zed', now());
SQL
P -f supabase/guild_schema.sql >/dev/null 2>&1   # idempotent + dọn bản cũ
LEFT=$(P -t -A -c "select (select count(*) from pg_proc where proname in ('guild_list_public')
  or (proname='guild_create' and pronargs=5) or (proname='guild_join' and pronargs=4))
  + (select count(*) from information_schema.columns
     where table_name='guilds' and column_name in ('is_public','invite_code'))")
P -c "select requires_approval, requested from guild_list(1)" >/dev/null 2>&1 \
  || { echo "MIGRATION FAIL: guild_list chưa nâng cấp"; exit 1; }
NICKS=$(P -t -A -c "select string_agg(nickname, ',' order by joined_at) from guild_members where guild_id = 'eeeeeeee-0000-0000-0000-000000000001'")
[ "$NICKS" = "Bob,bob#2,BOB#3,Zed" ] || { echo "MIGRATION FAIL: tên trùng chưa được đổi đúng: $NICKS"; exit 1; }
P -c "insert into guild_members (user_id, guild_id, nickname) values ('ffffffff-0000-0000-0000-000000000004', 'eeeeeeee-0000-0000-0000-000000000001', 'x')" >/dev/null 2>&1 \
  && { echo "MIGRATION FAIL: chỉ mục tên duy nhất chưa có"; exit 1; }
P -q -c "delete from guilds where id = 'eeeeeeee-0000-0000-0000-000000000001'; delete from auth.users where id::text like 'ffffffff-%'"
[ "$LEFT" = "0" ] || { echo "MIGRATION FAIL: còn $LEFT dấu vết bản cũ"; exit 1; }
P -t -A -f supabase/tests/guild_scenarios.sql 2>&1 | grep -v "^NOTICE\|^$\|^t_as\|^guild_\|^ *$" | tail -${TAIL:-15}
