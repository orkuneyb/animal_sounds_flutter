"""Prints the description page of Wikimedia Commons files, for checking a licence by eye.

Usage (from the project root):
    python scripts/sounds/commons_page.py "File:Jaguar saw.flac" "File:..."

Prints the page text (source, author, licence template, permission) and
keeps a copy in animal-sound-research/reports/pages/. Nothing is downloaded.
"""
import json
import pathlib
import re
import sys
import time
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "animal-sound-research" / "reports" / "pages"
API = "https://commons.wikimedia.org/w/api.php"
AGENT = "animal-sound-research/1.0 (licence check for an educational app)"


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    for title in sys.argv[1:]:
        url = API + "?" + urllib.parse.urlencode({
            "action": "query", "titles": title, "prop": "revisions", "rvprop": "content|timestamp",
            "rvslots": "main", "format": "json", "formatversion": "2"})
        request = urllib.request.Request(url, headers={"User-Agent": AGENT})
        with urllib.request.urlopen(request, timeout=40) as answer:
            page = json.loads(answer.read().decode("utf-8"))["query"]["pages"][0]
        text = page["revisions"][0]["slots"]["main"]["content"] if "revisions" in page else "(no such page)"
        name = re.sub(r"[^A-Za-z0-9]+", "_", title)[:80]
        (OUT / f"{name}.txt").write_text(text, encoding="utf-8")
        print("=====", title.encode("ascii", "backslashreplace").decode())
        print(text[:1800].encode("ascii", "backslashreplace").decode())
        time.sleep(3)
    return 0


if __name__ == "__main__":
    sys.exit(main())
