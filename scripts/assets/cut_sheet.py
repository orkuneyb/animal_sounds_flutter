"""Cuts the animals out of one supplied character sheet.

Usage (from the project root, inside the build/venv environment):
    python scripts/assets/cut_sheet.py 1 lion tiger elephant dog cat cow horse sheep owl dolphin

The first argument is the sheet number (should-cut-animals/<n>.png); the
names are the animals in reading order, top row first; a name ending in !
keeps only the largest piece of that animal. The original sheet
is only read, never changed. For every animal the script writes
docs/animal-art/cut/s<sheet>_p<position>_<name>.png (512x512, RGBA,
transparent, the drawing itself untouched) and adds a record under the same
key to docs/animal-art/cut/report.json. Keys carry sheet and position, so a
second drawing of an animal never overwrites the first. Nothing is copied
into assets/. If animals cannot be separated safely the script says so and
writes nothing for them.

How it works:
  1. A segmentation model (BiRefNet) separates all characters from the
     background, checkerboard included.
  2. Connected shapes are matched to the names by position. Shapes that
     touch (one character overlapping another) are split along the
     narrowest join and the animals involved are marked `touching`, so a
     person looks at them.
  3. Each animal is cropped with only its own pixels, its soft edge is
     cleaned of background colour, and it is centred on a square canvas
     with a margin and scaled down once.
"""
import json
import pathlib
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = pathlib.Path(__file__).resolve().parents[2]
SHEETS = ROOT / "should-cut-animals"
OUT = ROOT / "docs" / "animal-art" / "cut"
SIZE = 512
MARGIN = 0.07
MODEL = "birefnet-general"
COLUMNS = 5


def matte(image: Image.Image) -> np.ndarray:
    """Alpha (0-255) of everything that is a character."""
    from rembg import new_session, remove
    cut = remove(image, session=new_session(MODEL), post_process_mask=False)
    return np.asarray(cut.getchannel("A")).copy()


def expected_centres(count: int, width: int, height: int) -> list:
    columns = min(COLUMNS, count)  # a sheet with fewer animals is one row
    rows = (count + columns - 1) // columns
    return [((i % columns + 0.5) * width / columns, (i // columns + 0.5) * height / rows)
            for i in range(count)]


def separate(alpha: np.ndarray, count: int, rgb: np.ndarray):
    """Returns one label per animal (1..count, reading order), the set of
    animal numbers that had to be split apart, and a list of problems."""
    solid = alpha > 128
    labels, found = ndimage.label(solid)
    sizes = ndimage.sum(solid, labels, range(1, found + 1))
    big = [i + 1 for i, size in enumerate(sizes) if size > 0.004 * solid.size]
    height, width = alpha.shape
    centres = expected_centres(count, width, height)

    # Which expected animals fall on which shape.
    owner = {}
    for number, (cx, cy) in enumerate(centres, start=1):
        best, best_distance = None, None
        for shape in big:
            ys, xs = np.nonzero(labels == shape)
            distance = ((xs - cx) ** 2 + (ys - cy) ** 2).min()
            if best_distance is None or distance < best_distance:
                best, best_distance = shape, distance
        owner.setdefault(best, []).append(number)

    result = np.zeros_like(labels)
    touching, problems = set(), []
    if len(big) != count:
        problems.append(f"found {len(big)} large shapes, expected {count}")
    for shape in big:
        if shape not in owner:
            problems.append(f"a large shape ({int(sizes[shape - 1])} px) belongs to no position; dropped")
    for shape, numbers in owner.items():
        region = labels == shape
        if len(numbers) == 1:
            result[region] = numbers[0]
            continue
        # Two or more animals in one shape: one overlaps the other. Cut
        # between each pair of neighbours along the path that crosses the
        # least of the shape and prefers drawn outlines.
        touching.update(numbers)
        per_row = min(COLUMNS, count)
        rows_used = {(n - 1) // per_row for n in numbers}
        columns_used = {(n - 1) % per_row for n in numbers}
        if len(rows_used) == 1:
            result[region] = numbers[0]
            for left, right in zip(numbers, numbers[1:]):
                seam = seam_between(region, rgb, centres[left - 1][0], centres[right - 1][0])
                columns = np.arange(region.shape[1])[None, :]
                result[region & (columns > seam[:, None])] = right
        elif len(columns_used) == 1 and len(numbers) == 2:
            top, bottom = numbers
            seam = seam_between(region.T, rgb.transpose(1, 0, 2),
                                centres[top - 1][1], centres[bottom - 1][1])
            lines = np.arange(region.shape[0])[:, None]
            result[region] = top
            result[region & (lines > seam[None, :])] = bottom
        else:
            problems.append(f"positions {numbers} are joined in a way that cannot be split safely; skipped")

    # Small loose bits (a drop of water, a leaf) join the animal they sit
    # next to. A bit that is not right beside any animal is a stray from a
    # neighbour's decoration and is dropped.
    loose = solid & (result == 0)
    if loose.any() and (result > 0).any():
        distance, nearest = ndimage.distance_transform_edt(result == 0, return_indices=True)
        bits, bit_count = ndimage.label(loose)
        for bit in range(1, bit_count + 1):
            where = bits == bit
            if distance[where].min() <= 14:
                ys, xs = np.nonzero(where)
                k = distance[where].argmin()
                result[where] = result[nearest[0][ys[k], xs[k]], nearest[1][ys[k], xs[k]]]
    return result, touching, problems


def seam_between(region: np.ndarray, rgb: np.ndarray, x_left: float, x_right: float) -> np.ndarray:
    """A top-to-bottom line between two horizontally neighbouring animals.

    Returns, for every row, the last column that belongs to the left animal.
    The line is the cheapest path where crossing the merged shape costs 1,
    crossing a strong drawn edge inside it costs almost nothing, and
    background is free. For animals above one another, pass the transposed
    region and picture.
    """
    span = x_right - x_left
    x0, x1 = int(x_left + 0.2 * span), int(x_right - 0.2 * span)
    grey = ndimage.gaussian_filter(rgb.astype(np.float32).mean(axis=2), 1.0)
    edges = ndimage.gaussian_gradient_magnitude(grey, 1.0)
    edges = np.clip(edges / (np.percentile(edges, 99) + 1e-6), 0, 1)
    cost = np.where(region, 1.0 - 0.92 * edges, 0.0)[:, x0:x1]
    rows, cols = cost.shape
    total = cost.copy()
    back = np.zeros((rows, cols), dtype=np.int16)
    reach = 2
    for y in range(1, rows):
        best = np.full(cols, np.inf)
        choice = np.zeros(cols, dtype=np.int16)
        for step in range(-reach, reach + 1):
            shifted = np.full(cols, np.inf)
            if step < 0:
                shifted[-step:] = total[y - 1, :step]
            elif step > 0:
                shifted[:-step] = total[y - 1, step:]
            else:
                shifted = total[y - 1]
            better = shifted + 0.02 * abs(step) < best
            best = np.where(better, shifted + 0.02 * abs(step), best)
            choice = np.where(better, step, choice)
        total[y] += best
        back[y] = choice
    seam = np.zeros(rows, dtype=np.int64)
    x = int(total[-1].argmin())
    for y in range(rows - 1, -1, -1):
        seam[y] = x + x0
        x = int(np.clip(x + back[y, x], 0, cols - 1))
    return seam


def defringe(rgb: np.ndarray, alpha: np.ndarray) -> np.ndarray:
    """Gives half-transparent edge pixels the colour of the nearest solid
    pixel, so no light background shows as a halo around fur."""
    solid = alpha >= 250
    if not solid.any():
        return rgb
    _, nearest = ndimage.distance_transform_edt(~solid, return_indices=True)
    cleaned = rgb[nearest[0], nearest[1]]
    edge = (alpha > 0) & ~solid
    out = rgb.copy()
    out[edge] = cleaned[edge]
    return out


def dehalo(rgb: np.ndarray, alpha: np.ndarray) -> np.ndarray:
    """On a sheet with a white background the outermost pixels of fur carry
    some of that white. Edge pixels that are clearly lighter than the body
    just inside them take the body's colour. Thin parts with no inside
    (whiskers) are left alone."""
    deep = ndimage.binary_erosion(alpha >= 250, iterations=3)
    if not deep.any():
        return rgb
    distance, nearest = ndimage.distance_transform_edt(~deep, return_indices=True)
    inside = rgb[nearest[0], nearest[1]].astype(np.int16)
    light = rgb.astype(np.int16).mean(axis=2) - inside.mean(axis=2)
    halo = (alpha > 0) & ~deep & (distance <= 5) & (light > 30) & (rgb.min(axis=2) > 150)
    out = rgb.copy()
    out[halo] = inside[halo].astype(np.uint8)
    return out


def cut_animal(rgb: np.ndarray, alpha: np.ndarray, own: np.ndarray, white_sheet: bool = False):
    # Keep the soft edge that belongs to this animal, nothing of its neighbours.
    reach = ndimage.binary_dilation(own, iterations=3)
    other = ndimage.binary_dilation((~own) & (alpha > 128), iterations=1)
    keep = reach & ~other | own
    # The model's matte tops out a little below full strength; stretch it so
    # the body is fully solid and faint background haze is fully clear.
    a = np.where(keep, alpha, 0).astype(np.float32)
    a = np.clip((a - 20.0) / (235.0 - 20.0), 0.0, 1.0) * 255.0
    a = a.astype(np.uint8)
    ys, xs = np.nonzero(a > 24)
    box = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
    colours = defringe(dehalo(rgb, a) if white_sheet else rgb, a)
    rgba = np.dstack([colours, a])[box[1]:box[3], box[0]:box[2]]
    return Image.fromarray(rgba, "RGBA"), box


def compose(cut: Image.Image) -> Image.Image:
    inner = int(SIZE * (1 - 2 * MARGIN))
    scale = inner / max(cut.size)
    resized = cut.resize((max(1, round(cut.width * scale)), max(1, round(cut.height * scale))),
                         Image.LANCZOS)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((SIZE - resized.width) // 2, (SIZE - resized.height) // 2))
    return canvas


def describe(picture: Image.Image, name: str, sheet: str, number: int, box, touching: bool,
             sheet_size, target: pathlib.Path) -> dict:
    a = np.asarray(picture.getchannel("A"))
    pieces, piece_count = ndimage.label(a > 128)
    piece_sizes = ndimage.sum(a > 128, pieces, range(1, piece_count + 1))
    width, height = sheet_size
    at_edge = box[0] <= 1 or box[1] <= 1 or box[2] >= width - 1 or box[3] >= height - 1
    return {
        "animal": name,
        "sheet": f"{sheet}.png",
        "position": number,
        "file": target.name,
        "source_box": box,
        "source_pixels": [box[2] - box[0], box[3] - box[1]],
        "upscaled": max(box[2] - box[0], box[3] - box[1]) < SIZE * (1 - 2 * MARGIN),
        "touching_neighbour": touching,
        "touches_sheet_edge": bool(at_edge),
        "pieces": int((np.asarray(piece_sizes) > 40).sum()),
        "size": list(picture.size),
        "mode": picture.mode,
        "transparent_share": round(float((a == 0).mean()), 3),
        "solid_share": round(float((a == 255).mean()), 3),
        "bytes": target.stat().st_size,
    }


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    sheet, names = sys.argv[1], sys.argv[2:]
    source = Image.open(SHEETS / f"{sheet}.png").convert("RGB")
    rgb = np.asarray(source)
    alpha = matte(source)
    labels, touching, problems = separate(alpha, len(names), rgb)
    # A plain white background (not a checkerboard) leaves a white rim on fur.
    white_sheet = bool((rgb[alpha < 10].min(axis=1) > 240).mean() > 0.95)
    for problem in problems:
        print("PROBLEM:", problem)
    OUT.mkdir(parents=True, exist_ok=True)
    report_path = OUT / "report.json"
    report = json.loads(report_path.read_text(encoding="utf-8")) if report_path.exists() else {}
    for number, name in enumerate(names, start=1):
        main_only = name.endswith("!")
        name = name.rstrip("!")
        key = f"s{int(sheet):02d}_p{number:02d}_{name}"
        # A position that was renamed leaves no stale record or file behind.
        for old in [k for k in report if k.startswith(key[:8]) and k != key]:
            (OUT / f"{old}.png").unlink(missing_ok=True)
            del report[old]
        own = labels == number
        if not own.any():
            print(f"{key}: NOT CUT")
            report[key] = {"animal": name, "sheet": f"{sheet}.png", "position": number,
                           "status": "not_cut"}
            continue
        if main_only:
            # Drop loose specks (a neighbour's whisker, a stray leaf).
            parts, part_count = ndimage.label(own)
            part_sizes = ndimage.sum(own, parts, range(1, part_count + 1))
            own = parts == int(np.argmax(part_sizes)) + 1
        cut, box = cut_animal(rgb, alpha, own, white_sheet)
        picture = compose(cut)
        target = OUT / f"{key}.png"
        picture.save(target, optimize=True)
        record = describe(picture, name, sheet, number, box, number in touching,
                          source.size, target)
        report[key] = record
        flags = [k for k in ("touching_neighbour", "touches_sheet_edge", "upscaled") if record[k]]
        if record["pieces"] > 1:
            flags.append(f"pieces={record['pieces']}")
        print(f"{key}: {box[2] - box[0]}x{box[3] - box[1]} px in sheet, "
              f"{target.stat().st_size // 1024} KB {' '.join(flags)}")
    report_path.write_text(json.dumps(report, indent=1, ensure_ascii=False), encoding="utf-8")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
