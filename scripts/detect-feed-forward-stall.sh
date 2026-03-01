#!/usr/bin/env bash
# detect-feed-forward-stall.sh — DS-32: Feed-Forward Stall
# Detects repos where learnings are extracted but no structural changes follow.
# LEARNINGS.md grows but scripts/constitution/agents unchanged for N sessions.
#
# Usage: bash scripts/detect-feed-forward-stall.sh [repo_path] [--sessions N] [--json]
# Exits 0 if healthy (learnings produce structural changes), 1 if stalled, 2 if insufficient data.
#
# Stage 8 M2 item 8.9 (v129 definitions, v130 implementation)
set -euo pipefail

REPO="${1:-.}"
SESSIONS=3
JSON_OUT=false

shift 2>/dev/null || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sessions) SESSIONS="$2"; shift 2 ;;
    --json) JSON_OUT=true; shift ;;
    *) shift ;;
  esac
done

cd "$REPO"

# Check for LEARNINGS.md
if [ ! -f LEARNINGS.md ]; then
  if $JSON_OUT; then
    echo '{"ds":"DS-32","signal":"no-learnings","fires":false,"reason":"No LEARNINGS.md found"}'
  else
    echo "DS-32: No LEARNINGS.md found. Skipping."
  fi
  exit 2
fi

# Get recent commits (N sessions approximated by N*5 commits as heuristic)
COMMIT_WINDOW=$((SESSIONS * 5))

# Count L-number additions in recent commits
LEARNING_ADDS=$(git log --oneline -"$COMMIT_WINDOW" --diff-filter=M -- LEARNINGS.md 2>/dev/null | wc -l | tr -d ' ')

# Count structural file changes in the same window
# Structural = scripts/, .specify/, .agents/, .github/agents/, Makefile, schemas/
STRUCTURAL_CHANGES=$(git log --oneline -"$COMMIT_WINDOW" --diff-filter=AMRD -- \
  'scripts/*.sh' 'scripts/*.py' \
  '.specify/' '.agents/' '.github/agents/' \
  'Makefile' 'schemas/' 2>/dev/null | wc -l | tr -d ' ')

# Also check for L-number growth specifically (more precise signal)
# Count distinct L-numbers added in recent diffs
NEW_LNUMBERS=$(git log -"$COMMIT_WINDOW" -p -- LEARNINGS.md 2>/dev/null | \
  grep -E '^\+\| L[0-9]+' 2>/dev/null | \
  grep -oE 'L[0-9]+' 2>/dev/null | \
  sort -u | wc -l | tr -d ' ')

# Fire condition: learnings growing but 0 structural changes
FIRES=false
REASON="healthy"
if [ "$NEW_LNUMBERS" -gt 0 ] && [ "$STRUCTURAL_CHANGES" -eq 0 ]; then
  FIRES=true
  REASON="$NEW_LNUMBERS new L-numbers in last $COMMIT_WINDOW commits but 0 structural file changes"
elif [ "$LEARNING_ADDS" -gt 0 ] && [ "$STRUCTURAL_CHANGES" -eq 0 ]; then
  FIRES=true
  REASON="$LEARNING_ADDS LEARNINGS.md modifications in last $COMMIT_WINDOW commits but 0 structural file changes"
else
  REASON="$NEW_LNUMBERS new L-numbers, $STRUCTURAL_CHANGES structural changes in last $COMMIT_WINDOW commits"
fi

if $JSON_OUT; then
  cat <<JSON
{"ds":"DS-32","signal":"feed-forward-stall","fires":$FIRES,"new_lnumbers":$NEW_LNUMBERS,"structural_changes":$STRUCTURAL_CHANGES,"learning_commits":$LEARNING_ADDS,"window_commits":$COMMIT_WINDOW,"sessions":$SESSIONS,"reason":"$REASON"}
JSON
else
  if $FIRES; then
    echo "DS-32 FIRES: Feed-forward stall — $REASON"
  else
    echo "DS-32 OK: $REASON"
  fi
fi

if $FIRES; then
  exit 1
else
  exit 0
fi
