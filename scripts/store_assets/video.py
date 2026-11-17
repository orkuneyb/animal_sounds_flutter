"""Builds the Play Store promo video (1920x1080, about 35 s) for each app language.

Usage (from the project root, after capture_test.dart has run):
    python scripts/store_assets/video.py            all locales with captures
    python scripts/store_assets/video.py tr-TR      just these

Uses real app captures and the texts of scripts/store_assets/copy.json. The
sound is soft background music (made by music.py, so free of rights) with
three gentle animal sounds from the app laid quietly over it: an alpaca hum,
an owl and a hen. All three are CC0 or public domain, so the video needs no
credit line. Every scene zooms in slowly and the scenes
slide into one another. Writes docs/store-assets/<locale>/promo_video.mp4.
Play needs a YouTube URL, so upload the file to YouTube (public or unlisted,
ads off) and paste the link into the listing of that language.
"""
import pathlib
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import compose  # noqa: E402

ROOT = compose.ROOT
SOUNDS = ROOT / "assets" / "animal_sounds"
FRAMES = ROOT / "build" / "store_assets" / "video"
MUSIC = ROOT / "build" / "store_assets" / "music.wav"
FADE = 0.5
FPS = 30
MUSIC_GAIN = 0.9
ANIMAL_GAIN = 0.32
ANIMAL_SECONDS = 2.6

# (kind, gradient, sound, seconds); kind is a raw capture name, "intro", "new" or "outro".
# The number after a capture name is its caption in copy.json "shots".
SCENES = [
    ("intro", ("#FF8A5C", "#FFC46B"), None, 3.6),
    ("new", ("#7B5CFA", "#C45CF0"), None, 4.2),
    ("02_sound:1", ("#FFB300", "#FF7A45"), "alpaca", 4.0),
    ("05_guess:2", ("#2F9BFF", "#6C63FF"), "owl", 4.0),
    ("04_quiz:3", ("#7B5CFA", "#C45CF0"), None, 4.0),
    ("03_info:4", ("#33B36B", "#128A62"), None, 4.0),
    ("08_daily:5", ("#B06AF2", "#F56FA8"), "chicken", 4.0),
    ("09_collection:6", ("#18B6A4", "#2F80ED"), None, 4.0),
    ("outro", ("#FF7A45", "#F0457A"), None, 4.0),
]
OLD = ["elephant", "lion", "dog", "tiger", "giraffe", "owl", "cow", "monkey"]
NEW = ["red_panda", "flamingo", "snow_leopard", "toucan", "lemur", "polar_bear", "fennec_fox", "chameleon",
       "kiwi", "orangutan", "hedgehog", "meerkat", "seahorse", "rhinoceros", "butterfly", "chimpanzee"]
COLORS = ["#C8E6C9", "#FFE0B2", "#F8BBD0", "#B3E5FC", "#FFF9C4", "#D1C4E9", "#FFCCBC", "#DCEDC8"]
TILTS = (-5, 4, -3, 5, -4, 3, -5, 4)


def base_css(grad) -> str:
    return f"""{compose.font_css()}
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:1920px;height:1080px;overflow:hidden}}
body{{font-family:{compose.FAMILY};position:relative;color:#fff;
  background:linear-gradient(135deg,{grad[0]},{grad[1]})}}
.blob{{position:absolute;border-radius:50%;background:rgba(255,255,255,.13)}}
.b1{{width:900px;height:900px;left:-320px;top:-380px}}
.b2{{width:1100px;height:1100px;right:-380px;bottom:-640px;background:rgba(0,0,0,.07)}}
.t{{border-radius:52px;display:flex;align-items:center;justify-content:center;
  box-shadow:0 14px 30px rgba(0,0,0,.22)}}
"""


def page(locale: str, grad, body: str, css: str) -> str:
    return (f'<!doctype html><html dir="{compose.direction(locale)}"><head><meta charset="utf-8"><style>'
            f'{base_css(grad)}{css}</style></head><body><div class="blob b1"></div>'
            f'<div class="blob b2"></div>{body}</body></html>')


def tiles(animals: list, size: int) -> str:
    out = ""
    for i, animal in enumerate(animals):
        src = compose.uri(compose.IMAGES / (animal + ".png"))
        out += (f'<div class="t" style="width:{size}px;height:{size}px;background:{COLORS[i % 8]};'
                f'transform:rotate({TILTS[i % 8]}deg)"><img style="max-width:{int(size * .8)}px;'
                f'max-height:{int(size * .8)}px" src="{src}"></div>')
    return out


def scene_html(locale, raw, grad, l1, l2):
    size = 104 if max(len(l1), len(l2)) > 14 else 128
    side = "right" if compose.direction(locale) == "ltr" else "left"
    other = "left" if side == "right" else "right"
    return page(locale, grad, f"""<div class="txt"><div class="l1">{l1}</div><div class="l2">{l2}</div></div>
<div class="phone"><img src="{compose.uri(raw)}"></div>""", f"""
.txt{{position:absolute;{other}:130px;top:0;bottom:0;width:1040px;display:flex;
  flex-direction:column;justify-content:center;text-shadow:0 7px 0 rgba(0,0,0,.13)}}
.l1{{font-weight:900;font-size:{size}px;line-height:1.1;letter-spacing:-2px}}
.l2{{font-weight:900;font-size:{size}px;line-height:1.1;letter-spacing:-2px;color:#FFF3C4}}
.phone{{position:absolute;{side}:190px;top:40px;width:500px;padding:15px;border-radius:62px;
  background:#1c1b22;box-shadow:0 36px 80px rgba(0,0,0,.36),inset 0 0 0 3px #3a3944;
  transform:rotate({3 if side == 'right' else -3}deg)}}
.phone img{{display:block;width:470px;border-radius:48px}}""")


def card_html(locale, grad, title, tagline):
    size = 176 if len(title) <= 14 else 132
    return page(locale, grad, f"""<div class="c"><div class="title">{title}</div><div class="tag">{tagline}</div></div>
<div class="row">{tiles(NEW[:4] + OLD[:4], 196)}</div>""", f"""
.c{{position:absolute;left:0;right:0;top:150px;text-align:center}}
.title{{font-weight:900;font-size:{size}px;letter-spacing:-3px;text-shadow:0 9px 0 rgba(0,0,0,.14)}}
.tag{{display:inline-block;margin-top:26px;font-weight:800;font-size:60px;color:#5A2A0C;
  background:#fff;padding:16px 52px;border-radius:999px;box-shadow:0 10px 0 rgba(0,0,0,.1)}}
.row{{position:absolute;left:0;right:0;bottom:110px;display:flex;justify-content:center;gap:26px;direction:ltr}}""")


def new_html(locale, grad, line1, line2):
    return page(locale, grad, f"""<div class="c"><div class="title">{line1}</div><div class="tag">{line2}</div></div>
<div class="grid">{tiles(NEW, 190)}</div>""", """
.c{position:absolute;left:0;right:0;top:70px;text-align:center}
.title{font-weight:900;font-size:124px;letter-spacing:-2px;text-shadow:0 8px 0 rgba(0,0,0,.14)}
.tag{display:inline-block;margin-top:14px;font-weight:900;font-size:52px;color:#fff;
  background:#E8463C;padding:12px 46px;border-radius:999px;box-shadow:0 9px 0 rgba(0,0,0,.14)}
.grid{position:absolute;left:150px;right:150px;bottom:70px;display:grid;
  grid-template-columns:repeat(8,1fr);gap:30px 12px;justify-items:center;direction:ltr}""")


def build(chrome, locale, copy):
    raw_dir = compose.RAW / locale
    stills = []
    for i, (kind, grad, _, _) in enumerate(SCENES):
        if kind in ("intro", "outro"):
            html = card_html(locale, grad, copy["title"], copy["tagline"])
        elif kind == "new":
            html = new_html(locale, grad, *copy["new"])
        else:
            raw, shot = kind.split(":")
            html = scene_html(locale, raw_dir / f"{raw}.png", grad, *copy["shots"][int(shot)])
        out = FRAMES / locale / f"scene_{i:02d}.png"
        compose.render(chrome, html, f"{locale}_video_{i:02d}", out, 1920, 1080)
        stills.append(out)

    cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"]
    for still in stills:
        cmd += ["-i", str(still)]
    total = sum(scene[3] for scene in SCENES)
    subprocess.run([sys.executable, str(pathlib.Path(__file__).with_name("music.py")), f"{total:.2f}"],
                   check=True, stdout=subprocess.DEVNULL)
    cmd += ["-i", str(MUSIC)]
    voiced = [(i, scene[2]) for i, scene in enumerate(SCENES) if scene[2]]
    for _, sound in voiced:
        cmd += ["-i", str(SOUNDS / f"{sound}.mp3")]

    n = len(SCENES)
    filters = []
    for i, (_, _, _, secs) in enumerate(SCENES):
        frames = round((secs + FADE) * FPS)
        # A slow push-in; the picture is enlarged first so the motion stays smooth.
        filters.append(
            f"[{i}:v]scale=3840:2160:flags=lanczos,zoompan=z='1+0.06*on/{frames}':"
            f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d={frames}:s=1920x1080:fps={FPS},"
            f"format=yuv420p[v{i}]")
    last, offset, starts = "v0", 0.0, [0.0]
    for i in range(1, n):
        offset += SCENES[i - 1][3]
        starts.append(offset)
        transition = "fade" if i in (1, n - 1) else "slideleft"
        filters.append(
            f"[{last}][v{i}]xfade=transition={transition}:duration={FADE}:offset={offset:.2f}[x{i}]")
        last = f"x{i}"
    # The animal sounds sit well under the music: shortened, softened at
    # the top and faded at both ends.
    filters.append(f"[{n}:a]volume={MUSIC_GAIN}[music]")
    for k, (i, _) in enumerate(voiced):
        filters.append(
            f"[{n + 1 + k}:a]atrim=0:{ANIMAL_SECONDS},lowpass=f=5000,volume={ANIMAL_GAIN},"
            f"afade=t=in:d=0.15,afade=t=out:st={ANIMAL_SECONDS - 0.8}:d=0.8,"
            f"aformat=channel_layouts=stereo,adelay={int((starts[i] + 0.9) * 1000)}:all=1[a{k}]")
    filters.append("[music]" + "".join(f"[a{k}]" for k in range(len(voiced)))
                   + f"amix=inputs={len(voiced) + 1}:normalize=0,alimiter=limit=0.9,apad[aout]")
    out = compose.OUT / locale / "promo_video.mp4"
    cmd += ["-filter_complex", ";".join(filters), "-map", f"[{last}]", "-map", "[aout]",
            "-t", f"{total:.2f}", "-c:v", "libx264", "-preset", "medium", "-crf", "19",
            "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2",
            "-movflags", "+faststart", str(out)]
    subprocess.run(cmd, check=True)
    print("wrote", out.relative_to(ROOT), f"({total:.1f}s)")


def main() -> int:
    chrome = next((c for c in compose.CHROME_CANDIDATES if pathlib.Path(c).exists()), None)
    if chrome is None:
        print("Chrome or Edge not found", file=sys.stderr)
        return 1
    for locale in sys.argv[1:] or list(compose.COPY):
        if (compose.RAW / locale).exists():
            build(chrome, locale, compose.COPY[locale])
    return 0


if __name__ == "__main__":
    sys.exit(main())
