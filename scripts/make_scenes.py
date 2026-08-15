"""Vẽ 6 cảnh quán trà sữa theo giai đoạn (Xe đẩy → Kiosk → Chuỗi cafe → Xưởng
nướng → Nhà máy phô mai → Đế chế) làm backdrop cho vùng chạm. Phong cách flat
cute, cùng tông brand với icon.

Khung RỘNG-THẤP 1080×540 (tỉ lệ 2:1) để khớp vùng hiển thị wide-short trên màn
hình — BoxFit.cover gần như không phải cắt (trước đây ảnh 1080×1000 gần vuông bị
cắt mất nửa trên quán). Nội dung chính giữ trong vùng an toàn giữa khung.

Chạy: python scripts/make_scenes.py  → assets/scene/stage{1..6}.png"""
import os
from PIL import Image, ImageDraw
import make_icon as mi

SS = 2
W, H = 1080, 540
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
PINK=(0xF4,0xC2,0xD0); PINK_D=(0xC6,0x5B,0x7C)
GOLD=(0xE7,0xC1,0x54); GOLD_D=(0xB8,0x86,0x0B)

def base():
    img = mi.vgrad(CW, CH, SKY_TOP, SKY_BOT).convert("RGBA")
    d = ImageDraw.Draw(img)
    gy = 0.80 * H  # ground line (design units, chưa nhân SS)
    d.rectangle([0, px(gy), CW, CH], fill=GROUND)
    d.rectangle([0, px(gy), CW, px(gy + 10)], fill=GROUND2)
    return img, d, gy

def awning(d, x0, x1, y, drop, stripes):
    """Mái hiên sọc từ y xuống y+drop."""
    w = (x1 - x0) / stripes
    for i in range(stripes):
        col = AWN if i % 2 == 0 else AWN2
        sx = x0 + i*w
        d.polygon([(px(sx),px(y)),(px(sx+w),px(y)),
                   (px(sx+w*0.7),px(y+drop)),(px(sx+w*0.3),px(y+drop))], fill=col)

def plant(d, cx, base_y, s=1.0):
    pot_w=px(40*s)
    d.rounded_rectangle([px(cx)-pot_w,px(base_y)-px(34*s),px(cx)+pot_w,px(base_y)],
                        radius=px(8), fill=WOOD)
    for dx in (-26,0,26):
        d.ellipse([px(cx+dx)-px(22*s),px(base_y)-px(80*s),
                   px(cx+dx)+px(22*s),px(base_y)-px(30*s)], fill=PLANT)
    d.ellipse([px(cx)-px(17*s),px(base_y)-px(100*s),
               px(cx)+px(17*s),px(base_y)-px(58*s)], fill=PLANT_D)

def lights(d, x0, x1, y):
    n=10
    pts=[(x0+(x1-x0)*i/n, y+18*(1-abs(i/n-0.5)*2)) for i in range(n+1)]  # dây võng
    for a,b in zip(pts, pts[1:]):
        d.line([(px(a[0]),px(a[1])),(px(b[0]),px(b[1]))], fill=WOOD_D, width=px(3))
    for x,yy in pts:
        d.ellipse([px(x)-px(6),px(yy),px(x)+px(6),px(yy)+px(12)], fill=LIGHT)

def steam(d, cx, top):
    """Khói bốc lên trong tầm [top, top+~90] (nhỏ để vừa khung thấp)."""
    for dx,dy,r in [(0,66,18),(14,34,22),(-6,4,26)]:
        d.ellipse([px(cx+dx-r),px(top+dy-r),px(cx+dx+r),px(top+dy+r)],
                  fill=(255,255,255,150))

def flag(d, cx, top_y):
    d.rectangle([px(cx-3),px(top_y),px(cx+3),px(top_y+60)],fill=BROWN_D)
    d.polygon([(px(cx+3),px(top_y)),(px(cx+60),px(top_y+14)),(px(cx+3),px(top_y+30))],fill=PINK_D)

def star_s(d, cx, cy, r, fill):
    import math
    pts=[]
    for i in range(10):
        a=-math.pi/2+i*math.pi/5; rr=r if i%2==0 else r*0.45
        pts.append((px(cx)+px(rr)*math.cos(a),px(cy)+px(rr)*math.sin(a)))
    d.polygon(pts,fill=fill)


def stage1():  # Xe đẩy vỉa hè
    img,d,gy=base()
    for cx,cy,r in [(180,90,45),(232,92,60),(880,120,50)]:
        d.ellipse([px(cx-r),px(cy-r),px(cx+r),px(cy+r)],fill=(255,255,255,120))
    bx0,bx1,by0,by1=270,810,gy-215,gy
    d.rounded_rectangle([px(bx0),px(by0),px(bx1),px(by1)],radius=px(16),fill=WOOD)
    d.rounded_rectangle([px(bx0),px(by0),px(bx1),px(by0+34)],radius=px(10),fill=WOOD_D)
    d.rounded_rectangle([px(bx0+30),px(by0+58),px(bx1-30),px(by1-34)],radius=px(10),fill=WALL)
    for wx in (bx0+70,bx1-70):
        d.ellipse([px(wx-42),px(by1-26),px(wx+42),px(by1+54)],fill=DARK)
        d.ellipse([px(wx-16),px(by1-2),px(wx+16),px(by1+30)],fill=WOOD_D)
    awning(d,bx0-20,bx1+20,by0-84,84,6)
    d.rectangle([px(bx0-14),px(by0-84),px(bx0),px(by0)],fill=WOOD_D)
    d.rectangle([px(bx1),px(by0-84),px(bx1+14),px(by0)],fill=WOOD_D)
    return img

def stage2():  # Kiosk cửa hàng nhỏ
    img,d,gy=base()
    bx0,bx1,by0,by1=210,870,gy-300,gy
    d.rounded_rectangle([px(bx0),px(by0),px(bx1),px(by1)],radius=px(18),fill=WALL)
    d.rectangle([px(bx0),px(by1-46),px(bx1),px(by1)],fill=WALL_SH)
    d.polygon([(px(bx0-30),px(by0)),(px(bx1+30),px(by0)),
               (px(bx1-20),px(by0-70)),(px(bx0+20),px(by0-70))],fill=BROWN)
    d.rectangle([px(bx0-30),px(by0),px(bx1+30),px(by0+16)],fill=BROWN_D)
    gx0,gx1,gy0,gy1=bx0+50,bx1-50,by0+80,by1-110
    d.rounded_rectangle([px(gx0),px(gy0),px(gx1),px(gy1)],radius=px(12),fill=GLASS)
    d.rectangle([px((bx0+bx1)//2-4),px(gy0),px((bx0+bx1)//2+4),px(gy1)],fill=GLASS_D)
    d.rectangle([px(gx0),px((gy0+gy1)//2-4),px(gx1),px((gy0+gy1)//2+4)],fill=GLASS_D)
    d.rounded_rectangle([px(bx0+30),px(by1-110),px(bx1-30),px(by1-66)],radius=px(8),fill=WOOD)
    awning(d,bx0+20,bx1-20,by0+54,70,7)
    plant(d,bx0+26,by1,0.95)
    plant(d,bx1-26,by1,0.95)
    return img

def stage3():  # Chuỗi cafe sang trọng
    img,d,gy=base()
    bx0,bx1,by0,by1=140,940,gy-330,gy
    d.rounded_rectangle([px(bx0),px(by0),px(bx1),px(by1)],radius=px(20),fill=WALL)
    d.rectangle([px(bx0),px(by0+118),px(bx1),px(by0+132)],fill=WALL_SH)
    d.rounded_rectangle([px(bx0-40),px(by0-55),px(bx1+40),px(by0+8)],radius=px(14),fill=BROWN)
    d.rounded_rectangle([px(bx0-40),px(by0-55),px(bx1+40),px(by0-30)],radius=px(10),fill=BROWN_D)
    lights(d,bx0+10,bx1-10,by0+28)
    for gx0,gx1 in [(bx0+50,(bx0+bx1)//2-15),((bx0+bx1)//2+15,bx1-50)]:
        d.rounded_rectangle([px(gx0),px(by0+158),px(gx1),px(by1-50)],radius=px(12),fill=GLASS)
        d.line([(px((gx0+gx1)//2),px(by0+158)),(px((gx0+gx1)//2),px(by1-50))],fill=GLASS_D,width=px(4))
    for wx in (bx0+120,540,bx1-120):
        d.rounded_rectangle([px(wx-52),px(by0+48),px(wx+52),px(by0+116)],radius=px(10),fill=GLASS)
    for tx in (300,780):
        d.ellipse([px(tx-56),px(gy-12),px(tx+56),px(gy+22)],fill=WOOD)
        d.rectangle([px(tx-6),px(gy+16),px(tx+6),px(gy+52)],fill=WOOD_D)
    plant(d,bx0-6,by1,1.0)
    plant(d,bx1+6,by1,1.0)
    return img

def stage4():  # Xưởng trà sữa nướng — nâu ấm + ống khói
    img,d,gy=base()
    bx0,bx1,by0,by1=155,925,gy-250,gy
    d.rounded_rectangle([px(bx0),px(by0),px(bx1),px(by1)],radius=px(18),fill=WALL)
    d.rectangle([px(bx0),px(by1-50),px(bx1),px(by1)],fill=WALL_SH)
    d.polygon([(px(bx0-30),px(by0)),(px(bx1+30),px(by0)),
               (px(bx1-20),px(by0-70)),(px(bx0+20),px(by0-70))],fill=BROWN)
    d.rectangle([px(bx0-30),px(by0),px(bx1+30),px(by0+16)],fill=BROWN_D)
    d.rectangle([px(bx1-150),px(by0-108),px(bx1-108),px(by0-30)],fill=BROWN_D)  # ống khói
    steam(d,bx1-129,by0-108)
    d.rounded_rectangle([px(bx0+56),px(by0+70),px(bx1-56),px(by1-92)],radius=px(12),fill=GLASS)
    d.rounded_rectangle([px((bx0+bx1)//2-88),px(by1-176),px((bx0+bx1)//2+88),px(by1-92)],
                        radius=px(12),fill=(0xF2,0xA6,0x3A))  # lò nướng cam
    awning(d,bx0+40,bx1-40,by0+52,64,8)
    plant(d,bx0+18,by1,1.0); plant(d,bx1-18,by1,1.0)
    return img

def stage5():  # Nhà máy phô mai tươi — hồng + biển hiệu to
    img,d,gy=base()
    bx0,bx1,by0,by1=145,935,gy-330,gy
    d.rounded_rectangle([px(bx0),px(by0),px(bx1),px(by1)],radius=px(20),fill=(0xFF,0xF0,0xF3))
    d.rectangle([px(bx0),px(by0+112),px(bx1),px(by0+126)],fill=PINK)
    d.rounded_rectangle([px(bx0-40),px(by0-64),px(bx1+40),px(by0+6)],radius=px(14),fill=PINK_D)
    d.rounded_rectangle([px(bx0-40),px(by0-64),px(bx1+40),px(by0-40)],radius=px(10),fill=PINK)
    lights(d,bx0+10,bx1-10,by0+30)
    for gx0,gx1 in [(bx0+50,(bx0+bx1)//2-15),((bx0+bx1)//2+15,bx1-50)]:
        d.rounded_rectangle([px(gx0),px(by0+158),px(gx1),px(by1-50)],radius=px(12),fill=GLASS)
    for wx in (bx0+120,540,bx1-120):
        d.rounded_rectangle([px(wx-52),px(by0+48),px(wx+52),px(by0+114)],radius=px(10),fill=GLASS)
    plant(d,bx0-6,by1,1.0); plant(d,bx1+6,by1,1.0)
    return img

def stage6():  # Đế chế toàn cầu — tháp vàng + cờ + sao
    img,d,gy=base()
    for sx0,sx1 in [(110,340),(740,970)]:
        d.rounded_rectangle([px(sx0),px(gy-210),px(sx1),px(gy)],radius=px(14),fill=WALL)
        for r in range(2):
            for c in range(2):
                d.rounded_rectangle([px(sx0+30+c*90),px(gy-178+r*80),px(sx0+90+c*90),px(gy-128+r*80)],
                                    radius=px(6),fill=GLASS)
    tx0,tx1,ty0=390,690,gy-330
    d.rounded_rectangle([px(tx0),px(ty0),px(tx1),px(gy)],radius=px(16),fill=(0xFF,0xF3,0xE0))
    d.rounded_rectangle([px(tx0-16),px(ty0),px(tx1+16),px(ty0+24)],radius=px(8),fill=GOLD_D)
    d.polygon([(px(tx0-16),px(ty0)),(px(tx1+16),px(ty0)),(px((tx0+tx1)//2),px(ty0-54))],fill=GOLD)  # chóp
    flag(d,(tx0+tx1)//2,ty0-90)
    for r in range(3):
        d.rounded_rectangle([px(tx0+36),px(ty0+56+r*84),px(tx1-36),px(ty0+120+r*84)],radius=px(8),fill=GLASS)
    for cx,cy in [(210,84),(900,70),(540,46)]:
        star_s(d,cx,cy,22,GOLD)
    return img

out=os.path.abspath(os.path.join(os.path.dirname(__file__),"..","assets","scene"))
os.makedirs(out,exist_ok=True)
for name,fn in [("stage1",stage1),("stage2",stage2),("stage3",stage3),
                ("stage4",stage4),("stage5",stage5),("stage6",stage6)]:
    fn().convert("RGB").resize((W,H),Image.LANCZOS).save(os.path.join(out,f"{name}.png"))
print("saved:",sorted(os.listdir(out)))
