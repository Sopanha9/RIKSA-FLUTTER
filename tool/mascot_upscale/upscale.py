"""Upscale mascot strips from HEAD and add only motion-compensated midpoints.

Run from any directory with:
    python tool/mascot_upscale/upscale.py

All source pixels come from ``git show HEAD:<path>`` so repeated runs are
idempotent after the working copies have been replaced.
"""

from __future__ import annotations

import io
import re
import statistics
import subprocess
import dataclasses
from dataclasses import dataclass
from pathlib import Path, PurePosixPath

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[2]
ASSET_ROOT = "assets/images/mascots"
PREVIEW_DIR = ROOT / "tool" / "mascot_upscale" / "preview"
SPECIES = ("capybara", "crocodile")
MOODS = (
    "idle",
    "happy",
    "sad",
    "thinking",
    "sleep",
    "celebrate",
    "greeting",
    "treat",
    "love",
    "walk",
    "trophy",
)
SCALE = 3

# Conservative ghost gates, measured on the original-resolution RGBA frames.
# Outline count and estimated stroke width may each drift at most 15% from the
# two neighbours' average; the warped midpoint silhouette must overlap both.
MAX_OUTLINE_COUNT_DELTA = 0.15
MAX_STROKE_WIDTH_DELTA = 0.15
MAX_LOCAL_OUTLINE_DELTA = 0.22

# Pairs that pass the metrics but show a visible smudge in the 2x review sheet.
# (species, mood, 0-based index of the first frame of the pair).
MANUAL_REJECTS = {
    ("crocodile", "thinking", 1),
    ("crocodile", "celebrate", 6),
    ("crocodile", "happy", 3),
}
MIN_SILHOUETTE_IOU = 0.82
DARK_PIXEL_LUMINANCE = 82
DARK_PIXEL_ALPHA = 112
SILHOUETTE_ALPHA = 64

# Motion search uses 12 px cells, 12 px patches, and offsets within three
# source pixels in every direction.
MOTION_CELL = 12
MOTION_PATCH = 12
MOTION_SEARCH_RADIUS = 3


@dataclass
class FrameFeatures:
    width: int
    height: int
    gray: list[int]
    alpha: list[int]


@dataclass
class PairAssessment:
    index: int
    midpoint: Image.Image
    metrics: dict[str, float]
    mean_motion: float
    max_motion: float
    accepted: bool
    rejected_by: tuple[str, ...]


def git_show(path: str) -> bytes:
    result = subprocess.run(
        ["git", "show", f"HEAD:{path}"],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return result.stdout


def source_catalog() -> dict[tuple[str, str], list[tuple[int, str]]]:
    """List the original, contiguous body frames tracked by HEAD."""
    catalog: dict[tuple[str, str], list[tuple[int, str]]] = {}
    for species in SPECIES:
        tracked = subprocess.run(
            [
                "git",
                "ls-tree",
                "-r",
                "--name-only",
                "HEAD",
                "--",
                f"{ASSET_ROOT}/{species}",
            ],
            cwd=ROOT,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        ).stdout.splitlines()
        for mood in MOODS:
            expression = re.compile(rf"{re.escape(mood)}_(\d+)\.png$")
            matches: list[tuple[int, str]] = []
            for path in tracked:
                if PurePosixPath(path).parent.as_posix() != f"{ASSET_ROOT}/{species}":
                    continue
                match = expression.fullmatch(PurePosixPath(path).name)
                if match:
                    matches.append((int(match.group(1)), path))
            matches.sort()
            numbers = [number for number, _ in matches]
            if not numbers or numbers != list(range(1, len(numbers) + 1)):
                raise RuntimeError(
                    f"HEAD source frames for {species}/{mood} must start at 1 "
                    f"with no gaps; found {numbers}"
                )
            catalog[(species, mood)] = matches
    return catalog


def open_rgba(data: bytes) -> Image.Image:
    with Image.open(io.BytesIO(data)) as source:
        return source.convert("RGBA")


def flat_pixels(image: Image.Image) -> list:
    pixels = image.load()
    return [pixels[x, y] for y in range(image.height) for x in range(image.width)]


def frame_features(image: Image.Image) -> FrameFeatures:
    matte = Image.new("RGBA", image.size, (255, 255, 255, 255))
    gray = Image.alpha_composite(matte, image).convert("L")
    return FrameFeatures(
        image.width,
        image.height,
        [int(value) for value in flat_pixels(gray)],
        [int(value) for value in flat_pixels(image.getchannel("A"))],
    )


def upscale(image: Image.Image) -> Image.Image:
    """Use the established 3x premultiplied Lanczos upscale and sharpening."""
    premultiplied = image.convert("RGBa")
    resized = premultiplied.resize(
        (image.width * SCALE, image.height * SCALE),
        Image.Resampling.LANCZOS,
    )
    red, green, blue, alpha = resized.split()
    sharpen = ImageFilter.UnsharpMask(radius=0.7, percent=40, threshold=3)
    sharpened = [channel.filter(sharpen) for channel in (red, green, blue)]
    bounded = [ImageChops.darker(channel, alpha) for channel in sharpened]
    return Image.merge("RGBa", (*bounded, alpha)).convert("RGBA")


def block_motion(
    first: FrameFeatures, second: FrameFeatures
) -> tuple[list[list[tuple[float, float]]], list[list[bool]]]:
    """Estimate first-to-second displacement on a coarse grid by SAD matching."""
    if (first.width, first.height) != (second.width, second.height):
        raise ValueError("Neighbour frames must have equal dimensions")
    width, height = first.width, first.height
    x_edges = list(range(0, width, MOTION_CELL)) + [width]
    y_edges = list(range(0, height, MOTION_CELL)) + [height]
    vectors: list[list[tuple[float, float]]] = []
    active: list[list[bool]] = []

    for y0, y1 in zip(y_edges, y_edges[1:]):
        vector_row: list[tuple[float, float]] = []
        active_row: list[bool] = []
        for x0, x1 in zip(x_edges, x_edges[1:]):
            center_x = (x0 + x1 - 1) // 2
            center_y = (y0 + y1 - 1) // 2
            patch_half = MOTION_PATCH // 2
            px0 = max(0, center_x - patch_half)
            px1 = min(width, center_x + patch_half)
            py0 = max(0, center_y - patch_half)
            py1 = min(height, center_y + patch_half)
            samples: list[tuple[int, int, int, float]] = []
            visible = 0
            for y in range(py0, py1):
                for x in range(px0, px1):
                    index = y * width + x
                    alpha = first.alpha[index]
                    visible += alpha
                    weight = 2.25 if alpha > 80 and first.gray[index] < 112 else 1.0
                    samples.append((x, y, index, weight))

            if visible < 16 or not samples:
                vector_row.append((0.0, 0.0))
                active_row.append(False)
                continue

            best_cost = float("inf")
            best_offset = (0, 0)
            zero_cost = 0.0
            for dy in range(-MOTION_SEARCH_RADIUS, MOTION_SEARCH_RADIUS + 1):
                for dx in range(-MOTION_SEARCH_RADIUS, MOTION_SEARCH_RADIUS + 1):
                    cost = 0.0
                    for x, y, source_index, weight in samples:
                        tx, ty = x + dx, y + dy
                        if 0 <= tx < width and 0 <= ty < height:
                            target_index = ty * width + tx
                            target_gray = second.gray[target_index]
                            target_alpha = second.alpha[target_index]
                        else:
                            target_gray, target_alpha = 255, 0
                        cost += weight * abs(first.gray[source_index] - target_gray)
                        cost += 0.55 * abs(first.alpha[source_index] - target_alpha)
                    if dx == 0 and dy == 0:
                        zero_cost = cost
                    score = cost + 0.15 * (abs(dx) + abs(dy))
                    if score < best_cost:
                        best_cost = score
                        best_offset = (dx, dy)

            # Ignore weak matches, which usually come from flat fill colors.
            measured_cost = best_cost - 0.15 * (abs(best_offset[0]) + abs(best_offset[1]))
            improvement = (zero_cost - measured_cost) / max(zero_cost, 1.0)
            if (
                best_offset != (0, 0)
                and abs(best_offset[0]) < MOTION_SEARCH_RADIUS
                and abs(best_offset[1]) < MOTION_SEARCH_RADIUS
                and improvement >= 0.08
            ):
                vector_row.append((float(best_offset[0]), float(best_offset[1])))
            else:
                vector_row.append((0.0, 0.0))
            active_row.append(True)
        vectors.append(vector_row)
        active.append(active_row)
    return vectors, active


def node_vectors(
    vectors: list[list[tuple[float, float]]], active: list[list[bool]]
) -> list[list[tuple[float, float]]]:
    """Average neighboring cell matches at shared mesh corners."""
    rows, columns = len(vectors), len(vectors[0])
    nodes: list[list[tuple[float, float]]] = []
    for row in range(rows + 1):
        node_row: list[tuple[float, float]] = []
        for column in range(columns + 1):
            nearby = [
                vectors[r][c]
                for r in (row - 1, row)
                for c in (column - 1, column)
                if 0 <= r < rows and 0 <= c < columns and active[r][c]
            ]
            if nearby:
                node_row.append(
                    (
                        sum(vector[0] for vector in nearby) / len(nearby),
                        sum(vector[1] for vector in nearby) / len(nearby),
                    )
                )
            else:
                node_row.append((0.0, 0.0))
        nodes.append(node_row)
    return nodes


def warp_halfway(
    image: Image.Image,
    nodes: list[list[tuple[float, float]]],
    x_edges: list[int],
    y_edges: list[int],
    source_direction: float,
) -> Image.Image:
    """Warp a source halfway toward/away from the estimated neighbor motion."""
    mesh = []
    scale = 1.0
    for row, (y0, y1) in enumerate(zip(y_edges, y_edges[1:])):
        for column, (x0, x1) in enumerate(zip(x_edges, x_edges[1:])):
            corners = (
                (x0, y0, nodes[row][column]),
                (x0, y1, nodes[row + 1][column]),
                (x1, y1, nodes[row + 1][column + 1]),
                (x1, y0, nodes[row][column + 1]),
            )
            source_quad = tuple(
                coordinate
                for x, y, vector in corners
                for coordinate in (
                    x + source_direction * 0.5 * vector[0] * scale,
                    y + source_direction * 0.5 * vector[1] * scale,
                )
            )
            mesh.append(((x0, y0, x1, y1), source_quad))
    premultiplied = image.convert("RGBa")
    return premultiplied.transform(
        image.size,
        Image.Transform.MESH,
        mesh,
        resample=Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    )


def motion_compensated_midpoint(
    first: Image.Image,
    second: Image.Image,
    first_features: FrameFeatures | None = None,
    second_features: FrameFeatures | None = None,
) -> tuple[Image.Image, float, float, Image.Image, Image.Image]:
    """Warp both RGBA neighbours by half the block-matched motion and blend."""
    first_features = first_features or frame_features(first)
    second_features = second_features or frame_features(second)
    vectors, active = block_motion(first_features, second_features)
    nodes = node_vectors(vectors, active)
    magnitudes = [
        (dx * dx + dy * dy) ** 0.5
        for row, active_row in zip(vectors, active)
        for (dx, dy), is_active in zip(row, active_row)
        if is_active and (dx or dy)
    ]
    mean_motion = statistics.mean(magnitudes) if magnitudes else 0.0
    max_motion = max(magnitudes, default=0.0)

    x_edges = list(range(0, first.width, MOTION_CELL)) + [first.width]
    y_edges = list(range(0, first.height, MOTION_CELL)) + [first.height]
    if max_motion == 0.0:
        first_warped = first.convert("RGBa")
        second_warped = second.convert("RGBa")
    else:
        first_warped = warp_halfway(first, nodes, x_edges, y_edges, -1.0)
        second_warped = warp_halfway(second, nodes, x_edges, y_edges, 1.0)
    midpoint = Image.blend(first_warped, second_warped, 0.5).convert("RGBA")
    return (
        midpoint,
        mean_motion,
        max_motion,
        first_warped.convert("RGBA"),
        second_warped.convert("RGBA"),
    )


def silhouette_iou(first: Image.Image, second: Image.Image) -> float:
    first_alpha = flat_pixels(first.getchannel("A"))
    second_alpha = flat_pixels(second.getchannel("A"))
    intersection = 0
    union = 0
    for a, b in zip(first_alpha, second_alpha):
        av = a > SILHOUETTE_ALPHA
        bv = b > SILHOUETTE_ALPHA
        intersection += av and bv
        union += av or bv
    return intersection / union if union else 1.0


def skeleton_pixel_count(mask: set[tuple[int, int]]) -> int:
    """Zhang-Suen thinning used to estimate dark-stroke centerline length."""
    points = set(mask)
    if not points:
        return 0
    while True:
        changed = False
        for phase in (0, 1):
            remove: list[tuple[int, int]] = []
            for x, y in points:
                neighbors = (
                    (x, y - 1),
                    (x + 1, y - 1),
                    (x + 1, y),
                    (x + 1, y + 1),
                    (x, y + 1),
                    (x - 1, y + 1),
                    (x - 1, y),
                    (x - 1, y - 1),
                )
                values = [neighbor in points for neighbor in neighbors]
                count = sum(values)
                if count < 2 or count > 6:
                    continue
                transitions = sum(
                    not values[index] and values[(index + 1) % 8]
                    for index in range(8)
                )
                if transitions != 1:
                    continue
                north, _, east, _, south, _, west, _ = values
                if phase == 0:
                    if north and east and south:
                        continue
                    if east and south and west:
                        continue
                else:
                    if north and east and west:
                        continue
                    if north and south and west:
                        continue
                remove.append((x, y))
            if remove:
                points.difference_update(remove)
                changed = True
        if not changed:
            return len(points)


def dark_outline_pixels(image: Image.Image) -> set[tuple[int, int]]:
    pixels = flat_pixels(image.convert("RGBA"))
    width, height = image.size
    dark: set[tuple[int, int]] = set()
    for index, (red, green, blue, alpha) in enumerate(pixels):
        luminance = (299 * red + 587 * green + 114 * blue) // 1000
        if alpha >= DARK_PIXEL_ALPHA and luminance <= DARK_PIXEL_LUMINANCE:
            dark.add((index % width, index // width))
    return dark


def outline_metrics(image: Image.Image) -> tuple[int, float]:
    dark = dark_outline_pixels(image)
    count = len(dark)
    skeleton = skeleton_pixel_count(dark)
    thickness = count / skeleton if skeleton else 0.0
    return count, thickness


def local_outline_delta(
    first_warped: Image.Image,
    second_warped: Image.Image,
    midpoint: Image.Image,
) -> float:
    """Check outline count per motion cell to expose local doubled features."""
    masks = [
        dark_outline_pixels(first_warped),
        dark_outline_pixels(second_warped),
        dark_outline_pixels(midpoint),
    ]
    width, height = midpoint.size
    counts: list[dict[tuple[int, int], int]] = []
    for mask in masks:
        current: dict[tuple[int, int], int] = {}
        for x, y in mask:
            cell = (x // MOTION_CELL, y // MOTION_CELL)
            current[cell] = current.get(cell, 0) + 1
        counts.append(current)
    cell_columns = (width + MOTION_CELL - 1) // MOTION_CELL
    cell_rows = (height + MOTION_CELL - 1) // MOTION_CELL
    worst = 0.0
    for row in range(cell_rows):
        for column in range(cell_columns):
            cell = (column, row)
            first_count = counts[0].get(cell, 0)
            second_count = counts[1].get(cell, 0)
            midpoint_count = counts[2].get(cell, 0)
            reference = (first_count + second_count) / 2
            if reference < 20 and midpoint_count < 20:
                continue
            delta = (
                abs(midpoint_count - reference) / reference
                if reference > 0
                else float("inf")
            )
            worst = max(worst, delta)
    return worst


def relative_delta(value: float, reference: float) -> float:
    return abs(value - reference) / reference if reference > 0 else (0.0 if value == 0 else float("inf"))


def ghost_metrics(
    first: Image.Image,
    second: Image.Image,
    midpoint: Image.Image,
    first_warped: Image.Image,
    second_warped: Image.Image,
) -> dict[str, float]:
    outline_a, thickness_a = outline_metrics(first)
    outline_b, thickness_b = outline_metrics(second)
    outline_mid, thickness_mid = outline_metrics(midpoint)
    outline_reference = (outline_a + outline_b) / 2
    thickness_reference = (thickness_a + thickness_b) / 2
    return {
        "outline_a": float(outline_a),
        "outline_b": float(outline_b),
        "outline_mid": float(outline_mid),
        "outline_delta": relative_delta(outline_mid, outline_reference),
        "thickness_a": thickness_a,
        "thickness_b": thickness_b,
        "thickness_mid": thickness_mid,
        "thickness_delta": relative_delta(thickness_mid, thickness_reference),
        "local_outline_delta": local_outline_delta(first_warped, second_warped, midpoint),
        "iou_a": silhouette_iou(midpoint, first),
        "iou_b": silhouette_iou(midpoint, second),
    }


def passes_ghost_gates(metrics: dict[str, float]) -> tuple[bool, tuple[str, ...]]:
    failures = []
    if metrics["outline_delta"] > MAX_OUTLINE_COUNT_DELTA:
        failures.append("outline-count")
    if metrics["thickness_delta"] > MAX_STROKE_WIDTH_DELTA:
        failures.append("stroke-width")
    if metrics["local_outline_delta"] > MAX_LOCAL_OUTLINE_DELTA:
        failures.append("local-outline")
    if min(metrics["iou_a"], metrics["iou_b"]) < MIN_SILHOUETTE_IOU:
        failures.append("silhouette-IoU")
    return not failures, tuple(failures)


def assess_pair(
    index: int,
    first: Image.Image,
    second: Image.Image,
    first_features: FrameFeatures,
    second_features: FrameFeatures,
) -> PairAssessment:
    midpoint, mean_motion, max_motion, warped_first, warped_second = motion_compensated_midpoint(
        first, second, first_features, second_features
    )
    metrics = ghost_metrics(first, second, midpoint, warped_first, warped_second)
    accepted, rejected_by = passes_ghost_gates(metrics)
    return PairAssessment(
        index,
        midpoint,
        metrics,
        mean_motion,
        max_motion,
        accepted,
        rejected_by,
    )


def print_pair_result(
    species: str, mood: str, source_count: int, assessment: PairAssessment
) -> None:
    next_number = (assessment.index + 1) % source_count + 1
    status = "ACCEPT" if assessment.accepted else "REJECT"
    m = assessment.metrics
    reasons = "" if assessment.accepted else f" failed={','.join(assessment.rejected_by)}"
    print(
        f"{status} {species}/{mood} {assessment.index + 1}->{next_number}: "
        f"outline A/M/B={m['outline_a']:.0f}/{m['outline_mid']:.0f}/{m['outline_b']:.0f} "
        f"delta={m['outline_delta'] * 100:.1f}%; "
        f"stroke A/M/B={m['thickness_a']:.2f}/{m['thickness_mid']:.2f}/{m['thickness_b']:.2f} "
        f"delta={m['thickness_delta'] * 100:.1f}%; "
        f"local-outline={m['local_outline_delta'] * 100:.1f}%; "
        f"IoU A/B={m['iou_a']:.3f}/{m['iou_b']:.3f}; "
        f"motion mean/max={assessment.mean_motion:.2f}/{assessment.max_motion:.2f}px"
        f"{reasons}"
    )


def encode_png(image: Image.Image) -> bytes:
    output = io.BytesIO()
    image.convert("RGBA").save(output, format="PNG", optimize=True)
    return output.getvalue()


def make_contact_sheet(
    species: str,
    sources: dict[tuple[str, str], list[tuple[int, bytes]]],
    output_images: dict[tuple[str, str], list[tuple[str, bytes]]],
) -> None:
    """Write a compact overview of original and final mood strips."""
    tile_width, tile_height = 72, 112
    thumb_size = (66, 88)
    label_width, panel_gap = 76, 24
    margin, title_height, row_height = 8, 38, 118
    max_before = max(len(sources[(species, mood)]) for mood in MOODS)
    max_after = max(len(output_images[(species, mood)]) for mood in MOODS)
    before_width = max_before * tile_width
    after_width = max_after * tile_width
    sheet_width = margin * 2 + label_width + before_width + panel_gap + after_width
    sheet_height = margin * 2 + title_height + len(MOODS) * row_height
    sheet = Image.new("RGB", (sheet_width, sheet_height), (242, 242, 242))
    draw = ImageDraw.Draw(sheet)
    before_x = margin + label_width
    after_x = before_x + before_width + panel_gap
    draw.text((before_x, margin + 5), f"{species.title()} - before (Git HEAD)", fill=(24, 24, 24))
    draw.text((after_x, margin + 5), "after (3x upscale + accepted midpoints)", fill=(24, 24, 24))
    divider_x = before_x + before_width + panel_gap // 2
    draw.line((divider_x, margin, divider_x, sheet_height - margin), fill=(180, 180, 180))

    for row, mood in enumerate(MOODS):
        y = margin + title_height + row * row_height
        draw.text((margin, y + 46), mood, fill=(24, 24, 24))
        draw.line((margin, y + row_height - 1, sheet_width - margin, y + row_height - 1), fill=(218, 218, 218))
        before_frames = [open_rgba(data) for _, data in sources[(species, mood)]]
        after_frames = [open_rgba(data) for _, data in output_images[(species, mood)]]
        for panel_x, frames in ((before_x, before_frames), (after_x, after_frames)):
            for index, frame in enumerate(frames):
                tile_x = panel_x + index * tile_width
                matte = Image.new("RGBA", frame.size, (255, 255, 255, 255))
                visible = Image.alpha_composite(matte, frame).convert("RGB")
                thumb = ImageOps.contain(visible, thumb_size, method=Image.Resampling.LANCZOS)
                image_x = tile_x + (tile_width - thumb.width) // 2
                image_y = y + 2 + (thumb_size[1] - thumb.height) // 2
                sheet.paste(thumb, (image_x, image_y))
                draw.text((tile_x + 3, y + 94), str(index + 1), fill=(70, 70, 70))

    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    sheet.save(PREVIEW_DIR / f"{species}_before_after.png", optimize=True)


def make_inbetween_review_sheet(
    species: str,
    accepted_pairs: dict[tuple[str, str], list[PairAssessment]],
    source_frames: dict[tuple[str, str], list[Image.Image]],
    output_images: dict[tuple[str, str], list[tuple[str, bytes]]],
    frame_refs: dict[tuple[str, str], dict[str, dict[int, str]]],
) -> None:
    """Show every accepted A/mid/B triplet at 2x source resolution."""
    groups_by_mood: list[tuple[str, list[tuple[PairAssessment, int, int, tuple[str, str, str], int, int]]]] = []
    blob_maps: dict[str, dict[str, bytes]] = {}
    for mood in MOODS:
        key = (species, mood)
        blob_maps[mood] = dict(output_images[key])
        mood_items = []
        for pair in accepted_pairs[key]:
            a_number = pair.index + 1
            b_number = (pair.index + 1) % len(source_frames[key]) + 1
            refs = frame_refs[key]
            width, height = source_frames[key][pair.index].size
            filenames = (
                refs["original"][a_number],
                refs["midpoint"][pair.index],
                refs["original"][b_number],
            )
            mood_items.append((pair, a_number, b_number, filenames, width, height))
        if mood_items:
            groups_by_mood.append((mood, mood_items))

    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    title_height, margin = 34, 10
    if not groups_by_mood:
        sheet = Image.new("RGB", (640, 90), (242, 242, 242))
        ImageDraw.Draw(sheet).text(
            (margin, margin), f"{species.title()}: no midpoint pairs passed the ghost gates", fill=(24, 24, 24)
        )
        sheet.save(PREVIEW_DIR / f"{species}_inbetween_review.png", optimize=True)
        return

    # Two pair groups share a row. Each mood keeps its own tile dimensions so
    # a large strip cannot inflate every other mood's 2x review images.
    rows: list[list[tuple[str, list[tuple[PairAssessment, int, int, tuple[str, str, str], int, int]]]]] = []
    for mood, mood_items in groups_by_mood:
        for start in range(0, len(mood_items), 2):
            rows.append([(mood, mood_items[start : start + 2])])

    row_widths = []
    row_heights = []
    for row in rows:
        width = margin * 2
        height = 0
        for _mood, pair_items in row:
            for _pair, _a, _b, _names, original_width, original_height in pair_items:
                tile_width = original_width * 2 + 12
                width += 3 * tile_width + 16
                height = max(height, 48 + original_height * 2)
        row_widths.append(width)
        row_heights.append(height + 10)

    sheet_width = max(row_widths) if row_widths else 640
    sheet_height = margin * 2 + title_height + sum(row_heights)
    sheet = Image.new("RGB", (sheet_width, sheet_height), (242, 242, 242))
    draw = ImageDraw.Draw(sheet)
    draw.text(
        (margin, margin + 5),
        f"{species.title()} - accepted motion-compensated pairs (2x zoom)",
        fill=(24, 24, 24),
    )

    y0 = margin + title_height
    for row, row_height in zip(rows, row_heights):
        x0 = margin
        for mood, pair_items in row:
            blobs = blob_maps[mood]
            for pair, a_number, b_number, filenames, original_width, original_height in pair_items:
                frame_width, frame_height = original_width * 2, original_height * 2
                tile_width = frame_width + 12
                metrics = pair.metrics
                draw.text(
                    (x0, y0),
                    f"{mood} {a_number}->{b_number} outline {metrics['outline_delta']*100:.1f}% "
                    f"stroke {metrics['thickness_delta']*100:.1f}% local {metrics['local_outline_delta']*100:.1f}% "
                    f"IoU {metrics['iou_a']:.2f}/{metrics['iou_b']:.2f}",
                    fill=(24, 24, 24),
                )
                labels = (
                    f"A: {mood}_{a_number}",
                    f"mid {a_number}->{b_number}",
                    f"B: {mood}_{b_number}",
                )
                for column, (filename, label) in enumerate(zip(filenames, labels)):
                    x = x0 + column * tile_width
                    draw.text((x + 3, y0 + 17), label, fill=(65, 65, 65))
                    with Image.open(io.BytesIO(blobs[filename])) as source:
                        frame = source.convert("RGBA")
                        target_size = (frame.width * 2 // SCALE, frame.height * 2 // SCALE)
                        frame = frame.resize(target_size, Image.Resampling.LANCZOS)
                    matte = Image.new("RGBA", frame.size, (255, 255, 255, 255))
                    visible = Image.alpha_composite(matte, frame).convert("RGB")
                    image_x = x + (frame_width - visible.width) // 2
                    sheet.paste(visible, (image_x, y0 + 34))
                x0 += 3 * tile_width + 16
        y0 += row_height

    sheet.save(PREVIEW_DIR / f"{species}_inbetween_review.png", optimize=True)


def prepare_outputs(
    catalog: dict[tuple[str, str], list[tuple[int, str]]]
) -> tuple[
    dict[tuple[str, str], list[tuple[int, bytes]]],
    dict[tuple[str, str], list[tuple[str, bytes]]],
    dict[tuple[str, str], list[Image.Image]],
    dict[tuple[str, str], list[PairAssessment]],
    dict[tuple[str, str], dict[str, dict[int, str]]],
    dict[tuple[str, str], tuple[int, int]],
]:
    sources: dict[tuple[str, str], list[tuple[int, bytes]]] = {}
    output_images: dict[tuple[str, str], list[tuple[str, bytes]]] = {}
    source_frames: dict[tuple[str, str], list[Image.Image]] = {}
    accepted_pairs: dict[tuple[str, str], list[PairAssessment]] = {}
    frame_refs: dict[tuple[str, str], dict[str, dict[int, str]]] = {}
    pair_counts: dict[tuple[str, str], tuple[int, int]] = {}

    for species in SPECIES:
        for mood in MOODS:
            key = (species, mood)
            originals = [(number, git_show(path)) for number, path in catalog[key]]
            images = [open_rgba(data) for _, data in originals]
            source_frames[key] = images
            sources[key] = originals
            features = [frame_features(image) for image in images]
            assessments: list[PairAssessment] = []
            for index, first in enumerate(images):
                next_index = (index + 1) % len(images)
                assessment = assess_pair(
                    index,
                    first,
                    images[next_index],
                    features[index],
                    features[next_index],
                )
                if (species, mood, index) in MANUAL_REJECTS:
                    assessment = dataclasses.replace(
                        assessment, accepted=False, rejected_by=("manual-smudge",)
                    )
                assessments.append(assessment)
                print_pair_result(species, mood, len(images), assessment)

            accepted = [assessment for assessment in assessments if assessment.accepted]
            rejected_count = len(assessments) - len(accepted)
            accepted_pairs[key] = accepted
            pair_counts[key] = (len(accepted), rejected_count)
            accepted_by_index = {assessment.index: assessment for assessment in accepted}

            sequence: list[tuple[Image.Image, str, int]] = []
            scaled_originals = [upscale(image) for image in images]
            for index, scaled in enumerate(scaled_originals):
                sequence.append((scaled, "original", index + 1))
                if index in accepted_by_index:
                    sequence.append((upscale(accepted_by_index[index].midpoint), "midpoint", index))

            encoded: list[tuple[str, bytes]] = []
            refs: dict[str, dict[int, str]] = {"original": {}, "midpoint": {}}
            for output_number, (image, kind, source_index) in enumerate(sequence, start=1):
                filename = f"{mood}_{output_number}.png"
                encoded.append((filename, encode_png(image)))
                refs[kind][source_index] = filename
            output_images[key] = encoded
            frame_refs[key] = refs

    return sources, output_images, source_frames, accepted_pairs, frame_refs, pair_counts


def write_assets(output_images: dict[tuple[str, str], list[tuple[str, bytes]]]) -> None:
    for species in SPECIES:
        directory = ROOT / ASSET_ROOT / species
        for path in directory.glob("*.png"):
            if any(re.fullmatch(rf"{re.escape(mood)}_\d+\.png", path.name) for mood in MOODS):
                path.unlink()
        for mood in MOODS:
            for filename, data in output_images[(species, mood)]:
                (directory / filename).write_bytes(data)


def main() -> None:
    print(
        "Ghost gates: outline count delta <= 15.0%; stroke-width delta <= 15.0%; "
        "local 12px-cell outline delta <= 40.0%; "
        "silhouette IoU with both neighbors >= 0.820"
    )
    catalog = source_catalog()
    sources, output_images, source_frames, accepted_pairs, frame_refs, pair_counts = prepare_outputs(catalog)

    total_accepted = sum(accepted for accepted, _ in pair_counts.values())
    total_rejected = sum(rejected for _, rejected in pair_counts.values())
    print(f"Pair totals: accepted={total_accepted}, rejected={total_rejected}")
    print("Per-mood pair totals (accepted/rejected):")
    for species in SPECIES:
        print(f"{species}:")
        for mood in MOODS:
            accepted, rejected = pair_counts[(species, mood)]
            print(f"  {mood}: {accepted}/{rejected}")

    for species in SPECIES:
        make_contact_sheet(species, sources, output_images)
        make_inbetween_review_sheet(species, accepted_pairs, source_frames, output_images, frame_refs)

    write_assets(output_images)

    print("New frame counts (before -> after):")
    for species in SPECIES:
        print(f"{species}:")
        for mood in MOODS:
            before = len(sources[(species, mood)])
            after = len(output_images[(species, mood)])
            print(f"  {mood}: {before} -> {after}")


if __name__ == "__main__":
    main()
