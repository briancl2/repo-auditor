#!/usr/bin/env bash
# repo-auditor.sh — Composite repo health audit (deterministic)
#
# Wraps 5 proven deterministic tools plus the DS-34+ signature sweep into a
# single audit run:
#   1. pre-scan-target.sh    → AI surface inventory
#   2. classify-repo-maturity.sh → Phase classification
#   3. stall-risk-score.sh   → 6-signal stall risk
#   4. extract-repo-dna.sh   → 10-feature DNA fingerprint
#   5. detect-capability-drift.sh → Tool tracking drift
#   6. detect-new-signatures.sh → Extended DS bundle (DS-34+)
#
# Then runs score-audit-dimensions.sh to produce a 5-dimension scorecard.
#
# Usage: bash scripts/repo-auditor.sh <repo_path> [output_dir] [options]
#
# Modes:
#   standard (default) — 5 bash tools + dimension scorer
#   deep               — standard + semantic cross-reference analysis (5 checks)
#
# Outputs:
#   <output_dir>/AUDIT_REPORT.md   — Human-readable composite report
#   <output_dir>/SCORECARD.json    — Machine-readable 5-dimension scores
#   <output_dir>/SCORECARD_RECEIPTS.json — Raw scorer receipts + count reconciliation
#   <output_dir>/CONTEXT_SCORE_MANIFEST.json — Context / git / local-artifact preflight
#   <output_dir>/pre-scan/         — Pre-scan artifacts (PRE_SCAN.md, etc.)
#   <output_dir>/maturity.txt      — classify-repo-maturity.sh output
#   <output_dir>/stall-risk.txt    — stall-risk-score.sh output
#   <output_dir>/dna.txt           — extract-repo-dna.sh output
#   <output_dir>/drift.txt         — detect-capability-drift.sh output
#   <output_dir>/DS-34-plus-results.json — Extended signature bundle
#
# Guardrails:
#   - No associative arrays (macOS bash 3.2 compat, L10)
#   - No grep -c || echo 0 under pipefail (L11)
#   - All paths relative to script dir
#
# Exit codes:
#   0 — audit completed successfully
#   1 — missing argument or tool failure

set -euo pipefail

resolve_realpath_for_scope() {
    python3 - "$1" <<'PYEOF'
import os
import sys

print(os.path.realpath(sys.argv[1]))
PYEOF
}

dirty_closeout_scope_is_valid() {
    python3 - "$1" "$2" "$3" <<'PYEOF'
import os
import re
import sys

repo_root = os.path.realpath(sys.argv[1]).rstrip("/")
output_dir = os.path.realpath(sys.argv[2]).rstrip("/")
current_working_dir = os.path.realpath(sys.argv[3]).rstrip("/")
tmp_root = os.path.realpath(os.environ.get("TMPDIR", "/tmp")).rstrip("/")

canonical_pattern = re.compile(rf"^{re.escape(repo_root)}/work/[0-9]{{8}}T[0-9]{{6}}Z/post-audit$")
staging_pattern = re.compile(rf"^{re.escape(tmp_root)}/[0-9]{{8}}T[0-9]{{6}}Z\.post-audit\.run\.[^/]+$")

allowed = repo_root == current_working_dir and (
    canonical_pattern.fullmatch(output_dir) or staging_pattern.fullmatch(output_dir)
)
raise SystemExit(0 if allowed else 1)
PYEOF
}

# ── Argument parsing ──────────────────────────────────────────────────
AUDIT_MODE="standard"
AUDIT_CONTEXT_ID="${AUDIT_CONTEXT_ID:-standard}"
REQUIRE_PORTABLE_CONTEXT=0
COMPARE_ORACLE_VERSION="${COMPARE_ORACLE_VERSION:-1.0.0}"
ALLOW_DIRTY_CLOSEOUT=0
# Optional env fallback for automation wrappers that do not pass the CLI flag.
REPRESENTATIVENESS_AUTHORITY="${REPRESENTATIVENESS_AUTHORITY_REPO:-}"
POSITIONAL=()

while [ "$#" -gt 0 ]; do
    case "$1" in
        --mode)
            AUDIT_MODE="${2:?Usage: --mode <standard|deep>}"
            shift 2
            ;;
        --context-id)
            AUDIT_CONTEXT_ID="${2:?Usage: --context-id <name>}"
            shift 2
            ;;
        --require-portable-context)
            REQUIRE_PORTABLE_CONTEXT=1
            shift
            ;;
        --allow-dirty-closeout-post-audit)
            ALLOW_DIRTY_CLOSEOUT=1
            shift
            ;;
        --representativeness-authority)
            REPRESENTATIVENESS_AUTHORITY="${2:?Usage: --representativeness-authority <repo_path>}"
            shift 2
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

REPO="${POSITIONAL[0]:?Usage: repo-auditor.sh <repo_path> [output_dir] [options]}"
OUTPUT_DIR="${POSITIONAL[1]:-audit_output}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# W6 fix: validate repo path exists
if [ ! -d "$REPO" ]; then
    echo "ERROR: $REPO not found or not a directory" >&2
    exit 1
fi

if [ "$ALLOW_DIRTY_CLOSEOUT" -eq 1 ]; then
    if [ "${REPO_AUDITOR_CLOSEOUT_CALLER:-}" != "1" ]; then
        echo "ERROR: --allow-dirty-closeout-post-audit is reserved for work-close callers." >&2
        exit 1
    fi
    REPO_REALPATH="$(resolve_realpath_for_scope "$REPO")"
    OUTPUT_REALPATH="$(resolve_realpath_for_scope "$OUTPUT_DIR")"
    if ! dirty_closeout_scope_is_valid "$REPO_REALPATH" "$OUTPUT_REALPATH" "$(pwd -P)"; then
        echo "ERROR: --allow-dirty-closeout-post-audit requires a self-audit from the target repo root with output under work/<session>/post-audit or the matching closeout staging temp dir" >&2
        exit 1
    fi
fi

# ── C4: Pre-operation guard rails (Stage 11.2) ───────────────────────
# ── C4: Shared lockdir (H3 fix: single definition, passed to guard) ──
LOCKDIR="/tmp/repo-auditor-locks"

GUARD_SCRIPT="$SCRIPT_DIR/operation-guard.sh"
if [ -x "$GUARD_SCRIPT" ]; then
    GUARD_ARGS=("$REPO" "--lockdir" "$LOCKDIR")
    if [ "$ALLOW_DIRTY_CLOSEOUT" -eq 1 ]; then
        GUARD_ARGS+=("--allow-dirty-closeout-post-audit")
    fi
    if ! bash "$GUARD_SCRIPT" "${GUARD_ARGS[@]}" 2>&1; then
        echo "ERROR: Operation guard FAILED. Aborting audit." >&2
        exit 1
    fi
fi

# ── C4: Acquire operation lock (PID matches this process) ────────────
LOCKFILE="$LOCKDIR/$(echo "$REPO" | tr '/' '_').lock"
mkdir -p "$LOCKDIR"
echo $$ > "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

# Resolve repo name for display
REPO_NAME="$(basename "$REPO")"

# Create output structure
mkdir -p "$OUTPUT_DIR/pre-scan"

echo "================================================================"
echo "Repo Auditor: $REPO_NAME"
echo "================================================================"
echo ""
echo "Target:  $REPO"
echo "Output:  $OUTPUT_DIR"
echo "Mode:    $AUDIT_MODE"
echo "Context: $AUDIT_CONTEXT_ID"
echo ""

# Track failures (no associative arrays per L10)
FAILURES=""
FAIL_COUNT=0

CONTEXT_SCRIPT="$SCRIPT_DIR/write_context_score_manifest.py"
CONTEXT_MANIFEST="$OUTPUT_DIR/CONTEXT_SCORE_MANIFEST.json"

echo "--- Writing context-score manifest ---"
echo ""
CONTEXT_CMD=(python3 "$CONTEXT_SCRIPT" "$REPO" "$CONTEXT_MANIFEST" --context-id "$AUDIT_CONTEXT_ID" --compare-oracle-version "$COMPARE_ORACLE_VERSION")
if [ "$REQUIRE_PORTABLE_CONTEXT" -eq 1 ]; then
    CONTEXT_CMD+=(--require-portable-context)
fi
if [ -n "$REPRESENTATIVENESS_AUTHORITY" ]; then
    CONTEXT_CMD+=(--representativeness-authority "$REPRESENTATIVENESS_AUTHORITY")
fi
if "${CONTEXT_CMD[@]}" > "$OUTPUT_DIR/context-manifest-log.txt" 2>&1; then
    echo "  [context] ✅ manifest written"
else
    rc=$?
    echo "  [context] ⚠️  exit $rc (details in context-manifest-log.txt)"
    FAILURES="$FAILURES context-manifest"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    if [ "$REQUIRE_PORTABLE_CONTEXT" -eq 1 ]; then
        echo "ERROR: portable context required but preflight rejected this audit." >&2
        exit 1
    fi
fi
echo ""

PRESCAN_SCRIPT="$SCRIPT_DIR/../.agents/skills/pre-scanning/scripts/pre-scan-target.sh"
if [ ! -x "$PRESCAN_SCRIPT" ]; then
    echo "ERROR: pre-scan script not found or not executable: $PRESCAN_SCRIPT" >&2
    exit 1
fi

run_tool() {
    local name="$1"
    local outfile="$2"
    shift 2
    echo "  [$name] running..."
    if "$@" > "$outfile" 2>&1; then
        echo "  [$name] ✅ done ($(wc -l < "$outfile" | tr -d ' ') lines)"
    else
        local exit_code=$?
        echo "  [$name] ⚠️  exit $exit_code (output saved)"
        # drift detector exits 1 on high drift — that's data, not failure
        if [ "$name" = "drift" ]; then
            echo "  [$name] (non-zero exit expected when drift > threshold)"
        else
            FAILURES="$FAILURES $name"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    fi
}

echo "--- Running core audit tools + DS-34+ signature sweep ---"
echo ""

# 1. Pre-scan (writes to directory, not stdout)
echo "  [pre-scan] running..."
if bash "$PRESCAN_SCRIPT" "$REPO" "$OUTPUT_DIR/pre-scan" > "$OUTPUT_DIR/pre-scan-log.txt" 2>&1; then
    if [ -f "$OUTPUT_DIR/pre-scan/PRE_SCAN.md" ]; then
        PRESCAN_LINES=$(wc -l < "$OUTPUT_DIR/pre-scan/PRE_SCAN.md" | tr -d ' ')
    else
        PRESCAN_LINES="unknown"
    fi
    echo "  [pre-scan] ✅ done ($PRESCAN_LINES lines)"
else
    rc=$?
    echo "  [pre-scan] ⚠️  exit $rc"
    FAILURES="$FAILURES pre-scan"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 2-5. Tools that write to stdout
run_tool "maturity" "$OUTPUT_DIR/maturity.txt" bash "$SCRIPT_DIR/classify-repo-maturity.sh" "$REPO"
run_tool "stall-risk" "$OUTPUT_DIR/stall-risk.txt" bash "$SCRIPT_DIR/stall-risk-score.sh" "$REPO"
run_tool "dna" "$OUTPUT_DIR/dna.txt" bash "$SCRIPT_DIR/extract-repo-dna.sh" "$REPO"
run_tool "drift" "$OUTPUT_DIR/drift.txt" bash "$SCRIPT_DIR/detect-capability-drift.sh" "$REPO"
run_tool "ds-34-plus" "$OUTPUT_DIR/ds-34-plus-log.txt" bash "$SCRIPT_DIR/detect-new-signatures.sh" "$REPO" "$OUTPUT_DIR"

echo ""

# --- Score dimensions ---
echo "--- Scoring 5 audit dimensions ---"
echo ""
if AUDIT_CONTEXT_ID="$AUDIT_CONTEXT_ID" \
    CONTEXT_SCORE_MANIFEST="$CONTEXT_MANIFEST" \
    COMPARE_ORACLE_VERSION="$COMPARE_ORACLE_VERSION" \
    bash "$SCRIPT_DIR/score-audit-dimensions.sh" "$OUTPUT_DIR" 2>"$OUTPUT_DIR/scorer-errors.txt"; then
    # Validate JSON
    if python3 -c "import json; json.load(open('$OUTPUT_DIR/SCORECARD.json')); json.load(open('$OUTPUT_DIR/SCORECARD_RECEIPTS.json'))" 2>/dev/null; then
        echo "  [scorecard] ✅ SCORECARD.json + SCORECARD_RECEIPTS.json written (valid JSON)"
    else
        echo "  [scorecard] ⚠️  score artifacts written but INVALID JSON"
        FAILURES="$FAILURES scorecard-json"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
else
    echo "  [scorecard] ⚠️  scorer failed"
    FAILURES="$FAILURES scorecard"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- Generate composite report ---
echo ""
echo "--- Generating AUDIT_REPORT.md ---"
echo ""

# Extract key metrics for the report
PHASE="unknown"
STALL_SCORE="?"
MATURITY_SCORE="?"
TRAJECTORY="?"
DRIFT_PCT="?"
CO_EVO="?"
TOTAL_FILES="?"
AI_SURFACES="?"

# Parse maturity output
if [ -f "$OUTPUT_DIR/maturity.txt" ]; then
    PHASE=$(grep "^PHASE:" "$OUTPUT_DIR/maturity.txt" | head -1 | sed 's/PHASE: *//' | sed 's/ *$//')
fi

# Parse stall-risk output
if [ -f "$OUTPUT_DIR/stall-risk.txt" ]; then
    STALL_SCORE=$(grep "SCORE:" "$OUTPUT_DIR/stall-risk.txt" | head -1 | sed 's/.*SCORE: *//' | sed 's/ .*//')
fi

# Parse DNA output
if [ -f "$OUTPUT_DIR/dna.txt" ]; then
    MATURITY_SCORE=$(grep "Maturity Score:" "$OUTPUT_DIR/dna.txt" | head -1 | sed 's/.*Maturity Score: *//' | sed 's/ *$//')
    TRAJECTORY=$(grep "Trajectory:" "$OUTPUT_DIR/dna.txt" | head -1 | sed 's/.*Trajectory: *//' | sed 's/ *$//')
    CO_EVO=$(grep "Co-Evolution Ratio:" "$OUTPUT_DIR/dna.txt" | head -1 | sed 's/.*Co-Evolution Ratio: *//' | sed 's/ *$//')
fi

# Parse drift output
if [ -f "$OUTPUT_DIR/drift.txt" ]; then
    DRIFT_PCT=$(grep "Undocumented:" "$OUTPUT_DIR/drift.txt" | head -1 | sed 's/.*(//' | sed 's/).*//' || true)
    if [ -z "$DRIFT_PCT" ]; then
        DRIFT_PCT="?"
    fi
fi

# Parse pre-scan log
if [ -f "$OUTPUT_DIR/pre-scan-log.txt" ]; then
    TOTAL_FILES=$(grep "^Total files:" "$OUTPUT_DIR/pre-scan-log.txt" | head -1 | sed 's/.*: *//' | sed 's/ *$//' || true)
    AI_SURFACES=$(grep "^AI surfaces:" "$OUTPUT_DIR/pre-scan-log.txt" | head -1 | sed 's/.*: *//' | sed 's/ *$//' || true)
fi

# Read scorecard if it exists
SCORECARD_SUMMARY=""
if [ -f "$OUTPUT_DIR/SCORECARD.json" ]; then
    SCORECARD_SUMMARY=$(cat "$OUTPUT_DIR/SCORECARD.json")
fi

FIRED_SIGNATURES_MD="None."
if [ -f "$OUTPUT_DIR/DS-34-plus-results.json" ]; then
    FIRED_SIGNATURES_MD=$(python3 - "$OUTPUT_DIR/DS-34-plus-results.json" <<'PY'
import json
import sys

path = sys.argv[1]
data = json.load(open(path))
rows = []
for item in data.get("results", []):
    if not item.get("fired"):
        continue
    ds_id = item.get("ds_id", "?")
    name = item.get("name", "Unnamed signature")
    severity = item.get("severity", "?")
    evidence = str(item.get("evidence", "")).strip().replace("\n", " ")
    if len(evidence) > 180:
        evidence = evidence[:177] + "..."
    rows.append(f"| {ds_id} | {name} | {severity} | {evidence or 'n/a'} |")

if rows:
    print("| Signature | Name | Severity | Evidence |")
    print("|---|---|---|---|")
    print("\n".join(rows))
else:
    print("None.")
PY
)
fi

REPRESENTATIVENESS_MD="No explicit representativeness authority comparison was requested."
if [ -f "$CONTEXT_MANIFEST" ]; then
    REPRESENTATIVENESS_MD=$(python3 - "$CONTEXT_MANIFEST" <<'PY'
import json
import sys

manifest = json.load(open(sys.argv[1]))
rep = manifest.get("representativeness", {})
if not rep.get("enabled"):
    print("No explicit representativeness authority comparison was requested.")
    raise SystemExit(0)

authority = rep.get("authority_repo_path") or "(missing)"
risks = rep.get("risks") or []
notes = rep.get("notes") or []
if risks:
    print(f"**WARNING:** audited target is not representative of authority repo `{authority}`.")
    print("")
    print("| Risk | Note |")
    print("|---|---|")
    for idx, risk in enumerate(risks):
        note = notes[idx] if idx < len(notes) else ""
        print(f"| {risk} | {note} |")
else:
    print(f"Authority comparison passed for `{authority}`.")
PY
)
fi

cat > "$OUTPUT_DIR/AUDIT_REPORT.md" << EOF
# Audit Report: $REPO_NAME

> Generated by repo-auditor.sh (deterministic)
> Date: $(date +%Y-%m-%d)
> Target: $REPO

## Summary

| Metric | Value |
|---|---|
| Phase | $PHASE |
| Maturity Score | $MATURITY_SCORE |
| Stall Risk | $STALL_SCORE/100 |
| Trajectory | $TRAJECTORY |
| Co-Evolution Ratio | $CO_EVO |
| Drift | $DRIFT_PCT |
| Total Files | $TOTAL_FILES |
| AI Surfaces | $AI_SURFACES |
| Context Manifest | $(basename "$CONTEXT_MANIFEST") |

## Dimension Scorecard

\`\`\`json
$SCORECARD_SUMMARY
\`\`\`

## Score Receipts

- Context manifest: \`$(basename "$CONTEXT_MANIFEST")\`
- Scorer receipts: \`SCORECARD_RECEIPTS.json\`

## Representativeness

$REPRESENTATIVENESS_MD

## Fired High-Signal Detections

$FIRED_SIGNATURES_MD

## Tool Outputs

| Tool | Output File | Status |
|---|---|---|
| context-score manifest | CONTEXT_SCORE_MANIFEST.json | $([ -f "$CONTEXT_MANIFEST" ] && echo "✅" || echo "❌") |
| pre-scan-target.sh | pre-scan/ | $([ -f "$OUTPUT_DIR/pre-scan/PRE_SCAN.md" ] && echo "✅" || echo "❌") |
| classify-repo-maturity.sh | maturity.txt | $([ -s "$OUTPUT_DIR/maturity.txt" ] && echo "✅" || echo "❌") |
| stall-risk-score.sh | stall-risk.txt | $([ -s "$OUTPUT_DIR/stall-risk.txt" ] && echo "✅" || echo "❌") |
| extract-repo-dna.sh | dna.txt | $([ -s "$OUTPUT_DIR/dna.txt" ] && echo "✅" || echo "❌") |
| detect-capability-drift.sh | drift.txt | $([ -s "$OUTPUT_DIR/drift.txt" ] && echo "✅" || echo "❌") |
| detect-new-signatures.sh | DS-34-plus-results.json | $([ -f "$OUTPUT_DIR/DS-34-plus-results.json" ] && echo "✅" || echo "❌") |
| score receipts | SCORECARD_RECEIPTS.json | $([ -f "$OUTPUT_DIR/SCORECARD_RECEIPTS.json" ] && echo "✅" || echo "❌") |

## Failures

$(if [ "$FAIL_COUNT" -eq 0 ]; then echo "None."; else echo "**$FAIL_COUNT tool(s) failed:** $FAILURES"; fi)
EOF

echo "  ✅ AUDIT_REPORT.md written"
echo ""
echo "================================================================"
echo "Audit Complete: $REPO_NAME"
echo "================================================================"
echo "  Phase:          $PHASE"
echo "  Maturity:       $MATURITY_SCORE"
echo "  Stall Risk:     $STALL_SCORE/100"
echo "  Drift:          $DRIFT_PCT"
echo "  Co-Evo Ratio:   $CO_EVO"
echo "  Tool failures:  $FAIL_COUNT"
echo ""
echo "Outputs:"
echo "  $OUTPUT_DIR/AUDIT_REPORT.md"
echo "  $OUTPUT_DIR/SCORECARD.json"
echo "  $OUTPUT_DIR/SCORECARD_RECEIPTS.json"
echo "  $OUTPUT_DIR/CONTEXT_SCORE_MANIFEST.json"
echo "================================================================"

# ── Deep mode: Domain subagent dispatch via copilot CLI (v163) ───────
if [ "$AUDIT_MODE" = "deep" ]; then
    echo ""
    echo "--- Running Deep Mode: Domain Subagent Dispatch ---"
    echo ""

    PAYLOADS_DIR="$OUTPUT_DIR/payloads"
    mkdir -p "$PAYLOADS_DIR"

    AGENTS_DIR="$SCRIPT_DIR/../.agents"
    DEEP_MODEL="${DEEP_MODEL:-claude-sonnet-4.5}"
    DEEP_TIMEOUT="${DEEP_TIMEOUT:-120}"
    _to="timeout"; command -v timeout >/dev/null 2>&1 || _to="gtimeout"
    _has_timeout=false; command -v "$_to" >/dev/null 2>&1 && _has_timeout=true

    # Domain agents to dispatch (6 domains)
    DEEP_DOMAINS="governance surface skill measurement improvement theater"
    DEEP_OK=0
    DEEP_FAIL=0

    for domain in $DEEP_DOMAINS; do
        agent_file="$AGENTS_DIR/${domain}-auditor.agent.md"
        payload_file="$PAYLOADS_DIR/${domain}.md"
        if [ ! -f "$agent_file" ]; then
            echo "  [$domain] SKIP: agent file not found"
            DEEP_FAIL=$((DEEP_FAIL + 1))
            continue
        fi
        echo "  [$domain] dispatching..."
        prompt_text="Read .agents/${domain}-auditor.agent.md for instructions. Audit the target repo at $REPO. Write all findings to stdout in markdown table format."
        dispatch_ok=false
        if [ "$_has_timeout" = true ]; then
            if (cd "$SCRIPT_DIR/.." && $_to "$DEEP_TIMEOUT" copilot --model "$DEEP_MODEL" \
                -p "$prompt_text" --allow-all --no-ask-user < /dev/null > "$payload_file" 2>/dev/null); then
                dispatch_ok=true
            fi
        else
            if (cd "$SCRIPT_DIR/.." && copilot --model "$DEEP_MODEL" \
                -p "$prompt_text" --allow-all --no-ask-user < /dev/null > "$payload_file" 2>/dev/null); then
                dispatch_ok=true
            fi
        fi
        if [ "$dispatch_ok" = true ] && [ -s "$payload_file" ]; then
            echo "  [$domain] done ($(wc -l < "$payload_file" | tr -d ' ') lines)"
            DEEP_OK=$((DEEP_OK + 1))
        else
            echo "  [$domain] FAILED"
            DEEP_FAIL=$((DEEP_FAIL + 1))
        fi
    done

    echo ""
    echo "  Domain dispatch: $DEEP_OK OK, $DEEP_FAIL failed"

    # Synthesis: combine domain findings into deep audit summary
    if [ "$DEEP_OK" -gt 0 ]; then
        echo ""
        echo "  [synthesis] combining domain findings..."
        synth_prompt="Read .agents/audit-synthesis.agent.md for instructions. Combine all domain audit payloads in $OUTPUT_DIR/payloads/ into a unified deep audit summary. Write a JSON summary to stdout with total_findings and findings_by_severity."
        synth_ok=false
        if [ "$_has_timeout" = true ]; then
            if (cd "$SCRIPT_DIR/.." && $_to "$DEEP_TIMEOUT" copilot --model claude-opus-4.6 \
                -p "$synth_prompt" --allow-all --no-ask-user < /dev/null > "$OUTPUT_DIR/DEEP_FINDINGS.json" 2>/dev/null); then
                synth_ok=true
            fi
        else
            if (cd "$SCRIPT_DIR/.." && copilot --model claude-opus-4.6 \
                -p "$synth_prompt" --allow-all --no-ask-user < /dev/null > "$OUTPUT_DIR/DEEP_FINDINGS.json" 2>/dev/null); then
                synth_ok=true
            fi
        fi
        if [ "$synth_ok" = true ] && [ -s "$OUTPUT_DIR/DEEP_FINDINGS.json" ]; then
            echo "  [synthesis] done"
            # Append deep findings summary to AUDIT_REPORT.md
            DEEP_COUNT=$(python3 -c "import json; d=json.load(open('$OUTPUT_DIR/DEEP_FINDINGS.json')); print(d.get('total_findings',0))" 2>/dev/null || echo "$DEEP_OK domains")
            DEEP_HIGH=$(python3 -c "import json; d=json.load(open('$OUTPUT_DIR/DEEP_FINDINGS.json')); print(d.get('findings_by_severity',{}).get('HIGH',0))" 2>/dev/null || echo "?")
            printf '\n## Deep Semantic Analysis\n\n| Metric | Value |\n|---|---|\n| Mode | deep |\n| Domains dispatched | %s/%s |\n| Total findings | %s |\n| HIGH severity | %s |\n\nSee DEEP_FINDINGS.json and payloads/ for full details.\n' \
                "$DEEP_OK" "6" "$DEEP_COUNT" "$DEEP_HIGH" >> "$OUTPUT_DIR/AUDIT_REPORT.md"
        else
            echo "  [synthesis] FAILED (domain payloads still available in payloads/)"
        fi
    fi
fi

# ── C1: Runtime evaluation of audit quality (Stage 11.2) ─────────────
EVAL_SCRIPT="$SCRIPT_DIR/score-operation.sh"
if [ -x "$EVAL_SCRIPT" ]; then
    echo ""
    bash "$EVAL_SCRIPT" "$OUTPUT_DIR" || true
    # Also produce JSON artifact alongside audit outputs
    bash "$EVAL_SCRIPT" "$OUTPUT_DIR" --json > "$OUTPUT_DIR/OPERATION_EVAL.json" 2>/dev/null || true
fi

# Lockfile cleanup handled by trap EXIT (set at lock acquisition)

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
