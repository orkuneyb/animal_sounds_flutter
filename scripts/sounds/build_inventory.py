"""Lists every animal of the app that has no sound yet, as a research inventory.

Usage (from the project root):
    python scripts/sounds/build_inventory.py

Reads docs/animal-art/animals.json and writes
animal-sound-research/reports/inventory.json and inventory.md. Research
notes already written for an animal (target species, state, notes) are kept
when the script runs again. Nothing in assets/ is touched.
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "animal-sound-research" / "reports"
PILOT = ["gibbon", "jaguar", "raccoon", "nightingale", "hoopoe", "cicada", "katydid", "walrus",
         "alpaca", "butterfly"]
SOURCES = {
    "birds": ["Wikimedia Commons", "xeno-canto", "Freesound", "Internet Archive"],
    "other": ["Wikimedia Commons", "Freesound", "Internet Archive", "xeno-canto (insects, frogs, bats)"],
}


def main() -> int:
    animals = json.loads((ROOT / "docs" / "animal-art" / "animals.json").read_text(encoding="utf-8"))
    path = OUT / "inventory.json"
    old = {r["animal_id"]: r for r in json.loads(path.read_text(encoding="utf-8"))} if path.exists() else {}
    rows = []
    for a in animals:
        if a["app_index"] is None or a["has_sound"]:
            continue
        kept = old.get(a["id"], {})
        rows.append({
            "animal_id": a["id"],
            "app_index": a["app_index"],
            "name_tr": a["name_tr"],
            "name_en": a["name_en"],
            "category": a["category"],
            "scientific_name": a["scientific_name"],
            "name_confidence": a["identification_confidence"],
            "image": f"assets/animal_images/{a['id']}.png",
            "expected_file": f"{a['id']}.mp3",
            "pilot": a["id"] in PILOT,
            "sources_to_try": SOURCES["birds" if a["category"] == "birds" else "other"],
            "target_species": kept.get("target_species", a["scientific_name"]),
            "sound_type": kept.get("sound_type", "TO_RESEARCH"),
            "research_state": kept.get("research_state", "not_started"),
            "notes": kept.get("notes", ""),
        })
    rows.sort(key=lambda r: r["app_index"])
    OUT.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(rows, ensure_ascii=False, indent=1) + "\n", encoding="utf-8", newline="\n")
    lines = ["# Ses araştırma envanteri", "",
             f"Sesi olmayan {len(rows)} hayvan. Bu dosya `scripts/sounds/build_inventory.py` tarafından üretilir.", "",
             "| # | id | Hayvan | İngilizce | Kategori | Hedef tür | Ad güveni | Pilot | Durum | Ses türü |",
             "|---|---|---|---|---|---|---|---|---|---|"]
    for n, r in enumerate(rows, start=1):
        lines.append(f"| {n} | `{r['animal_id']}` | {r['name_tr']} | {r['name_en']} | {r['category']} "
                     f"| {r['target_species'] or '—'} | {r['name_confidence']} | {'evet' if r['pilot'] else ''} "
                     f"| {r['research_state']} | {r['sound_type']} |")
    (OUT / "inventory.md").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    print(len(rows), "animals without a sound;", sum(r["pilot"] for r in rows), "in the pilot")
    return 0


if __name__ == "__main__":
    sys.exit(main())
