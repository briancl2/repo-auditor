#!/usr/bin/env bash
# detect-llm-validation-gap.sh — DS-46: LLM-path validation gap detection
# Detects repos whose CI/tests validate scorers and fixtures but never execute
# the live LLM/orchestrated workflow those validators are meant to protect.
#
# Usage: bash scripts/detect-llm-validation-gap.sh <repo_path>

set -euo pipefail

REPO="${1:?Usage: detect-llm-validation-gap.sh <repo_path>}"
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
        "ds_id": "DS-46",
        "name": "LLM-path validation gap",
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

workflow_surfaces = []
for pattern in (
    ".github/agents/*.md",
    ".github/prompts/*.md",
    ".github/skills/*/SKILL.md",
    "tools/run_*orchestrated*.sh",
    "tools/*newsletter*.sh",
):
    workflow_surfaces.extend(path for path in repo.glob(pattern) if path.is_file())

validation_files = []
for pattern in (
    ".github/workflows/*.yml",
    ".github/workflows/*.yaml",
    "tools/test_*.sh",
    "tools/validate*.sh",
    "tests/*.sh",
    "scripts/test*.sh",
):
    validation_files.extend(path for path in repo.glob(pattern) if path.is_file())

workflow_count = len(workflow_surfaces)
validation_count = len(validation_files)

validation_text = "\n".join(
    path.read_text(encoding="utf-8", errors="replace").lower()
    for path in validation_files
)

llm_execution_patterns = [
    r"run_.*orchestrated",
    r"prepare_newsletter_cycle",
    r"\bcopilot\b",
    r"customer_newsletter\.agent",
    r"phase3_curation",
]
validator_only_patterns = [
    r"test_benchmark_regression",
    r"score-",
    r"validate_pipeline_strict",
    r"validate_newsletter",
    r"score-structural",
    r"score-heuristic",
]

llm_execution_refs = [pat for pat in llm_execution_patterns if re.search(pat, validation_text)]
validator_only_refs = [pat for pat in validator_only_patterns if re.search(pat, validation_text)]
explicit_gap_text = (
    "tests the scoring tools and benchmark data, not the llm skills" in validation_text
    or "not the llm skills" in validation_text
)

fired = False
reasons = []
if workflow_count >= 3 and validation_count >= 1 and not llm_execution_refs and validator_only_refs:
    fired = True
    reasons.append("validation surface exercises validators/scorers but never executes the live LLM workflow")
if explicit_gap_text:
    fired = True
    reasons.append("validation text explicitly declares scorer-only coverage and excludes LLM skills")

evidence = []
if workflow_surfaces:
    evidence.append(
        "workflow surfaces: " + ",".join(str(path.relative_to(repo)) for path in workflow_surfaces[:6])
    )
if validation_files:
    evidence.append(
        "validation files: " + ",".join(str(path.relative_to(repo)) for path in validation_files[:6])
    )
if validator_only_refs:
    evidence.append("validator refs: " + ",".join(sorted(set(validator_only_refs))))
if llm_execution_refs:
    evidence.append("llm execution refs: " + ",".join(sorted(set(llm_execution_refs))))
if reasons:
    evidence.append("reasons: " + "; ".join(reasons))

run_helper({
    "fired": fired,
    "workflow_surfaces_count": workflow_count,
    "validation_files_count": validation_count,
    "llm_execution_reference_count": len(llm_execution_refs),
    "validator_reference_count": len(validator_only_refs),
    "explicit_gap_text": explicit_gap_text,
    "evidence": " | ".join(evidence) or "workflow or validation surfaces not present",
})
PY
