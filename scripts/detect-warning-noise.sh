#!/usr/bin/env bash
# detect-warning-noise.sh — DS-27: Warning ledger noise ratio
# Detects repos where the warning ledger has excessive unacknowledged warnings.
# Multi-signal: unacked_count/total_count ratio + unique_unacked_categories/total_categories.
# Threshold (PROVISIONAL): SNR > 25% flags. Per-repo baseline recommended.
#
# Usage: bash scripts/detect-warning-noise.sh [repo_path] [--threshold N] [--json]
# Exits 0 if noise below threshold (healthy), 1 if above threshold (noisy), 2 if no ledger.
#
# Stage 6 M3.1 (R-DS27, F15)
set -euo pipefail

REPO="${1:-.}"
THRESHOLD=25
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

# Find warning ledger (search work/ and root)
LEDGER=""
for candidate in work/WARNING_LEDGER.jsonl WARNING_LEDGER.jsonl; do
  if [ -f "$candidate" ]; then
    LEDGER="$candidate"
    break
  fi
done

if [ -z "$LEDGER" ]; then
  if $JSON_OUT; then
    echo '{"ds":"DS-27","signal":"no-ledger","fires":false,"reason":"No WARNING_LEDGER.jsonl found"}'
  else
    echo "DS-27: No WARNING_LEDGER.jsonl found. Skipping."
  fi
  exit 2
fi

# Count entries using grep (no python dependency)
total=$(wc -l < "$LEDGER" | tr -d ' ')
if [ "$total" -eq 0 ]; then
  if $JSON_OUT; then
    echo '{"ds":"DS-27","signal":"empty-ledger","fires":false,"reason":"Ledger exists but empty"}'
  else
    echo "DS-27: Warning ledger empty. Skipping."
  fi
  exit 2
fi

# Count acknowledged (entries with "acknowledged":true or "acknowledged": true)
acked=$(grep -c '"acknowledged"[[:space:]]*:[[:space:]]*true' "$LEDGER" 2>/dev/null || echo "0")
unacked=$((total - acked))

# Noise ratio as percentage
if [ "$total" -gt 0 ]; then
  noise_pct=$(( (unacked * 100) / total ))
else
  noise_pct=0
fi

# Count unique categories for unacked entries
unacked_categories=0
total_categories=0
if command -v python3 >/dev/null 2>&1; then
  eval "$(python3 -c "
import json, sys
total_cats = set()
unacked_cats = set()
for line in open('$LEDGER'):
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        cat = d.get('category', 'unknown')
        total_cats.add(cat)
        if not d.get('acknowledged', False):
            unacked_cats.add(cat)
    except json.JSONDecodeError:
        pass
print(f'total_categories={len(total_cats)}')
print(f'unacked_categories={len(unacked_cats)}')
" 2>/dev/null)" || true
fi

# Determine if DS fires
fires=false
if [ "$noise_pct" -gt "$THRESHOLD" ]; then
  fires=true
fi

if $JSON_OUT; then
  cat <<-ENDJSON
{"ds":"DS-27","signal":"warning-noise","fires":$fires,"total":$total,"acked":$acked,"unacked":$unacked,"noise_pct":$noise_pct,"threshold":$THRESHOLD,"total_categories":$total_categories,"unacked_categories":$unacked_categories,"ledger":"$LEDGER"}
ENDJSON
else
  echo "DS-27: Warning Ledger Noise Ratio"
  echo "  Ledger: $LEDGER"
  echo "  Total: $total  Acked: $acked  Unacked: $unacked"
  echo "  Noise: ${noise_pct}% (threshold: ${THRESHOLD}%)"
  echo "  Categories: $total_categories total, $unacked_categories with unacked"
  if $fires; then
    echo "  FIRES: Noise ratio ${noise_pct}% exceeds ${THRESHOLD}%"
    exit 1
  else
    echo "  OK: Noise ratio ${noise_pct}% within ${THRESHOLD}% threshold"
    exit 0
  fi
fi

if $fires; then
  exit 1
else
  exit 0
fi
