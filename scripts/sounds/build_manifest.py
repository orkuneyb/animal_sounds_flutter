"""Writes the manifest, credits and missing-sound lists of the sound research.

Usage (from the project root):
    python scripts/sounds/build_manifest.py

Reads reports/inventory.json (every animal without a sound),
selections.json (chosen recordings), findings.json (what the research of an
animal turned up when no recording could be used) and reviews.json (the
owner's decisions from the review page), all inside animal-sound-research.
Writes there:

  sounds_manifest.json   one entry per animal; "file" is null when there is none
  credits.json           source, author, licence and attribution of every file
  missing_sounds.json    animals without a usable recording, and why
  reports/inventory.*    refreshed with the research state

"verified" only says that the source page and the licence were checked at
their origin. Nobody has listened yet: "review_status" stays "pending"
until the owner decides on the review page.
"""
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE = ROOT / "animal-sound-research"


def load(name: str, default):
    path = BASE / name
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else default


def save(name: str, data) -> None:
    (BASE / name).write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8", newline="\n")


def main() -> int:
    inventory = load("reports/inventory.json", [])
    chosen = {e["animal_id"]: e for e in load("selections.json", []) if e.get("file")}
    findings = load("findings.json", {})
    reviews = load("reviews.json", {})
    files = [e["file"] for e in chosen.values()]
    hashes = [e["original_sha256"] for e in chosen.values()]
    if len(set(files)) != len(files) or len(set(hashes)) != len(hashes):
        sys.exit("the same recording is assigned to two animals")

    manifest, credits, missing = [], [], []
    for row in inventory:
        animal = row["animal_id"]
        entry = chosen.get(animal)
        review = reviews.get(animal, {})
        base = {"animal_id": animal, "name_tr": row["name_tr"], "name_en": row["name_en"],
                "category": row["category"], "name_confidence": row["name_confidence"], "pilot": row["pilot"]}
        if entry:
            in_review = entry["folder"] != "processed"
            manifest.append({
                **base, "sound_type": entry["sound_type"], "file": entry["file"],
                "state": "needs_review" if in_review else "processed",
                "recorded_species": entry["species"], "seconds": entry["seconds"],
                "lufs": entry["lufs"], "peak_db": entry["peak_db"],
                "source": entry["source"], "source_page": entry["page_url"], "original_url": entry["file_url"],
                "original": entry["original"], "original_sha256": entry["original_sha256"],
                "author": entry["author"], "license": entry["licence"], "license_url": entry["licence_url"],
                "attribution": entry["attribution"], "downloaded": entry["downloaded"], "edits": entry["edits"],
                "origin": entry["origin"], "license_check": entry["licence_check"],
                "species_check": entry["species_check"], "notes": entry["notes"],
                "verified": not in_review,
                "review_status": review.get("status", "pending"), "review_note": review.get("note", ""),
            })
            credits.append({k: manifest[-1][k] for k in (
                "animal_id", "file", "sound_type", "recorded_species", "source", "source_page", "original_url",
                "author", "license", "license_url", "attribution", "downloaded", "edits")})
            row["research_state"], row["sound_type"] = manifest[-1]["state"], entry["sound_type"]
            row["target_species"] = entry["species"]
        else:
            found = findings.get(animal)
            manifest.append({**base, "sound_type": None, "file": None,
                             "state": "no_usable_recording" if found else "not_researched",
                             "verified": False, "review_status": review.get("status", "pending"),
                             "review_note": review.get("note", ""),
                             "notes": found["reason"] if found else ""})
            if found:
                missing.append({**base, **found})
                row["research_state"] = "no_usable_recording"
    save("sounds_manifest.json", manifest)
    save("credits.json", credits)
    save("missing_sounds.json", missing)
    save("reports/inventory.json", inventory)
    subprocess.run([sys.executable, str(pathlib.Path(__file__).with_name("build_inventory.py"))], check=True)
    print(len(manifest), "animals;", len(credits), "with a file;", len(missing), "researched without a usable recording;",
          sum(1 for m in manifest if m["state"] == "not_researched"), "not researched yet")
    return 0


if __name__ == "__main__":
    sys.exit(main())
