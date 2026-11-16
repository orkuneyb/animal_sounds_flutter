"""Installs approved photos and sounds into the app and records their sources.

Usage (from the project root):
    python scripts/assets/install.py --photos lion tiger ... --sounds lion cat ...

Photos come from build/photo_out/<name>.png (written by make_photo.py) and
sounds from build/pilot_sounds/<name>.mp3. Each installed file is copied into
assets/ and its source, author and licence are written to
docs/credits/credits.json (the full record, with URLs) and
assets/credits.json (what the in-app "Sources and licences" page shows).
Safe to run again; entries are replaced, never duplicated.
"""
import json
import pathlib
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
PHOTO_OUT = ROOT / "build" / "photo_out"
SOUND_OUT = ROOT / "build" / "pilot_sounds"
MASTER = ROOT / "docs" / "credits" / "credits.json"
IN_APP = ROOT / "assets" / "credits.json"


def load(path: pathlib.Path, default):
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else default


def short_licence(text: str) -> str:
    """One short licence name per entry, whatever note the source carried."""
    text = (text or "").strip()
    return "Public domain" if text.lower().startswith("public domain") else text


def key(entry: dict) -> tuple:
    return (entry["animal"], entry["kind"])


def main() -> int:
    args = sys.argv[1:]
    photos, sounds, target = [], [], None
    for arg in args:
        if arg == "--photos":
            target = photos
        elif arg == "--sounds":
            target = sounds
        elif target is not None:
            target.append(arg)
    if not photos and not sounds:
        print(__doc__)
        return 1

    entries = {key(e): e for e in load(MASTER, [])}

    photo_sources = load(PHOTO_OUT / "sources.json", {})
    for name in photos:
        source = photo_sources[name]
        shutil.copyfile(PHOTO_OUT / f"{name}.png", ROOT / "assets" / "animal_images" / f"{name}.png")
        entries[(name, "image")] = {
            "animal": name, "kind": "image",
            "author": source["author"], "license": short_licence(source["license"]),
            "license_url": source["license_url"],
            "source_page": source["source_page"], "file_url": source["file_url"],
            "changes": "background removed, cropped, resized",
        }

    sound_sources = {s["animal"]: s for s in load(SOUND_OUT / "sources.json", [])}
    for name in sounds:
        source = sound_sources[name]
        if source.get("status") != "ok":
            raise SystemExit(f"{name}: no usable sound was found")
        shutil.copyfile(SOUND_OUT / f"{name}.mp3", ROOT / "assets" / "animal_sounds" / f"{name}.mp3")
        entries[(name, "sound")] = {
            "animal": name, "kind": "sound",
            "author": source["author"], "license": short_licence(source["license"]),
            "license_url": source.get("license_url", ""),
            "source_page": source["source_page"], "file_url": source.get("file_url", ""),
            "changes": "trimmed, volume adjusted, converted to MP3",
        }

    ordered = sorted(entries.values(), key=lambda e: (e["animal"], e["kind"]))
    MASTER.parent.mkdir(parents=True, exist_ok=True)
    MASTER.write_text(json.dumps(ordered, ensure_ascii=False, indent=1) + "\n",
                      encoding="utf-8", newline="\n")
    in_app = [{k: e[k] for k in ("animal", "kind", "author", "license", "license_url")}
              for e in ordered]
    IN_APP.write_text(json.dumps(in_app, ensure_ascii=False, indent=1) + "\n",
                      encoding="utf-8", newline="\n")
    print(f"installed {len(photos)} photos, {len(sounds)} sounds; "
          f"{len(ordered)} credit entries")
    return 0


if __name__ == "__main__":
    sys.exit(main())
