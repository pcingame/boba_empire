"""Ghép 3 cảnh thành video ~30s có tiếng game thật (assets/audio) khớp thời điểm sự kiện.

python3 build_montage.py  — đọc raw/m.mp4, raw/rec_m.log (giờ bắt đầu quay), raw/drive_m.log (EV|sfx|epoch).
"""
import re, subprocess, os
D = 'raw/'
REC0 = float(open(D + 'rec_m.log').read().split('Recording started')[0].split()[-1]) if False else None
for l in open(D + 'rec_m.log'):
    if 'Recording started' in l:
        REC0 = float(l.split()[0])
SND = '/Users/doanthanhphuong/development/flutter_project/emprire/boba_empire/assets/audio/'
ev = [(m.group(1), int(m.group(2)) / 1000) for m in (re.search(r'EV\|(\w+)\|(\d+)', l) for l in open(D + 'drive_m.log', errors='ignore')) if m]
# (bắt đầu epoch, kết thúc epoch, tốc độ)
SEGS = [(1792173085.0, 1792173093.0, 1.0), (1792173097.6, 1792173112.0, 1.5), (1792173127.0, 1792173144.4, 1.5)]
out_t = 0.0
vf, af = [], []
inputs = ['-i', D + 'm.mp4']
labels = []
n_in = 1
mix_in = []
for i, (a, b, sp) in enumerate(SEGS):
    ss, to = a - REC0, b - REC0
    vf.append(f"[0:v]trim=start={ss:.3f}:end={to:.3f},setpts=(PTS-STARTPTS)/{sp},split[a{i}][b{i}];"
              f"[b{i}]scale=1080:1920,boxblur=30:5[bg{i}];[a{i}]scale=-2:1920[fg{i}];[bg{i}][fg{i}]overlay=(W-w)/2:0,fps=30,format=yuv420p[v{i}]")
    last = {}
    for name, t in ev:
        if a <= t <= b and t - last.get(name, -9) > 0.08:
            last[name] = t
            mix_in.append((name, (out_t + (t - a) / sp)))
    out_t += (b - a) / sp
total = out_t
fc = ';'.join(vf) + ';' + ''.join(f'[v{i}]' for i in range(len(SEGS))) + f"concat=n={len(SEGS)}:v=1:a=0[vout]"
# âm thanh: mỗi sự kiện một input wav + adelay, trộn bằng amix (không chuẩn hoá)
for name, t in mix_in:
    inputs += ['-i', SND + {'tap': 'tap', 'buy': 'buy', 'reward': 'reward', 'unlock': 'unlock', 'vip': 'vip', 'prestige': 'prestige'}[name] + '.wav']
    ms = int(t * 1000)
    af.append(f"[{n_in}:a]volume=0.9,adelay={ms}|{ms}[s{n_in}]")
    labels.append(f'[s{n_in}]')
    n_in += 1
fc += ';' + ';'.join(af) + ';' + ''.join(labels) + f"amix=inputs={len(labels)}:normalize=0,afade=t=out:st={total-0.6:.2f}:d=0.6,apad=whole_dur={total:.2f}[aout]"
open('raw/filter.txt', 'w').write(fc)
subprocess.run(['ffmpeg', '-v', 'error', '-y'] + inputs + ['-filter_complex_script', 'raw/filter.txt', '-map', '[vout]', '-map', '[aout]',
               '-c:v', 'libx264', '-crf', '20', '-preset', 'medium', '-c:a', 'aac', '-b:a', '160k', '-t', f'{total:.2f}', '4_tong_hop_30s.mp4'], check=True)
print('xong', round(total, 1), 's,', len(mix_in), 'tiếng')
