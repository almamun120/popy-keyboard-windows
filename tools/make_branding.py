#!/usr/bin/env python3
"""Generates every Popy Keyboard image: icons, splash, About banner, installer wizard images.
Run:  python tools/make_branding.py      (needs Pillow with raqm for Bengali shaping)
Outputs go to assets/icons, assets/images and tools/generated/ ."""
import io, math, os, struct, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
FONT = os.path.join(ROOT, "assets", "fonts", "kalpurush.ttf")
OUT = os.path.join(ROOT, "tools", "generated")
os.makedirs(OUT, exist_ok=True)

C1, C2, C3 = (46, 16, 101), (124, 58, 237), (20, 184, 166)   # indigo -> violet -> teal
WHITE = (255, 255, 255)


def font(size):
    return ImageFont.truetype(FONT, size, layout_engine=ImageFont.Layout.RAQM)


def gradient(w, h, stops, angle=135):
    """Linear gradient; stops = [(pos, (r,g,b))...]."""
    a = math.radians(angle)
    dx, dy = math.cos(a), math.sin(a)
    img = Image.new("RGB", (w, h))
    px = img.load()
    mx = abs(dx) * w + abs(dy) * h
    for y in range(h):
        for x in range(w):
            t = ((x - w / 2) * dx + (y - h / 2) * dy) / mx + 0.5
            t = min(1, max(0, t))
            for i in range(len(stops) - 1):
                p0, c0 = stops[i]; p1, c1 = stops[i + 1]
                if t <= p1:
                    u = (t - p0) / (p1 - p0) if p1 > p0 else 0
                    px[x, y] = tuple(int(c0[k] + (c1[k] - c0[k]) * u) for k in range(3))
                    break
    return img


def waves(w, h, seed=7, n=7):
    """Soft flowing lines on a transparent layer."""
    rnd = random.Random(seed)
    S = 3
    lay = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    for i in range(n):
        amp = rnd.uniform(0.05, 0.16) * h * S
        ph = rnd.uniform(0, 6.28)
        fr = rnd.uniform(1.0, 2.2) * 6.28 / (w * S)
        base = (0.3 + 0.55 * i / n) * h * S
        pts = [(x, base + amp * math.sin(x * fr + ph)) for x in range(0, w * S, 4)]
        d.line(pts, fill=(255, 255, 255, rnd.randint(28, 70)), width=max(2, S))
    return lay.resize((w, h), Image.LANCZOS)


def rounded_mask(size, radius, scale=4):
    m = Image.new("L", (size * scale, size * scale), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size * scale - 1, size * scale - 1], radius * scale, fill=255)
    return m.resize((size, size), Image.LANCZOS)


def icon_image(size):
    """App icon: rounded gradient square with a white Bengali 'প' and a small key-cap accent."""
    S = max(size, 256)
    g = gradient(S, S, [(0, C3), (0.5, C2), (1, C1)], angle=125).convert("RGBA")
    g.alpha_composite(waves(S, S, seed=3, n=5))
    d = ImageDraw.Draw(g)
    f = font(int(S * 0.78))
    bb = d.textbbox((0, 0), "প", font=f)
    tx = (S - (bb[2] - bb[0])) / 2 - bb[0]
    ty = (S - (bb[3] - bb[1])) / 2 - bb[1] - S * 0.02
    sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(sh).text((tx + S * 0.012, ty + S * 0.02), "প", font=f, fill=(0, 0, 0, 110))
    g.alpha_composite(sh.filter(ImageFilter.GaussianBlur(S * 0.012)))
    d = ImageDraw.Draw(g)
    d.text((tx, ty), "প", font=f, fill=WHITE)
    # keyboard accent: three small caps under the letter
    cw, ch, gap = S * 0.11, S * 0.045, S * 0.03
    x0 = (S - (3 * cw + 2 * gap)) / 2
    y0 = S * 0.88
    for i in range(3):
        d.rounded_rectangle([x0 + i * (cw + gap), y0, x0 + i * (cw + gap) + cw, y0 + ch], ch / 3, fill=(255, 255, 255, 200))
    g.putalpha(rounded_mask(S, int(S * 0.22)))
    return g.resize((size, size), Image.LANCZOS)


def ico_bmp_entry(img):
    """One BMP (DIB, 32 bit BGRA) icon image - understood by every Delphi/Windows version."""
    w, h = img.size
    px = img.convert("RGBA").load()
    xor = bytearray()
    for y in range(h - 1, -1, -1):
        for x in range(w):
            r, g, b, a = px[x, y]
            xor += bytes((b, g, r, a))
    row = ((w + 31) // 32) * 4
    andm = bytearray()
    for y in range(h - 1, -1, -1):
        bits = bytearray(row)
        for x in range(w):
            if px[x, y][3] < 128:
                bits[x // 8] |= 0x80 >> (x % 8)
        andm += bits
    hdr = struct.pack("<IiiHHIIiiII", 40, w, h * 2, 1, 32, 0, len(xor) + len(andm), 0, 0, 0, 0)
    return hdr + bytes(xor) + bytes(andm)


def build_ico(sizes, png_for=(256,)):
    entries = []
    for s in sizes:
        im = icon_image(s)
        if s in png_for:
            b = io.BytesIO(); im.save(b, "PNG"); data = b.getvalue()
        else:
            data = ico_bmp_entry(im)
        entries.append((s, data))
    out = struct.pack("<HHH", 0, 1, len(entries))
    off = 6 + 16 * len(entries)
    for s, data in entries:
        out += struct.pack("<BBBBHHII", 0 if s >= 256 else s, 0 if s >= 256 else s, 0, 0, 1, 32, len(data), off)
        off += len(data)
    return out + b"".join(d for _, d in entries)


def text_center(d, xy, s, f, fill):
    bb = d.textbbox((0, 0), s, font=f)
    d.text((xy[0] - (bb[2] - bb[0]) / 2 - bb[0], xy[1] - (bb[3] - bb[1]) / 2 - bb[1]), s, font=f, fill=fill)


def splash(w=474, h=317):
    g = gradient(w, h, [(0, C1), (0.55, C2), (1, C3)], angle=20).convert("RGBA")
    g.alpha_composite(waves(w, h, seed=11, n=9))
    d = ImageDraw.Draw(g)
    big = font(int(h * 0.95))
    sh = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(sh).text((w * 0.60, -h * 0.10), "প", font=big, fill=(255, 255, 255, 38))
    g.alpha_composite(sh)
    ic = icon_image(96)
    g.alpha_composite(ic, (34, 52))
    d = ImageDraw.Draw(g)
    d.text((150, 56), "Popy Keyboard", font=ImageFont.truetype(FONT, 40, layout_engine=ImageFont.Layout.RAQM), fill=WHITE)
    d.text((152, 112), "পপি কিবোর্ড", font=font(26), fill=(255, 255, 255, 230))
    d.text((152, 150), "বাংলা ফোনেটিক টাইপিং", font=font(17), fill=(255, 255, 255, 200))
    d.rounded_rectangle([34, h - 46, w - 34, h - 40], 3, fill=(255, 255, 255, 60))
    d.rounded_rectangle([34, h - 46, 34 + (w - 68) * 0.35, h - 40], 3, fill=(255, 255, 255, 220))
    d.text((34, h - 30), "Starting…", font=ImageFont.truetype(FONT, 12), fill=(255, 255, 255, 200))
    return g.convert("RGB")


def side_banner(w=164, h=314):
    g = gradient(w, h, [(0, C3), (0.45, C2), (1, C1)], angle=75).convert("RGBA")
    g.alpha_composite(waves(w, h, seed=5, n=8))
    big = font(int(h * 0.8))
    sh = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(sh).text((-w * 0.1, h * 0.12), "প", font=big, fill=(255, 255, 255, 40))
    g.alpha_composite(sh)
    g.alpha_composite(icon_image(88), ((w - 88) // 2, 28))
    d = ImageDraw.Draw(g)
    text_center(d, (w / 2, 150), "Popy", ImageFont.truetype(FONT, 30, layout_engine=ImageFont.Layout.RAQM), WHITE)
    text_center(d, (w / 2, 182), "Keyboard", ImageFont.truetype(FONT, 22, layout_engine=ImageFont.Layout.RAQM), (255, 255, 255, 230))
    text_center(d, (w / 2, 222), "বাংলা টাইপিং হোক", font(15), (255, 255, 255, 220))
    text_center(d, (w / 2, 244), "আরও সহজ", font(15), (255, 255, 255, 220))
    return g.convert("RGB")


def main():
    ico = build_ico([16, 24, 32, 48, 64, 128, 256])
    open(os.path.join(ROOT, "assets", "icons", "Popy.ico"), "wb").write(ico)
    for n, sizes in (("icon16", [16]), ("icon32", [32]), ("icon128", [128])):
        open(os.path.join(OUT, n + ".ico"), "wb").write(build_ico(sizes, png_for=()))
    sp = splash(); sp.save(os.path.join(OUT, "splash.jpg"), "JPEG", quality=92); sp.save(os.path.join(OUT, "splash.png"))
    sb = side_banner(); sb.save(os.path.join(OUT, "about_side.bmp"), "BMP"); sb.save(os.path.join(OUT, "about_side.png"))
    # Inno Setup wizard images
    wl = side_banner(164, 314); wl.save(os.path.join(ROOT, "assets", "images", "installer-wizard-large.bmp"), "BMP")
    ws = icon_image(55).convert("RGB") if False else Image.alpha_composite(Image.new("RGBA", (55, 55), (255, 255, 255, 255)), icon_image(55)).convert("RGB")
    ws.save(os.path.join(ROOT, "assets", "images", "installer-wizard-small.bmp"), "BMP")
    icon_image(256).save(os.path.join(OUT, "icon256.png"))
    print("done")


if __name__ == "__main__":
    main()
