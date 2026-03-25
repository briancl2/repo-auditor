#!/usr/bin/env python3
"""Write a deterministic context-score manifest for a repo-auditor run."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ARTIFACT_DIRS = ("work", "runs")


def run_git(target: Path, *args: str) -> tuple[bool, str]:
    try:
        proc = subprocess.run(
            ["git", "-C", str(target), *args],
            capture_output=True,
            text=True,
            check=True,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        if isinstance(exc, subprocess.CalledProcessError):
            output = exc.stdout or exc.stderr or ""
        else:
            output = str(exc)
        return False, output.strip()
    return True, proc.stdout.strip()


def parse_auditorignore(target: Path) -> set[str]:
    path = target / ".auditorignore"
    ignored: set[str] = set()
    if not path.exists():
        return ignored
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.split("#", 1)[0].strip()
        if not line:
            continue
        normalized = line.lstrip("./").rstrip("/")
        if normalized:
            ignored.add(normalized)
    return ignored


def count_files(path: Path) -> int:
    if not path.exists():
        return 0
    return sum(1 for entry in path.rglob("*") if entry.is_file())


def count_git_lines(target: Path, *args: str) -> int:
    ok, output = run_git(target, *args)
    if not ok or not output:
        return 0
    return len([line for line in output.splitlines() if line.strip()])


def artifact_entry(
    target: Path,
    ignored: set[str],
    name: str,
    git_present: bool,
    git_root_matches_target: bool,
) -> dict[str, object]:
    artifact_path = target / name
    files = count_files(artifact_path)
    ignored_by_auditor = name in ignored
    counted_in_score_surface = files > 0 and not ignored_by_auditor
    tracked_files = 0
    if git_present and git_root_matches_target:
        tracked_files = count_git_lines(target, "ls-files", "--cached", "--", name)
    local_only_files = files if not git_present else max(files - tracked_files, 0)
    return {
        "files": files,
        "ignored_by_auditor": ignored_by_auditor,
        "counted_in_score_surface": counted_in_score_surface,
        "tracked_files": tracked_files,
        "local_only_files": local_only_files,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("target_repo")
    parser.add_argument("output_path")
    parser.add_argument("--context-id", default="standard")
    parser.add_argument("--compare-oracle-version", default="1.0.0")
    parser.add_argument("--require-portable-context", action="store_true")
    args = parser.parse_args()

    target = Path(args.target_repo).resolve()
    output_path = Path(args.output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    ignored = parse_auditorignore(target)

    git_present, git_toplevel = run_git(target, "rev-parse", "--show-toplevel")
    git_head_present = False
    git_head = ""
    git_status: list[str] = []
    git_root_matches_target = False
    borrowed_parent_git_root = False

    if git_present:
        git_head_present, git_head = run_git(target, "rev-parse", "HEAD")
        git_status_present, git_status_raw = run_git(target, "status", "--short")
        if git_status_present and git_status_raw:
            git_status = [line for line in git_status_raw.splitlines() if line]
        git_root_matches_target = Path(git_toplevel).resolve() == target
        borrowed_parent_git_root = not git_root_matches_target

    local_artifact_counts = {
        name: artifact_entry(target, ignored, name, git_present, git_root_matches_target)
        for name in ARTIFACT_DIRS
    }
    counted_files_total = sum(
        int(entry["files"])
        for entry in local_artifact_counts.values()
        if entry["counted_in_score_surface"]
    )
    counted_local_only_files_total = sum(
        int(entry["local_only_files"])
        for entry in local_artifact_counts.values()
        if entry["counted_in_score_surface"]
    )

    portable_risks: list[str] = []
    if not git_present:
        portable_risks.append("missing_git_history")
    if borrowed_parent_git_root:
        portable_risks.append("borrowed_parent_git_root")
    if counted_local_only_files_total > 0:
        portable_risks.append("counted_local_artifact_inflation_possible")

    portable_ready = not portable_risks

    manifest = {
        "schema_version": "1.0.0",
        "audit_context_id": args.context_id,
        "target_repo_path": str(target),
        "compare_oracle_version": args.compare_oracle_version,
        "auditorignore": {
            "active": bool(ignored),
            "entries": sorted(ignored),
        },
        "git": {
            "present": git_present,
            "toplevel": git_toplevel if git_present else "",
            "head": git_head if git_head_present else "",
            "status_short": git_status,
            "root_matches_target": git_root_matches_target,
            "borrowed_parent_git_root": borrowed_parent_git_root,
        },
        "local_artifact_counts": {
            **local_artifact_counts,
            "counted_files_total": counted_files_total,
            "counted_local_only_files_total": counted_local_only_files_total,
        },
        "portable_authority": {
            "ready": portable_ready,
            "risks": portable_risks,
        },
        "preflight_checks": [
            {
                "id": "git-root-belongs-to-target",
                "status": "pass" if git_root_matches_target else "fail",
                "detail": (
                    "git rev-parse --show-toplevel resolves to the audited repo"
                    if git_root_matches_target
                    else "git history is missing or resolves outside the audited repo"
                ),
            },
            {
                "id": "local-artifact-volume-emitted",
                "status": "pass",
                "detail": "work/ and runs/ file counts are retained in the manifest.",
            },
            {
                "id": "portable-authority-readiness",
                "status": "pass" if portable_ready else "fail",
                "detail": (
                    "Context is portable for widening authority."
                    if portable_ready
                    else "Context is retained as a non-portable cross-check unless risks are cleared."
                ),
            },
        ],
    }

    output_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    if args.require_portable_context and not portable_ready:
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
