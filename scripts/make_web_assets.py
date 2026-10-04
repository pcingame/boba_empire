#!/usr/bin/env python3
"""Tạo lại ảnh cho landing page (docs/assets) từ ảnh store.

Chạy từ gốc repo:  python3 scripts/make_web_assets.py
Cần Pillow (pip3 install pillow). Idempotent — ghi đè file cũ.

Sinh ra:
- docs/assets/{vi,en,es,id,pt,th}/<tên>.webp  (560px rộng, từ assets/store/screenshots_ios/6.9in)
- docs/assets/apple-touch-icon.png (180) và favicon.png (64) từ docs/assets/icon-256.png
- docs/assets/og.jpg (1200x630) cho Open Graph / Twitter card
Tiếng Hàn (ko) KHÔNG có thư mục riêng: trang dùng bộ ảnh en (xem index.html).
"""
import os
from PIL import Image, ImageDraw, ImageFont

SRC = 'assets/store/screenshots_ios/6.9in'
OUT = 'docs/assets'
NAMES = ['01_home', '02_collection', '03_market', '04_daily_quests',
         '05_wheel', '06_pearls_play', '08_prestige', '09_achievements']
LANGS = ['vi', 'en', 'es', 'id', 'pt', 'th']


def shots():
    for lang in LANGS:
        os.makedirs(f'{OUT}/{lang}', exist_ok=True)
        for n in NAMES:
            im = Image.open(f'{SRC}/{lang}/{n}.png').convert('RGB')
            w = 560
            h = round(im.height * w / im.width)
            im.resize((w, h), Image.LANCZOS).save(
                f'{OUT}/{lang}/{n}.webp', 'WEBP', quality=80, method=6)


def icons():
    ic = Image.open(f'{OUT}/icon-256.png').convert('RGBA')
    ic.resize((180, 180), Image.LANCZOS).save(f'{OUT}/apple-touch-icon.png')
    ic.resize((64, 64), Image.LANCZOS).save(f'{OUT}/favicon.png')
    return ic


def og(ic):
    bg = Image.new('RGB', (1200, 630), (253, 243, 220))
    d = ImageDraw.Draw(bg)
    for y in range(630):  # nền gradient nhẹ
        t = y / 630
        d.line([(0, y), (1200, y)],
               fill=(int(253 - 12 * t), int(243 - 30 * t), int(220 - 50 * t)))
    icon = ic.resize((200, 200), Image.LANCZOS)
    bg.paste(icon, (90, 120), icon)
    try:
        f1 = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf', 84)
        f2 = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 34)
    except OSError:
        f1 = f2 = ImageFont.load_default()
    d.text((90, 350), 'Boba Empire', font=f1, fill=(106, 63, 24))
    d.text((92, 455), 'Idle tycoon: tap, upgrade, build your', font=f2, fill=(122, 98, 76))
    d.text((92, 500), 'bubble tea empire.', font=f2, fill=(122, 98, 76))
    for n, x, y in [('01_home', 640, 60), ('02_collection', 860, 120)]:
        s = Image.open(f'{SRC}/en/{n}.png').convert('RGB')
        w = 250
        h = round(s.height * w / s.width)
        s = s.resize((w, h), Image.LANCZOS)
        m = Image.new('L', s.size, 0)
        ImageDraw.Draw(m).rounded_rectangle([0, 0, w, h], radius=28, fill=255)
        bg.paste(s, (x, y), m)
    bg.save(f'{OUT}/og.jpg', 'JPEG', quality=86)


if __name__ == '__main__':
    shots()
    og(icons())
    print('xong: docs/assets đã được làm mới')
