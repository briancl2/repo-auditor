#!/usr/bin/env python3
"""Build a clean temporary repo snapshot for closeout-time auditing.

The snapshot starts from the target repo's current HEAD, overlays the current
candidate worktree state for tracked changes and non-ignored untracked files,
removes excluded closeout-generated paths, and rewrites the snapshot HEAD with
the candidate tree plus original commit metadata so ordinary clean-tree
guardrails still apply without adding a synthetic extra commit.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Iterable


def run_git(repo_root: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(repo_root), *args],
        check=True,
        capture_output=True,
        text=True,
    )


def normalize_relpath(value: str) -> str:
    text = value
    while text.startswith("./"):
        text = text[2:]
    text = text.strip("/")
    return text


def path_is_excluded(relpath: str, excluded: set[str]) -> bool:
    normalized = normalize_relpath(relpath)
    if not normalized:
        return False
    for root in excluded:
        if normalized == root or normalized.startswith(f"{root}/"):
            return True
    return False


def remove_path(path: Path) -> None:
    if not path.exists() and not path.is_symlink():
        return
    if path.is_symlink() or path.is_file():
        path.unlink()
        return
    shutil.rmtree(path)


def copy_path(source_root: Path, snapshot_root: Path, relpath: str) -> None:
    source = source_root / relpath
    destination = snapshot_root / relpath
    destination.parent.mkdir(parents=True, exist_ok=True)
    remove_path(destination)

    if source.is_symlink():
        os.symlink(os.readlink(source), destination)
    elif source.is_dir():
        shutil.copytree(source, destination, symlinks=True)
    else:
        shutil.copy2(source, destination)


def zero_terminated_paths(repo_root: Path, command: list[str]) -> list[str]:
    result = subprocess.run(
        ["git", "-C", str(repo_root), *command],
        check=True,
        capture_output=True,
    )
    raw = result.stdout
    if not raw:
        return []
    return [normalize_relpath(item.decode("utf-8", errors="surrogateescape")) for item in raw.split(b"\0") if item]


def changed_candidate_paths(repo_root: Path) -> tuple[list[str], list[str]]:
    tracked = zero_terminated_paths(repo_root, ["diff", "--name-only", "--no-renames", "-z", "HEAD", "--"])
    untracked = zero_terminated_paths(repo_root, ["ls-files", "--others", "--exclude-standard", "-z"])
    return tracked, untracked


def apply_exclusions(snapshot_root: Path, excluded: Iterable[str]) -> None:
    for relpath in excluded:
        remove_path(snapshot_root / relpath)


def commit_field(snapshot_root: Path, fmt: str) -> str:
    return run_git(snapshot_root, "show", "-s", f"--format={fmt}", "HEAD").stdout.rstrip("\n")


def head_ref(snapshot_root: Path) -> str:
    result = subprocess.run(
        ["git", "-C", str(snapshot_root), "symbolic-ref", "-q", "HEAD"],
        check=False,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip() or "HEAD"


def materialize_clean_head(snapshot_root: Path) -> bool:
    run_git(snapshot_root, "add", "-A")
    status = run_git(snapshot_root, "status", "--porcelain").stdout.strip()
    if not status:
        return False

    tree_sha = run_git(snapshot_root, "write-tree").stdout.strip()
    parent_line = commit_field(snapshot_root, "%P")
    message = commit_field(snapshot_root, "%B")
    env = os.environ.copy()
    env.update(
        {
            "GIT_AUTHOR_NAME": commit_field(snapshot_root, "%an"),
            "GIT_AUTHOR_EMAIL": commit_field(snapshot_root, "%ae"),
            "GIT_AUTHOR_DATE": commit_field(snapshot_root, "%aI"),
            "GIT_COMMITTER_NAME": commit_field(snapshot_root, "%cn"),
            "GIT_COMMITTER_EMAIL": commit_field(snapshot_root, "%ce"),
            "GIT_COMMITTER_DATE": commit_field(snapshot_root, "%cI"),
        }
    )

    command = ["git", "-C", str(snapshot_root), "commit-tree", tree_sha]
    for parent_sha in parent_line.split():
        command.extend(["-p", parent_sha])
    result = subprocess.run(
        command,
        input=message,
        check=True,
        capture_output=True,
        text=True,
        env=env,
    )
    new_head = result.stdout.strip()
    run_git(snapshot_root, "update-ref", head_ref(snapshot_root), new_head)
    run_git(snapshot_root, "reset", "--hard", "-q", new_head)
    return True


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo_root", help="Path to the live repo whose candidate state should be snapshotted.")
    parser.add_argument("snapshot_dir", help="Directory to create as the clean temporary snapshot repo.")
    parser.add_argument(
        "--exclude-relpath",
        action="append",
        default=[],
        help="Repo-relative path to exclude from the snapshot. Repeatable.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = Path(args.repo_root).expanduser().resolve()
    snapshot_dir = Path(args.snapshot_dir).expanduser().resolve()

    if not repo_root.is_dir():
        raise SystemExit(f"ERROR: repo_root is not a directory: {repo_root}")
    git_dir = subprocess.run(
        ["git", "-C", str(repo_root), "rev-parse", "--git-dir"],
        capture_output=True,
        text=True,
        check=False,
    )
    if git_dir.returncode != 0:
        raise SystemExit(f"ERROR: repo_root is not a git repo: {repo_root}")

    excluded = {normalize_relpath(item) for item in args.exclude_relpath if normalize_relpath(item)}
    tracked_paths, untracked_paths = changed_candidate_paths(repo_root)

    if snapshot_dir.exists():
        raise SystemExit(f"ERROR: snapshot_dir already exists: {snapshot_dir}")
    snapshot_dir.parent.mkdir(parents=True, exist_ok=True)

    subprocess.run(
        ["git", "clone", "--quiet", "--no-hardlinks", str(repo_root), str(snapshot_dir)],
        check=True,
        capture_output=True,
        text=True,
    )

    apply_exclusions(snapshot_dir, excluded)

    copied_paths = 0
    removed_paths = 0
    for relpath in tracked_paths:
        if path_is_excluded(relpath, excluded):
            continue
        source = repo_root / relpath
        if source.exists() or source.is_symlink():
            copy_path(repo_root, snapshot_dir, relpath)
            copied_paths += 1
        else:
            remove_path(snapshot_dir / relpath)
            removed_paths += 1

    for relpath in untracked_paths:
        if path_is_excluded(relpath, excluded):
            continue
        copy_path(repo_root, snapshot_dir, relpath)
        copied_paths += 1

    apply_exclusions(snapshot_dir, excluded)
    committed = materialize_clean_head(snapshot_dir)

    payload = {
        "snapshot_dir": str(snapshot_dir),
        "repo_root": str(repo_root),
        "excluded_paths": sorted(excluded),
        "tracked_overlay_paths": len(tracked_paths),
        "untracked_overlay_paths": len(untracked_paths),
        "copied_paths": copied_paths,
        "removed_paths": removed_paths,
        "materialized_clean_head": committed,
        "snapshot_head": run_git(snapshot_dir, "rev-parse", "HEAD").stdout.strip(),
    }
    json.dump(payload, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
