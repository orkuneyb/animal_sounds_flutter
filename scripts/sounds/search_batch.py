"""Searches Wikimedia Commons for many animals at once and lists usable candidates.

Usage (from the project root):
    python scripts/sounds/search_batch.py            search every animal not searched yet
    python scripts/sounds/search_batch.py --list     only print the candidates found so far

Reads animal-sound-research/reports/queries.json ({animal id: [search
phrases]}; the phrases are also the words a recording must mention to count
as being about that animal). Every answer is kept in reports/search/<id>.json.
The list shows only recordings whose licence is CC0, public domain or CC BY;
CC BY-SA ones are counted, for the separate review list. Nothing is
downloaded.
"""
import json
import pathlib
import re
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from find_commons import OUT, plain, search  # noqa: E402

BASE = OUT.parent.parent
NOISE = re.compile(r"LL-Q|pronunciation|pronounc|spoken|wikipedia|article|\.mid$|^File:[A-Za-z]{2,3}-|"
                   r"aussprache|prononciation|voice of|podcast|interview|engine|exhaust", re.I)


def licence_class(name: str) -> str:
    low = name.lower()
    if "nc" in low.split() or "-nc" in low or "nd" in low.split() or "-nd" in low:
        return "no"
    if "sa" in low:
        return "sa"
    if low.startswith(("cc0", "public domain", "pd")):
        return "free"
    if low.startswith("cc by"):
        return "by"
    return "unknown"


def rows_for(animal: str, phrases: list) -> list:
    found = {}
    for phrase in phrases:
        for page in search(phrase):
            found.setdefault(page["title"], page)
        time.sleep(4)
    rows = []
    for title, page in found.items():
        info = (page.get("videoinfo") or [{}])[0]
        meta = {k: v.get("value", "") for k, v in (info.get("extmetadata") or {}).items()}
        rows.append({
            "title": title, "page": info.get("descriptionurl"), "file": info.get("url"),
            "seconds": info.get("duration"), "bytes": info.get("size"), "mime": info.get("mime"),
            "licence": meta.get("LicenseShortName", ""), "licence_url": meta.get("LicenseUrl", ""),
            "author": plain(meta.get("Artist", "")), "credit": plain(meta.get("Credit", "")),
            "description": plain(meta.get("ImageDescription", ""))[:400],
            "categories": meta.get("Categories", ""), "uploader": info.get("user"),
        })
    return rows


def relevant(row: dict, phrases: list) -> bool:
    text = " ".join([row["title"], row["description"], row["categories"]]).lower()
    return (not NOISE.search(row["title"])) and any(p.lower() in text for p in phrases) \
        and (row["seconds"] or 0) >= 0.5


def main() -> int:
    queries = json.loads((BASE / "reports" / "queries.json").read_text(encoding="utf-8"))
    OUT.mkdir(parents=True, exist_ok=True)
    for animal, phrases in queries.items():
        path = OUT / f"{animal}.json"
        if "--list" not in sys.argv and not path.exists():
            path.write_text(json.dumps(rows_for(animal, phrases), ensure_ascii=False, indent=1), encoding="utf-8")
        if not path.exists():
            continue
        rows = [r for r in json.loads(path.read_text(encoding="utf-8")) if relevant(r, phrases)]
        usable = [r for r in rows if licence_class(r["licence"]) in ("free", "by")]
        share = sum(1 for r in rows if licence_class(r["licence"]) == "sa")
        print(f"## {animal}: {len(usable)} usable, {share} CC BY-SA", flush=True)
        for r in usable[:8]:
            line = (f"   {r['licence'][:13]:13} {str(r['seconds'])[:5]:>5}s {r['title'][5:75]} | {r['author'][:28]} "
                    f"| {r['description'][:110]}")
            print(line.encode("ascii", "backslashreplace").decode(), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
