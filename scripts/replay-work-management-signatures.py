#!/usr/bin/env python3
"""Replay AS-20..AS-29 work-management signatures against bounded targets."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


SIGNATURE_IDS = [f"AS-{index}" for index in range(20, 30)]
DEFAULT_MAX_TARGETS = 8


def parse_repo(value: str) -> tuple[str, Path]:
    if "=" in value:
        name, raw_path = value.split("=", 1)
        name = name.strip()
    else:
        raw_path = value
        name = Path(value).name
    path = Path(raw_path).expanduser().resolve()
    if not name:
        raise argparse.ArgumentTypeError("--repo entries must include a non-empty name")
    return name, path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run AS-20..AS-29 against a bounded set of read-only target repositories.",
    )
    parser.add_argument(
        "--repo",
        action="append",
        type=parse_repo,
        required=True,
        metavar="NAME=PATH",
        help="Replay target. May be repeated; target repositories are read-only.",
    )
    parser.add_argument(
        "--output-dir",
        required=True,
        type=Path,
        help="Directory where AS_WORK_MANAGEMENT_REPLAY.json is written.",
    )
    parser.add_argument(
        "--max-targets",
        type=int,
        default=DEFAULT_MAX_TARGETS,
        help=f"Maximum number of targets to scan (default {DEFAULT_MAX_TARGETS}).",
    )
    return parser.parse_args()


def run_signature(script_dir: Path, signature_id: str, repo: Path) -> dict[str, Any]:
    completed = subprocess.run(
        [sys.executable, str(script_dir / "as_signature_scan.py"), signature_id, str(repo)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if completed.returncode != 0:
        return {
            "ds_id": signature_id,
            "fired": False,
            "error": "signature_scan_failed",
            "returncode": completed.returncode,
            "stderr": completed.stderr[-1000:],
        }
    try:
        return json.loads(completed.stdout)
    except json.JSONDecodeError as exc:
        return {
            "ds_id": signature_id,
            "fired": False,
            "error": "signature_scan_invalid_json",
            "message": str(exc),
            "stdout": completed.stdout[-1000:],
        }


def summarize_target(name: str, path: Path, script_dir: Path) -> dict[str, Any]:
    results = [run_signature(script_dir, signature_id, path) for signature_id in SIGNATURE_IDS]
    fired_ids = [result["ds_id"] for result in results if result.get("fired")]
    error_ids = [result["ds_id"] for result in results if result.get("error")]
    as22 = next((result for result in results if result.get("ds_id") == "AS-22"), {})
    return {
        "name": name,
        "path": str(path),
        "exists": path.is_dir(),
        "signature_count": len(results),
        "fired_ids": fired_ids,
        "error_ids": error_ids,
        "closure_regrowth_fired": bool(as22.get("fired")),
        "closure_regrowth_count": as22.get("signals", {}).get(
            "github_native_closure_regrowth_count", 0
        ),
        "github_native_closeout_bypassed_count": as22.get("signals", {}).get(
            "github_native_closeout_bypassed_count", 0
        ),
        "results": results,
    }


def main() -> int:
    args = parse_args()
    repos: list[tuple[str, Path]] = args.repo
    if args.max_targets < 1:
        print("ERROR: --max-targets must be positive", file=sys.stderr)
        return 2
    if len(repos) > args.max_targets:
        print(
            f"ERROR: {len(repos)} targets exceeds --max-targets {args.max_targets}",
            file=sys.stderr,
        )
        return 2
    missing = [f"{name}={path}" for name, path in repos if not path.is_dir()]
    if missing:
        print(f"ERROR: replay target(s) missing: {', '.join(missing)}", file=sys.stderr)
        return 2

    script_dir = Path(__file__).resolve().parent
    targets = [summarize_target(name, path, script_dir) for name, path in repos]
    fired_target_count = sum(1 for target in targets if target["fired_ids"])
    closure_regrowth_target_count = sum(1 for target in targets if target["closure_regrowth_fired"])
    error_target_count = sum(1 for target in targets if target["error_ids"])
    payload = {
        "schema_version": "issue164-work-management-replay-v1",
        "signature_ids": SIGNATURE_IDS,
        "max_targets": args.max_targets,
        "target_count": len(targets),
        "fired_target_count": fired_target_count,
        "closure_regrowth_target_count": closure_regrowth_target_count,
        "error_target_count": error_target_count,
        "bounded_non_claims": [
            "Replay is read-only and does not mutate target repositories.",
            "Replay is bounded to AS-20 through AS-29 and the per-signature text scan limit.",
            "A clean replay is detector precision evidence, not proof of issue or PR closure.",
        ],
        "targets": targets,
    }

    args.output_dir.mkdir(parents=True, exist_ok=True)
    output_path = args.output_dir / "AS_WORK_MANAGEMENT_REPLAY.json"
    output_path.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))
    return 0 if error_target_count == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
