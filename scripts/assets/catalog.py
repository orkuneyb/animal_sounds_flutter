"""Checks the cut-out animals of one sheet and draws a control catalogue.

Usage (from the project root, inside the build/venv environment):
    python scripts/assets/catalog.py 1 lion=Aslan tiger=Kaplan ...
    python scripts/assets/catalog.py 1 lion=Aslan "tiger=Kaplan|fil kulağı üstüne biniyordu"

The first argument is the sheet number. Each following argument is
name=Turkish name in reading order (the same names given to cut_sheet.py),
optionally followed by | and a note. A note makes the entry "needs review",
and so does a failed automatic check: joined to a neighbour, cut by the
sheet border, more than one piece, haze, missing margin. Results go into
docs/animal-art/cut/report.json and docs/animal-art/katalog-<n>.png, which
shows every animal on a light and a dark background so halos and holes are
easy to spot.
"""
import json
import pathlib
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "animal-art" / "cut"
DOCS = ROOT / "docs" / "animal-art"
FONTS = ROOT / "assets" / "google_fonts"
CELL, PAD, COLUMNS = 360, 16, 5


def automatic_checks(picture: Image.Image, record: dict) -> dict:
    alpha = np.asarray(picture.getchannel("A")) if "A" in picture.getbands() else None
    if alpha is None:
        return {"rgba": False}
    border = 12
    return {
        "size_512": picture.size == (512, 512),
        "rgba": picture.mode == "RGBA",
        "background_clear": bool((alpha == 0).mean() > 0.2),
        "body_solid": bool((alpha == 255).mean() > 0.06),
        "corners_clear": bool(all(alpha[y, x] == 0 for y in (0, 511) for x in (0, 511))),
        "margin_kept": bool(alpha[:border].max() == 0 and alpha[-border:].max() == 0
                            and alpha[:, :border].max() == 0 and alpha[:, -border:].max() == 0),
        "no_haze": bool(((alpha > 0) & (alpha < 40)).mean() < 0.02),
        "not_joined": not record["touching_neighbour"],
        "inside_sheet": not record["touches_sheet_edge"],
        "one_piece": record["pieces"] == 1,
    }


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    number, entries = int(sys.argv[1]), []
    for arg in sys.argv[2:]:
        name, _, rest = arg.partition("=")
        turkish, _, note = rest.partition("|")
        entries.append((name, turkish, note.strip()))

    report_path = OUT / "report.json"
    report = json.loads(report_path.read_text(encoding="utf-8"))
    bold = ImageFont.truetype(str(FONTS / "Nunito-ExtraBold.ttf"), 24)
    regular = ImageFont.truetype(str(FONTS / "Nunito-SemiBold.ttf"), 16)

    row_height = CELL * 2 + 92
    rows = (len(entries) + COLUMNS - 1) // COLUMNS
    sheet = Image.new("RGB", (PAD + COLUMNS * (CELL + PAD), PAD + rows * (row_height + PAD)), "#FFFBF5")
    draw = ImageDraw.Draw(sheet)
    failed, keys = [], []
    for i, (name, turkish, note) in enumerate(entries):
        key = f"s{number:02d}_p{i + 1:02d}_{name}"
        keys.append(key)
        record = report[key]
        x = PAD + (i % COLUMNS) * (CELL + PAD)
        y = PAD + (i // COLUMNS) * (row_height + PAD)
        record.update({"name_tr": turkish, "note": note})
        if record.get("status") == "not_cut":
            draw.text((x + 4, y + 4), f"{turkish}: KESİLEMEDİ", font=bold, fill="#C0392B")
            continue
        picture = Image.open(OUT / f"{key}.png")
        checks = automatic_checks(picture, record)
        bad = [k for k, v in checks.items() if not v]
        # A note starting with "OK:" records that a person looked at the
        # flagged point and found the cut correct.
        waived = note.startswith("OK:")
        record.update({"checks": checks,
                       "status": "ok" if waived or not (note or bad) else "needs_review"})
        if bad and not waived:
            failed.append((key, bad))
        small = picture.resize((CELL, CELL), Image.LANCZOS)
        for k, background in enumerate(("#FFE3B8", "#26232B")):
            tile = Image.new("RGB", (CELL, CELL), background)
            tile.paste(small, (0, 0), small)
            sheet.paste(tile, (x, y + k * CELL))
        draw.text((x + 4, y + 2 * CELL + 4), f"{turkish}  ·  {name}", font=bold, fill="#3B2A20")
        problem = record["status"] != "ok"
        label = ("İNCELE: " + (note or ", ".join(bad))) if problem else ("tamam" + (f" ({note[3:].strip()})" if note else ""))
        draw.text((x + 4, y + 2 * CELL + 38), label[:48], font=regular,
                  fill="#C0392B" if problem else "#5A7A3A")
        w, h = record["source_pixels"]
        draw.text((x + 4, y + 2 * CELL + 62),
                  f"{key}.png · {w}x{h} px · {record['bytes'] // 1024} KB",
                  font=regular, fill="#8A6B55")
    DOCS.mkdir(parents=True, exist_ok=True)
    target = DOCS / f"katalog-{number:02d}.png"
    sheet.save(target)
    report_path.write_text(json.dumps(report, indent=1, ensure_ascii=False), encoding="utf-8")
    ok = sum(1 for k in keys if report[k].get("status") == "ok")
    print(f"{ok} ok, {len(keys) - ok} need review; wrote {target.relative_to(ROOT)}")
    for key, checks in failed:
        print("  automatic check failed:", key, checks)
    return 0


if __name__ == "__main__":
    sys.exit(main())
