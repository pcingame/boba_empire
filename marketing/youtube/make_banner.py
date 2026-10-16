"""Ảnh bìa kênh YouTube 2560x1440. Chữ nằm trong vùng an toàn 1546x423 ở giữa (mọi thiết bị đều thấy). Chạy: python3 make_banner.py"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
ROOT = '../../'
R = ROOT + 'assets/store/screenshots_ios/6.9in/vi/'
F = ROOT + 'assets/fonts/Baloo2.ttf'
BR = (94, 56, 30)
def font(s):
    f = ImageFont.truetype(F, s)
    try: f.set_variation_by_axes([800])
    except Exception: pass
    return f
W, H = 2560, 1440
im = Image.new('RGB', (W, H)); d = ImageDraw.Draw(im)
for y in range(H):
    t = y / H; d.line([(0, y), (W, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip((250, 236, 214), (234, 204, 166))))
im = im.convert('RGBA'); d = ImageDraw.Draw(im, 'RGBA')
for x, y, r in [(250, 250, 330), (2300, 200, 280), (1280, 1500, 420), (2450, 1250, 300)]:
    d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, 80))

def phone(path, height):
    s = Image.open(path).convert('RGB'); w = int(s.width * height / s.height); s = s.resize((w, height), Image.LANCZOS)
    r = w // 12; m = Image.new('L', s.size, 0); ImageDraw.Draw(m).rounded_rectangle([0, 0, w - 1, height - 1], r, fill=255)
    pad = 24; out = Image.new('RGBA', (w + 2 * pad, height + 2 * pad), (0, 0, 0, 0))
    sh = Image.new('RGBA', out.size, (0, 0, 0, 0)); ImageDraw.Draw(sh).rounded_rectangle([pad, pad + 14, pad + w, pad + height + 14], r, fill=(60, 35, 15, 90))
    out.alpha_composite(sh.filter(ImageFilter.GaussianBlur(16)))
    fr = Image.new('RGBA', (w + 16, height + 16), (60, 36, 22, 255)); fm = Image.new('L', fr.size, 0)
    ImageDraw.Draw(fm).rounded_rectangle([0, 0, fr.width - 1, fr.height - 1], r + 6, fill=255)
    out.paste(fr, (pad - 8, pad - 8), fm); out.paste(s, (pad, pad), m); return out

# Mỗi bên một điện thoại, nằm ngoài vùng an toàn (x < 507 hoặc x > 2053), cắt mép dưới cho tràn khung
for name, x, y in [('01_home.png', 10, 300), ('08_prestige.png', 2030, 300)]:
    p = phone(R + name, 1050); im.alpha_composite(p, (x, y))

# Vùng an toàn 1546x423 ở giữa: icon + tên + khẩu hiệu
SX, SY = (W - 1546) // 2, (H - 423) // 2
_i = Image.open(ROOT + 'assets/icon/app_icon.png').convert('RGBA')
_b = Image.new('RGBA', _i.size, (246, 228, 200, 255)); _b.alpha_composite(_i)
_m = Image.new('L', _i.size, 0); ImageDraw.Draw(_m).rounded_rectangle([0, 0, 1023, 1023], 230, fill=255)
icon = _b.copy(); icon.putalpha(_m); icon = icon.resize((300, 300), Image.LANCZOS)
im.alpha_composite(icon, (SX + 10, SY + 61))
d = ImageDraw.Draw(im)
d.text((SX + 350, SY + 20), 'Boba Empire', font=font(190), fill=BR)
d.text((SX + 356, SY + 235), 'Game mở quán trà sữa', font=font(84), fill=(170, 100, 50))
d.text((SX + 356, SY + 335), 'Chạm · Pha chế · PK · Sưu tập', font=font(56), fill=BR)
im.convert('RGB').save('banner_2560x1440.png')
print('ok')
