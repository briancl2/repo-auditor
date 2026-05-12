#!/usr/bin/env bash
# detect-risk-review-gap.sh - DS-48: advisory risk-based review gap detection
# Detects repos that require broad LLM review without a repo-defined risk route.
#
# Usage: bash scripts/detect-risk-review-gap.sh <repo_path>

set -euo pipefail

REPO="${1:?Usage: detect-risk-review-gap.sh <repo_path>}"
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
    args = [
        sys.executable,
        str(helper),
        json.dumps(
            {
                "ds_id": "DS-48",
                "name": "Risk-based review gap",
                "severity": "MEDIUM",
                "prevention_tier": "T2",
            }
        ),
    ]
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

candidate_patterns = (
    "AGENTS.md",
    "CLAUDE.md",
    "README.md",
    ".github/copilot-instructions.md",
    ".github/instructions/*.md",
    "docs/**/*.md",
    "Makefile",
)

surfaces: list[Path] = []
seen: set[Path] = set()
for pattern in candidate_patterns:
    for path in repo.glob(pattern):
        if path.is_file() and path not in seen:
            surfaces.append(path)
            seen.add(path)

snippets: list[str] = []
for path in surfaces:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        continue
    snippets.append(f"\n--- {path.relative_to(repo)} ---\n{text[:12000]}")

combined = "\n".join(snippets).lower()
search_text = re.sub(r"\s+", " ", combined)

review_required_patterns = (
    r"make review.{0,80}(required|mandatory|before commit|before every commit|on every commit)",
    r"(required|mandatory).{0,80}make review",
    r"review is mandatory",
    r"full llm review.{0,80}(required|mandatory|all changes|every diff)",
)
review_required = any(re.search(pattern, search_text) for pattern in review_required_patterns)

risk_router_terms = (
    "risk class",
    "risk classes",
    "risk-tiered",
    "risk tiered",
    "risk-gated",
    "risk gated",
    "risk router",
    "risk routing",
    "low-risk",
    "medium-risk",
    "high-risk",
    "behavioral risk",
)
risk_router_present = any(term in combined for term in risk_router_terms)

low_risk_route_patterns = (
    r"low-risk.{0,160}(quality[- ]gate|spot-check|spot check|skip.{0,40}review|without.{0,40}make review)",
    r"quality[- ]gate.{0,160}(spot-check|spot check).{0,160}(low-risk|low risk)",
    r"review.{0,80}(only|required).{0,120}(medium|high)",
)
low_risk_route_present = any(re.search(pattern, search_text) for pattern in low_risk_route_patterns)

high_risk_route_patterns = (
    r"high-risk.{0,160}(review|maintainer|benchmark|spec)",
    r"(prompt|model|output|schema|shared contract).{0,120}(review|benchmark|required)",
    r"behavioral risk.{0,160}(review|benchmark|spec)",
)
high_risk_route_present = any(re.search(pattern, search_text) for pattern in high_risk_route_patterns)

severity_policy_patterns = (
    r"(critical|high).{0,80}(block|blocking|mandatory)",
    r"medium.{0,80}(advisory|disposition)",
    r"severity.{0,120}(risk|critical|high|medium|advisory)",
)
severity_policy_present = any(re.search(pattern, search_text) for pattern in severity_policy_patterns)

evidence = []
if surfaces:
    evidence.append("surfaces: " + ",".join(str(path.relative_to(repo)) for path in surfaces[:8]))
if review_required:
    evidence.append("broad review requirement detected")
if risk_router_present:
    evidence.append("risk-router terms detected")
if low_risk_route_present:
    evidence.append("low-risk deterministic/spot-check route detected")
if high_risk_route_present:
    evidence.append("high-risk review/benchmark route detected")
if severity_policy_present:
    evidence.append("risk-conditioned severity policy detected")

has_concrete_route = (low_risk_route_present or high_risk_route_present) and risk_router_present
fired = review_required and not has_concrete_route and not severity_policy_present

if fired:
    classification = "broad_review_without_risk_route"
elif has_concrete_route and severity_policy_present:
    classification = "risk_router_with_severity_policy"
elif has_concrete_route:
    classification = "risk_router_present"
elif not review_required:
    classification = "insufficient_review_policy_to_judge"
else:
    classification = "review_policy_inconclusive"

limitations = (
    "Advisory only: this detector reads repo policy text and does not prove "
    "review cost, correctness, or that a vault-style taxonomy should be copied."
)

run_helper(
    {
        "fired": fired,
        "classification": classification,
        "review_required": review_required,
        "risk_router_present": risk_router_present,
        "low_risk_route_present": low_risk_route_present,
        "high_risk_route_present": high_risk_route_present,
        "severity_policy_present": severity_policy_present,
        "policy_surface_count": len(surfaces),
        "advisory_only": True,
        "limitations": limitations,
        "evidence": " | ".join(evidence) or "no policy surfaces found",
    }
)
PY
