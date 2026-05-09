#!/usr/bin/env python3
"""Audit a clean HEAD snapshot of a dirty target without mutating the target."""

from __future__ import annotations

import argparse
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


RECEIPT_VERSION = "1.0.0"
MODE = "clean-head-snapshot"


def run(args: list[str], cwd: Path | None = None, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,
        cwd=str(cwd) if cwd else None,
        check=check,
        capture_output=True,
        text=True,
    )


def git(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return run(["git", "-C", str(repo), *args], check=check)


def resolve_git_path(repo: Path, value: str) -> Path:
    path = Path(value)
    if not path.is_absolute():
        path = repo / path
    return path.resolve()


def status_entries(repo: Path) -> list[str]:
    result = git(repo, "status", "--porcelain=v2")
    return [line for line in result.stdout.splitlines() if line]


def path_is_self_or_child(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
    except ValueError:
        return False
    return True


def paths_overlap(first: Path, second: Path) -> bool:
    return path_is_self_or_child(first, second) or path_is_self_or_child(second, first)


def validate_output_locations(target: Path, output_dir: Path, snapshot_dir: Path) -> None:
    for label, path in (("output dir", output_dir), ("snapshot dir", snapshot_dir)):
        if path_is_self_or_child(path, target):
            raise SystemExit(f"ERROR: {label} must not be inside the target repo: {path}")
    if paths_overlap(output_dir, snapshot_dir):
        raise SystemExit("ERROR: output dir and snapshot dir must be separate non-overlapping paths")


def source_state(repo: Path) -> dict[str, Any]:
    status = status_entries(repo)
    return {
        "path": str(repo),
        "head": git(repo, "rev-parse", "HEAD").stdout.strip(),
        "tree": git(repo, "rev-parse", "HEAD^{tree}").stdout.strip(),
        "branch": git(repo, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip(),
        "git_dir": git(repo, "rev-parse", "--git-dir").stdout.strip(),
        "git_common_dir": git(repo, "rev-parse", "--git-common-dir").stdout.strip(),
        "status_porcelain_v2": status,
        "status_entry_count": len(status),
        "untracked_count": sum(1 for item in status if item.startswith("? ")),
        "modified_count": sum(1 for item in status if not item.startswith("? ")),
        "dirty": bool(status),
    }


def validate_source(repo: Path) -> dict[str, Any]:
    if not repo.is_dir():
        raise SystemExit(f"ERROR: target repo is not a directory: {repo}")
    inside = git(repo, "rev-parse", "--is-inside-work-tree", check=False)
    if inside.returncode != 0 or inside.stdout.strip() != "true":
        raise SystemExit(f"ERROR: target is not a git worktree: {repo}")
    bare = git(repo, "rev-parse", "--is-bare-repository").stdout.strip()
    if bare == "true":
        raise SystemExit(f"ERROR: bare repositories are not supported: {repo}")

    state = source_state(repo)
    git_dir = resolve_git_path(repo, state["git_dir"])
    common_dir = resolve_git_path(repo, state["git_common_dir"])
    if git_dir != common_dir:
        raise SystemExit("ERROR: linked worktrees are not supported for clean HEAD snapshot audit")

    gitmodules = git(repo, "ls-files", ".gitmodules").stdout.strip()
    if gitmodules:
        raise SystemExit("ERROR: submodule targets are not supported for clean HEAD snapshot audit")
    return state


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2, sort_keys=True)
        handle.write("\n")


def load_json(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def compact_pointer(receipt: dict[str, Any]) -> dict[str, Any]:
    source = receipt["source"]
    snapshot = receipt["snapshot"]
    return {
        "version": RECEIPT_VERSION,
        "mode": MODE,
        "file": "CLEAN_HEAD_SNAPSHOT_RECEIPT.json",
        "source_head": source["head"],
        "source_dirty": source["dirty"],
        "source_status_entry_count": source["status_entry_count"],
        "source_untracked_count": source["untracked_count"],
        "source_modified_count": source["modified_count"],
        "snapshot_head": snapshot["head"],
        "snapshot_tree": snapshot["tree"],
        "snapshot_status_clean": snapshot["status_clean"],
        "audit_exit_code": receipt["audit"]["exit_code"],
        "non_authorization": True,
    }


def augment_scorecard_outputs(output_dir: Path, receipt: dict[str, Any]) -> None:
    run_receipt = load_json(output_dir / "AUDIT_RUN_RECEIPT.json")
    if receipt["audit"]["exit_code"] != 0 or (run_receipt or {}).get("status") != "completed":
        return

    pointer = compact_pointer(receipt)
    receipts_path = output_dir / "SCORECARD_RECEIPTS.json"
    scorecard_path = output_dir / "SCORECARD.json"

    receipts = load_json(receipts_path)
    if receipts is not None:
        receipts["clean_head_snapshot"] = pointer
        write_json(receipts_path, receipts)

    scorecard = load_json(scorecard_path)
    if scorecard is not None:
        scorecard.setdefault("receipts", {})["clean_head_snapshot"] = pointer
        write_json(scorecard_path, scorecard)


def build_initial_receipt(source: dict[str, Any], snapshot_dir: Path, output_dir: Path) -> dict[str, Any]:
    return {
        "version": RECEIPT_VERSION,
        "mode": MODE,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "source": source,
        "snapshot": {
            "path": str(snapshot_dir),
            "clone_args": ["git", "clone", "--quiet", "--no-local", "--no-hardlinks"],
            "excludes_uncommitted_source_state": True,
            "head": None,
            "tree": None,
            "status_clean": None,
        },
        "audit": {
            "output_dir": str(output_dir),
            "exit_code": None,
        },
        "non_authorization_statement": "Clean HEAD snapshot audit evidence does not authorize deleting, archiving, compressing, or rewriting target files.",
        "scan_cap_statement": "Clean HEAD snapshot mode does not change dual-inventory scan limits or convert scan-limited evidence into complete evidence.",
    }


def clone_snapshot(source: Path, snapshot_dir: Path, expected_head: str) -> dict[str, Any]:
    if snapshot_dir.exists():
        raise SystemExit(f"ERROR: snapshot dir already exists: {snapshot_dir}")
    snapshot_dir.parent.mkdir(parents=True, exist_ok=True)
    run(["git", "clone", "--quiet", "--no-local", "--no-hardlinks", str(source), str(snapshot_dir)])
    git(snapshot_dir, "checkout", "--quiet", expected_head)
    status = status_entries(snapshot_dir)
    if status:
        raise SystemExit("ERROR: snapshot checkout is dirty")
    return {
        "head": git(snapshot_dir, "rev-parse", "HEAD").stdout.strip(),
        "tree": git(snapshot_dir, "rev-parse", "HEAD^{tree}").stdout.strip(),
        "status_clean": True,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target_repo")
    parser.add_argument("output_dir")
    parser.add_argument("--snapshot-dir", required=True, help="Directory to create for the clean HEAD snapshot.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    target = Path(args.target_repo).expanduser().resolve()
    output_dir = Path(args.output_dir).expanduser().resolve()
    snapshot_dir = Path(args.snapshot_dir).expanduser().resolve()
    repo_root = Path(__file__).resolve().parents[1]

    validate_output_locations(target, output_dir, snapshot_dir)
    source = validate_source(target)
    output_dir.mkdir(parents=True, exist_ok=True)
    receipt_path = output_dir / "CLEAN_HEAD_SNAPSHOT_RECEIPT.json"
    receipt = build_initial_receipt(source, snapshot_dir, output_dir)
    write_json(receipt_path, receipt)

    snapshot = clone_snapshot(target, snapshot_dir, source["head"])
    receipt["snapshot"].update(snapshot)
    write_json(receipt_path, receipt)

    audit = subprocess.run(
        ["bash", str(repo_root / "scripts" / "repo-auditor.sh"), str(snapshot_dir), str(output_dir)],
        check=False,
    )
    receipt["audit"]["exit_code"] = audit.returncode
    receipt["completed_at"] = datetime.now(timezone.utc).isoformat()
    write_json(receipt_path, receipt)
    augment_scorecard_outputs(output_dir, receipt)
    return audit.returncode


if __name__ == "__main__":
    raise SystemExit(main())
