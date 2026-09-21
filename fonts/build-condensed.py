#!/usr/bin/env python3
"""Regenerates Bescii-Mono-Condensed.ttf from Bescii-Mono.ttf.

Requires fontTools (`sudo pacman -S python-fonttools`, or `pip install
fonttools`). Run from anywhere:

    python3 build-condensed.py

Two things done to the source font, both explained in LICENSE.txt:

1. Every glyph outline and advance width scaled 0.606x horizontally, to
   match JetBrainsMono's glyph width — Bescii Mono's glyphs render ~65%
   wider than JetBrainsMono's at the same point size, which overflows the
   fixed-width column layouts some Omarchy shell panels use.

2. Every Private Use Area cmap entry removed. Bescii maps its own "pixel
   art for games" glyphs into the same PUA range Nerd Font icons live in
   (confirmed collision: U+F026-U+F028, the volume/speaker icon glyphs
   used by the Omarchy audio panel — Bescii's own art rendered there
   instead of the real icon). Removing the mappings lets those codepoints
   correctly fall through to a real icon-capable font instead.
"""
import sys
from pathlib import Path

from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.transformPen import TransformPen

HERE = Path(__file__).resolve().parent
SRC = HERE / "Bescii-Mono.ttf"
DEST = HERE / "Bescii-Mono-Condensed.ttf"
SCALE = 0.606


def is_pua(codepoint):
    return (
        0xE000 <= codepoint <= 0xF8FF
        or 0xF0000 <= codepoint <= 0xFFFFD
        or 0x100000 <= codepoint <= 0x10FFFD
    )


def main():
    font = TTFont(str(SRC))
    glyf = font["glyf"]
    hmtx = font["hmtx"]
    glyph_set = font.getGlyphSet()

    for name in font.getGlyphOrder():
        pen = TTGlyphPen(glyph_set)
        glyph_set[name].draw(TransformPen(pen, (SCALE, 0, 0, 1, 0, 0)))
        glyf[name] = pen.glyph()
        aw, lsb = hmtx[name]
        hmtx[name] = (round(aw * SCALE), round(lsb * SCALE))

    for tbl, attr in (("hhea", "advanceWidthMax"), ("OS/2", "xAvgCharWidth")):
        if tbl in font and hasattr(font[tbl], attr):
            setattr(font[tbl], attr, round(getattr(font[tbl], attr) * SCALE))

    removed = 0
    for table in font["cmap"].tables:
        for cp in list(table.cmap.keys()):
            if is_pua(cp):
                del table.cmap[cp]
                removed += 1

    # nameID 16 ("preferred family") is what fontconfig actually keys on —
    # it's just "Bescii" in the source, not "Bescii Mono", so a naive
    # find-and-replace on "Bescii Mono" alone misses it and leaves a
    # collision with the original font's family alias.
    for rec in font["name"].names:
        s = rec.toUnicode()
        if rec.nameID in (1, 4, 16) and s == "Bescii Mono":
            rec.string = "Bescii Mono Condensed"
        elif rec.nameID == 16 and s == "Bescii":
            rec.string = "Bescii Condensed"
        elif rec.nameID == 6 and s == "Bescii-Mono":
            rec.string = "Bescii-Mono-Condensed"
        elif rec.nameID == 3 and "Bescii-Mono" in s:
            rec.string = s.replace("Bescii-Mono", "Bescii-Mono-Condensed")

    font.save(str(DEST))
    print(f"wrote {DEST} (scaled {SCALE}x, removed {removed} PUA cmap entries)")


if __name__ == "__main__":
    if not SRC.exists():
        sys.exit(f"missing source font: {SRC}")
    main()
