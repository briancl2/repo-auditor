#!/usr/bin/env bash
# detect-capability-drift.sh — Compare tools on disk vs documented tools.
# Usage: bash scripts/detect-capability-drift.sh [repo_path] [--threshold N] [--json]
#
# Exits non-zero if drift exceeds threshold (default 20%).
# Generic: discovers tracking files dynamically, not hardcoded to any structure.

set -euo pipefail

REPO="${1:-.}"
THRESHOLD=20
JSON_OUT=false

shift 2>/dev/null || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --threshold) THRESHOLD="$2"; shift 2 ;;
    --json) JSON_OUT=true; shift ;;
    *) shift ;;
  esac
done

cd "$REPO"

# ──────────────────────────────────────────────────────────────────────
# Step 1: Find all tools on disk
# ──────────────────────────────────────────────────────────────────────
TOOLS_ON_DISK=()

# Scripts in scripts/ or tools/ directories
while IFS= read -r f; do
  TOOLS_ON_DISK+=("$f")
done < <(find . \( -path ./node_modules -o -path ./.git -o -path ./vendor -o -path ./targets \) -prune -o \
  \( -name '*.sh' -o -name '*.py' \) -print 2>/dev/null \
  | grep -iE '(scripts|tools)/' \
  | sed 's|^\./||' \
  | sort -u)

# Skill SKILL.md files
while IFS= read -r f; do
  TOOLS_ON_DISK+=("$f")
done < <(find . \( -path ./node_modules -o -path ./.git -o -path ./vendor -o -path ./targets \) -prune -o \
  -path '*/skills/*/SKILL.md' -print 2>/dev/null \
  | sed 's|^\./||' \
  | sort -u)

# Agent .agent.md files
while IFS= read -r f; do
  TOOLS_ON_DISK+=("$f")
done < <(find . \( -path ./node_modules -o -path ./.git -o -path ./vendor -o -path ./targets \) -prune -o \
  -name '*.agent.md' -print 2>/dev/null \
  | sed 's|^\./||' \
  | sort -u)

TOTAL_DISK=${#TOOLS_ON_DISK[@]}

if [[ $TOTAL_DISK -eq 0 ]]; then
  echo "No tools found on disk in $REPO"
  exit 0
fi

# ──────────────────────────────────────────────────────────────────────
# Step 2: Find tracking files (files that reference scripts/tools/skills)
# ──────────────────────────────────────────────────────────────────────
TRACKING_FILES=()

# Candidate tracking files: AGENTS.md, README.md, STATUS.md, CONTRIBUTING.md, Makefile, etc.
CANDIDATES=(
  "AGENTS.md" "README.md" "STATUS.md" "CONTRIBUTING.md" "RUNBOOK.md"
  "Makefile" "makefile" "GNUmakefile"
  "docs/README.md" "docs/AGENTS.md"
)

# Also look for files matching *INVENTORY* or *REGISTRY*
while IFS= read -r f; do
  CANDIDATES+=("$f")
done < <(find . -maxdepth 3 \( -path ./node_modules -o -path ./.git -o -path ./vendor -o -path ./targets \) -prune -o \
  \( -iname '*inventory*' -o -iname '*registry*' -o -iname '*catalog*' -o -iname '*catalogue*' \) \
  -type f -print 2>/dev/null \
  | sed 's|^\./||')

# Filter candidates to those that exist and reference scripts/tools/skills
for candidate in "${CANDIDATES[@]}"; do
  if [[ -f "$candidate" ]]; then
    # Check if it references tool-like paths
    if grep -qiE '(scripts/|tools/|\.agents/skills/|\.github/skills/|\.github/agents/|\.agent\.md|SKILL\.md)' "$candidate" 2>/dev/null; then
      TRACKING_FILES+=("$candidate")
    fi
  fi
done

# Deduplicate
TRACKING_FILES=($(printf '%s\n' "${TRACKING_FILES[@]}" | sort -u))

if [[ ${#TRACKING_FILES[@]} -eq 0 ]]; then
  echo "WARNING: No tracking files found that reference scripts/tools/skills."
  echo "All $TOTAL_DISK tools on disk are untracked."
  if $JSON_OUT; then
    echo "{\"total_disk\": $TOTAL_DISK, \"total_tracked\": 0, \"drift_count\": $TOTAL_DISK, \"drift_pct\": 100, \"threshold\": $THRESHOLD, \"pass\": false, \"tracking_files\": [], \"undocumented\": $(printf '%s\n' "${TOOLS_ON_DISK[@]}" | jq -R . | jq -s .)}"
  fi
  exit 1
fi

# ──────────────────────────────────────────────────────────────────────
# Step 3: Check each tool against tracking files
# ──────────────────────────────────────────────────────────────────────
TRACKED=()
UNTRACKED=()

# Build a temp file with all tracking content for fast search
TRACKING_TMP=$(mktemp)
trap 'rm -f "$TRACKING_TMP"' EXIT
for tf in "${TRACKING_FILES[@]}"; do
  cat "$tf" 2>/dev/null >> "$TRACKING_TMP"
  echo "" >> "$TRACKING_TMP"
done

for tool in "${TOOLS_ON_DISK[@]}"; do
  # Extract just the filename for matching (e.g., "score-output-quality.sh")
  basename_tool=$(basename "$tool")
  # Also try the relative path without leading ./
  relpath="${tool#./}"

  # For skill SKILL.md files, also match by skill name (e.g., "building-skill")
  skill_name=""
  if [[ "$basename_tool" == "SKILL.md" ]]; then
    # Extract skill name from path like .agents/skills/building-skill/SKILL.md
    skill_name=$(echo "$relpath" | sed -n 's|.*skills/\([^/]*\)/SKILL\.md|\1|p')
  fi

  # For scripts inside a skill directory, check if the parent skill is documented
  parent_skill=""
  if echo "$relpath" | grep -qE 'skills/[^/]+/scripts/'; then
    parent_skill=$(echo "$relpath" | sed -n 's|.*skills/\([^/]*\)/scripts/.*|\1|p')
  fi

  # For agent files, also match by agent name (e.g., "b5a-agent-fixer")
  agent_name=""
  if [[ "$basename_tool" == *.agent.md ]]; then
    agent_name="${basename_tool%.agent.md}"
  fi

  # Check if the basename, relative path, skill name, parent skill, or agent name appears in tracking files
  found=false
  if grep -qF "$basename_tool" "$TRACKING_TMP" 2>/dev/null; then
    found=true
  elif grep -qF "$relpath" "$TRACKING_TMP" 2>/dev/null; then
    found=true
  elif [[ -n "$skill_name" ]] && grep -qF "$skill_name" "$TRACKING_TMP" 2>/dev/null; then
    found=true
  elif [[ -n "$parent_skill" ]] && grep -qF "$parent_skill" "$TRACKING_TMP" 2>/dev/null; then
    # Scripts inside a documented skill are considered tracked via the skill
    found=true
  elif [[ -n "$agent_name" ]] && grep -qF "$agent_name" "$TRACKING_TMP" 2>/dev/null; then
    found=true
  fi

  # Handle range/bracket notation: ground-truth-t1.sh matches ground-truth-t[1-7].sh
  if ! $found; then
    # Strip trailing digits before extension to get stem
    stem_no_ext=$(echo "${basename_tool%.*}" | sed 's/[0-9]*$//')
    if [[ -n "$stem_no_ext" ]] && [[ "$stem_no_ext" != "${basename_tool%.*}" ]]; then
      # Check that a bracket-range reference exists for this stem prefix
      if grep -qE "${stem_no_ext}.*\[.*\]" "$TRACKING_TMP" 2>/dev/null; then
        found=true
      fi
    fi
  fi

  if $found; then
    TRACKED+=("$tool")
  else
    UNTRACKED+=("$tool")
  fi
done

DRIFT_COUNT=${#UNTRACKED[@]}
TRACKED_COUNT=${#TRACKED[@]}

if [[ $TOTAL_DISK -gt 0 ]]; then
  DRIFT_PCT=$(( DRIFT_COUNT * 100 / TOTAL_DISK ))
else
  DRIFT_PCT=0
fi

PASS=true
if [[ $DRIFT_PCT -gt $THRESHOLD ]]; then
  PASS=false
fi

# ──────────────────────────────────────────────────────────────────────
# Output
# ──────────────────────────────────────────────────────────────────────
if $JSON_OUT; then
  UNTRACKED_JSON=$(printf '%s\n' "${UNTRACKED[@]}" | jq -R . | jq -s . 2>/dev/null || echo "[]")
  TRACKING_JSON=$(printf '%s\n' "${TRACKING_FILES[@]}" | jq -R . | jq -s . 2>/dev/null || echo "[]")
  cat <<EOF
{
  "total_disk": $TOTAL_DISK,
  "total_tracked": $TRACKED_COUNT,
  "drift_count": $DRIFT_COUNT,
  "drift_pct": $DRIFT_PCT,
  "threshold": $THRESHOLD,
  "pass": $PASS,
  "tracking_files": $TRACKING_JSON,
  "undocumented": $UNTRACKED_JSON
}
EOF
else
  echo "=== Capability Drift Report ==="
  echo ""
  echo "Repo:           $(basename "$(pwd)")"
  echo "Tools on disk:  $TOTAL_DISK"
  echo "Tools tracked:  $TRACKED_COUNT"
  echo "Undocumented:   $DRIFT_COUNT ($DRIFT_PCT%)"
  echo "Threshold:      $THRESHOLD%"
  echo "Tracking files: ${TRACKING_FILES[*]}"
  echo ""

  if [[ $DRIFT_COUNT -gt 0 ]]; then
    echo "--- Undocumented tools ---"
    for u in "${UNTRACKED[@]}"; do
      echo "  ✗ $u"
    done
    echo ""
  fi

  if $PASS; then
    echo "RESULT: PASS (drift $DRIFT_PCT% ≤ threshold $THRESHOLD%)"
  else
    echo "RESULT: FAIL (drift $DRIFT_PCT% > threshold $THRESHOLD%)"
  fi
fi

if ! $PASS; then
  exit 1
fi
