#!/usr/bin/env bash
# detect-new-signatures.sh — Unified runner for DS-34+
# Runs the extended post-DS-33 signatures and outputs a combined JSON report.
# Usage: bash scripts/detect-new-signatures.sh <repo_path> [output_dir]
#
# Each signature runs under a per-signature wall-clock budget
# (DS_SWEEP_SIGNATURE_TIMEOUT_SECONDS, default 60) so a single slow or hung
# detector on a large repo can never stall the whole sweep. Progress and
# elapsed time are emitted per signature so a slow sweep is distinguishable
# from a true hang, and a signature that exceeds its budget is recorded as a
# fail-fast diagnostic result (which signature, why, elapsed) rather than
# blocking scorecard generation.
set -euo pipefail
REPO="${1:?Usage: detect-new-signatures.sh <repo_path> [output_dir]}"
OUTPUT_DIR="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SIGNATURE_TIMEOUT="${DS_SWEEP_SIGNATURE_TIMEOUT_SECONDS:-60}"

if [ ! -d "$REPO" ]; then
    echo "ERROR: $REPO not a directory" >&2
    exit 1
fi

TMPDIR_DS=$(mktemp -d)
trap 'rm -rf "$TMPDIR_DS"' EXIT

echo "=== DS-34+: $(basename "$REPO") ===" >&2

scripts=(
    "detect-stale-todos.sh"
    "detect-unused-deps.sh"
    "detect-green-only-ci.sh"
    "detect-readme-drift.sh"
    "detect-config-proliferation.sh"
    "detect-silent-errors.sh"
    "detect-commit-entropy.sh"
    "detect-test-theater.sh"
    "detect-broken-links.sh"
    "detect-velocity-bypass.sh"
    "detect-closeout-control-drift.sh"
    "detect-workflow-contract-drift.sh"
    "detect-llm-validation-gap.sh"
    "detect-summary-source-parity-gap.sh"
    "detect-github-actions-concurrency-gap.sh"
    "detect-as-instruction-root-drift.sh"
    "detect-as-docs-vs-observed-host-drift.sh"
    "detect-as-missing-runtime-heartbeat.sh"
    "detect-as-validator-live-path-gap.sh"
    "detect-as-memory-authority-confusion.sh"
    "detect-as-prompt-only-optimization-surface.sh"
    "detect-as-unused-platform-surface.sh"
    "detect-external-critique-health.sh"
    "detect-as-cost-without-token-fields.sh"
    "detect-as-cost-model-mismatch.sh"
    "detect-as-request-tool-amplification-gap.sh"
    "detect-as-pricing-provenance-gap.sh"
    "detect-as-copied-evidence-boundary-gap.sh"
    "detect-as-unauthorized-production-default-enablement.sh"
    "detect-as-missing-rollback-control-proof.sh"
    "detect-as-aggregate-only-readiness.sh"
    "detect-as-stale-direct-token-evidence.sh"
    "detect-as-forbidden-public-customernewsletter-mutation.sh"
    "detect-as-source-intelligence-intake-gap.sh"
    "detect-as-selection-handback-recommendation.sh"
    "detect-as-too-small-goal-mode-episode.sh"
    "detect-as-github-native-closure-regrowth.sh"
    "detect-as-owner-surface-ambiguity.sh"
    "detect-as-reciprocal-proving-ground-gap.sh"
    "detect-as-goal-runtime-evidence-gap.sh"
    "detect-as-reactive-self-healing-loop.sh"
    "detect-as-shell-reserved-status-variable.sh"
    "detect-as-stale-default-capability-guidance.sh"
    "detect-as-hermes-foreground-receipt-adoption-gap.sh"
    "detect-as-interrupted-goal-recovery-gap.sh"
    "detect-as-fractured-serial-continuation.sh"
    "detect-as-unanchored-self-learning-claim.sh"
    "detect-as-foreground-failure-guidance-gap.sh"
    "detect-as-closure-run-identity-gap.sh"
    "detect-as-upstream-capability-intake-gap.sh"
    "detect-as-gbrain-instruction-distribution-overclaim.sh"
    "detect-as-issue164-runtime-drift.sh"
    "detect-as-self-authored-campaign-pause-authority.sh"
    "detect-as-scheduled-evidence-boundary-gap.sh"
    "detect-as-hermes-github-reliability-boundary-gap.sh"
    "detect-as-campaign-sync-completed-track-gap.sh"
    "detect-as-route-changing-learning-propagation-gap.sh"
    "detect-as-capability-placement-gap.sh"
    "detect-as-hermes-foreground-reliability-evidence-gap.sh"
    "detect-as-codex-native-runtime-readiness-evidence-gap.sh"
    "detect-as-deep-research-source-intelligence-native-corpus-gap.sh"
    "detect-as-integrated-native-capability-acceptance-gap.sh"
    "detect-as-standalone-external-intelligence-sidecar-gap.sh"
    "detect-as-scheduled-readback-owner-proof-gap.sh"
    "detect-as-hermes-foreground-failure-disposition-gap.sh"
    "detect-as-missing-operating-model-alignment-anchor.sh"
    "detect-as-missing-repo-anthropology-surface.sh"
    "detect-as-maturity-boundary-claim-overreach.sh"
    "detect-as-closure-signal-integrity.sh"
    "detect-as-review-ergonomics-working-memory-lightness.sh"
    "detect-as-external-closure-coupling.sh"
)

idx=0
total=${#scripts[@]}
timed_out_count=0
failed_count=0
for script in "${scripts[@]}"; do
    n=$((idx + 1))
    out="$TMPDIR_DS/ds_${idx}.json"
    start_epoch=$(date +%s)
    rc=0
    bash "$SCRIPT_DIR/run-with-timeout.sh" "$SIGNATURE_TIMEOUT" \
        bash "$SCRIPT_DIR/$script" "$REPO" > "$out" 2>/dev/null || rc=$?
    elapsed=$(( $(date +%s) - start_epoch ))
    if [ "$rc" -eq 0 ]; then
        echo "  [$n/$total] $script (${elapsed}s)" >&2
    else
        fallback_id="unknown"
        case "$script" in
            detect-as-github-native-closure-regrowth.sh) fallback_id="AS-22" ;;
            detect-as-closure-run-identity-gap.sh) fallback_id="AS-34" ;;
        esac
        if [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
            timed_out_count=$((timed_out_count + 1))
            reason="timeout after ${SIGNATURE_TIMEOUT}s"
            echo "  [$n/$total] $script TIMEOUT after ${SIGNATURE_TIMEOUT}s (elapsed ${elapsed}s) — sweep continues" >&2
        else
            failed_count=$((failed_count + 1))
            reason="script failed (exit $rc)"
            echo "  [$n/$total] $script FAILED (exit $rc, ${elapsed}s)" >&2
        fi
        python3 "$SCRIPT_DIR/ds_json_helper.py" \
            "{\"ds_id\":\"$fallback_id\",\"family\":\"${fallback_id:0:2}\",\"fired\":false}" \
            "error=$reason" "script=$script" "elapsed_seconds=$elapsed" \
            "signature_timeout_seconds=$SIGNATURE_TIMEOUT" > "$out"
    fi
    idx=$((idx + 1))
done

if [ "$timed_out_count" -gt 0 ] || [ "$failed_count" -gt 0 ]; then
    echo "=== $total signatures: $timed_out_count timed out, $failed_count failed (recorded as diagnostics, sweep completed) ===" >&2
fi

# Assemble via python3 (no heredocs — uses separate .py file)
python3 "$SCRIPT_DIR/assemble_ds_results.py" "$TMPDIR_DS" "$(basename "$REPO")" "$REPO" "$OUTPUT_DIR"

echo "=== Done ===" >&2
