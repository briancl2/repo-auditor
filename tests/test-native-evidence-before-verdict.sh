#!/usr/bin/env bash
# Verify AS-57 detects docs-readback-only adoption/readiness/fallback verdicts
# that lack a native attempt or a concrete owner-surface blocker, and preserves
# the negative cases from repo-agent-core
# docs/native-evidence-before-verdict-contract.md.
# Read-only; targets are never modified.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# ── Positive classes (must fire) ─────────────────────────────────────────
POS_DOCS_READBACK="$TMPDIR/pos-docs-readback"
POS_LOCAL_DOCTOR="$TMPDIR/pos-local-doctor"
POS_NEGATIVE_VERDICT="$TMPDIR/pos-negative-verdict"
POS_KEYWORD_STUFFING="$TMPDIR/pos-keyword-stuffing"
# ── Negative classes (must stay clean) ───────────────────────────────────
NEG_ORIENTATION="$TMPDIR/neg-orientation"
NEG_CITATION_SUPPORTS="$TMPDIR/neg-citation-supports"
NEG_OWNER_BLOCKER="$TMPDIR/neg-owner-blocker"
NEG_CONTRACT_POINTER="$TMPDIR/neg-contract-pointer"

mkdir -p \
    "$POS_DOCS_READBACK/docs" "$POS_LOCAL_DOCTOR/docs" \
    "$POS_NEGATIVE_VERDICT/docs" "$POS_KEYWORD_STUFFING/docs" \
    "$NEG_ORIENTATION/docs" "$NEG_CITATION_SUPPORTS/docs" \
    "$NEG_OWNER_BLOCKER/docs" "$NEG_CONTRACT_POINTER/docs"

cat > "$POS_DOCS_READBACK/docs/verdict.md" <<'EOF'
# GBrain adoption readback

Based on reading the upstream README and AGENTS.md, GBrain is production-ready
and we should adopt it as the default memory backend now.
The local doctor output is green and the retained validation receipt passed.
No native GBrain command was executed, and this adoption verdict rests on the
docs and model summary alone.
EOF

cat > "$POS_LOCAL_DOCTOR/docs/verdict.md" <<'EOF'
# Upstream tool readiness

The local doctor output is green and the retained validation receipt passed,
so the upstream tool is GA and adoption-ready for production.
No native command was invoked against the real system.
EOF

cat > "$POS_NEGATIVE_VERDICT/docs/verdict.md" <<'EOF'
# Native capability judgment

This upstream tool is not production-ready and a fallback is required.
We base this verdict on the model summary and prompt contract alone.
We did not run the native setup and there is no blocker to report.
EOF

cat > "$POS_KEYWORD_STUFFING/docs/verdict.md" <<'EOF'
# Native adoption review

We reviewed the README, AGENTS.md, and INSTALL_FOR_AGENTS install docs, and the
native setup and native run commands, and conclude the system is adoption-ready
for production. We did not actually run any native command.
EOF

cat > "$NEG_ORIENTATION/docs/orient.md" <<'EOF'
# Upstream native model orientation

This document orients readers to the upstream native model and the required
record fields. Reading the README and AGENTS.md is necessary but not sufficient.
No adoption, readiness, or fallback verdict is made here.
EOF

cat > "$NEG_CITATION_SUPPORTS/docs/cite.md" <<'EOF'
# Upstream capability notes

Per the upstream README, the native tool supports SSO and audit logging.
We cite these docs only to support our understanding of the native model;
we make no adoption or readiness decision and defer any verdict to a future
native attempt.
EOF

cat > "$NEG_OWNER_BLOCKER/docs/blocker.md" <<'EOF'
# Native adoption blocker

Based on the upstream docs, this native tool looks adoptable and close to
production-ready. But we stopped before the native run because running it needs
unauthorized production access; a blocker was filed to the owner repo issue.
EOF

cat > "$NEG_CONTRACT_POINTER/docs/pointer.md" <<'EOF'
# Native evidence contract pointer

This repository follows the repo-agent-core native-evidence-before-verdict
contract. See docs/native-evidence-before-verdict-contract.md for the required
record fields such as component_identity and native_attempt_or_blocker.
EOF

python3 - "$REPO_ROOT" \
    "$POS_DOCS_READBACK" "$POS_LOCAL_DOCTOR" "$POS_NEGATIVE_VERDICT" "$POS_KEYWORD_STUFFING" \
    "$NEG_ORIENTATION" "$NEG_CITATION_SUPPORTS" "$NEG_OWNER_BLOCKER" "$NEG_CONTRACT_POINTER" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root = Path(sys.argv[1])
(
    pos_docs_readback,
    pos_local_doctor,
    pos_negative_verdict,
    pos_keyword_stuffing,
    neg_orientation,
    neg_citation_supports,
    neg_owner_blocker,
    neg_contract_pointer,
) = map(Path, sys.argv[2:10])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-native-evidence-before-verdict.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


def assert_shape(result: dict) -> None:
    assert result["ds_id"] == "AS-57", result
    assert result["family"] == "AS", result
    assert result["name"] == "native-evidence-before-verdict", result
    assert result["severity"] == "HIGH", result
    assert (
        result["signals"]["contract_ref"]
        == "repo-agent-core/docs/native-evidence-before-verdict-contract.md"
    ), result


# Positive classes fire with exactly one offender surface each.
for repo in (
    pos_docs_readback,
    pos_local_doctor,
    pos_negative_verdict,
    pos_keyword_stuffing,
):
    result = run(repo)
    assert_shape(result)
    assert result["fired"] is True, result
    assert result["signals"]["native_evidence_before_verdict_count"] == 1, result

# Negative classes stay clean.
for repo in (
    neg_orientation,
    neg_citation_supports,
    neg_owner_blocker,
    neg_contract_pointer,
):
    result = run(repo)
    assert_shape(result)
    assert result["fired"] is False, result
    assert result["signals"]["native_evidence_before_verdict_count"] == 0, result

# The docs-only orientation surface is still recognized as a verdict-free surface
# (context present, no verdict), not merely skipped.
orientation = run(neg_orientation)
assert orientation["signals"]["verdict_surface_count"] == 0, orientation

# The owner-blocker surface has a verdict but is grounded by the blocker.
blocker = run(neg_owner_blocker)
assert blocker["signals"]["verdict_surface_count"] == 1, blocker
assert blocker["signals"]["native_attempt_or_blocker_surface_count"] == 1, blocker
PY

echo "PASS: AS-57 native-evidence-before-verdict detector covered"
