#!/usr/bin/env python3
"""Generate all audio for Four in a Row with pure synthesis (no external assets).

Tabletop-arcade identity: wooden knocks, chunky button clicks, warm brass-ish
jingles, soft tungsten-lounge music loops. 44.1kHz mono 16-bit WAV.
"""
import math
import os
import wave
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   'assets', 'audio')
os.makedirs(OUT, exist_ok=True)

rng = np.random.default_rng(7)


def env_ad(n, a, d, peak=1.0):
    """Attack/decay envelope over n samples."""
    e = np.ones(n)
    na = max(1, int(a * SR))
    nd = max(1, int(d * SR))
    e[:na] = np.linspace(0, 1, na)
    if nd >= n:
        e *= np.linspace(1, 0, n)
    else:
        e[n - nd:] = np.linspace(1, 0, nd)
    return e * peak


def tone(freq, dur, peak=0.7, attack=0.004, harmonics=(1.0, 0.35, 0.12)):
    n = int(dur * SR)
    t = np.arange(n) / SR
    sig = np.zeros(n)
    for i, h in enumerate(harmonics):
        sig += h * np.sin(2 * math.pi * freq * (i + 1) * t)
    sig *= env_ad(n, attack, dur - attack, peak)
    return sig


def knock(freq, dur=0.14, peak=0.9):
    """Wooden tok: low sine + noise click transient."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    body = np.sin(2 * math.pi * freq * t) * np.exp(-t * 28)
    snap = rng.standard_normal(n) * np.exp(-t * 260) * 0.5
    return (body + snap) * peak


def save(name, sig):
    sig = np.clip(sig, -1, 1)
    sig = (sig * 0.75 * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(sig.tobytes())
    print('wrote', name, f'{len(sig)/SR:.2f}s')


def seq(notes, note_dur, gap=0.0, peak=0.6, harm=(1.0, 0.4, 0.15)):
    """Concatenate tones with slight overlap-free gaps."""
    total = int((note_dur + gap) * len(notes) * SR)
    sig = np.zeros(total)
    for i, f in enumerate(notes):
        t = tone(f, note_dur, peak, harmonics=harm)
        s = int(i * (note_dur + gap) * SR)
        sig[s:s + len(t)] += t
    return sig


# --- SFX -----------------------------------------------------------------
# click: chunky arcade button press
n = int(0.07 * SR)
t = np.arange(n) / SR
click = (rng.standard_normal(n) * np.exp(-t * 220) * 0.9
         + np.sin(2 * math.pi * 2600 * t) * np.exp(-t * 300) * 0.4)
save('click.wav', click)

# drop: disc lands in the chute (wooden tok, pitch drops slightly)
_d1, _d2 = knock(190, 0.16) * 0.9, knock(120, 0.2, 0.4)
_n = max(len(_d1), len(_d2))
save('drop.wav', np.pad(_d1, (0, _n - len(_d1))) + np.pad(_d2, (0, _n - len(_d2))))

# start: warm opening chime
save('start.wav', seq([523.25, 659.25, 783.99], 0.16, 0.03, peak=0.55))

# win: brass-ish rising fanfare
save('win.wav', seq([392.0, 523.25, 659.25, 783.99, 1046.5], 0.18, 0.02, peak=0.6))

# lose: gentle descending phrase (not harsh)
save('lose.wav', seq([440.0, 349.23, 261.63], 0.3, 0.05, peak=0.5,
                     harm=(1.0, 0.25, 0.08)))

# invalid: dull muted thud (column full)
n = int(0.18 * SR)
t = np.arange(n) / SR
invalid = (np.sin(2 * math.pi * 95 * t) * np.exp(-t * 22)
           + rng.standard_normal(n) * np.exp(-t * 90) * 0.25)
save('invalid.wav', invalid * 0.85)


# --- Music loops ----------------------------------------------------------
def pad_chord(freqs, dur, peak=0.28):
    """Soft warm pad: stacked sines with slow attack, loop-safe."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    sig = np.zeros(n)
    for f in freqs:
        sig += (np.sin(2 * math.pi * f * t)
                + 0.4 * np.sin(2 * math.pi * f * 2 * t)
                + 0.15 * np.sin(2 * math.pi * f * 3 * t))
    sig /= max(1, len(freqs))
    a = int(0.4 * SR)
    e = np.ones(n)
    e[:a] = np.linspace(0, 1, a)
    e[-a:] = np.linspace(1, 0, a)  # crossfade-friendly edges
    return sig * e * peak * 4


def music_loop(chords, bar, name, pulse_note=None, pulse_vol=0.0):
    sig = np.concatenate([pad_chord(c, bar) for c in chords])
    if pulse_note:
        n = len(sig)
        t = np.arange(n) / SR
        pulse = np.sin(2 * math.pi * pulse_note * t) * (0.5 + 0.5 * np.sin(2 * math.pi * 0.5 * t)) ** 2
        sig += pulse * pulse_vol
    # loop-safe: crossfade last 0.5s into start
    xf = int(0.5 * SR)
    sig[:xf] = sig[:xf] * np.linspace(0, 1, xf) + sig[-xf:] * np.linspace(1, 0, xf)
    save(name, sig)


C = {  # warm major voicings (Hz)
    'C': [261.63, 329.63, 392.0],
    'G': [196.0, 246.94, 392.0],
    'Am': [220.0, 261.63, 329.63],
    'F': [174.61, 220.0, 349.23],
    'Em': [164.81, 196.0, 329.63],
    'Dm': [146.83, 174.61, 293.66],
}
music_loop([C['C'], C['F'], C['G'], C['C']], 2.4, 'music_menu.wav',
           pulse_note=130.81, pulse_vol=0.10)
music_loop([C['Am'], C['F'], C['C'], C['G'], C['Am'], C['Em'], C['F'], C['G']],
           2.0, 'music_game.wav', pulse_note=98.0, pulse_vol=0.07)
print('done ->', OUT)
