#!/usr/bin/env bash
# Verify AS-38 detects self-authored campaign pause authority without flagging grounded pauses or ordinary next tracks.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

SELF_AUTHORED_REPO="$TMPDIR/self-authored-no-action"
NEGATIVE_SEARCH_REPO="$TMPDIR/negative-search-pause"
STALE_DOWNSTREAM_REPO="$TMPDIR/stale-downstream-pause"
OPERATOR_PAUSE_REPO="$TMPDIR/operator-approved-pause"
TRUE_CLOSURE_REPO="$TMPDIR/true-campaign-closure"
EXPLAINER_REPO="$TMPDIR/detector-docs"
ORDINARY_NEXT_REPO="$TMPDIR/ordinary-next-track"

mkdir -p \
    "$SELF_AUTHORED_REPO/docs" \
    "$NEGATIVE_SEARCH_REPO/docs" \
    "$STALE_DOWNSTREAM_REPO/docs" \
    "$OPERATOR_PAUSE_REPO/docs" \
    "$TRUE_CLOSURE_REPO/docs" \
    "$EXPLAINER_REPO/detection-signatures" \
    "$ORDINARY_NEXT_REPO/docs"

cat > "$SELF_AUTHORED_REPO/docs/campaign-sync.md" <<'EOF'
# Issue #164 Campaign Sync

Active child: none.
Next active track: None selected.
Codex found no current admissible owner-surface action remains, so the campaign
should stop until new work appears.
EOF

cat > "$NEGATIVE_SEARCH_REPO/docs/campaign-sync.md" <<'EOF'
# GitHub-Native Campaign Sync

Pause the campaign. Next active track: None selected.
Evidence: gh issue list returned no open child issues and no open PRs, so there
is no next owner-surface route.
EOF

cat > "$STALE_DOWNSTREAM_REPO/docs/campaign-sync.md" <<'EOF'
# Issue164 Active Track Disposition

Campaign is complete for now. Next active track: none.
The only support is a stale downstream reference from a previous final
opportunity package; no fresh owner issue or PR is named.
EOF

cat > "$OPERATOR_PAUSE_REPO/docs/campaign-sync.md" <<'EOF'
# Issue #164 Operator Pause

Next active track: None selected.
Explicit operator approval to pause the campaign was recorded on the GitHub
issue before clearing the active track.
EOF

cat > "$TRUE_CLOSURE_REPO/docs/campaign-sync.md" <<'EOF'
# Issue #164 Final Closure

True campaign closure: all campaign work is closed and all campaign families
are resolved. Unresolved campaign families: none. Next active track: None
selected.
EOF

cat > "$EXPLAINER_REPO/detection-signatures/DS-43-plus.md" <<'EOF'
# Detector Docs

### AS-38: Self-Authored Campaign Pause Authority
- Detects: `Next active track: None selected` when backed only by no open issue
  search results, stale downstream references, or a self-authored no-action
  assertion.
- Clean examples: explicit operator-approved pause evidence and true campaign
  closure with no unresolved campaign families.
EOF

cat > "$ORDINARY_NEXT_REPO/docs/campaign-sync.md" <<'EOF'
# Issue #164 Campaign Sync

Active child: repo-auditor#100.
Next active track: repo-auditor#100 - self-authored campaign pause authority detector.
First owner PR: repo-auditor AS-38 detector implementation with focused fixtures.
EOF

python3 - "$REPO_ROOT" "$SELF_AUTHORED_REPO" "$NEGATIVE_SEARCH_REPO" "$STALE_DOWNSTREAM_REPO" "$OPERATOR_PAUSE_REPO" "$TRUE_CLOSURE_REPO" "$EXPLAINER_REPO" "$ORDINARY_NEXT_REPO" <<'PY'
import json
import subprocess
import sys

(
    repo_root,
    self_authored_repo,
    negative_search_repo,
    stale_downstream_repo,
    operator_pause_repo,
    true_closure_repo,
    explainer_repo,
    ordinary_next_repo,
) = sys.argv[1:9]


def run(repo):
    completed = subprocess.run(
        ["bash", f"{repo_root}/scripts/detect-as-self-authored-campaign-pause-authority.sh", repo],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    return json.loads(completed.stdout)


self_authored = run(self_authored_repo)
assert self_authored["ds_id"] == "AS-38", self_authored
assert self_authored["fired"] is True, self_authored
assert self_authored["signals"]["campaign_pause_authority_count"] == 1, self_authored
assert self_authored["signals"]["none_selected_disposition_count"] == 1, self_authored
assert self_authored["signals"]["self_authored_no_action_count"] == 1, self_authored

negative_search = run(negative_search_repo)
assert negative_search["fired"] is True, negative_search
assert negative_search["signals"]["negative_search_pause_authority_count"] == 1, negative_search

stale_downstream = run(stale_downstream_repo)
assert stale_downstream["fired"] is True, stale_downstream
assert stale_downstream["signals"]["stale_downstream_pause_authority_count"] == 1, stale_downstream

for repo in (operator_pause_repo, true_closure_repo, explainer_repo, ordinary_next_repo):
    payload = run(repo)
    assert payload["ds_id"] == "AS-38", payload
    assert payload["fired"] is False, payload
    assert payload["signals"]["campaign_pause_authority_count"] == 0, payload

operator_pause = run(operator_pause_repo)
assert operator_pause["signals"]["operator_approved_pause_count"] == 1, operator_pause

true_closure = run(true_closure_repo)
assert true_closure["signals"]["true_campaign_closure_count"] == 1, true_closure
PY

echo "Self-authored campaign pause authority detector test passed."
