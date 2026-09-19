#!/usr/bin/env python3
"""Read-only PNG/catalog checks; requires Pillow. Prints a JSON audit.

Run from the frontend root. Optionally pass the backend checkout to compare
its actual migration icon identifiers against the committed catalog fixture.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path

from PIL import Image

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--backend', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
catalog = json.loads((root / 'test/fixtures/achievement_catalog.json').read_text())
identifiers = {entry['iconUrl'] for entry in catalog}
assert len(catalog) == len(identifiers) == 31
widget = (root / 'lib/core/widgets/riksa_achievement_image.dart').read_text()
mapped = set(re.findall(r"'(/icons/ach-[^']+\.png)'\s*:", widget))
assert mapped == identifiers, f'Mapping differs: {mapped ^ identifiers}'
if args.backend:
    migrations = args.backend / 'src/main/resources/db/migration'
    seeded = set()
    for migration in migrations.glob('*.sql'):
        seeded.update(re.findall(r"'(/icons/ach-[^']+\.png)'", migration.read_text()))
    assert seeded == identifiers, f'Backend catalog differs: {seeded ^ identifiers}'

report = []
for entry in catalog:
    filename = Path(entry['iconUrl']).name
    rank = filename.startswith('ach-rank-')
    asset = root / 'assets/images' / ('ranks' if rank else 'achievements') / (filename.removeprefix('ach-rank-') if rank else filename)
    with Image.open(asset) as im:
        im.load()
        assert im.mode == 'RGBA', f'{asset}: expected RGBA'
        alpha = im.getchannel('A')
        hist = alpha.histogram()
        count = im.width * im.height
        assert hist[0] > count * .1, f'{asset}: missing transparent background'
        assert sum(hist[240:]) > count * .3, f'{asset}: missing opaque artwork'
        assert all(alpha.getpixel(point) == 0 for point in [(0, 0), (im.width - 1, 0), (0, im.height - 1), (im.width - 1, im.height - 1)])
        # Ignore imperceptible alpha noise when measuring visible sizing.
        # Original pixels are preserved, including antialiased edges.
        bounds = alpha.point(lambda value: 255 if value >= 16 else 0).getbbox()
        assert bounds[0] > 0 and bounds[1] > 0 and bounds[2] < im.width and bounds[3] < im.height, f'{asset}: artwork touches canvas edge'
        report.append(dict(**entry, asset=str(asset.relative_to(root)), reusedRank=rank, size=list(im.size), alphaBounds=list(bounds), transparentPixels=hist[0], fullyOpaquePixels=hist[255], nearlyOpaquePixels=sum(hist[240:]), sha256=hashlib.sha256(asset.read_bytes()).hexdigest()))
new = [row for row in report if not row['reusedRank']]
assert len(new) == 26
assert len({tuple(row['size']) for row in new}) == 1
assert len(list((root / 'assets/images/achievements').glob('*.png'))) == 26
print(json.dumps(dict(catalogCount=len(catalog), newImages=26, reusedRanks=5, images=report), indent=2))
