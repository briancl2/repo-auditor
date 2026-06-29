#!/usr/bin/env bash
# Verify AS-42 detects route-changing learning propagation gaps without flagging complete bounded material.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/route-learning-gap"
CLEAN_REPO="$TMPDIR/route-learning-clean"
NEUTRAL_REPO="$TMPDIR/route-learning-neutral"
HISTORICAL_REPO="$TMPDIR/route-learning-historical"
PRECISION_REPO="$TMPDIR/route-learning-precision"
mkdir -p "$GAP_REPO/docs" "$CLEAN_REPO/docs" "$NEUTRAL_REPO/docs"
mkdir -p "$HISTORICAL_REPO/docs/completions"
mkdir -p "$PRECISION_REPO/docs"

cat > "$GAP_REPO/docs/route-learning.md" <<'EOF'
# Route-changing learning note

ROUTE_CHANGING_LEARNING_FAILURE_RECEIPT route_changed=true.

Learning / Recovery says a broad GBrain search miss proves absence and changes
the route. The comment carried `repo-auditor#132` and JSON literal evidence, but
literal_safe_github_readback has no comment_url, expected_literals, or
readback_status. Hermes runs as a background queue and controller for follow-up
routing.
EOF

cat > "$GAP_REPO/docs/route-learning-stale-gbrain.md" <<'EOF'
# Route-changing stale GBrain note

Learning / Recovery

- GitHub surface: https://github.com/briancl2/build-meta-analysis/issues/840
- Raw evidence: /tmp/issue164-gbrain-exact-readback-learning-20260617T033611Z/progress-ledger.jsonl
- Optional GBrain slug: bma/issue164/learning/stale-card
- Fallback without memory: use GitHub issue/PR/check/merge truth.
- Owner action: open the repo-auditor AS-42 owner PR.
- Stale GBrain evidence is accepted as route truth.
- Bounded non-claims: no background GBrain, no controller, no scheduler, no queue, no daemon.
EOF

cat > "$CLEAN_REPO/docs/route-learning.json" <<'EOF'
{
  "artifact": "ROUTE_CHANGING_LEARNING_FAILURE_RECEIPT",
  "route_changed": true,
  "route_change_reason": "literal-safe GitHub readback changed the final owner route",
  "github_surface": "https://github.com/briancl2/build-meta-analysis/issues/811#issuecomment-4713816039",
  "raw_evidence": [
    "stdout/stderr receipt for foreground Hermes timeout",
    "/tmp/issue164-hermes-github-reliability-20260615T231816Z/repo-auditor-readonly-bma/as40-bma-final-main-after-all-repairs.json"
  ],
  "gbrain_search_disposition": {
    "found_route_changing_record": false,
    "note": "Broad GBrain search miss is advisory only and does not prove absence."
  },
  "gbrain_exact_handle_replay": [
    {
      "slug": "bma/issue164/learning/hermes-failure-visible-fallback-2026-06-14",
      "command": "timeout 10 gbrain get bma/issue164/learning/hermes-failure-visible-fallback-2026-06-14",
      "status": "passed",
      "decision_impact": "exact-handle replay confirmed the GitHub-visible fallback route"
    }
  ],
  "gbrain_slug_or_no_capture_reason": "bma/issue164/learning/hermes-failure-visible-fallback-2026-06-14",
  "fallback_without_memory": "Use GitHub issue/PR/check truth and the same owner action without advisory GBrain.",
  "owner_action": "Open repo-auditor owner PR for AS-42 route-changing learning propagation coverage.",
  "literal_safe_github_readback": {
    "required": true,
    "comment_url": "https://github.com/briancl2/build-meta-analysis/issues/811#issuecomment-4713816039",
    "expected_literals": ["repo-auditor#132", "fired=false"],
    "readback_status": "matched"
  },
  "bounded_non_claims": [
    "does not run background GBrain",
    "does not run background Hermes",
    "does not start a controller, scheduler, queue, daemon, or retry loop",
    "does not create issues or pull requests automatically"
  ]
}
EOF

cat > "$NEUTRAL_REPO/docs/notes.md" <<'EOF'
# Notes

Ordinary repository notes about release hygiene.
EOF

cat > "$HISTORICAL_REPO/docs/completions/stale-route-learning.md" <<'EOF'
# Historical route-changing learning note

ROUTE_CHANGING_LEARNING_FAILURE_RECEIPT without current GitHub evidence.
EOF

# --- Precision fixtures (repo-auditor#174): three known false-positive classes
#     that must NOT fire once the surface adjective, no-capture, and wrapped
#     non-claims handling are tightened. Each doc is otherwise grounded so a
#     revert of one precision fix re-fires exactly that doc.
#
# P1: principle-naming prose. Uses the bare "route-changing" adjective only, with
#     no record markers -> must de-classify (no surface match) and not fire.
cat > "$PRECISION_REPO/docs/principle-naming.md" <<'EOF'
# Grounded route-changing learning principle

Naming policy: grounded route-changing learnings should carry a fallback and a
runtime reference. This is principle-naming prose, not a learning record, and
creates no GitHub or owner obligation.
EOF

# P2: a genuine route-change record whose memory disposition is an explicit
#     no-capture reason -> there is no memory to fall back from, so
#     missing_fallback_without_memory must be suppressed.
cat > "$PRECISION_REPO/docs/no-capture-record.md" <<'EOF'
# Route-changing learning record (no-capture)

- ROUTE_CHANGING_LEARNING_FAILURE_RECEIPT route_changed=true.
- GitHub surface: https://github.com/briancl2/repo-auditor/issues/174
- Raw evidence: /tmp/issue164-precision/as42-no-capture-receipt.jsonl
- Memory disposition: no_capture_reason=routine-validation not_reusable.
- Owner action: open the repo-auditor AS-42 owner PR.
- Bounded non-claims: this record does not start a controller, scheduler, queue, or daemon.
EOF

# P3: a fully grounded record whose bounded-non-claims sentence WRAPS across two
#     physical lines, leaving the control words (daemon, queue, registry) on a
#     line with no negation. Sentence-aware segmentation must keep the negation
#     attached so background_or_controller_overclaim does not fire.
cat > "$PRECISION_REPO/docs/wrapped-non-claims.md" <<'EOF'
# Route-changing learning record (wrapped non-claims)

- ROUTE_CHANGING_LEARNING_FAILURE_RECEIPT route_changed=true.
- GitHub surface: https://github.com/briancl2/repo-auditor/issues/174
- Raw evidence: /tmp/issue164-precision/as42-wrapped-receipt.jsonl
- gbrain_slug_or_no_capture_reason: bma/issue164/learning/as42-precision-2026-06-29
- Exact handle replay: timeout 10 gbrain get bma/issue164/learning/as42-precision-2026-06-29 status=passed.
- fallback_without_memory: use GitHub issue/PR/check truth without advisory GBrain.
- Owner action: open the repo-auditor AS-42 owner PR.
- Bounded non-claims: this record does not authorize a background controller, scheduler,
  daemon, queue, registry, or retry loop.
EOF

python3 - "$REPO_ROOT" "$GAP_REPO" "$CLEAN_REPO" "$NEUTRAL_REPO" "$HISTORICAL_REPO" "$PRECISION_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root, gap_repo, clean_repo, neutral_repo, historical_repo, precision_repo = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-route-changing-learning-propagation-gap.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


gap = run(gap_repo)
assert gap["ds_id"] == "AS-42", gap
assert gap["fired"] is True, gap
assert gap["signals"]["route_changing_learning_gap_count"] == 2, gap
assert gap["signals"]["missing_github_surface_count"] == 1, gap
assert gap["signals"]["missing_raw_evidence_count"] == 1, gap
assert gap["signals"]["missing_gbrain_slug_or_no_capture_reason_count"] == 1, gap
assert gap["signals"]["missing_exact_readback_or_no_capture_count"] == 1, gap
assert gap["signals"]["missing_fallback_without_memory_count"] == 1, gap
assert gap["signals"]["missing_owner_action_count"] == 1, gap
assert gap["signals"]["unsafe_literal_readback_count"] == 1, gap
assert gap["signals"]["broad_search_miss_as_absence_count"] == 1, gap
assert gap["signals"]["stale_or_failed_gbrain_overclaim_count"] == 1, gap
assert gap["signals"]["background_or_controller_overclaim_count"] == 1, gap

for repo in (clean_repo, neutral_repo):
    payload = run(repo)
    assert payload["ds_id"] == "AS-42", payload
    assert payload["fired"] is False, payload
    assert payload["signals"]["route_changing_learning_gap_count"] == 0, payload
    assert payload["signals"]["historical_evidence_skipped_count"] == 0, payload

historical_payload = run(historical_repo)
assert historical_payload["ds_id"] == "AS-42", historical_payload
assert historical_payload["fired"] is False, historical_payload
assert historical_payload["signals"]["route_changing_learning_gap_count"] == 0, historical_payload
assert historical_payload["signals"]["historical_evidence_skipped_count"] == 1, historical_payload

# Precision (repo-auditor#174): all three false-positive classes must clear.
# A revert of any one precision fix re-fires its own doc, so these asserts pin
# each fix individually.
precision = run(precision_repo)
assert precision["ds_id"] == "AS-42", precision
assert precision["fired"] is False, precision
assert precision["signals"]["route_changing_learning_gap_count"] == 0, precision
# Bug 3 lock: a no-capture record has no memory to fall back from.
assert precision["signals"]["missing_fallback_without_memory_count"] == 0, precision
# Bug 2 lock: a wrapped bounded-non-claims sentence is not an affirmative overclaim.
assert precision["signals"]["background_or_controller_overclaim_count"] == 0, precision
# Bug 1 lock: principle-naming + grounded records leave two grounded surfaces and
# de-classify the adjective-only doc (so grounded count is 2, not 3).
assert precision["signals"]["route_changing_learning_grounded_count"] == 2, precision
PY

echo "PASS: AS-42 route-changing learning propagation detector covered"
