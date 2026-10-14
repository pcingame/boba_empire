#!/usr/bin/env bash
# Chạy kịch bản thưởng top BXH trên Postgres tạm (cần `brew install postgresql@16`).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
TMP="$(mktemp -d)"; PORT=54395
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
for f in leaderboard_schema m3_leaderboard_schema accessory_leaderboard_schema recipe_leaderboard_schema accessory_market_schema leaderboard_rewards_schema; do
  P -f supabase/$f.sql >/dev/null 2>&1 || { echo "nạp $f lỗi"; P -f supabase/$f.sql; exit 1; }
done
# chạy lại lần 2 phải idempotent
P -f supabase/recipe_leaderboard_schema.sql >/dev/null 2>&1 || { echo "recipe lb không idempotent"; exit 1; }
P -f supabase/leaderboard_rewards_schema.sql >/dev/null 2>&1 || { echo "không idempotent"; exit 1; }
P -f supabase/tests/lb_rewards_scenarios.sql 2>&1 | grep -E "FAIL|ERROR|LB REWARDS OK" || { echo "NO RESULT"; exit 1; }
P -f supabase/tests/recipe_lb_scenarios.sql 2>&1 | grep -E "FAIL|ERROR|RECIPE LB OK" || { echo "NO RESULT (recipe lb)"; exit 1; }
