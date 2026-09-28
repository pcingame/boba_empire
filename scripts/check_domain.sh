#!/usr/bin/env bash
# Kiểm domain bobaempiregame.com đã trỏ đúng GitHub Pages chưa.
# Chạy: bash scripts/check_domain.sh
# Dùng sau khi sửa DNS ở Namecheap — DNS lan mất vài phút tới vài giờ, script
# này cho biết còn thiếu đúng cái gì thay vì ngồi đoán.
set -u

DOMAIN=bobaempiregame.com
PAGES_IPS=(185.199.108.153 185.199.109.153 185.199.110.153 185.199.111.153)
ok=0; fail=0
pass() { echo "  ✅ $1"; ok=$((ok+1)); }
bad()  { echo "  ❌ $1"; fail=$((fail+1)); }

echo "1) A record của $DOMAIN → 4 IP của GitHub Pages"
got=$(dig +short "$DOMAIN" A | sort)
if [ -z "$got" ]; then
  bad "chưa có A record nào (bước 2 trong DOMAIN_TODO.md)"
else
  want=$(printf '%s\n' "${PAGES_IPS[@]}" | sort)
  if [ "$got" = "$want" ]; then
    pass "đủ 4 IP, đúng"
  else
    bad "đang trỏ: $(echo "$got" | tr '\n' ' ')"
    echo "     cần đúng 4 IP: ${PAGES_IPS[*]}"
  fi
fi

echo "2) URL Redirect parking của Namecheap đã gỡ chưa"
# Parking để lại A record lạ ở gốc. Chưa có A record nào thì chưa kết luận được.
if [ -z "$got" ]; then
  echo "  ⏭  bỏ qua — chưa có A record nào để xét"
elif dig +short "$DOMAIN" A | grep -qvE "$(IFS='|'; echo "${PAGES_IPS[*]}")"; then
  bad "còn bản ghi lạ ở gốc — xem lại bước 1 trong DOMAIN_TODO.md"
else
  pass "không thấy bản ghi lạ ở gốc"
fi

echo "3) CNAME www → pcingame.github.io"
cname=$(dig +short "www.$DOMAIN" CNAME)
case "$cname" in
  pcingame.github.io.) pass "đúng" ;;
  "") bad "chưa có CNAME cho www (bước 3)" ;;
  *) bad "đang trỏ $cname, cần pcingame.github.io." ;;
esac

echo "4) Trang web trả về gì"
# `|| echo` sẽ nối thêm chuỗi vào mã đã in ra ("000000") — dùng biến trung gian.
code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://$DOMAIN")
[ -z "$code" ] && code=000
case "$code" in
  200) pass "HTTPS 200 — trang đã sống" ;;
  000) bad "không kết nối được (DNS chưa lan, hoặc chứng chỉ HTTPS chưa cấp xong)" ;;
  *)   bad "HTTP $code — thường là GitHub Pages chưa nhận custom domain (bước 5)" ;;
esac

echo "5) Email forwarding support@$DOMAIN"
if dig +short "$DOMAIN" MX | grep -q .; then
  pass "có MX record: $(dig +short "$DOMAIN" MX | tr '\n' ' ')"
else
  bad "chưa có MX — mail tới support@$DOMAIN sẽ bounce (bước 4)"
fi

echo
echo "Xong: $ok đạt, $fail chưa. Chi tiết từng bước: DOMAIN_TODO.md"
[ "$fail" -eq 0 ]
