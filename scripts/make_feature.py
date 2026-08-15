"""Vẽ Feature Graphic 1024x500 cho Google Play — phong cách claymorphism khớp UI
mới: nền kem cozy, cup bóng mềm, chip gem/sao/xu nổi, tiêu đề Fredoka.
Chạy: python scripts/make_feature.py"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import make_icon as mi

FSS = 2
W, H = 1024, 500
CW, CH = W * FSS, H * FSS

def px(v): return int(round(v * FSS))

# palette (kem trà sữa + accent)
BG_TOP = (0xFB, 0xEA, 0xD5)
BG_BOT = (0xF1, 0xD3, 0xB0)
BROWN = (0x6E, 0x3F, 0x1C)
BROWN2 = (0x8D, 0x55, 0x24)
GEM = (0x7F, 0xC7, 0xE8)
GEM_HI = (0xCF, 0xEC, 0xF7)
GOLD = (0xFF, 0xCB, 0x5C)
GOLD_D = (0xF2, 0xA6, 0x3A)
WHITE = (0xFF, 0xFB, 0xF4)

FONT = os.path.join(os.path.dirname(__file__), "..", "assets", "fonts", "Fredoka.ttf")

# Fredoka (variable) THIẾU block Vietnamese precomposed (U+1Exx) — trong app OK
# nhờ fallback Roboto, nhưng PIL không fallback nên chữ có dấu ra ô vuông. Vì vậy:
# tiêu đề "Boba Empire" (không dấu) dùng Fredoka; phần tiếng Việt dùng Segoe UI Bold.
def font(size):
    return ImageFont.truetype(FONT, size)

def font_vi(size):
    return ImageFont.truetype(r"C:\Windows\Fonts\segoeuib.ttf", size)

def soft_shadow(size, draw_fn, blur, alpha=90):
    """Trả layer RGBA có bóng mờ (vẽ shape đen rồi blur)."""
    lay = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    draw_fn(d)
    lay = lay.filter(ImageFilter.GaussianBlur(blur))
    # tăng độ đậm
    r, g, b, a = lay.split()
    a = a.point(lambda v: min(255, int(v * alpha / 60)))
    return Image.merge("RGBA", (r, g, b, a))

def star(d, cx, cy, r, fill):
    import math
    pts = []
    for i in range(10):
        ang = -math.pi / 2 + i * math.pi / 5
        rad = r if i % 2 == 0 else r * 0.45
        pts.append((cx + rad * math.cos(ang), cy + rad * math.sin(ang)))
    d.polygon(pts, fill=fill)

def diamond(d, cx, cy, r, fill, hi):
    d.polygon([(cx, cy - r), (cx + r * 0.8, cy), (cx, cy + r), (cx - r * 0.8, cy)], fill=fill)
    d.polygon([(cx, cy - r), (cx + r * 0.35, cy - r * 0.35), (cx - r * 0.35, cy - r * 0.35)], fill=hi)

def coin(d, cx, cy, r):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GOLD)
    d.ellipse([cx - r * 0.62, cy - r * 0.62, cx + r * 0.62, cy + r * 0.62],
              outline=GOLD_D, width=px(3))

# ---- nền gradient + blob mềm ----
canvas = mi.vgrad(CW, CH, BG_TOP, BG_BOT).convert("RGBA")
d = ImageDraw.Draw(canvas)
for cx, cy, r in [(120, 120, 150), (930, 400, 180), (760, 70, 90)]:
    d.ellipse([px(cx - r), px(cy - r), px(cx + r), px(cy + r)],
              fill=(255, 255, 255, 26))

# ---- cup + bóng mềm (đất sét) ----
cup = mi.build_cup()
cup_h = int(0.82 * CH)
cup = cup.resize((int(cup.width * cup_h / cup.height), cup_h), Image.LANCZOS)
cx = int(0.75 * CW - cup.width / 2)
cy = int(0.52 * CH - cup.height / 2)
# bóng ellipse dưới đáy cup
sh = soft_shadow(
    (CW, CH),
    lambda dd: dd.ellipse(
        [cx + px(20), cy + cup.height - px(40), cx + cup.width - px(20),
         cy + cup.height + px(46)], fill=(0, 0, 0, 120)),
    blur=px(14), alpha=70)
canvas.alpha_composite(sh)
canvas.alpha_composite(cup, (cx, cy))

# ---- chip gem/sao/xu nổi quanh cup ----
def chip(cx_, cy_, r, kind):
    sh = soft_shadow((CW, CH),
        lambda dd: dd.ellipse([px(cx_ - r), px(cy_ - r + 6), px(cx_ + r), px(cy_ + r + 6)],
                              fill=(0, 0, 0, 120)), blur=px(8), alpha=60)
    canvas.alpha_composite(sh)
    d.ellipse([px(cx_ - r), px(cy_ - r), px(cx_ + r), px(cy_ + r)], fill=WHITE)
    if kind == "gem":
        diamond(d, px(cx_), px(cy_), px(r * 0.6), GEM, GEM_HI)
    elif kind == "star":
        star(d, px(cx_), px(cy_), px(r * 0.7), GOLD)
    else:
        coin(d, px(cx_), px(cy_), px(r * 0.66))

chip(605, 150, 38, "gem")
chip(940, 250, 34, "star")
chip(910, 120, 28, "coin")

# ---- chữ ----
def text(x, y, s, f, fill, anchor="lm", shadow=True):
    if shadow:
        d.text((x + px(3), y + px(4)), s, font=f, fill=(0x5A, 0x33, 0x14, 120), anchor=anchor)
    d.text((x, y), s, font=f, fill=fill, anchor=anchor)

mx = px(64)
text(mx, px(190), "Boba Empire", font(px(84)), BROWN, "lm")
text(mx, px(266), "Đế Chế Trà Sữa", font_vi(px(38)), BROWN2, "lm")
text(mx, px(328), "Chạm · Nâng cấp · Xây đế chế", font_vi(px(25)), BROWN2, "lm", shadow=False)

out = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "store"))
os.makedirs(out, exist_ok=True)
canvas.convert("RGB").resize((W, H), Image.LANCZOS).save(os.path.join(out, "feature_graphic.png"))
print("saved:", os.path.join(out, "feature_graphic.png"))
