#!/usr/bin/env bash
# Chạy các file SQL "phải chạy lại" lên Supabase THẬT bằng psql (thay cho dán tay vào SQL Editor).
#
#   export SUPABASE_DB_URL='postgresql://postgres:<MẬT KHẨU>@db.<ref>.supabase.co:5432/postgres'
#   scripts/deploy_supabase_sql.sh                 # chạy cả danh sách bên dưới (hỏi xác nhận)
#   scripts/deploy_supabase_sql.sh --dry-run       # chỉ in sẽ chạy gì, không kết nối
#   scripts/deploy_supabase_sql.sh -y story_speedrun4_schema recipe_daily_schema   # chỉ vài file, không hỏi
#
# Lấy chuỗi kết nối: Supabase Dashboard → Project Settings → Database → Connection string → URI. Dùng cổng
# 5432 (direct hoặc "Session pooler"), KHÔNG dùng "Transaction pooler" (6543). Mật khẩu là mật khẩu DATABASE
# (đặt/đổi ở cùng trang), không phải anon/service_role key. KHÔNG commit chuỗi này, KHÔNG dán vào chat.
#
# Mọi file đều idempotent. Mỗi file chạy trong MỘT giao dịch (--single-transaction): lỗi giữa chừng thì file đó
# hoàn tác nguyên vẹn, script dừng ngay và báo file nào lỗi (các file trước đó đã áp dụng xong, không bị đụng).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# Danh sách mặc định: các schema đã đổi mà CHƯA chắc chạy trên server (thứ tự không quan trọng với phụ thuộc,
# riêng leaderboard_rewards để cuối cho dễ đọc). Sửa danh sách này khi có đợt SQL mới.
DEFAULT_FILES=(
  leaderboard_schema m3_leaderboard_schema accessory_leaderboard_schema recipe_leaderboard_schema
  recipe_order_leaderboard_schema recipe_daily_schema
  story_speedrun_schema story_speedrun2_schema story_speedrun3_schema story_speedrun4_schema
  event_leaderboard_schema accessory_market_schema leaderboard_rewards_schema arena_schema
  guild_schema guild_dungeon_schema arena_leaderboard_schema season_leaderboard_schema
  player_title_schema player_gender_schema player_avatar_schema player_profile_schema friends_schema world_boss_schema
)

YES=0; DRY=0; FILES=()
for a in "$@"; do
  case "$a" in
    -y|--yes) YES=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
    *) FILES+=("${a%.sql}") ;;
  esac
done
[ ${#FILES[@]} -eq 0 ] && FILES=("${DEFAULT_FILES[@]}")

for f in "${FILES[@]}"; do
  [ -s "supabase/$f.sql" ] || { echo "✗ supabase/$f.sql không tồn tại hoặc RỖNG — dừng."; exit 1; }
done

echo "Sẽ chạy ${#FILES[@]} file theo thứ tự:"
for f in "${FILES[@]}"; do echo "  • supabase/$f.sql ($(wc -l < "supabase/$f.sql" | tr -d ' ') dòng)"; done
[ "$DRY" = 1 ] && { echo "(dry-run: không kết nối)"; exit 0; }

: "${SUPABASE_DB_URL:?Chưa đặt SUPABASE_DB_URL (xem hướng dẫn đầu file)}"
command -v psql >/dev/null || { echo "Không có psql (brew install postgresql@16)"; exit 1; }
case "$SUPABASE_DB_URL" in *:6543/*) echo "✗ Cổng 6543 là Transaction pooler — dùng 5432."; exit 1 ;; esac
# Chỉ in host, không bao giờ in mật khẩu.
HOST=$(printf '%s' "$SUPABASE_DB_URL" | sed -E 's#^[a-z]+://[^@]*@([^:/?]+).*#\1#')
echo "Máy chủ: $HOST"
if [ "$YES" != 1 ]; then
  read -r -p "Chạy lên máy chủ trên? (gõ 'yes' để tiếp tục) " ans
  [ "$ans" = "yes" ] || { echo "Huỷ."; exit 1; }
fi

psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -q -t -A -c "select 'kết nối OK: ' || current_database() || ' / ' || current_user" || exit 1
for f in "${FILES[@]}"; do
  printf '→ %s ... ' "$f"
  if out=$(psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -q --single-transaction -f "supabase/$f.sql" 2>&1); then
    echo "OK"
  else
    echo "LỖI"; echo "$out" | grep -vE '^psql:.*NOTICE' | tail -15
    echo "✗ Dừng tại $f (file này đã hoàn tác; các file trước đó đã áp dụng)."; exit 1
  fi
done
echo "✓ Xong ${#FILES[@]} file."
