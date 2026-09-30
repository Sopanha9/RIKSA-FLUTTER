"""Builds every launcher icon from the "Study Duo" design.

The design is a 240-unit square: lime ground, a violet band along the bottom,
the capybara on the right and the crocodile in front of it on the left. Run
from the repo root after changing the design or the buddy sprites:

    python tool/app_icon/make_icons.py
"""
import json
import os

from PIL import Image, ImageDraw

LIME = (0xD5, 0xF0, 0x6A)
VIOLET = (0x76, 0x57, 0xEE)
BAND_TOP = 170  # design units from the top
CAPY = ('assets/images/mascots/capybara/idle_1.png', 112, 64, 132)  # left, top, width
CROC = ('assets/images/mascots/crocodile/idle_1.png', 4, 40, 140)
CORNER = 56  # rounded-corner radius for icons that carry their own shape

MASTER = 1024


def _sprite(path, width):
    img = Image.open(path).convert('RGBA')
    height = round(img.height * width / img.width)
    return img.resize((round(width), height), Image.LANCZOS)


def draw(size, box=None, background=True, foreground=True):
    """The design on a size x size canvas, its 240-unit square mapped onto
    box (x, y, side); the ground and band bleed to the canvas edges."""
    x0, y0, side = box or (0, 0, size)
    unit = side / 240
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    if background:
        ground = ImageDraw.Draw(canvas)
        ground.rectangle([0, 0, size, size], fill=LIME)
        ground.rectangle([0, round(y0 + BAND_TOP * unit), size, size], fill=VIOLET)
    if foreground:
        for path, left, top, width in (CAPY, CROC):
            sprite = _sprite(path, width * unit)
            canvas.alpha_composite(sprite, (round(x0 + left * unit), round(y0 + top * unit)))
    return canvas


def rounded(img):
    mask = Image.new('L', img.size, 0)
    radius = round(img.width * CORNER / 240)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.width - 1, img.height - 1], radius, fill=255)
    out = img.copy()
    out.putalpha(mask)
    return out


def save(img, path, size, alpha=True):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img = img.resize((size, size), Image.LANCZOS)
    (img if alpha else img.convert('RGB')).save(path, optimize=True)


def ios():
    folder = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    full = draw(MASTER)
    with open(f'{folder}/Contents.json') as f:
        images = json.load(f)['images']
    for image in images:
        points = float(image['size'].split('x')[0])
        pixels = round(points * int(image['scale'][0]))
        # iOS masks the corners itself and rejects icons with transparency.
        save(full, f"{folder}/{image['filename']}", pixels, alpha=False)


def android():
    res = 'android/app/src/main/res'
    densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    legacy = rounded(draw(MASTER))
    # Adaptive layers are 108 dp. Every launcher shape, a circle included,
    # shows the middle 66 dp, so the buddies go there; the ground bleeds out.
    layer = 432 * 3
    box = (layer * 21 // 108, layer * 21 // 108, layer * 66 // 108)
    back = draw(layer, box, foreground=False)
    front = draw(layer, box, background=False)
    for name, scale in densities.items():
        save(legacy, f'{res}/mipmap-{name}/ic_launcher.png', round(48 * scale))
        save(back, f'{res}/mipmap-{name}/ic_launcher_background.png', round(108 * scale))
        save(front, f'{res}/mipmap-{name}/ic_launcher_foreground.png', round(108 * scale))
    os.makedirs(f'{res}/mipmap-anydpi-v26', exist_ok=True)
    with open(f'{res}/mipmap-anydpi-v26/ic_launcher.xml', 'w', newline='\n') as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n'
                '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
                '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
                '</adaptive-icon>\n')


def web():
    full = rounded(draw(MASTER))
    for size in (192, 512):
        save(full, f'web/icons/Icon-{size}.png', size)
    # Maskable icons keep the design inside the middle 80 %.
    inset = MASTER // 10
    maskable = draw(MASTER, (inset, inset, MASTER - 2 * inset))
    for size in (192, 512):
        save(maskable, f'web/icons/Icon-maskable-{size}.png', size)
    save(full, 'web/favicon.png', 32)


if __name__ == '__main__':
    ios()
    android()
    web()
    print('icons written')
