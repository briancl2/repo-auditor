#!/usr/bin/env bash
# Verify AS-40 detects Hermes/GitHub reliability boundary gaps without flagging clean bounded material.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/hermes-github-gap"
CLEAN_REPO="$TMPDIR/hermes-github-clean"
NEUTRAL_REPO="$TMPDIR/hermes-github-neutral"
HISTORICAL_REPO="$TMPDIR/hermes-github-historical"
GENERIC_FAILURE_REPO="$TMPDIR/hermes-github-generic-failure"
mkdir -p "$GAP_REPO/docs" "$CLEAN_REPO/docs" "$NEUTRAL_REPO/docs"
mkdir -p "$HISTORICAL_REPO/docs/completions" "$GENERIC_FAILURE_REPO/docs"

cat > "$GAP_REPO/docs/reliability.md" <<'EOF'
# Issue #164 Hermes/GitHub reliability note

This is a non-final Issue #164 child PR. The PR body says it does not close
#798, and that wording is acceptable because author intent is clear.

HERMES_FOREGROUND_FAILURE_GUIDANCE shows provider_user_request_timeout on #796.
No fresh repro or failure residue disposition has been recorded yet.
The failure-to-issue conversion remains pending for this Hermes provider timeout.

Hermes owns merge polling and retries the PR until green as a background Hermes
worker.
EOF

cat > "$CLEAN_REPO/docs/reliability.md" <<'EOF'
# Issue #164 Hermes/GitHub reliability note

Non-final Issue #164 PRs use `Refs` wording only. The parsed GitHub
`closingIssuesReferences` readback is empty.

HERMES_FOREGROUND_FAILURE_GUIDANCE from #796 was followed by a fresh bounded
repro and the failure residue classification is recovered_close_residue.

Boundary: Hermes remains foreground only and does not merge, retry, schedule,
queue, run as a daemon, act as a controller, or own background work.
EOF

cat > "$NEUTRAL_REPO/docs/notes.md" <<'EOF'
# Notes

Ordinary repo docs with no Hermes or Issue #164 reliability surface.
EOF

cat > "$HISTORICAL_REPO/docs/completions/stale.json" <<'EOF'
{
  "operator_intent": "Historical Issue #164 completion manifest.",
  "outcome": "BMA foreground failure-to-issue conversion ran without a daemon, queue, scheduler, retry loop, controller, or target repo mutation.",
  "not_yet_delivered": "Hermes target execution and public/fleet adoption were not delivered."
}
EOF

cat > "$GENERIC_FAILURE_REPO/docs/failure-to-issue.md" <<'EOF'
# Issue #164 foreground failure conversion

# Generic BMA failure conversion is not Hermes-specific residue.
BMA foreground `failure-to-issue` guidance converts command failures into
GitHub-visible owner issues. It is not a Hermes-specific timeout claim and does
not require a current repro unless the evidence is tied to a Hermes foreground
failure receipt or provider timeout residue.
EOF

python3 - "$REPO_ROOT" "$GAP_REPO" "$CLEAN_REPO" "$NEUTRAL_REPO" "$HISTORICAL_REPO" "$GENERIC_FAILURE_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root, gap_repo, clean_repo, neutral_repo, historical_repo, generic_failure_repo = map(Path, sys.argv[1:])

def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-hermes-github-reliability-boundary-gap.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)

gap = run(gap_repo)
assert gap["ds_id"] == "AS-40", gap
assert gap["fired"] is True, gap
assert gap["signals"]["hermes_github_reliability_gap_count"] == 1, gap
assert gap["signals"]["negated_closure_keyword_parse_hazard_count"] == 1, gap
assert gap["signals"]["missing_fresh_hermes_failure_disposition_count"] == 1, gap
assert gap["signals"]["hermes_coordinator_or_background_overclaim_count"] == 1, gap

for repo in (clean_repo, neutral_repo, generic_failure_repo):
    payload = run(repo)
    assert payload["ds_id"] == "AS-40", payload
    assert payload["fired"] is False, payload
    assert payload["signals"]["hermes_github_reliability_gap_count"] == 0, payload
    assert payload["signals"]["historical_evidence_skipped_count"] == 0, payload

historical_payload = run(historical_repo)
assert historical_payload["ds_id"] == "AS-40", historical_payload
assert historical_payload["fired"] is False, historical_payload
assert historical_payload["signals"]["hermes_github_reliability_gap_count"] == 0, historical_payload
assert historical_payload["signals"]["historical_evidence_skipped_count"] == 1, historical_payload
PY

echo "PASS: AS-40 Hermes/GitHub reliability boundary detector covered"
