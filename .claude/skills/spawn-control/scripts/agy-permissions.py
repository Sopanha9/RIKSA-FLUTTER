#!/usr/bin/env python3
"""Manage the narrow Agy permission profile used by the spawn-control skill.

Headless `agy -p` cannot prompt for tool approval, so a review worker dies on
its first `rg` or `git status` unless the grants already exist. This installs
exactly the read-only grants a review worker needs — nothing wider.

    agy-permissions.py check      # report readiness, change nothing
    agy-permissions.py install    # add only missing grants, backup first
    agy-permissions.py restore    # restore this tool's backup

Exit codes: 0 ready/done, 1 not ready, 2 malformed or unusable config.

Permissions are not a security boundary. Isolation is: Agy still runs against a
disposable clone, never the user's tree.

Standard library only. On Windows the interpreter is usually `python`, not
`python3`.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
import tempfile
from pathlib import Path

# Read-only inspection only. Deliberately excludes `command(git)` (which would
# cover add/commit/reset/clean/push) and anything that builds, tests, installs
# or mutates. The orchestrator runs builds, analyzers and tests itself.
REQUIRED_GRANTS = [
    "command(git status)",
    "command(git diff)",
    "command(git log)",
    "command(git show)",
    "command(git ls-files)",
    "command(rg)",
    "command(grep)",
]

BACKUP_SUFFIX = ".spawn-control.bak"


def default_settings_path() -> Path:
    return Path.home() / ".gemini" / "antigravity-cli" / "settings.json"


def is_wildcard(grant: str) -> bool:
    """True for grants that widen beyond a named target."""
    if "*" in grant:
        return True
    return grant.strip() in {"command", "command()"}


class ConfigError(Exception):
    """Settings file exists but cannot be used safely."""


def load_settings(path: Path) -> tuple[dict, bool]:
    """Return (settings, existed). A missing file yields an empty dict."""
    if not path.exists():
        return {}, False
    try:
        raw = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise ConfigError(f"cannot read {path}: {exc}") from exc
    if not raw.strip():
        return {}, True
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ConfigError(f"malformed JSON in {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise ConfigError(f"{path}: expected a JSON object at the top level")
    return data, True


def existing_grants(settings: dict) -> list[str]:
    perms = settings.get("permissions")
    if perms is None:
        return []
    if not isinstance(perms, dict):
        raise ConfigError("'permissions' is present but is not an object")
    allow = perms.get("allow", [])
    if allow is None:
        return []
    if not isinstance(allow, list):
        raise ConfigError("'permissions.allow' is present but is not a list")
    for item in allow:
        if not isinstance(item, str):
            raise ConfigError(
                f"'permissions.allow' contains a non-string entry: {item!r}"
            )
    return allow


def atomic_write_json(path: Path, data: dict) -> None:
    """Serialize, re-parse to prove validity, then replace in one step."""
    text = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    json.loads(text)  # refuse to write anything we cannot read back

    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(
        dir=str(path.parent), prefix=path.name + ".", suffix=".tmp"
    )
    tmp = Path(tmp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp, path)
    except BaseException:
        tmp.unlink(missing_ok=True)
        raise


def cmd_check(path: Path) -> int:
    print("Agy permission preflight")
    print(f"  settings: {path}")
    print()

    try:
        settings, existed = load_settings(path)
        grants = existing_grants(settings)
    except ConfigError as exc:
        print(f"ERROR   {exc}", file=sys.stderr)
        print("\nResult: UNUSABLE CONFIG", file=sys.stderr)
        return 2

    if not existed:
        print("  settings file does not exist yet")
        print()

    have = set(grants)
    missing = []
    for grant in REQUIRED_GRANTS:
        if grant in have:
            print(f"OK      {grant}")
        else:
            print(f"MISSING {grant}")
            missing.append(grant)

    extra = [g for g in grants if g not in REQUIRED_GRANTS]
    if extra:
        print()
        print("Also present (not required by spawn-control, left untouched):")
        for grant in sorted(set(extra)):
            flag = "  WILDCARD -> " if is_wildcard(grant) else "  "
            print(f"{flag}{grant}")

    wildcards = [g for g in grants if is_wildcard(g)]
    if wildcards:
        print()
        print(
            "WARNING: wildcard grant(s) present. This tool never adds these; "
            "consider removing them.",
            file=sys.stderr,
        )

    print()
    if missing:
        print("Result: NOT READY")
        print(f"        {len(missing)} grant(s) missing; run 'install' to add them")
        return 1
    print("Result: READY")
    return 0


def cmd_install(path: Path) -> int:
    try:
        settings, existed = load_settings(path)
        grants = existing_grants(settings)
    except ConfigError as exc:
        print(f"ERROR   {exc}", file=sys.stderr)
        print("Refusing to modify a config this tool cannot parse.", file=sys.stderr)
        return 2

    have = set(grants)
    missing = [g for g in REQUIRED_GRANTS if g not in have]

    if not missing:
        print(f"Nothing to add — all {len(REQUIRED_GRANTS)} required grants present.")
        print(f"Preserved {len(grants)} existing grant(s).")
        print()
        print("Agy permissions: READY")
        return 0

    # Never overwrite an existing known-good backup with a later state.
    backup = path.with_name(path.name + BACKUP_SUFFIX)
    if existed:
        if backup.exists():
            print(f"Backup already exists, keeping it: {backup}")
        else:
            shutil.copy2(path, backup)
            print(f"Backup written: {backup}")
    else:
        print(f"No settings file at {path} — creating a minimal one.")

    # Dedupe while preserving the original order, then append what is missing.
    merged: list[str] = []
    for grant in grants:
        if grant not in merged:
            merged.append(grant)
    deduped = len(grants) - len(merged)
    added = []
    for grant in missing:
        if is_wildcard(grant):  # defensive; REQUIRED_GRANTS has none
            continue
        merged.append(grant)
        added.append(grant)

    permissions = settings.get("permissions")
    if not isinstance(permissions, dict):
        permissions = {}
    permissions["allow"] = merged
    settings["permissions"] = permissions

    try:
        atomic_write_json(path, settings)
    except (OSError, ValueError) as exc:
        print(f"ERROR   write failed, original left intact: {exc}", file=sys.stderr)
        return 2

    print()
    print("Added:")
    for grant in added:
        print(f"  {grant}")
    if deduped:
        print(f"\nRemoved {deduped} duplicate grant entr(y|ies).")
    print(f"\nPreserved {len(merged) - len(added)} existing grant(s).")
    print()
    print("Agy permissions: READY")
    return 0


def cmd_restore(path: Path) -> int:
    backup = path.with_name(path.name + BACKUP_SUFFIX)
    if not backup.exists():
        print(f"No backup from this tool at {backup}", file=sys.stderr)
        return 2
    try:
        data = json.loads(backup.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR   backup is unusable: {exc}", file=sys.stderr)
        return 2
    if not isinstance(data, dict):
        print("ERROR   backup is not a JSON object", file=sys.stderr)
        return 2
    try:
        atomic_write_json(path, data)
    except (OSError, ValueError) as exc:
        print(f"ERROR   restore failed: {exc}", file=sys.stderr)
        return 2
    print(f"Restored {path}")
    print(f"  from {backup}")
    print("Backup left in place.")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Manage the narrow Agy permission profile for spawn-control."
    )
    parser.add_argument("action", choices=["check", "install", "restore"])
    parser.add_argument(
        "--settings",
        type=Path,
        default=None,
        help="override the settings path (testing)",
    )
    args = parser.parse_args(argv)

    path = args.settings or default_settings_path()
    return {
        "check": cmd_check,
        "install": cmd_install,
        "restore": cmd_restore,
    }[args.action](path)


if __name__ == "__main__":
    sys.exit(main())
