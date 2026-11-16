"""Puts the approved drawings of animals the app already has into the app.

Usage (from the project root):
    python scripts/assets/install_art.py

For every animal in docs/animal-art/animals.json that is already in the app
(it has an app_index) and passed quality control, copies its picture from
docs/animal-art/final/ over assets/animal_images/<id>.png. The id, the saved
index and the sound stay as they are. Photo credits of replaced pictures are
removed from the credit files, because the photo is no longer shipped; sound
credits are kept. Animals that are new to the app, or whose drawing still
needs review, are not touched. Run it again any time; it only copies.
"""
import json
import pathlib
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
ART = ROOT / "docs" / "animal-art"
IMAGES = ROOT / "assets" / "animal_images"
CREDIT_FILES = [ROOT / "docs" / "credits" / "credits.json", ROOT / "assets" / "credits.json"]


def main() -> int:
    animals = json.loads((ART / "animals.json").read_text(encoding="utf-8"))
    installed, waiting = [], []
    for animal in animals:
        if animal["app_index"] is None:
            continue
        if animal["qc_status"] != "ok":
            waiting.append(animal["id"])
            continue
        shutil.copyfile(ROOT / animal["image"], IMAGES / f"{animal['id']}.png")
        installed.append(animal["id"])

    for path in CREDIT_FILES:
        credits = json.loads(path.read_text(encoding="utf-8"))
        kept = [c for c in credits if not (c["kind"] == "image" and c["animal"] in installed)]
        path.write_text(json.dumps(kept, ensure_ascii=False, indent=1) + "\n",
                        encoding="utf-8", newline="\n")
        print(f"{path.relative_to(ROOT)}: {len(credits) - len(kept)} photo credits removed, {len(kept)} kept")

    print(f"installed {len(installed)} pictures: {' '.join(installed)}")
    print(f"left as they were (drawing needs review): {' '.join(waiting) or '-'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
