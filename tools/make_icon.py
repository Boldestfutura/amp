#!/usr/bin/env python3
"""Generate the original Amp app icon as an iOS 26 Icon Composer package.

Outputs:
  Amp/Resources/AppIcon.icon/            a layered Liquid Glass icon package
      icon.json                         declarative document (background fill,
                                        layers, specializations)
      Assets/ampersand.png              flat white ampersand glyph layer
  Amp/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
                                        flattened legacy fallback render

The artwork is original: an ampersand set in Open Sans ExtraBold (or the best
available bold face), used as a flat white glyph. Icon Composer supplies all
Liquid Glass styling (specular, shadow, translucency, refraction), so nothing
is baked into the assets.

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

# Palette (sRGB 0..1): deep indigo -> vivid violet -> warm magenta.
BG_TOP = (0.18039, 0.12941, 0.36078)   # 46 34 92
BG_BOT = (0.73725, 0.29020, 0.54118)   # 188 74 138
GLYPH_LIGHT = (1.0, 1.0, 1.0)
GLYPH_DARK = (1.0, 0.45098, 0.36078)
GLYPH_LIGHT_8 = (255, 255, 255)   # same color, 8-bit, for raster output

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


def glyph_mask(text, target_frac=0.60):
    """Alpha mask of the glyph, scaled to occupy target_frac of the canvas."""
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

    # Recenter on the actual ink bounds (font metrics are asymmetric).
    b = mask.getbbox()
    dx = int(round(((W - (b[2] - b[0])) / 2) - b[0]))
    dy = int(round(((W - (b[3] - b[1])) / 2) - b[1]))
    return mask.transform((W, W), Image.AFFINE, (1, 0, -dx, 0, 1, -dy))


def flat_glyph(color):
    """A flat, unstyled glyph in `color` with the mask as its alpha channel."""
    img = Image.new("RGBA", (W, W), color + (0,))
    img.putalpha(glyph_mask("&"))
    return img


def write_icon_package():
    os.makedirs(ASSETS, exist_ok=True)

    flat_glyph(GLYPH_LIGHT_8).resize((S, S), Image.LANCZOS).save(
        os.path.join(ASSETS, "ampersand.png")
    )

    def srgb(c):
        return "extended-srgb:" + ",".join(f"{v:.5f}" for v in (*c, 1.0))

    doc = {
        "features": ["refractivity", "specular-location"],
        "fill-specializations": [
            {
                "value": {
                    "linear-gradient": [srgb(BG_TOP), srgb(BG_BOT)],
                }
            },
            {
                "appearance": "dark",
                "value": {
                    "linear-gradient": [
                        srgb((0.11373, 0.08627, 0.24314)),
                        srgb((0.58824, 0.22353, 0.42745)),
                    ],
                },
            },
        ],
        "groups": [
            {
                "name": "Amp Mark",
                "layers": [
                    {
                        "name": "Ampersand",
                        "image-name": "ampersand.png",
                        "glass": True,
                        "fill-specializations": [
                            {"value": {"solid": srgb(GLYPH_LIGHT)}},
                            {
                                "appearance": "dark",
                                "value": {"solid": srgb(GLYPH_DARK)},
                            },
                            {
                                "appearance": "tinted",
                                "value": {"solid": srgb(GLYPH_LIGHT)},
                            },
                        ],
                    }
                ],
                "shadow": {"kind": "neutral", "opacity": 0.35},
                "specular": True,
                "translucency": {"enabled": True, "value": 0.15},
                "refractivity": {"enabled": True, "depth": 0.5, "strength": 0.5},
            }
        ],
        "supported-platforms": {"squares": ["iOS"]},
    }

    with open(os.path.join(ICON_PKG, "icon.json"), "w") as fh:
        json.dump(doc, fh, indent=2)
        fh.write("\n")


def write_legacy_png():
    """Flattened preview for the pre-iOS 26 asset-catalog fallback."""
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

    base = Image.alpha_composite(base, flat_glyph(GLYPH_LIGHT_8))

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
    print("wrote AppIcon.icon/ (icon.json + Assets/ampersand.png)")
    print("wrote Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")


if __name__ == "__main__":
    main()
