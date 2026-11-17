"""Builds Play Store listing images from the raw captures, in every app language.

Usage (from the project root, after capture_test.dart has run for a locale):
    python scripts/store_assets/compose.py            all locales with captures
    python scripts/store_assets/compose.py tr-TR      just these

Reads  build/store_assets/raw/<locale>/*.png and scripts/store_assets/copy.json
Writes docs/store-assets/<locale>/phone_NN.png          (1080x1920)
       docs/store-assets/<locale>/feature_graphic.png   (1024x500)
       docs/store-assets/<locale>/onizleme.jpg          (all of them on one sheet)

The pages are laid out as HTML and photographed with Chrome or Edge. Hindi
and Arabic have no letters in the app font, so the pages name Windows fonts
that do as a fallback; Arabic pages run right to left.
"""
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
RAW = ROOT / "build" / "store_assets" / "raw"
OUT = ROOT / "docs" / "store-assets"
TMP = ROOT / "build" / "store_assets" / "html"
FONTS = ROOT / "assets" / "google_fonts"
IMAGES = ROOT / "assets" / "animal_images"
COPY = json.loads((pathlib.Path(__file__).with_name("copy.json")).read_text(encoding="utf-8"))
FAMILY = "'Nunito','Nirmala UI','Dubai','Segoe UI',sans-serif"

CHROME_CANDIDATES = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
]

# (raw capture, gradient top, gradient bottom, accent, sticker animals: the new ones)
SHOTS = [
    ("01_home", "#FF8A5C", "#FFC46B", "#FFF3D6", ["red_panda", "flamingo"]),
    ("02_sound", "#FFB300", "#FF7A45", "#FFF3D6", ["lemur", "fennec_fox"]),
    ("05_guess", "#2F9BFF", "#6C63FF", "#DDF0FF", ["kiwi", "chimpanzee"]),
    ("04_quiz", "#7B5CFA", "#C45CF0", "#EFE3FF", ["snow_leopard", "chameleon"]),
    ("03_info", "#33B36B", "#128A62", "#DFF7E6", ["polar_bear", "hedgehog"]),
    ("08_daily", "#B06AF2", "#F56FA8", "#F8E1FF", ["orangutan", "butterfly"]),
    ("09_collection", "#18B6A4", "#2F80ED", "#DCF7F3", ["meerkat", "seahorse"]),
    ("06_compare", "#FF7A45", "#F0457A", "#FFE6DA", ["rhinoceros", "hippopotamus"]),
]
# Feature graphic: (animal, left, top, height) on the right half, back row first.
PARADE = [("flamingo", 470, 34, 250), ("polar_bear", 790, 70, 210), ("snow_leopard", 610, 96, 200),
          ("toucan", 880, 236, 200), ("lemur", 500, 250, 210), ("red_panda", 690, 262, 220)]


def uri(path: pathlib.Path) -> str:
    return path.resolve().as_uri()


def font_css() -> str:
    faces = []
    for weight, name in [(600, "SemiBold"), (700, "Bold"), (800, "ExtraBold"), (900, "Black")]:
        faces.append(
            "@font-face{font-family:'Nunito';font-weight:%d;src:url('%s');}"
            % (weight, uri(FONTS / f"Nunito-{name}.ttf"))
        )
    return "".join(faces)


def direction(locale: str) -> str:
    return "rtl" if locale.startswith("ar") else "ltr"


def phone_html(locale: str, raw: pathlib.Path, top: str, bottom: str, accent: str,
               stickers: list, line1: str, line2: str, width: int = 820) -> str:
    long = max(len(line1), len(line2)) > 13
    size = 104 if long else 128
    return f"""<!doctype html><html dir="{direction(locale)}"><head><meta charset="utf-8"><style>
{font_css()}
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:1080px;height:1920px;overflow:hidden}}
body{{font-family:{FAMILY};background:linear-gradient(165deg,{top},{bottom});position:relative}}
.blob{{position:absolute;border-radius:50%;background:rgba(255,255,255,.13)}}
.b1{{width:760px;height:760px;left:-260px;top:-300px}}
.b2{{width:520px;height:520px;right:-190px;top:300px;background:rgba(255,255,255,.09)}}
.b3{{width:900px;height:900px;left:120px;bottom:-520px;background:rgba(0,0,0,.07)}}
.head{{position:absolute;left:30px;right:30px;top:112px;text-align:center;color:#fff;
  text-shadow:0 6px 0 rgba(0,0,0,.13)}}
.l1{{font-weight:900;font-size:{size}px;line-height:1.06;letter-spacing:-2px}}
.l2{{font-weight:800;font-size:{min(84, size - 20)}px;line-height:1.12;color:{accent};margin-top:10px}}
.l2.big{{font-weight:900;font-size:{size}px;line-height:1.06;letter-spacing:-2px;margin-top:0}}
.phone{{position:absolute;left:50%;top:492px;width:{width}px;margin-left:-{width // 2}px;
  padding:22px;border-radius:92px;background:#1c1b22;
  box-shadow:0 40px 90px rgba(0,0,0,.34),inset 0 0 0 3px #3a3944}}
.phone img{{display:block;width:{width - 44}px;border-radius:72px}}
.sticker{{position:absolute;width:270px;height:270px;border-radius:50%;background:#fff;
  box-shadow:0 18px 40px rgba(0,0,0,.24);display:flex;align-items:center;justify-content:center}}
.sticker img{{max-width:216px;max-height:216px}}
.s1{{left:-62px;top:980px;transform:rotate(-9deg)}}
.s2{{right:-62px;top:1420px;transform:rotate(8deg)}}
</style></head><body>
<div class="blob b1"></div><div class="blob b2"></div><div class="blob b3"></div>
<div class="head"><div class="l1">{line1}</div><div class="l2 {'big' if len(line2) <= 11 else ''}">{line2}</div></div>
<div class="phone"><img src="{uri(raw)}"></div>
<div class="sticker s1"><img src="{uri(IMAGES / (stickers[0] + '.png'))}"></div>
<div class="sticker s2"><img src="{uri(IMAGES / (stickers[1] + '.png'))}"></div>
</body></html>"""


def feature_html(locale: str, copy: dict) -> str:
    animals = "".join(
        f'<img class="a" style="left:{left}px;top:{top}px;height:{height}px" src="{uri(IMAGES / (name + ".png"))}">'
        for name, left, top, height in PARADE)
    longest = max(len(word) for word in copy["title"].split())
    size = 50 if longest > 9 else 72 if len(copy["title"]) <= 14 else 58
    return f"""<!doctype html><html dir="{direction(locale)}"><head><meta charset="utf-8"><style>
{font_css()}
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:1024px;height:500px;overflow:hidden}}
body{{font-family:{FAMILY};background:linear-gradient(120deg,#FF7A45 0%,#FFA64D 50%,#FFD86B 100%);position:relative}}
.blob{{position:absolute;border-radius:50%;background:rgba(255,255,255,.16)}}
.b1{{width:520px;height:520px;left:-200px;top:-240px}}
.b2{{width:760px;height:760px;right:-160px;bottom:-470px;background:rgba(255,255,255,.26)}}
.b3{{width:300px;height:300px;right:250px;top:-150px;background:rgba(255,255,255,.14)}}
.txt{{position:absolute;left:52px;top:0;bottom:0;width:410px;display:flex;flex-direction:column;
  justify-content:center;align-items:flex-start;color:#fff;direction:{direction(locale)}}}
.title{{font-weight:900;font-size:{size}px;line-height:1.05;letter-spacing:-1.5px;text-shadow:0 5px 0 rgba(0,0,0,.14)}}
.tag{{font-weight:800;font-size:27px;margin-top:20px;color:#5A2A0C;background:#fff;padding:9px 24px;
  border-radius:999px;box-shadow:0 7px 0 rgba(0,0,0,.1);white-space:nowrap}}
.badge{{font-weight:900;font-size:30px;margin-top:18px;color:#fff;background:#E8463C;padding:8px 24px;
  border-radius:999px;box-shadow:0 7px 0 rgba(0,0,0,.14);white-space:nowrap}}
.a{{position:absolute;filter:drop-shadow(0 14px 14px rgba(90,42,12,.28))}}
.new{{position:absolute;right:26px;top:22px;width:150px;height:150px;border-radius:50%;background:#7B5CFA;
  color:#fff;display:flex;align-items:center;justify-content:center;text-align:center;font-weight:900;
  font-size:{30 if len(copy['ribbon']) <= 9 else 24}px;line-height:1.05;transform:rotate(10deg);
  box-shadow:0 10px 0 rgba(0,0,0,.14);border:6px solid #fff;padding:10px}}
</style></head><body>
<div class="blob b1"></div><div class="blob b2"></div><div class="blob b3"></div>
{animals}
<div class="new">{copy['ribbon']}</div>
<div class="txt"><div class="title">{copy['title']}</div><div class="tag">{copy['tagline']}</div>
<div class="badge">{copy['badge']}</div></div>
</body></html>"""


def render(chrome: str, html: str, name: str, out: pathlib.Path, w: int, h: int) -> None:
    TMP.mkdir(parents=True, exist_ok=True)
    out.parent.mkdir(parents=True, exist_ok=True)
    page = TMP / f"{name}.html"
    page.write_text(html, encoding="utf-8")
    subprocess.run(
        [chrome, "--headless=new", "--disable-gpu", "--hide-scrollbars",
         "--force-device-scale-factor=1", f"--window-size={w},{h}",
         "--virtual-time-budget=4000", f"--screenshot={out}", uri(page)],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    # Play rejects PNGs with an alpha channel on the feature graphic.
    from PIL import Image
    Image.open(out).convert("RGB").save(out, optimize=True)
    print("wrote", out.relative_to(ROOT))


def overview(locale: str) -> None:
    """All eight phone pictures and the feature graphic on one sheet, for a quick look."""
    from PIL import Image
    folder = OUT / locale
    sheet = Image.new("RGB", (8 * 300 + 9 * 10, 533 + 30 + 340), "#15151a")
    for i in range(8):
        shot = Image.open(folder / f"phone_{i + 1:02d}.png").resize((300, 533), Image.LANCZOS)
        sheet.paste(shot, (10 + i * 310, 10))
    feature = Image.open(folder / "feature_graphic.png").resize((676, 330), Image.LANCZOS)
    sheet.paste(feature, (10, 553))
    sheet.save(folder / "onizleme.jpg", quality=88)


def main() -> int:
    chrome = next((c for c in CHROME_CANDIDATES if pathlib.Path(c).exists()), None)
    if chrome is None:
        print("Chrome or Edge not found", file=sys.stderr)
        return 1
    wanted = sys.argv[1:] or list(COPY)
    for locale in wanted:
        copy, raw_dir = COPY[locale], RAW / locale
        if not raw_dir.exists():
            print("skip", locale, "(no captures)")
            continue
        for i, (shot, lines) in enumerate(zip(SHOTS, copy["shots"]), start=1):
            name, top, bottom, accent, stickers = shot
            # The sound screen keeps its play button at the bottom, so that
            # shot shows the whole phone instead of cropping it.
            width = 664 if name == "02_sound" else 820
            html = phone_html(locale, raw_dir / f"{name}.png", top, bottom, accent,
                              stickers, lines[0], lines[1], width)
            render(chrome, html, f"{locale}_{i:02d}",
                   OUT / locale / f"phone_{i:02d}.png", 1080, 1920)
        render(chrome, feature_html(locale, copy),
               f"{locale}_feature", OUT / locale / "feature_graphic.png", 1024, 500)
        overview(locale)
    return 0


if __name__ == "__main__":
    sys.exit(main())
