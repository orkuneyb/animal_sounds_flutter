"""Draws a spectrogram sheet of original recordings, for choosing the part to use.

Usage (from the project root):
    python scripts/sounds/spectrograms.py out.png bison canary crane ...

Each named animal's original (animal-sound-research/originals/<id>/) is
drawn as one strip, 0-11 kHz, with its length in seconds, so a time on the
strip can be read off as position / width x length. Only reads the files.
"""
import pathlib
import subprocess
import sys

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE = ROOT / "animal-sound-research" / "originals"
WIDTH, HEIGHT = 1500, 200


def main() -> int:
    out, animals = pathlib.Path(sys.argv[1]), sys.argv[2:]
    sheet = Image.new("RGB", (WIDTH, len(animals) * (HEIGHT + 22)), "white")
    draw = ImageDraw.Draw(sheet)
    tmp = out.with_suffix(".strip.png")
    for row, animal in enumerate(animals):
        source = next((BASE / animal).iterdir())
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(source), "-lavfi",
                        f"aformat=channel_layouts=mono,aresample=22050,showspectrumpic=s={WIDTH}x{HEIGHT}:legend=0:scale=log",
                        str(tmp)], check=True)
        probe = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
                                str(source)], capture_output=True, text=True)
        seconds = float(probe.stdout.strip())
        y = row * (HEIGHT + 22)
        sheet.paste(Image.open(tmp).convert("RGB"), (0, y + 20))
        draw.text((4, y + 4), f"{animal}  {seconds:.1f} s  (100 px = {seconds / 15:.2f} s)", fill="black")
        for tick in range(1, 15):
            draw.line([(tick * 100, y + 20), (tick * 100, y + 28)], fill="white")
    tmp.unlink(missing_ok=True)
    sheet.save(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
