#!/usr/bin/env bash
# test-token-efficiency-transfer.sh - bounded acceptance-spec check for the
# retained B15-2 token-efficiency transfer hypothesis.
#
# The test passes when repo-auditor truthfully fails closed: the retained
# token-efficiency fields are shown to be semantically incompatible with the
# current owner-surface outputs unless a new adapter/shared-core layer is
# introduced. The retained owner-side receipt may still be refreshed as
# current evidence by binding it to the live BMA foundation provenance
# contract and the paired critique hash.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURE_DIR="$REPO_ROOT/tests/fixtures/token-efficiency-transfer"
LABELS="$FIXTURE_DIR/benchmark-labels-v1.json"
BASELINE="$FIXTURE_DIR/token-allocation-report-summary-baseline-2026-03-17.json"
PRODUCTION="$FIXTURE_DIR/token-allocation-report-summary-production-2026-03-17.json"
FIELD_STATEMENT="$FIXTURE_DIR/field-statement.json"
REQUESTED_OUTPUT="${1:-}"
REQUESTED_CRITIQUE_OUTPUT="${2:-}"
BMA_CURRENT_FOUNDATION_PATH="${BMA_CURRENT_FOUNDATION_PATH:-}"

if [ -z "$BMA_CURRENT_FOUNDATION_PATH" ]; then
    DEFAULT_BMA_FOUNDATION="$REPO_ROOT/../build-meta-analysis/research/benchmarks/token-efficiency-preservation/owner-receipt-current-foundation-v1.json"
    if [ -f "$DEFAULT_BMA_FOUNDATION" ]; then
        BMA_CURRENT_FOUNDATION_PATH="$DEFAULT_BMA_FOUNDATION"
    else
        BMA_CURRENT_FOUNDATION_PATH="__EMBEDDED_FALLBACK__"
    fi
fi

TMPDIR="$(mktemp -d)"
cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

resolve_repo_path() {
    case "$1" in
        /*) printf '%s\n' "$1" ;;
        *) printf '%s\n' "$REPO_ROOT/$1" ;;
    esac
}

TARGET_REPO="$TMPDIR/minimal-target"
AUDIT_OUTPUT="$TMPDIR/audit-output"
RECEIPT_OUTPUT="$REQUESTED_OUTPUT"
if [ -z "$RECEIPT_OUTPUT" ]; then
    RECEIPT_OUTPUT="$TMPDIR/token-efficiency-transfer-readiness.json"
else
    RECEIPT_OUTPUT="$(resolve_repo_path "$RECEIPT_OUTPUT")"
fi
CRITIQUE_OUTPUT="$REQUESTED_CRITIQUE_OUTPUT"
if [ -z "$CRITIQUE_OUTPUT" ]; then
    CRITIQUE_OUTPUT="$(dirname "$RECEIPT_OUTPUT")/token-efficiency-transfer-mapping-critique.md"
else
    CRITIQUE_OUTPUT="$(resolve_repo_path "$CRITIQUE_OUTPUT")"
fi

mkdir -p "$TARGET_REPO" "$AUDIT_OUTPUT" "$(dirname "$RECEIPT_OUTPUT")" "$(dirname "$CRITIQUE_OUTPUT")"

echo "=== Token-Efficiency Transfer Acceptance-Spec ==="

cd "$TARGET_REPO"
git init -q
git config user.email "codex@example.com"
git config user.name "Codex"
printf '# AGENTS.md\n' > AGENTS.md
printf 'review:\n\t@echo ok\n' > Makefile
git add AGENTS.md Makefile
git commit -qm "init transfer fixture"

bash "$REPO_ROOT/scripts/repo-auditor.sh" "$TARGET_REPO" "$AUDIT_OUTPUT" > /dev/null

python3 - "$LABELS" "$BASELINE" "$PRODUCTION" "$FIELD_STATEMENT" "$AUDIT_OUTPUT" "$RECEIPT_OUTPUT" "$CRITIQUE_OUTPUT" "$BMA_CURRENT_FOUNDATION_PATH" <<'PY'
import hashlib
import json
import pathlib
import sys
from datetime import datetime, timezone


def load_json(path_str):
    path = pathlib.Path(path_str)
    return path, json.load(open(path))


def key_exists_anywhere(node, target):
    if isinstance(node, dict):
        if target in node:
            return True
        return any(key_exists_anywhere(value, target) for value in node.values())
    if isinstance(node, list):
        return any(key_exists_anywhere(value, target) for value in node)
    return False


def path_exists(node, dotted):
    parts = dotted.split(".")
    current = [node]
    for raw_part in parts:
        next_nodes = []
        is_list = raw_part.endswith("[]")
        part = raw_part[:-2] if is_list else raw_part
        for candidate in current:
            if isinstance(candidate, dict):
                if part in candidate:
                    value = candidate[part]
                    if is_list:
                        if isinstance(value, list):
                            next_nodes.extend(value)
                    else:
                        next_nodes.append(value)
            elif isinstance(candidate, list):
                for item in candidate:
                    if isinstance(item, dict) and part in item:
                        value = item[part]
                        if is_list:
                            if isinstance(value, list):
                                next_nodes.extend(value)
                        else:
                            next_nodes.append(value)
        current = next_nodes
        if not current:
            return False
    return True


def first_hotspot_value(doc, key):
    hotspots = doc.get("hotspots", [])
    if not hotspots:
        raise AssertionError(f"missing hotspots for {key}")
    if key not in hotspots[0]:
        raise AssertionError(f"missing hotspot key: {key}")
    return hotspots[0][key]


labels_path, labels = load_json(sys.argv[1])
baseline_path, baseline = load_json(sys.argv[2])
production_path, production = load_json(sys.argv[3])
statement_path, statement = load_json(sys.argv[4])
audit_output = pathlib.Path(sys.argv[5])
receipt_path = pathlib.Path(sys.argv[6])
critique_path = pathlib.Path(sys.argv[7])
foundation_path = sys.argv[8]

if foundation_path == "__EMBEDDED_FALLBACK__":
    current_foundation = {
        "schema_version": "1.0.0",
        "admission_contract_version": "owner_receipt_admission_v1",
        "provenance_field": "bma_foundation_provenance",
        "current_inputs": {
            "source_corpus": {"sha256": "embedded-fallback-source-corpus-sha256"},
            "package_manifest": {"sha256": "embedded-fallback-package-manifest-sha256"},
            "worktree_fingerprint": {
                "sha256": "embedded-fallback-worktree-fingerprint-sha256",
                "branch": "embedded/token-efficiency-preservation",
                "head": "embedded-fallback-head",
            },
        },
        "critique_calibration_bundle_sha256": "embedded-fallback-critique-calibration-sha256",
        "foundation_contract_sha256": "embedded-fallback-foundation-contract-sha256",
    }
    current_foundation_label = "embedded fallback token-efficiency provenance contract"
else:
    with open(foundation_path) as foundation_handle:
        current_foundation = json.load(foundation_handle)
    current_foundation_label = "current BMA token-efficiency foundation contract"

assert current_foundation["schema_version"] == "1.0.0"
assert current_foundation["admission_contract_version"] == "owner_receipt_admission_v1"
assert current_foundation["provenance_field"] == "bma_foundation_provenance"
assert current_foundation["foundation_contract_sha256"]
assert current_foundation["critique_calibration_bundle_sha256"]
assert current_foundation["current_inputs"]["source_corpus"]["sha256"]
assert current_foundation["current_inputs"]["package_manifest"]["sha256"]
assert current_foundation["current_inputs"]["worktree_fingerprint"]["sha256"]
assert current_foundation["current_inputs"]["worktree_fingerprint"]["branch"]
assert current_foundation["current_inputs"]["worktree_fingerprint"]["head"]

scorecard = json.load(open(audit_output / "SCORECARD.json"))
receipts = json.load(open(audit_output / "SCORECARD_RECEIPTS.json"))
manifest = json.load(open(audit_output / "CONTEXT_SCORE_MANIFEST.json"))
operation_eval = json.load(open(audit_output / "OPERATION_EVAL.json"))

owner_docs = {
    "SCORECARD.json": scorecard,
    "SCORECARD_RECEIPTS.json": receipts,
    "CONTEXT_SCORE_MANIFEST.json": manifest,
    "OPERATION_EVAL.json": operation_eval,
}

assert labels.get("labels"), "benchmark labels fixture must be populated"
assert baseline["report_metadata"]["decision_readiness"]
assert production["report_metadata"]["decision_readiness"]
assert "proxy_rows" in baseline["topline_metrics"]
assert "proxy_share_pct" in baseline["topline_metrics"]
assert "unlinked_rows" in baseline["topline_metrics"]
assert "unlinked_share_pct" in baseline["topline_metrics"]
assert "classification_confidence" in production["hotspots"][0]
assert "actionability_status" in production["hotspots"][0]

field_examples = {
    "decision_readiness": {
        "baseline": baseline["topline_metrics"]["decision_readiness"],
        "production": production["topline_metrics"]["decision_readiness"],
    },
    "proxy_rows": {
        "baseline": baseline["topline_metrics"]["proxy_rows"],
        "production": production["topline_metrics"]["proxy_rows"],
    },
    "proxy_share_pct": {
        "baseline": baseline["topline_metrics"]["proxy_share_pct"],
        "production": production["topline_metrics"]["proxy_share_pct"],
    },
    "unlinked_rows": {
        "baseline": baseline["topline_metrics"]["unlinked_rows"],
        "production": production["topline_metrics"]["unlinked_rows"],
    },
    "unlinked_share_pct": {
        "baseline": baseline["topline_metrics"]["unlinked_share_pct"],
        "production": production["topline_metrics"]["unlinked_share_pct"],
    },
    "classification_confidence": {
        "production_hotspot_id": production["hotspots"][0]["hotspot_id"],
        "production_value": first_hotspot_value(production, "classification_confidence"),
        "production_score": first_hotspot_value(production, "classification_confidence_score"),
    },
    "actionability_status": {
        "production_hotspot_id": production["hotspots"][0]["hotspot_id"],
        "production_value": first_hotspot_value(production, "actionability_status"),
        "production_summary": first_hotspot_value(production, "actionability_summary"),
    },
}

kept_field_statement = []
for field in statement["kept_fields"]:
    name = field["field"]
    source_present = any(
        path_exists(baseline, path) or path_exists(production, path)
        for path in field["source_paths"]
    )
    assert source_present, f"source fixture missing expected field path(s) for {name}"

    native_key_present = any(key_exists_anywhere(doc, name) for doc in owner_docs.values())
    assert not native_key_present, f"{name} unexpectedly present in owner outputs"

    kept_field_statement.append(
        {
            "field": name,
            "source_paths": field["source_paths"],
            "source_examples": field_examples[name],
            "owner_surface_files": field["owner_surface_files"],
            "owner_surface_paths": field["owner_surface_paths"],
            "closest_owner_surface_files": field["closest_owner_surface_files"],
            "closest_owner_surface_paths": field["closest_owner_surface_paths"],
            "literal_key_absent_from_owner_outputs": True,
            "status": field["status"],
            "reason": field["reason"],
        }
    )

verified_signal_groups = []
for group in statement["signal_groups"]:
    missing_paths = []
    for dotted in group["owner_surface_paths"]:
        if dotted.startswith("portable_authority."):
            if not path_exists(manifest, dotted):
                missing_paths.append(dotted)
        elif dotted.startswith("count_reconciliation.") or dotted.startswith("receipt_integrity."):
            if not path_exists(receipts, dotted):
                missing_paths.append(dotted)
        elif dotted.startswith("tier1_checks.") or dotted.startswith("tier2_warnings."):
            if not path_exists(scorecard, dotted):
                missing_paths.append(dotted)
        else:
            if not path_exists(operation_eval, dotted):
                missing_paths.append(dotted)
    assert not missing_paths, f"missing partial signal path(s): {missing_paths}"
    verified_signal_groups.append(
        {
            "group": group["group"],
            "owner_surface_files": group["owner_surface_files"],
            "owner_surface_paths": group["owner_surface_paths"],
            "status": group["status"],
            "reason": group["reason"],
        }
    )

critique_text = """# Token-Efficiency Transfer Mapping Critique

## current-surface truth

No. The retained readiness receipt shows that current `repo-auditor` outputs
and receipts (`SCORECARD.json`, `SCORECARD_RECEIPTS.json`,
`CONTEXT_SCORE_MANIFEST.json`, `OPERATION_EVAL.json`) do not carry the kept
B15-2 fields natively. The owner surface exposes aggregate repo-audit maturity,
receipt-integrity, and portability signals, but not token-allocation
`decision_readiness`, `proxy_rows`, `proxy_share_pct`, `unlinked_rows`,
`unlinked_share_pct`, `classification_confidence`, or `actionability_status`.
Any claim that those semantics already flow through current owner surfaces would
be false.

## stale semantic carryover

Yes. Any attempted PASS on this batch would depend on replaying historical BMA
token-allocation semantics onto current `repo-auditor` outputs that were built
for repo-audit maturity scoring, not hotspot allocation readiness. The nearest
owner-surface signals are only coarse analogs, so forcing a transfer result
would be stale semantic carryover rather than current-surface truth.

## authority inflation

Yes, if a PASS or "transfer ready" claim were issued from this evidence. The
current receipt proves only that `repo-auditor` has some audit-control and
receipt-integrity signals, not that it can natively carry the token-efficiency
oracle fields. This critique therefore supports the retained fail-closed
`semantic_incompatibility` verdict and rejects any stronger downstream-transfer
claim on present evidence.

## current foundation provenance match

Yes. This retained owner receipt is regenerated against the %s. The paired
readiness JSON stamps `bma_foundation_provenance` with admission contract
`%s`, foundation contract SHA `%s`, critique-calibration SHA `%s`,
source-corpus SHA `%s`, package-manifest SHA `%s`, worktree fingerprint SHA
`%s`, and authoritative worktree `%s` @ `%s`. The receipt also binds this
paired critique by hash so BMA can reject it cleanly on the next contract
rotation.

## Verdict

Keep the owner-side result as `FAIL` with blocker class
`semantic_incompatibility`. The truthful transfer claim remains fail-closed,
but this refreshed receipt can still count as current owner-side evidence under
the live BMA provenance contract.
""" % (
    current_foundation_label,
    current_foundation["admission_contract_version"],
    current_foundation["foundation_contract_sha256"],
    current_foundation["critique_calibration_bundle_sha256"],
    current_foundation["current_inputs"]["source_corpus"]["sha256"],
    current_foundation["current_inputs"]["package_manifest"]["sha256"],
    current_foundation["current_inputs"]["worktree_fingerprint"]["sha256"],
    current_foundation["current_inputs"]["worktree_fingerprint"]["branch"],
    current_foundation["current_inputs"]["worktree_fingerprint"]["head"],
)
critique_sha256 = hashlib.sha256(critique_text.encode("utf-8")).hexdigest()

receipt = {
    "receipt_version": "1.0.0",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "generator": "tests/test-token-efficiency-transfer.sh",
    "verdict": "FAIL",
    "blocker_class": statement["expected_blocker_class"],
    "fixture_files": statement["source_fixture_files"],
    "comparison_procedure": statement["comparison_procedure"],
    "owner_surface_run": {
        "target_fixture": "clean minimal git repo",
        "generated_output_files": statement["owner_surface_generated_files"],
        "audit_output_dir": str(audit_output),
    },
    "kept_field_statement": kept_field_statement,
    "partial_owner_signals": verified_signal_groups,
    "pass_conditions_met": [],
    "pass_conditions_failed": [
        "Current repo-auditor outputs do not expose decision_readiness as a native owner-surface field.",
        "Current repo-auditor outputs do not expose proxy_rows or proxy_share_pct.",
        "Current repo-auditor outputs do not expose unlinked_rows or unlinked_share_pct.",
        "Current repo-auditor outputs do not keep classification_confidence separate from actionability_status because neither hotspot-level field exists natively.",
        "Current repo-auditor validity signals are coarse audit-control receipts, not token-efficiency hotspot instrumentation gaps.",
    ],
    "mismatch_summary": [
        "Repo-auditor is currently a repo-maturity auditor, not a token-allocation hotspot scorer.",
        "Any forced PASS would require a new semantic adapter that silently reinterprets current owner outputs as token-efficiency readiness fields.",
        "The truthful owner-side result on present evidence is fail-closed semantic incompatibility.",
    ],
    "critique_prompts": [
        "current-surface truth: does the receipt prove the kept fields flow through existing repo-auditor surfaces rather than a one-off adapter",
        "stale semantic carryover: does any PASS result depend on replaying historical BMA semantics that the current owner surface no longer fits",
        "authority inflation: does the receipt claim more than current-surface representability actually proves",
        "current foundation provenance match: does the retained readiness receipt bind itself to the current BMA contract and this paired critique hash rather than a stale prior contract",
    ],
    "non_claims": statement["non_claims"],
    "bma_foundation_provenance": {
        "schema_version": current_foundation["schema_version"],
        "admission_contract_version": current_foundation["admission_contract_version"],
        "critique_contract_version": current_foundation["admission_contract_version"],
        "foundation_contract_sha256": current_foundation["foundation_contract_sha256"],
        "critique_calibration_bundle_sha256": current_foundation["critique_calibration_bundle_sha256"],
        "source_corpus_sha256": current_foundation["current_inputs"]["source_corpus"]["sha256"],
        "package_manifest_sha256": current_foundation["current_inputs"]["package_manifest"]["sha256"],
        "worktree_fingerprint_sha256": current_foundation["current_inputs"]["worktree_fingerprint"]["sha256"],
        "authoritative_worktree_branch": current_foundation["current_inputs"]["worktree_fingerprint"]["branch"],
        "authoritative_worktree_head": current_foundation["current_inputs"]["worktree_fingerprint"]["head"],
        "critique_sha256": critique_sha256,
    },
}

critique_path.parent.mkdir(parents=True, exist_ok=True)
receipt_path.parent.mkdir(parents=True, exist_ok=True)
critique_path.write_text(critique_text)
receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")

assert receipt["verdict"] == "FAIL"
assert receipt["blocker_class"] == "semantic_incompatibility"
assert all(item["status"] == "not_representable" for item in kept_field_statement)
assert all(item["status"] == "partial_non_equivalent" for item in verified_signal_groups)
assert receipt["bma_foundation_provenance"]["critique_sha256"] == critique_sha256
assert (
    receipt["bma_foundation_provenance"]["foundation_contract_sha256"]
    == current_foundation["foundation_contract_sha256"]
)
assert (
    receipt["bma_foundation_provenance"]["critique_calibration_bundle_sha256"]
    == current_foundation["critique_calibration_bundle_sha256"]
)
PY

python3 - "$RECEIPT_OUTPUT" "$CRITIQUE_OUTPUT" <<'PY'
import json
import sys

receipt = json.load(open(sys.argv[1]))
print("  PASS retained receipt written:", sys.argv[1])
print("  PASS paired critique written:", sys.argv[2])
print("  PASS verdict:", receipt["verdict"])
print("  PASS blocker_class:", receipt["blocker_class"])
print("  PASS non-representable kept fields:", len(receipt["kept_field_statement"]))
print("  PASS partial owner signal groups:", len(receipt["partial_owner_signals"]))
print("  PASS foundation contract:", receipt["bma_foundation_provenance"]["foundation_contract_sha256"])
PY

echo "  VERDICT: PASS"
