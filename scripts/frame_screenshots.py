#!/usr/bin/env python3
"""Frames raw phone screenshots for the Play listing.

Reads store/raw/*.png|jpg (sorted by file name) and store/captions.txt (one
caption per line, same order). Writes 1080x1920 images to store/screens/.
Real phones are often taller than 2:1, which Play rejects, so each screenshot
is placed on a 9:16 canvas under a caption.
"""
import pathlib
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.exit("Pillow is missing. Run: pip install pillow")

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "store" / "raw"
OUT = ROOT / "store" / "screens"
CAPTIONS = ROOT / "store" / "captions.txt"

W, H = 1080, 1920
BG = (20, 50, 58)        # deep water
TEXT = (234, 240, 241)   # mist
CAPTION_H = 330
MARGIN = 110

FONT_PATHS = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    "/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf",
]


def load_font(size):
    for path in FONT_PATHS:
        if pathlib.Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default(size=size)


def wrap(draw, text, font, max_width):
    lines, line = [], ""
    for word in text.split():
        trial = f"{line} {word}".strip()
        if draw.textlength(trial, font=font) <= max_width:
            line = trial
        else:
            lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *img.size], radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def main():
    files = sorted(p for p in RAW.glob("*") if p.suffix.lower() in {".png", ".jpg", ".jpeg"})
    if not files:
        sys.exit(f"No screenshots found in {RAW}")
    captions = []
    if CAPTIONS.exists():
        captions = [c.strip() for c in CAPTIONS.read_text().splitlines() if c.strip()]
    OUT.mkdir(parents=True, exist_ok=True)

    font = load_font(66)
    for i, path in enumerate(files):
        shot = Image.open(path).convert("RGB")
        box_w, box_h = W - 2 * MARGIN, H - CAPTION_H - 90
        scale = min(box_w / shot.width, box_h / shot.height)
        shot = shot.resize((int(shot.width * scale), int(shot.height * scale)), Image.LANCZOS)
        shot = rounded(shot, 48)

        canvas = Image.new("RGB", (W, H), BG)
        draw = ImageDraw.Draw(canvas)

        caption = captions[i] if i < len(captions) else path.stem
        lines = wrap(draw, caption, font, W - 2 * 90)
        line_h = font.size + 14
        y = (CAPTION_H - line_h * len(lines)) // 2 + 20
        for line in lines:
            w = draw.textlength(line, font=font)
            draw.text(((W - w) / 2, y), line, font=font, fill=TEXT)
            y += line_h

        canvas.paste(shot, ((W - shot.width) // 2, CAPTION_H), shot)
        target = OUT / f"{i + 1:02d}.png"
        canvas.save(target)
        print("wrote", target.relative_to(ROOT))


if __name__ == "__main__":
    main()
