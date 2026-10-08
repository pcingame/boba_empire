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
SQL
P -f supabase/guild_schema.sql >/dev/null 2>&1   # idempotent + dọn bản cũ
LEFT=$(P -t -A -c "select (select count(*) from pg_proc where proname in ('guild_list_public')
  or (proname='guild_create' and pronargs=5) or (proname='guild_join' and pronargs=4))
  + (select count(*) from information_schema.columns
     where table_name='guilds' and column_name in ('is_public','invite_code'))")
P -c "select requires_approval, requested from guild_list(1)" >/dev/null 2>&1 \
  || { echo "MIGRATION FAIL: guild_list chưa nâng cấp"; exit 1; }
[ "$LEFT" = "0" ] || { echo "MIGRATION FAIL: còn $LEFT dấu vết bản cũ"; exit 1; }
P -t -A -f supabase/tests/guild_scenarios.sql 2>&1 | grep -v "^NOTICE\|^$\|^t_as\|^guild_\|^ *$" | tail -${TAIL:-15}
