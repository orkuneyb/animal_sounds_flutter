"""Collects everything needed for the Play Console into one folder.

Usage (from the project root):
    python scripts/store_assets/package.py

Reads scripts/store_assets/listing.json (short and full description per
language), copy.json (app title), docs/release-notes/<version>.md,
docs/store-assets/<locale>/, docs/icon/play_store_icon_512.png and the built
bundle. Writes docs/play-store/<version>/ with one folder per language and
rewrites store_listings.txt. Texts longer than Play allows stop the script.
"""
import json
import pathlib
import re
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
HERE = pathlib.Path(__file__).resolve().parent
ASSETS = ROOT / "docs" / "store-assets"
NAMES = {"en-US": "English (en-US)", "tr-TR": "Türkçe (tr-TR)", "ru-RU": "Русский (ru-RU)",
         "pt-BR": "Português – Brasil (pt-BR)", "hi-IN": "हिन्दी (hi-IN)", "es-ES": "Español (es-ES)",
         "ar-SA": "العربية (ar)", "de-DE": "Deutsch (de-DE)"}
LIMITS = {"title": 30, "short": 80, "full": 4000}


def main() -> int:
    listing = json.loads((HERE / "listing.json").read_text(encoding="utf-8"))
    copy = json.loads((HERE / "copy.json").read_text(encoding="utf-8"))
    version = re.search(r"^version:\s*([\d.]+)\+(\d+)", (ROOT / "pubspec.yaml").read_text(encoding="utf-8"), re.M)
    name, code = version.group(1), version.group(2)
    out = ROOT / "docs" / "play-store" / name
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)

    problems, summary = [], []
    plain = ["=" * 80, "GOOGLE PLAY STORE LISTINGS", "=" * 80, ""]
    for locale, texts in listing.items():
        title = copy[locale]["title"]
        for kind, text in (("title", title), ("short", texts["short"]), ("full", texts["full"])):
            if len(text) > LIMITS[kind]:
                problems.append(f"{locale} {kind}: {len(text)} characters, limit {LIMITS[kind]}")
        folder = out / locale
        folder.mkdir()
        (folder / "1-uygulama-adi.txt").write_text(title + "\n", encoding="utf-8")
        (folder / "2-kisa-aciklama.txt").write_text(texts["short"] + "\n", encoding="utf-8")
        (folder / "3-tam-aciklama.txt").write_text(texts["full"] + "\n", encoding="utf-8")
        source = ASSETS / locale
        shutil.copyfile(source / "feature_graphic.png", folder / "4-feature-graphic-1024x500.png")
        for i in range(1, 9):
            shutil.copyfile(source / f"phone_{i:02d}.png", folder / f"5-telefon-{i:02d}.png")
        video = source / "promo_video.mp4"
        if video.exists():
            shutil.copyfile(video, folder / "6-tanitim-videosu.mp4")
        else:
            problems.append(f"{locale}: promo video missing")
        summary.append(f"| {NAMES[locale]} | {title} | {len(texts['short'])}/80 | {len(texts['full'])}/4000 |")
        plain += ["", "=" * 80, NAMES[locale], "=" * 80, "", "TITLE:", title, "", "SHORT DESCRIPTION:",
                  texts["short"], "", "FULL DESCRIPTION:", texts["full"], ""]
    if problems:
        sys.exit("\n".join(problems))

    shutil.copyfile(ROOT / "docs" / "icon" / "play_store_icon_512.png", out / "uygulama-ikonu-512.png")
    notes = (ROOT / "docs" / "release-notes" / f"{name}.md").read_text(encoding="utf-8")
    (out / "surum-notlari.txt").write_text(notes[notes.index("<en-US>"):], encoding="utf-8")
    bundle = ROOT / "build" / "app" / "outputs" / "bundle" / "release" / "app-release.aab"
    if bundle.exists():
        shutil.copyfile(bundle, out / f"hayvan-sesleri-{name}-{code}.aab")
    (ROOT / "store_listings.txt").write_text("\n".join(plain) + "\n", encoding="utf-8", newline="\n")

    guide = f"""# Play Console paketi — sürüm {name} (kod {code})

Bu klasör `scripts/store_assets/package.py` tarafından üretilir.

## İçindekiler

- `hayvan-sesleri-{name}-{code}.aab` — yüklenecek uygulama paketi
- `surum-notlari.txt` — 8 dilin sürüm notları, Play Console'a tek seferde yapıştırılır
- `uygulama-ikonu-512.png` — mağaza ikonu (512×512)
- Her dil için bir klasör:
  - `1-uygulama-adi.txt`
  - `2-kisa-aciklama.txt` (en çok 80 karakter)
  - `3-tam-aciklama.txt` (en çok 4000 karakter)
  - `4-feature-graphic-1024x500.png`
  - `5-telefon-01…08.png` (1080×1920)
  - `6-tanitim-videosu.mp4` (YouTube'a yüklenir, bağlantısı yapıştırılır)

## Nereye girilir

1. **Sürüm:** Sürüm > Üretim (ya da test kanalı) > Yeni sürüm oluştur. `.aab` dosyasını sürükleyin,
   `surum-notlari.txt` içeriğinin tamamını sürüm notları kutusuna yapıştırın.
2. **Mağaza girişi:** Büyüme > Mağaza varlığı > Ana mağaza girişi. Sağ üstteki dil seçiciden dili
   seçin; o dilin klasöründeki ad, kısa açıklama ve tam açıklamayı yapıştırın, grafikleri yükleyin.
   Uygulama ikonu yalnızca varsayılan dilde bir kez yüklenir.
3. **Video:** Her dilin videosunu YouTube'a yükleyin (herkese açık ya da liste dışı, reklamlar
   kapalı, "çocuklara özel" işaretli olabilir) ve bağlantıyı o dilin "Video" alanına yapıştırın.
4. Arapça klasörünün adı `ar-SA`; Play Console'da bu dil "Arapça – ar" olarak geçer.

## Metin uzunlukları

| Dil | Ad | Kısa açıklama | Tam açıklama |
|---|---|---|---|
{chr(10).join(summary)}
"""
    (out / "00-OKU.md").write_text(guide, encoding="utf-8", newline="\n")
    size = sum(p.stat().st_size for p in out.rglob("*") if p.is_file()) / 1e6
    print("wrote", out.relative_to(ROOT), f"({size:.0f} MB, {sum(1 for p in out.rglob('*') if p.is_file())} files)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
