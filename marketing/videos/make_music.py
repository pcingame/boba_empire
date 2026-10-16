"""Nhạc nền tự soạn (không dính bản quyền): giai điệu pluck vui + bass + trống nhẹ, 104 BPM, ~30s. Chạy: python3 make_music.py"""
import numpy as np, wave
SR = 44100
BPM = 104
beat = 60 / BPM
DUR = 29.2
N = int(SR * DUR)
out = np.zeros(N)

def hz(m): return 440 * 2 ** ((m - 69) / 12)
def env(n, a=0.005, d=0.25):
    t = np.arange(n) / SR
    return np.minimum(t / a, 1) * np.exp(-t / d)
def pluck(m, dur, vol=0.25):
    n = int(SR * dur); t = np.arange(n) / SR
    f = hz(m)
    w = np.sin(2*np.pi*f*t) + 0.4*np.sin(2*np.pi*2*f*t) + 0.15*np.sin(2*np.pi*3*f*t)
    return w * env(n, 0.004, 0.18) * vol
def add(sig, t0):
    i = int(t0 * SR)
    if i >= N: return
    j = min(N, i + len(sig)); out[i:j] += sig[:j-i]

# Am - F - C - G (mỗi hợp âm 4 phách), lặp
chords = [(57, [69, 72, 76]), (53, [65, 69, 72]), (48, [67, 72, 76]), (55, [67, 71, 74])]
scale = [72, 74, 76, 79, 81, 79, 76, 74]  # giai điệu ngũ cung vui
total_beats = int(DUR / beat) + 1
rng = np.random.default_rng(3)
for b in range(total_beats):
    t0 = b * beat
    root, tri = chords[(b // 4) % 4]
    if b % 4 in (0, 2): add(pluck(root - 12, beat*1.6, 0.35), t0)
    for k in range(2):
        add(pluck(tri[(b*2 + k) % 3], beat*0.6, 0.12), t0 + k*beat/2)
    if b >= 8 and b % 2 == 0:
        add(pluck(scale[(b//2 + (b//16)*3) % len(scale)], beat*1.2, 0.2), t0)
    if b % 4 in (0, 2):
        n = int(SR*0.18); t = np.arange(n)/SR
        add(np.sin(2*np.pi*(120*np.exp(-t*18)+45)*t) * np.exp(-t*14) * 0.5, t0)
    for k in range(2):
        n = int(SR*0.05)
        add(rng.standard_normal(n) * np.exp(-np.arange(n)/SR*90) * 0.05, t0 + k*beat/2)
fade_in = np.minimum(np.arange(N)/(SR*0.8), 1)
fade_out = np.minimum((N - np.arange(N))/(SR*1.5), 1)
out *= fade_in * fade_out
out = out / np.max(np.abs(out)) * 0.8
pcm = (out * 32767).astype(np.int16)
with wave.open('nhac_nen.wav', 'wb') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
print('ok')
