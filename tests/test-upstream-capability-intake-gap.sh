#!/usr/bin/env bash
# Validate AS-35 upstream capability intake gap detector.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/detect-as-upstream-capability-intake-gap.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/gap-repo"
HEALTHY_REPO="$TMPDIR/healthy-repo"
STALE_REPO="$TMPDIR/stale-repo"
mkdir -p "$GAP_REPO/docs" "$HEALTHY_REPO/docs" "$STALE_REPO/docs"

cat > "$GAP_REPO/docs/intake.md" <<'EOF'
# Upstream Capability Intake

Component identity: local drift detector
Local version: wrapper@abc123
Upstream reference: repo-auditor classified detector
Behindness signal: local detector can disagree with owner detector
Delta clusters: archive classification and retained evidence scoping
Capability decisions: adopt native capability
Update action: delete/sunset local detector
Validation: missing
EOF

cat > "$HEALTHY_REPO/docs/intake.md" <<'EOF'
# Upstream Capability Intake

Component identity: local drift detector
Local version: wrapper@abc123
Upstream reference: repo-auditor classified detector commit def456
Behindness signal: local detector can disagree with owner detector
Source refs: repo-auditor#84 and repo-agent-core#35
Delta clusters: archive classification and retained evidence scoping
Capability decisions: owner-route plus delete/sunset after validation
Update action: open owner PR
Validation: make check, make test, and drift replay receipt
Adoption-plan refs: repo-auditor#84
Owner routes: repo-auditor owns detector behavior
Non-claims: no scheduler, controller, registry, generated inventory, or target mutation
Out-of-bounds surfaces: downstream repos and background scans
EOF

cat > "$STALE_REPO/docs/intake.md" <<'EOF'
# Upstream Capability Intake

Component identity: local drift detector
Local version: wrapper@abc123
Upstream reference: stale
Behindness signal: behindness reduced to 0
Source refs: stale
Delta clusters: archive classification
Capability decisions: adopt
Update action: update now
Validation: missing
Adoption-plan refs: repo-auditor#84
Owner routes: repo-auditor owns detector behavior
Non-claims: no scheduler, controller, registry, generated inventory, or target mutation
Out-of-bounds surfaces: downstream repos and background scans
EOF

gap_json=$(bash "$SCRIPT" "$GAP_REPO")
printf '%s' "$gap_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-35"
assert data["fired"] is True
assert data["signals"]["missing_field_record_count"] >= 1
assert data["signals"]["update_claim_without_validation_count"] >= 1
'
echo "  PASS: AS-35 fires on missing required intake fields and validation"

healthy_json=$(bash "$SCRIPT" "$HEALTHY_REPO")
printf '%s' "$healthy_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-35"
assert data["fired"] is False
assert data["signals"]["upstream_intake_record_count"] >= 1
'
echo "  PASS: AS-35 accepts complete bounded intake record"

stale_json=$(bash "$SCRIPT" "$STALE_REPO")
printf '%s' "$stale_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
assert data["ds_id"] == "AS-35"
assert data["fired"] is True
assert data["signals"]["stale_source_ref_record_count"] >= 1
assert data["signals"]["update_claim_without_validation_count"] >= 1
'
echo "  PASS: AS-35 fires on stale source refs and update claims without validation"

echo "  VERDICT: PASS"
