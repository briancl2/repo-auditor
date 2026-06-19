#!/usr/bin/env bash
# Verify AS-48 detects standalone external-intelligence sidecar gaps.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/standalone-sidecar-gap"
OVERCLAIM_REPO="$TMPDIR/standalone-sidecar-overclaim"
CLEAN_REPO="$TMPDIR/standalone-sidecar-clean"
NEUTRAL_REPO="$TMPDIR/standalone-sidecar-neutral"
CONTRACT_REPO="$TMPDIR/standalone-sidecar-contract"
HISTORICAL_REPO="$TMPDIR/standalone-sidecar-historical"
BROAD_GAP_REPO="$TMPDIR/standalone-sidecar-broad-gap"
SOURCE_LEDGER_V2_GAP_REPO="$TMPDIR/standalone-sidecar-source-ledger-v2-gap"
CLEAN_BROAD_REPO="$TMPDIR/standalone-sidecar-clean-broad"
LOCAL_AWARE_OVERCLAIM_REPO="$TMPDIR/standalone-sidecar-local-aware-overclaim"
mkdir -p "$GAP_REPO/docs" "$OVERCLAIM_REPO/docs" "$CLEAN_REPO/docs"
mkdir -p "$NEUTRAL_REPO/docs" "$CONTRACT_REPO/docs" "$HISTORICAL_REPO/docs/completions"
mkdir -p "$BROAD_GAP_REPO/docs" "$SOURCE_LEDGER_V2_GAP_REPO/docs" "$CLEAN_BROAD_REPO/docs"
mkdir -p "$LOCAL_AWARE_OVERCLAIM_REPO/docs"

cat > "$GAP_REPO/docs/sidecar.md" <<'EOF'
# Sidecar Prompt

Prompt B for BMA should solve the architecture problem.
Definitions: TBD.
EOF

cat > "$OVERCLAIM_REPO/docs/sidecar.md" <<'EOF'
# Sidecar Prompt

STANDALONE_EXTERNAL_INTELLIGENCE_SIDECAR
You are an external intelligence.
Read the GitHub issue and inspect the local repository path before answering.
Review this prompt and improve it.
Prompt B can proceed without the actual Prompt A output.
Deep Research should research this, but source rules are omitted.
The sidecar approves PRs and becomes closure truth.
A controller queue creates GitHub issues automatically and auto-merges repairs.
EOF

cat > "$CLEAN_REPO/docs/sidecar.md" <<'EOF'
# Standalone External-Intelligence Sidecar Prompt

STANDALONE_EXTERNAL_INTELLIGENCE_SIDECAR
You are an external intelligence receiving a standalone prompt.
You do not have local filesystem access, private repository access, GitHub
issue access, prior chat access, or workspace context beyond what is embedded.
All required context is embedded below.
Public URLs are optional and non-load-bearing.

## Definitions And Glossary

- BMA: Build Meta Analysis, the campaign workspace.
- Prompt A: first pass for clarifying questions and context gaps.
- Prompt B: second pass after actual Prompt A output plus answered context.
- Deep Research: research mode with research targets, source rules, and source-ledger response shape.

## Embedded Context

The prompt contains enough context for an external model to answer without
private files, prior chats, or GitHub access. It explains goals, boundaries,
failure modes, integration points, and success criteria.

## Actual Prompt A Output

The model asked for definitions and missing context.

## Answered Context

The operator answered the missing context and embedded it here.

## Research Targets

Research prompt quality and standalone external review patterns.

## Source Rules

Use public sources only and return a source-ledger response shape.

## Response Shape

Return Executive Verdict, Prompt A Reconciliation, Findings, Risks, Source Ledger, and Next Step.

## Boundary

Sidecar output is advisory and does not close GitHub issues, approve pull
requests, mutate repositories, replace operator judgment, or become closure
truth. No controller, scheduler, queue, daemon, registry, automatic GitHub
mutation, or auto-merge is authorized.
EOF

cat > "$NEUTRAL_REPO/docs/notes.md" <<'EOF'
# Notes

Ordinary documentation without sidecar prompt material.
EOF

cat > "$CONTRACT_REPO/docs/sidecar-prompt-ab-response-shaped-contract.md" <<'EOF'
# Standalone External-Intelligence Sidecar Contract

AS-48 Standalone External Intelligence Sidecar Gap detector documentation.
EOF

cat > "$HISTORICAL_REPO/docs/completions/sidecar.md" <<'EOF'
# Historical Sidecar Prompt

Prompt B without actual Prompt A output.
EOF

cat > "$BROAD_GAP_REPO/docs/broad-sidecar.md" <<'EOF'
# Broad Standalone Sidecar Acceptance

BROAD_STANDALONE_SIDECAR_ACCEPTANCE
STANDALONE_EXTERNAL_INTELLIGENCE_SIDECAR
You are an external intelligence receiving a standalone prompt.
You do not have local filesystem access, private repository access, GitHub
issue access, prior chat access, or workspace context beyond what is embedded.
All required context is embedded below.
Public URLs are optional and non-load-bearing.
Definitions: BMA means Build Meta Analysis. Deep Research means manual public
research mode.
Response Shape: return verdict, source ledger, and next owner action.
Sidecar output is advisory and not closure truth.
This claims broad sidecar acceptance but omits proxy battery, red-team
regression, local-aware critique, manual transport, and explicit non-claims.
EOF

cat > "$SOURCE_LEDGER_V2_GAP_REPO/docs/source-ledger-v2.md" <<'EOF'
# Source-Ledger V2 Adoption

STANDALONE_EXTERNAL_INTELLIGENCE_SIDECAR
DEEP_RESEARCH_SOURCE_LEDGER_V2_ADOPTION
You are an external intelligence receiving a standalone prompt.
You do not have local filesystem access, private repository access, GitHub
issue access, prior chat access, or workspace context beyond what is embedded.
All required context is embedded below.
Public URLs are optional and non-load-bearing.
Definitions: Deep Research means manual public research mode.
Deep Research includes research targets, source rules, and source-ledger output.
Response Shape: return verdict, source ledger, and next owner action.
Sidecar output is advisory and not closure truth.
The source ledger records consulted-on date, but omits the other v2 fields.
EOF

cat > "$LOCAL_AWARE_OVERCLAIM_REPO/docs/local-aware-overclaim.md" <<'EOF'
# Local-Aware Critique Misuse

STANDALONE_EXTERNAL_INTELLIGENCE_SIDECAR
You are an external intelligence receiving a standalone prompt.
You do not have local filesystem access, private repository access, GitHub
issue access, prior chat access, or workspace context beyond what is embedded.
All required context is embedded below.
Public URLs are optional and non-load-bearing.
Definitions: local-aware critique means a reviewer that may inspect the local
repository.
Response Shape: return verdict and next owner action.
Sidecar output is advisory and not closure truth.
The local-aware critique is standalone sidecar proof.
EOF

cat > "$CLEAN_BROAD_REPO/docs/broad-sidecar-clean.md" <<'EOF'
# Broad Standalone Sidecar Acceptance

BROAD_STANDALONE_SIDECAR_ACCEPTANCE
STANDALONE_EXTERNAL_INTELLIGENCE_SIDECAR
You are an external intelligence receiving a standalone prompt.
You do not have local filesystem access, private repository access, GitHub
issue access, prior chat access, or workspace context beyond what is embedded.
All required context is embedded below.
Public URLs are optional and non-load-bearing.

## Definitions And Glossary

- Prompt A: first pass for clarifying questions and context gaps.
- Prompt B: second pass after actual Prompt A output plus answered context.
- Deep Research: research mode with research targets, source rules, and
  source-ledger response shape.
- Local-aware critique: diagnostics lane that may inspect local files and is not
  standalone sidecar proof.

## Embedded Context

The prompt contains the required goals, failure modes, integration points,
source-ledger v2 fields, evidence requirements, and boundaries.

## Actual Prompt A Output

The model asked for definitions and missing context.

## Answered Context

The operator answered the missing context and embedded it here.

## Research Targets

Research standalone prompt quality and public-source source-ledger practice.

## Source Rules

Use public sources only and return a source-ledger v2 response shape with
consulted_on_date, exclusion_rationale, and recommendation_effect.

## Response Shape

Return Executive Verdict, Findings, Risks, Source Ledger, and Next Step.

## Proof

The bundle-only Opus proxy battery accepted 8/8 trials.
Red-team boundary regression validation failed as expected.
The local-aware critique pass had no unresolved CRITICAL or HIGH findings.
A final manual Deep Research transport trial passed.

## Boundary

Sidecar output is advisory and does not close GitHub issues, approve pull
requests, mutate repositories, replace operator judgment, or become closure
truth. No Deep Research API validation is claimed.
No authenticated-source capture validation is claimed.
No sidecar closure truth is claimed. No source
registry, crawler, watcher, controller, scheduler, queue, daemon, automatic
ingestion, automatic GitHub mutation, or auto-merge is authorized.
EOF

python3 - "$REPO_ROOT" "$GAP_REPO" "$OVERCLAIM_REPO" "$CLEAN_REPO" "$NEUTRAL_REPO" "$CONTRACT_REPO" "$HISTORICAL_REPO" "$BROAD_GAP_REPO" "$SOURCE_LEDGER_V2_GAP_REPO" "$CLEAN_BROAD_REPO" "$LOCAL_AWARE_OVERCLAIM_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

(
    repo_root,
    gap_repo,
    overclaim_repo,
    clean_repo,
    neutral_repo,
    contract_repo,
    historical_repo,
    broad_gap_repo,
    source_ledger_v2_gap_repo,
    clean_broad_repo,
    local_aware_overclaim_repo,
) = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-standalone-external-intelligence-sidecar-gap.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


gap = run(gap_repo)
assert gap["ds_id"] == "AS-48", gap
assert gap["fired"] is True, gap
assert gap["signals"]["standalone_external_intelligence_sidecar_gap_count"] == 1, gap
assert gap["signals"]["missing_standalone_sidecar_token_count"] == 1, gap
assert gap["signals"]["missing_access_boundary_count"] == 1, gap
assert gap["signals"]["missing_embedded_context_count"] == 1, gap
assert gap["signals"]["missing_url_boundary_count"] == 1, gap
assert gap["signals"]["missing_response_shape_count"] == 1, gap
assert gap["signals"]["prompt_b_without_actual_prompt_a_count"] == 1, gap

overclaim = run(overclaim_repo)
assert overclaim["ds_id"] == "AS-48", overclaim
assert overclaim["fired"] is True, overclaim
assert overclaim["signals"]["local_private_github_dependency_count"] == 1, overclaim
assert overclaim["signals"]["prompt_layer_confusion_count"] == 1, overclaim
assert overclaim["signals"]["prompt_b_without_actual_prompt_a_count"] == 1, overclaim
assert overclaim["signals"]["deep_research_missing_research_shape_count"] == 1, overclaim
assert overclaim["signals"]["sidecar_authority_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["control_plane_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["automatic_github_overclaim_count"] == 1, overclaim

for repo in (clean_repo, neutral_repo, contract_repo):
    payload = run(repo)
    assert payload["ds_id"] == "AS-48", payload
    assert payload["fired"] is False, payload
    assert payload["signals"]["standalone_external_intelligence_sidecar_gap_count"] == 0, payload

historical = run(historical_repo)
assert historical["ds_id"] == "AS-48", historical
assert historical["fired"] is False, historical
assert historical["signals"]["historical_evidence_skipped_count"] == 1, historical

broad_gap = run(broad_gap_repo)
assert broad_gap["ds_id"] == "AS-48", broad_gap
assert broad_gap["fired"] is True, broad_gap
assert broad_gap["signals"]["missing_broad_proxy_battery_count"] == 1, broad_gap
assert broad_gap["signals"]["missing_redteam_regression_count"] == 1, broad_gap
assert broad_gap["signals"]["missing_local_aware_critique_count"] == 1, broad_gap
assert broad_gap["signals"]["missing_final_manual_deep_research_transport_count"] == 1, broad_gap
assert broad_gap["signals"]["missing_deep_research_api_nonclaim_count"] == 1, broad_gap
assert broad_gap["signals"]["missing_authenticated_capture_nonclaim_count"] == 1, broad_gap
assert broad_gap["signals"]["missing_sidecar_closure_truth_nonclaim_count"] == 1, broad_gap

source_ledger_v2_gap = run(source_ledger_v2_gap_repo)
assert source_ledger_v2_gap["ds_id"] == "AS-48", source_ledger_v2_gap
assert source_ledger_v2_gap["fired"] is True, source_ledger_v2_gap
assert source_ledger_v2_gap["signals"]["missing_consulted_on_date_count"] == 0, source_ledger_v2_gap
assert source_ledger_v2_gap["signals"]["missing_exclusion_rationale_count"] == 1, source_ledger_v2_gap
assert source_ledger_v2_gap["signals"]["missing_recommendation_effect_count"] == 1, source_ledger_v2_gap

local_aware_overclaim = run(local_aware_overclaim_repo)
assert local_aware_overclaim["ds_id"] == "AS-48", local_aware_overclaim
assert local_aware_overclaim["fired"] is True, local_aware_overclaim
assert local_aware_overclaim["signals"]["local_aware_as_standalone_proof_count"] == 1, local_aware_overclaim

clean_broad = run(clean_broad_repo)
assert clean_broad["ds_id"] == "AS-48", clean_broad
assert clean_broad["fired"] is False, clean_broad
assert clean_broad["signals"]["standalone_external_intelligence_sidecar_gap_count"] == 0, clean_broad
PY

echo "PASS: AS-48 standalone external-intelligence sidecar detector covered"
