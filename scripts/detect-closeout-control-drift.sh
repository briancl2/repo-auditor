#!/usr/bin/env bash
# detect-closeout-control-drift.sh — DS-44: Stage 15 closeout-control drift detection
# Fires when work contracts with Stage 15-style closeout controls drift on:
#   1. disposition retention (review/critique receipt present, disposition missing)
#   2. helper authority binding (helper metadata mismatches reconciliation artifact)
#   3. telemetry structural sanity (negative values or inconsistent totals)
#   4. pointer closure duplication (GitHub pointer closure coexists with duplicate local closeout truth)
#
# Usage: bash scripts/detect-closeout-control-drift.sh <repo_path>
#
# This detector is intentionally bounded to repos that use work/ contracts and
# Stage 15-style closeout artifacts. If none are present, the DS is not
# applicable and returns a non-firing JSON result.

set -euo pipefail

REPO="${1:?Usage: detect-closeout-control-drift.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

fired=false
work_dirs_scanned=0
pointer_closure_dirs_scanned=0
disposition_gap_count=0
helper_drift_count=0
telemetry_anomaly_count=0
pointer_duplicate_truth_count=0
evidence=""

declare -a POINTER_DUPLICATE_SURFACES=(
    "completion-manifest.json"
    "completion-manifest.md"
    "handoff-sync-facts.json"
    "closeout-disposition.json"
    "closeout-reconciliation.json"
    "closeout-telemetry.json"
    "session-end-review.md"
    "ask-reconciliation.md"
)

append_evidence() {
    local fragment="$1"
    if [ -z "$fragment" ]; then
        return 0
    fi
    if [ -n "$evidence" ]; then
        evidence="${evidence}; "
    fi
    evidence="${evidence}${fragment}"
}

check_helper_binding() {
    local reconciliation_path="$1"
    local helper_path="$2"
    local helper_key="$3"
    python3 - "$reconciliation_path" "$helper_path" "$helper_key" <<'PY'
import json
import pathlib
import sys

reconciliation_path, helper_path, helper_key = sys.argv[1:4]

try:
    reconciliation = json.load(open(reconciliation_path))
    helper = json.load(open(helper_path))
except Exception as exc:
    print(f"{pathlib.Path(helper_path).name}: unreadable ({exc})")
    sys.exit(1)

expected = reconciliation.get("helper_outputs", {}).get(helper_key)
if not isinstance(expected, dict):
    print(f"{pathlib.Path(helper_path).name}: helper output missing from reconciliation artifact")
    sys.exit(1)

if helper.get("canonicality") != expected.get("canonicality"):
    print(f"{pathlib.Path(helper_path).name}: canonicality mismatch")
    sys.exit(1)

if helper.get("oracle_binding") != expected.get("oracle_binding"):
    print(f"{pathlib.Path(helper_path).name}: oracle_binding mismatch")
    sys.exit(1)
PY
}

check_telemetry_sanity() {
    local telemetry_path="$1"
    python3 - "$telemetry_path" <<'PY'
import json
import pathlib
import sys

telemetry_path = sys.argv[1]

try:
    data = json.load(open(telemetry_path))
except Exception as exc:
    print(f"{pathlib.Path(telemetry_path).name}: unreadable ({exc})")
    sys.exit(1)

required_lists = {
    "payload_paths": list,
    "session_sources": list,
}
required_dicts = {
    "phase_timestamps": dict,
    "summary": dict,
}
required_nonnegative = [
    "closeout_window_seconds",
    "active_closeout_seconds",
    "inactive_gap_seconds",
    "artifact_payload_bytes",
    "compaction_count",
]

for key, expected_type in required_lists.items():
    value = data.get(key)
    if not isinstance(value, expected_type):
        print(f"{pathlib.Path(telemetry_path).name}: {key} missing or wrong type")
        sys.exit(1)

for key, expected_type in required_dicts.items():
    value = data.get(key)
    if not isinstance(value, expected_type):
        print(f"{pathlib.Path(telemetry_path).name}: {key} missing or wrong type")
        sys.exit(1)

for key in required_nonnegative:
    value = data.get(key)
    if not isinstance(value, int) or value < 0:
        print(f"{pathlib.Path(telemetry_path).name}: {key} missing or negative")
        sys.exit(1)

window_seconds = data["closeout_window_seconds"]
active_seconds = data["active_closeout_seconds"]
inactive_seconds = data["inactive_gap_seconds"]
if active_seconds + inactive_seconds > window_seconds:
    print(f"{pathlib.Path(telemetry_path).name}: active+inactive exceeds closeout window")
    sys.exit(1)

summary = data["summary"]
payload_total = summary.get("payload_files_total")
phase_total = summary.get("phase_timestamps_total")
source_total = summary.get("session_sources_total")

if payload_total != len(data["payload_paths"]):
    print(f"{pathlib.Path(telemetry_path).name}: payload_files_total mismatch")
    sys.exit(1)
if phase_total != len(data["phase_timestamps"]):
    print(f"{pathlib.Path(telemetry_path).name}: phase_timestamps_total mismatch")
    sys.exit(1)
if source_total != len(data["session_sources"]):
    print(f"{pathlib.Path(telemetry_path).name}: session_sources_total mismatch")
    sys.exit(1)

source_compactions = 0
for source in data["session_sources"]:
    source_compaction = source.get("compaction_count")
    matching_events = source.get("matching_event_count")
    if not isinstance(source_compaction, int) or source_compaction < 0:
        print(f"{pathlib.Path(telemetry_path).name}: session source compaction_count missing or negative")
        sys.exit(1)
    if not isinstance(matching_events, int) or matching_events < 0:
        print(f"{pathlib.Path(telemetry_path).name}: matching_event_count missing or negative")
        sys.exit(1)
    source_compactions += source_compaction

if source_compactions != data["compaction_count"]:
    print(f"{pathlib.Path(telemetry_path).name}: compaction_count mismatch")
    sys.exit(1)
PY
}

if [ ! -d "$REPO/work" ]; then
    python3 "$SCRIPT_DIR/ds_json_helper.py" \
        '{"ds_id":"DS-44","name":"Closeout control drift","severity":"HIGH","prevention_tier":"T1"}' \
        "fired=false" \
        "work_dirs_scanned=0" \
        "pointer_closure_dirs_scanned=0" \
        "disposition_gap_count=0" \
        "helper_drift_count=0" \
        "telemetry_anomaly_count=0" \
        "pointer_duplicate_truth_count=0" \
        "evidence=No work/ directory found - DS not applicable"
    exit 0
fi

for work_dir in "$REPO"/work/*/; do
    [ -d "$work_dir" ] || continue

    dir_name=$(basename "$work_dir")
    has_review=false
    has_critique=false
    has_disposition=false
    has_reconciliation=false
    has_telemetry=false
    has_pointer_closure=false
    has_stage15_surface=false

    [ -f "$work_dir/review-receipt.json" ] && has_review=true
    [ -f "$work_dir/critique-receipt.json" ] && has_critique=true
    [ -f "$work_dir/closeout-disposition.json" ] && has_disposition=true
    [ -f "$work_dir/closeout-reconciliation.json" ] && has_reconciliation=true
    [ -f "$work_dir/closeout-telemetry.json" ] && has_telemetry=true
    [ -f "$work_dir/github-campaign-pointer.json" ] && has_pointer_closure=true

    if [ "$has_review" = true ] || [ "$has_critique" = true ] || [ "$has_disposition" = true ] || [ "$has_reconciliation" = true ] || [ "$has_telemetry" = true ]; then
        has_stage15_surface=true
    fi

    if [ "$has_stage15_surface" = false ] && [ "$has_pointer_closure" = false ]; then
        continue
    fi

    work_dirs_scanned=$((work_dirs_scanned + 1))

    if [ "$has_pointer_closure" = true ]; then
        pointer_closure_dirs_scanned=$((pointer_closure_dirs_scanned + 1))
        duplicate_surfaces=()
        for duplicate_surface in "${POINTER_DUPLICATE_SURFACES[@]}"; do
            if [ -f "$work_dir/$duplicate_surface" ]; then
                duplicate_surfaces+=("$duplicate_surface")
            fi
        done
        if [ "${#duplicate_surfaces[@]}" -gt 0 ]; then
            pointer_duplicate_truth_count=$((pointer_duplicate_truth_count + 1))
            append_evidence "${dir_name}: github-campaign-pointer.json present with duplicate local closeout truth (${duplicate_surfaces[*]})"
        fi
    fi

    if [ "$has_stage15_surface" = false ]; then
        continue
    fi

    if [ "$has_disposition" = false ] && { [ "$has_review" = true ] || [ "$has_critique" = true ]; }; then
        disposition_gap_count=$((disposition_gap_count + 1))
        append_evidence "${dir_name}: review/critique receipt present but closeout-disposition.json missing"
    fi

    reconciliation_path="$work_dir/closeout-reconciliation.json"
    for pair in "measurement-summary.json:measurement_summary" "ser-effectivity.json:ser_effectivity"; do
        helper_file="${pair%%:*}"
        helper_key="${pair##*:}"
        helper_path="$work_dir/$helper_file"
        if [ ! -f "$helper_path" ]; then
            continue
        fi

        if [ "$has_reconciliation" = false ]; then
            helper_drift_count=$((helper_drift_count + 1))
            append_evidence "${dir_name}: ${helper_file} present without closeout-reconciliation.json"
            continue
        fi

        helper_message=""
        if ! helper_message=$(check_helper_binding "$reconciliation_path" "$helper_path" "$helper_key" 2>&1); then
            helper_drift_count=$((helper_drift_count + 1))
            append_evidence "${dir_name}: ${helper_message}"
        fi
    done

    if [ "$has_telemetry" = true ]; then
        telemetry_message=""
        if ! telemetry_message=$(check_telemetry_sanity "$work_dir/closeout-telemetry.json" 2>&1); then
            telemetry_anomaly_count=$((telemetry_anomaly_count + 1))
            append_evidence "${dir_name}: ${telemetry_message}"
        fi
    fi
done

if [ "$work_dirs_scanned" -eq 0 ]; then
    append_evidence "No Stage 15 closeout-control surfaces or pointer-closed work found in work/"
fi

if [ "$disposition_gap_count" -gt 0 ] || [ "$helper_drift_count" -gt 0 ] || [ "$telemetry_anomaly_count" -gt 0 ] || [ "$pointer_duplicate_truth_count" -gt 0 ]; then
    fired=true
fi

python3 "$SCRIPT_DIR/ds_json_helper.py" \
    '{"ds_id":"DS-44","name":"Closeout control drift","severity":"HIGH","prevention_tier":"T1"}' \
    "fired=$fired" \
    "work_dirs_scanned=$work_dirs_scanned" \
    "pointer_closure_dirs_scanned=$pointer_closure_dirs_scanned" \
    "disposition_gap_count=$disposition_gap_count" \
    "helper_drift_count=$helper_drift_count" \
    "telemetry_anomaly_count=$telemetry_anomaly_count" \
    "pointer_duplicate_truth_count=$pointer_duplicate_truth_count" \
    "evidence=$evidence"
