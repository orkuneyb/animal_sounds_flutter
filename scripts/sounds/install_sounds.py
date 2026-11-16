"""Puts the approved sounds into the app and sets the rejected ones aside.

Usage (from the project root):
    python scripts/sounds/install_sounds.py                  approved sounds with a checked licence
    python scripts/sounds/install_sounds.py --with-doubtful  also approved ones whose licence or species is unverified

Reads sounds_manifest.json and reviews.json in animal-sound-research.

Approved: the MP3 is copied to assets/animal_sounds/<id>.mp3. An existing
file there is never overwritten. The credit (author, licence, source,
changes) is added to docs/credits/credits.json and, in short form, to
assets/credits.json, which the app's "Sources and licences" page shows.

Rejected: the MP3 and its original move to animal-sound-research/rejected/<id>/,
the choice is taken off the selection list and noted in rejected/rejected.json
and findings.json, so the animal simply stays without a sound.

Pending sounds are left alone. Run build_manifest.py afterwards.
"""
import json
import pathlib
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE = ROOT / "animal-sound-research"
SOUNDS = ROOT / "assets" / "animal_sounds"
MASTER = ROOT / "docs" / "credits" / "credits.json"
IN_APP = ROOT / "assets" / "credits.json"
PLACE = {"Wikimedia Commons": "Wikimedia Commons", "Freesound": "Freesound",
         "Freesound (Wikimedia Commons kopyası)": "Freesound"}


def load(path: pathlib.Path, default):
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else default


def save(path: pathlib.Path, data) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8", newline="\n")


def main() -> int:
    with_doubtful = "--with-doubtful" in sys.argv
    manifest = load(BASE / "sounds_manifest.json", [])
    reviews = load(BASE / "reviews.json", {})
    selections = load(BASE / "selections.json", [])
    findings = load(BASE / "findings.json", {})
    rejected = load(BASE / "rejected" / "rejected.json", [])
    master, in_app = load(MASTER, []), load(IN_APP, [])
    installed, held, set_aside = [], [], []

    for row in manifest:
        animal, status = row["animal_id"], reviews.get(row["animal_id"], {}).get("status")
        if not row["file"]:
            continue
        if status == "approved":
            if row["state"] != "processed" and not with_doubtful:
                held.append(animal)
                continue
            target = SOUNDS / f"{animal}.mp3"
            source = BASE / row["file"]
            if target.exists() and target.read_bytes() != source.read_bytes():
                sys.exit(f"{target.name} already exists with other content; not overwritten")
            shutil.copyfile(source, target)
            author = row["author"] if PLACE[row["source"]] in row["author"] else f"{row['author']} ({PLACE[row['source']]})"
            licence = row["license"].replace(" (beyan)", "")
            credit = {"animal": animal, "kind": "sound", "author": author, "license": licence,
                      "license_url": row["license_url"]}
            full = {**credit, "source_page": row["source_page"], "file_url": row["original_url"],
                    "changes": "trimmed, volume adjusted, converted to MP3"}
            if row["sound_type"] != "REAL_ANIMAL_SOUND":
                full["note"] = "movement sound of the animal, not its call"
            if row["state"] != "processed":
                full["note"] = "licence or species could not be verified at the source; approved by the owner"
            master[:] = [c for c in master if not (c["animal"] == animal and c["kind"] == "sound")] + [full]
            in_app[:] = [c for c in in_app if not (c["animal"] == animal and c["kind"] == "sound")] + [credit]
            installed.append(animal)
        elif status == "rejected":
            folder = BASE / "rejected" / animal
            folder.mkdir(parents=True, exist_ok=True)
            for item in (row["file"], row["original"]):
                if (BASE / item).exists():
                    shutil.move(str(BASE / item), str(folder / pathlib.Path(item).name))
            leftover = BASE / "originals" / animal
            if leftover.exists() and not any(leftover.iterdir()):
                leftover.rmdir()
            selections[:] = [e for e in selections if e["animal_id"] != animal]
            rejected.append({"animal_id": animal, "file": f"rejected/{animal}/{animal}.mp3", "source": row["source_page"],
                             "license": row["license"], "recorded_species": row["recorded_species"],
                             "reason": "Kontrol sayfasında reddedildi; yeniden araştırılmayacak.",
                             "decided": reviews[animal].get("decided")})
            findings[animal] = {"reason": f"Bulunan kayıt ({row['source']}, {row['author']}) kontrol sayfasında reddedildi; "
                                          "kararınız gereği yeniden araştırılmayacak, hayvan sessiz kalıyor.",
                                "cc_by_sa_candidates": [], "environment_sound_considered": False}
            set_aside.append(animal)

    key = lambda c: (c["animal"], c["kind"])  # noqa: E731
    save(MASTER, sorted(master, key=key))
    save(IN_APP, sorted(in_app, key=key))
    save(BASE / "selections.json", selections)
    save(BASE / "findings.json", findings)
    save(BASE / "rejected" / "rejected.json", rejected)
    print(len(installed), "installed:", " ".join(installed))
    print(len(held), "approved but held (unverified licence or species):", " ".join(held))
    print(len(set_aside), "rejected and set aside:", " ".join(set_aside))
    return 0


if __name__ == "__main__":
    sys.exit(main())
