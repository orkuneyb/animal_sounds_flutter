"""Renders the animal drawings to the PNGs the app ships.

Usage (from the project root):
    python scripts/art/render.py            # every drawing
    python scripts/art/render.py lion goat  # only these
    python scripts/art/render.py --preview  # also writes build/art/sheet.png

Reads  scripts/art/svg/<name>.svg   (viewBox 0 0 100 100, transparent)
Writes assets/animal_images/<name>.png (640x640, transparent)
"""
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SVG = ROOT / "scripts" / "art" / "svg"
OUT = ROOT / "assets" / "animal_images"
TMP = ROOT / "build" / "art"
SIZE = 640
CHROME = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
]


def render(chrome: str, svg: pathlib.Path) -> None:
    TMP.mkdir(parents=True, exist_ok=True)
    page = TMP / f"{svg.stem}.html"
    page.write_text(
        "<!doctype html><style>*{margin:0}html,body{background:transparent}"
        f"svg{{display:block;width:{SIZE}px;height:{SIZE}px}}</style>"
        + svg.read_text(encoding="utf-8"), encoding="utf-8")
    out = OUT / f"{svg.stem}.png"
    subprocess.run(
        [chrome, "--headless=new", "--disable-gpu", "--hide-scrollbars",
         "--force-device-scale-factor=1", f"--window-size={SIZE},{SIZE}",
         "--default-background-color=00000000", f"--screenshot={out}",
         page.resolve().as_uri()],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def sheet(names) -> None:
    from PIL import Image, ImageDraw
    cell, cols = 160, 10
    rows = (len(names) + cols - 1) // cols
    img = Image.new("RGB", (cell * cols, (cell + 18) * rows), "#FFF8EE")
    draw = ImageDraw.Draw(img)
    for i, name in enumerate(names):
        tile = Image.open(OUT / f"{name}.png").convert("RGBA").resize((cell, cell))
        x, y = (i % cols) * cell, (i // cols) * (cell + 18)
        img.paste(tile, (x, y), tile)
        draw.text((x + 6, y + cell + 2), name, fill="#3b2a20")
    TMP.mkdir(parents=True, exist_ok=True)
    img.save(TMP / "sheet.png")
    print("wrote", (TMP / "sheet.png").relative_to(ROOT))


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    chrome = next((c for c in CHROME if pathlib.Path(c).exists()), None)
    if chrome is None:
        print("Chrome or Edge not found", file=sys.stderr)
        return 1
    files = sorted(SVG.glob("*.svg"))
    if args:
        files = [f for f in files if f.stem in args]
    for svg in files:
        render(chrome, svg)
    print("rendered", len(files))
    if "--preview" in sys.argv:
        sheet([f.stem for f in files])
    return 0


if __name__ == "__main__":
    sys.exit(main())
