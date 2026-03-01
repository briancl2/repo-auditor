#!/usr/bin/env bash
# detect-measurement-disconnect.sh — DS-33: Measurement-Action Disconnect
# Detects repos where measurement artifacts are produced (SCORECARD, SER)
# but no measurement-driven changes follow. Scoring system runs but doesn't steer.
#
# Usage: bash scripts/detect-measurement-disconnect.sh [repo_path] [--sessions N] [--json]
# Exits 0 if healthy (measurement drives action), 1 if disconnected, 2 if insufficient data.
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

# Find work directories (most recent N*2 to account for non-code-change contracts)
WORK_SEARCH=$((SESSIONS * 2))
WORK_DIRS=()
if [ -d work/ ]; then
  while IFS= read -r d; do
    [ -f "$d/WORK.md" ] && WORK_DIRS+=("$d")
  done < <(find work/ -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort -r | head -"$WORK_SEARCH")
fi

if [ "${#WORK_DIRS[@]}" -lt "$SESSIONS" ]; then
  if $JSON_OUT; then
    echo "{\"ds\":\"DS-33\",\"signal\":\"insufficient-data\",\"fires\":false,\"reason\":\"Only ${#WORK_DIRS[@]} work dirs found, need $SESSIONS\"}"
  else
    echo "DS-33: Insufficient data (${#WORK_DIRS[@]} work dirs, need $SESSIONS). Skipping."
  fi
  exit 2
fi

# Count consecutive zero-delta code-change sessions (most recent first)
ZERO_DELTA_STREAK=0
TOTAL_CODE_CHANGE=0
for wdir in "${WORK_DIRS[@]}"; do
  # Check work type
  WTYPE=$(grep -i 'work type' "$wdir/WORK.md" 2>/dev/null | head -1 | sed 's/.*: *//' | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
  if [ "$WTYPE" != "code-change" ]; then
    continue
  fi
  TOTAL_CODE_CHANGE=$((TOTAL_CODE_CHANGE + 1))

  # Check for DELTA.md or measurement-summary.json
  DELTA=999  # sentinel for "no delta found"
  if [ -f "$wdir/DELTA.md" ]; then
    # Extract delta from DELTA.md (format varies: "Delta: +N" or "N->M" or similar)
    DELTA=$(grep -oE '[+-]?[0-9]+' "$wdir/DELTA.md" 2>/dev/null | tail -1 || echo "999")
  fi
  if [ -f "$wdir/measurement-summary.json" ]; then
    DELTA=$(python3 -c "import json; d=json.load(open('$wdir/measurement-summary.json')); print(d.get('delta',999))" 2>/dev/null || echo "999")
  fi

  # Check post-audit SCORECARD
  if [ -f "$wdir/post-audit/SCORECARD.json" ] && [ -f "$wdir/pre-audit/SCORECARD.json" ]; then
    PRE=$(python3 -c "import json; print(json.load(open('$wdir/pre-audit/SCORECARD.json')).get('composite',0))" 2>/dev/null || echo "0")
    POST=$(python3 -c "import json; print(json.load(open('$wdir/post-audit/SCORECARD.json')).get('composite',0))" 2>/dev/null || echo "0")
    DELTA=$((POST - PRE))
  fi

  if [ "$DELTA" -eq 0 ] 2>/dev/null; then
    ZERO_DELTA_STREAK=$((ZERO_DELTA_STREAK + 1))
  else
    break  # streak broken
  fi

  [ "$TOTAL_CODE_CHANGE" -ge "$SESSIONS" ] && break
done

# Fire condition: N>=3 consecutive code-change with zero delta
FIRES=false
REASON="healthy"
if [ "$ZERO_DELTA_STREAK" -ge "$SESSIONS" ]; then
  FIRES=true
  REASON="$ZERO_DELTA_STREAK consecutive code-change sessions with zero SCORECARD delta"
elif [ "$TOTAL_CODE_CHANGE" -lt "$SESSIONS" ]; then
  REASON="Only $TOTAL_CODE_CHANGE code-change sessions found (need $SESSIONS for detection)"
else
  REASON="$ZERO_DELTA_STREAK zero-delta streak (threshold: $SESSIONS). Last session had non-zero delta."
fi

if $JSON_OUT; then
  cat <<JSON
{"ds":"DS-33","signal":"measurement-disconnect","fires":$FIRES,"zero_delta_streak":$ZERO_DELTA_STREAK,"total_code_change":$TOTAL_CODE_CHANGE,"threshold":$SESSIONS,"reason":"$REASON"}
JSON
else
  if $FIRES; then
    echo "DS-33 FIRES: Measurement-action disconnect — $REASON"
  else
    echo "DS-33 OK: $REASON"
  fi
fi

if $FIRES; then
  exit 1
else
  exit 0
fi
