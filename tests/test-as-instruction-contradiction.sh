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
NEG_ARCHIVE_SURFACE="$TMPDIR/neg-archive-surface"
NEG_CLAUSE_SCOPED="$TMPDIR/neg-clause-scoped"
NEG_RECOMMENDED_NOT_GATED="$TMPDIR/neg-recommended-not-gated"
NEG_GARBAGE_TOKEN="$TMPDIR/neg-garbage-token"
NEG_HISTORICAL_LEARNING_ROW="$TMPDIR/neg-historical-learning-row"

mkdir -p \
    "$POS_CITED_LIVE_DEAD/.agents/skills/memory" "$POS_CITED_LIVE_DEAD/docs" \
    "$POS_MANDATE_FORBID" \
    "$NEG_CONSISTENT/.agents/skills/memory" "$NEG_CONSISTENT/docs" \
    "$NEG_TRANSITION/docs" \
    "$NEG_DISTINCT_TOKENS/.agents/skills/memory" "$NEG_DISTINCT_TOKENS/docs" \
    "$NEG_CONDITIONAL" \
    "$NEG_ARCHIVE_SURFACE/docs/archive/principle-ledger" \
    "$NEG_ARCHIVE_SURFACE/docs" \
    "$NEG_CLAUSE_SCOPED" \
    "$NEG_RECOMMENDED_NOT_GATED/.specify/memory" \
    "$NEG_GARBAGE_TOKEN" \
    "$NEG_HISTORICAL_LEARNING_ROW"

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

# Negative: historical/archive surfaces are receipts, not live instruction
# surfaces, so an archived live citation must not contradict a live deprecation.
cat > "$NEG_ARCHIVE_SURFACE/LEARNINGS.md" <<'EOF'
# Learnings

PRINCIPLE_LEDGER is dead and no longer maintained after the archive migration.
EOF
cat > "$NEG_ARCHIVE_SURFACE/docs/archive/principle-ledger/README.md" <<'EOF'
# Archived principle ledger

PRINCIPLE_LEDGER remains the canonical source of truth inside this frozen archive.
EOF

# Negative: mandate/forbid cues in separate clauses on the same physical line
# must not color every token in the line.
cat > "$NEG_CLAUSE_SCOPED/AGENTS.md" <<'EOF'
# AGENTS

If launch is approved, name the expected shape (`full-wave`, `compact-wave`);
an inspect-only heartbeat must not write, route, retry, dispatch, poll, or mutate.
Unless default proof exists, do not omit explicit `--provider`.
EOF

# Negative: recommended, not gated guidance is intentionally non-absolute.
cat > "$NEG_RECOMMENDED_NOT_GATED/.specify/memory/constitution.md" <<'EOF'
# Constitution

`make review` should run before significant commits. `--no-verify` is NEVER
permitted.

> Note: `make review` is recommended, not gated. It does not block commits.
The 3 hard gates are: `make work`, `make check`, and `make work-close`.
EOF

# Negative: punctuation/stop-word fragments are not actionable mandate tokens.
cat > "$NEG_GARBAGE_TOKEN/AGENTS.md" <<'EOF'
# AGENTS

You must always record `,,, and` in the prose separator field.
Never record `,,, and`; use a real action token instead.
EOF

# Negative: LEARNINGS table rows are historical log evidence, not current
# instruction mandates; dotted stage IDs are also not action tokens.
cat > "$NEG_HISTORICAL_LEARNING_ROW/LEARNINGS.md" <<'EOF'
# Learnings

| # | Learning | Source |
|---|---|---|
| L999 | **Stage `14.2.1` must validate runtime claims separately; it never tested runtime equivalence.** With --max-autopilot-continues 5, the advisor consumed context and never reached synthesis. | Historical RCA only. |
EOF

python3 - "$REPO_ROOT" \
    "$POS_CITED_LIVE_DEAD" "$POS_MANDATE_FORBID" \
    "$NEG_CONSISTENT" "$NEG_TRANSITION" "$NEG_DISTINCT_TOKENS" "$NEG_CONDITIONAL" \
    "$NEG_ARCHIVE_SURFACE" "$NEG_CLAUSE_SCOPED" "$NEG_RECOMMENDED_NOT_GATED" \
    "$NEG_GARBAGE_TOKEN" "$NEG_HISTORICAL_LEARNING_ROW" <<'PY'
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
    neg_archive_surface,
    neg_clause_scoped,
    neg_recommended_not_gated,
    neg_garbage_token,
    neg_historical_learning_row,
) = map(Path, sys.argv[2:13])


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
    neg_archive_surface,
    neg_clause_scoped,
    neg_recommended_not_gated,
    neg_garbage_token,
    neg_historical_learning_row,
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
