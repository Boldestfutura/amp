#!/usr/bin/env python3
"""Generate an original Amp app icon (1024x1024) - a bold ampersand on a
rounded-square gradient with a soft glass sheen. No third-party artwork used."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math, os

S = 1024
SS = 4  # supersample factor
W = S * SS

# Palette: deep indigo -> violet -> warm magenta, subtle and premium.
TOP = (46, 34, 92)
MID = (92, 52, 138)
BOT = (188, 74, 138)

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

def gradient_bg(w, h):
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        t = y / (h - 1)
        if t < 0.5:
            c = lerp(TOP, MID, t / 0.5)
        else:
            c = lerp(MID, BOT, (t - 0.5) / 0.5)
        for x in range(w):
            px[x, y] = c
    return img

# Rounded-square mask (iOS-ish squircle approximation via large radius)
def squircle_mask(size, radius_frac=0.235):
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    r = int(size * radius_frac)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=255)
    return mask

def radial_glow(size, center, radius, color, alpha=90):
    layer = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(layer)
    d.ellipse([center[0]-radius, center[1]-radius, center[0]+radius, center[1]+radius], fill=alpha)
    layer = layer.filter(ImageFilter.GaussianBlur(radius * 0.35))
    glow = Image.new("RGBA", (size, size), color + (0,))
    glow.putalpha(layer)
    return glow

def main():
    bg = gradient_bg(W, W).convert("RGBA")

    # Top glass sheen: a bright diagonal band, blurred.
    sheen = Image.new("L", (W, W), 0)
    d = ImageDraw.Draw(sheen)
    d.polygon([(0, int(W*0.03)), (W, int(W*0.22)), (W, 0), (0, 0)], fill=70)
    sheen = sheen.filter(ImageFilter.GaussianBlur(W*0.05))
    white = Image.new("RGBA", (W, W), (255, 255, 255, 0))
    white.putalpha(sheen)
    bg = Image.alpha_composite(bg, white)

    # Soft glow top-left and bottom-right for depth.
    bg = Image.alpha_composite(bg, radial_glow(W, (int(W*0.30), int(W*0.26)), int(W*0.42), (255, 255, 255), 60))
    bg = Image.alpha_composite(bg, radial_glow(W, (int(W*0.76), int(W*0.80)), int(W*0.40), (255, 180, 230), 45))

    # Ampersand
    text = "&"
    # Prefer a clean geometric bold; fall back gracefully.
    candidates = [
        "/usr/share/fonts/open-sans/OpenSans-Bold.ttf",
        "/usr/share/fonts/open-sans/OpenSans-Semibold.ttf",
        "/usr/share/fonts/redhat/RedHatDisplay-Bold.otf",
        "/usr/share/fonts/aajohan-comfortaa-fonts/Comfortaa-Bold.otf",
        "/usr/share/fonts/liberation-sans-fonts/LiberationSans-Bold.ttf",
    ]
    font_path = next((p for p in candidates if os.path.exists(p)), None)
    if font_path is None:
        raise SystemExit("No suitable bold font found")

    target = int(W * 0.60)
    size = 10
    font = ImageFont.truetype(font_path, size)
    # Scale to target glyph height.
    while True:
        bbox = font.getbbox(text)
        h = bbox[3] - bbox[1]
        if h >= target or size > W:
            break
        size += 8
        font = ImageFont.truetype(font_path, size)

    bbox = font.getbbox(text)
    gw, gh = bbox[2] - bbox[0], bbox[3] - bbox[1]
    pos = ((W - gw) / 2 - bbox[0], (W - gh) / 2 - bbox[1])

    # Drop shadow for the glyph.
    shadow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.text((pos[0], pos[1] + int(W*0.012)), text, font=font, fill=(20, 8, 40, 130))
    shadow = shadow.filter(ImageFilter.GaussianBlur(W*0.012))
    bg = Image.alpha_composite(bg, shadow)

    # Glyph in near-white with a faint vertical gradient (glass-etched look).
    glyph = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glyph)
    gd.text(pos, text, font=font, fill=(255, 255, 255, 255))
    # Subtle inner tint at the bottom of the glyph.
    tint = Image.new("RGBA", (W, W), (255, 210, 240, 0))
    ta = Image.new("L", (W, W), 0)
    td = ImageDraw.Draw(ta)
    td.rectangle([0, int(W*0.55), W, W], fill=70)
    ta = ta.filter(ImageFilter.GaussianBlur(W*0.02))
    tint.putalpha(Image.composite(ta, Image.new("L", (W, W), 0), glyph.split()[3]))
    glyph = Image.alpha_composite(glyph, tint)
    bg = Image.alpha_composite(bg, glyph)

    # Apply squircle mask.
    mask = squircle_mask(W)
    out = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    out.paste(bg, (0, 0), mask)

    out = out.resize((S, S), Image.LANCZOS)
    outdir = os.path.dirname(os.path.abspath(__file__))
    out.save(os.path.join(outdir, "AppIcon-1024.png"))
    print("wrote AppIcon-1024.png")

if __name__ == "__main__":
    main()
