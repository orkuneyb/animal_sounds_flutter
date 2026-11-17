"""Builds the animal picture library from the cut sheets.

Usage (from the project root, inside the build/venv environment):
    python scripts/assets/build_library.py

Reads docs/animal-art/species.json (one row per unique animal: id, Turkish
name, English name, scientific name, category, chosen drawing, repeated
drawings, how sure the identification is, note) and the cutting results in
docs/animal-art/cut/report.json. Writes, all under docs/animal-art:

  final/<id>.png          drawings that passed every check
  needs-review/<id>.png   drawings with a cutting fault or an unsure name
  archive/<key>.png       repeated drawings of an animal (kept, not used)
  animals.json            the metadata of every animal
  needs-review.md         what a person has to decide
  ses-esleme.md           which animal has a sound in the app and which not
  kontrol-katalogu-N.png  every animal with its Turkish name and file name

Nothing in assets/ or should-cut-animals/ is touched.
"""
import json
import pathlib
import re
import shutil
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
ART = ROOT / "docs" / "animal-art"
CUT = ART / "cut"
FONTS = ROOT / "assets" / "google_fonts"
CELL, LABEL, PER_ROW, PER_PAGE = 216, 62, 8, 40


def app_animals() -> list:
    """Animal ids of the app, in saved order."""
    text = (ROOT / "lib" / "repositories" / "animal_repository.dart").read_text(encoding="utf-8")
    return re.findall(r"^\s*\('([a-z_]+)',\s*AnimalGroup", text, flags=re.M)


def fresh(folder: pathlib.Path) -> pathlib.Path:
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    return folder


def draw_catalogue(animals: list) -> int:
    bold = ImageFont.truetype(str(FONTS / "Nunito-ExtraBold.ttf"), 17)
    small = ImageFont.truetype(str(FONTS / "Nunito-SemiBold.ttf"), 13)
    for old in ART.glob("kontrol-katalogu-*.png"):
        old.unlink()
    pages = [animals[i:i + PER_PAGE] for i in range(0, len(animals), PER_PAGE)]
    for number, page in enumerate(pages, start=1):
        rows = (len(page) + PER_ROW - 1) // PER_ROW
        sheet = Image.new("RGB", (PER_ROW * CELL + 8, rows * (CELL + LABEL) + 8), "#FFFBF5")
        draw = ImageDraw.Draw(sheet)
        for i, animal in enumerate(page):
            x, y = 8 + (i % PER_ROW) * CELL, 8 + (i // PER_ROW) * (CELL + LABEL)
            ok = animal["qc_status"] == "ok"
            tile = Image.new("RGB", (CELL - 8, CELL - 8), "#FFE3B8" if ok else "#F6D2CC")
            picture = Image.open(ROOT / animal["image"]).resize((CELL - 8, CELL - 8), Image.LANCZOS)
            tile.paste(picture, (0, 0), picture)
            sheet.paste(tile, (x, y))
            draw.text((x + 2, y + CELL - 6), animal["name_tr"][:22], font=bold, fill="#3B2A20")
            draw.text((x + 2, y + CELL + 16), f"{animal['id']}.png"[:30], font=small, fill="#8A6B55")
            tag = "tamam" if ok else "İNCELE"
            tag += " · uygulamada var" if animal["app_index"] is not None else " · yeni"
            draw.text((x + 2, y + CELL + 33), tag, font=small, fill="#5A7A3A" if ok else "#C0392B")
        sheet.save(ART / f"kontrol-katalogu-{number}.png")
    return len(pages)


def main() -> int:
    species = json.loads((ART / "species.json").read_text(encoding="utf-8"))
    report = json.loads((CUT / "report.json").read_text(encoding="utf-8"))
    by_position = {key[:7]: key for key in report}
    in_app = app_animals()
    sounds = {p.stem for p in (ROOT / "assets" / "animal_sounds").glob("*.mp3")}

    used, ids = [], set()
    for row in species:
        if row[0] in ids:
            sys.exit(f"{row[0]} listed twice")
        ids.add(row[0])
        used += [row[5]] + row[6]
    missing = sorted(set(by_position) - set(used))
    twice = sorted({k for k in used if used.count(k) > 1})
    unknown = sorted(set(used) - set(by_position))
    if missing or twice or unknown:
        sys.exit(f"drawings not listed: {missing}; listed twice: {twice}; not cut: {unknown}")

    final, review, archive = fresh(ART / "final"), fresh(ART / "needs-review"), fresh(ART / "archive")
    animals = []
    for animal_id, name_tr, name_en, scientific, category, pick, repeats, confidence, note in species:
        cut = report[by_position[pick]]
        reasons = []
        if cut.get("status") != "ok":
            reasons.append("kesim: " + (cut.get("note") or "otomatik kontrol"))
        if confidence == "low":
            reasons.append("tür adı: " + note)
        folder = review if reasons else final
        shutil.copyfile(CUT / f"{by_position[pick]}.png", folder / f"{animal_id}.png")
        for repeat in repeats:
            shutil.copyfile(CUT / f"{by_position[repeat]}.png", archive / f"{by_position[repeat]}.png")
        animals.append({
            "id": animal_id,
            "app_index": in_app.index(animal_id) if animal_id in in_app else None,
            "name_tr": name_tr,
            "name_en": name_en,
            "scientific_name": scientific or None,
            "category": category,
            "image": (folder / f"{animal_id}.png").relative_to(ROOT).as_posix(),
            "source_sheet": cut["sheet"],
            "source_position": cut["position"],
            "source_box": cut.get("source_box"),
            "identification_confidence": confidence,
            "identification_note": note,
            "qc_status": "needs_review" if reasons else "ok",
            "qc_reasons": reasons,
            "qc_note": cut.get("note", ""),
            "repeated_drawings": [f"docs/animal-art/archive/{by_position[r]}.png" for r in repeats],
            "has_sound": animal_id in sounds,
            "sound_file": f"assets/animal_sounds/{animal_id}.mp3" if animal_id in sounds else None,
        })
    (ART / "animals.json").write_text(json.dumps(animals, ensure_ascii=False, indent=1) + "\n",
                                      encoding="utf-8", newline="\n")

    ok = [a for a in animals if a["qc_status"] == "ok"]
    waiting = [a for a in animals if a["qc_status"] != "ok"]
    unsure = [a for a in ok if a["identification_confidence"] == "medium"]
    without_picture = [name for name in in_app if name not in ids]

    lines = ["# İnceleme bekleyenler", "",
             "Bu dosya `scripts/assets/build_library.py` tarafından üretilir.", "",
             f"## Uygulamaya eklenmeyecek, karar bekleyen çizimler ({len(waiting)})", "",
             "| Hayvan | Dosya | Kaynak | Neden |", "|---|---|---|---|"]
    for a in waiting:
        lines.append(f"| {a['name_tr']} | `needs-review/{a['id']}.png` | {a['source_sheet']} #{a['source_position']} "
                     f"| {'; '.join(a['qc_reasons'])} |")
    lines += ["", f"## Adı konmuş ama onayınıza sunulan türler ({len(unsure)})", "",
              "Kesimleri temiz; ad büyük olasılıkla doğru ama benzer bir türle karışabilir.", "",
              "| Verilen ad | Dosya | Kaynak | Not |", "|---|---|---|---|"]
    for a in unsure:
        lines.append(f"| {a['name_tr']} | `final/{a['id']}.png` | {a['source_sheet']} #{a['source_position']} "
                     f"| {a['identification_note']} |")
    merged = [a for a in animals if a["repeated_drawings"]]
    lines += ["", f"## Tekrar sayılan çizimler ({sum(len(a['repeated_drawings']) for a in merged)})", "",
              "Aynı hayvanın ikinci çizimi sayılıp arşive alındı. Ayrı bir tür olarak düşündükleriniz varsa söyleyin.", "",
              "| Hayvan | Kullanılan | Arşive alınan | Not |", "|---|---|---|---|"]
    for a in merged:
        archived = ", ".join(f"`{pathlib.PurePosixPath(p).name}`" for p in a["repeated_drawings"])
        lines.append(f"| {a['name_tr']} | {a['source_sheet']} #{a['source_position']} | {archived} "
                     f"| {a['identification_note']} |")
    lines += ["", f"## Uygulamada olup yeni çizimi bulunmayan hayvanlar ({len(without_picture)})", ""]
    lines += [f"- `{name}`" for name in without_picture]
    (ART / "needs-review.md").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")

    lines = ["# Ses eşleme listesi", "",
             "Bu dosya `scripts/assets/build_library.py` tarafından üretilir. Hiçbir ses dosyası "
             "oluşturulmadı, değiştirilmedi ya da yeniden adlandırılmadı.", "",
             "Beklenen dosya adı her hayvan için `assets/animal_sounds/<id>.mp3` biçimindedir.", "",
             "| Hayvan | id | Uygulamada | Ses dosyası |", "|---|---|---|---|"]
    for a in sorted(animals, key=lambda a: (not a["has_sound"], a["name_tr"])):
        lines.append(f"| {a['name_tr']} | `{a['id']}` | {'var' if a['app_index'] is not None else 'yeni'} "
                     f"| {('`' + a['id'] + '.mp3` mevcut') if a['has_sound'] else 'YOK — eklenecek'} |")
    for name in without_picture:
        lines.append(f"| ({name}) | `{name}` | var, yeni çizimi yok "
                     f"| {('`' + name + '.mp3` mevcut') if name in sounds else 'YOK'} |")
    (ART / "ses-esleme.md").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")

    pages = draw_catalogue(animals)
    print(f"{len(report)} drawings, {len(animals)} unique animals, "
          f"{sum(len(r[6]) for r in species)} repeats archived")
    print(f"{len(ok)} passed ({len(unsure)} with a name to confirm), {len(waiting)} need review")
    print(f"in the app already: {sum(1 for a in animals if a['app_index'] is not None)} of {len(in_app)}; "
          f"no new drawing for: {without_picture}")
    print(f"with a sound: {sum(1 for a in animals if a['has_sound'])}; "
          f"final folder {sum(p.stat().st_size for p in final.glob('*.png')) // 1024} KB; {pages} catalogue pages")
    return 0


if __name__ == "__main__":
    sys.exit(main())
