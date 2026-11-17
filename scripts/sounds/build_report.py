"""Writes the Turkish summary report of the sound research from the manifest.

Usage (from the project root):
    python scripts/sounds/build_report.py

Reads animal-sound-research/sounds_manifest.json and writes
animal-sound-research/reports/rapor.md.
"""
import collections
import json
import pathlib
import sys

BASE = pathlib.Path(__file__).resolve().parents[2] / "animal-sound-research"
STATUS = {"pending": "bekliyor", "approved": "onaylandı", "rejected": "reddedildi", "research_again": "tekrar araştır"}


def main() -> int:
    rows = json.loads((BASE / "sounds_manifest.json").read_text(encoding="utf-8"))
    ready = [r for r in rows if r["state"] == "processed"]
    review = [r for r in rows if r["state"] == "needs_review"]
    missing = [r for r in rows if r["state"] == "no_usable_recording"]
    licences = collections.Counter(r["license"] for r in ready)
    free = sum(n for name, n in licences.items() if name.startswith(("CC0", "Public")))
    lines = [
        "# Ses araştırması raporu", "",
        "Uygulamanın ses klasörüne (`assets/animal_sounds`), koduna ve görsellerine dokunulmadı; her şey "
        "`animal-sound-research/` içinde. Yalnızca Wikimedia Commons tarandı (bir kayıt Freesound kökenli): "
        "Freesound ve xeno-canto aramaları API anahtarı istiyor.", "",
        "Kayıtları dinleyen bir insan değil, program işledi. \"Doğrulandı\" yalnızca kaynak sayfası ve lisansın "
        "kökeninde kontrol edildiği anlamına gelir; sesin doğru ve temiz olup olmadığına kontrol sayfasında siz "
        "karar verirsiniz.", "",
        "## Sonuç", "", "| | Sayı |", "|---|---|",
        f"| Araştırılan hayvan | {len(rows)} |",
        f"| Gerçek ses kaydı hazır (lisansı doğrulanmış) | {len(ready)} |",
        f"| İnceleme klasöründe (lisans ya da tür şüpheli) | {len(review)} |",
        "| Ortam / hareket sesi | 0 |",
        f"| Uygun ses bulunamayan | {len(missing)} |",
        f"| Hazır kayıtlarda CC0 / kamu malı | {free} |",
        f"| Hazır kayıtlarda CC BY (atıf gerekir) | {len(ready) - free} |",
        f"| CC BY-SA adayı olduğu için ayrı listeye alınan hayvan | "
        f"{sum(1 for r in missing if 'CC BY-SA' in r['notes'])} |", "",
        "## Entegrasyona aday kayıtlar", "",
        "| Hayvan | id | Kayıttaki tür | Süre | Lisans | Kararınız | Not |", "|---|---|---|---|---|---|---|"]
    for r in ready:
        lines.append(f"| {r['name_tr']} | `{r['animal_id']}` | {r['recorded_species']} | "
                     f"{str(r['seconds']).replace('.', ',')} sn | {r['license']} | {STATUS[r['review_status']]} | {r['notes']} |")
    lines += ["", "## İnceleme klasöründekiler", "",
              "Bunlar dinlenebilir ama lisansı ya da türü kaynağında doğrulanamadı; onaylasanız da bu risk sürer.", "",
              "| Hayvan | id | Lisans | Kararınız | Neden şüpheli |", "|---|---|---|---|---|"]
    for r in review:
        doubt = r["license_check"] if "DOĞRULANAMADI" in r["license_check"] else r["species_check"]
        lines.append(f"| {r['name_tr']} | `{r['animal_id']}` | {r['license']} | {STATUS[r['review_status']]} | {doubt} |")
    lines += ["", "## Uygun ses bulunamayanlar", "", "| Hayvan | id | Neden |", "|---|---|---|"]
    for r in missing:
        lines.append(f"| {r['name_tr']} | `{r['animal_id']}` | {r['notes']} |")
    lines += ["", "## Dosyalar", "",
              "- `sounds_manifest.json` — her hayvan için bir kayıt; sesi olmayanlarda `file: null`",
              "- `credits.json` — kaynak, yazar, lisans, atıf metni, yapılan düzenlemeler",
              "- `missing_sounds.json` — bulunamayanlar ve CC BY-SA aday listeleri",
              "- `rejected/` — reddedilen kayıtlar ve nedenleri",
              "- `originals/<id>/` — değiştirilmemiş orijinaller (SHA-256 manifestte)",
              "- `reviews.json` — kontrol sayfasındaki kararlarınız", "",
              "## Kontrol sayfası", "", "```", "build/venv/Scripts/python scripts/sounds/review_server.py", "```", "",
              "Sonra tarayıcıda `http://127.0.0.1:8765`."]
    (BASE / "reports" / "rapor.md").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    print(len(ready), "ready,", len(review), "in review,", len(missing), "missing;", free, "free,", len(ready) - free, "CC BY")
    return 0


if __name__ == "__main__":
    sys.exit(main())
