"""Prepares the app icon files from a square source picture.

Usage (from the project root, inside the build/venv environment):
    python scripts/assets/make_icon.py icon.png

Writes into assets/icon/:
  icon.png             1024x1024, the whole picture (store icon, iOS, old Android)
  icon_foreground.png  1024x1024, the character and its sound waves on a clear
                       background, sized to stay inside the circle Android
                       cuts adaptive icons to
  icon_256.png         256x256 copy of the foreground (start-up screen)
and prints the average background colour for pubspec.yaml. Afterwards run
`dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.

The character is separated by a segmentation model. The orange sound waves
beside it are not part of the character for the model, so they are picked
by colour: strongly orange pixels to the right of and above the head.
"""
import pathlib
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "icon"
SIZE = 1024
# flutter_launcher_icons shrinks the foreground to 68 % and Android shows a
# circle 61 % of the canvas wide, so content must stay within this radius.
SAFE_RADIUS = 0.61 / 0.68 / 2 * SIZE * 0.97


def main() -> int:
    from rembg import new_session, remove
    source = Image.open(sys.argv[1]).convert("RGB")
    if source.width != source.height:
        sys.exit("the icon has to be square")
    rgb = np.asarray(source).astype(np.int16)
    body = np.asarray(remove(source, session=new_session("birefnet-general"),
                             post_process_mask=False).getchannel("A")).astype(np.float32)
    body = np.clip((body - 20) / 215, 0, 1)

    orange = rgb[..., 0] - rgb[..., 2]          # background is grey-green, waves are orange
    waves = np.clip((orange - 45) / 60.0, 0, 1)
    waves[ndimage.binary_dilation(body > 0.5, iterations=6)] = 0
    ys, xs = np.nonzero(body > 0.5)
    head_x, top = (xs.min() + xs.max()) / 2, ys.min()
    height = ys.max() - ys.min()
    yy, xx = np.mgrid[:rgb.shape[0], :rgb.shape[1]]
    waves[(xx < head_x) | (yy > top + 0.45 * height)] = 0
    parts, count = ndimage.label(waves > 0.5)
    sizes = ndimage.sum(waves > 0.5, parts, range(1, count + 1))
    keep = np.isin(parts, [i + 1 for i, s in enumerate(sizes) if s > 0.0004 * waves.size])
    waves[~ndimage.binary_dilation(keep, iterations=5)] = 0
    print("sound wave pieces kept:", int(keep.any()) and len([s for s in sizes if s > 0.0004 * waves.size]))

    alpha = np.maximum(body, waves)
    cut = Image.fromarray(np.dstack([rgb.astype(np.uint8), (alpha * 255).astype(np.uint8)]), "RGBA")
    ys, xs = np.nonzero(alpha > 0.1)
    cx, cy = (xs.min() + xs.max()) / 2, (ys.min() + ys.max()) / 2
    reach = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2).max()
    scale = SAFE_RADIUS / reach
    resized = cut.resize((round(cut.width * scale), round(cut.height * scale)), Image.LANCZOS)
    foreground = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    foreground.alpha_composite(resized, (round(SIZE / 2 - cx * scale), round(SIZE / 2 - cy * scale)))

    OUT.mkdir(parents=True, exist_ok=True)
    source.resize((SIZE, SIZE), Image.LANCZOS).save(OUT / "icon.png", optimize=True)
    foreground.save(OUT / "icon_foreground.png", optimize=True)
    foreground.resize((256, 256), Image.LANCZOS).save(OUT / "icon_256.png", optimize=True)
    background = rgb[alpha < 0.02].mean(axis=0)
    print("background colour #%02x%02x%02x" % tuple(int(v) for v in background))
    return 0


if __name__ == "__main__":
    sys.exit(main())
