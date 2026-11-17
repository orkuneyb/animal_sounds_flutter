"""Edits one animal's entry in docs/animal-art/sheets.json.

Usage (from the project root):
    python scripts/assets/sheet_notes.py 10 7 --note "fok bıyığı temizlendi" --main
    python scripts/assets/sheet_notes.py 8 7 --name gazelle --tr Ceylan
    python scripts/assets/sheet_notes.py 5 3 --note ""

Arguments are the sheet number and the position (1-10, reading order).
--note sets the note ("OK: ..." records a point that was looked at and found
fine; any other note marks the animal "needs review"), --main keeps only the
largest piece when cutting, --name and --tr rename it. Several edits can be
chained by repeating "sheet position options" after a "+".
"""
import json
import pathlib
import sys

PATH = pathlib.Path(__file__).resolve().parents[2] / "docs" / "animal-art" / "sheets.json"


def save(sheets: dict) -> None:
    lines = ["{"]
    keys = list(sheets)
    for key in keys:
        rows = sheets[key]
        halves = [", ".join(json.dumps(a, ensure_ascii=False) for a in rows[i:i + 5]) for i in (0, 5) if rows[i:i + 5]]
        lines.append(f' "{key}": [' + (",\n" + " " * 7).join(halves) + "]" + ("," if key != keys[-1] else ""))
    lines.append("}")
    PATH.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def main() -> int:
    sheets = json.loads(PATH.read_text(encoding="utf-8"))
    edits, current = [], []
    for arg in sys.argv[1:]:
        if arg == "+":
            edits.append(current)
            current = []
        else:
            current.append(arg)
    edits.append(current)
    for edit in edits:
        if len(edit) < 2:
            print(__doc__)
            return 1
        entry = sheets[edit[0]][int(edit[1]) - 1]
        options = edit[2:]
        i = 0
        while i < len(options):
            if options[i] == "--main":
                if "main" not in entry[3:]:
                    entry.append("main")
                i += 1
            elif options[i] == "--note":
                entry[2] = options[i + 1]
                i += 2
            elif options[i] == "--name":
                entry[0] = options[i + 1]
                i += 2
            elif options[i] == "--tr":
                entry[1] = options[i + 1]
                i += 2
            else:
                print("unknown option", options[i])
                return 1
    save(sheets)
    return 0


if __name__ == "__main__":
    sys.exit(main())
