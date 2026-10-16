from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
R='/Users/doanthanhphuong/development/flutter_project/emprire/boba_empire/assets/store/screenshots_ios/6.9in/vi/'
O='./'
F='/Users/doanthanhphuong/development/flutter_project/emprire/boba_empire/assets/fonts/Baloo2.ttf'
def font(s):
    f=ImageFont.truetype(F,s)
    try: f.set_variation_by_axes([800])
    except Exception: pass
    return f
def grad(w,h,c1=(250,236,214),c2=(234,204,166)):
    im=Image.new('RGB',(w,h)); d=ImageDraw.Draw(im)
    for y in range(h):
        t=y/h; d.line([(0,y),(w,y)],fill=tuple(int(c1[i]+(c2[i]-c1[i])*t) for i in range(3)))
    return im
def phone(path,height):
    s=Image.open(path).convert('RGB'); w=int(s.width*height/s.height); s=s.resize((w,height),Image.LANCZOS)
    r=max(12,w//12); m=Image.new('L',s.size,0); ImageDraw.Draw(m).rounded_rectangle([0,0,w-1,height-1],r,fill=255)
    pad=14; out=Image.new('RGBA',(w+2*pad,height+2*pad),(0,0,0,0))
    sh=Image.new('RGBA',out.size,(0,0,0,0)); ImageDraw.Draw(sh).rounded_rectangle([pad,pad+8,pad+w,pad+height+8],r,fill=(60,35,15,90))
    out.alpha_composite(sh.filter(ImageFilter.GaussianBlur(10)))
    fr=Image.new('RGBA',(w+10,height+10),(60,36,22,255)); fm=Image.new('L',fr.size,0); ImageDraw.Draw(fm).rounded_rectangle([0,0,fr.width-1,fr.height-1],r+4,fill=255)
    out.paste(fr,(pad-5,pad-5),fm); out.paste(s,(pad,pad),m); return out
def center(d,text,f,cx,y,fill):
    w=d.textlength(text,font=f); d.text((cx-w/2,y),text,font=f,fill=fill)
BR=(94,56,30)
_i=Image.open('/Users/doanthanhphuong/development/flutter_project/emprire/boba_empire/assets/icon/app_icon.png').convert('RGBA')
_b=Image.new('RGBA',_i.size,(246,228,200,255)); _b.alpha_composite(_i)
_m=Image.new('L',_i.size,0); ImageDraw.Draw(_m).rounded_rectangle([0,0,1023,1023],230,fill=255)
icon=_b.copy(); icon.putalpha(_m)
# avatar 1024 vuông (Facebook tự cắt tròn)
av=grad(1024,1024); ic=icon.resize((900,900),Image.LANCZOS); av.paste(ic,(62,62),ic); av.save(O+'avatar_1024.png')
# bìa 1640x856
W,H=1640,856; c=grad(W,H).convert('RGBA'); d=ImageDraw.Draw(c)
for x,y,r in[(120,120,170),(1000,-40,150),(1500,700,200)]: d.ellipse([x-r,y-r,x+r,y+r],fill=(255,255,255,90))
c.alpha_composite(icon.resize((200,200),Image.LANCZOS),(90,90))
d.text((90,330),'Boba Empire',font=font(120),fill=BR)
d.text((94,470),'Đế Chế Trà Sữa',font=font(64),fill=(170,100,50))
d.text((94,570),'Chạm · Nâng cấp · Pha chế · PK',font=font(40),fill=BR)
d.rounded_rectangle([90,670,560,760],45,fill=BR); d.text((135,688),'Tải trên App Store',font=font(42),fill=(255,244,226))
for i,(n,dy) in enumerate([('01_home.png',70),('06_pearls_play.png',20),('08_prestige.png',90)]):
    p=phone(R+n,640); c.alpha_composite(p,(870+i*250,dy+60))
c.convert('RGB').save(O+'cover_1640x856.png')
# ảnh bài đăng 1080x1350: tiêu đề + 1 điện thoại
posts=[('01_home.png','Mở quán trà sữa\ntừ chiếc xe đẩy nhỏ'),('06_pearls_play.png','Ghép 3 trà sữa\nthử thách mỗi màn'),('08_prestige.png','Nhượng quyền để mạnh hơn\nXây đế chế nghìn tỷ'),('05_wheel.png','Quay thưởng\nsưu tập phụ kiện'),('03_market.png','Chợ phụ kiện\nmua bán, trao đổi'),('04_daily_quests.png','Nhiệm vụ mỗi ngày\nnhận 💎 miễn phí')]
for i,(n,t) in enumerate(posts,1):
    im=grad(1080,1350).convert('RGBA'); dd=ImageDraw.Draw(im)
    for j,l in enumerate(t.replace('💎','').split('\n')): center(dd,l.strip(),font(76),540,60+j*95,BR)
    p=phone(R+n,1000); im.alpha_composite(p,((1080-p.width)//2,300))
    dd.text((40,1290),'Boba Empire',font=font(34),fill=(170,100,50))
    im.convert('RGB').save(O+f'post_{i:02d}.png')
