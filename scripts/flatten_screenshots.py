#!/usr/bin/env python3
"""Bỏ kênh alpha khỏi ảnh chụp (PNG -> RGB). App Store Connect từ chối PNG có
kênh alpha, báo "Your file couldn't be saved". Ảnh chụp bằng integration_test
luôn là RGBA, nên shoot.sh gọi script này sau khi chụp.

    python3 scripts/flatten_screenshots.py assets/store/screenshots/iphone [...]
"""
import glob
import sys

from PIL import Image

n = 0
for d in sys.argv[1:]:
    for f in sorted(glob.glob(f"{d}/**/*.png", recursive=True)):
        im = Image.open(f)
        if im.mode == "RGB":
            continue
        icc = im.info.get("icc_profile")
        rgba = im.convert("RGBA")
        out = Image.new("RGB", rgba.size, (255, 255, 255))
        out.paste(rgba, mask=rgba.getchannel("A"))
        kw = {"icc_profile": icc} if icc else {}
        out.save(f, "PNG", optimize=True, **kw)
        n += 1
print(f"flatten: {n} ảnh")
