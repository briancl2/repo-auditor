#!/usr/bin/env bash
# detect-summary-source-parity-gap.sh — DS-47: summary-source parity gap
# Detects report/evidence surfaces that use retained summary metrics as
# behavior evidence for total events / tool calls / tool distribution without
# the exact same-surface parity stack.
#
# Usage: bash scripts/detect-summary-source-parity-gap.sh <repo_path>

set -euo pipefail

REPO="${1:?Usage: detect-summary-source-parity-gap.sh <repo_path>}"
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
        "ds_id": "DS-47",
        "name": "Summary-source parity gap",
        "severity": "HIGH",
        "prevention_tier": "T1",
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


repo = Path(sys.argv[1]).resolve()
if not repo.is_dir():
    print('{"error":"repo_not_found"}')
    raise SystemExit(1)

skip_parts = {
    ".git",
    "node_modules",
    ".venv",
    "vendor",
    "__pycache__",
    "archive",
    "benchmarks",
    "work",
    "specs",
    "targets",
    ".agents",
    ".specify",
}
allowed_top_levels = {"docs", "research", "audit", "runs"}

summary_patterns = [
    r"session-log-summary\.md",
    r"retained summary",
    r"current retained summary",
    r"summary artifact",
]
behavior_patterns = [
    r"behavior evidence",
    r"behavior source",
    r"used as behavior",
    r"used as .*evidence",
    r"treated as .*source",
]
field_patterns = {
    "total_events": [r"total events"],
    "tool_calls": [r"tool calls"],
    "tool_distribution": [r"tool distribution"],
}
provenance_patterns = [
    r"summary[- ]provenance",
    r"provenance receipt",
    r"matches a fresh replay",
    r"replayed summary",
]
parser_patterns = [
    r"session-parser",
    r"direct parser",
    r"parse_session\.py",
]
raw_patterns = [
    r"raw-event",
    r"tool\.execution_start",
    r"events\.jsonl",
]
out_of_scope_patterns = [
    r"duration",
    r"error-event parity",
]

files_scanned = 0
in_scope_file_count = 0
gap_count = 0
out_of_scope_count = 0
evidence_parts: list[str] = []

for path in repo.rglob("*.md"):
    rel = path.relative_to(repo)
    if any(part in skip_parts for part in rel.parts):
        continue
    if len(rel.parts) > 1 and rel.parts[0] not in allowed_top_levels:
        continue
    text = path.read_text(encoding="utf-8", errors="replace").lower()
    files_scanned += 1

    has_summary = any(re.search(pattern, text) for pattern in summary_patterns)
    has_behavior = any(re.search(pattern, text) for pattern in behavior_patterns)
    in_scope_fields = [
        field for field, patterns in field_patterns.items()
        if any(re.search(pattern, text) for pattern in patterns)
    ]

    if has_summary and has_behavior and in_scope_fields:
        in_scope_file_count += 1
        has_provenance = any(re.search(pattern, text) for pattern in provenance_patterns)
        has_parser = any(re.search(pattern, text) for pattern in parser_patterns)
        has_raw = any(re.search(pattern, text) for pattern in raw_patterns)

        missing_layers = []
        if not has_provenance:
            missing_layers.append("summary_provenance")
        if not has_parser:
            missing_layers.append("direct_parser")
        if not has_raw:
            missing_layers.append("raw_event")

        if missing_layers:
            gap_count += 1
            evidence_parts.append(
                f"gap=>{rel}:fields={','.join(in_scope_fields)}:missing={','.join(missing_layers)}"
            )
        else:
            evidence_parts.append(
                f"non_hit=>{rel}:fields={','.join(in_scope_fields)}:parity=complete"
            )
        # In-scope field claims take precedence over duration/error-only
        # mentions so mixed files are treated as in-scope, not out-of-scope.
        continue

    if has_summary and has_behavior and any(re.search(pattern, text) for pattern in out_of_scope_patterns):
        out_of_scope_count += 1
        evidence_parts.append(f"out_of_scope=>{rel}")

fired = gap_count > 0

run_helper({
    "fired": fired,
    "files_scanned": files_scanned,
    "in_scope_file_count": in_scope_file_count,
    "gap_count": gap_count,
    "out_of_scope_count": out_of_scope_count,
    "evidence": " | ".join(evidence_parts[:6]) or "no summary-source parity surfaces found",
})
PY
