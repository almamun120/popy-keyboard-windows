#!/usr/bin/env python3
"""Builds 'Keyboard and Spell checker/popy_tray.res' (tray icons TRAYBN = Bangla mode, TRAYEN = system default mode)."""
import io, os, struct, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw
import make_branding as mb
from resio import write_res

SIZES = (16, 20, 24, 32)


def english_icon(size):
    S = 256
    g = mb.gradient(S, S, [(0, (148, 163, 184)), (1, (71, 85, 105))], angle=125).convert("RGBA")
    d = ImageDraw.Draw(g)
    f = mb.ImageFont.truetype(mb.FONT, int(S * 0.70), layout_engine=mb.ImageFont.Layout.RAQM)
    bb = d.textbbox((0, 0), "A", font=f)
    d.text(((S - (bb[2] - bb[0])) / 2 - bb[0], (S - (bb[3] - bb[1])) / 2 - bb[1]), "A", font=f, fill=(255, 255, 255, 255))
    g.putalpha(mb.rounded_mask(S, int(S * 0.22)))
    return g.resize((size, size), Image.LANCZOS)


def group(images, first_id):
    grp = struct.pack("<HHH", 0, 1, len(images)); res = []
    for k, im in enumerate(images):
        d = mb.ico_bmp_entry(im); w = im.size[0]
        grp += struct.pack("<BBBBHHIH", w, w, 0, 0, 1, 32, len(d), first_id + k)
        res.append((3, first_id + k, 0x1010, 1033, d))
    return grp, res


bn_grp, bn_res = group([mb.icon_image(s) for s in SIZES], 101)
en_grp, en_res = group([english_icon(s) for s in SIZES], 201)
entries = bn_res + en_res + [(14, "TRAYBN", 0x1030, 1033, bn_grp), (14, "TRAYEN", 0x1030, 1033, en_grp)]
out = os.path.join(mb.ROOT, "Keyboard and Spell checker", "popy_tray.res")
open(out, "wb").write(write_res(entries))
print("wrote", out)
