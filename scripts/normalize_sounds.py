"""Evens out the loudness of every animal sound.

Usage (from the project root, needs ffmpeg on PATH):
    python scripts/normalize_sounds.py

Each file in assets/animal_sounds is re-encoded to 44.1 kHz MP3 (channels unchanged) at about
-16 LUFS with peaks limited to -1 dBFS, so no animal is far louder or quieter
than the next one. Files already within 2.5 LU of the target are left untouched.
"""
import pathlib
import re
import subprocess
import tempfile

SOUNDS = pathlib.Path(__file__).resolve().parents[1] / "assets" / "animal_sounds"
TARGET = -16.0
# Files this close to the target are left alone, so running the script again
# never re-encodes (and slowly degrades) a sound that is already fine.
TOLERANCE = 2.5


def loudness(path: pathlib.Path) -> float:
    out = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", str(path),
         "-af", "ebur128", "-f", "null", "-"],
        capture_output=True, text=True).stderr
    return float(re.findall(r"I:\s+(-?[\d.]+) LUFS", out)[-1])


def main() -> None:
    for path in sorted(SOUNDS.glob("*.mp3")):
        before = loudness(path)
        gain = TARGET - before
        if abs(gain) < TOLERANCE:
            print(f"{path.name:16} {before:6.1f} LUFS  kept")
            continue
        with tempfile.TemporaryDirectory() as tmp:
            out = pathlib.Path(tmp) / path.name
            subprocess.run(
                ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                 "-i", str(path),
                 "-af", f"volume={gain:.2f}dB,alimiter=limit=0.89:level=false",
                 "-ar", "44100", "-codec:a", "libmp3lame",
                 "-b:a", "128k", str(out)],
                check=True)
            after = loudness(out)
            path.write_bytes(out.read_bytes())
        print(f"{path.name:16} {before:6.1f} -> {after:6.1f} LUFS")


if __name__ == "__main__":
    main()
