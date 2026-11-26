# mix.py <music.wav> <sfx.wav> <seconds> <out.wav>
# Mixes the trailer soundtrack (music) with the captured game SFX, 44.1 kHz stereo s16,
# trims to <seconds>, fades the end out and soft-limits peaks.
import array
import math
import sys
import wave


def read(path):
    w = wave.open(path)
    ch, rate, width, n = w.getnchannels(), w.getframerate(), w.getsampwidth(), w.getnframes()
    assert width == 2, f"{path}: expected 16-bit"
    data = array.array("h", w.readframes(n))
    if ch == 1:
        st = array.array("h", [0]) * (n * 2)
        st[0::2] = data
        st[1::2] = data
        data = st
    return rate, data


music_path, sfx_path, seconds, out_path = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4]
RATE = 44100
m_rate, music = read(music_path)
s_rate, sfx = read(sfx_path)
assert m_rate == RATE, m_rate
n = int(seconds * RATE)

if s_rate != RATE:  # linear resample of the SFX track
    src_frames = len(sfx) // 2
    out = array.array("h", [0]) * (n * 2)
    ratio = s_rate / RATE
    for i in range(n):
        pos = i * ratio
        j = int(pos)
        f = pos - j
        if j + 1 >= src_frames:
            break
        for c in (0, 1):
            out[i * 2 + c] = int(sfx[j * 2 + c] * (1 - f) + sfx[(j + 1) * 2 + c] * f)
    sfx = out

mix = array.array("h", [0]) * (n * 2)
fade_out = 2.6 * RATE
for i in range(n):
    g = 1.0
    if i > n - fade_out:
        g = max(0.0, (n - i) / fade_out)
    for c in (0, 1):
        k = i * 2 + c
        mv = music[k] / 32768.0 if k < len(music) else 0.0
        sv = sfx[k] / 32768.0 if k < len(sfx) else 0.0
        v = (mv * 0.95 + sv * 0.55) * g
        if abs(v) > 0.7:  # soft knee: continuous, slope 1 at 0.7, approaches 1.0
            v = math.copysign(0.7 + 0.3 * math.tanh((abs(v) - 0.7) / 0.3), v)
        mix[k] = int(max(-1.0, min(1.0, v)) * 32767)

w = wave.open(out_path, "wb")
w.setnchannels(2)
w.setsampwidth(2)
w.setframerate(RATE)
w.writeframes(mix.tobytes())
w.close()
print("mixed", out_path, f"{n / RATE:.2f}s", "sfx rate", s_rate)
