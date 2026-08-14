"""Vẽ 3 cảnh quán trà sữa theo giai đoạn (Xe đẩy → Kiosk → Chuỗi cafe) làm
backdrop cho vùng chạm. Phong cách flat cute, cùng tông brand với icon.
Chạy: python scripts/make_scenes.py  → assets/scene/stage{1,2,3}.png"""
import os
from PIL import Image, ImageDraw
import make_icon as mi

SS = 2
W, H = 1080, 1000
CW, CH = W * SS, H * SS

def px(v): return int(round(v * SS))

# palette
SKY_TOP=(0xFB,0xEA,0xD5); SKY_BOT=(0xF6,0xDD,0xC0)
GROUND=(0xE7,0xC9,0xA0); GROUND2=(0xD9,0xB4,0x87)
WOOD=(0xA9,0x71,0x3F); WOOD_D=(0x6E,0x44,0x23)
WALL=(0xFF,0xF3,0xE0); WALL_SH=(0xF0,0xDF,0xC4)
BROWN=(0x8D,0x55,0x24); BROWN_D=(0x6E,0x44,0x23)
AWN=(0xE0,0x71,0x5C); AWN2=(0xFB,0xEA,0xD5)
GLASS=(0xBF,0xE3,0xE8); GLASS_D=(0x8F,0xC6,0xCE)
PLANT=(0x6F,0xAE,0x7C); PLANT_D=(0x4F,0x8C,0x5E)
DARK=(0x3A,0x24,0x1A); LIGHT=(0xFF,0xD2,0x7A)

_CUP = mi.build_cup()  # ảnh cup trong suốt để làm biển hiệu

def base():
    img = mi.vgrad(CW, CH, SKY_TOP, SKY_BOT).convert("RGBA")
    d = ImageDraw.Draw(img)
    gy = 0.72 * H  # đơn vị design (chưa nhân SS)
    d.rectangle([0, px(gy), CW, CH], fill=GROUND)
    d.rectangle([0, px(gy), CW, px(gy + 14)], fill=GROUND2)
    return img, d, gy

def sign(img, cx, cy, h):
    """Dán biển hiệu cup nhỏ tại (cx,cy) cao h (px design)."""
    hh = px(h); c = _CUP.resize((int(_CUP.width*hh/_CUP.height), hh), Image.LANCZOS)
    img.alpha_composite(c, (px(cx)-c.width//2, px(cy)-c.height//2))

def awning(d, x0, x1, y, drop, stripes):
    """Mái hiên sọc từ y xuống y+drop."""
    w = (x1 - x0) / stripes
    for i in range(stripes):
        col = AWN if i % 2 == 0 else AWN2
        sx = x0 + i*w
        d.polygon([(px(sx),px(y)),(px(sx+w),px(y)),
                   (px(sx+w*0.7),px(y+drop)),(px(sx+w*0.3),px(y+drop))], fill=col)

def plant(d, cx, base_y, s=1.0):
    pot_w=px(46*s)
    d.rounded_rectangle([px(cx)-pot_w,px(base_y)-px(40*s),px(cx)+pot_w,px(base_y)],
                        radius=px(8), fill=WOOD)
    for dx in (-30,0,30):
        d.ellipse([px(cx+dx)-px(26*s),px(base_y)-px(96*s),
                   px(cx+dx)+px(26*s),px(base_y)-px(36*s)], fill=PLANT)
    d.ellipse([px(cx)-px(20*s),px(base_y)-px(120*s),
               px(cx)+px(20*s),px(base_y)-px(70*s)], fill=PLANT_D)

def lights(d, x0, x1, y):
    n=10
    pts=[(x0+(x1-x0)*i/n, y+22*(1-abs(i/n-0.5)*2)) for i in range(n+1)]  # dây võng
    for a,b in zip(pts, pts[1:]):
        d.line([(px(a[0]),px(a[1])),(px(b[0]),px(b[1]))], fill=WOOD_D, width=px(3))
    for x,yy in pts:
        d.ellipse([px(x)-px(7),px(yy),px(x)+px(7),px(yy)+px(14)], fill=LIGHT)


def stage1():
    img,d,gy=base()
    # đám mây nhẹ
    for cx,cy,r in [(200,150,60),(260,150,80),(880,220,70)]:
        d.ellipse([px(cx-r),px(cy-r),px(cx+r),px(cy+r)],fill=(255,255,255,120))
    # xe đẩy
    bx0,bx1,by0,by1=330,750,gy-260,gy
    d.rounded_rectangle([px(bx0),px(by0),px(bx1),px(by1)],radius=px(16),fill=WOOD)
    d.rounded_rectangle([px(bx0),px(by0),px(bx1),px(by0+40)],radius=px(10),fill=WOOD_D)
    # bảng "counter" sáng
    d.rounded_rectangle([px(bx0+30),px(by0+70),px(bx1-30),px(by1-40)],radius=px(10),fill=WALL)
    # bánh xe
    for wx in (bx0+70,bx1-70):
        d.ellipse([px(wx-46),px(by1-30),px(wx+46),px(by1+62)],fill=DARK)
        d.ellipse([px(wx-18),px(by1-2),px(wx+18),px(by1+34)],fill=WOOD_D)
    # mái hiên
    awning(d,bx0-20,bx1+20,by0-90,90,6)
    # cột đỡ mái
    d.rectangle([px(bx0-14),px(by0-90),px(bx0),px(by0)],fill=WOOD_D)
    d.rectangle([px(bx1),px(by0-90),px(bx1+14),px(by0)],fill=WOOD_D)
    # biển cup treo
    return img

def stage2():
    img,d,gy=base()
    bx0,bx1,by0,by1=250,830,gy-430,gy
    # tường
    d.rounded_rectangle([px(bx0),px(by0),px(bx1),px(by1)],radius=px(18),fill=WALL)
    d.rectangle([px(bx0),px(by1-60),px(bx1),px(by1)],fill=WALL_SH)
    # mái
    d.polygon([(px(bx0-30),px(by0)),(px(bx1+30),px(by0)),
               (px(bx1-20),px(by0-90)),(px(bx0+20),px(by0-90))],fill=BROWN)
    d.rectangle([px(bx0-30),px(by0),px(bx1+30),px(by0+18)],fill=BROWN_D)
    # cửa sổ/counter kính
    d.rounded_rectangle([px(bx0+50),px(by0+90),px(bx1-50),px(by1-150)],radius=px(12),fill=GLASS)
    d.rectangle([px((bx0+bx1)//2-4),px(by0+90),px((bx0+bx1)//2+4),px(by1-150)],fill=GLASS_D)
    d.rectangle([px(bx0+50),px(by0+90+((by1-150)-(by0+90))//2-4),
                 px(bx1-50),px(by0+90+((by1-150)-(by0+90))//2+4)],fill=GLASS_D)
    # counter gỗ
    d.rounded_rectangle([px(bx0+30),px(by1-150),px(bx1-30),px(by1-90)],radius=px(8),fill=WOOD)
    # mái hiên sọc
    awning(d,bx0+20,bx1-20,by0+60,80,7)
    plant(d,bx0+30,by1)
    plant(d,bx1-30,by1)
    return img

def stage3():
    img,d,gy=base()
    bx0,bx1,by0,by1=170,910,gy-500,gy
    # tường 2 tầng
    d.rounded_rectangle([px(bx0),px(by0),px(bx1),px(by1)],radius=px(20),fill=WALL)
    d.rectangle([px(bx0),px(by0+180),px(bx1),px(by0+196)],fill=WALL_SH)
    # mái phẳng sang
    d.rounded_rectangle([px(bx0-40),px(by0-70),px(bx1+40),px(by0+10)],radius=px(14),fill=BROWN)
    d.rounded_rectangle([px(bx0-40),px(by0-70),px(bx1+40),px(by0-40)],radius=px(10),fill=BROWN_D)
    # dàn đèn
    lights(d,bx0+10,bx1-10,by0+40)
    # cửa kính lớn tầng dưới
    for i,(gx0,gx1) in enumerate([(bx0+50,(bx0+bx1)//2-15),((bx0+bx1)//2+15,bx1-50)]):
        d.rounded_rectangle([px(gx0),px(by0+230),px(gx1),px(by1-70)],radius=px(12),fill=GLASS)
        d.line([(px((gx0+gx1)//2),px(by0+230)),(px((gx0+gx1)//2),px(by1-70))],fill=GLASS_D,width=px(4))
    # cửa sổ tầng trên
    for wx in (bx0+120,540,bx1-120):
        d.rounded_rectangle([px(wx-55),px(by0+70),px(wx+55),px(by0+165)],radius=px(10),fill=GLASS)
    # bàn ghế ngoài
    for tx in (300,780):
        d.ellipse([px(tx-60),px(gy-14),px(tx+60),px(gy+26)],fill=WOOD)
        d.rectangle([px(tx-6),px(gy+20),px(tx+6),px(gy+70)],fill=WOOD_D)
    plant(d,bx0-10,by1,1.15)
    plant(d,bx1+10,by1,1.15)
    return img

out=os.path.abspath(os.path.join(os.path.dirname(__file__),"..","assets","scene"))
os.makedirs(out,exist_ok=True)
for name,fn in [("stage1",stage1),("stage2",stage2),("stage3",stage3)]:
    fn().convert("RGB").resize((W,H),Image.LANCZOS).save(os.path.join(out,f"{name}.png"))
print("saved:",sorted(os.listdir(out)))
