#!/usr/bin/env python3
"""classify-dirty-noise.py — Classify a target repo's dirty working tree.

Splits `git status --porcelain=v1 -z` entries into two buckets:

  * tolerated noise — generated/OS scratch that should never make a repo
    unauditable: `__pycache__/` dirs, `*.pyc`/`*.pyo` bytecode, `.DS_Store`,
    and the repo-star `work/` scratch convention.
  * meaningful     — everything else (real uncommitted source changes).

The dirty-start guard (scripts/operation-guard.sh) uses this to degrade
gracefully: a tree dirty only with noise proceeds (with the tolerated noise
recorded for transparency), while meaningful uncommitted changes still block.

Usage: python3 scripts/classify-dirty-noise.py <repo_path>

Always exits 0 after emitting a JSON classification on stdout. If git status
cannot be read (not a git repo, no git binary), it reports git_available=false
with zero entries so callers can fall back to their own handling.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

# Cap the number of example paths echoed into the classification so a large
# scratch tree does not bloat the scorecard/guard output.
MAX_EXAMPLE_PATHS = 20


def is_noise_path(path: str) -> bool:
    """True when a dirty path is generated/OS scratch rather than source."""
    normalized = path.strip().rstrip("/")
    if not normalized:
        return False
    parts = normalized.split("/")
    base = parts[-1]
    if base == ".DS_Store":
        return True
    if normalized.endswith(".pyc") or normalized.endswith(".pyo"):
        return True
    if "__pycache__" in parts:
        return True
    # Repo-star `work/` scratch convention (ephemeral session output).
    if parts[0] == "work":
        return True
    return False


def status_paths(repo: Path) -> tuple[bool, list[str]]:
    """Return (git_available, changed_paths) from porcelain v2-safe parsing.

    Uses `--porcelain=v1 -z` so paths are emitted verbatim (no quoting) and
    NUL-delimited. Rename/copy records carry a trailing origin field which is
    consumed and ignored -- the destination path is what we classify."""
    try:
        result = subprocess.run(
            ["git", "-C", str(repo), "status", "--porcelain=v1", "-z"],
            capture_output=True,
            timeout=60,
            check=True,
        )
    except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return False, []

    records = result.stdout.decode("utf-8", errors="replace").split("\0")
    paths: list[str] = []
    i = 0
    while i < len(records):
        record = records[i]
        if record == "":
            i += 1
            continue
        # Each status record is "XY PATH" (2 status chars + space + path).
        xy = record[:2]
        path = record[3:]
        if path:
            paths.append(path)
        # Rename/copy entries append the origin path as its own NUL field.
        if "R" in xy or "C" in xy:
            i += 2
        else:
            i += 1
    return True, paths


def classify(repo: Path) -> dict:
    git_available, paths = status_paths(repo)
    meaningful: list[str] = []
    tolerated: list[str] = []
    for path in paths:
        if is_noise_path(path):
            tolerated.append(path)
        else:
            meaningful.append(path)
    return {
        "repo": str(repo),
        "git_available": git_available,
        "dirty": bool(paths),
        "total_entries": len(paths),
        "meaningful_count": len(meaningful),
        "tolerated_noise_count": len(tolerated),
        "meaningful_paths": meaningful[:MAX_EXAMPLE_PATHS],
        "tolerated_noise_paths": tolerated[:MAX_EXAMPLE_PATHS],
        "noise_classes": ["__pycache__/", "*.pyc", "*.pyo", ".DS_Store", "work/"],
    }


def main() -> int:
    if len(sys.argv) != 2:
        print(json.dumps({"error": "usage: classify-dirty-noise.py <repo_path>"}))
        return 2
    repo = Path(sys.argv[1]).expanduser().resolve()
    print(json.dumps(classify(repo), indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
