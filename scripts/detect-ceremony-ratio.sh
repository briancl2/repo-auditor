#!/usr/bin/env bash
# detect-ceremony-ratio.sh — DS-29: Ceremony commit ratio
# Detects repos where ceremony commits (handoffs, status updates, FLYWHEEL updates)
# dominate over substantive commits (code, scripts, specs, research).
# Multi-signal: file path classification + diff stat size + per-repo baseline.
# Threshold (PROVISIONAL): >65% flags. Per-repo baseline recommended.
#
# Usage: bash scripts/detect-ceremony-ratio.sh [repo_path] [--commits N] [--threshold N] [--json]
# Exits 0 if healthy, 1 if ceremony ratio exceeds threshold, 2 if insufficient data.
#
# Stage 6 M3.2 (R-DS29, F3)
set -euo pipefail

REPO="${1:-.}"
COMMIT_COUNT=20
THRESHOLD=65
JSON_OUT=false

shift 2>/dev/null || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --commits) COMMIT_COUNT="$2"; shift 2 ;;
    --threshold) THRESHOLD="$2"; shift 2 ;;
    --json) JSON_OUT=true; shift ;;
    *) shift ;;
  esac
done

cd "$REPO"

# Verify git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if $JSON_OUT; then
    echo '{"ds":"DS-29","signal":"no-git","fires":false,"reason":"Not a git repo"}'
  else
    echo "DS-29: Not a git repository. Skipping."
  fi
  exit 2
fi

# Get recent commits
TOTAL=$(git log --oneline -"$COMMIT_COUNT" 2>/dev/null | wc -l | tr -d ' ')

if [ "$TOTAL" -lt 5 ]; then
  if $JSON_OUT; then
    echo '{"ds":"DS-29","signal":"insufficient-data","fires":false,"reason":"<5 commits"}'
  else
    echo "DS-29: Fewer than 5 commits. Skipping."
  fi
  exit 2
fi

# Ceremony file patterns (files that are ONLY process/tracking)
# These are generic patterns that work across repos with the operating model
is_ceremony_file() {
  local f="$1"
  case "$f" in
    docs/handoffs/*) return 0 ;;
    HANDOFF*) return 0 ;;
    FLYWHEEL.md|STATUS.md|ROADMAP.md) return 0 ;;
    work/*) return 0 ;;
    AGENTS.md) return 0 ;;
    .specify/memory/*) return 0 ;;
    LEARNINGS.md) return 0 ;;
    WARNING_LEDGER*) return 0 ;;
    OPERATING_MODEL_SCORECARD*) return 0 ;;
    *) return 1 ;;
  esac
}

# Substantive file patterns (files that are code/content)
is_substantive_file() {
  local f="$1"
  case "$f" in
    scripts/*.sh|scripts/*.py) return 0 ;;
    *.py|*.js|*.ts|*.go|*.rs|*.sh) return 0 ;;
    specs/*/spec.md|specs/*/plan.md|specs/*/tasks.md) return 0 ;;
    schemas/*) return 0 ;;
    tests/*) return 0 ;;
    Makefile|.github/*) return 0 ;;
    research/*) return 0 ;;
    .agents/skills/*/SKILL.md) return 0 ;;
    .agents/*.agent.md) return 0 ;;
    templates/*) return 0 ;;
    *) return 1 ;;
  esac
}

# Classify each commit using multi-signal
CEREMONY=0
SUBSTANTIVE=0
MIXED=0

while IFS= read -r sha; do
  [ -z "$sha" ] && continue

  # Signal 1: File path classification
  all_ceremony=true
  has_substantive=false
  file_count=0

  while IFS= read -r file; do
    [ -z "$file" ] && continue
    file_count=$((file_count + 1))

    if is_substantive_file "$file"; then
      has_substantive=true
      all_ceremony=false
    elif ! is_ceremony_file "$file"; then
      # Unknown file — not clearly ceremony
      all_ceremony=false
    fi
  done <<< "$(git diff-tree --no-commit-id --name-only -r "$sha" 2>/dev/null)"

  # Signal 2: Diff stat size (ceremony commits tend to be small)
  insertions=$(git diff-tree --no-commit-id --numstat -r "$sha" 2>/dev/null | awk '{s+=$1} END {print s+0}')
  deletions=$(git diff-tree --no-commit-id --numstat -r "$sha" 2>/dev/null | awk '{s+=$2} END {print s+0}')
  total_lines=$((insertions + deletions))

  # Classification logic:
  # - All files are ceremony AND diff < 200 lines → CEREMONY
  # - Has substantive file → SUBSTANTIVE
  # - Otherwise → MIXED (counted as ceremony-leaning)
  if [ "$file_count" -eq 0 ]; then
    # Merge commit or empty — skip
    continue
  elif $all_ceremony && [ "$total_lines" -lt 200 ]; then
    CEREMONY=$((CEREMONY + 1))
  elif $has_substantive; then
    SUBSTANTIVE=$((SUBSTANTIVE + 1))
  elif $all_ceremony; then
    # Large ceremony commit (>200 lines) — still ceremony but big
    CEREMONY=$((CEREMONY + 1))
  else
    MIXED=$((MIXED + 1))
  fi
done <<< "$(git log --format='%H' -"$COMMIT_COUNT" 2>/dev/null)"

CLASSIFIED=$((CEREMONY + SUBSTANTIVE + MIXED))
if [ "$CLASSIFIED" -eq 0 ]; then
  if $JSON_OUT; then
    echo '{"ds":"DS-29","signal":"no-classified","fires":false,"reason":"No commits classified"}'
  else
    echo "DS-29: No commits could be classified. Skipping."
  fi
  exit 2
fi

# Ceremony ratio: ceremony + mixed (ceremony-leaning) vs total
ceremony_total=$((CEREMONY + MIXED))
ceremony_pct=$((ceremony_total * 100 / CLASSIFIED))

fires=false
if [ "$ceremony_pct" -gt "$THRESHOLD" ]; then
  fires=true
fi

if $JSON_OUT; then
  echo "{\"ds\":\"DS-29\",\"signal\":\"ceremony-ratio\",\"fires\":$fires,\"ceremony\":$CEREMONY,\"substantive\":$SUBSTANTIVE,\"mixed\":$MIXED,\"classified\":$CLASSIFIED,\"ceremony_pct\":$ceremony_pct,\"threshold\":$THRESHOLD,\"commits_analyzed\":$COMMIT_COUNT}"
else
  echo "DS-29: Ceremony Commit Ratio"
  echo "  Commits analyzed: $CLASSIFIED (of $COMMIT_COUNT requested)"
  echo "  Ceremony: $CEREMONY  Substantive: $SUBSTANTIVE  Mixed: $MIXED"
  echo "  Ceremony ratio: ${ceremony_pct}% (threshold: ${THRESHOLD}%)"
  if $fires; then
    echo "  FIRES: Ceremony ratio ${ceremony_pct}% exceeds ${THRESHOLD}%"
    exit 1
  else
    echo "  OK: Ceremony ratio ${ceremony_pct}% within ${THRESHOLD}% threshold"
    exit 0
  fi
fi

if $fires; then
  exit 1
else
  exit 0
fi
