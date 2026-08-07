#!/usr/bin/env bash
#
# Tải bộ SFX CC0 (public domain) về assets/audio/ với đúng tên game cần.
#
# Nguồn: Kenney "Interface Sounds", đóng gói bởi Calinou — giấy phép CC0-1.0
#   https://github.com/Calinou/kenney-interface-sounds
#   CC0 = miễn phí hoàn toàn, dùng thương mại, KHÔNG cần ghi công.
#
# Chạy lại bất cứ lúc nào để lấy lại / đổi bộ tiếng (ghi đè file cùng tên):
#   bash scripts/fetch_sfx.sh
# Sau đó HOT RESTART app (không phải hot reload) để nạp lại cache âm thanh.
set -euo pipefail

BASE="https://raw.githubusercontent.com/Calinou/kenney-interface-sounds/master/addons/kenney_interface_sounds"
DEST="$(cd "$(dirname "$0")/.." && pwd)/assets/audio"
mkdir -p "$DEST"

# Ánh xạ <tên game> → <tên file nguồn>. Muốn đổi tiếng: sửa vế phải (danh sách
# file xem trong repo nguồn, ví dụ click_001, glass_003, confirmation_002...).
mapping="
tap:glass_002
buy:confirmation_001
unlock:open_002
prestige:bong_001
vip:pluck_001
reward:select_005
"

count=0
while IFS=: read -r name src; do
  [ -z "$name" ] && continue
  out="$DEST/$name.wav"
  echo "↓ $name.wav  ←  $src.wav"
  curl -fsSL "$BASE/$src.wav" -o "$out"
  # Chặn "tải nhầm trang lỗi": file WAV thật bắt đầu bằng 'RIFF'.
  if ! head -c4 "$out" | grep -q RIFF; then
    echo "  ✗ không phải WAV hợp lệ: $out" >&2
    exit 1
  fi
  count=$((count + 1))
done <<< "$mapping"

echo "✓ Xong: $count file trong $DEST"
