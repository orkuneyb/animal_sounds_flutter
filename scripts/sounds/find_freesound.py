"""Searches Freesound for recordings with a licence the app can use.

Usage (from the project root, with the key in the environment):
    FREESOUND_API_KEY=... python scripts/sounds/find_freesound.py            every animal not searched yet
    FREESOUND_API_KEY=... python scripts/sounds/find_freesound.py --list     print what was found so far
    ... find_freesound.py --only lynx puma                                   just these animals

Reads animal-sound-research/reports/freesound_queries.json:
{animal id: {"q": [search phrases], "must": [words; one of them has to be
in the sound's name, tags or description]}}. Only CC0 and CC BY
("Attribution") sounds between 0.4 and 180 seconds are asked for. Answers
are kept in reports/search_freesound/<id>.json. Nothing is downloaded. The
key is read from the environment and never written anywhere.
"""
import json
import os
import pathlib
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE = ROOT / "animal-sound-research"
OUT = BASE / "reports" / "search_freesound"
API = "https://freesound.org/apiv2/search/text/"
FIELDS = "id,name,description,tags,license,username,duration,avg_rating,num_ratings,num_downloads,url,previews,type,samplerate"
FILTER = 'license:("Creative Commons 0" OR "Attribution") duration:[0.4 TO 180]'


def ask(phrase: str) -> list:
    key = os.environ.get("FREESOUND_API_KEY")
    if not key:
        sys.exit("set FREESOUND_API_KEY first")
    url = API + "?" + urllib.parse.urlencode({"query": phrase, "filter": FILTER, "fields": FIELDS,
                                              "page_size": "30", "sort": "score"})
    request = urllib.request.Request(url, headers={"Authorization": f"Token {key}",
                                                   "User-Agent": "animal-sound-research/1.0"})
    for wait in (0, 30, 90):
        time.sleep(wait)
        try:
            with urllib.request.urlopen(request, timeout=40) as answer:
                return json.loads(answer.read().decode("utf-8")).get("results", [])
        except urllib.error.HTTPError as error:
            if error.code != 429:
                raise
    sys.exit("Freesound keeps answering 'too many requests'; try again later")


def relevant(row: dict, must: list) -> bool:
    text = " ".join([row["name"], " ".join(row.get("tags") or []), row.get("description") or ""]).lower()
    return any(word.lower() in text for word in must)


def main() -> int:
    queries = json.loads((BASE / "reports" / "freesound_queries.json").read_text(encoding="utf-8"))
    only = sys.argv[sys.argv.index("--only") + 1:] if "--only" in sys.argv else None
    OUT.mkdir(parents=True, exist_ok=True)
    for animal, spec in queries.items():
        if only and animal not in only:
            continue
        path = OUT / f"{animal}.json"
        if "--list" not in sys.argv and not path.exists():
            found = {}
            for phrase in spec["q"]:
                for row in ask(phrase):
                    found.setdefault(row["id"], row)
                time.sleep(1.2)
            path.write_text(json.dumps(list(found.values()), ensure_ascii=False, indent=1), encoding="utf-8")
        if not path.exists():
            continue
        rows = [r for r in json.loads(path.read_text(encoding="utf-8")) if relevant(r, spec["must"])]
        rows.sort(key=lambda r: (-(r.get("num_downloads") or 0)))
        print(f"## {animal}: {len(rows)} candidates", flush=True)
        for r in rows[:int(os.environ.get("TOP", "6"))]:
            licence = "CC0" if "zero" in r["license"] else "BY" + r["license"].rstrip("/").split("/")[-1]
            text = " ".join((r.get("description") or "").split())[:150]
            line = (f"   {r['id']:>7} {licence:6} {r['duration']:6.1f}s dl{r.get('num_downloads') or 0:>6} "
                    f"{r['name'][:48]} | {r['username'][:16]} | {text}")
            print(line.encode("ascii", "backslashreplace").decode(), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
