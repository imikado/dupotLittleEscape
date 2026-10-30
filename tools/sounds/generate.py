#!/usr/bin/env python3
# Génère les bruitages (sounds/*.wav) et la musique (sounds/music.ogg) par
# synthèse : pas de fichier externe, pas de dépendance (Python 3 seul, ffmpeg
# pour encoder la musique en Ogg Vorbis).
#
# Usage : ./tools/sounds/generate.py [nom...]
#   nom : sons à régénérer (par défaut tous), ex. : door_open music
import math
import os
import random
import struct
import subprocess
import sys
import wave

RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "sounds")

# --- outils --------------------------------------------------------------


def buffer(duration):
    return [0.0] * int(duration * RATE)


def note(name):
    """'C5', 'F#4'... -> fréquence"""
    names = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
    semitone = names[name[0]]
    rest = name[1:]
    if rest.startswith("#"):
        semitone += 1
        rest = rest[1:]
    elif rest.startswith("b"):
        semitone -= 1
        rest = rest[1:]
    midi = 12 * (int(rest) + 1) + semitone
    return 440.0 * 2 ** ((midi - 69) / 12)


def triangle(phase):
    phase = phase % 1.0
    return 4 * phase - 1 if phase < 0.5 else 3 - 4 * phase


def add_tone(buf, start, duration, freq, volume, attack=0.005, decay=None,
             wave_="sine", freq_end=None, partials=((1, 1.0),), vibrato=0.0):
    """ajoute une note : enveloppe attaque linéaire puis décroissance
    exponentielle (decay = temps pour /e) ou plateau puis relâchement"""
    first = int(start * RATE)
    count = int(duration * RATE)
    phase = [0.0] * len(partials)
    for i in range(count):
        index = first + i
        if index >= len(buf):
            break
        t = i / RATE
        f = freq if freq_end is None else freq + (freq_end - freq) * (t / duration)
        if vibrato:
            f *= 1 + vibrato * math.sin(2 * math.pi * 5.5 * t)
        if t < attack:
            env = t / attack
        elif decay is not None:
            env = math.exp(-(t - attack) / decay)
        else:
            env = 1.0
        # relâchement court en fin de note : pas de clic
        tail = duration - t
        if tail < 0.01:
            env *= tail / 0.01
        value = 0.0
        for p, (ratio, amp) in enumerate(partials):
            phase[p] += f * ratio / RATE
            if wave_ == "triangle":
                value += amp * triangle(phase[p])
            else:
                value += amp * math.sin(2 * math.pi * phase[p])
        buf[index] += value * env * volume


def add_noise(buf, start, duration, volume, attack=0.005, decay=None,
              lowpass=1.0, highpass=0.0, rng=None, shape=None):
    """bruit filtré (passe-bas / passe-haut d'ordre 1, coefficients 0..1)"""
    rng = rng or random.Random(1)
    first = int(start * RATE)
    count = int(duration * RATE)
    low = 0.0
    previous = 0.0
    high = 0.0
    for i in range(count):
        index = first + i
        if index >= len(buf):
            break
        t = i / RATE
        if shape:
            env = shape(t / duration)
        elif t < attack:
            env = t / attack
        elif decay is not None:
            env = math.exp(-(t - attack) / decay)
        else:
            env = 1.0
        tail = duration - t
        if tail < 0.01:
            env *= tail / 0.01
        low += lowpass * (rng.uniform(-1, 1) - low)
        high = (1 - highpass) * (high + low - previous) if highpass else low
        previous = low
        buf[index] += high * env * volume


def bell(buf, start, freq, volume, decay=0.35, duration=None):
    """cloche / clochette : partiels inharmoniques"""
    add_tone(buf, start, duration or decay * 4, freq, volume, attack=0.002,
             decay=decay, partials=((1, 1.0), (2.0, 0.35), (2.76, 0.18), (5.4, 0.06)))


def knock(buf, start, freq, volume, decay=0.04):
    """coup sur du bois : sinus grave très court + bruit"""
    add_tone(buf, start, decay * 6, freq, volume, attack=0.001, decay=decay,
             freq_end=freq * 0.7)
    add_noise(buf, start, decay * 3, volume * 0.5, attack=0.001, decay=decay * 0.5,
              lowpass=0.35)


def metal_click(buf, start, volume, freq=2300):
    add_tone(buf, start, 0.06, freq, volume, attack=0.0005, decay=0.008,
             partials=((1, 1.0), (1.47, 0.6), (2.31, 0.3)))
    add_noise(buf, start, 0.03, volume * 0.6, attack=0.0005, decay=0.004,
              lowpass=0.9, highpass=0.6)


def creak(buf, start, duration, volume, rate_from=28, rate_to=55, pitch=700, seed=3):
    """grincement : train d'impulsions de cadence variable dans un résonateur"""
    rng = random.Random(seed)
    t = 0.0
    while t < duration:
        progress = t / duration
        env = math.sin(math.pi * progress) ** 0.7
        rate = rate_from + (rate_to - rate_from) * progress
        add_tone(buf, start + t, 0.02, pitch * (1 + 0.15 * progress) * rng.uniform(0.97, 1.03),
                 volume * env * rng.uniform(0.7, 1.0), attack=0.0008, decay=0.004,
                 partials=((1, 1.0), (2.1, 0.4), (3.3, 0.15)))
        t += 1.0 / rate


def reverb(buf, mix=0.25, room=0.8):
    """réverbération simple (filtres en peigne parallèles)"""
    delays = [int(RATE * d) for d in (0.0297, 0.0371, 0.0411, 0.0437)]
    out = buf[:]
    for delay in delays:
        line = [0.0] * delay
        position = 0
        gain = room * 0.85
        for i, value in enumerate(buf):
            echo = line[position]
            line[position] = value + echo * gain
            position = (position + 1) % delay
            out[i] += echo * mix / len(delays)
    return out


def normalize(buf, peak=0.8):
    top = max(1e-9, max(abs(v) for v in buf))
    return [v * peak / top for v in buf]


def save_wav(name, buf, peak=0.8):
    buf = normalize(buf, peak)
    path = os.path.join(OUT_DIR, name + ".wav")
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v)) * 32767)) for v in buf))
    print(path)


# --- bruitages -----------------------------------------------------------

def click():
    buf = buffer(0.06)
    add_tone(buf, 0, 0.05, 1500, 0.6, attack=0.001, decay=0.008, freq_end=900)
    add_noise(buf, 0, 0.02, 0.2, attack=0.001, decay=0.004, lowpass=0.6)
    return buf, 0.45


def pop():
    buf = buffer(0.14)
    add_tone(buf, 0, 0.12, 380, 0.8, attack=0.003, decay=0.05, freq_end=980)
    return buf, 0.5


def tick():
    buf = buffer(0.05)
    add_tone(buf, 0, 0.04, 2600, 0.5, attack=0.0005, decay=0.006)
    knock(buf, 0, 900, 0.4, decay=0.01)
    return buf, 0.4


def beep():
    buf = buffer(0.09)
    add_tone(buf, 0, 0.08, 1320, 0.5, attack=0.003, wave_="triangle")
    return buf, 0.3


def code_ok():
    buf = buffer(0.9)
    for i, n in enumerate(("C6", "E6", "G6", "C7")):
        bell(buf, i * 0.075, note(n), 0.5, decay=0.18 + i * 0.05)
    return reverb(buf, 0.3), 0.6


def code_wrong():
    buf = buffer(0.45)
    for i, (f, f2) in enumerate(((240, 220), (190, 160))):
        add_tone(buf, i * 0.16, 0.14, f, 0.6, attack=0.005, wave_="triangle", freq_end=f2,
                 partials=((1, 1.0), (2, 0.5), (3, 0.25)))
    return buf, 0.5


def locked():
    buf = buffer(0.35)
    for i, t in enumerate((0.0, 0.07, 0.15)):
        metal_click(buf, t, 0.7 - i * 0.1, freq=2000 + i * 150)
        knock(buf, t, 260, 0.35, decay=0.02)
    return buf, 0.6


def unlock():
    buf = buffer(0.7)
    metal_click(buf, 0.0, 0.5, freq=2600)
    metal_click(buf, 0.12, 0.9, freq=1700)
    knock(buf, 0.12, 300, 0.4, decay=0.02)
    bell(buf, 0.22, note("G6"), 0.25, decay=0.12)
    bell(buf, 0.30, note("C7"), 0.25, decay=0.18)
    return buf, 0.65


def door_open():
    buf = buffer(0.9)
    metal_click(buf, 0.0, 0.5, freq=1800)
    creak(buf, 0.06, 0.6, 0.35, pitch=620)
    add_noise(buf, 0.05, 0.7, 0.25, lowpass=0.05, shape=lambda p: math.sin(math.pi * p))
    return buf, 0.6


def door_close():
    buf = buffer(0.5)
    add_noise(buf, 0, 0.18, 0.2, lowpass=0.05, shape=lambda p: p)
    knock(buf, 0.16, 110, 1.0, decay=0.06)
    metal_click(buf, 0.18, 0.35, freq=2100)
    return reverb(buf, 0.15), 0.7


def drawer_open():
    buf = buffer(0.45)
    add_noise(buf, 0, 0.35, 0.5, lowpass=0.12, highpass=0.02,
              shape=lambda p: math.sin(math.pi * p) * (0.8 + 0.2 * math.sin(p * 60)))
    knock(buf, 0.34, 220, 0.4, decay=0.025)
    return buf, 0.55


def drawer_close():
    buf = buffer(0.45)
    add_noise(buf, 0, 0.25, 0.5, lowpass=0.12, highpass=0.02,
              shape=lambda p: math.sin(math.pi * p) * (0.8 + 0.2 * math.sin(p * 60)))
    knock(buf, 0.24, 160, 1.0, decay=0.04)
    return buf, 0.6


def box_open():
    buf = buffer(0.4)
    metal_click(buf, 0.0, 0.4, freq=2400)
    creak(buf, 0.03, 0.28, 0.3, rate_from=45, rate_to=70, pitch=1100, seed=5)
    return buf, 0.5


def box_close():
    buf = buffer(0.25)
    knock(buf, 0.0, 330, 1.0, decay=0.03)
    metal_click(buf, 0.01, 0.25, freq=2500)
    return buf, 0.55


def pickup():
    buf = buffer(1.2)
    for i, n in enumerate(("G5", "C6", "E6", "G6", "C7")):
        bell(buf, i * 0.06, note(n), 0.45, decay=0.15 + i * 0.04)
    # paillettes
    rng = random.Random(7)
    for i in range(10):
        bell(buf, 0.25 + i * 0.045, rng.uniform(3000, 5200), 0.08, decay=0.04)
    return reverb(buf, 0.35), 0.65


def switch():
    buf = buffer(0.5)
    metal_click(buf, 0.0, 0.5, freq=1900)
    add_tone(buf, 0.05, 0.12, note("E6"), 0.3, attack=0.004, wave_="triangle")
    add_tone(buf, 0.15, 0.22, note("B6"), 0.3, attack=0.004, decay=0.1, wave_="triangle")
    return buf, 0.45


def water():
    buf = buffer(1.4)
    add_noise(buf, 0, 1.4, 0.4, lowpass=0.3, highpass=0.05,
              shape=lambda p: min(1, p * 6) * min(1, (1 - p) * 3))
    rng = random.Random(11)
    for i in range(26):
        t = rng.uniform(0.05, 1.2)
        f = rng.uniform(500, 1400)
        add_tone(buf, t, 0.05, f, 0.12, attack=0.002, decay=0.012, freq_end=f * 1.6)
    return buf, 0.45


def win():
    buf = buffer(3.2)
    melody = (("C5", 0.0), ("E5", 0.14), ("G5", 0.28), ("C6", 0.42), ("G5", 0.7), ("C6", 0.84))
    for n, t in melody:
        bell(buf, t, note(n), 0.5, decay=0.25)
        add_tone(buf, t, 0.3, note(n), 0.25, attack=0.004, decay=0.12, wave_="triangle")
    # accord final
    for n in ("C5", "E5", "G5", "C6", "E6"):
        bell(buf, 1.05, note(n), 0.35, decay=0.7, duration=2.0)
    rng = random.Random(3)
    for i in range(16):
        bell(buf, 1.05 + i * 0.06, rng.uniform(2800, 5000), 0.07, decay=0.05)
    return reverb(buf, 0.4), 0.7


# --- musique -------------------------------------------------------------

BPM = 92
BEAT = 60.0 / BPM
BAR = BEAT * 4
# grille d'accords (2 mesures chacun), jouée deux fois avec une mélodie différente
CHORDS = [
    ("C3", ("C4", "E4", "G4", "B4")),
    ("A2", ("A3", "C4", "E4", "G4")),
    ("F2", ("F3", "A3", "C4", "E4")),
    ("G2", ("G3", "B3", "D4", "F4")),
]
# mélodie : (note, temps de départ en battements dans la grille, durée en battements)
MELODY_A = [("E5", 0, 1.5), ("G5", 1.5, 0.5), ("C6", 2, 2), ("B5", 4, 1), ("G5", 5, 1), ("E5", 6, 2),
            ("C5", 8, 1.5), ("E5", 9.5, 0.5), ("A5", 10, 2), ("G5", 12, 1), ("E5", 13, 1), ("C5", 14, 2),
            ("F5", 16, 1.5), ("A5", 17.5, 0.5), ("C6", 18, 2), ("A5", 20, 1), ("F5", 21, 1), ("E5", 22, 2),
            ("D5", 24, 1.5), ("G5", 25.5, 0.5), ("B5", 26, 2), ("A5", 28, 1), ("G5", 29, 1), ("D5", 30, 2)]
MELODY_B = [("G5", 0, 3), ("E5", 3, 1), ("D5", 4, 2), ("C5", 6, 2),
            ("E5", 8, 3), ("C5", 11, 1), ("A4", 12, 4),
            ("A5", 16, 3), ("G5", 19, 1), ("F5", 20, 2), ("E5", 22, 2),
            ("D5", 24, 2), ("E5", 26, 1), ("F5", 27, 1), ("G5", 28, 4)]
ARPEGGIO = (0, 1, 2, 3, 2, 1, 2, 3)


def music():
    cycle = len(CHORDS) * 2 * BAR
    length = cycle * 2
    tail = 3.0
    buf = buffer(length + tail)
    for loop, melody in enumerate((MELODY_A, MELODY_B)):
        origin = loop * cycle
        for c, (bass, chord) in enumerate(CHORDS):
            start = origin + c * 2 * BAR
            # nappe douce
            for n in chord:
                for detune in (0.997, 1.003):
                    add_tone(buf, start, 2 * BAR, note(n) * detune, 0.035, attack=0.6)
            # basse sur les temps 1 et 3
            for beat in range(0, 8, 2):
                add_tone(buf, start + beat * BEAT, BEAT * 1.8, note(bass), 0.22, attack=0.01,
                         decay=0.5, partials=((1, 1.0), (2, 0.25)))
            # arpège façon kalimba, en croches
            for step in range(16):
                n = chord[ARPEGGIO[step % 8]]
                accent = 1.0 if step % 4 == 0 else 0.7
                add_tone(buf, start + step * BEAT / 2, 0.6, note(n) * 2, 0.07 * accent,
                         attack=0.002, decay=0.12, partials=((1, 1.0), (3, 0.12), (4.1, 0.05)))
        for n, beat, duration in melody:
            t = origin + beat * BEAT
            add_tone(buf, t, duration * BEAT + 0.3, note(n), 0.11, attack=0.02, decay=duration * BEAT * 0.8,
                     wave_="triangle", vibrato=0.004)
            bell(buf, t, note(n), 0.05, decay=0.2)
    buf = reverb(buf, 0.35, room=0.85)
    # boucle sans couture : la queue de réverbération revient au début
    count = int(length * RATE)
    for i in range(count, len(buf)):
        buf[i - count] += buf[i]
    buf = normalize(buf[:count], 0.7)

    wav = os.path.join(OUT_DIR, "music.tmp.wav")
    with wave.open(wav, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(struct.pack("<h", int(v * 32767)) for v in buf))
    ogg = os.path.join(OUT_DIR, "music.ogg")
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", wav, "-c:a", "libvorbis", "-q:a", "4", ogg],
                   check=True)
    os.remove(wav)
    print(ogg)


SOUNDS = {
    "click": click, "pop": pop, "tick": tick, "beep": beep,
    "code_ok": code_ok, "code_wrong": code_wrong, "locked": locked, "unlock": unlock,
    "door_open": door_open, "door_close": door_close, "drawer_open": drawer_open,
    "drawer_close": drawer_close, "box_open": box_open, "box_close": box_close,
    "pickup": pickup, "switch": switch, "water": water, "win": win,
}


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    names = sys.argv[1:] or list(SOUNDS) + ["music"]
    for name in names:
        if name == "music":
            music()
        elif name in SOUNDS:
            buf, peak = SOUNDS[name]()
            save_wav(name, buf, peak)
        else:
            sys.exit("Son inconnu : " + name)


if __name__ == "__main__":
    main()
