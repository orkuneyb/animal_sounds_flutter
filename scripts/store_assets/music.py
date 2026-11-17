"""Makes the soft background music of the promo video.

Usage (from the project root, inside the build/venv environment):
    python scripts/store_assets/music.py [seconds]

Writes build/store_assets/music.wav (48 kHz, stereo). The tune is computed
here from scratch, so nobody else holds rights in it: a gentle marimba line
over plucked ukulele-like chords (C, G, A minor, F), a round bass and a very
quiet shaker, at 92 beats a minute. Everything is kept below about 2 kHz in
its main energy so it stays easy on the ear under the animal sounds.
"""
import pathlib
import sys
import wave

import numpy as np
from scipy import signal

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "store_assets" / "music.wav"
RATE = 48000
BEAT = 60 / 92
NOTE = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
# One bar each: chord tones for the strum, bass note, marimba line in eighth notes ("-" = rest).
BARS = [
    (["C4", "E4", "G4", "C5"], "C2", ["E5", "-", "G5", "C5", "E5", "-", "G5", "-"]),
    (["B3", "D4", "G4", "B4"], "G2", ["D5", "-", "G5", "B4", "D5", "-", "G5", "-"]),
    (["A3", "C4", "E4", "A4"], "A2", ["C5", "-", "E5", "A4", "C5", "-", "E5", "-"]),
    (["A3", "C4", "F4", "A4"], "F2", ["A4", "-", "C5", "F5", "E5", "-", "D5", "-"]),
    (["C4", "E4", "G4", "C5"], "C2", ["E5", "G5", "-", "E5", "C5", "-", "G4", "-"]),
    (["B3", "D4", "G4", "B4"], "G2", ["D5", "G5", "-", "D5", "B4", "-", "G4", "-"]),
    (["A3", "C4", "E4", "A4"], "A2", ["C5", "E5", "-", "C5", "A4", "-", "E5", "-"]),
    (["A3", "C4", "F4", "A4"], "F2", ["F5", "-", "E5", "-", "D5", "-", "C5", "-"]),
]


def hertz(name: str) -> float:
    semitone = NOTE[name[0]] + 12 * (int(name[-1]) + 1)
    return 440.0 * 2 ** ((semitone - 69) / 12)


def marimba(freq: float, seconds: float = 1.1) -> np.ndarray:
    t = np.arange(int(seconds * RATE)) / RATE
    tone = np.sin(2 * np.pi * freq * t) * np.exp(-t * 5.0)
    tone += 0.22 * np.sin(2 * np.pi * freq * 4 * t) * np.exp(-t * 14.0)
    tone *= np.minimum(1, t / 0.006)
    return tone


def pluck(freq: float, seconds: float = 1.6) -> np.ndarray:
    """A plucked nylon string (Karplus-Strong)."""
    length = int(RATE / freq)
    rng = np.random.default_rng(int(freq))
    line = signal.lfilter([0.5, 0.5], [1], rng.uniform(-1, 1, length))
    out = np.empty(int(seconds * RATE))
    for i in range(len(out)):
        out[i] = line[i % length]
        line[i % length] = 0.497 * (line[i % length] + line[(i + 1) % length])
    return out


def bass(freq: float, seconds: float) -> np.ndarray:
    t = np.arange(int(seconds * RATE)) / RATE
    return np.sin(2 * np.pi * freq * t) * np.minimum(1, t / 0.02) * np.exp(-t * 1.6)


def shaker(seconds: float = 0.09) -> np.ndarray:
    rng = np.random.default_rng(7)
    noise = rng.normal(size=int(seconds * RATE))
    b, a = signal.butter(2, [3000, 7000], btype="band", fs=RATE)
    t = np.arange(len(noise)) / RATE
    return signal.lfilter(b, a, noise) * np.exp(-t * 60)


def add(track: np.ndarray, sound: np.ndarray, at: float, gain: float) -> None:
    start = int(at * RATE)
    end = min(len(track), start + len(sound))
    if start < len(track):
        track[start:end] += gain * sound[:end - start]


def main() -> int:
    seconds = float(sys.argv[1]) if len(sys.argv) > 1 else 36.0
    left, right = np.zeros(int(seconds * RATE)), np.zeros(int(seconds * RATE))
    bar = 4 * BEAT
    cache = {}
    for index in range(int(seconds / bar) + 1):
        chord, low, line = BARS[index % len(BARS)]
        start = index * bar
        quiet_intro = index == 0
        for beat in (0, 2):
            for track in (left, right):
                add(track, bass(hertz(low), 2 * BEAT), start + beat * BEAT, 0.30)
        for beat, strength in ((1, 0.11), (3, 0.09)):
            for k, name in enumerate(chord):
                sound = cache.setdefault(name, pluck(hertz(name)))
                add(left, sound, start + beat * BEAT + k * 0.018, strength * 1.15)
                add(right, sound, start + beat * BEAT + k * 0.018, strength * 0.85)
        if not quiet_intro:
            for step, name in enumerate(line):
                if name == "-":
                    continue
                sound = cache.setdefault("m" + name, marimba(hertz(name)))
                add(left, sound, start + step * BEAT / 2, 0.20)
                add(right, sound, start + step * BEAT / 2, 0.26)
        for step in (1, 3, 5, 7):
            for track in (left, right):
                add(track, shaker(), start + step * BEAT / 2, 0.035)
    mix = np.stack([left, right], axis=1)
    b, a = signal.butter(2, 6500, btype="low", fs=RATE)
    mix = signal.lfilter(b, a, mix, axis=0)
    t = np.arange(len(mix)) / RATE
    mix *= (np.minimum(1, t / 0.4) * np.minimum(1, (seconds - t) / 2.5))[:, None]
    mix *= 0.6 / np.abs(mix).max()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "wb") as file:
        file.setnchannels(2)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes((mix * 32767).astype("<i2").tobytes())
    print("wrote", OUT.relative_to(ROOT), f"{seconds:.1f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
