"""Vẽ Feature Graphic 1024x500 cho Google Play (banner đầu trang listing).
Tái dùng cốc trà sữa từ make_icon.py. Render 2x rồi thu nhỏ cho nét chữ + cạnh.
Chạy: python scripts/make_feature.py"""
import os
from PIL import Image, ImageDraw, ImageFont
import make_icon as mi

FSS = 2
W, H = 1024, 500
CW, CH = W * FSS, H * FSS

BROWN_TOP = (0xA8, 0x6B, 0x3B)
BROWN_BOT = (0x63, 0x38, 0x18)
TITLE = (0xFF, 0xF4, 0xE2)
SUB = (0xF0, 0xD7, 0xB4)
SHADOW = (0x3A, 0x20, 0x0E)


def font(path, size):
    return ImageFont.truetype(rf"C:\Windows\Fonts\{path}", size)


def text_shadow(d, xy, s, f, fill, anchor="lm", dxy=(3 * FSS, 3 * FSS)):
    d.text((xy[0] + dxy[0], xy[1] + dxy[1]), s, font=f, fill=SHADOW + (140,), anchor=anchor)
    d.text(xy, s, font=f, fill=fill, anchor=anchor)


# nền gradient nâu
canvas = mi.vgrad(CW, CH, BROWN_TOP, BROWN_BOT).convert("RGBA")
d = ImageDraw.Draw(canvas)

# bong bóng trang trí (vòng tròn mờ) rải góc
for cx, cy, r, a in [(180, 90, 70, 26), (320, 430, 46, 22), (930, 120, 90, 20),
                     (860, 440, 40, 24), (60, 300, 34, 20), (700, 60, 30, 18)]:
    d.ellipse([(cx - r) * FSS, (cy - r) * FSS, (cx + r) * FSS, (cy + r) * FSS],
              outline=(255, 255, 255, a), width=6 * FSS)

# cốc trà sữa bên phải
cup = mi.build_cup()
cup_h = int(0.84 * CH)
cup = cup.resize((int(cup.width * cup_h / cup.height), cup_h), Image.LANCZOS)
canvas.alpha_composite(cup, (int(0.76 * CW - cup.width / 2), int(0.54 * CH - cup.height / 2)))

# trân châu rải quanh cốc
for cx, cy, r in [(560, 400, 16), (600, 450, 12), (985, 350, 14), (930, 300, 11)]:
    d.ellipse([(cx - r) * FSS, (cy - r) * FSS, (cx + r) * FSS, (cy + r) * FSS], fill=mi.PEARL)

# chữ bên trái
mx = 70 * FSS
text_shadow(d, (mx, 200 * FSS), "Boba Empire", font("seguibl.ttf", 80 * FSS), TITLE, "lm")
text_shadow(d, (mx, 280 * FSS), "Đế Chế Trà Sữa", font("segoeuib.ttf", 42 * FSS), SUB, "lm")
text_shadow(d, (mx, 336 * FSS), "Chạm pha trà · Xây đế chế",
            font("segoeuib.ttf", 27 * FSS), SUB, "lm", dxy=(2 * FSS, 2 * FSS))

out = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "store"))
os.makedirs(out, exist_ok=True)
canvas.convert("RGB").resize((W, H), Image.LANCZOS).save(os.path.join(out, "feature_graphic.png"))
print("saved:", os.path.join(out, "feature_graphic.png"))
