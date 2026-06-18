#!/usr/bin/env bash
# Verify AS-46 detects missing Deep Research source-intelligence native corpus fields.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/deep-research-corpus-gap"
OVERCLAIM_REPO="$TMPDIR/deep-research-corpus-overclaim"
CLEAN_REPO="$TMPDIR/deep-research-corpus-clean"
NEUTRAL_REPO="$TMPDIR/deep-research-corpus-neutral"
CONTRACT_REPO="$TMPDIR/deep-research-corpus-contract"
HISTORICAL_REPO="$TMPDIR/deep-research-corpus-historical"
mkdir -p "$GAP_REPO/docs" "$OVERCLAIM_REPO/docs" "$CLEAN_REPO/docs"
mkdir -p "$NEUTRAL_REPO/docs" "$CONTRACT_REPO/docs" "$HISTORICAL_REPO/docs/completions"

cat > "$GAP_REPO/docs/deep-research-corpus.md" <<'EOF'
# Deep Research/source-intelligence native corpus

DEEP_RESEARCH_SOURCE_INTELLIGENCE_NATIVE_CORPUS is planned for the campaign.
source_id entries exist.
manual Deep Research sidecar: TBD.
EOF

cat > "$OVERCLAIM_REPO/docs/deep-research-corpus.md" <<'EOF'
# Deep Research/source-intelligence native corpus

DEEP_RESEARCH_SOURCE_INTELLIGENCE_NATIVE_CORPUS composes SOURCE_INSIGHT_PACKET.
source_count: 19 exact operator X URLs.
source_id values: arc4-x-01 through arc4-x-19.
access order: public/no-auth first, then exact-url authenticated capture.
manual Deep Research sidecar prompt only.
deep_research_api_disposition=rescoped_failed_not_authorized.
equal-insight disposition records insight/no-insight and contradiction.
claim_effect routes each claim to evidence.
evidence_tier records official_current_fact, local_proof, or operator_corpus.
owner/no-action disposition records owner_surface or explicit_no_action.
bounded non-claims: none.
GitHub issue/PR/check/merge truth is recorded.
next_owner_action: repo-upgrade-advisor recommendation propagation.

Deep Research API ran live and proved the research intake.
Codex Cloud remote execution ran as a live proof for this corpus.
A source registry crawler and background watcher keep the corpus fresh.
Retain raw authenticated DOM and screenshots in the committed package.
automatic issue creation and auto-merge are enabled.
The retained closeout package is closure truth.
This authorizes downstream mutation.
EOF

cat > "$CLEAN_REPO/docs/deep-research-corpus.md" <<'EOF'
# Deep Research/source-intelligence native corpus

DEEP_RESEARCH_SOURCE_INTELLIGENCE_NATIVE_CORPUS composes SOURCE_INSIGHT_PACKET.
source_count: 19 exact operator-provided X URLs.
source_id values: arc4-x-01 through arc4-x-19.
access order: public/no-auth first, then exact-url authenticated capture only
for approved URLs.
manual Deep Research sidecar prompt only.
deep_research_api_disposition=rescoped_failed_not_authorized.
equal-insight disposition records insight/no-insight and contradiction.
claim_effect routes each claim to evidence.
evidence_tier records official_current_fact, local_proof, or operator_corpus.
owner/no-action disposition records owner_surface or explicit_no_action.
bounded non-claims: no live Deep Research API run, no live Codex Cloud
execution, no live Codex remote execution, no crawler, no source registry, no
watcher, no controller, no scheduler, no queue, no daemon, no automatic GitHub
mutation, no retained closeout truth, and no downstream mutation.
GitHub issue/PR/check/merge truth is recorded.
next_owner_action: repo-upgrade-advisor recommendation propagation.
EOF

cat > "$NEUTRAL_REPO/docs/notes.md" <<'EOF'
# Notes

Ordinary notes without Deep Research source-intelligence native corpus material.
EOF

cat > "$CONTRACT_REPO/docs/deep-research-source-intelligence-native-corpus-contract.md" <<'EOF'
# Deep Research Source-Intelligence Native Corpus Contract

This detector should suppress the shared contract definition. It defines
DEEP_RESEARCH_SOURCE_INTELLIGENCE_NATIVE_CORPUS, SOURCE_INSIGHT_PACKET,
manual sidecar, source_id, evidence_tier, and owner/no-action fields.
EOF

cat > "$HISTORICAL_REPO/docs/completions/deep-research-corpus.md" <<'EOF'
# Historical Deep Research/source-intelligence native corpus

DEEP_RESEARCH_SOURCE_INTELLIGENCE_NATIVE_CORPUS is missing source IDs and
owner routing in this old completion note.
EOF

python3 - "$REPO_ROOT" "$GAP_REPO" "$OVERCLAIM_REPO" "$CLEAN_REPO" "$NEUTRAL_REPO" "$CONTRACT_REPO" "$HISTORICAL_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root, gap_repo, overclaim_repo, clean_repo, neutral_repo, contract_repo, historical_repo = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-deep-research-source-intelligence-native-corpus-gap.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


gap = run(gap_repo)
assert gap["ds_id"] == "AS-46", gap
assert gap["fired"] is True, gap
assert gap["signals"]["deep_research_source_intelligence_native_corpus_gap_count"] == 1, gap
assert gap["signals"]["missing_native_contract_token_count"] == 0, gap
assert gap["signals"]["missing_source_insight_packet_count"] == 1, gap
assert gap["signals"]["missing_source_count_or_corpus_scope_count"] == 1, gap
assert gap["signals"]["missing_access_order_count"] == 1, gap
assert gap["signals"]["missing_equal_insight_disposition_count"] == 1, gap
assert gap["signals"]["missing_claim_effect_count"] == 1, gap
assert gap["signals"]["missing_evidence_tier_count"] == 1, gap
assert gap["signals"]["missing_owner_no_action_count"] == 1, gap
assert gap["signals"]["missing_bounded_non_claims_count"] == 1, gap
assert gap["signals"]["vague_field_count"] >= 1, gap

overclaim = run(overclaim_repo)
assert overclaim["ds_id"] == "AS-46", overclaim
assert overclaim["fired"] is True, overclaim
assert overclaim["signals"]["live_deep_research_api_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["live_cloud_remote_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["crawler_registry_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["raw_authenticated_retention_count"] == 1, overclaim
assert overclaim["signals"]["automatic_github_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["retained_closeout_overclaim_count"] == 1, overclaim
assert overclaim["signals"]["downstream_mutation_overclaim_count"] == 1, overclaim

for repo in (clean_repo, neutral_repo, contract_repo):
    payload = run(repo)
    assert payload["ds_id"] == "AS-46", payload
    assert payload["fired"] is False, payload
    assert payload["signals"]["deep_research_source_intelligence_native_corpus_gap_count"] == 0, payload

historical = run(historical_repo)
assert historical["ds_id"] == "AS-46", historical
assert historical["fired"] is False, historical
assert historical["signals"]["historical_evidence_skipped_count"] == 1, historical
PY

echo "PASS: AS-46 Deep Research source-intelligence native corpus detector covered"
