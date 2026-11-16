"""Records, for every searched animal without a chosen recording, what the search found.

Usage (from the project root):
    python scripts/sounds/build_findings.py

Reads reports/queries.json, reports/search/<id>.json and selections.json in
animal-sound-research and rewrites findings.json: the reason no recording
could be used and the CC BY-SA recordings set aside for separate review.
Hand-written reasons in reports/finding_notes.json ({animal id: text}) are
put in front of the automatic one. Entries of animals that were not part of
the batch search are kept as they are.
"""
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from search_batch import BASE, OUT, licence_class, relevant  # noqa: E402

KEYS = "Freesound da tarandı; orada da uygun, türü belli bir kayıt çıkmadı. Xeno-canto API anahtarı istediği için taranamadı."


def main() -> int:
    queries = json.loads((BASE / "reports" / "queries.json").read_text(encoding="utf-8"))
    chosen = {e["animal_id"] for e in json.loads((BASE / "selections.json").read_text(encoding="utf-8"))}
    notes_path = BASE / "reports" / "finding_notes.json"
    notes = json.loads(notes_path.read_text(encoding="utf-8")) if notes_path.exists() else {}
    path = BASE / "findings.json"
    findings = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
    for animal in chosen:
        findings.pop(animal, None)
    for animal, phrases in queries.items():
        source = OUT / f"{animal}.json"
        if animal in chosen or not source.exists():
            continue
        rows = [r for r in json.loads(source.read_text(encoding="utf-8")) if relevant(r, phrases)]
        share = [r for r in rows if licence_class(r["licence"]) == "sa"]
        reason = "Wikimedia Commons'ta ticari kullanıma uygun lisanslı (CC0, kamu malı, CC BY) ve türü doğrulanabilir kayıt bulunamadı."
        if share:
            reason += f" Hayvanın adı geçen {len(share)} CC BY-SA kayıt ayrı listeye alındı (içlerinde konuyla ilgisiz olanlar olabilir)."
        if animal in notes:
            reason = notes[animal] + " " + reason
        findings[animal] = {
            "reason": reason + " " + KEYS,
            "cc_by_sa_candidates": [{k: r[k] for k in ("title", "page", "seconds", "licence", "author", "description")}
                                    for r in share[:30]],
            "environment_sound_considered": False,
        }
    path.write_text(json.dumps(findings, ensure_ascii=False, indent=1) + "\n", encoding="utf-8", newline="\n")
    print(len(findings), "animals without a usable recording;",
          sum(1 for f in findings.values() if f["cc_by_sa_candidates"]), "have CC BY-SA candidates")
    return 0


if __name__ == "__main__":
    sys.exit(main())
