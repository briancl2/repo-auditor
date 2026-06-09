#!/usr/bin/env bash
# Validate AS-36 GBrain instruction distribution overclaim detector.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/detect-as-gbrain-instruction-distribution-overclaim.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

CANONICAL_REPO="$TMPDIR/canonical-repo"
CANONICAL_UNRELATED_NEGATION_REPO="$TMPDIR/canonical-unrelated-negation-repo"
CANONICAL_PRIOR_NEGATION_REPO="$TMPDIR/canonical-prior-negation-repo"
CANONICAL_PRIOR_NO_PERIOD_NEGATION_REPO="$TMPDIR/canonical-prior-no-period-negation-repo"
CANONICAL_PRIOR_BULLET_NEGATION_REPO="$TMPDIR/canonical-prior-bullet-negation-repo"
BACKGROUND_REPO="$TMPDIR/background-repo"
BACKGROUND_CRON_REPO="$TMPDIR/background-cron-repo"
BACKGROUND_COMMAND_FIRST_REPO="$TMPDIR/background-command-first-repo"
JOBS_WORKER_REPO="$TMPDIR/jobs-worker-repo"
WRAPPED_BACKGROUND_REPO="$TMPDIR/wrapped-background-repo"
WRAPPED_SYNC_BACKGROUND_REPO="$TMPDIR/wrapped-sync-background-repo"
MISSING_REPO="$TMPDIR/missing-repo"
WRAPPED_DISTRIBUTION_REPO="$TMPDIR/wrapped-distribution-repo"
GITHUB_INSTRUCTIONS_REPO="$TMPDIR/github-instructions-repo"
NEGATED_BOUNDARY_REPO="$TMPDIR/negated-boundary-repo"
NEGATION_WINDOW_REPO="$TMPDIR/negation-window-repo"
SAME_LINE_NEGATION_REPO="$TMPDIR/same-line-negation-repo"
UNRELATED_BACKGROUND_REPO="$TMPDIR/unrelated-background-repo"
UNRELATED_GBRAIN_REPO="$TMPDIR/unrelated-gbrain-repo"
SOURCE_NOT_REQUIRED_REPO="$TMPDIR/source-not-required-repo"
HEALTHY_REPO="$TMPDIR/healthy-repo"
HERMES_GBRAIN_CONTRACT_REPO="$TMPDIR/hermes-gbrain-contract-repo"
EXACT_REPLAY_MISSING_REPO="$TMPDIR/exact-replay-missing-repo"
EXACT_REPLAY_HEALTHY_REPO="$TMPDIR/exact-replay-healthy-repo"
mkdir -p "$CANONICAL_REPO" "$CANONICAL_UNRELATED_NEGATION_REPO" "$CANONICAL_PRIOR_NEGATION_REPO" "$CANONICAL_PRIOR_NO_PERIOD_NEGATION_REPO" "$CANONICAL_PRIOR_BULLET_NEGATION_REPO" "$BACKGROUND_REPO" "$BACKGROUND_CRON_REPO" "$BACKGROUND_COMMAND_FIRST_REPO" "$JOBS_WORKER_REPO" "$WRAPPED_BACKGROUND_REPO" "$WRAPPED_SYNC_BACKGROUND_REPO" "$MISSING_REPO" "$WRAPPED_DISTRIBUTION_REPO" "$GITHUB_INSTRUCTIONS_REPO/.github/instructions" "$NEGATED_BOUNDARY_REPO" "$NEGATION_WINDOW_REPO" "$SAME_LINE_NEGATION_REPO" "$UNRELATED_BACKGROUND_REPO" "$UNRELATED_GBRAIN_REPO" "$SOURCE_NOT_REQUIRED_REPO" "$HEALTHY_REPO" "$HERMES_GBRAIN_CONTRACT_REPO" "$EXACT_REPLAY_MISSING_REPO" "$EXACT_REPLAY_HEALTHY_REPO"

cat > "$CANONICAL_REPO/AGENTS.md" <<'EOF'
# AGENTS

GBrain is canonical for repo-local instruction distribution and overrides repo evidence.
EOF

cat > "$CANONICAL_UNRELATED_NEGATION_REPO/AGENTS.md" <<'EOF'
# AGENTS

GBrain is canonical for repo-local instruction distribution; do not use repo evidence.
EOF

cat > "$CANONICAL_PRIOR_NEGATION_REPO/AGENTS.md" <<'EOF'
# AGENTS

Do not mutate downstream targets.
GBrain canonicality is required for repo-local instruction distribution.
Source/citation/provenance refs are required.
EOF

cat > "$CANONICAL_PRIOR_NO_PERIOD_NEGATION_REPO/AGENTS.md" <<'EOF'
# AGENTS

Do not mutate downstream targets
GBrain canonicality is required for repo-local instruction distribution.
Source/citation/provenance refs are required.
EOF

cat > "$CANONICAL_PRIOR_BULLET_NEGATION_REPO/AGENTS.md" <<'EOF'
# AGENTS

- Do not mutate downstream targets
- GBrain canonicality is required for repo-local instruction distribution.
- Source/citation/provenance refs are required.
EOF

cat > "$BACKGROUND_REPO/AGENTS.md" <<'EOF'
# AGENTS

GBrain remains advisory for repo-local instruction distribution.
Use GBrain sync --watch to keep instruction surfaces fresh.
Source/citation/provenance refs are required.
EOF

cat > "$BACKGROUND_CRON_REPO/AGENTS.md" <<'EOF'
# AGENTS

GBrain remains advisory for repo-local instruction distribution.
Use GBrain cron to keep instruction surfaces fresh.
Source/citation/provenance refs are required.
EOF

cat > "$BACKGROUND_COMMAND_FIRST_REPO/AGENTS.md" <<'EOF'
# AGENTS

GBrain remains advisory for repo-local instruction distribution.
Use cron to refresh GBrain instruction surfaces.
Source/citation/provenance refs are required.
EOF

cat > "$JOBS_WORKER_REPO/AGENTS.md" <<'EOF'
# AGENTS

GBrain remains advisory for repo-local instruction distribution.
Use GBrain jobs worker to keep instruction surfaces fresh.
Source/citation/provenance refs are required.
EOF

cat > "$WRAPPED_BACKGROUND_REPO/AGENTS.md" <<'EOF'
# AGENTS

GBrain remains advisory for repo-local instruction distribution.
Use GBrain
sync --watch to keep instruction surfaces fresh.
Source/citation/provenance refs are required.
EOF

cat > "$WRAPPED_SYNC_BACKGROUND_REPO/AGENTS.md" <<'EOF'
# AGENTS

GBrain remains advisory for repo-local instruction distribution.
Use GBrain sync
--watch to keep instruction surfaces fresh.
Source/citation/provenance refs are required.
EOF

cat > "$MISSING_REPO/AGENTS.md" <<'EOF'
# AGENTS

Use GBrain distribution records for repo-local instructions.
EOF

cat > "$WRAPPED_DISTRIBUTION_REPO/AGENTS.md" <<'EOF'
# AGENTS

Use GBrain
distribution records for repo-local instructions.
EOF

cat > "$GITHUB_INSTRUCTIONS_REPO/.github/instructions/gbrain.instructions.md" <<'EOF'
# GBrain Instructions

Use GBrain distribution records for repo-local instruction surfaces.
EOF

cat > "$NEGATED_BOUNDARY_REPO/AGENTS.md" <<'EOF'
# AGENTS

Use GBrain distribution records for repo-local instructions. GBrain is not
advisory and distribution can proceed without source refs.
EOF

cat > "$NEGATION_WINDOW_REPO/AGENTS.md" <<'EOF'
# AGENTS

Do not mutate downstream repos.
Use GBrain sync --watch for repo-local instruction distribution.
GBrain remains advisory. Source/citation/provenance refs are required.
EOF

cat > "$SAME_LINE_NEGATION_REPO/AGENTS.md" <<'EOF'
# AGENTS

Do not mutate downstream repos; use GBrain sync --watch for repo-local
instruction distribution. GBrain remains advisory.
Source/citation/provenance refs are required.
EOF

cat > "$UNRELATED_BACKGROUND_REPO/AGENTS.md" <<'EOF'
# AGENTS

GBrain remains advisory for repo-local instruction distribution.
Source/citation/provenance refs are required.
The release job uses cron, queues, and schedulers for ordinary service work.
EOF

cat > "$UNRELATED_GBRAIN_REPO/AGENTS.md" <<'EOF'
# AGENTS

GBrain may be queried for historical notes during research.
EOF

cat > "$SOURCE_NOT_REQUIRED_REPO/AGENTS.md" <<'EOF'
# AGENTS

GBrain remains advisory for repo-local instruction distribution.
Source refs are not required for GBrain distribution records.
EOF

cat > "$HEALTHY_REPO/AGENTS.md" <<'EOF'
# AGENTS

Advisory GBrain distribution into repo-local instructions consumes
repo-agent-core docs/gbrain-repo-local-instruction-distribution-contract.md by
copy-sync or citation only. GBrain remains advisory: use records only with
source/citation/provenance or GitHub surface references, never as canonical
truth, and never to override operator intent, GitHub issue/PR/check/merge
truth, target/repo evidence, or repo-local instructions. Route stale, missing,
uncited, or overclaiming guidance to the owner surface. Do not use GBrain bulk
import, sync/watch, cron, autopilot, dream, jobs worker, MCP serving, minions,
daemons, schedulers, queues, hidden registries, or background memory behavior.
EOF

cat > "$HERMES_GBRAIN_CONTRACT_REPO/README.md" <<'EOF'
# Hermes Doer With GBrain-Distributed Instructions

Hermes remains a bounded foreground first-attempt doer while consuming
repo-local instruction surfaces that cite advisory GBrain distribution guidance.
GBrain remains advisory and may be used only with source/citation/provenance or
GitHub surface references. The contract forbids claims that promote GBrain
canonicality, source-of-truth status, or a canonical GBrain memory claim.
It also forbids background GBrain behavior, bulk import, sync/watch, cron,
autopilot, dream, jobs worker, MCP serving, minions, daemons, schedulers,
queues, hidden registries, or background memory behavior.

This episode does not make GBrain canonical, does not let GBrain override
operator intent, and does not run `gbrain sync --watch`, cron, autopilot, dream,
jobs worker, MCP serving, minions, daemons, schedulers, queues, hidden
registries, or background memory behavior.
EOF

cat > "$EXACT_REPLAY_MISSING_REPO/AGENTS.md" <<'EOF'
# AGENTS

Use GBrain exact-handle replay for operator-intent defaults before launch.
Record the broad search result and exact-get result.
EOF

cat > "$EXACT_REPLAY_HEALTHY_REPO/AGENTS.md" <<'EOF'
# AGENTS

Use GBrain exact-handle replay only as advisory memory for operator-intent
defaults. Record broad search/query disposition, exact-get evidence, GBrain
slug or no-capture reason, and fallback without memory. Record raw GitHub
surface evidence and owner action. Record source/citation/provenance refs.
GBrain remains advisory. canonical_records_written=0; this does not make GBrain canonical.
Do not use GBrain sync --watch, cron, autopilot, dream, jobs worker, MCP
serving, minions, daemons, schedulers, queues, hidden registries, or background
memory behavior.
EOF

canonical_json=$(bash "$SCRIPT" "$CANONICAL_REPO")
printf '%s' "$canonical_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["canonical_claim_count"] >= 1
'
echo "  PASS: AS-36 fires on GBrain canonical or override claims"

canonical_unrelated_negation_json=$(bash "$SCRIPT" "$CANONICAL_UNRELATED_NEGATION_REPO")
printf '%s' "$canonical_unrelated_negation_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["canonical_claim_count"] >= 1
'
echo "  PASS: AS-36 does not let unrelated same-line negation suppress canonical claims"

canonical_prior_negation_json=$(bash "$SCRIPT" "$CANONICAL_PRIOR_NEGATION_REPO")
printf '%s' "$canonical_prior_negation_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["canonical_claim_count"] >= 1
'
echo "  PASS: AS-36 does not let unrelated prior-sentence negation suppress canonical claims"

canonical_prior_no_period_negation_json=$(bash "$SCRIPT" "$CANONICAL_PRIOR_NO_PERIOD_NEGATION_REPO")
printf '%s' "$canonical_prior_no_period_negation_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["canonical_claim_count"] >= 1
'
echo "  PASS: AS-36 does not let unrelated prior no-period negation suppress canonical claims"

canonical_prior_bullet_negation_json=$(bash "$SCRIPT" "$CANONICAL_PRIOR_BULLET_NEGATION_REPO")
printf '%s' "$canonical_prior_bullet_negation_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["canonical_claim_count"] >= 1
'
echo "  PASS: AS-36 does not let unrelated prior bullet negation suppress canonical claims"

background_json=$(bash "$SCRIPT" "$BACKGROUND_REPO")
printf '%s' "$background_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["background_gbrain_command_count"] >= 1
'
echo "  PASS: AS-36 fires on un-negated background GBrain commands"

background_cron_json=$(bash "$SCRIPT" "$BACKGROUND_CRON_REPO")
printf '%s' "$background_cron_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["background_gbrain_command_count"] >= 1
'
echo "  PASS: AS-36 fires on un-negated GBrain cron guidance"

background_command_first_json=$(bash "$SCRIPT" "$BACKGROUND_COMMAND_FIRST_REPO")
printf '%s' "$background_command_first_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["background_gbrain_command_count"] >= 1
'
echo "  PASS: AS-36 fires on command-first GBrain background guidance"

jobs_worker_json=$(bash "$SCRIPT" "$JOBS_WORKER_REPO")
printf '%s' "$jobs_worker_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["background_gbrain_command_count"] >= 1
'
echo "  PASS: AS-36 fires on GBrain jobs worker guidance"

wrapped_background_json=$(bash "$SCRIPT" "$WRAPPED_BACKGROUND_REPO")
printf '%s' "$wrapped_background_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["background_gbrain_command_count"] >= 1
'
echo "  PASS: AS-36 fires on wrapped GBrain background commands"

wrapped_sync_background_json=$(bash "$SCRIPT" "$WRAPPED_SYNC_BACKGROUND_REPO")
printf '%s' "$wrapped_sync_background_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["background_gbrain_command_count"] >= 1
'
echo "  PASS: AS-36 fires on wrapped GBrain sync background commands"

missing_json=$(bash "$SCRIPT" "$MISSING_REPO")
printf '%s' "$missing_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["missing_advisory_boundary_count"] >= 1
assert data["signals"]["missing_source_or_citation_expectation_count"] >= 1
'
echo "  PASS: AS-36 fires on missing advisory and source/citation boundaries"

wrapped_distribution_json=$(bash "$SCRIPT" "$WRAPPED_DISTRIBUTION_REPO")
printf '%s' "$wrapped_distribution_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["missing_advisory_boundary_count"] >= 1
'
echo "  PASS: AS-36 sees wrapped GBrain distribution context"

github_instructions_json=$(bash "$SCRIPT" "$GITHUB_INSTRUCTIONS_REPO")
printf '%s' "$github_instructions_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["missing_advisory_boundary_count"] >= 1
'
echo "  PASS: AS-36 scans GitHub .instructions.md surfaces"

negated_boundary_json=$(bash "$SCRIPT" "$NEGATED_BOUNDARY_REPO")
printf '%s' "$negated_boundary_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["missing_advisory_boundary_count"] >= 1
assert data["signals"]["missing_source_or_citation_expectation_count"] >= 1
'
echo "  PASS: AS-36 rejects negated advisory and source/citation wording"

negation_window_json=$(bash "$SCRIPT" "$NEGATION_WINDOW_REPO")
printf '%s' "$negation_window_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["background_gbrain_command_count"] >= 1
'
echo "  PASS: AS-36 does not let unrelated prior negation suppress a GBrain background command"

same_line_negation_json=$(bash "$SCRIPT" "$SAME_LINE_NEGATION_REPO")
printf '%s' "$same_line_negation_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["background_gbrain_command_count"] >= 1
'
echo "  PASS: AS-36 does not let unrelated same-line negation suppress a GBrain background command"

unrelated_background_json=$(bash "$SCRIPT" "$UNRELATED_BACKGROUND_REPO")
printf '%s' "$unrelated_background_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is False
assert data["signals"]["background_gbrain_command_count"] == 0
'
echo "  PASS: AS-36 ignores unrelated cron/queue/scheduler guidance"

unrelated_gbrain_json=$(bash "$SCRIPT" "$UNRELATED_GBRAIN_REPO")
printf '%s' "$unrelated_gbrain_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is False
assert data["signals"]["gbrain_instruction_surface_count"] == 0
'
echo "  PASS: AS-36 ignores GBrain mentions without distribution context"

source_not_required_json=$(bash "$SCRIPT" "$SOURCE_NOT_REQUIRED_REPO")
printf '%s' "$source_not_required_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True
assert data["signals"]["missing_source_or_citation_expectation_count"] >= 1
'
echo "  PASS: AS-36 rejects source/citation terms that are explicitly not required"

exact_replay_missing_json=$(bash "$SCRIPT" "$EXACT_REPLAY_MISSING_REPO")
printf '%s' "$exact_replay_missing_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is True, data
signals = data["signals"]
assert signals["exact_replay_gap_count"] >= 1, signals
assert signals["missing_advisory_boundary_count"] >= 1, signals
assert signals["missing_source_or_citation_expectation_count"] >= 1, signals
assert signals["missing_exact_replay_fallback_count"] >= 1, signals
assert signals["missing_exact_replay_no_canonical_count"] >= 1, signals
assert signals["missing_exact_replay_no_background_count"] >= 1, signals
'
echo "  PASS: AS-36 fires on exact-handle replay surfaces missing advisory/source/fallback/no-canonical/no-background boundaries"

exact_replay_healthy_json=$(bash "$SCRIPT" "$EXACT_REPLAY_HEALTHY_REPO")
printf '%s' "$exact_replay_healthy_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is False, data
signals = data["signals"]
assert signals["gbrain_instruction_surface_count"] >= 1, signals
assert signals["exact_replay_gap_count"] == 0, signals
assert signals["canonical_claim_count"] == 0, signals
assert signals["background_gbrain_command_count"] == 0, signals
'
echo "  PASS: AS-36 accepts bounded GBrain exact-handle replay instruction guidance"

healthy_json=$(bash "$SCRIPT" "$HEALTHY_REPO")
printf '%s' "$healthy_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is False
assert data["signals"]["gbrain_instruction_surface_count"] >= 1
'
echo "  PASS: AS-36 accepts bounded advisory GBrain instruction guidance"

hermes_gbrain_contract_json=$(bash "$SCRIPT" "$HERMES_GBRAIN_CONTRACT_REPO")
printf '%s' "$hermes_gbrain_contract_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-36"
assert data["fired"] is False, data
assert data["signals"]["gbrain_instruction_surface_count"] >= 1
assert data["signals"]["canonical_claim_count"] == 0
assert data["signals"]["background_gbrain_command_count"] == 0
'
echo "  PASS: AS-36 accepts bounded Hermes/GBrain contract non-claims"

echo "  VERDICT: PASS"
