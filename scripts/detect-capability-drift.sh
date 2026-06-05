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

SCOPE_VERSION="capability-drift-classified-v1"

classify_scope() {
  local relpath="$1"
  local lower
  lower=$(printf '%s' "$relpath" | tr '[:upper:]' '[:lower:]')

  case "$lower" in
    work/*|runs/*|research/evidence/*|targets/*|*/.target-snapshot/*|*clean-head-snapshot*|*audit-snapshot*)
      printf '%s\n' "retained"
      return
      ;;
    tests/fixtures/*|fixtures/*|*/fixtures/*|examples/*|*/examples/*|example/*|*/example/*|demo/*|*/demo/*)
      printf '%s\n' "test_fixture"
      return
      ;;
    archive/*|*/archive/*|archives/*|*/archives/*|archived/*|*/archived/*)
      printf '%s\n' "archive"
      return
      ;;
    node_modules/*|*/node_modules/*|vendor/*|*/vendor/*|.venv*/*|*/.venv*/*|venv/*|*/venv/*|.tox/*|*/.tox/*|__pycache__/*|*/__pycache__/*|.mypy_cache/*|*/.mypy_cache/*|.pytest_cache/*|*/.pytest_cache/*|.eggs/*|*/.eggs/*|build/*|*/build/*|dist/*|*/dist/*|site-packages/*|*/site-packages/*)
      printf '%s\n' "generated"
      return
      ;;
  esac

  printf '%s\n' "live"
}

find_tool_candidates() {
  find . -path ./.git -prune -o "$@" -print 2>/dev/null
}

canonical_tool_identity() {
  local relpath="$1"
  relpath="${relpath#./}"
  case "$relpath" in
    .github/skills/*)
      printf '%s\n' ".agents/skills/${relpath#.github/skills/}"
      ;;
    *)
      printf '%s\n' "$relpath"
      ;;
  esac
}

dedupe_tool_candidates() {
  local deduped_tmp
  if [[ ${#ALL_TOOL_CANDIDATES[@]} -eq 0 ]]; then
    return
  fi
  deduped_tmp=$(mktemp)
  printf '%s\n' "${ALL_TOOL_CANDIDATES[@]}" \
    | while IFS= read -r f; do
        [[ -n "$f" ]] || continue
        canonical_tool_identity "$f"
      done \
    | sort -u > "$deduped_tmp"

  ALL_TOOL_CANDIDATES=()
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    ALL_TOOL_CANDIDATES+=("$f")
  done < "$deduped_tmp"
  rm -f "$deduped_tmp"
}

json_array_from_name() {
  local name="$1"
  local count
  eval "count=\${#${name}[@]}"
  if [[ "$count" -eq 0 ]]; then
    printf '[]\n'
    return
  fi
  eval "printf '%s\\n' \"\${${name}[@]}\"" | jq -R . | jq -s . 2>/dev/null || printf '[]\n'
}

emit_json_report() {
  local total_disk="$1"
  local tracked_count="$2"
  local drift_count="$3"
  local drift_pct="$4"
  local pass_value="$5"
  local tracking_json="$6"
  local undocumented_json="$7"
  local live_json="$8"
  local retained_json="$9"
  local archive_json="${10}"
  local test_fixture_json="${11}"
  local generated_json="${12}"

  cat <<EOF
{
  "scope_version": "$SCOPE_VERSION",
  "total_disk": $total_disk,
  "total_tracked": $tracked_count,
  "drift_count": $drift_count,
  "drift_pct": $drift_pct,
  "threshold": $THRESHOLD,
  "pass": $pass_value,
  "tracking_files": $tracking_json,
  "undocumented": $undocumented_json,
  "scope_counts": {
    "live": ${#TOOLS_ON_DISK[@]},
    "retained": ${#RETAINED_TOOLS[@]},
    "archive": ${#ARCHIVE_TOOLS[@]},
    "test_fixture": ${#TEST_FIXTURE_TOOLS[@]},
    "generated": ${#GENERATED_TOOLS[@]}
  },
  "scope_paths": {
    "live": $live_json,
    "retained": $retained_json,
    "archive": $archive_json,
    "test_fixture": $test_fixture_json,
    "generated": $generated_json
  }
}
EOF
}

# ──────────────────────────────────────────────────────────────────────
# Step 1: Find and classify all tool-like paths on disk
# ──────────────────────────────────────────────────────────────────────
ALL_TOOL_CANDIDATES=()
TOOLS_ON_DISK=()
RETAINED_TOOLS=()
ARCHIVE_TOOLS=()
TEST_FIXTURE_TOOLS=()
GENERATED_TOOLS=()

# Scripts in scripts/ or tools/ directories
while IFS= read -r f; do
  ALL_TOOL_CANDIDATES+=("$f")
done < <(find_tool_candidates \
  \( -name '*.sh' -o -name '*.py' \) -print 2>/dev/null \
  | grep -iE '(scripts|tools)/' \
  | sed 's|^\./||' \
  | sort -u)

# Skill SKILL.md files
while IFS= read -r f; do
  ALL_TOOL_CANDIDATES+=("$f")
done < <(find_tool_candidates \
  -path '*/skills/*/SKILL.md' -print 2>/dev/null \
  | sed 's|^\./||' \
  | sort -u)

# Skill reference prompt/material files
while IFS= read -r f; do
  ALL_TOOL_CANDIDATES+=("$f")
done < <(find_tool_candidates \
  -path '*/skills/*/references/*.md' -print 2>/dev/null \
  | sed 's|^\./||' \
  | sort -u)

# GitHub skills mirrors are often symlinks to .agents/skills. Follow only that
# bounded mirror and canonicalize the resulting paths so mirrors do not double
# count or create duplicate drift.
if [[ -e ".github/skills" ]]; then
  while IFS= read -r f; do
    ALL_TOOL_CANDIDATES+=("$f")
  done < <(find -L .github/skills \
    \( -name 'SKILL.md' -o -path '*/scripts/*.sh' -o -path '*/scripts/*.py' -o -path '*/references/*.md' \) \
    -print 2>/dev/null \
    | sed 's|^\./||' \
    | sort -u)
fi

# Agent .agent.md files
while IFS= read -r f; do
  ALL_TOOL_CANDIDATES+=("$f")
done < <(find_tool_candidates \
  -name '*.agent.md' -print 2>/dev/null \
  | sed 's|^\./||' \
  | sort -u)

dedupe_tool_candidates

if [[ ${#ALL_TOOL_CANDIDATES[@]} -gt 0 ]]; then
  while IFS= read -r tool; do
    [[ -n "$tool" ]] || continue
    scope=$(classify_scope "$tool")
    case "$scope" in
      live) TOOLS_ON_DISK+=("$tool") ;;
      retained) RETAINED_TOOLS+=("$tool") ;;
      archive) ARCHIVE_TOOLS+=("$tool") ;;
      test_fixture) TEST_FIXTURE_TOOLS+=("$tool") ;;
      generated) GENERATED_TOOLS+=("$tool") ;;
    esac
  done < <(printf '%s\n' "${ALL_TOOL_CANDIDATES[@]}" | sort -u)
fi

TOTAL_DISK=${#TOOLS_ON_DISK[@]}

if [[ $TOTAL_DISK -eq 0 ]]; then
  if $JSON_OUT; then
    TRACKING_JSON="[]"
    UNTRACKED_JSON="[]"
    LIVE_JSON=$(json_array_from_name TOOLS_ON_DISK)
    RETAINED_JSON=$(json_array_from_name RETAINED_TOOLS)
    ARCHIVE_JSON=$(json_array_from_name ARCHIVE_TOOLS)
    TEST_FIXTURE_JSON=$(json_array_from_name TEST_FIXTURE_TOOLS)
    GENERATED_JSON=$(json_array_from_name GENERATED_TOOLS)
    emit_json_report 0 0 0 0 true "$TRACKING_JSON" "$UNTRACKED_JSON" "$LIVE_JSON" "$RETAINED_JSON" "$ARCHIVE_JSON" "$TEST_FIXTURE_JSON" "$GENERATED_JSON"
  else
    echo "No live tools found on disk in $REPO"
    echo "Scope counts: live=0 retained=${#RETAINED_TOOLS[@]} archive=${#ARCHIVE_TOOLS[@]} test_fixture=${#TEST_FIXTURE_TOOLS[@]} generated=${#GENERATED_TOOLS[@]}"
  fi
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
  if [[ "$(classify_scope "$f")" == "live" ]]; then
    CANDIDATES+=("$f")
  fi
done < <(find . -maxdepth 3 -path ./.git -prune -o \
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
  echo "All $TOTAL_DISK live tools on disk are untracked."
  if $JSON_OUT; then
    TRACKING_JSON="[]"
    UNTRACKED_JSON=$(json_array_from_name TOOLS_ON_DISK)
    LIVE_JSON=$(json_array_from_name TOOLS_ON_DISK)
    RETAINED_JSON=$(json_array_from_name RETAINED_TOOLS)
    ARCHIVE_JSON=$(json_array_from_name ARCHIVE_TOOLS)
    TEST_FIXTURE_JSON=$(json_array_from_name TEST_FIXTURE_TOOLS)
    GENERATED_JSON=$(json_array_from_name GENERATED_TOOLS)
    emit_json_report "$TOTAL_DISK" 0 "$TOTAL_DISK" 100 false "$TRACKING_JSON" "$UNTRACKED_JSON" "$LIVE_JSON" "$RETAINED_JSON" "$ARCHIVE_JSON" "$TEST_FIXTURE_JSON" "$GENERATED_JSON"
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

  # For scripts/references inside a skill directory, check if the parent skill is documented
  parent_skill=""
  if echo "$relpath" | grep -qE 'skills/[^/]+/(scripts|references)/'; then
    parent_skill=$(echo "$relpath" | sed -E -n 's#.*skills/([^/]+)/(scripts|references)/.*#\1#p')
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
  UNTRACKED_JSON=$(json_array_from_name UNTRACKED)
  TRACKING_JSON=$(json_array_from_name TRACKING_FILES)
  LIVE_JSON=$(json_array_from_name TOOLS_ON_DISK)
  RETAINED_JSON=$(json_array_from_name RETAINED_TOOLS)
  ARCHIVE_JSON=$(json_array_from_name ARCHIVE_TOOLS)
  TEST_FIXTURE_JSON=$(json_array_from_name TEST_FIXTURE_TOOLS)
  GENERATED_JSON=$(json_array_from_name GENERATED_TOOLS)
  emit_json_report "$TOTAL_DISK" "$TRACKED_COUNT" "$DRIFT_COUNT" "$DRIFT_PCT" "$PASS" "$TRACKING_JSON" "$UNTRACKED_JSON" "$LIVE_JSON" "$RETAINED_JSON" "$ARCHIVE_JSON" "$TEST_FIXTURE_JSON" "$GENERATED_JSON"
else
  echo "=== Capability Drift Report ==="
  echo ""
  echo "Repo:           $(basename "$(pwd)")"
  echo "Tools on disk:  $TOTAL_DISK"
  echo "Tools tracked:  $TRACKED_COUNT"
  echo "Undocumented:   $DRIFT_COUNT ($DRIFT_PCT%)"
  echo "Threshold:      $THRESHOLD%"
  echo "Scope counts:   live=$TOTAL_DISK retained=${#RETAINED_TOOLS[@]} archive=${#ARCHIVE_TOOLS[@]} test_fixture=${#TEST_FIXTURE_TOOLS[@]} generated=${#GENERATED_TOOLS[@]}"
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
