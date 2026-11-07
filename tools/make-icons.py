#!/usr/bin/env python3
"""LiD Koçu — Android ikonlarını Pillow ile çizer (başka araç gerekmez).
Kullanım: python3 tools/make-icons.py
Çıktı: flutter/lid_kocu/android/app/src/main/res/mipmap-*/ (adaptive ön plan/arka plan/tek renkli + eski tip ikonlar)
       store/play-icon-512.png (Play Store ikonu 512x512 PNG)
Tasarım: mavi zemin, beyaz test kâğıdı, sarı başlık şeridi, mavi onay işareti (prototipin renkleri).
"""
import os
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
RES = os.path.join(ROOT, 'flutter', 'lid_kocu', 'android', 'app', 'src', 'main', 'res')
STORE = os.path.join(ROOT, 'store')
BLUE, BLUE_DK, WHITE, YELLOW, INK = (31, 79, 216), (22, 58, 168), (255, 255, 255), (255, 200, 61), (20, 35, 59)
DENS = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
SS = 4  # süper örnekleme


def canvas(px):
    return Image.new('RGBA', (px * SS, px * SS), (0, 0, 0, 0))


def sc(v, px):  # 512'lik çizim uzayından piksele
    return v * px * SS / 512.0


def background(px):
    im = canvas(px)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, px * SS, px * SS), fill=BLUE + (255,))
    d.ellipse((sc(256 - 330, px), sc(256 - 330, px), sc(256 + 330, px), sc(256 + 330, px)), fill=(37, 90, 232, 255))  # merkezde hafif ışık
    return im.resize((px, px), Image.LANCZOS)


def page(d, px, color_page, color_band, color_mark, lines):
    # Güvenli bölge (adaptive): merkezden 156 birim yarıçap; sayfa köşegen yarıçapı ~148
    x0, y0, x1, y1 = 176, 132, 336, 380
    d.rounded_rectangle((sc(x0, px), sc(y0, px), sc(x1, px), sc(y1, px)), radius=sc(22, px), fill=color_page)
    if color_band is not None:
        d.rounded_rectangle((sc(x0, px), sc(y0, px), sc(x1, px), sc(y0 + 52, px)), radius=sc(22, px), fill=color_band)
        d.rectangle((sc(x0, px), sc(y0 + 30, px), sc(x1, px), sc(y0 + 52, px)), fill=color_band)
    pts = [(208, 244), (244, 282), (306, 204)]
    w = sc(26, px)
    d.line([(sc(x, px), sc(y, px)) for x, y in pts], fill=color_mark, width=int(w), joint='curve')
    for x, y in (pts[0], pts[2]):
        r = w / 2
        d.ellipse((sc(x, px) - r, sc(y, px) - r, sc(x, px) + r, sc(y, px) + r), fill=color_mark)
    for y, x_end in lines:
        d.rounded_rectangle((sc(204, px), sc(y, px), sc(x_end, px), sc(y + 14, px)), radius=sc(7, px), fill=lines_color(color_page, color_mark))


def lines_color(color_page, color_mark):
    return (176, 190, 214, 255) if color_page[3] else color_mark


def foreground(px, scale=1.0):
    im = canvas(px)
    d = ImageDraw.Draw(im)
    page(d, px, WHITE + (255,), YELLOW + (255,), BLUE + (255,), [(318, 308), (344, 276)])
    out = im.resize((px, px), Image.LANCZOS)
    if scale != 1.0:
        s = int(round(px * scale))
        small = out.resize((s, s), Image.LANCZOS)
        out = Image.new('RGBA', (px, px), (0, 0, 0, 0))
        out.paste(small, ((px - s) // 2, (px - s) // 2), small)
    return out


def monochrome(px):
    """Android 13+ temalı ikon: yalnızca alfa kullanılır (sayfa çerçevesi + onay işareti)."""
    im = canvas(px)
    d = ImageDraw.Draw(im)
    x0, y0, x1, y1 = 176, 132, 336, 380
    d.rounded_rectangle((sc(x0, px), sc(y0, px), sc(x1, px), sc(y1, px)), radius=sc(22, px), outline=(255, 255, 255, 255), width=int(sc(16, px)))
    pts = [(208, 244), (244, 282), (306, 204)]
    w = sc(26, px)
    d.line([(sc(x, px), sc(y, px)) for x, y in pts], fill=(255, 255, 255, 255), width=int(w), joint='curve')
    for x, y in (pts[0], pts[2]):
        r = w / 2
        d.ellipse((sc(x, px) - r, sc(y, px) - r, sc(x, px) + r, sc(y, px) + r), fill=(255, 255, 255, 255))
    return im.resize((px, px), Image.LANCZOS)


def masked(img, kind):
    w = img.size[0]
    big = w * 4
    mk = Image.new('L', (big, big), 0)
    d = ImageDraw.Draw(mk)
    if kind == 'circle':
        d.ellipse((0, 0, big - 1, big - 1), fill=255)
    else:
        d.rounded_rectangle((0, 0, big - 1, big - 1), radius=int(big * 0.18), fill=255)
    mk = mk.resize((w, w), Image.LANCZOS)
    out = img.copy()
    out.putalpha(mk)
    return out


def main():
    for dn, f in DENS.items():
        out = os.path.join(RES, 'mipmap-' + dn)
        os.makedirs(out, exist_ok=True)
        a = int(round(108 * f))
        foreground(a, 0.96).save(os.path.join(out, 'ic_launcher_foreground.png'), optimize=True)
        background(a).save(os.path.join(out, 'ic_launcher_background.png'), optimize=True)
        monochrome(a).save(os.path.join(out, 'ic_launcher_monochrome.png'), optimize=True)
        l = int(round(48 * f))  # Android 7.x (API 24-25) eski tip ikonlar
        full = background(l)
        full.alpha_composite(foreground(l, 1.2))
        masked(full, 'square').save(os.path.join(out, 'ic_launcher.png'), optimize=True)
        masked(full, 'circle').save(os.path.join(out, 'ic_launcher_round.png'), optimize=True)
    os.makedirs(STORE, exist_ok=True)
    big = background(512)
    big.alpha_composite(foreground(512, 1.3))
    big.convert('RGBA').save(os.path.join(STORE, 'play-icon-512.png'), optimize=True)
    print('ikonlar hazır')


if __name__ == '__main__':
    main()
