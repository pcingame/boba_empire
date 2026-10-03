#!/usr/bin/env bash
# Chụp ảnh màn hình cho store bằng integration_test.
#
#   ./scripts/shoot.sh <udid>                 # tiếng Việt
#   ./scripts/shoot.sh <udid> en              # một ngôn ngữ
#   ./scripts/shoot.sh <udid> all             # cả 6 ngôn ngữ
#
# Lấy udid: `xcrun simctl list devices available | grep iPad`
#
# Ảnh ra ở assets/store/screenshots/<ipad|iphone>/<ngôn ngữ>_<tên>.png
# Kích thước ảnh = kích thước máy ảo, nên CHỌN ĐÚNG MÁY:
#   App Store đòi ảnh iPad 13" (2064x2752) → dùng "iPad Pro 13-inch".
#   iPhone 6.9" (1320x2868)                → dùng "iPhone 17 Pro Max".
set -euo pipefail

UDID="${1:-}"
LOCALES="${2:-vi}"

if [[ -z "$UDID" ]]; then
  echo "thiếu udid. Xem: xcrun simctl list devices available | grep -i ipad" >&2
  exit 1
fi

# Tên máy quyết định thư mục ảnh — iPad và iPhone phải để riêng.
NAME="$(xcrun simctl list devices available -j \
  | python3 -c "import json,sys;d=json.load(sys.stdin)['devices'];print(next((x['name'] for v in d.values() for x in v if x['udid']=='$UDID'),''))")"
if [[ -z "$NAME" ]]; then
  echo "không thấy máy ảo $UDID" >&2
  exit 1
fi
case "$NAME" in
  *iPad*) KIND=ipad ;;
  *)      KIND=iphone ;;
esac

if [[ "$LOCALES" == "all" ]]; then
  LOCALES="vi en es id pt th"
fi

export SHOT_DIR="assets/store/screenshots/$KIND" # driver đọc từ môi trường
echo "máy: $NAME ($KIND) · ngôn ngữ: $LOCALES"
xcrun simctl boot "$UDID" 2>/dev/null || true

for loc in $LOCALES; do
  echo "--- $loc ---"
  flutter drive \
    --driver=test_driver/screenshots.dart \
    --target=integration_test/screenshots_test.dart \
    -d "$UDID" \
    --dart-define=SHOT_LOCALE="$loc" \
    --dart-define=SHOT_DIR="assets/store/screenshots/$KIND"
done

echo
echo "xong. Ảnh ở assets/store/screenshots/$KIND/"
ls -1 "assets/store/screenshots/$KIND/" 2>/dev/null | head -20
