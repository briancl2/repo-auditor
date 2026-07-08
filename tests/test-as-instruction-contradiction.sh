#!/usr/bin/env bash
# Verify AS-58 detects contradictory or self-invalidating instruction guidance:
#   - cross-surface "cited live while dead/dormant" (a skill cites a named
#     reference as live/canonical while another surface marks it dead), and
#   - within-surface "mandate and forbid the same action".
# It must stay silent on consistent instructions, described transitions
# (former-state prose), and dead/live cues that belong to different references.
# Read-only; targets are never modified.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# ── Positive classes (must fire) ─────────────────────────────────────────
POS_CITED_LIVE_DEAD="$TMPDIR/pos-cited-live-dead"
POS_MANDATE_FORBID="$TMPDIR/pos-mandate-forbid"
# ── Negative classes (must stay clean) ───────────────────────────────────
NEG_CONSISTENT="$TMPDIR/neg-consistent"
NEG_TRANSITION="$TMPDIR/neg-transition"
NEG_DISTINCT_TOKENS="$TMPDIR/neg-distinct-tokens"
NEG_CONDITIONAL="$TMPDIR/neg-conditional"

mkdir -p \
    "$POS_CITED_LIVE_DEAD/.agents/skills/memory" "$POS_CITED_LIVE_DEAD/docs" \
    "$POS_MANDATE_FORBID" \
    "$NEG_CONSISTENT/.agents/skills/memory" "$NEG_CONSISTENT/docs" \
    "$NEG_TRANSITION/docs" \
    "$NEG_DISTINCT_TOKENS/.agents/skills/memory" "$NEG_DISTINCT_TOKENS/docs" \
    "$NEG_CONDITIONAL"

# Positive: a skill cites PRINCIPLE_LEDGER as the live/canonical source of truth
# while a status doc records it as dead/dormant (the real BMA-shaped class).
cat > "$POS_CITED_LIVE_DEAD/.agents/skills/memory/SKILL.md" <<'EOF'
# Memory skill

Always consult the PRINCIPLE_LEDGER before acting; it is the canonical source of
truth and remains the live authority for governing principles in this repo.
EOF
cat > "$POS_CITED_LIVE_DEAD/docs/surface-status.md" <<'EOF'
# Surface status

PRINCIPLE_LEDGER is dead and has been dormant for roughly 8 weeks. It is archived
and no longer maintained.
EOF

# Positive: one surface both mandates and forbids the same action token.
cat > "$POS_MANDATE_FORBID/AGENTS.md" <<'EOF'
# AGENTS

You must always use `--no-verify` so commits stay fast.
Never use `--no-verify`; it bypasses the required pre-commit gates.
EOF

# Negative: skill and status doc agree the ledger is the live source of truth.
cat > "$NEG_CONSISTENT/.agents/skills/memory/SKILL.md" <<'EOF'
# Memory skill

Consult the PRINCIPLE_LEDGER; it is the canonical source of truth for principles.
EOF
cat > "$NEG_CONSISTENT/docs/surface-status.md" <<'EOF'
# Surface status

PRINCIPLE_LEDGER is the live, currently maintained authority for principles.
EOF

# Negative: a single surface describes a transition (former state), not a
# current contradiction.
cat > "$NEG_TRANSITION/docs/transition.md" <<'EOF'
# Transition

PRINCIPLE_LEDGER was formerly the canonical source of truth but is now dead and
archived. Use the new registry instead.
EOF

# Negative: dead cue and live cue belong to DIFFERENT reference tokens on the
# same line; clause analysis must not cross-contaminate them.
cat > "$NEG_DISTINCT_TOKENS/.agents/skills/memory/SKILL.md" <<'EOF'
# Memory skill

The PRINCIPLE_LEDGER is the canonical source of truth. Consult it and cite it.
EOF
cat > "$NEG_DISTINCT_TOKENS/docs/history.md" <<'EOF'
# History

The OLD_LEDGER was archived and is now dead; PRINCIPLE_LEDGER replaced it.
EOF

# Negative: conditional, non-absolute guidance is not a mandate/forbid pair.
cat > "$NEG_CONDITIONAL/AGENTS.md" <<'EOF'
# AGENTS

Run `make check` before every commit. Avoid `--no-verify` unless the operator
explicitly approves it for a documented exception.
EOF

python3 - "$REPO_ROOT" \
    "$POS_CITED_LIVE_DEAD" "$POS_MANDATE_FORBID" \
    "$NEG_CONSISTENT" "$NEG_TRANSITION" "$NEG_DISTINCT_TOKENS" "$NEG_CONDITIONAL" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root = Path(sys.argv[1])
(
    pos_cited_live_dead,
    pos_mandate_forbid,
    neg_consistent,
    neg_transition,
    neg_distinct_tokens,
    neg_conditional,
) = map(Path, sys.argv[2:8])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-instruction-contradiction.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


def assert_shape(result: dict) -> None:
    assert result["ds_id"] == "AS-58", result
    assert result["family"] == "AS", result
    assert result["name"] == "instruction-contradiction", result
    assert result["severity"] == "MEDIUM", result
    assert result["prevention_tier"] == "T2", result


# Positive classes fire with exactly one offender each.
cited = run(pos_cited_live_dead)
assert_shape(cited)
assert cited["fired"] is True, cited
assert cited["signals"]["instruction_contradiction_count"] == 1, cited
assert cited["signals"]["cited_live_while_dead_count"] == 1, cited
assert cited["signals"]["mandate_and_forbid_count"] == 0, cited

mandate = run(pos_mandate_forbid)
assert_shape(mandate)
assert mandate["fired"] is True, mandate
assert mandate["signals"]["instruction_contradiction_count"] == 1, mandate
assert mandate["signals"]["mandate_and_forbid_count"] == 1, mandate
assert mandate["signals"]["cited_live_while_dead_count"] == 0, mandate

# Negative classes stay clean.
for repo in (
    neg_consistent,
    neg_transition,
    neg_distinct_tokens,
    neg_conditional,
):
    result = run(repo)
    assert_shape(result)
    assert result["fired"] is False, result
    assert result["signals"]["instruction_contradiction_count"] == 0, result

# The distinct-token negative still recognizes both instruction surfaces; it just
# does not manufacture a contradiction across different reference names.
distinct = run(neg_distinct_tokens)
assert distinct["signals"]["instruction_surface_count"] == 2, distinct
PY

echo "PASS: AS-58 instruction-contradiction detector covered"
