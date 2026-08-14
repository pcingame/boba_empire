"""Vẽ app icon Boba Empire bằng Pillow (không cần SVG renderer / API key).
Xuất: app_icon.png (master, có nền) + app_icon_foreground.png (trong suốt).
Render ở 4x rồi thu nhỏ để cạnh mượt (anti-alias)."""
import os
from PIL import Image, ImageDraw

SS = 4
U = 1024
T = U * SS

def px(v):
    return int(round(v * SS))

def vgrad(w, h, top, bot):
    """Ảnh gradient dọc top->bot."""
    base = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / max(1, h - 1)
        base.putpixel((0, y), tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)))
    return base.resize((w, h))

# ---- palette ----
BG_TOP = (0xB0, 0x72, 0x40)
BG_BOT = (0x6B, 0x3D, 0x1B)
LID = (0xFF, 0xF3, 0xE0)
LID_RIM = (0xE7, 0xD3, 0xB0)
TEA_TOP = (0xE3, 0xAC, 0x6E)
TEA_BOT = (0xB6, 0x79, 0x3B)
PEARL = (0x2A, 0x17, 0x10)
STRAW = (0xF0, 0x8A, 0x6E)
STRAW_HI = (0xF9, 0xBA, 0xAB)
FACE = (0x3A, 0x24, 0x1A)
BLUSH = (0xEC, 0x90, 0x78)


def build_cup():
    """Vẽ cốc (lid + body + straw + pearls + mặt cười) trên nền trong suốt,
    trả về ảnh đã crop sát nội dung."""
    img = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # --- straw (vẽ riêng rồi xoay 14°) ---
    straw = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    ds = ImageDraw.Draw(straw)
    ds.rounded_rectangle([px(486), px(150), px(538), px(610)], radius=px(26), fill=STRAW)
    ds.rounded_rectangle([px(497), px(165), px(512), px(600)], radius=px(8), fill=STRAW_HI)
    straw = straw.rotate(-14, resample=Image.BICUBIC, center=(px(512), px(430)))
    img.alpha_composite(straw)

    # --- lid (nắp cốc, rộng hơn thân) ---
    d.rounded_rectangle([px(334), px(300), px(690), px(398)], radius=px(34), fill=LID)
    d.rounded_rectangle([px(334), px(372), px(690), px(398)], radius=px(14), fill=LID_RIM)

    # --- body (thân cốc, bo góc) với gradient trà sữa ---
    bx0, by0, bx1, by1 = px(372), px(398), px(652), px(792)
    body_mask = Image.new("L", (T, T), 0)
    ImageDraw.Draw(body_mask).rounded_rectangle([bx0, by0, bx1, by1], radius=px(48), fill=255)
    grad = vgrad(bx1 - bx0, by1 - by0, TEA_TOP, TEA_BOT).convert("RGBA")
    tea = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    tea.paste(grad, (bx0, by0))
    img.paste(tea, (0, 0), body_mask)

    # highlight sáng bên trái thân
    d.rounded_rectangle([px(392), px(430), px(414), px(720)], radius=px(11),
                        fill=(255, 255, 255, 55))

    # --- pearls (trân châu) đáy cốc ---
    pr = px(30)
    rows = [(px(700), [px(430), px(492), px(554), px(616)]),
            (px(748), [px(460), px(524), px(588)])]
    for cy, xs in rows:
        for cx in xs:
            d.ellipse([cx - pr, cy - pr, cx + pr, cy + pr], fill=PEARL)

    # --- mặt cười kawaii ---
    er = px(16)
    for ex in (px(474), px(550)):
        d.ellipse([ex - er, px(560) - er, ex + er, px(560) + er], fill=FACE)
    d.arc([px(478), px(568), px(546), px(624)], start=15, end=165, fill=FACE, width=px(9))
    for bx in (px(452), px(572)):
        d.ellipse([bx - px(14), px(595) - px(9), bx + px(14), px(595) + px(9)],
                  fill=BLUSH + (150,))

    return img.crop(img.getbbox())


def compose(cup, with_bg, cup_frac, cy_frac=0.5, bg=None):
    canvas = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    if with_bg:
        top, bot = bg
        mask = Image.new("L", (T, T), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, T - 1, T - 1], radius=px(210), fill=255)
        grad = vgrad(T, T, top, bot).convert("RGBA")
        canvas.paste(grad, (0, 0), mask)

    target_h = int(cup_frac * T)
    scale = target_h / cup.height
    cw, ch = int(cup.width * scale), target_h
    c = cup.resize((cw, ch), Image.LANCZOS)
    canvas.alpha_composite(c, (int((T - cw) / 2), int(cy_frac * T - ch / 2)))
    return canvas.resize((U, U), Image.LANCZOS)


out = r"D:\Code\boba_empire\boba_empire\assets\icon"
os.makedirs(out, exist_ok=True)
cup = build_cup()

CREAM_TOP = (0xF6, 0xE4, 0xCB)
CREAM_BOT = (0xE9, 0xC9, 0xA2)

# Master (iOS + legacy Android): nền kem bo góc + cốc.
master = compose(cup, True, 0.66, 0.52, bg=(CREAM_TOP, CREAM_BOT))
master.convert("RGB").save(os.path.join(out, "app_icon.png"))

# Adaptive background: nền kem FULL-BLEED (không bo góc — hệ thống tự mask).
bg_full = vgrad(U, U, CREAM_TOP, CREAM_BOT)
bg_full.save(os.path.join(out, "app_icon_bg.png"))

# Adaptive foreground: chỉ cốc, trong suốt, trong vùng an toàn.
fg = compose(cup, False, 0.60, 0.50)
fg.save(os.path.join(out, "app_icon_foreground.png"))

print("saved:", sorted(os.listdir(out)))
