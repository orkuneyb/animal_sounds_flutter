"""Builds Play Store listing images from the raw captures.

Usage (from the project root, after capture_test.dart has run):
    python scripts/store_assets/compose.py

Reads  build/store_assets/raw/<locale>/*.png
Writes docs/store-assets/<locale>/phone_NN.png   (1080x1920)
       docs/store-assets/<locale>/feature_graphic.png (1024x500)
"""
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
RAW = ROOT / "build" / "store_assets" / "raw"
OUT = ROOT / "docs" / "store-assets"
TMP = ROOT / "build" / "store_assets" / "html"
FONTS = ROOT / "assets" / "google_fonts"
IMAGES = ROOT / "assets" / "animal_images"

CHROME_CANDIDATES = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
]

# (raw capture, gradient top, gradient bottom, accent, sticker animals)
SHOTS = [
    ("01_home", "#FF8A5C", "#FFC46B", "#FFF3D6", ["lion", "elephant"]),
    ("02_sound", "#FFB300", "#FF7A45", "#FFF3D6", ["parrot", "cow"]),
    ("05_guess", "#2F9BFF", "#6C63FF", "#DDF0FF", ["owl", "monkey"]),
    ("04_quiz", "#7B5CFA", "#C45CF0", "#EFE3FF", ["giraffe", "panda"]),
    ("03_info", "#33B36B", "#128A62", "#DFF7E6", ["tiger", "koala"]),
    ("08_daily", "#B06AF2", "#F56FA8", "#F8E1FF", ["whale", "fox"]),
    ("09_collection", "#18B6A4", "#2F80ED", "#DCF7F3", ["squirrel", "frog"]),
    ("06_compare", "#FF7A45", "#F0457A", "#FFE6DA", ["bear", "kangaroo"]),
]

COPY = {
    "en-US": {
        "shots": [
            ("Tap &amp; Hear", "50 cute animals"),
            ("Real Animal", "Sounds"),
            ("Guess the", "Sound!"),
            ("Fun Quizzes", "for little learners"),
            ("Fun Facts", "Read Aloud"),
            ("A New Animal", "Every Day"),
            ("Collect", "Them All"),
            ("Who Is", "Bigger?"),
        ],
        "title": "Animal Sounds",
        "tagline": "Listen · Learn · Play",
    },
    "tr-TR": {
        "shots": [
            ("Dokun ve Dinle", "50 sevimli hayvan"),
            ("Gerçek Hayvan", "Sesleri"),
            ("Sesi", "Tahmin Et!"),
            ("Eğlenceli Quiz", "minik kaşifler için"),
            ("Eğlenceli Bilgiler", "sesli anlatımla"),
            ("Her Gün", "yeni bir hayvan"),
            ("Hepsini", "Topla"),
            ("Hangisi", "Daha Büyük?"),
        ],
        "title": "Hayvan Sesleri",
        "tagline": "Dinle · Öğren · Oyna",
    },
}


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


def phone_html(raw: pathlib.Path, top: str, bottom: str, accent: str,
               stickers: list, line1: str, line2: str, width: int = 820) -> str:
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
{font_css()}
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:1080px;height:1920px;overflow:hidden}}
body{{font-family:'Nunito';background:linear-gradient(165deg,{top},{bottom});position:relative}}
.blob{{position:absolute;border-radius:50%;background:rgba(255,255,255,.13)}}
.b1{{width:760px;height:760px;left:-260px;top:-300px}}
.b2{{width:520px;height:520px;right:-190px;top:300px;background:rgba(255,255,255,.09)}}
.b3{{width:900px;height:900px;left:120px;bottom:-520px;background:rgba(0,0,0,.07)}}
.head{{position:absolute;left:0;right:0;top:112px;text-align:center;color:#fff;
  text-shadow:0 6px 0 rgba(0,0,0,.13)}}
.l1{{font-weight:900;font-size:128px;line-height:1.02;letter-spacing:-2px}}
.l2{{font-weight:800;font-size:84px;line-height:1.1;color:{accent};margin-top:10px}}
.l2.big{{font-weight:900;font-size:128px;line-height:1.02;letter-spacing:-2px;margin-top:0}}
.phone{{position:absolute;left:50%;top:492px;width:{width}px;margin-left:-{width // 2}px;
  padding:22px;border-radius:92px;background:#1c1b22;
  box-shadow:0 40px 90px rgba(0,0,0,.34),inset 0 0 0 3px #3a3944}}
.phone img{{display:block;width:{width - 44}px;border-radius:72px}}
.sticker{{position:absolute;width:250px;height:250px;border-radius:50%;background:#fff;
  box-shadow:0 18px 40px rgba(0,0,0,.24);display:flex;align-items:center;justify-content:center}}
.sticker img{{max-width:182px;max-height:182px}}
.s1{{left:-58px;top:980px;transform:rotate(-9deg)}}
.s2{{right:-58px;top:1420px;transform:rotate(8deg)}}
</style></head><body>
<div class="blob b1"></div><div class="blob b2"></div><div class="blob b3"></div>
<div class="head"><div class="l1">{line1}</div><div class="l2 {'big' if len(line2) <= 11 else ''}">{line2}</div></div>
<div class="phone"><img src="{uri(raw)}"></div>
<div class="sticker s1"><img src="{uri(IMAGES / (stickers[0] + '.png'))}"></div>
<div class="sticker s2"><img src="{uri(IMAGES / (stickers[1] + '.png'))}"></div>
</body></html>"""


def feature_html(title: str, tagline: str) -> str:
    animals = ["elephant", "lion", "dog", "tiger", "giraffe", "owl"]
    tiles = "".join(
        f'<div class="t t{i}"><img src="{uri(IMAGES / (a + ".png"))}"></div>'
        for i, a in enumerate(animals)
    )
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
{font_css()}
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:1024px;height:500px;overflow:hidden}}
body{{font-family:'Nunito';background:linear-gradient(120deg,#FF8A5C 0%,#FFB84D 55%,#FFD86B 100%);position:relative}}
.blob{{position:absolute;border-radius:50%;background:rgba(255,255,255,.16)}}
.b1{{width:520px;height:520px;left:-200px;top:-240px}}
.b2{{width:640px;height:640px;right:-180px;bottom:-380px;background:rgba(255,255,255,.2)}}
.txt{{position:absolute;left:56px;top:132px;color:#fff;text-shadow:0 5px 0 rgba(0,0,0,.14)}}
.title{{font-weight:900;font-size:74px;line-height:1;letter-spacing:-2px}}
.tag{{font-weight:800;font-size:34px;margin-top:22px;color:#5A2A0C;text-shadow:none;
  background:#fff;display:inline-block;padding:10px 28px;border-radius:999px;
  box-shadow:0 8px 0 rgba(0,0,0,.1)}}
.t{{position:absolute;width:150px;height:150px;border-radius:40px;display:flex;
  align-items:center;justify-content:center;box-shadow:0 12px 26px rgba(0,0,0,.2)}}
.t img{{max-width:118px;max-height:118px}}
.t0{{right:296px;top:70px;background:#C8E6C9;transform:rotate(-6deg)}}
.t1{{right:138px;top:52px;background:#FFE0B2;transform:rotate(5deg)}}
.t2{{right:-20px;top:92px;background:#F8BBD0;transform:rotate(-4deg)}}
.t3{{right:280px;top:262px;background:#B3E5FC;transform:rotate(6deg)}}
.t4{{right:120px;top:248px;background:#FFF9C4;transform:rotate(-5deg)}}
.t5{{right:-38px;top:284px;background:#D1C4E9;transform:rotate(7deg)}}
.note{{position:absolute;font-weight:900;color:rgba(255,255,255,.9);font-size:64px}}
.n1{{left:600px;top:200px;transform:rotate(-14deg)}}
.n2{{left:560px;top:384px;transform:rotate(12deg);font-size:48px}}
</style></head><body>
<div class="blob b1"></div><div class="blob b2"></div>
{tiles}
<div class="txt"><div class="title">{title}</div><div class="tag">{tagline}</div></div>
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


def main() -> int:
    chrome = next((c for c in CHROME_CANDIDATES if pathlib.Path(c).exists()), None)
    if chrome is None:
        print("Chrome or Edge not found", file=sys.stderr)
        return 1
    for locale, copy in COPY.items():
        raw_dir = RAW / locale
        if not raw_dir.exists():
            print("skip", locale, "(no captures)")
            continue
        for i, (shot, lines) in enumerate(zip(SHOTS, copy["shots"]), start=1):
            name, top, bottom, accent, stickers = shot
            # The sound screen keeps its play button at the bottom, so that
            # shot shows the whole phone instead of cropping it.
            width = 664 if name == "02_sound" else 820
            html = phone_html(raw_dir / f"{name}.png", top, bottom, accent,
                              stickers, lines[0], lines[1], width)
            render(chrome, html, f"{locale}_{i:02d}",
                   OUT / locale / f"phone_{i:02d}.png", 1080, 1920)
        render(chrome, feature_html(copy["title"], copy["tagline"]),
               f"{locale}_feature", OUT / locale / "feature_graphic.png", 1024, 500)
    return 0


if __name__ == "__main__":
    sys.exit(main())
