"""Copies the texts of newly added animals into the app's translation files.

Usage (from the project root):
    python scripts/i18n/add_animals.py goat parrot rabbit ...

For every named animal and every language it takes the ten texts from
scripts/i18n/new_animals/<lang>.json, adds them to
assets/translations/<lang>.json, adds the name to the nested "animal_names"
block, and rewrites the two badge texts that state the number of animals so
they match the animal list in lib/repositories/animal_repository.dart.
Safe to run again.
"""
import json
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from ui_keys import DIR, LANGS, ROOT, insert  # noqa: E402

SRC = ROOT / "scripts" / "i18n" / "new_animals"
SUFFIXES = ["", "_desc", "_size", "_weight", "_lifespan", "_habitat", "_diet",
            "_fun_fact_1", "_fun_fact_2", "_fun_fact_3"]
COUNT_KEYS = ["achievement_sound_master_desc", "achievement_animal_expert_desc"]
OLD_COUNT = re.compile(r"\d+|[٠-٩]+|[०-९]+")


def animal_count() -> int:
    repo = (ROOT / "lib" / "repositories" / "animal_repository.dart").read_text(encoding="utf-8")
    return len(re.findall(r"^\s*\('\w+', AnimalGroup\.", repo, flags=re.M))


def add_names(text: str, names: dict) -> str:
    """Adds entries to the nested "animal_names" object."""
    start = text.index('"animal_names": {')
    end = text.index("}", start)
    block = text[start:end]
    existing = dict(re.findall(r'"(\w+)":\s*"([^"]*)"', block))
    lines = [f'        {json.dumps(k)}: {json.dumps(v, ensure_ascii=False)}'
             for k, v in names.items() if k not in existing]
    if not lines:
        return text
    return text[:end].rstrip() + ",\n" + ",\n".join(lines) + "\n    " + text[end:]


def main() -> int:
    animals = sys.argv[1:]
    if not animals:
        print(__doc__)
        return 1
    count = animal_count()
    for lang in LANGS:
        source = json.loads((SRC / f"{lang}.json").read_text(encoding="utf-8"))
        path = DIR / f"{lang}.json"
        text = path.read_text(encoding="utf-8")
        current = json.loads(text)
        pairs = {f"{a}{s}": source[f"{a}{s}"] for a in animals for s in SUFFIXES}
        for key in COUNT_KEYS:
            pairs[key] = OLD_COUNT.sub(str(count), current[key], count=1)
        text = insert(text, pairs)
        text = add_names(text, {a: source[a] for a in animals})
        json.loads(text)
        path.write_text(text, encoding="utf-8", newline="\n")
        print(lang, "ok:", len(animals), "animals, count text ->", count)
    return 0


if __name__ == "__main__":
    sys.exit(main())
