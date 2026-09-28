"""Vẽ 18 cảnh quán trà sữa theo giai đoạn làm backdrop cho vùng chạm. Phong
cách flat cute, cùng tông brand với icon. Mỗi cảnh lấy tông theo màu chủ đề của
giai đoạn đó trong `main.dart` (`_seedForStage`) để nền và giao diện ăn nhau.

Khung RỘNG-THẤP 1080×540 (tỉ lệ 2:1) để khớp vùng hiển thị wide-short trên màn
hình — BoxFit.cover gần như không phải cắt (trước đây ảnh 1080×1000 gần vuông bị
cắt mất nửa trên quán). Nội dung chính giữ trong vùng an toàn giữa khung.

Chạy: python scripts/make_scenes.py  → assets/scene/stage{1..18}.png"""
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

def base(top=None, bot=None):
    """Nền trời + mặt đất. [top]/[bot] đổi màu trời cho các giai đoạn sau
    (đêm, vũ trụ...) — để None thì dùng tông kem mặc định."""
    img = mi.vgrad(CW, CH, top or SKY_TOP, bot or SKY_BOT).convert("RGBA")
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


# --- Bảng màu bổ sung cho giai đoạn 7-18 (bám theo _seedForStage ở main.dart) ---
STEEL=(0x3F,0x7F,0x9E); STEEL_D=(0x2B,0x5A,0x73)
INDIGO=(0x6B,0x6F,0xBF); INDIGO_D=(0x4A,0x4E,0x91)
TEAL=(0x3E,0x9E,0x88); TEAL_D=(0x2A,0x74,0x63)
OLIVE=(0x7C,0x9A,0x2E); OLIVE_D=(0x5B,0x72,0x1E)
ELEC=(0x3B,0x8F,0xD1); ELEC_D=(0x24,0x60,0x92)
AMBER=(0xD1,0x82,0x3B); AMBER_D=(0x9B,0x5C,0x24)
PURPLE=(0x8F,0x5F,0xB5); PURPLE_D=(0x67,0x41,0x86)
NIGHT=(0x5B,0x7F,0xA8); NIGHT_D=(0x2C,0x3E,0x5C)
BRICK=(0xB5,0x54,0x4F); BRICK_D=(0x86,0x3A,0x36)
PEACE=(0x3F,0xA3,0x7D); PEACE_D=(0x2B,0x77,0x59)
OCEAN=(0x4F,0x6F,0xC4); OCEAN_D=(0x36,0x4D,0x91)
TRUTH=(0xE8,0xC9,0x6B); TRUTH_D=(0xB8,0x92,0x2E)
NIGHT_SKY_T=(0x2B,0x35,0x52); NIGHT_SKY_B=(0x53,0x5F,0x82)
SPACE_T=(0x21,0x27,0x47); SPACE_B=(0x3C,0x46,0x77)


def space(top, bot):
    """Nền vũ trụ: KHÔNG có dải đất — cảnh hành tinh/chân lý mà có nền cát
    vàng ở đáy thì rất lạc quẻ."""
    img = mi.vgrad(CW, CH, top, bot).convert("RGBA")
    return img, ImageDraw.Draw(img), 0.80 * H


def tower(d, x0, x1, y0, gy, fill, win=GLASS, rows=3, cols=3, radius=14):
    """Toà nhà chữ nhật + lưới cửa sổ. Dùng lại cho hầu hết cảnh 7-18."""
    d.rounded_rectangle([px(x0),px(y0),px(x1),px(gy)],radius=px(radius),fill=fill)
    if rows and cols:
        wgap=(x1-x0)/(cols+1); hgap=(gy-y0)/(rows+1.4)
        for r in range(rows):
            for c in range(cols):
                cx=x0+wgap*(c+1); cy=y0+hgap*(r+0.8)
                d.rounded_rectangle([px(cx-wgap*0.3),px(cy-hgap*0.26),
                                     px(cx+wgap*0.3),px(cy+hgap*0.26)],
                                    radius=px(5),fill=win)


def globe(d, cx, cy, r, fill, line):
    """Quả địa cầu: tròn + 1 kinh tuyến + 2 vĩ tuyến."""
    d.ellipse([px(cx-r),px(cy-r),px(cx+r),px(cy+r)],fill=fill)
    d.ellipse([px(cx-r*0.42),px(cy-r),px(cx+r*0.42),px(cy+r)],outline=line,width=px(4))
    for f in (-0.42, 0.0, 0.42):
        d.line([(px(cx-r*0.97),px(cy+r*f)),(px(cx+r*0.97),px(cy+r*f))],fill=line,width=px(4))


def uptrend(d, x0, y0, x1, y1, fill):
    """Đường giá đi lên kiểu bảng chứng khoán (gấp khúc)."""
    n=6
    pts=[]
    for i in range(n+1):
        t=i/n
        # đi lên nhưng có nhịp lên xuống cho ra dáng biểu đồ
        wob = (-0.12 if i%2 else 0.06)
        pts.append((x0+(x1-x0)*t, y0+(y1-y0)*(t+wob)))
    for a,b in zip(pts,pts[1:]):
        d.line([(px(a[0]),px(a[1])),(px(b[0]),px(b[1]))],fill=fill,width=px(7))


def stage7():  # Niêm yết sàn chứng khoán — bảng điện tử + đường giá lên
    img,d,gy=base()
    tower(d,120,430,gy-250,gy,STEEL_D,win=STEEL,rows=3,cols=2)
    tower(d,650,960,gy-220,gy,STEEL_D,win=STEEL,rows=2,cols=2)
    bx0,bx1,by0=440,640,gy-300
    d.rounded_rectangle([px(bx0),px(by0),px(bx1),px(gy)],radius=px(16),fill=WALL)
    # Bảng điện tử: đặt hẳn trong khung, mép trên cách đỉnh ảnh >= 20px.
    bd0,bd1,bt,bb=250,900,20,190
    d.rounded_rectangle([px(bd0),px(bt),px(bd1),px(bb)],radius=px(14),fill=DARK)
    uptrend(d,bd0+40,bb-40,bd1-40,bt+45,(0x6F,0xE0,0x9A))
    for i,h in enumerate((26,44,18,52,34)):
        x=bd0+40+i*26
        d.rectangle([px(x),px(bb-24-h),px(x+14),px(bb-24)],fill=STEEL)
    return img

def stage8():  # Tập đoàn đa ngành — nhiều khối cao thấp so le
    img,d,gy=base()
    blocks=[(90,260,200),(270,420,300),(430,600,250),(610,790,340),(800,980,230)]
    for i,(x0,x1,h) in enumerate(blocks):
        f = INDIGO if i%2 else INDIGO_D
        tower(d,x0,x1,gy-h,gy,f,win=WALL,rows=max(2,h//110),cols=2)
    d.rounded_rectangle([px(610),px(gy-390),px(790),px(gy-340)],radius=px(10),fill=GOLD)
    return img

def stage9():  # Quỹ đầu tư toàn cầu — trụ sở + quả địa cầu
    img,d,gy=base()
    tower(d,110,380,gy-230,gy,TEAL_D,win=TEAL,rows=2,cols=2)
    tower(d,700,970,gy-230,gy,TEAL_D,win=TEAL,rows=2,cols=2)
    d.rounded_rectangle([px(410),px(gy-190),px(670),px(gy)],radius=px(16),fill=WALL)
    d.rounded_rectangle([px(396),px(gy-214),px(684),px(gy-182)],radius=px(10),fill=TEAL_D)
    globe(d,540,gy-310,96,TEAL,WALL)  # đáy quả cầu chạm nóc bệ
    return img

def stage10():  # Chuỗi cung ứng nông trại — kho mái dốc + silo + luống cây
    img,d,gy=base()
    d.rectangle([0,px(gy),CW,CH],fill=(0xC9,0xC0,0x84))
    bx0,bx1,by0=250,760,gy-210
    d.rounded_rectangle([px(bx0),px(by0),px(bx1),px(gy)],radius=px(12),fill=(0xC6,0x6B,0x52))
    d.polygon([(px(bx0-34),px(by0)),(px(bx1+34),px(by0)),
               (px(bx1-10),px(by0-88)),(px(bx0+10),px(by0-88))],fill=BROWN_D)
    d.rounded_rectangle([px((bx0+bx1)//2-64),px(gy-120),px((bx0+bx1)//2+64),px(gy)],
                        radius=px(8),fill=WALL)
    for sx in (810,905):  # silo
        d.rounded_rectangle([px(sx-38),px(gy-250),px(sx+38),px(gy)],radius=px(30),fill=WALL_SH)
        d.ellipse([px(sx-38),px(gy-288),px(sx+38),px(gy-212)],fill=OLIVE_D)
    for i in range(7):  # luống cây
        x=70+i*26
        d.ellipse([px(x-14),px(gy-46),px(x+14),px(gy-6)],fill=OLIVE)
    plant(d,200,gy,0.9)
    return img

def stage11():  # Đế chế công nghệ AI — khối tối + mạch phát sáng
    img,d,gy=base(NIGHT_SKY_T,NIGHT_SKY_B)
    tower(d,150,430,gy-300,gy,(0x1E,0x2A,0x3A),win=ELEC,rows=3,cols=2)
    tower(d,650,930,gy-260,gy,(0x1E,0x2A,0x3A),win=ELEC,rows=3,cols=2)
    cx,cy=540,gy-210
    d.rounded_rectangle([px(cx-110),px(cy-70),px(cx+110),px(gy)],radius=px(16),fill=(0x16,0x20,0x2E))
    for dx,dy in [(-70,-130),(0,-170),(70,-130),(-40,-60),(40,-60)]:
        d.ellipse([px(cx+dx-14),px(cy+dy-14),px(cx+dx+14),px(cy+dy+14)],fill=ELEC)
        d.line([(px(cx),px(cy-20)),(px(cx+dx),px(cy+dy))],fill=ELEC_D,width=px(5))
    d.ellipse([px(cx-26),px(cy-46),px(cx+26),px(cy+6)],fill=ELEC)
    return img

def stage12():  # Huyền thoại trà sữa — bệ đá + cúp vàng + tia sáng
    img,d,gy=base()
    for i in range(9):  # tia sáng
        a=-3.14159/2 + (i-4)*0.20
        import math
        d.polygon([(px(540),px(gy-300)),
                   (px(540+math.cos(a)*300-16),px(gy-300+math.sin(a)*300)),
                   (px(540+math.cos(a)*300+16),px(gy-300+math.sin(a)*300))],
                  fill=(0xFF,0xE7,0xB8,110))
    d.rounded_rectangle([px(330),px(gy-70),px(750),px(gy)],radius=px(14),fill=AMBER_D)
    d.rounded_rectangle([px(380),px(gy-110),px(700),px(gy-60)],radius=px(12),fill=AMBER)
    d.rounded_rectangle([px(470),px(gy-260),px(610),px(gy-110)],radius=px(30),fill=GOLD)
    d.ellipse([px(430),px(gy-260),px(500),px(gy-180)],outline=GOLD,width=px(12))
    d.ellipse([px(580),px(gy-260),px(650),px(gy-180)],outline=GOLD,width=px(12))
    star_s(d,540,gy-310,30,GOLD)
    return img

def stage13():  # Học viện Trà Sữa — cột + fronton tam giác
    img,d,gy=base()
    bx0,bx1,by0=200,880,gy-250
    d.rounded_rectangle([px(bx0),px(by0),px(bx1),px(gy)],radius=px(10),fill=WALL)
    d.polygon([(px(bx0-40),px(by0)),(px(bx1+40),px(by0)),(px(540),px(by0-120))],fill=PURPLE)
    d.rectangle([px(bx0-40),px(by0),px(bx1+40),px(by0+22)],fill=PURPLE_D)
    for i in range(5):  # cột
        cx=bx0+70+i*135
        d.rounded_rectangle([px(cx-22),px(by0+40),px(cx+22),px(gy-30)],radius=px(8),fill=WALL_SH)
    d.rectangle([px(bx0),px(gy-30),px(bx1),px(gy)],fill=PURPLE_D)
    star_s(d,540,by0-62,24,GOLD)
    return img

def stage14():  # Thành phố Trà Sữa — skyline đêm, cửa sổ sáng
    img,d,gy=base(NIGHT_SKY_T,NIGHT_SKY_B)
    for cx,cy,r in [(190,88,34),(880,70,28)]:
        d.ellipse([px(cx-r),px(cy-r),px(cx+r),px(cy+r)],fill=(255,255,255,90))
    blocks=[(40,170,240),(180,300,330),(310,430,260),(440,600,400),
            (610,720,290),(730,860,350),(870,1040,250)]
    for i,(x0,x1,h) in enumerate(blocks):
        tower(d,x0,x1,gy-h,gy,NIGHT_D if i%2 else NIGHT,win=LIGHT,
              rows=max(2,h//100),cols=2)
    return img

def stage15():  # Quốc gia Trà Sữa — toà nhà mái vòm + cờ
    img,d,gy=base()
    bx0,bx1,by0=180,900,gy-210
    d.rounded_rectangle([px(bx0),px(by0),px(bx1),px(gy)],radius=px(12),fill=WALL)
    d.rectangle([px(bx0),px(gy-34),px(bx1),px(gy)],fill=BRICK_D)
    for i in range(6):
        cx=bx0+80+i*112
        d.rounded_rectangle([px(cx-20),px(by0+40),px(cx+20),px(gy-34)],radius=px(8),fill=WALL_SH)
    d.rounded_rectangle([px(420),px(by0-46),px(660),px(by0+6)],radius=px(10),fill=BRICK_D)
    d.pieslice([px(410),px(by0-236),px(670),px(by0-36)],180,360,fill=BRICK)
    d.rounded_rectangle([px(524),px(by0-286),px(556),px(by0-150)],radius=px(8),fill=BRICK_D)
    flag(d,540,by0-286)
    return img

def stage16():  # Liên minh thế giới — địa cầu lớn + vòng cờ
    img,d,gy=base()
    import math
    tower(d,80,300,gy-180,gy,PEACE_D,win=WALL,rows=2,cols=2)
    tower(d,780,1000,gy-180,gy,PEACE_D,win=WALL,rows=2,cols=2)
    globe(d,540,gy-170,px(150)//SS,PEACE,WALL)
    for i in range(7):
        a=math.pi*(0.12+0.13*i)
        fx=540-math.cos(a)*250; fy=gy-170-math.sin(a)*250
        d.rectangle([px(fx-3),px(fy),px(fx+3),px(fy+44)],fill=WOOD_D)
        d.polygon([(px(fx+3),px(fy)),(px(fx+40),px(fy+10)),(px(fx+3),px(fy+22))],
                  fill=GOLD if i%2 else PEACE)
    return img

def stage17():  # Hành tinh Trà Sữa — hành tinh có vành đai + sao
    img,d,gy=space(SPACE_T,SPACE_B)
    import math
    for cx,cy,r in [(140,80,4),(320,140,3),(760,70,4),(980,160,3),(560,60,3)]:
        d.ellipse([px(cx-r),px(cy-r),px(cx+r),px(cy+r)],fill=(255,255,255,220))
    d.ellipse([px(330),px(gy-330),px(750),px(gy+50)],fill=OCEAN)
    d.ellipse([px(400),px(gy-290),px(560),px(gy-170)],fill=OCEAN_D)
    d.ellipse([px(560),px(gy-140),px(700),px(gy-40)],fill=OCEAN_D)
    d.ellipse([px(230),px(gy-220),px(850),px(gy-100)],outline=TRUTH,width=px(14))
    star_s(d,880,gy-320,26,TRUTH)
    return img

def stage18():  # Chân lý Trà Sữa — cổng sáng + ly khổng lồ
    img,d,gy=space(SPACE_T,SPACE_B)
    import math
    for i in range(11):  # hào quang
        a=-math.pi/2+(i-5)*0.17
        d.polygon([(px(540),px(gy-190)),
                   (px(540+math.cos(a)*330-20),px(gy-190+math.sin(a)*330)),
                   (px(540+math.cos(a)*330+20),px(gy-190+math.sin(a)*330))],
                  fill=(0xFF,0xE7,0xB8,90))
    d.ellipse([px(330),px(gy-400),px(750),px(gy+20)],outline=TRUTH,width=px(16))
    cup=[(455,gy-300),(625,gy-300),(600,gy-20),(480,gy-20)]
    d.polygon([(px(x),px(y)) for x,y in cup],fill=WALL)
    d.polygon([(px(470),px(gy-165)),(px(610),px(gy-165)),
               (px(600),px(gy-20)),(px(480),px(gy-20))],fill=BROWN)
    d.rounded_rectangle([px(440),px(gy-322),px(640),px(gy-292)],radius=px(12),fill=TRUTH)
    d.rectangle([px(556),px(gy-392),px(578),px(gy-300)],fill=PINK_D)
    for cx,cy in [(250,120),(830,100),(540,70)]:
        star_s(d,cx,cy,20,TRUTH)
    return img

out=os.path.abspath(os.path.join(os.path.dirname(__file__),"..","assets","scene"))
os.makedirs(out,exist_ok=True)
_all=[stage1,stage2,stage3,stage4,stage5,stage6,stage7,stage8,stage9,
      stage10,stage11,stage12,stage13,stage14,stage15,stage16,stage17,stage18]
for i,fn in enumerate(_all,1):
    name=f"stage{i}"
    fn().convert("RGB").resize((W,H),Image.LANCZOS).save(os.path.join(out,f"{name}.png"))
print("saved:",sorted(os.listdir(out)))
