#!/usr/bin/env bash
# detect-github-actions-concurrency-gap.sh — DS-48: GitHub Actions concurrency gap
# Detects push/PR GitHub Actions workflows without cancel-in-progress protection.
#
# Usage: bash scripts/detect-github-actions-concurrency-gap.sh <repo_path>

set -euo pipefail

REPO="${1:?Usage: detect-github-actions-concurrency-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 - "$REPO" "$SCRIPT_DIR" <<'PY'
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path


def run_helper(payload: dict[str, object]) -> None:
    helper = Path(sys.argv[2]) / "ds_json_helper.py"
    args = [sys.executable, str(helper), json.dumps({
        "ds_id": "DS-48",
        "name": "GitHub Actions concurrency gap",
        "severity": "MEDIUM",
        "prevention_tier": "T2",
    })]
    for key, value in payload.items():
        if isinstance(value, bool):
            rendered = "true" if value else "false"
        elif isinstance(value, list):
            rendered = ",".join(str(item) for item in value)
        else:
            rendered = str(value)
        args.append(f"{key}={rendered}")
    proc = subprocess.run(args, check=True, capture_output=True, text=True)
    sys.stdout.write(proc.stdout)


def strip_comment(line: str) -> str:
    in_single = False
    in_double = False
    escaped = False
    out = []
    for char in line:
        if escaped:
            out.append(char)
            escaped = False
            continue
        if char == "\\" and in_double:
            out.append(char)
            escaped = True
            continue
        if char == "'" and not in_double:
            in_single = not in_single
        elif char == '"' and not in_single:
            in_double = not in_double
        if char == "#" and not in_single and not in_double:
            break
        out.append(char)
    return "".join(out).rstrip()


def indent(line: str) -> int:
    return len(line) - len(line.lstrip(" "))


def key_name(line: str) -> str | None:
    match = re.match(r"\s*['\"]?([A-Za-z0-9_-]+)['\"]?\s*:", line)
    return match.group(1) if match else None


def mentions_trigger(text: str) -> bool:
    return bool(re.search(r"(^|[^A-Za-z0-9_-])(push|pull_request)([^A-Za-z0-9_-]|$)", text))


def has_push_or_pr_trigger(lines: list[str]) -> bool:
    clean = [strip_comment(line) for line in lines]
    for idx, line in enumerate(clean):
        match = re.match(r"\s*['\"]?on['\"]?\s*:\s*(.*)$", line)
        if not match:
            continue
        base_indent = indent(line)
        inline_value = match.group(1).strip()
        if inline_value and mentions_trigger(inline_value):
            return True
        for nested in clean[idx + 1:]:
            stripped = nested.strip()
            if not stripped:
                continue
            nested_indent = indent(nested)
            if nested_indent <= base_indent:
                break
            if mentions_trigger(stripped):
                return True
    return False


def cancel_value_usable(value: str) -> bool:
    normalized = value.strip().strip("'\"").lower()
    if not normalized:
        return False
    return normalized not in {"false", "no", "0", "off"}


def block_has_cancel(lines: list[str], start: int, base_indent: int, inline_value: str) -> bool:
    if "cancel-in-progress" in inline_value:
        _, _, value = inline_value.partition("cancel-in-progress")
        _, _, rhs = value.partition(":")
        return cancel_value_usable(rhs)
    for nested in lines[start + 1:]:
        stripped = strip_comment(nested).strip()
        if not stripped:
            continue
        nested_indent = indent(nested)
        if nested_indent <= base_indent:
            break
        match = re.match(r"['\"]?cancel-in-progress['\"]?\s*:\s*(.+)$", stripped)
        if match and cancel_value_usable(match.group(1)):
            return True
    return False


def concurrency_blocks(lines: list[str], *, offset: int = 0) -> list[dict[str, object]]:
    blocks: list[dict[str, object]] = []
    clean = [strip_comment(line) for line in lines]
    for idx, line in enumerate(clean):
        match = re.match(r"(\s*)['\"]?concurrency['\"]?\s*:\s*(.*)$", line)
        if not match:
            continue
        base_indent = len(match.group(1))
        blocks.append({
            "line": offset + idx + 1,
            "indent": base_indent,
            "has_cancel": block_has_cancel(clean, idx, base_indent, match.group(2)),
        })
    return blocks


def job_blocks(lines: list[str]) -> list[tuple[str, list[str]]]:
    clean = [strip_comment(line) for line in lines]
    jobs_start = None
    jobs_indent = 0
    for idx, line in enumerate(clean):
        if re.match(r"\s*['\"]?jobs['\"]?\s*:\s*$", line):
            jobs_start = idx
            jobs_indent = indent(line)
            break
    if jobs_start is None:
        return []

    jobs: list[tuple[str, int, int]] = []
    job_indent = None
    current_name = None
    current_start = 0
    for idx in range(jobs_start + 1, len(clean)):
        line = clean[idx]
        stripped = line.strip()
        if not stripped:
            continue
        current_indent = indent(line)
        if current_indent <= jobs_indent:
            break
        if job_indent is None:
            job_indent = current_indent
        if current_indent == job_indent:
            name = key_name(line)
            if name is None:
                continue
            if current_name is not None:
                jobs.append((current_name, current_start, idx))
            current_name = name
            current_start = idx
    if current_name is not None:
        jobs.append((current_name, current_start, len(clean)))

    return [(name, lines[start:end]) for name, start, end in jobs]


def analyze_workflow(path: Path, repo: Path) -> dict[str, object]:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    rel = str(path.relative_to(repo))
    triggered = has_push_or_pr_trigger(lines)
    if not triggered:
        return {"rel": rel, "triggered": False, "gap": False, "mode": "not_push_or_pr"}

    blocks = concurrency_blocks(lines)
    workflow_level_ok = any(block["indent"] == 0 and block["has_cancel"] for block in blocks)
    jobs = job_blocks(lines)
    missing_jobs: list[str] = []
    if jobs:
        for name, job_lines in jobs:
            if not any(block["has_cancel"] for block in concurrency_blocks(job_lines)):
                missing_jobs.append(name)
    job_level_ok = bool(jobs) and not missing_jobs
    gap = not workflow_level_ok and not job_level_ok
    if workflow_level_ok:
        mode = "workflow_level"
    elif job_level_ok:
        mode = "job_level"
    else:
        mode = "missing_concurrency" if not jobs else f"missing_jobs={','.join(missing_jobs)}"
    return {
        "rel": rel,
        "triggered": True,
        "gap": gap,
        "mode": mode,
        "workflow_level_ok": workflow_level_ok,
        "job_level_ok": job_level_ok,
    }


repo = Path(sys.argv[1]).resolve()
if not repo.is_dir():
    print('{"error":"repo_not_found"}')
    raise SystemExit(1)

workflow_dir = repo / ".github" / "workflows"
workflow_files = []
if workflow_dir.is_dir():
    workflow_files = sorted([*workflow_dir.glob("*.yml"), *workflow_dir.glob("*.yaml")])

analyses = [analyze_workflow(path, repo) for path in workflow_files]
triggered = [item for item in analyses if item["triggered"]]
gaps = [item for item in triggered if item["gap"]]
workflow_level = [item for item in triggered if item.get("workflow_level_ok")]
job_level = [item for item in triggered if item.get("job_level_ok")]
evidence_parts = [
    f"gap=>{item['rel']}:{item['mode']}" for item in gaps[:5]
]
if not evidence_parts:
    evidence_parts = [
        f"non_hit=>{item['rel']}:{item['mode']}" for item in analyses[:5]
    ]

run_helper({
    "fired": bool(gaps),
    "workflow_file_count": len(workflow_files),
    "triggered_workflow_count": len(triggered),
    "workflow_level_concurrency_count": len(workflow_level),
    "job_level_concurrency_workflow_count": len(job_level),
    "gap_count": len(gaps),
    "evidence": " | ".join(evidence_parts) or "no GitHub Actions workflow files found",
})
PY
