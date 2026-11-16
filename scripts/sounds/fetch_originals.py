"""Downloads the chosen source recordings, untouched, into the research folder.

Usage (from the project root):
    python scripts/sounds/fetch_originals.py

Reads animal-sound-research/selections.json (the hand-kept list of chosen
recordings). Every entry with a "file_url" is saved once as
animal-sound-research/originals/<animal id>/<file name>; its size, SHA-256
and download date are written back into the entry. A file that is already
there is not fetched again. Files are only saved, never opened or run.
"""
import datetime
import hashlib
import json
import pathlib
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE = ROOT / "animal-sound-research"
AGENT = "animal-sound-research/1.0 (licence check for an educational app)"
ALLOWED = (".ogg", ".oga", ".flac", ".wav", ".mp3", ".opus")
LIMIT = 150 * 1024 * 1024


def main() -> int:
    path = BASE / "selections.json"
    entries = json.loads(path.read_text(encoding="utf-8"))
    waiting = 0
    for entry in entries:
        url = entry.get("file_url")
        if not url:
            continue
        name = pathlib.PurePosixPath(urllib.parse.unquote(urllib.parse.urlparse(url).path)).name
        if not name.lower().endswith(ALLOWED):
            sys.exit(f"{entry['animal_id']}: {name!r} is not an audio file name")
        folder = BASE / "originals" / entry["animal_id"]
        folder.mkdir(parents=True, exist_ok=True)
        target = folder / name
        if not target.exists():
            request = urllib.request.Request(url, headers={"User-Agent": AGENT})
            data = None
            for wait in (0, 30, 90, 180):
                time.sleep(wait)  # the site asks callers that go too fast to slow down
                try:
                    with urllib.request.urlopen(request, timeout=120) as answer:
                        data = answer.read(LIMIT + 1)
                    break
                except urllib.error.HTTPError as error:
                    if error.code not in (429, 503):
                        raise
            if data is None:
                print(f"{entry['animal_id']}: the site keeps answering 'too many requests'; run again later")
                waiting += 1
                continue
            if len(data) > LIMIT:
                sys.exit(f"{name}: larger than {LIMIT} bytes, not saved")
            target.write_bytes(data)
            entry["downloaded"] = datetime.date.today().isoformat()
            time.sleep(8)
        data = target.read_bytes()
        entry["original"] = target.relative_to(BASE).as_posix()
        entry["original_bytes"] = len(data)
        entry["original_sha256"] = hashlib.sha256(data).hexdigest()
        print(entry["animal_id"], name.encode("ascii", "backslashreplace").decode(), len(data) // 1024, "KB")
    # Only the download facts are written back, into the list as it is now.
    facts = {e["animal_id"]: e for e in entries}
    current = json.loads(path.read_text(encoding="utf-8"))
    for entry in current:
        for key in ("downloaded", "original", "original_bytes", "original_sha256"):
            if key in facts.get(entry["animal_id"], {}):
                entry[key] = facts[entry["animal_id"]][key]
    path.write_text(json.dumps(current, ensure_ascii=False, indent=1) + "\n", encoding="utf-8", newline="\n")
    return 1 if waiting else 0


if __name__ == "__main__":
    sys.exit(main())
