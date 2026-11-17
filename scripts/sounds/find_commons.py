"""Searches Wikimedia Commons for audio recordings and lists their licences.

Usage (from the project root):
    python scripts/sounds/find_commons.py gibbon "Hylobates" "gibbon song"

The first argument is the animal id; the rest are search phrases. A phrase
that starts with "Category:" lists the audio files of that Commons category
instead. Every
audio file found is printed with its length, licence, author and
description, and the full answers are kept in
animal-sound-research/reports/search/<id>.json so a choice can be traced
back. Nothing is downloaded.
"""
import html
import json
import pathlib
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "animal-sound-research" / "reports" / "search"
API = "https://commons.wikimedia.org/w/api.php"
AGENT = "animal-sound-research/1.0 (licence check for an educational app)"


def plain(text: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", text or ""))).strip()


def ask(params: dict) -> dict:
    url = API + "?" + urllib.parse.urlencode({**params, "format": "json", "formatversion": "2"})
    request = urllib.request.Request(url, headers={"User-Agent": AGENT})
    for wait in (0, 20, 60, 120):
        time.sleep(wait)  # the site asks callers that go too fast to slow down
        try:
            with urllib.request.urlopen(request, timeout=40) as answer:
                return json.loads(answer.read().decode("utf-8"))
        except urllib.error.HTTPError as error:
            if error.code not in (429, 503):
                raise
    raise SystemExit("Commons keeps answering 'too many requests'; try again later")


def search(phrase: str) -> list:
    data = ask({
        "action": "query", "generator": "search", "gsrnamespace": "6", "gsrlimit": "25",
        "gsrsearch": f"filetype:audio {phrase}",
        "prop": "videoinfo", "viprop": "url|size|mime|extmetadata|user",
    })
    return data.get("query", {}).get("pages", [])


def category(title: str) -> list:
    data = ask({
        "action": "query", "generator": "categorymembers", "gcmtitle": title, "gcmtype": "file",
        "gcmlimit": "200", "prop": "videoinfo", "viprop": "url|size|mime|extmetadata|user",
    })
    pages = data.get("query", {}).get("pages", [])
    return [p for p in pages if (p.get("videoinfo") or [{}])[0].get("mime", "").startswith(("audio", "application/ogg"))]


def main() -> int:
    animal, phrases = sys.argv[1], sys.argv[2:]
    found = {}
    for phrase in phrases:
        for page in (category(phrase) if phrase.startswith("Category:") else search(phrase)):
            found.setdefault(page["title"], page)
        time.sleep(3)
    rows = []
    for title, page in found.items():
        info = (page.get("videoinfo") or [{}])[0]
        meta = {k: v.get("value", "") for k, v in (info.get("extmetadata") or {}).items()}
        rows.append({
            "title": title,
            "page": info.get("descriptionurl"),
            "file": info.get("url"),
            "seconds": info.get("duration"),
            "bytes": info.get("size"),
            "mime": info.get("mime"),
            "licence": meta.get("LicenseShortName", ""),
            "licence_url": meta.get("LicenseUrl", ""),
            "author": plain(meta.get("Artist", "")),
            "credit": plain(meta.get("Credit", "")),
            "attribution_required": meta.get("AttributionRequired", ""),
            "description": plain(meta.get("ImageDescription", ""))[:400],
            "categories": meta.get("Categories", ""),
            "uploader": info.get("user"),
        })
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / f"{animal}.json").write_text(json.dumps(rows, ensure_ascii=False, indent=1), encoding="utf-8")
    for row in sorted(rows, key=lambda r: r["licence"]):
        line = (f"{row['licence'][:14]:14} {str(row['seconds'])[:6]:>6}s  {row['title'][5:70]}  "
                f"| {row['author'][:30]} | {row['description'][:90]}")
        print(line.encode("ascii", "backslashreplace").decode())
    print(len(rows), "files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
