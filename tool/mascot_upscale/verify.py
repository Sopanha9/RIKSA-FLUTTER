"""Verify counts, 3x dimensions, output scope, and accepted midpoint gates."""

from __future__ import annotations

import io
import re
import subprocess
from pathlib import Path

from PIL import Image

from upscale import (
    ASSET_ROOT,
    MAX_LOCAL_OUTLINE_DELTA,
    MAX_OUTLINE_COUNT_DELTA,
    MAX_STROKE_WIDTH_DELTA,
    MIN_SILHOUETTE_IOU,
    MOODS,
    ROOT,
    SCALE,
    SPECIES,
    MANUAL_REJECTS,
    assess_pair,
    frame_features,
    git_show,
    open_rgba,
    passes_ghost_gates,
    source_catalog,
    upscale,
)


DART_FILE = ROOT / "lib" / "features" / "mascot" / "domain" / "mascot.dart"
SIZE_LIMIT = 40_000_000


def dart_counts() -> dict[tuple[str, str], int]:
    source = DART_FILE.read_text(encoding="utf-8")
    start = source.index("static const _frameCounts = {")
    end = source.index("\n  };", start)
    section = source[start:end]
    counts: dict[tuple[str, str], int] = {}
    for species in SPECIES:
        match = re.search(
            rf"MascotSpecies\.{re.escape(species)}:\s*\{{(.*?)\}}", section, re.S
        )
        if not match:
            raise RuntimeError(f"Could not read _frameCounts for {species}")
        for mood, count in re.findall(r"MascotMood\.(\w+):\s*(\d+)", match.group(1)):
            counts[(species, mood)] = int(count)
    return counts


def asset_tree_bytes_before() -> int:
    result = subprocess.run(
        [
            "git",
            "ls-tree",
            "-rl",
            "HEAD",
            "--",
            f"{ASSET_ROOT}/capybara",
            f"{ASSET_ROOT}/crocodile",
        ],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    total = 0
    for line in result.stdout.splitlines():
        metadata, _path = line.split("\t", 1)
        total += int(metadata.split()[3])
    return total


def asset_tree_bytes_after() -> int:
    return sum(
        path.stat().st_size
        for species in SPECIES
        for path in (ROOT / ASSET_ROOT / species).rglob("*")
        if path.is_file()
    )


def load_output(path: Path) -> tuple[Image.Image, str, tuple[int, int]]:
    with Image.open(path) as image:
        return image.convert("RGBA"), image.mode, image.size


def main() -> None:
    catalog = source_catalog()
    declared_counts = dart_counts()
    expected_keys = {(species, mood) for species in SPECIES for mood in MOODS}
    if set(declared_counts) != expected_keys:
        missing = sorted(expected_keys - set(declared_counts))
        extra = sorted(set(declared_counts) - expected_keys)
        raise RuntimeError(f"_frameCounts mood mismatch; missing={missing}, extra={extra}")

    total_originals = 0
    total_accepted = 0
    total_rejected = 0
    total_strays: list[str] = []
    for species in SPECIES:
        directory = ROOT / ASSET_ROOT / species
        target_names: set[str] = set()
        for mood in MOODS:
            key = (species, mood)
            entries = catalog[key]
            frames = [open_rgba(git_show(path)) for _, path in entries]
            features = [frame_features(frame) for frame in frames]
            assessments = [
                assess_pair(
                    index,
                    frames[index],
                    frames[(index + 1) % len(frames)],
                    features[index],
                    features[(index + 1) % len(frames)],
                )
                for index in range(len(frames))
            ]
            accepted = [
                assessment
                for assessment in assessments
                if assessment.accepted and (species, mood, assessment.index) not in MANUAL_REJECTS
            ]
            accepted_indexes = {assessment.index for assessment in accepted}
            expected_count = len(entries) + len(accepted)
            if declared_counts[key] != expected_count:
                raise RuntimeError(
                    f"{species}/{mood}: Dart declares {declared_counts[key]}, "
                    f"but ghost gates yield {expected_count} frames"
                )

            for number in range(1, expected_count + 1):
                filename = f"{mood}_{number}.png"
                target_names.add(filename)
                if not (directory / filename).is_file():
                    raise RuntimeError(f"Missing output: {species}/{filename}")

            # Originals occur in the output sequence with accepted midpoints
            # after their preceding source pair.
            for index, (source_number, git_path) in enumerate(entries):
                output_number = index + 1 + sum(
                    1 for accepted_index in accepted_indexes if accepted_index < index
                )
                output_path = directory / f"{mood}_{output_number}.png"
                original = open_rgba(git_show(git_path))
                generated, generated_mode, generated_size = load_output(output_path)
                expected_size = (original.width * SCALE, original.height * SCALE)
                if generated_mode != "RGBA" or generated_size != expected_size:
                    raise RuntimeError(
                        f"{species}/{mood}_{source_number}: output mode/size "
                        f"{generated_mode}/{generated_size}, expected RGBA/{expected_size}"
                    )
                total_originals += 1

            # Every accepted midpoint must match the generated, motion-warped
            # frame and pass all three objective ghost gates.
            for assessment in accepted:
                passed, failures = passes_ghost_gates(assessment.metrics)
                if not passed:
                    raise RuntimeError(
                        f"Accepted {species}/{mood} pair {assessment.index + 1} "
                        f"fails ghost gates: {failures}; metrics={assessment.metrics}"
                    )
                midpoint_number = assessment.index + 2 + sum(
                    1 for accepted_index in accepted_indexes if accepted_index < assessment.index
                )
                midpoint_path = directory / f"{mood}_{midpoint_number}.png"
                generated_midpoint, generated_mode, generated_size = load_output(midpoint_path)
                expected_midpoint = upscale(assessment.midpoint)
                if (
                    generated_mode != "RGBA"
                    or generated_size != expected_midpoint.size
                    or generated_midpoint.tobytes() != expected_midpoint.tobytes()
                ):
                    raise RuntimeError(
                        f"{species}/{mood} accepted pair {assessment.index + 1}: "
                        "saved midpoint differs from its motion-compensated output"
                    )

            total_accepted += len(accepted)
            total_rejected += len(assessments) - len(accepted)
            print(
                f"PASS {species}/{mood}: {expected_count} sequential frames; "
                f"Dart count matches; {len(accepted)} accepted and "
                f"{len(assessments) - len(accepted)} rejected pairs; "
                "all originals are exactly 3x RGBA; accepted midpoints pass ghost gates"
            )

        actual_names = {path.name for path in directory.glob("*.png")}
        total_strays.extend(
            f"{species}/{name}" for name in sorted(actual_names - target_names)
        )
        missing_names = target_names - actual_names
        if missing_names:
            raise RuntimeError(f"Missing {species} PNGs: {sorted(missing_names)}")

    if total_strays:
        raise RuntimeError(f"Stray top-level PNGs: {total_strays}")

    before_bytes = asset_tree_bytes_before()
    after_bytes = asset_tree_bytes_after()
    if after_bytes >= SIZE_LIMIT:
        raise RuntimeError(f"Asset folders are {after_bytes} bytes; limit is {SIZE_LIMIT}")

    print(
        f"PASS all 22 moods: no stray top-level PNGs; {total_originals} Git originals verified"
    )
    print(
        f"PASS midpoint ghost gates: {total_accepted} accepted, {total_rejected} rejected; "
        f"count/stroke deltas <= {MAX_OUTLINE_COUNT_DELTA*100:.0f}%/"
        f"{MAX_STROKE_WIDTH_DELTA*100:.0f}%/{MAX_LOCAL_OUTLINE_DELTA*100:.0f}% local; "
        f"silhouette IoU >= {MIN_SILHOUETTE_IOU:.2f}"
    )
    print(
        f"PASS full species asset folders: {before_bytes:,} bytes before -> "
        f"{after_bytes:,} bytes after ({after_bytes / 1_000_000:.2f} MB); under 40 MB"
    )


if __name__ == "__main__":
    main()
