"""Builds the Play Store promo video (1920x1080, ~31 s) for each locale.

Usage (from the project root, after capture_test.dart has run):
    python scripts/store_assets/video.py

Uses real app captures and the app's own animal sounds.
Writes docs/store-assets/<locale>/promo_video.mp4. Play needs a YouTube URL,
so upload the file to YouTube (public or unlisted, ads off) and paste the link.
"""
import pathlib
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import compose  # noqa: E402

ROOT = compose.ROOT
SOUNDS = ROOT / "assets" / "animal_sounds"
FRAMES = ROOT / "build" / "store_assets" / "video"
FADE = 0.5

# (raw capture or None for a title card, gradient, sound, seconds)
SCENES = [
    (None, ("#FF8A5C", "#FFC46B"), "lion", 3.5),
    ("02_sound", ("#FFB300", "#FF7A45"), "cow", 4.0),
    ("05_guess", ("#2F9BFF", "#6C63FF"), "rooster", 4.0),
    ("04_quiz", ("#7B5CFA", "#C45CF0"), "dog", 4.0),
    ("03_info", ("#33B36B", "#128A62"), "elephant", 4.0),
    ("08_daily", ("#B06AF2", "#F56FA8"), "whale", 4.0),
    ("09_collection", ("#18B6A4", "#2F80ED"), "duck", 4.0),
    (None, ("#FF7A45", "#F0457A"), "sheep", 4.0),
]

COPY = {
    "en-US": {
        "intro": ("Animal Sounds", "Listen · Learn · Play"),
        "scenes": [
            ("Real Animal", "Sounds"), ("Guess the", "Sound!"),
            ("Fun", "Quizzes"), ("Fun Facts", "Read Aloud"),
            ("A New Animal", "Every Day"), ("Collect", "Them All"),
        ],
        "outro": ("Animal Sounds", "Listen · Learn · Play"),
    },
    "tr-TR": {
        "intro": ("Hayvan Sesleri", "Dinle · Öğren · Oyna"),
        "scenes": [
            ("Gerçek Hayvan", "Sesleri"), ("Sesi", "Tahmin Et!"),
            ("Eğlenceli", "Quiz"), ("Eğlenceli Bilgiler", "Sesli Anlatımla"),
            ("Her Gün", "Yeni Bir Hayvan"), ("Hepsini", "Topla"),
        ],
        "outro": ("Hayvan Sesleri", "Dinle · Öğren · Oyna"),
    },
}

TILTS = (-5, 4, -3, 5, -4, 3, -5, 4)

BASE_CSS = """
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:1920px;height:1080px;overflow:hidden}
body{font-family:'Nunito';position:relative;color:#fff}
.blob{position:absolute;border-radius:50%;background:rgba(255,255,255,.13)}
.b1{width:900px;height:900px;left:-320px;top:-380px}
.b2{width:1100px;height:1100px;right:-380px;bottom:-640px;background:rgba(0,0,0,.07)}
"""


def scene_html(raw, grad, l1, l2):
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
{compose.font_css()}{BASE_CSS}
body{{background:linear-gradient(135deg,{grad[0]},{grad[1]})}}
.txt{{position:absolute;left:130px;top:0;bottom:0;width:1000px;display:flex;
  flex-direction:column;justify-content:center;text-shadow:0 7px 0 rgba(0,0,0,.13)}}
.l1{{font-weight:900;font-size:128px;line-height:1.04;letter-spacing:-2px}}
.l2{{font-weight:900;font-size:128px;line-height:1.04;letter-spacing:-2px;color:#FFF3C4}}
.phone{{position:absolute;right:190px;top:40px;width:500px;padding:15px;border-radius:62px;
  background:#1c1b22;box-shadow:0 36px 80px rgba(0,0,0,.36),inset 0 0 0 3px #3a3944;
  transform:rotate(3deg)}}
.phone img{{display:block;width:470px;border-radius:48px}}
</style></head><body><div class="blob b1"></div><div class="blob b2"></div>
<div class="txt"><div class="l1">{l1}</div><div class="l2">{l2}</div></div>
<div class="phone"><img src="{compose.uri(raw)}"></div></body></html>"""


def card_html(grad, title, tagline):
    animals = ["elephant", "lion", "dog", "tiger", "giraffe", "owl", "cow", "monkey"]
    colors = ["#C8E6C9", "#FFE0B2", "#F8BBD0", "#B3E5FC", "#FFF9C4", "#D1C4E9", "#FFCCBC", "#DCEDC8"]
    tiles = ""
    for tilt, animal, color in zip(TILTS, animals, colors):
        src = compose.uri(compose.IMAGES / (animal + ".png"))
        tiles += (f'<div class="t" style="background:{color};transform:rotate({tilt}deg)">'
                  f'<img src="{src}"></div>')
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
{compose.font_css()}{BASE_CSS}
body{{background:linear-gradient(135deg,{grad[0]},{grad[1]})}}
.c{{position:absolute;left:0;right:0;top:150px;text-align:center}}
.title{{font-weight:900;font-size:176px;letter-spacing:-3px;text-shadow:0 9px 0 rgba(0,0,0,.14)}}
.tag{{display:inline-block;margin-top:26px;font-weight:800;font-size:60px;color:#5A2A0C;
  background:#fff;padding:16px 52px;border-radius:999px;box-shadow:0 10px 0 rgba(0,0,0,.1)}}
.row{{position:absolute;left:0;right:0;bottom:110px;display:flex;justify-content:center;gap:26px}}
.t{{width:196px;height:196px;border-radius:52px;display:flex;align-items:center;
  justify-content:center;box-shadow:0 14px 30px rgba(0,0,0,.22)}}
.t img{{max-width:154px;max-height:154px}}
</style></head><body><div class="blob b1"></div><div class="blob b2"></div>
<div class="c"><div class="title">{title}</div><div class="tag">{tagline}</div></div>
<div class="row">{tiles}</div></body></html>"""


def build(chrome, locale, copy):
    raw_dir = compose.RAW / locale
    stills = []
    captions = iter(copy["scenes"])
    for i, (raw, grad, _, _) in enumerate(SCENES):
        if raw is None:
            lines = copy["intro"] if i == 0 else copy["outro"]
            html = card_html(grad, *lines)
        else:
            html = scene_html(raw_dir / f"{raw}.png", grad, *next(captions))
        out = FRAMES / locale / f"scene_{i:02d}.png"
        compose.render(chrome, html, f"{locale}_video_{i:02d}", out, 1920, 1080)
        stills.append(out)

    cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"]
    for still, (_, _, _, secs) in zip(stills, SCENES):
        cmd += ["-loop", "1", "-t", f"{secs + FADE}", "-i", str(still)]
    for _, _, sound, _ in SCENES:
        cmd += ["-i", str(SOUNDS / f"{sound}.mp3")]

    n = len(SCENES)
    filters = [f"[{i}:v]fps=30,format=yuv420p[v{i}]" for i in range(n)]
    last, offset, starts = "v0", 0.0, [0.0]
    for i in range(1, n):
        offset += SCENES[i - 1][3]
        starts.append(offset)
        transition = "fade" if i in (1, n - 1) else "slideleft"
        filters.append(
            f"[{last}][v{i}]xfade=transition={transition}:duration={FADE}:offset={offset:.2f}[x{i}]")
        last = f"x{i}"
    total = offset + SCENES[-1][3]
    for i, start in enumerate(starts):
        length = SCENES[i][3] - 0.5
        filters.append(
            f"[{n + i}:a]atrim=0:{length},afade=t=out:st={length - 0.5}:d=0.5,"
            f"adelay={int((start + 0.35) * 1000)}:all=1[a{i}]")
    filters.append("".join(f"[a{i}]" for i in range(n))
                   + f"amix=inputs={n}:normalize=0,apad[aout]")
    out = compose.OUT / locale / "promo_video.mp4"
    cmd += ["-filter_complex", ";".join(filters), "-map", f"[{last}]", "-map", "[aout]",
            "-t", f"{total:.2f}", "-c:v", "libx264", "-preset", "slow", "-crf", "18",
            "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2",
            "-movflags", "+faststart", str(out)]
    subprocess.run(cmd, check=True)
    print("wrote", out.relative_to(ROOT), f"({total:.1f}s)")


def main() -> int:
    chrome = next((c for c in compose.CHROME_CANDIDATES if pathlib.Path(c).exists()), None)
    if chrome is None:
        print("Chrome or Edge not found", file=sys.stderr)
        return 1
    for locale, copy in COPY.items():
        if (compose.RAW / locale).exists():
            build(chrome, locale, copy)
    return 0


if __name__ == "__main__":
    sys.exit(main())
