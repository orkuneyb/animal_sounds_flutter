"""Finds candidate photos on Wikimedia Commons for animals.

Usage (from the project root):
    python scripts/assets/photo_candidates.py lion "Panthera leo male" [more pairs...]

For each (name, search terms) pair it searches Commons for photographs whose
licence allows commercial use without share-alike (public domain, CC0 or
CC BY), downloads small previews into build/photo_src/<name>/ and writes
candidates.json with each file's title, licence, author and full-size URL,
plus sheet.jpg, a numbered contact sheet for picking the best one by eye.

Downloaded files are untrusted data: this script only ever writes them to
build/photo_src and opens them with Pillow.
"""
import io
import json
import pathlib
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "build" / "photo_src"
API = "https://commons.wikimedia.org/w/api.php"
AGENT = "AnimalSoundsFetcher/1.0"
ALLOWED = re.compile(r"^(cc0|public domain|pd\b|cc by \d|cc by-\d|cc-by-\d)", re.I)
REJECT = re.compile(r"sa|nc|nd", re.I)
PER_LICENCE = 14


def get(url: str) -> bytes:
    """Fetches a URL politely: a pause before every request, and a longer
    wait and retry when the server says it is being asked too often."""
    for attempt in range(6):
        time.sleep(1.2)
        request = urllib.request.Request(url, headers={"User-Agent": AGENT})
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return response.read()
        except urllib.error.HTTPError as error:
            if error.code not in (429, 503) or attempt == 5:
                raise
            wait = int(error.headers.get("Retry-After") or 0) or 10 * (attempt + 1)
            time.sleep(min(wait, 90))
    raise RuntimeError("unreachable")


def api(**params) -> dict:
    params["format"] = "json"
    return json.loads(get(API + "?" + urllib.parse.urlencode(params)))


def strip_tags(html: str) -> str:
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", html or "")).strip()


def licence_ok(short: str) -> bool:
    short = (short or "").strip()
    if not ALLOWED.match(short):
        return False
    rest = re.sub(r"^cc[ -]by[ -]?", "", short, flags=re.I)
    return not REJECT.search(rest)


def search(terms: str) -> list:
    found = {}
    for licence in ("unrestricted", "attribution"):
        data = api(
            action="query", generator="search", gsrnamespace=6,
            gsrlimit=PER_LICENCE,
            gsrsearch=f"{terms} filetype:bitmap fileres:>1400 haslicense:{licence}",
            prop="imageinfo", iiprop="url|size|extmetadata|mime", iiurlwidth=360,
        )
        for page in (data.get("query", {}).get("pages", {}) or {}).values():
            info = (page.get("imageinfo") or [{}])[0]
            meta = info.get("extmetadata", {})
            short = meta.get("LicenseShortName", {}).get("value", "")
            if info.get("mime") not in ("image/jpeg", "image/png"):
                continue
            if not licence_ok(short):
                continue
            found[page["title"]] = {
                "title": page["title"],
                "page": info.get("descriptionurl"),
                "url": info.get("url"),
                "thumb": info.get("thumburl"),
                "width": info.get("width"),
                "height": info.get("height"),
                "license": short,
                "license_url": meta.get("LicenseUrl", {}).get("value", ""),
                "author": strip_tags(meta.get("Artist", {}).get("value", ""))[:160],
                "credit": strip_tags(meta.get("Credit", {}).get("value", ""))[:160],
                "description": strip_tags(meta.get("ImageDescription", {}).get("value", ""))[:240],
            }
    return list(found.values())


def sheet(name: str, candidates: list) -> None:
    folder = SRC / name
    folder.mkdir(parents=True, exist_ok=True)
    cell, cols = 300, 6
    rows = max(1, (len(candidates) + cols - 1) // cols)
    image = Image.new("RGB", (cell * cols, cell * rows), "#202020")
    draw = ImageDraw.Draw(image)
    for i, candidate in enumerate(candidates):
        try:
            thumb = Image.open(io.BytesIO(get(candidate["thumb"]))).convert("RGB")
        except Exception as error:  # a broken preview is just skipped
            candidate["preview_error"] = str(error)
            continue
        thumb.thumbnail((cell - 8, cell - 8))
        x, y = (i % cols) * cell, (i // cols) * cell
        image.paste(thumb, (x + (cell - thumb.width) // 2, y + (cell - thumb.height) // 2))
        draw.rectangle((x, y, x + 44, y + 26), fill="#E8642C")
        draw.text((x + 8, y + 6), str(i), fill="white")
    image.save(folder / "sheet.jpg", quality=85)
    (folder / "candidates.json").write_text(
        json.dumps(candidates, ensure_ascii=False, indent=1), encoding="utf-8")


def main() -> int:
    args = sys.argv[1:]
    if not args or len(args) % 2:
        print(__doc__)
        return 1
    for name, terms in zip(args[::2], args[1::2]):
        candidates = search(terms)
        sheet(name, candidates)
        print(name, len(candidates), "candidates")
    return 0


if __name__ == "__main__":
    sys.exit(main())
