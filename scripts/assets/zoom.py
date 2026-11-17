"""Puts cut-out animals side by side at full size for a close look.

Usage (from the project root, inside the build/venv environment):
    python scripts/assets/zoom.py out.png s05_p01 s05_p02 ...

Each argument after the output path is the start of a file name in
docs/animal-art/cut. The animals are drawn at 512x512, four per row, on a
mid-grey background that shows both light and dark fringes.
"""
import pathlib
import sys

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[2]
CUT = ROOT / "docs" / "animal-art" / "cut"
PER_ROW = 4


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    files = []
    for prefix in sys.argv[2:]:
        found = sorted(CUT.glob(prefix + "*.png"))
        if not found:
            print("not found:", prefix)
            return 1
        files.append(found[0])
    rows = (len(files) + PER_ROW - 1) // PER_ROW
    sheet = Image.new("RGB", (PER_ROW * 512, rows * 512), "#6E7F8D")
    draw = ImageDraw.Draw(sheet)
    for i, path in enumerate(files):
        picture = Image.open(path).convert("RGBA")
        x, y = (i % PER_ROW) * 512, (i // PER_ROW) * 512
        sheet.paste(picture, (x, y), picture)
        draw.text((x + 8, y + 6), path.stem, fill="white")
    sheet.save(sys.argv[1])
    return 0


if __name__ == "__main__":
    sys.exit(main())
