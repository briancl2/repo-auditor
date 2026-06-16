#!/usr/bin/env bash
# Verify AS-41 detects Campaign Sync completed-track readback drift and predicate gaps.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

GAP_REPO="$TMPDIR/campaign-sync-gap"
CLEAN_REPO="$TMPDIR/campaign-sync-clean"
NEUTRAL_REPO="$TMPDIR/campaign-sync-neutral"
HISTORICAL_REPO="$TMPDIR/campaign-sync-historical"
mkdir -p "$GAP_REPO/docs" "$GAP_REPO/scripts" "$CLEAN_REPO/docs" "$NEUTRAL_REPO/docs"
mkdir -p "$HISTORICAL_REPO/docs/completions"

cat > "$GAP_REPO/docs/final-sync-drift.md" <<'EOF'
# Final Campaign Sync

## Campaign Sync
- Completed track: #816 Hermes failure residue guidance
- Next active track: #798 Runtime Learning Shadow
- Micro-work rule: no standalone tiny output-cleanup issues.
- Threshold clause: adoption/delivery proof

Issue #164 readback:
Completed latest track: #811 stale completed track
EOF

cat > "$GAP_REPO/docs/final-sync-missing-readback.md" <<'EOF'
# Final Campaign Sync admission

Closes #818.

## Campaign Sync
- Completed track: #818 maker-checker completed-track carrier
- Next active track: #798 Runtime Learning Shadow
- Micro-work rule: no standalone tiny output-cleanup issues.
- Threshold clause: adoption/delivery proof
EOF

cat > "$GAP_REPO/scripts/validate-github-campaign-pointer.py" <<'EOF'
def campaign_sync_errors_for_data(fields):
    keys_to_match = ["next active track", "micro-work rule", "threshold clause"]
    return keys_to_match
EOF

cat > "$CLEAN_REPO/docs/final-sync-clean.md" <<'EOF'
# Final Campaign Sync

## Campaign Sync
- Completed track: #818 maker-checker completed-track carrier
- Next active track: #798 Runtime Learning Shadow
- Micro-work rule: no standalone tiny output-cleanup issues.
- Threshold clause: adoption/delivery proof

Issue #164 readback:
Completed latest track: #818 maker-checker completed-track carrier

campaign_sync_completed_track_readback:
  matched: true
EOF

cat > "$CLEAN_REPO/docs/contract.md" <<'EOF'
# Campaign Sync contract

Final Campaign Sync predicate coverage requires next active track, micro-work
rule, threshold clause, completed track, Completed latest track:, and
campaign_sync_completed_track_readback before admit.
EOF

cat > "$NEUTRAL_REPO/docs/notes.md" <<'EOF'
# Notes

Ordinary repository notes with no Campaign Sync admission surface.
EOF

cat > "$HISTORICAL_REPO/docs/completions/stale-sync.md" <<'EOF'
# Historical Campaign Sync

## Campaign Sync
- Completed track: old track
- Next active track: old next track

Completed latest track: another old track
EOF

python3 - "$REPO_ROOT" "$GAP_REPO" "$CLEAN_REPO" "$NEUTRAL_REPO" "$HISTORICAL_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root, gap_repo, clean_repo, neutral_repo, historical_repo = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-campaign-sync-completed-track-gap.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


gap = run(gap_repo)
assert gap["ds_id"] == "AS-41", gap
assert gap["fired"] is True, gap
assert gap["signals"]["campaign_sync_completed_track_gap_count"] == 3, gap
assert gap["signals"]["completed_track_drift_count"] == 1, gap
assert gap["signals"]["missing_final_completed_track_readback_count"] == 1, gap
assert gap["signals"]["missing_completed_track_predicate_coverage_count"] == 1, gap

for repo in (clean_repo, neutral_repo):
    payload = run(repo)
    assert payload["ds_id"] == "AS-41", payload
    assert payload["fired"] is False, payload
    assert payload["signals"]["campaign_sync_completed_track_gap_count"] == 0, payload
    assert payload["signals"]["historical_evidence_skipped_count"] == 0, payload

historical_payload = run(historical_repo)
assert historical_payload["ds_id"] == "AS-41", historical_payload
assert historical_payload["fired"] is False, historical_payload
assert historical_payload["signals"]["campaign_sync_completed_track_gap_count"] == 0, historical_payload
assert historical_payload["signals"]["historical_evidence_skipped_count"] == 1, historical_payload
PY

echo "PASS: AS-41 Campaign Sync completed-track detector covered"
