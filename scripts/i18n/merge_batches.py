"""Checks the animal texts written in batches and adds the animals to the app.

Usage (from the project root):
    python scripts/i18n/merge_batches.py            check only
    python scripts/i18n/merge_batches.py --apply    check, then add

Each scripts/i18n/new_animals/batches/batch_<n>.json holds, for some
animals, the picture traits ("traits") and the ten texts in eight languages
("texts"). The check makes sure nothing is missing or empty, the units are
ones the app can read, and the numbers agree across languages. With --apply
the texts are merged into scripts/i18n/new_animals/<lang>.json and the
animals are appended to lib/repositories/animal_repository.dart in the order
of docs/animal-art/animals.json (animals already listed are left alone, so
saved ids never move). Afterwards run add_animals.py with the printed names.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "scripts" / "i18n" / "new_animals"
REPO = ROOT / "lib" / "repositories" / "animal_repository.dart"
LANGS = ["en-US", "tr-TR", "ru-RU", "pt-BR", "hi-IN", "es-ES", "ar-SA", "de-DE"]
SUFFIXES = ["", "_desc", "_size", "_weight", "_lifespan", "_habitat", "_diet",
            "_fun_fact_1", "_fun_fact_2", "_fun_fact_3"]
TRAITS = {
    "group": ["farm", "wild", "birds", "water", "small"],
    "home": ["farm", "house", "savanna", "forest", "jungle", "sea", "ice", "desert", "lake",
             "mountain", "meadow", "city"],
    "food": ["grass", "plants", "meat", "fish", "insects", "seeds", "fruit", "nectar", "everything"],
    "size": ["smaller", "same", "bigger"],
}
# The same patterns as lib/utils/animal_data_parser.dart.
WEIGHT = re.compile(r"kg|кг|किलो|كغ|كجم|gram|(\d|\s)(g|gr|г)(\s|\.|$|,)|ग्राम|غرام|грамм")
LENGTH = re.compile(r"cm|см|सेमी|سم|met(er|re|ro)|метр|मीटर|متر|(\d|\s)(m|м)(\s|\.|$|,)")
DIGITS = re.compile(r"\d+(?:[.,]\d+)?")


def numbers(text: str) -> list:
    return [n.replace(",", ".") for n in DIGITS.findall(text)]


def main() -> int:
    apply = "--apply" in sys.argv
    traits, texts, problems = {}, {lang: {} for lang in LANGS}, []
    for path in sorted((SRC / "batches").glob("batch_*.json")):
        batch = json.loads(path.read_text(encoding="utf-8"))
        traits.update(batch["traits"])
        for lang in LANGS:
            texts[lang].update(batch["texts"].get(lang, {}))

    library = json.loads((ROOT / "docs" / "animal-art" / "animals.json").read_text(encoding="utf-8"))
    wanted = [a for a in library if a["qc_status"] == "ok"]
    listed = re.findall(r"^\s*\('([a-z_]+)',\s*AnimalGroup", REPO.read_text(encoding="utf-8"), flags=re.M)
    new = [a["id"] for a in wanted if a["id"] not in listed]

    for animal in new:
        if animal not in traits:
            problems.append(f"{animal}: no traits")
            continue
        for kind, allowed in TRAITS.items():
            if traits[animal].get(kind) not in allowed:
                problems.append(f"{animal}: {kind} = {traits[animal].get(kind)!r}")
        for lang in LANGS:
            for suffix in SUFFIXES:
                value = texts[lang].get(animal + suffix)
                if not isinstance(value, str) or not value.strip() or "\n" in value:
                    problems.append(f"{animal}{suffix} [{lang}]: missing, empty or multi-line")
            size, weight = texts[lang].get(animal + "_size", ""), texts[lang].get(animal + "_weight", "")
            if not LENGTH.search(size.lower()):
                problems.append(f"{animal}_size [{lang}]: no readable unit in {size!r}")
            if not WEIGHT.search(weight.lower()):
                problems.append(f"{animal}_weight [{lang}]: no readable unit in {weight!r}")
            if re.search(r"[٠-٩०-९]", size + weight + texts[lang].get(animal + "_lifespan", "")):
                problems.append(f"{animal} [{lang}]: non-Western digits")
        for suffix in ("_size", "_weight", "_lifespan"):
            seen = {lang: numbers(texts[lang].get(animal + suffix, "")) for lang in LANGS}
            if not seen["en-US"] or len({tuple(v) for v in seen.values()}) != 1:
                problems.append(f"{animal}{suffix}: numbers differ across languages {seen}")
        tr = next(a["name_tr"] for a in wanted if a["id"] == animal)
        if texts["tr-TR"].get(animal) != tr:
            problems.append(f"{animal}: Turkish name {texts['tr-TR'].get(animal)!r}, expected {tr!r}")

    for problem in problems:
        print("PROBLEM:", problem.encode("ascii", "backslashreplace").decode())
    print(f"{len(new)} new animals, {len(problems)} problems")
    if problems or not apply:
        return 1 if problems else 0

    for lang in LANGS:
        path = SRC / f"{lang}.json"
        current = json.loads(path.read_text(encoding="utf-8"))
        current.update({animal + s: texts[lang][animal + s] for animal in new for s in SUFFIXES})
        path.write_text(json.dumps(current, ensure_ascii=False, indent=1) + "\n",
                        encoding="utf-8", newline="\n")
    lines = ["    // Added with the 3D picture set; their sounds are added later."]
    for animal in new:
        t = traits[animal]
        lines.append(f"    ('{animal}', AnimalGroup.{t['group']}, AnimalHome.{t['home']}, "
                     f"AnimalFood.{t['food']}, AnimalSize.{t['size']}),")
    repo = REPO.read_text(encoding="utf-8")
    marker = "  ]);\n"
    at = repo.index(marker)
    REPO.write_text(repo[:at] + "\n".join(lines) + "\n" + repo[at:], encoding="utf-8", newline="\n")
    print("added:", " ".join(new))
    return 0


if __name__ == "__main__":
    sys.exit(main())
