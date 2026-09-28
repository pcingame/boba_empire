#!/usr/bin/env bash
# Kiểm domain bobaempiregame.com đã trỏ đúng GitHub Pages chưa.
# Chạy: bash scripts/check_domain.sh
# Dùng sau khi sửa DNS ở Namecheap — DNS lan mất vài phút tới vài giờ, script
# này cho biết còn thiếu đúng cái gì thay vì ngồi đoán.
set -u

DOMAIN=bobaempiregame.com
# Hỏi DNS CÔNG CỘNG, không hỏi resolver của máy: resolver máy cache cả câu trả
# lời RỖNG từ trước khi thêm bản ghi, nên báo "chưa có" trong khi thực tế đã có.
RESOLVER=${RESOLVER:-1.1.1.1}
dig() { command dig "@$RESOLVER" "$@"; }
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

echo "3) www trỏ về đâu"
cname=$(dig +short "www.$DOMAIN" CNAME)
wwwips=$(dig +short "www.$DOMAIN" A | sort)
case "$cname" in
  pcingame.github.io.) pass "CNAME → pcingame.github.io. (đúng khuyến nghị GitHub)" ;;
  "$DOMAIN.")
    # Trỏ về gốc cũng chạy: nó nối tiếp vào 4 A record của gốc.
    if [ -n "$wwwips" ]; then
      pass "CNAME → $cname rồi ra IP GitHub — chạy được"
    else
      bad "CNAME → $cname nhưng gốc chưa ra IP nào"
    fi ;;
  "") bad "chưa có CNAME cho www (bước 3)" ;;
  *) bad "đang trỏ $cname — không phải GitHub Pages" ;;
esac

echo "4) Trang web trả về gì"
# --resolve: đi thẳng vào IP lấy từ DNS công cộng, khỏi phụ thuộc resolver máy
# (nó cache cả câu trả lời rỗng cũ và làm curl báo "không phân giải được").
ip=$(dig +short "$DOMAIN" A | head -1)
if [ -z "$ip" ]; then
  bad "chưa có IP để thử"
else
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 15 \
    --resolve "$DOMAIN:443:$ip" "https://$DOMAIN")
  [ -z "$code" ] && code=000
  case "$code" in
    200) pass "https://$DOMAIN trả 200 — trang sống, chứng chỉ hợp lệ" ;;
    000) bad "HTTPS lỗi (chứng chỉ chưa cấp xong?)" ;;
    *)   bad "HTTP $code — GitHub Pages chưa nhận custom domain (bước 5)" ;;
  esac

  # www PHẢI có trong chứng chỉ, nếu không người gõ www sẽ gặp cảnh báo bảo mật.
  wcode=$(curl -s -o /dev/null -w '%{http_code}' -m 15 \
    --resolve "www.$DOMAIN:443:$ip" "https://www.$DOMAIN")
  [ -z "$wcode" ] && wcode=000
  if [ "$wcode" = "000" ]; then
    bad "https://www.$DOMAIN lỗi chứng chỉ — đổi CNAME www thành pcingame.github.io. (xem DOMAIN_TODO.md)"
  else
    pass "https://www.$DOMAIN trả $wcode"
  fi
fi

echo "5) Email forwarding support@$DOMAIN"
if dig +short "$DOMAIN" MX | grep -q .; then
  pass "có MX record: $(dig +short "$DOMAIN" MX | tr '\n' ' ')"
else
  bad "chưa có MX — mail tới support@$DOMAIN sẽ bounce (bước 4)"
fi

echo
echo "Xong: $ok đạt, $fail chưa. Chi tiết từng bước: DOMAIN_TODO.md"
[ "$fail" -eq 0 ]
