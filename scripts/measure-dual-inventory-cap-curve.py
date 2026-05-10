#!/usr/bin/env python3
"""Measure dual-inventory scan-cap behavior across one target.

This helper is measurement-only. It creates minimal scorecard shells in the
output directory, runs the existing dual-inventory collector at each requested
cap, and records wall-clock plus receipt status. It does not authorize cleanup
or mutate the target.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import shutil
import subprocess
import tempfile
import time
from pathlib import Path
from typing import Any


DEFAULT_CAPS = "200,1000,2500,5000"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target_repo")
    parser.add_argument("output_dir")
    parser.add_argument("--caps", default=DEFAULT_CAPS, help="Comma-separated scan caps.")
    return parser.parse_args()


def parse_caps(raw: str) -> list[int]:
    caps: list[int] = []
    for part in raw.split(","):
        part = part.strip()
        if not part:
            continue
        value = int(part)
        if value < 1:
            raise ValueError("caps must be >= 1")
        caps.append(value)
    if not caps:
        raise ValueError("at least one cap is required")
    return caps


def git_snapshot(target: Path) -> dict[str, Any]:
    if not target.exists():
        return {"exists": False, "is_git": False, "dirty": None, "head": None}
    inside = subprocess.run(
        ["git", "-C", str(target), "rev-parse", "--is-inside-work-tree"],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    if inside.returncode != 0:
        return {"exists": True, "is_git": False, "dirty": None, "head": None}
    head = subprocess.run(
        ["git", "-C", str(target), "rev-parse", "HEAD"],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    ).stdout.strip()
    status = subprocess.run(
        ["git", "-C", str(target), "status", "--porcelain"],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    ).stdout.strip()
    return {"exists": True, "is_git": True, "dirty": bool(status), "head": head, "status": status}


def tracked_file_count(target: Path) -> int | None:
    proc = subprocess.run(
        ["git", "-C", str(target), "ls-files"],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    if proc.returncode != 0:
        return None
    return len([line for line in proc.stdout.splitlines() if line.strip()])


def write_scorecard_shell(output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "SCORECARD.json").write_text(json.dumps({"receipts": {}}, indent=2) + "\n")
    (output_dir / "SCORECARD_RECEIPTS.json").write_text(json.dumps({}, indent=2) + "\n")


def path_is_within(path: Path, parent: Path) -> bool:
    try:
        path.resolve().relative_to(parent.resolve())
    except ValueError:
        return False
    return True


def read_receipt(output_dir: Path) -> tuple[dict[str, Any], dict[str, Any]]:
    path = output_dir / "SCORECARD_RECEIPTS.json"
    if not path.is_file():
        return {}, {}
    payload = json.loads(path.read_text())
    return payload.get("primary_surface_inventory", {}), payload.get("full_facts_inventory", {})


def main() -> int:
    args = parse_args()
    target = Path(args.target_repo).expanduser().resolve()
    output_root = Path(args.output_dir).expanduser().resolve()
    caps = parse_caps(args.caps)
    collector = Path(__file__).resolve().parent / "collect-dual-inventory.py"
    output_inside_target = target.exists() and path_is_within(output_root, target)

    rows: list[dict[str, Any]] = []
    before = git_snapshot(target)
    scan_tmp: tempfile.TemporaryDirectory[str] | None = None
    scan_root = output_root
    if output_inside_target:
        scan_tmp = tempfile.TemporaryDirectory(prefix="repo-auditor-cap-curve-")
        scan_root = Path(scan_tmp.name)
    scan_root.mkdir(parents=True, exist_ok=True)

    for cap in caps:
        cap_dir = scan_root / f"cap-{cap}"
        write_scorecard_shell(cap_dir)
        env = os.environ.copy()
        env["REPO_AUDITOR_DUAL_INVENTORY_MAX_FILES"] = str(cap)
        started = time.time()
        proc = subprocess.run(
            ["python3", str(collector), str(target), str(cap_dir)],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            env=env,
        )
        elapsed = round(time.time() - started, 3)
        (cap_dir / "stdout.txt").write_text(proc.stdout)
        (cap_dir / "stderr.txt").write_text(proc.stderr)
        after = git_snapshot(target)
        primary, full = read_receipt(cap_dir)
        guidance = full.get("scan_limit_guidance", {})
        rows.append(
            {
                "cap": cap,
                "exit_code": proc.returncode,
                "elapsed_seconds": elapsed,
                "status": "completed" if proc.returncode == 0 else "failed",
                "primary_status": primary.get("status"),
                "primary_unique_paths": primary.get("total_unique_paths"),
                "primary_scan_limit_reached": primary.get("scan_limit_reached"),
                "full_status": full.get("status"),
                "full_total_files_scanned": full.get("total_files_scanned"),
                "full_scan_limit_reached": full.get("scan_limit_reached"),
                "full_denominator_mode": full.get("denominator_mode"),
                "full_auditor_pruned_total_files": full.get("auditor_pruned_total_files"),
                "full_scan_coverage_ratio": full.get("scan_coverage_ratio"),
                "full_scan_limit_guidance_status": guidance.get("status"),
                "full_minimum_complete_cap": guidance.get("minimum_complete_cap"),
                "full_recommended_rerun_cap": guidance.get("recommended_rerun_cap"),
                "full_trusted_local_override": guidance.get("trusted_local_override"),
                "tracked_files": tracked_file_count(target),
                "dirty_before": before.get("dirty"),
                "dirty_after": after.get("dirty"),
                "head_before": before.get("head"),
                "head_after": after.get("head"),
                "status_before": before.get("status"),
                "status_after": after.get("status"),
                "output_inside_target": output_inside_target,
                "output_dir": str(cap_dir),
                "error": proc.stderr.strip(),
            }
        )

    csv_path = scan_root / "dual-inventory-cap-curve.csv"
    fieldnames = list(rows[0].keys()) if rows else []
    with csv_path.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    final_snapshot_before_copy = git_snapshot(target)
    summary = {
        "schema_version": 1,
        "target": str(target),
        "output_dir": str(output_root),
        "output_inside_target": output_inside_target,
        "caps": caps,
        "mutation_detected": any(
            (row["head_before"] and row["head_before"] != row["head_after"])
            or (row.get("status_before") != row.get("status_after"))
            for row in rows
        ),
        "final_target_status_before_retention_copy": final_snapshot_before_copy.get("status"),
        "completed_runs": sum(1 for row in rows if row["status"] == "completed"),
        "limited_runs": sum(1 for row in rows if row["full_status"] == "available_limited"),
        "available_runs": sum(1 for row in rows if row["full_status"] == "available"),
        "rows": rows,
        "non_authorization": "This cap curve is measurement evidence only and does not authorize cleanup, deletion, archival, compression, or rewriting target files.",
    }
    (scan_root / "dual-inventory-cap-curve.json").write_text(json.dumps(summary, indent=2) + "\n")
    if scan_root != output_root:
        output_root.mkdir(parents=True, exist_ok=True)
        shutil.copytree(scan_root, output_root, dirs_exist_ok=True)
        summary["retention_copy_performed_after_measurement"] = True
        summary["final_target_status_after_retention_copy"] = git_snapshot(target).get("status")
        summary["mutation_detected"] = summary["mutation_detected"] or (
            summary["final_target_status_before_retention_copy"]
            != summary["final_target_status_after_retention_copy"]
        )
        (output_root / "dual-inventory-cap-curve.json").write_text(json.dumps(summary, indent=2) + "\n")
    if scan_tmp is not None:
        scan_tmp.cleanup()
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
