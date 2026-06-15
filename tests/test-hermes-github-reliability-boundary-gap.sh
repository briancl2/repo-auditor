#!/usr/bin/env bash
# Verify AS-40 detects Hermes/GitHub reliability boundary gaps without flagging clean bounded guidance.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/reliability-gap"
CLEAN_REPO="$TMPDIR/reliability-clean"
NEUTRAL_REPO="$TMPDIR/reliability-neutral"
mkdir -p "$GAP_REPO/docs" "$CLEAN_REPO/docs" "$NEUTRAL_REPO/docs"

cat > "$GAP_REPO/docs/reliability.md" <<'EOF'
# Reliability note

The PR body says this does not close #798, so the local body scan is sufficient
and there is no need for closingIssuesReferences.

Hermes foreground timed out after producing a useful diff. Codex fallback can
continue from the diff without failure guidance, GitHub issue truth, or a
failure-to-issue conversion.

Hermes owns the background coordinator queue for the merge loop and can operate
the campaign retry loop after the first failure.
EOF

cat > "$CLEAN_REPO/docs/reliability.md" <<'EOF'
# Reliability note

- Parsed closure receipt: GITHUB_PARSED_CLOSURE_SEMANTICS_RECEIPT.
- GitHub closingIssuesReferences: [] for the non-final carrier PR.
- HERMES_FOREGROUND_FAILURE_GUIDANCE routes any timeout or useful-diff failure
  through github-failure-to-issue before Codex fallback.
- Codex/BMA remains coordinator for validation, PR/CI/merge, Campaign Sync, and
  recovery.
- Boundary: no background Hermes, scheduler, queue, daemon, controller, retry
  loop, or Hermes-primary campaign operation.
EOF

cat > "$NEUTRAL_REPO/docs/detector-note.md" <<'EOF'
# AS-40 detector note

AS-40: Hermes/GitHub Reliability Boundary detects parsed closure, Hermes
failure disposition, and Hermes coordinator/background overclaim gaps. This is
detector documentation, not target guidance.
EOF

python3 - "$REPO_ROOT" "$GAP_REPO" "$CLEAN_REPO" "$NEUTRAL_REPO" <<'PY'
import json
import subprocess
import sys

repo_root, gap_repo, clean_repo, neutral_repo = sys.argv[1:5]

def run(repo):
    completed = subprocess.run(
        ["bash", f"{repo_root}/scripts/detect-as-hermes-github-reliability-boundary-gap.sh", repo],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    return json.loads(completed.stdout)

gap = run(gap_repo)
assert gap["ds_id"] == "AS-40", gap
assert gap["fired"] is True, gap
assert gap["signals"]["reliability_boundary_gap_count"] == 1, gap
assert gap["signals"]["parsed_closure_semantics_gap_count"] == 1, gap
assert gap["signals"]["hermes_failure_disposition_gap_count"] == 1, gap
assert gap["signals"]["hermes_coordinator_background_overclaim_count"] == 1, gap

for repo in (clean_repo, neutral_repo):
    payload = run(repo)
    assert payload["ds_id"] == "AS-40", payload
    assert payload["fired"] is False, payload
    assert payload["signals"]["reliability_boundary_gap_count"] == 0, payload
PY

echo "Hermes/GitHub reliability boundary gap detector test passed."
