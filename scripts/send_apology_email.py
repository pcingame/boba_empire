"""Gửi mail xin lỗi (crash) + mã quà tặng XINLOI2026 tới danh sách email, qua
Resend API (domain bobaempiregame.com đã verify — xem DOMAIN_TODO.md).

Chỉ dùng stdlib (urllib) — không cần cài gì thêm.

Lấy danh sách email:
  Supabase Dashboard -> SQL Editor -> chạy câu SQL join player_saves đã đưa
  trước đó -> Download CSV -> lưu file (1 cột "email", có/không header đều
  được, script tự bỏ dòng không giống email).

Chạy thử AN TOÀN trước (mặc định KHÔNG gửi thật):
  export RESEND_API_KEY=re_xxx
  python3 scripts/send_apology_email.py emails.csv

Gửi thật, giới hạn 3 người đầu để tự kiểm tra nội dung:
  python3 scripts/send_apology_email.py emails.csv --send --limit 3

Gửi thật cho toàn bộ danh sách:
  python3 scripts/send_apology_email.py emails.csv --send
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request

RESEND_URL = "https://api.resend.com/emails"

# Đổi nếu địa chỉ gửi khác — domain đã verify trên Resend thì gửi được từ bất
# kỳ địa chỉ @bobaempiregame.com nào, không cần verify riêng từng địa chỉ.
FROM_EMAIL = "Đế Chế Trà Sữa <support@bobaempiregame.com>"
SUBJECT = "Đế Chế Trà Sữa — xin lỗi vì mấy lần crash gần đây 🙇"

BODY_TEXT = """\
Chào bạn,

Mình là người làm ra Đế Chế Trà Sữa. Gần đây có vài bạn báo app bị thoát đột \
ngột khi đang chơi — mình xin lỗi vì trải nghiệm không mượt này.

Mình đã lần theo từng báo lỗi và vá xong các nguyên nhân đã tìm ra:
- App thoát khi xem quảng cáo nhận thưởng (Kim Cương, x2 thu nhập, Mưa \
Vàng...) nếu bạn thoát app/đóng hộp thoại đúng lúc quảng cáo đang tải.
- App thoát khi khôi phục save từ đám mây nếu save đó không tương thích với \
bản đang chơi.
- App thoát ở Đấu Trường nếu mất kết nối mạng giữa trận.

Bản vá đã có trong phiên bản mới nhất — bạn cập nhật app trên App \
Store/Play là được, không cần làm gì thêm, save của bạn vẫn an toàn.

Để xin lỗi vì sự bất tiện này, mình gửi tặng bạn 1.000 💎 Kim Cương. Mở app \
-> Cài đặt -> "Nhập mã quà tặng" -> gõ mã bên dưới -> Nhận quà:

    XINLOI2026

Cảm ơn bạn đã kiên nhẫn và tiếp tục đồng hành cùng quán trà sữa của mình 🧋

Thân,
Đế Chế Trà Sữa
"""

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")

# Resend free/starter plan giới hạn ~2 request/giây — nghỉ giữa 2 lần gửi để
# không bị 429. Tăng lên nếu plan trả phí cho phép nhanh hơn.
DELAY_SECONDS = 0.6


def load_emails(csv_path: str) -> list[str]:
    seen: set[str] = set()
    emails: list[str] = []
    with open(csv_path, newline="", encoding="utf-8") as f:
        for row in csv.reader(f):
            for cell in row:
                addr = cell.strip()
                if EMAIL_RE.match(addr) and addr.lower() not in seen:
                    seen.add(addr.lower())
                    emails.append(addr)
    return emails


def send_one(api_key: str, to: str) -> None:
    payload = json.dumps(
        {"from": FROM_EMAIL, "to": [to], "subject": SUBJECT, "text": BODY_TEXT}
    ).encode()
    req = urllib.request.Request(
        RESEND_URL,
        data=payload,
        method="POST",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            # Cloudflare (đứng trước API Resend) chặn thẳng User-Agent mặc
            # định của urllib ("Python-urllib/3.x") bằng 403 "error code:
            # 1010" — không phải lỗi API key. Giả User-Agent trình duyệt để
            # qua được.
            "User-Agent": (
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/605.1.15 (KHTML, like Gecko)"
            ),
        },
    )
    # 429 (rate limit) -> chờ rồi thử lại 1 lần, đủ cho khối lượng nhỏ (vài
    # trăm-nghìn người chơi). Lỗi khác thì ném lên cho vòng lặp ở main() ghi
    # log và đi tiếp, không dừng cả lô vì 1 địa chỉ lỗi.
    for attempt in range(2):
        try:
            urllib.request.urlopen(req, timeout=15)
            return
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt == 0:
                time.sleep(5)
                continue
            raise


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("csv_path", help="File CSV danh sách email (xuất từ Supabase)")
    ap.add_argument(
        "--send", action="store_true", help="Gửi thật (mặc định chỉ dry-run)"
    )
    ap.add_argument(
        "--limit", type=int, default=None, help="Chỉ gửi cho N người đầu (thử nghiệm)"
    )
    args = ap.parse_args()

    api_key = os.environ.get("RESEND_API_KEY")
    if args.send and not api_key:
        sys.exit("Thiếu biến môi trường RESEND_API_KEY (cần khi --send).")

    emails = load_emails(args.csv_path)
    if args.limit:
        emails = emails[: args.limit]

    print(f"Tìm thấy {len(emails)} email hợp lệ trong {args.csv_path}.")
    if not args.send:
        print("DRY-RUN — chưa gửi gì. Thêm --send để gửi thật.")
        for e in emails[:10]:
            print(f"  sẽ gửi -> {e}")
        if len(emails) > 10:
            print(f"  ... và {len(emails) - 10} người nữa")
        return

    ok, failed = 0, []
    for i, addr in enumerate(emails, 1):
        try:
            send_one(api_key, addr)
            ok += 1
            print(f"[{i}/{len(emails)}] gửi OK -> {addr}")
        except Exception as e:  # noqa: BLE001 — ghi log rồi đi tiếp, không dừng lô
            failed.append(addr)
            print(f"[{i}/{len(emails)}] LỖI -> {addr}: {e}")
        time.sleep(DELAY_SECONDS)

    print(f"\nXong: {ok} thành công, {len(failed)} lỗi.")
    if failed:
        fail_path = "send_apology_email_failed.csv"
        with open(fail_path, "w", encoding="utf-8") as f:
            f.write("\n".join(failed))
        print(f"Danh sách lỗi (thử gửi lại sau) đã lưu ở {fail_path}")


if __name__ == "__main__":
    main()
