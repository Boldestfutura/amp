#!/usr/bin/env python3
"""Generate the original Amp app icon as an iOS 26 Icon Composer package.

Outputs:
  Amp/Resources/AppIcon.icon/            a layered Liquid Glass icon package
      icon.json                         declarative document (background fill,
                                        groups/layers, specializations)
      Assets/glyph.png                  crisp ampersand glyph (front glass layer)
      Assets/disc.png                   circular "record" panel (back glass layer)
      Assets/ring.png                   thin concentric ring (record groove)
  Amp/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
                                        flattened legacy fallback render

Design intent (Liquid Glass):
  Real iOS 26 icons are a small stack of *separate glass pieces* that the system
  renders with refraction, specular highlights and shadows. A single flat glyph on
  a flat gradient gives those effects nothing to bite on, so the icon reads as a
  cheap sticker. This design instead provides:

    background  subtle top-to-bottom gradient (indigo -> violet)
    group "Record"   a glass disc + ring, slightly inset  -> refraction medium
    group "Mark"     a bold white ampersand, glass, crisp edges -> focal element

  Assets are flat and unstyled (no baked shadow/highlight/gradient); Icon Composer
  supplies all material. Edges are hard (no feathering) per Apple's guidance.

No third-party app artwork is used or copied.
"""
from PIL import Image, ImageDraw, ImageFont
import json
import os

S = 1024          # Icon Composer canvas is 1024x1024 points
SS = 4            # supersample for crisp glyph edges
W = S * SS

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
ICON_PKG = os.path.join(ROOT, "Amp", "Resources", "AppIcon.icon")
ASSETS = os.path.join(ICON_PKG, "Assets")
LEGACY_DIR = os.path.join(
    ROOT, "Amp", "Resources", "Assets.xcassets", "AppIcon.appiconset"
)

# Palette (sRGB 0..1).
BG_TOP = (0.16471, 0.11765, 0.32941)   # deep indigo
BG_BOT = (0.47059, 0.20392, 0.47843)   # violet
BG_TOP_DARK = (0.09804, 0.07451, 0.21569)
BG_BOT_DARK = (0.31373, 0.12941, 0.33333)

WHITE = (1.0, 1.0, 1.0)
WHITE_8 = (255, 255, 255)

FONT_CANDIDATES = [
    "/usr/share/fonts/open-sans/OpenSans-ExtraBold.ttf",
    "/usr/share/fonts/open-sans/OpenSans-Bold.ttf",
    "/usr/share/fonts/redhat/RedHatDisplay-ExtraBold.otf",
    "/usr/share/fonts/redhat/RedHatDisplay-Bold.otf",
    "/usr/share/fonts/aajohan-comfortaa-fonts/Comfortaa-Bold.otf",
    "/usr/share/fonts/liberation-sans-fonts/LiberationSans-Bold.ttf",
]


def find_font():
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            return path
    raise SystemExit("No suitable bold font found")


def _recenter(mask):
    """Shift a mask so its ink sits dead-center on the canvas."""
    b = mask.getbbox()
    dx = int(round(((W - (b[2] - b[0])) / 2) - b[0]))
    dy = int(round(((W - (b[3] - b[1])) / 2) - b[1]))
    return mask.transform((W, W), Image.AFFINE, (1, 0, -dx, 0, 1, -dy))


def glyph_mask(text, target_frac=0.52):
    """Alpha mask of the glyph, scaled so its ink height is target_frac of canvas."""
    font_path = find_font()
    target = int(W * target_frac)
    size = 10
    font = ImageFont.truetype(font_path, size)
    while True:
        bbox = font.getbbox(text)
        if (bbox[3] - bbox[1]) >= target or size > W:
            break
        size += 8
        font = ImageFont.truetype(font_path, size)

    bbox = font.getbbox(text)
    gw, gh = bbox[2] - bbox[0], bbox[3] - bbox[1]
    pos = ((W - gw) / 2 - bbox[0], (W - gh) / 2 - bbox[1])

    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).text(pos, text, font=font, fill=255)
    return _recenter(mask)


def _flat_from_mask(mask, color8):
    """Hard-edged flat color layer using `mask` as alpha (no feathering)."""
    hard = mask.point(lambda v: 255 if v >= 128 else 0)
    img = Image.new("RGBA", (W, W), color8 + (0,))
    img.putalpha(hard)
    return img


def disc_mask(diameter_frac=0.74, inner_hole_frac=0.06):
    """A filled circle with a small center hole (vinyl-record silhouette)."""
    mask = Image.new("L", (W, W), 0)
    d = ImageDraw.Draw(mask)
    r = (W * diameter_frac) / 2
    c = W / 2
    d.ellipse([c - r, c - r, c + r, c + r], fill=255)
    hr = W * inner_hole_frac
    d.ellipse([c - hr, c - hr, c + hr, c + hr], fill=0)
    return mask.point(lambda v: 255 if v >= 128 else 0)


def ring_mask(diameter_frac=0.60, thickness_frac=0.006):
    """Thin concentric groove ring."""
    mask = Image.new("L", (W, W), 0)
    d = ImageDraw.Draw(mask)
    r = (W * diameter_frac) / 2
    t = W * thickness_frac
    c = W / 2
    d.ellipse([c - r, c - r, c + r, c + r], outline=255, width=int(t))
    return mask.point(lambda v: 255 if v >= 128 else 0)


def write_icon_package():
    os.makedirs(ASSETS, exist_ok=True)

    def emit(mask, name, color8=WHITE_8):
        small = mask.resize((S, S), Image.LANCZOS)
        hard = small.point(lambda v: 255 if v >= 128 else 0)
        img = Image.new("RGBA", (S, S), color8 + (0,))
        img.putalpha(hard)
        img.save(os.path.join(ASSETS, name))

    emit(glyph_mask("&"), "glyph.png")
    emit(disc_mask(), "disc.png")
    emit(ring_mask(), "ring.png")

    def srgb(c):
        return "extended-srgb:" + ",".join(f"{v:.5f}" for v in (*c, 1.0))

    doc = {
        "features": ["refractivity", "specular-location"],
        "fill-specializations": [
            {"value": {"linear-gradient": [srgb(BG_TOP), srgb(BG_BOT)]}},
            {
                "appearance": "dark",
                "value": {
                    "linear-gradient": [srgb(BG_TOP_DARK), srgb(BG_BOT_DARK)]
                },
            },
        ],
        "groups": [
            {
                "name": "Record",
                "layers": [
                    {
                        "name": "Disc",
                        "image-name": "disc.png",
                        "glass": True,
                        "opacity": 0.30,
                        "fill-specializations": [
                            {"value": {"solid": srgb(WHITE)}},
                            {"appearance": "dark",
                             "value": {"solid": srgb(WHITE)}},
                            {"appearance": "tinted",
                             "value": {"solid": srgb(WHITE)}},
                        ],
                    },
                    {
                        "name": "Groove",
                        "image-name": "ring.png",
                        "glass": True,
                        "opacity": 0.55,
                        "fill-specializations": [
                            {"value": {"solid": srgb(WHITE)}},
                            {"appearance": "dark",
                             "value": {"solid": srgb(WHITE)}},
                            {"appearance": "tinted",
                             "value": {"solid": srgb(WHITE)}},
                        ],
                    },
                ],
                "specular": "inside",
                "translucency": {"enabled": True, "value": 0.20},
                "refractivity": {"enabled": True, "depth": 0.6, "strength": 0.6},
                "shadow": {"kind": "neutral", "opacity": 0.30},
            },
            {
                "name": "Mark",
                "layers": [
                    {
                        "name": "Ampersand",
                        "image-name": "glyph.png",
                        "glass": True,
                        "fill-specializations": [
                            {"value": {"solid": srgb(WHITE)}},
                            {"appearance": "dark",
                             "value": {"solid": srgb(WHITE)}},
                            {"appearance": "tinted",
                             "value": {"solid": srgb(WHITE)}},
                        ],
                    }
                ],
                "specular": "outside",
                "translucency": {"enabled": True, "value": 0.10},
                "shadow": {"kind": "neutral", "opacity": 0.35},
            },
        ],
        "supported-platforms": {"squares": ["iOS"]},
    }

    with open(os.path.join(ICON_PKG, "icon.json"), "w") as fh:
        json.dump(doc, fh, indent=2)
        fh.write("\n")


def write_legacy_png():
    """Flattened preview approximating the Liquid Glass look for the asset catalog."""
    os.makedirs(LEGACY_DIR, exist_ok=True)

    base = Image.new("RGBA", (W, W))
    px = base.load()
    for y in range(W):
        t = y / (W - 1)
        r = int((BG_TOP[0] + (BG_BOT[0] - BG_TOP[0]) * t) * 255)
        g = int((BG_TOP[1] + (BG_BOT[1] - BG_TOP[1]) * t) * 255)
        b = int((BG_TOP[2] + (BG_BOT[2] - BG_TOP[2]) * t) * 255)
        for x in range(W):
            px[x, y] = (r, g, b, 255)

    disc = _flat_from_mask(disc_mask(), WHITE_8)
    disc.putalpha(disc.split()[3].point(lambda v: int(v * 0.30)))
    base = Image.alpha_composite(base, disc)

    ring = _flat_from_mask(ring_mask(), WHITE_8)
    ring.putalpha(ring.split()[3].point(lambda v: int(v * 0.55)))
    base = Image.alpha_composite(base, ring)

    base = Image.alpha_composite(base, _flat_from_mask(glyph_mask("&"), WHITE_8))

    radius = int(W * 0.235)
    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, W - 1, W - 1], radius=radius, fill=255
    )
    out = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    out.paste(base, (0, 0), mask)
    out.resize((S, S), Image.LANCZOS).save(
        os.path.join(LEGACY_DIR, "AppIcon-1024.png")
    )


def main():
    write_icon_package()
    write_legacy_png()
    print("wrote AppIcon.icon/ (icon.json + Assets/{glyph,disc,ring}.png)")
    print("wrote Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")


if __name__ == "__main__":
    main()
