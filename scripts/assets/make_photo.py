"""Turns a chosen Commons photo into the app's transparent animal picture.

Usage (from the project root, inside the build/venv environment):
    python scripts/assets/make_photo.py lion 26 [elephant 11 ...]

The number is the candidate's position on build/photo_src/<name>/sheet.jpg
(written by photo_candidates.py). For each pair this script:
  1. downloads the photo at up to 1800 px into build/photo_src/<name>/
  2. removes the background with rembg
  3. crops to the animal, centres it on a square canvas with a margin
  4. writes build/photo_out/<name>.png (512x512, transparent, 256 colours)
  5. records the source, author and licence in build/photo_out/sources.json

Nothing is written to assets/; copying the approved pictures there is a
separate, deliberate step.
"""
import io
import json
import os
import pathlib
import sys

from PIL import Image

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from photo_candidates import ROOT, SRC, api, get  # noqa: E402

OUT = ROOT / "build" / "photo_out"
SIZE = 512
MARGIN = 0.06
# The background-removal model; REMBG_MODEL=u2net (or another rembg model)
# overrides it for a photo the default handles badly.
MODEL = os.environ.get("REMBG_MODEL", "birefnet-general-lite")

_session = None


def session():
    global _session
    if _session is None:
        from rembg import new_session
        _session = new_session(MODEL)
    return _session


def download(name: str, candidate: dict) -> pathlib.Path:
    folder = SRC / name
    target = folder / "original.jpg"
    data = api(action="query", titles=candidate["title"], prop="imageinfo",
               iiprop="url", iiurlwidth=1800)
    info = next(iter(data["query"]["pages"].values()))["imageinfo"][0]
    url = info.get("thumburl") or info["url"]
    Image.open(io.BytesIO(get(url))).convert("RGB").save(target, quality=95)
    return target


def keep_animal(alpha: Image.Image) -> Image.Image:
    """Keeps the largest connected shape and drops stray bits such as a twig
    or a patch of ground that the background removal left floating."""
    import numpy as np
    from scipy import ndimage
    mask = np.asarray(alpha) > 40
    labels, count = ndimage.label(mask)
    if count <= 1:
        return alpha
    sizes = ndimage.sum(mask, labels, range(1, count + 1))
    largest = int(sizes.argmax()) + 1
    keep = labels == largest
    return Image.fromarray((np.asarray(alpha) * keep).astype("uint8"))


def cut_out(source: pathlib.Path):
    """Returns the cropped animal and whether it reached the photo's border
    (then part of it was probably outside the frame)."""
    from rembg import remove
    cut = remove(Image.open(source), session=session(), post_process_mask=True)
    alpha = cut.getchannel("A").point(lambda v: 0 if v < 16 else v)
    alpha = keep_animal(alpha)
    cut.putalpha(alpha)
    box = alpha.point(lambda v: 255 if v > 40 else 0).getbbox()
    if box is None:
        raise RuntimeError("nothing left after background removal")
    edge = (box[0] <= 1 or box[1] <= 1
            or box[2] >= cut.width - 1 or box[3] >= cut.height - 1)
    return cut.crop(box), edge


def compose(cut: Image.Image) -> Image.Image:
    inner = int(SIZE * (1 - 2 * MARGIN))
    scale = inner / max(cut.size)
    resized = cut.resize(
        (max(1, round(cut.width * scale)), max(1, round(cut.height * scale))),
        Image.LANCZOS)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.paste(resized, ((SIZE - resized.width) // 2, (SIZE - resized.height) // 2), resized)
    return canvas


def main() -> int:
    args = sys.argv[1:]
    if not args or len(args) % 2:
        print(__doc__)
        return 1
    OUT.mkdir(parents=True, exist_ok=True)
    record_path = OUT / "sources.json"
    records = json.loads(record_path.read_text(encoding="utf-8")) if record_path.exists() else {}
    for name, index in zip(args[::2], args[1::2]):
        candidates = json.loads((SRC / name / "candidates.json").read_text(encoding="utf-8"))
        candidate = candidates[int(index)]
        source = download(name, candidate)
        cut, edge = cut_out(source)
        picture = compose(cut)
        target = OUT / f"{name}.png"
        # 256 colours with dithering: about a quarter of the file size, and
        # not distinguishable by eye at the sizes the app shows.
        picture.quantize(256, method=Image.Quantize.FASTOCTREE,
                         dither=Image.Dither.FLOYDSTEINBERG).save(target, optimize=True)
        records[name] = {
            "animal": name,
            "image": f"assets/animal_images/{name}.png",
            "source_page": candidate["page"],
            "file_url": candidate["url"],
            "author": candidate["author"],
            "license": candidate["license"],
            "license_url": candidate["license_url"],
            "description": candidate["description"],
            "touches_photo_edge": edge,
            "bytes": target.stat().st_size,
        }
        line = (f"{name}: {candidate['license']} | {candidate['author'][:50]} | "
                f"{target.stat().st_size // 1024} KB | edge={edge}")
        print(line.encode("ascii", "replace").decode())
        record_path.write_text(json.dumps(records, ensure_ascii=False, indent=1), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
