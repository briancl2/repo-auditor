#!/usr/bin/env bash
# scripts/score-operation.sh — Runtime evaluation of audit quality (C1: Runtime Eval)
#
# Evaluates the QUALITY of a completed audit operation — not whether it ran,
# but whether the output was complete, correct, and useful.
#
# This complements score-session.sh (which measures session PROCESS: hypothesis,
# gates, learnings) by measuring operational OUTPUT QUALITY (dimension coverage,
# detection signature hit rate, data completeness, consistency).
#
# Usage: bash scripts/score-operation.sh <audit_output_dir> [--json]
#
# Checks (9 total, 22 points max):
#   1. SCORECARD.json exists and valid (3pt)
#   2. All 5 dimensions scored (not null/0) (3pt)
#   3. AUDIT_REPORT.md exists and non-trivial (2pt)
#   4. All 5 tool outputs present (3pt)
#   5. Detection signature coverage (2pt)
#   6. No fallback/timeout indicators (2pt)
#   7. SCORECARD composite in valid range (2pt)
#   8. Phase classification present and non-empty (3pt)
#   9. Command-output ROI (avoid copying raw command dumps into governed audit artifacts) (2pt)
#
# Exit codes:
#   0 — evaluation complete (score in stdout)
#   1 — missing inputs
#
# Source: Stage 11.1 T8 pattern audit (C1). Addresses fleet gap:
#   "Fleet repos have score-session.sh (22-point session grader) but this measures
#    session PROCESS, not operational OUTPUT QUALITY."

set -euo pipefail

AUDIT_DIR="${1:?Usage: score-operation.sh <audit_output_dir> [--json]}"
JSON_MODE="false"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for arg in "$@"; do
    if [ "$arg" = "--json" ]; then JSON_MODE="true"; fi
done

if [ ! -d "$AUDIT_DIR" ]; then
    echo "ERROR: Audit output directory not found: $AUDIT_DIR" >&2
    exit 1
fi

SCORE=0
MAX=22
ISSUES=""
EVIDENCE=""
COMMAND_OUTPUT_RC=0
COMMAND_OUTPUT_VIOLATIONS_JSON="[]"
COMMAND_OUTPUT_ROI_RECEIPT="{}"

add_score() {
    local pts="$1"
    local label="$2"
    SCORE=$((SCORE + pts))
    EVIDENCE="${EVIDENCE}  +${pts}pt: $label\n"
}

add_issue() {
    local label="$1"
    ISSUES="${ISSUES}  - $label\n"
}

detect_command_output_noise() {
    python3 - "$AUDIT_DIR" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
raw_line = re.compile(
    r"^\s*(?:PASS|FAIL|WARN|ERROR|INFO):\s+|"
    r"^\s*(?:ok|not ok)\s+\d+\b|"
    r"^\s*(?:[+>$])\s*(?:make|bash|python3|git|npm|node|pytest|copilot)\b|"
    r"^\s*(?:npm ERR!|make(?:\[\d+\])?:|Traceback\b|File \".*\", line \d+)",
    re.IGNORECASE,
)


def raw_count(lines):
    return sum(1 for line in lines if raw_line.search(line))


def longest_raw_run(lines):
    longest = 0
    current = 0
    for line in lines:
        if raw_line.search(line):
            current += 1
            longest = max(longest, current)
        else:
            current = 0
    return longest


def add_violation(violations, artifact, location, reason, lines):
    violations.append(
        {
            "artifact": artifact,
            "location": location,
            "reason": reason,
            "raw_line_count": raw_count(lines),
            "longest_raw_run": longest_raw_run(lines),
        }
    )


def inspect_lines(artifact, lines):
    violations = []
    total = raw_count(lines)
    run = longest_raw_run(lines)
    if run >= 12:
        add_violation(
            violations,
            artifact,
            None,
            "governed artifact has consecutive raw-looking command output lines",
            lines,
        )
    elif total >= 30:
        add_violation(
            violations,
            artifact,
            None,
            "governed artifact has excessive raw-looking command output lines",
            lines,
        )

    in_fence = False
    fence_lines = []
    for line in lines + ["```"]:
        if line.startswith("```"):
            if in_fence:
                if longest_raw_run(fence_lines) >= 12 or raw_count(fence_lines) >= 20:
                    add_violation(
                        violations,
                        artifact,
                        "fenced block",
                        "governed artifact copied a raw command transcript block",
                        fence_lines,
                    )
                    break
                fence_lines = []
                in_fence = False
            else:
                in_fence = True
                fence_lines = []
            continue
        if in_fence:
            fence_lines.append(line)
    return violations


def iter_json_strings(value, prefix="$"):
    if isinstance(value, str):
        yield prefix, value
    elif isinstance(value, list):
        for index, item in enumerate(value):
            yield from iter_json_strings(item, f"{prefix}[{index}]")
    elif isinstance(value, dict):
        for key, item in value.items():
            yield from iter_json_strings(item, f"{prefix}.{key}")


violations = []
for label, path in (
    ("AUDIT_REPORT.md", root / "AUDIT_REPORT.md"),
    ("pre-scan/PRE_SCAN.md", root / "pre-scan" / "PRE_SCAN.md"),
    ("maturity.txt", root / "maturity.txt"),
    ("stall-risk.txt", root / "stall-risk.txt"),
    ("dna.txt", root / "dna.txt"),
    ("drift.txt", root / "drift.txt"),
):
    if path.is_file():
        violations.extend(
            inspect_lines(label, path.read_text(encoding="utf-8", errors="replace").splitlines())
        )

for name in ("SCORECARD.json", "DEEP_FINDINGS.json", "DS-34-plus-results.json"):
    path = root / name
    if not path.is_file():
        continue
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        continue
    total_raw_lines = 0
    for pointer, text in iter_json_strings(payload):
        lines = text.splitlines()
        total_raw_lines += raw_count(lines)
        if longest_raw_run(lines) >= 12 or raw_count(lines) >= 20:
            add_violation(
                violations,
                path.name,
                pointer,
                "governed machine artifact contains a raw-looking command transcript string",
                lines,
            )
    if total_raw_lines >= 30:
        violations.append(
            {
                "artifact": path.name,
                "location": "all string values",
                "reason": "governed machine artifact contains excessive raw-looking command lines across string values",
                "raw_line_count": total_raw_lines,
                "longest_raw_run": None,
            }
        )

print(json.dumps(violations))
raise SystemExit(1 if violations else 0)
PY
}

build_command_output_roi_receipt() {
    AUDIT_DIR="$AUDIT_DIR" \
    COMMAND_OUTPUT_RC="$COMMAND_OUTPUT_RC" \
    COMMAND_OUTPUT_VIOLATIONS_JSON="$COMMAND_OUTPUT_VIOLATIONS_JSON" \
    python3 - <<'PY'
import datetime as _dt
import json
import os
import pathlib

try:
    violations = json.loads(os.environ.get("COMMAND_OUTPUT_VIOLATIONS_JSON") or "[]")
except Exception:
    violations = [
        {
            "artifact": "unknown",
            "location": None,
            "reason": "command-output ROI detector returned malformed violation output",
            "raw_line_count": None,
            "longest_raw_run": None,
        }
    ]

failed = os.environ.get("COMMAND_OUTPUT_RC") != "0"
root = pathlib.Path(os.environ["AUDIT_DIR"])


def governed(path, artifact_class):
    return {
        "path": path,
        "artifact_class": artifact_class,
        "scanned": (root / path).is_file(),
    }


governed_artifacts = [
    governed("AUDIT_REPORT.md", "human_report"),
    governed("pre-scan/PRE_SCAN.md", "human_report"),
    governed("maturity.txt", "other_governed"),
    governed("stall-risk.txt", "other_governed"),
    governed("dna.txt", "other_governed"),
    governed("drift.txt", "other_governed"),
    governed("SCORECARD.json", "machine_summary"),
    governed("DEEP_FINDINGS.json", "machine_summary"),
    governed("DS-34-plus-results.json", "machine_summary"),
]
if not any(row["scanned"] for row in governed_artifacts):
    violations = [
        {
            "artifact": "governed_artifacts",
            "location": None,
            "reason": "no governed audit artifacts were present to scan",
            "raw_line_count": None,
            "longest_raw_run": None,
        }
    ]
    verdict = "not-measured"
    raw_transcript_detected = False
else:
    verdict = "fail" if failed else "pass"
    raw_transcript_detected = failed

payload = {
    "generated_at": _dt.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    "schema_version": "1.0.0",
    "artifact": "COMMAND_OUTPUT_ROI_RECEIPT",
    "receipt_id": "repo-auditor-command-output-roi",
    "source_benchmark": {
        "tactic_id": "command_output_roi",
        "promotion_scope": "fleet-portable",
        "evidence_ref": "build-meta-analysis:research/reports/provider-neutral-tier3-live-paired-benchmark-2026-04-26.md",
    },
    "owner_surface": {
        "repo": "repo-auditor",
        "runtime_surface": "scripts/score-operation.sh",
        "mode": "standard/deep audit output evaluation",
    },
    "governed_artifacts": governed_artifacts,
    "allowed_raw_receipt_artifacts": [
        "SCORECARD_RECEIPTS.json",
        "pre-scan-log.txt",
        "*.jsonl",
        "*RECEIPT*.md",
    ],
    "verdict": verdict,
    "raw_transcript_detected": raw_transcript_detected,
    "violations": violations,
    "policy": {
        "summary_required": True,
        "raw_logs_allowed_in": ["receipt artifacts", "stdout/stderr logs", "raw jsonl transcripts"],
        "direct_metric_claim": False,
        "cache_claim": False,
    },
    "bounded_non_claims": [
        "This receipt does not prove cache savings.",
        "This receipt does not promote provider-scoped prompt/context tactics.",
        "This receipt does not authorize target-repo mutation.",
    ],
}
print(json.dumps(payload, separators=(",", ":")))
PY
}

# ── Check 1: SCORECARD.json exists and valid JSON (3pt) ──────────────
SCORECARD="$AUDIT_DIR/SCORECARD.json"
if [ -f "$SCORECARD" ]; then
    if python3 -c "import json; json.load(open('$SCORECARD'))" 2>/dev/null; then
        add_score 3 "SCORECARD.json exists and valid JSON"
    else
        add_score 1 "SCORECARD.json exists but invalid JSON"
        add_issue "SCORECARD.json is not valid JSON"
    fi
else
    add_issue "SCORECARD.json missing"
fi

# ── Check 2: All 5 dimensions scored (3pt) ───────────────────────────
if [ -f "$SCORECARD" ]; then
    DIMS_SCORED=$(python3 -c "
import json, sys
try:
    sc = json.load(open('$SCORECARD'))
    dims = sc.get('dimensions', {})
    scored = sum(1 for v in dims.values() if v is not None and v != 0)
    print(scored)
except:
    print(0)
" 2>/dev/null || echo "0")
    if [ "$DIMS_SCORED" -ge 5 ]; then
        add_score 3 "All 5 dimensions scored ($DIMS_SCORED/5)"
    elif [ "$DIMS_SCORED" -ge 3 ]; then
        add_score 1 "Partial dimensions scored ($DIMS_SCORED/5)"
        add_issue "Only $DIMS_SCORED/5 dimensions have non-zero scores"
    else
        add_issue "Too few dimensions scored ($DIMS_SCORED/5)"
    fi
fi

# ── Check 3: AUDIT_REPORT.md exists and non-trivial (2pt) ────────────
REPORT="$AUDIT_DIR/AUDIT_REPORT.md"
if [ -f "$REPORT" ]; then
    REPORT_LINES=$(wc -l < "$REPORT" | tr -d ' ')
    if [ "$REPORT_LINES" -ge 20 ]; then
        add_score 2 "AUDIT_REPORT.md exists ($REPORT_LINES lines)"
    else
        add_score 1 "AUDIT_REPORT.md exists but sparse ($REPORT_LINES lines)"
        add_issue "AUDIT_REPORT.md is sparse ($REPORT_LINES lines, expect >=20)"
    fi
else
    add_issue "AUDIT_REPORT.md missing"
fi

# ── Check 4: All 5 tool outputs present (3pt) ────────────────────────
TOOL_FILES="pre-scan/PRE_SCAN.md maturity.txt stall-risk.txt dna.txt drift.txt"
TOOLS_FOUND=0
TOOLS_MISSING=""
for f in $TOOL_FILES; do
    if [ -f "$AUDIT_DIR/$f" ]; then
        TOOLS_FOUND=$((TOOLS_FOUND + 1))
    else
        TOOLS_MISSING="$TOOLS_MISSING $f"
    fi
done
if [ "$TOOLS_FOUND" -eq 5 ]; then
    add_score 3 "All 5 tool outputs present"
elif [ "$TOOLS_FOUND" -ge 3 ]; then
    add_score 1 "Partial tool outputs ($TOOLS_FOUND/5)"
    add_issue "Missing tool outputs:$TOOLS_MISSING"
else
    add_issue "Most tool outputs missing ($TOOLS_FOUND/5):$TOOLS_MISSING"
fi

# ── Check 5: Detection signature coverage (2pt) ──────────────────────
# Count how many detect-*.sh scripts are available and how many produced results
DS_SCRIPTS=$(find "$SCRIPT_DIR" -maxdepth 1 -name 'detect-*.sh' -type f 2>/dev/null | wc -l | tr -d ' ')
DS_RESULTS=0
if [ -d "$AUDIT_DIR/pre-scan" ]; then
    DS_RESULTS=$(find "$AUDIT_DIR" -name 'ds-*.json' -o -name 'DS-*.json' -o -name 'detect-*.txt' 2>/dev/null | wc -l | tr -d ' ')
fi
# Also check AUDIT_REPORT for detection signatures or SCORECARD
if [ -f "$SCORECARD" ]; then
    DS_IN_SCORECARD=$(python3 -c "
import json
try:
    sc = json.load(open('$SCORECARD'))
    findings = sc.get('detection_findings', sc.get('findings', []))
    print(len(findings) if isinstance(findings, list) else 0)
except:
    print(0)
" 2>/dev/null || echo "0")
    DS_RESULTS=$((DS_RESULTS + DS_IN_SCORECARD))
fi
if [ "$DS_SCRIPTS" -gt 0 ] && [ "$DS_RESULTS" -gt 0 ]; then
    add_score 2 "Detection signatures ran ($DS_RESULTS results from $DS_SCRIPTS scripts)"
elif [ "$DS_SCRIPTS" -eq 0 ]; then
    add_score 1 "No detection signature scripts found (skip)"
else
    add_issue "Detection signatures available ($DS_SCRIPTS scripts) but 0 results produced"
fi

# ── Check 6: No fallback/timeout indicators (2pt) ────────────────────
FALLBACK_SIGNALS=0
if grep -qi 'timeout\|fallback\|timed out\|TIMEOUT' "$AUDIT_DIR"/*.txt "$AUDIT_DIR"/*.md 2>/dev/null; then
    FALLBACK_SIGNALS=$((FALLBACK_SIGNALS + 1))
fi
if grep -qi 'error.*tool\|tool.*failed\|FAIL.*tool' "$AUDIT_DIR"/*.md 2>/dev/null; then
    FALLBACK_SIGNALS=$((FALLBACK_SIGNALS + 1))
fi
if [ "$FALLBACK_SIGNALS" -eq 0 ]; then
    add_score 2 "No fallback or timeout indicators"
else
    add_score 1 "Fallback/timeout indicators detected ($FALLBACK_SIGNALS signals)"
    add_issue "Fallback or timeout detected in audit artifacts"
fi

# ── Check 7: SCORECARD composite in valid range 1-100 (2pt) ──────────
if [ -f "$SCORECARD" ]; then
    COMPOSITE=$(python3 -c "
import json
try:
    sc = json.load(open('$SCORECARD'))
    print(sc.get('composite', sc.get('composite_score', -1)))
except:
    print(-1)
" 2>/dev/null || echo "-1")
    if [ "$COMPOSITE" -ge 1 ] 2>/dev/null && [ "$COMPOSITE" -le 100 ] 2>/dev/null; then
        add_score 2 "Composite score valid ($COMPOSITE/100)"
    else
        add_issue "Composite score out of range: $COMPOSITE"
    fi
fi

# ── Check 8: Phase classification present (3pt) ──────────────────────
MATURITY="$AUDIT_DIR/maturity.txt"
if [ -f "$MATURITY" ]; then
    PHASE=$(grep -oiE '(Phase|PHASE)[: ]+[0-5]' "$MATURITY" 2>/dev/null | head -1 || echo "")
    if [ -n "$PHASE" ]; then
        add_score 3 "Phase classification present ($PHASE)"
    else
        add_score 1 "maturity.txt exists but no Phase classification found"
        add_issue "Phase classification missing from maturity.txt"
    fi
else
    add_issue "maturity.txt missing (no phase classification)"
fi

# ── Check 9 (bonus): Deep findings present (Stage 11.3) ──────────────
DEEP_FILE="$AUDIT_DIR/DEEP_FINDINGS.json"
if [ -f "$DEEP_FILE" ]; then
    DEEP_COUNT=$(python3 -c "import json; print(json.load(open('$DEEP_FILE'))['total_findings'])" 2>/dev/null || echo "0")
    DEEP_HIGH=$(python3 -c "import json; print(json.load(open('$DEEP_FILE'))['findings_by_severity']['HIGH'])" 2>/dev/null || echo "0")
    if [ "$DEEP_COUNT" -gt 0 ] 2>/dev/null; then
        EVIDENCE="${EVIDENCE}  [deep] Deep semantic analysis: $DEEP_COUNT findings ($DEEP_HIGH HIGH)\n"
    fi
fi

# ── Check 9: Command-output ROI (2pt) ────────────────────────────────
set +e
COMMAND_OUTPUT_VIOLATIONS_JSON="$(detect_command_output_noise 2>/dev/null)"
COMMAND_OUTPUT_RC=$?
set -e
COMMAND_OUTPUT_ROI_RECEIPT="$(build_command_output_roi_receipt)"
COMMAND_OUTPUT_SCANNED_COUNT="$(
    COMMAND_OUTPUT_ROI_RECEIPT="$COMMAND_OUTPUT_ROI_RECEIPT" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ.get("COMMAND_OUTPUT_ROI_RECEIPT") or "{}")
print(sum(1 for row in payload.get("governed_artifacts", []) if row.get("scanned") is True))
PY
)"
if [ "$COMMAND_OUTPUT_RC" -eq 0 ] && [ "$COMMAND_OUTPUT_SCANNED_COUNT" -gt 0 ]; then
    add_score 2 "Command output summarized instead of copied as raw dumps"
elif [ "$COMMAND_OUTPUT_SCANNED_COUNT" -eq 0 ]; then
    add_issue "Command-output ROI not measured: no governed audit artifacts were present to scan"
else
    COMMAND_OUTPUT_SUMMARY="$(
        COMMAND_OUTPUT_VIOLATIONS_JSON="$COMMAND_OUTPUT_VIOLATIONS_JSON" python3 - <<'PY'
import json
import os

try:
    rows = json.loads(os.environ.get("COMMAND_OUTPUT_VIOLATIONS_JSON") or "[]")
except Exception:
    rows = []
print("; ".join(f"{row.get('artifact')}: {row.get('reason')}" for row in rows) or "raw command transcript detected")
PY
    )"
    add_issue "Command-output ROI violation: summarize command evidence and retain raw logs separately ($COMMAND_OUTPUT_SUMMARY)"
fi

# ── Output ────────────────────────────────────────────────────────────
if [ "$JSON_MODE" = "true" ]; then
    # Output JSON for machine consumption
    ISSUES_JSON=$(printf '%b' "$ISSUES" | sed 's/^  - //' | python3 -c "
import sys, json
lines = [l.strip() for l in sys.stdin if l.strip()]
print(json.dumps(lines))
" 2>/dev/null || echo '[]')
    VERDICT="PASS"
    if [ "$SCORE" -lt 16 ]; then VERDICT="FAIL"; fi
    if [ "$SCORE" -ge 16 ] && [ "$SCORE" -lt 20 ]; then VERDICT="WARN"; fi
    if [ "${COMMAND_OUTPUT_RC:-0}" -ne 0 ]; then VERDICT="FAIL"; fi

    COMMAND_OUTPUT_ROI_RECEIPT="$COMMAND_OUTPUT_ROI_RECEIPT" python3 -c "
import json, os, sys
result = {
    'score': $SCORE,
    'max': $MAX,
    'verdict': '$VERDICT',
    'audit_dir': '$AUDIT_DIR',
    'issues': $ISSUES_JSON,
    'command_output_roi_receipt': json.loads(os.environ.get('COMMAND_OUTPUT_ROI_RECEIPT') or '{}'),
    'timestamp': __import__('datetime').datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
}
json.dump(result, sys.stdout, indent=2)
print()
"
else
    echo "OPERATION EVAL: Audit Quality Assessment"
    echo "  Audit dir: $AUDIT_DIR"
    echo ""
    printf "%b" "$EVIDENCE"
    if [ -n "$ISSUES" ]; then
        echo ""
        echo "Issues detected (session grader would miss these):"
        printf "%b" "$ISSUES"
    fi
    echo ""
    VERDICT="PASS"
    if [ "$SCORE" -lt 16 ]; then VERDICT="FAIL"; fi
    if [ "$SCORE" -ge 16 ] && [ "$SCORE" -lt 20 ]; then VERDICT="WARN"; fi
    if [ "${COMMAND_OUTPUT_RC:-0}" -ne 0 ]; then VERDICT="FAIL"; fi
    echo "OPERATION EVAL: $SCORE/$MAX ($VERDICT)"
    if [ "$VERDICT" = "FAIL" ]; then
        echo "  NOTE: Score below 16/$MAX threshold or command-output ROI failed. Audit output quality is degraded."
    fi
fi

exit 0
