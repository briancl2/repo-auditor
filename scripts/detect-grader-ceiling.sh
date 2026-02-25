#!/usr/bin/env bash
# detect-grader-ceiling.sh — DS-30: Grader ceiling lock detection
# Detects repos where the OPERATING_MODEL_SCORECARD shows very low variance
# across 3+ consecutive scorecards, suggesting the grader is saturated and
# cannot distinguish good sessions from mediocre ones.
#
# Usage: bash scripts/detect-grader-ceiling.sh [repo_path] [--threshold N] [--json]
# Exits 0 if variance is healthy (no ceiling), 1 if ceiling detected, 2 if insufficient data.
#
# Cold-start grace: if <3 scorecards found, exits 2 (skip, no finding).
# Threshold (PROVISIONAL): variance <2 across 3+ consecutive scorecards.
#
# Stage 6 M3.3 (R-DS30, F13)
set -euo pipefail

REPO="${1:-.}"
THRESHOLD=2
JSON_OUT=false
MIN_SCORECARDS=3

shift 2>/dev/null || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --threshold) THRESHOLD="$2"; shift 2 ;;
    --json) JSON_OUT=true; shift ;;
    --min) MIN_SCORECARDS="$2"; shift 2 ;;
    *) shift ;;
  esac
done

cd "$REPO"

# Find OPERATING_MODEL_SCORECARD.json files (search work dirs)
SCORECARDS=()
while IFS= read -r f; do
  SCORECARDS+=("$f")
done < <(find work -name "OPERATING_MODEL_SCORECARD.json" -type f 2>/dev/null | sort)

SCORECARD_COUNT=${#SCORECARDS[@]}

echo "================================================================"
echo "DS-30: Grader Ceiling Lock Detection"
echo "================================================================"
echo ""
echo "  Repo: $(basename "$REPO")"
echo "  Scorecards found: $SCORECARD_COUNT"
echo "  Min required: $MIN_SCORECARDS"
echo "  Variance threshold: $THRESHOLD"
echo ""

# Cold-start grace
if [ "$SCORECARD_COUNT" -lt "$MIN_SCORECARDS" ]; then
  echo "  SKIP: insufficient data ($SCORECARD_COUNT < $MIN_SCORECARDS scorecards)"
  if $JSON_OUT; then
    echo "{\"ds\": \"DS-30\", \"status\": \"skip\", \"reason\": \"cold-start\", \"scorecard_count\": $SCORECARD_COUNT}"
  fi
  exit 2
fi

# Extract composite scores from the most recent N scorecards
SCORES=()
for sc in "${SCORECARDS[@]}"; do
  # Try to extract composite score
  COMPOSITE=$(python3 -c "
import json, sys
try:
    with open('$sc') as f:
        data = json.load(f)
    # Handle nested 'composite' or top-level 'composite'
    if 'composite' in data:
        c = data['composite']
        if isinstance(c, dict) and 'score' in c:
            print(c['score'])
        else:
            print(c)
    elif 'dimensions' in data:
        total = sum(d.get('score', 0) for d in data['dimensions'].values() if isinstance(d, dict))
        print(total)
    else:
        print(-1)
except Exception:
    print(-1)
" 2>/dev/null)
  
  if [ -n "$COMPOSITE" ] && [ "$COMPOSITE" != "-1" ]; then
    SCORES+=("$COMPOSITE")
    echo "  Score: $COMPOSITE  ($sc)"
  fi
done

VALID_COUNT=${#SCORES[@]}

if [ "$VALID_COUNT" -lt "$MIN_SCORECARDS" ]; then
  echo ""
  echo "  SKIP: only $VALID_COUNT valid scores extracted (need $MIN_SCORECARDS)"
  if $JSON_OUT; then
    echo "{\"ds\": \"DS-30\", \"status\": \"skip\", \"reason\": \"insufficient-valid\", \"valid_count\": $VALID_COUNT}"
  fi
  exit 2
fi

# Compute variance of last N scores (use all if more than MIN)
# Take the most recent MIN_SCORECARDS scores for analysis
RECENT_SCORES=("${SCORES[@]: -$MIN_SCORECARDS}")

# Compute min, max, range (variance proxy)
MIN_SCORE="${RECENT_SCORES[0]}"
MAX_SCORE="${RECENT_SCORES[0]}"
SUM=0
for s in "${RECENT_SCORES[@]}"; do
  SUM=$((SUM + s))
  if [ "$s" -lt "$MIN_SCORE" ]; then MIN_SCORE="$s"; fi
  if [ "$s" -gt "$MAX_SCORE" ]; then MAX_SCORE="$s"; fi
done
RANGE=$((MAX_SCORE - MIN_SCORE))
COUNT=${#RECENT_SCORES[@]}
AVG=$((SUM / COUNT))

echo ""
echo "  Recent $COUNT scores: ${RECENT_SCORES[*]}"
echo "  Range: $RANGE (min=$MIN_SCORE, max=$MAX_SCORE, avg=$AVG)"

CEILING_DETECTED=false
if [ "$RANGE" -lt "$THRESHOLD" ]; then
  CEILING_DETECTED=true
  echo ""
  echo "  ** CEILING DETECTED: range $RANGE < threshold $THRESHOLD **"
  echo "  The grader produces nearly identical scores across sessions."
  echo "  This suggests saturation — the grader cannot distinguish"
  echo "  good sessions from mediocre ones."
  echo ""
  echo "FINDING: DS-30 ceiling lock (range=$RANGE, threshold=$THRESHOLD)"
fi

if $JSON_OUT; then
  cat <<ENDJSON
{
  "ds": "DS-30",
  "status": "$(if $CEILING_DETECTED; then echo "fired"; else echo "clear"; fi)",
  "scorecard_count": $SCORECARD_COUNT,
  "valid_count": $VALID_COUNT,
  "recent_scores": [$(IFS=,; echo "${RECENT_SCORES[*]}")],
  "range": $RANGE,
  "threshold": $THRESHOLD,
  "min": $MIN_SCORE,
  "max": $MAX_SCORE,
  "avg": $AVG,
  "ceiling_detected": $CEILING_DETECTED
}
ENDJSON
fi

if $CEILING_DETECTED; then
  exit 1
else
  echo ""
  echo "  PASS: grader shows sufficient variance (range=$RANGE >= threshold=$THRESHOLD)"
  exit 0
fi
