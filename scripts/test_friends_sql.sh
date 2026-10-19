#!/usr/bin/env bash
# Chạy kịch bản SQL bạn bè trên Postgres tạm (cần `brew install postgresql@16`).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
TMP="$(mktemp -d)"; PORT=54396
trap 'pg_ctl -D "$TMP/pg" stop >/dev/null 2>&1 || true; rm -rf "$TMP"' EXIT
initdb -D "$TMP/pg" -U postgres --auth=trust >/dev/null
pg_ctl -D "$TMP/pg" -o "-p $PORT -c unix_socket_directories=''" -l "$TMP/pg.log" start >/dev/null
for _ in $(seq 20); do psql -h 127.0.0.1 -p $PORT -U postgres -c 'select 1' >/dev/null 2>&1 && break; sleep 0.5; done
P() { psql -h 127.0.0.1 -p $PORT -U postgres -v ON_ERROR_STOP=1 -q "$@"; }
P <<'SQL'
create schema auth; create table auth.users (id uuid primary key, is_anonymous boolean not null default false);
create function auth.uid() returns uuid language sql stable as
  $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
create role anon; create role authenticated; create publication supabase_realtime;
grant usage on schema public, auth to anon, authenticated;
SQL
for f in leaderboard_schema season_leaderboard_schema recipe_order_leaderboard_schema arena_schema arena_leaderboard_schema guild_schema friends_schema; do
  P -f supabase/$f.sql >/dev/null 2>&1 || { echo "nạp $f lỗi"; P -f supabase/$f.sql; exit 1; }
done
P -f supabase/friends_schema.sql >/dev/null 2>&1 || { echo "friends không idempotent"; exit 1; }
P -f supabase/tests/friends_scenarios.sql 2>&1 | grep -E "FAIL|ERROR|FRIENDS OK" || { echo "NO RESULT"; exit 1; }
