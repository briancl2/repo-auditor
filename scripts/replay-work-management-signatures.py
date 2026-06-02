#!/usr/bin/env python3
"""Replay AS-20..AS-33 work-management signatures against bounded targets."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any


SIGNATURE_IDS = [f"AS-{index}" for index in range(20, 34)]
CORE_FIVE_RECOVERY_RUNTIME_SIGNATURE_IDS = [f"AS-{index}" for index in range(29, 34)]
DEFAULT_MAX_TARGETS = 8
DOWNSTREAM_PILOT_CONTRACT_REFERENCE = (
    "repo-agent-core/docs/downstream-read-only-recovery-runtime-pilot-contract.md"
)
DOWNSTREAM_PILOT_RECEIPT_SHAPE = "DOWNSTREAM_READ_ONLY_RECOVERY_RUNTIME_PILOT_RECEIPT"
DOWNSTREAM_PILOT_BOUNDED_NON_CLAIMS = [
    "This receipt does not apply patches.",
    "This receipt does not open downstream PRs or issues.",
    "This receipt does not mutate the target repo.",
    "This receipt does not install hooks or change target repo configuration.",
    "This receipt does not start a daemon, scheduler, queue, controller, retry loop, hidden registry, background sync, MCP server, watcher, cron job, service, or autopilot.",
    "This receipt does not perform automatic GitHub issue creation.",
    "This receipt does not claim replay evidence is safe to use without explicit operator review and an explicit downstream write step outside this pilot.",
]


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
        description="Run AS-20..AS-33 against a bounded set of read-only target repositories.",
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


def run_git(repo: Path, args: list[str]) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["GIT_OPTIONAL_LOCKS"] = "0"
    return subprocess.run(
        ["git", "-C", str(repo), *args],
        check=False,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def git_value(repo: Path, args: list[str]) -> str | None:
    completed = run_git(repo, args)
    if completed.returncode != 0:
        return None
    value = completed.stdout.strip()
    return value or None


def git_dirty_count(repo: Path) -> int | None:
    completed = run_git(repo, ["status", "--porcelain"])
    if completed.returncode != 0:
        return None
    return sum(1 for line in completed.stdout.splitlines() if line.strip())


def target_repo_identity(name: str, path: Path) -> str:
    origin = git_value(path, ["remote", "get-url", "origin"])
    if origin:
        return f"{name} ({origin})"
    toplevel = git_value(path, ["rev-parse", "--show-toplevel"])
    if toplevel:
        return f"{name} ({toplevel})"
    return f"{name} ({path})"


def downstream_pilot_receipt(
    *,
    name: str,
    path: Path,
    generated_at: str,
    output_path: Path,
    git_head_before: str | None,
    git_head_after: str | None,
    dirty_count_before: int | None,
    dirty_count_after: int | None,
) -> dict[str, Any]:
    return {
        "artifact": DOWNSTREAM_PILOT_RECEIPT_SHAPE,
        "schema_version": 1,
        "generated_at": generated_at,
        "target_repo_identity": target_repo_identity(name, path),
        "target_path_or_name": str(path),
        "target_git_head_before": git_head_before,
        "target_git_head_after": git_head_after,
        "target_dirty_count_before": dirty_count_before,
        "target_dirty_count_after": dirty_count_after,
        "auditor_as_replay_artifact_path": str(output_path),
        "advisor_artifact_path": None,
        "optimizer_replay_receipt_path": None,
        "generated_patch_pack_path": None,
        "patch_metadata_path": None,
        "blocker_path": None,
        "apply_check_result_path": None,
        "bounded_non_claims": DOWNSTREAM_PILOT_BOUNDED_NON_CLAIMS,
    }


def summarize_target(
    name: str,
    path: Path,
    script_dir: Path,
    output_path: Path,
    generated_at: str,
) -> dict[str, Any]:
    git_head_before = git_value(path, ["rev-parse", "HEAD"])
    dirty_count_before = git_dirty_count(path)
    results = [run_signature(script_dir, signature_id, path) for signature_id in SIGNATURE_IDS]
    git_head_after = git_value(path, ["rev-parse", "HEAD"])
    dirty_count_after = git_dirty_count(path)
    fired_ids = [result["ds_id"] for result in results if result.get("fired")]
    error_ids = [result["ds_id"] for result in results if result.get("error")]
    as22 = next((result for result in results if result.get("ds_id") == "AS-22"), {})
    core_five_recovery_runtime_fired_ids = [
        result["ds_id"]
        for result in results
        if result.get("ds_id") in CORE_FIVE_RECOVERY_RUNTIME_SIGNATURE_IDS and result.get("fired")
    ]
    receipt = downstream_pilot_receipt(
        name=name,
        path=path,
        generated_at=generated_at,
        output_path=output_path,
        git_head_before=git_head_before,
        git_head_after=git_head_after,
        dirty_count_before=dirty_count_before,
        dirty_count_after=dirty_count_after,
    )
    return {
        "name": name,
        "path": str(path),
        "exists": path.is_dir(),
        "target_repo_identity": receipt["target_repo_identity"],
        "target_path_or_name": receipt["target_path_or_name"],
        "target_git_head_before": receipt["target_git_head_before"],
        "target_git_head_after": receipt["target_git_head_after"],
        "target_dirty_count_before": receipt["target_dirty_count_before"],
        "target_dirty_count_after": receipt["target_dirty_count_after"],
        "auditor_as_replay_artifact_path": receipt["auditor_as_replay_artifact_path"],
        "bounded_non_claims": receipt["bounded_non_claims"],
        "downstream_pilot_receipt": receipt,
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
        "core_five_recovery_runtime_fired_ids": core_five_recovery_runtime_fired_ids,
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
    args.output_dir.mkdir(parents=True, exist_ok=True)
    output_path = args.output_dir / "AS_WORK_MANAGEMENT_REPLAY.json"
    generated_at = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    targets = [
        summarize_target(name, path, script_dir, output_path, generated_at)
        for name, path in repos
    ]
    fired_target_count = sum(1 for target in targets if target["fired_ids"])
    closure_regrowth_target_count = sum(1 for target in targets if target["closure_regrowth_fired"])
    error_target_count = sum(1 for target in targets if target["error_ids"])
    payload = {
        "schema_version": "issue164-work-management-replay-v1",
        "contract_reference": DOWNSTREAM_PILOT_CONTRACT_REFERENCE,
        "receipt_shape_reference": DOWNSTREAM_PILOT_RECEIPT_SHAPE,
        "signature_ids": SIGNATURE_IDS,
        "core_five_recovery_runtime_signature_ids": CORE_FIVE_RECOVERY_RUNTIME_SIGNATURE_IDS,
        "max_targets": args.max_targets,
        "target_count": len(targets),
        "fired_target_count": fired_target_count,
        "closure_regrowth_target_count": closure_regrowth_target_count,
        "error_target_count": error_target_count,
        "bounded_non_claims": [
            "Replay is read-only and does not mutate target repositories.",
            "Replay is bounded to AS-20 through AS-33 and the per-signature text scan limit.",
            "AS-29 through AS-33 replay is bounded core-five recovery-runtime detector precision evidence only.",
            "A clean replay is detector precision evidence, not proof of issue or PR closure.",
        ],
        "targets": targets,
    }

    output_path.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))
    return 0 if error_target_count == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
