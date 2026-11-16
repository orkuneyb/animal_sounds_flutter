"""Adds chosen Freesound recordings to the selection list.

Usage (from the project root, with the key in the environment):
    FREESOUND_API_KEY=... python scripts/sounds/add_freesound.py

Reads animal-sound-research/reports/freesound_choices.json, a hand-kept list
of [animal id, sound id, sound type, folder, recorded species, how the
species is known, note]. For each it asks Freesound for the sound's own
record (name, author, licence, description) and writes an entry into
selections.json, replacing an earlier entry of the same animal; the replaced
file is moved to rejected/<animal>/ with the reason. The licence comes
straight from Freesound, which is where the recording was published. The
download address is Freesound's high-quality preview, because the original
upload can only be fetched after signing in.
"""
import json
import os
import pathlib
import shutil
import sys
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE = ROOT / "animal-sound-research"
TYPES = {"real": "REAL_ANIMAL_SOUND", "move": "ENVIRONMENT_OR_MOVEMENT_SOUND"}


def sound(number: int) -> dict:
    key = os.environ.get("FREESOUND_API_KEY") or sys.exit("set FREESOUND_API_KEY first")
    url = (f"https://freesound.org/apiv2/sounds/{number}/?fields=id,name,description,license,username,url,"
           "duration,previews,type,samplerate,created")
    request = urllib.request.Request(url, headers={"Authorization": f"Token {key}",
                                                   "User-Agent": "animal-sound-research/1.0"})
    with urllib.request.urlopen(request, timeout=40) as answer:
        return json.loads(answer.read().decode("utf-8"))


def licence(url: str) -> tuple:
    if "publicdomain/zero" in url:
        return "CC0", "https://creativecommons.org/publicdomain/zero/1.0/"
    if "/licenses/by/" in url:
        version = url.rstrip("/").split("/")[-1]
        return f"CC BY {version}", f"https://creativecommons.org/licenses/by/{version}/"
    sys.exit(f"licence not usable: {url}")


def main() -> int:
    choices = json.loads((BASE / "reports" / "freesound_choices.json").read_text(encoding="utf-8"))
    path = BASE / "selections.json"
    entries = json.loads(path.read_text(encoding="utf-8"))
    rejected_path = BASE / "rejected" / "rejected.json"
    rejected = json.loads(rejected_path.read_text(encoding="utf-8")) if rejected_path.exists() else []
    for animal, number, kind, folder, species, species_check, note in choices:
        old = next((e for e in entries if e["animal_id"] == animal), None)
        if old and str(number) in old.get("page_url", ""):
            continue
        info = sound(number)
        name, link = licence(info["license"])
        if old:
            target = BASE / "rejected" / animal
            target.mkdir(parents=True, exist_ok=True)
            for item in (old.get("file"), old.get("original")):
                if item and (BASE / item).exists():
                    shutil.move(str(BASE / item), str(target / pathlib.Path(item).name))
            leftover = BASE / "originals" / animal
            if leftover.exists() and not any(leftover.iterdir()):
                leftover.rmdir()
            rejected.append({"animal_id": animal, "file": f"rejected/{animal}/{pathlib.Path(old.get('file') or '').name}",
                             "source": old.get("page_url"), "license": old.get("licence"),
                             "reason": "Kaynağı ve lisansı daha güvenilir bir kayıt bulundu (Freesound).",
                             "replaced_by": info["url"]})
            entries.remove(old)
        description = " ".join((info.get("description") or "").split())
        attribution = f"{info['username']} (Freesound), {name}" + ("" if name == "CC0" else " — kısaltıldı")
        entries.append({
            "animal_id": animal, "key": animal, "source": "Freesound", "title": info["name"], "page_url": info["url"],
            "file_url": info["previews"]["preview-hq-ogg"], "source_seconds": info["duration"],
            "sound_type": TYPES[kind], "folder": folder, "species": species, "author": info["username"],
            "licence": name, "licence_url": link,
            "origin": f"Freesound ses {info['id']}, yüklenme {info['created'][:10]}. Kaydedenin açıklaması: {description[:300]}",
            "licence_check": "Lisans doğrudan Freesound'un kendi kaydından okundu (kaydın yayımlandığı yer).",
            "attribution": attribution, "species_check": species_check, "notes": note,
            "preview_only": True,
        })
        print(animal, number, name, info["name"][:50].encode("ascii", "backslashreplace").decode())
        time.sleep(1.1)
    path.write_text(json.dumps(entries, ensure_ascii=False, indent=1) + "\n", encoding="utf-8", newline="\n")
    rejected_path.write_text(json.dumps(rejected, ensure_ascii=False, indent=1) + "\n", encoding="utf-8", newline="\n")
    print(len(entries), "selections")
    return 0


if __name__ == "__main__":
    sys.exit(main())
