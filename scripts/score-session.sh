#!/usr/bin/env bash
# scripts/score-session.sh — Deterministic session grader
#
# Reads session artifacts (work dir, git log, LEARNINGS.md) and produces
# an OPERATING_MODEL_SCORECARD.json per schemas/OPERATING_MODEL_SCORECARD.schema.json.
# Simplified 4-dimension, 15pt grader for repo-auditor.
#
# Usage: scripts/score-session.sh <work_dir> <session_id>
# Exit codes: 0 = scored, 1 = missing inputs

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK_DIR="${1:?Usage: score-session.sh <work_dir> <session_id>}"
SESSION_ID="${2:?Usage: score-session.sh <work_dir> <session_id>}"
GRADER_VERSION="$(cd "$REPO_ROOT" && git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Resolve work dir to absolute path
if [[ ! "$WORK_DIR" = /* ]]; then
    WORK_DIR="$REPO_ROOT/$WORK_DIR"
fi

# ── Validation ────────────────────────────────────────────────────────
if [[ ! -d "$WORK_DIR" ]]; then
    echo "ERROR: Work directory not found: $WORK_DIR" >&2
    exit 1
fi
if [[ ! -f "$WORK_DIR/WORK.md" ]]; then
    echo "ERROR: WORK.md not found in $WORK_DIR" >&2
    exit 1
fi

# ── Helper: JSON array from args ─────────────────────────────────────
evidence_json() {
    python3 -c "
import json, sys
items = sys.argv[1:]
print(json.dumps(items))
" "$@"
}
# ── Session-scoped commit list (spec 057: R-SESSSCOPE) ─────────────
START_SHA=""
if [[ -f "$WORK_DIR/.start_sha" ]]; then
    START_SHA=$(tr -d '[:space:]' < "$WORK_DIR/.start_sha")
fi

get_session_shas() {
    if [[ -n "$START_SHA" ]] && git -C "$REPO_ROOT" merge-base --is-ancestor "$START_SHA" HEAD 2>/dev/null; then
        git -C "$REPO_ROOT" log --format='%H' "${START_SHA}..HEAD" 2>/dev/null
    else
        git -C "$REPO_ROOT" log --format='%H' -5 2>/dev/null
    fi
}

SESSION_SHAS=$(get_session_shas)
if [[ -z "$SESSION_SHAS" ]]; then
    SESSION_COMMIT_COUNT=0
else
    SESSION_COMMIT_COUNT=$(echo "$SESSION_SHAS" | wc -l | tr -d ' ')
fi
if [[ -n "$START_SHA" ]] && git -C "$REPO_ROOT" merge-base --is-ancestor "$START_SHA" HEAD 2>/dev/null; then
    COMMIT_SCOPE="session-scoped ($SESSION_COMMIT_COUNT commits since $(echo "$START_SHA" | cut -c1-7))"
else
    COMMIT_SCOPE="recent commits (fallback, no .start_sha)"
fi
# ==============================
# DIMENSION 1: hypothesis_discipline (max 3)
# ==============================
hd_score=0
hd_evidence=()

# Check 1: WORK.md has "Prediction:" line that's not a placeholder
if grep -q "Prediction:" "$WORK_DIR/WORK.md" 2>/dev/null; then
    if ! grep -q '{what you expect' "$WORK_DIR/WORK.md" 2>/dev/null; then
        hd_score=$((hd_score + 1))
        hd_evidence+=("1pt: WORK.md has Prediction filled in")
    else
        hd_evidence+=("0pt: WORK.md Prediction is template placeholder")
    fi
else
    hd_evidence+=("0pt: No Prediction: found in WORK.md")
fi

# Check 2: WORK.md has PASS: and FAIL: lines that are not placeholders
if grep -qiE '\*{0,2}PASS[^a-zA-Z]' "$WORK_DIR/WORK.md" 2>/dev/null && \
   grep -qiE '\*{0,2}FAIL[^a-zA-Z]' "$WORK_DIR/WORK.md" 2>/dev/null; then
    if ! grep -q '{measurable' "$WORK_DIR/WORK.md" 2>/dev/null; then
        hd_score=$((hd_score + 1))
        hd_evidence+=("1pt: PASS/FAIL criteria explicit in WORK.md")
    else
        hd_evidence+=("0pt: PASS/FAIL criteria are template placeholders")
    fi
else
    hd_evidence+=("0pt: Missing PASS or FAIL criteria in WORK.md")
fi

# Check 3: [x] Hypothesis stated checkbox
if grep -q '\[x\] Hypothesis stated' "$WORK_DIR/WORK.md" 2>/dev/null; then
    hd_score=$((hd_score + 1))
    hd_evidence+=("1pt: Hypothesis stated checkbox marked")
else
    hd_evidence+=("0pt: Hypothesis stated checkbox not marked")
fi

# ==============================
# DIMENSION 2: gate_integrity (max 4)
# ==============================
gi_score=0
gi_evidence=()

# Check 1: Gate 1 ran (WORK.md + pre-audit/)
if [[ -f "$WORK_DIR/WORK.md" ]] && [[ -d "$WORK_DIR/pre-audit" ]]; then
    gi_score=$((gi_score + 1))
    gi_evidence+=("1pt: Gate 1 ran (WORK.md + pre-audit/ present)")
else
    gi_evidence+=("0pt: Gate 1 incomplete (WORK.md or pre-audit/ missing)")
fi

# Check 2: Session-scoped commits have Spec-ID or Spec-Exempt trailer (spec 057)
trailer_total=0
trailer_pass=0
for sha in $SESSION_SHAS; do
    trailer_total=$((trailer_total + 1))
    body=$(cd "$REPO_ROOT" && git log --format='%B' -1 "$sha" 2>/dev/null)
    if echo "$body" | grep -qE '(Spec-ID:|Spec-Exempt:)'; then
        trailer_pass=$((trailer_pass + 1))
    fi
done
if [[ $trailer_total -gt 0 ]] && [[ $trailer_pass -eq $trailer_total ]]; then
    gi_score=$((gi_score + 1))
    gi_evidence+=("1pt: All $trailer_total $COMMIT_SCOPE commits have Spec-ID/Spec-Exempt trailer")
else
    gi_evidence+=("0pt: $trailer_pass/$trailer_total $COMMIT_SCOPE commits have trailers")
fi

# Check 3: No --no-verify detected in session commits (spec 057)
noverify_count=0
for sha in $SESSION_SHAS; do
    body=$(cd "$REPO_ROOT" && git log --format='%B' -1 "$sha" 2>/dev/null)
    if echo "$body" | grep -q 'No-Verify-Reason:'; then
        noverify_count=$((noverify_count + 1))
    fi
done
if [[ $noverify_count -eq 0 ]]; then
    gi_score=$((gi_score + 1))
    gi_evidence+=("1pt: No --no-verify detected in $COMMIT_SCOPE")
else
    gi_evidence+=("0pt: $noverify_count commits with No-Verify-Reason in $COMMIT_SCOPE")
fi

# Check 4: post-audit/ exists (Gate 3 ran)
if [[ -d "$WORK_DIR/post-audit" ]]; then
    gi_score=$((gi_score + 1))
    gi_evidence+=("1pt: Gate 3 ran (post-audit/ present)")
else
    gi_evidence+=("0pt: Gate 3 not completed (no post-audit/)")
fi

# ==============================
# DIMENSION 3: measurement_completeness (max 4)
# ==============================
mc_score=0
mc_evidence=()

# Check 1: pre-audit/SCORECARD.json exists
if [[ -f "$WORK_DIR/pre-audit/SCORECARD.json" ]]; then
    mc_score=$((mc_score + 1))
    mc_evidence+=("1pt: pre-audit/SCORECARD.json exists")
else
    mc_evidence+=("0pt: pre-audit/SCORECARD.json missing")
fi

# Check 2: post-audit/SCORECARD.json exists
if [[ -f "$WORK_DIR/post-audit/SCORECARD.json" ]]; then
    mc_score=$((mc_score + 1))
    mc_evidence+=("1pt: post-audit/SCORECARD.json exists")
else
    mc_evidence+=("0pt: post-audit/SCORECARD.json missing")
fi

# Check 3: DELTA.md exists
if [[ -f "$WORK_DIR/DELTA.md" ]]; then
    mc_score=$((mc_score + 1))
    mc_evidence+=("1pt: DELTA.md exists")
else
    mc_evidence+=("0pt: DELTA.md missing")
fi

# Check 4: OPERATING_MODEL_SCORECARD.json exists (grader itself ran)
# This will be false on first pass but true on re-grade
if [[ -f "$WORK_DIR/OPERATING_MODEL_SCORECARD.json" ]]; then
    mc_score=$((mc_score + 1))
    mc_evidence+=("1pt: OPERATING_MODEL_SCORECARD.json exists")
else
    mc_evidence+=("0pt: OPERATING_MODEL_SCORECARD.json not yet produced (expected on first run)")
fi

# ==============================
# DIMENSION 4: learning_extraction (max 3)
# ==============================
le_score=0
le_evidence=()

# Check 1: LEARNINGS.md has more lines than baseline
new_learnings=0
if [[ -f "$REPO_ROOT/LEARNINGS.md" ]] && [[ -f "$WORK_DIR/.learnings_baseline_count" ]]; then
    baseline=$(cat "$WORK_DIR/.learnings_baseline_count")
    current=$(grep -cE '^\| L[0-9]+' "$REPO_ROOT/LEARNINGS.md" 2>/dev/null || echo "0")
    new_learnings=$((current - baseline))
    if [[ $new_learnings -gt 0 ]]; then
        le_score=$((le_score + 1))
        le_evidence+=("1pt: $new_learnings new L-number entries since baseline")
    else
        le_evidence+=("0pt: No new L-number entries (baseline=$baseline, current=$current)")
    fi
else
    le_evidence+=("0pt: LEARNINGS.md or baseline count missing")
fi

# Check 2: New entries have table format (pipe-separated)
if [[ $new_learnings -gt 0 ]]; then
    # Check if the last N entries are pipe-delimited table rows
    table_count=$(grep -cE '^\| L[0-9]+\s*\|' "$REPO_ROOT/LEARNINGS.md" 2>/dev/null || echo "0")
    if [[ $table_count -ge $current ]]; then
        le_score=$((le_score + 1))
        le_evidence+=("1pt: New entries use pipe-delimited table format")
    else
        le_evidence+=("0pt: Some entries not in table format")
    fi
else
    le_evidence+=("0pt: No new entries to check format")
fi

# Check 3: New entries have non-empty source column
rm -f "$WORK_DIR/.source_check_tmp"
if [[ $new_learnings -gt 0 ]]; then
    grep -E '^\| L[0-9]+' "$REPO_ROOT/LEARNINGS.md" 2>/dev/null | tail -n "$new_learnings" | while IFS= read -r line; do
        source_col=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}')
        if [ -z "$source_col" ]; then
            echo "empty" >> "$WORK_DIR/.source_check_tmp"
        fi
    done || true
    if [[ -f "$WORK_DIR/.source_check_tmp" ]]; then
        rm -f "$WORK_DIR/.source_check_tmp"
        le_evidence+=("0pt: Some new entries have empty source column")
    else
        le_score=$((le_score + 1))
        le_evidence+=("1pt: New entries have non-empty source column")
    fi
else
    le_evidence+=("0pt: No new entries to check source")
fi

# ==============================
# COMPOSITE
# ==============================
total_score=$((hd_score + gi_score + mc_score + le_score))
total_max=15
percentage=$(python3 -c "print(round($total_score / $total_max * 100, 1))")

if [[ $total_score -ge 12 ]]; then
    verdict="PASS"
elif [[ $total_score -ge 9 ]]; then
    verdict="PARTIAL"
else
    verdict="FAIL"
fi

# ==============================
# OUTPUT JSON
# ==============================
output_file="$WORK_DIR/OPERATING_MODEL_SCORECARD.json"
WORK_DIR_REL="${WORK_DIR#"$REPO_ROOT"/}"

python3 -c "
import json, sys

data = {
    'schema_version': '1.0.0',
    'session_id': sys.argv[1],
    'timestamp': sys.argv[2],
    'work_dir': sys.argv[3],
    'grader_version': sys.argv[4],
    'dimensions': {
        'hypothesis_discipline': {
            'score': int(sys.argv[5]),
            'max': 3,
            'evidence': json.loads(sys.argv[9])
        },
        'gate_integrity': {
            'score': int(sys.argv[6]),
            'max': 4,
            'evidence': json.loads(sys.argv[10])
        },
        'measurement_completeness': {
            'score': int(sys.argv[7]),
            'max': 4,
            'evidence': json.loads(sys.argv[11])
        },
        'learning_extraction': {
            'score': int(sys.argv[8]),
            'max': 3,
            'evidence': json.loads(sys.argv[12])
        }
    },
    'composite': {
        'score': int(sys.argv[13]),
        'max': int(sys.argv[14]),
        'percentage': float(sys.argv[15])
    },
    'verdict': sys.argv[16]
}

with open(sys.argv[17], 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" "$SESSION_ID" "$TIMESTAMP" "$WORK_DIR_REL" "$GRADER_VERSION" \
  "$hd_score" "$gi_score" "$mc_score" "$le_score" \
  "$(evidence_json "${hd_evidence[@]}")" \
  "$(evidence_json "${gi_evidence[@]}")" \
  "$(evidence_json "${mc_evidence[@]}")" \
  "$(evidence_json "${le_evidence[@]}")" \
  "$total_score" "$total_max" "$percentage" "$verdict" \
  "$output_file"

# Validate output against schema (spec 055, R-SCHEMAVAL)
SCHEMA_FILE="$REPO_ROOT/schemas/OPERATING_MODEL_SCORECARD.schema.json"
if command -v jsonschema >/dev/null 2>&1; then
  if jsonschema -i "$output_file" "$SCHEMA_FILE" 2>/dev/null; then
    echo "Schema validation: PASS"
  else
    echo "ERROR: SCORECARD failed schema validation" >&2
    echo "  Schema: $SCHEMA_FILE" >&2
    echo "  Output: $output_file" >&2
    exit 1
  fi
else
  echo "WARN: jsonschema CLI not found, skipping SCORECARD validation" >&2
fi

echo "SCORECARD: $verdict ($total_score/$total_max = $percentage%)"
echo "  hypothesis_discipline:      $hd_score/3"
echo "  gate_integrity:             $gi_score/4"
echo "  measurement_completeness:   $mc_score/4"
echo "  learning_extraction:        $le_score/3"
echo "Output: $output_file"
