#!/usr/bin/env bash
# detect-workflow-contract-drift.sh — DS-45: workflow-contract drift detection
# Detects when helper/orchestrator scripts encode a compact workflow contract
# that higher-precedence agent/prompt/skill surfaces fail to carry forward.
#
# Usage: bash scripts/detect-workflow-contract-drift.sh <repo_path>

set -euo pipefail

REPO="${1:?Usage: detect-workflow-contract-drift.sh <repo_path>}"
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
        "ds_id": "DS-45",
        "name": "Workflow contract drift",
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

helper_candidates = []
for base in ("tools", "scripts"):
    root = repo / base
    if not root.exists():
        continue
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix not in {".sh", ".py", ".md"}:
            continue
        helper_candidates.append(path)

surface_candidates = []
for pattern in (
    ".github/agents/*.md",
    ".github/prompts/*.md",
    ".github/skills/*/SKILL.md",
    ".agents/*.md",
    ".agents/skills/*/SKILL.md",
):
    surface_candidates.extend(repo.glob(pattern))

helper_signals = {
    "working_set": [r"working set", r"build_phase3_working_set", r"phase3_working_set"],
    "scaffold_init": [r"init_phase3_curated_sections", r"initialize.*curated", r"scaffold"],
    "edit_in_place": [r"edit .* in place", r"canonical curated artifact", r"do not use .*create-file"],
    "todo_replacement": [r"replace all todo", r"todo markers", r"html comment placeholders"],
}

helper_texts: list[tuple[Path, str]] = []
for path in helper_candidates:
    text = path.read_text(encoding="utf-8", errors="replace")
    lowered = text.lower()
    if "phase3" in lowered or "curated" in lowered or "working set" in lowered:
        helper_texts.append((path, lowered))

surface_text = "\n".join(
    path.read_text(encoding="utf-8", errors="replace").lower()
    for path in surface_candidates
)

helper_hits: dict[str, list[str]] = {}
surface_hits: dict[str, bool] = {}
for signal, patterns in helper_signals.items():
    hit_files = []
    for path, lowered in helper_texts:
        if any(re.search(pattern, lowered) for pattern in patterns):
            hit_files.append(str(path.relative_to(repo)))
    if hit_files:
        helper_hits[signal] = hit_files
    surface_hits[signal] = any(re.search(pattern, surface_text) for pattern in patterns)

helper_signal_count = len(helper_hits)
missing_signals = [signal for signal in helper_hits if not surface_hits.get(signal)]
surface_has_generic_create = "create-file" in surface_text and "do not use a generic create-file" not in surface_text
surface_has_edit_guard = "edit in place" in surface_text or "do not use a generic create-file" in surface_text

fired = False
reasons = []
if helper_signal_count >= 2 and len(missing_signals) >= 2:
    fired = True
    reasons.append(
        f"helper contract exposes {helper_signal_count} compact-path signals but higher-precedence surfaces miss {len(missing_signals)} of them"
    )
if helper_signal_count >= 2 and surface_has_generic_create and not surface_has_edit_guard:
    fired = True
    reasons.append("higher-precedence surfaces still permit generic create-file behavior despite helper-level edit-in-place workflow")

evidence_parts = []
if helper_hits:
    evidence_parts.append(
        "helper signals: "
        + "; ".join(f"{signal}=>{','.join(paths)}" for signal, paths in sorted(helper_hits.items()))
    )
if missing_signals:
    evidence_parts.append("missing surface signals: " + ",".join(missing_signals))
if reasons:
    evidence_parts.append("reasons: " + "; ".join(reasons))

run_helper({
    "fired": fired,
    "helper_files_scanned": len(helper_texts),
    "surface_files_scanned": len(surface_candidates),
    "helper_signal_count": helper_signal_count,
    "missing_surface_signal_count": len(missing_signals),
    "missing_surface_signals": missing_signals,
    "evidence": " | ".join(evidence_parts) or "no compact phase workflow helper signals found",
})
PY
