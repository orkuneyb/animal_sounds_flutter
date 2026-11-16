"""Cuts and catalogues the sheets listed in docs/animal-art/sheets.json.

Usage (from the project root, inside the build/venv environment):
    python scripts/assets/run_sheets.py 2 3 4          cut, then catalogue
    python scripts/assets/run_sheets.py --catalog 2    catalogue only (after editing a note)

sheets.json maps a sheet number to its ten animals in reading order, each
as [file name, Turkish name, note] plus an
optional "main" to keep only the largest piece of that animal. A note marks the animal "needs review".
"""
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
HERE = pathlib.Path(__file__).resolve().parent


def main() -> int:
    args = sys.argv[1:]
    only_catalog = "--catalog" in args
    numbers = [a for a in args if not a.startswith("--")]
    sheets = json.loads((ROOT / "docs" / "animal-art" / "sheets.json").read_text(encoding="utf-8"))
    for number in numbers:
        animals = sheets[number]
        if not only_catalog:
            subprocess.run([sys.executable, str(HERE / "cut_sheet.py"), number]
                           + [a[0] + ("!" if "main" in a[3:] else "") for a in animals], cwd=ROOT)
        subprocess.run([sys.executable, str(HERE / "catalog.py"), number]
                       + [f"{a[0]}={a[1]}" + (f"|{a[2]}" if a[2] else "") for a in animals], cwd=ROOT)
    return 0


if __name__ == "__main__":
    sys.exit(main())
