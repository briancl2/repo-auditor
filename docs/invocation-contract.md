# repo-auditor Invocation Contract v1.0

## Inputs

| Parameter | Required | Description |
|---|---|---|
| TARGET | Yes | Path to target repository (absolute recommended) |
| OUTPUT_DIR | Yes | Path to output directory (will be created; absolute recommended) |
| MODE | No | `standard` (default) or `deep` |

## Additive Pilot

The repo also exposes an additive token-efficiency replay path:

```bash
make token-efficiency-measure SOURCE_PACK=<path> OUTPUT_DIR=<dir>
```

This pilot does not modify `SCORECARD.json` semantics. It replays a retained
token-efficiency source pack into additive artifacts and fails closed when
labels, hotspot fields, or exact attribution receipts are missing.

## Outputs (all written to OUTPUT_DIR/)

| Artifact | Format | Description |
|---|---|---|
| SCORECARD.json | JSON (schemas/SCORECARD.schema.json) | 5-dimension composite score (0-100) |
| SCORECARD_RECEIPTS.json | JSON | Raw dimension receipts plus count reconciliation and inventory metadata |
| AUDIT_RUN_RECEIPT.json | JSON | Run-level receipt with `status`, `reason`, required artifact presence, and exit code |
| TARGET_NATIVE_QUALITY_GATES.json | JSON | Additive target-local quality gate receipt emitted only when retained local gate evidence is present |
| AUDIT_REPORT.md | Markdown | Human-readable audit summary |
| pre-scan/PRE_SCAN.md | Markdown | File inventory and AI surface analysis |
| maturity.txt | Plain text | Maturity phase classification |
| stall-risk.txt | Plain text | 6-signal stall risk assessment |
| dna.txt | Plain text | 10-feature repo DNA fingerprint |
| drift.txt | Plain text | Capability drift analysis |
| TOKEN_MEASUREMENT_SUMMARY.json | JSON | Additive token-efficiency replay summary |
| HOTSPOT_EVIDENCE_PACKETS.json | JSON | Additive hotspot evidence packets |
| AGENTIC_ROOT_CAUSE_BRIEFS.json | JSON | Additive bounded advisory handoff briefs |
| WORKFLOW_INVESTIGATIONS.json | JSON | Additive workflow evidence support |

## Error Codes

| Code | Meaning |
|---|---|
| 0 | Success — all artifacts produced |
| 1 | Invalid arguments (missing TARGET or OUTPUT_DIR) |
| 2 | Target not found or not a directory |
| 3 | Tool failure (partial artifacts may exist) |

## Run Receipt and Partial Artifacts

Every invocation that has an output directory writes `AUDIT_RUN_RECEIPT.json`.
The receipt is the authoritative way for consumers to distinguish complete,
partial, and failed audit runs without inferring status from file presence alone.

Receipt `status` values:

- `completed`: required artifacts were produced and no audit tool failures were
  recorded.
- `partial`: a machine-readable scorecard was produced, but required report
  artifacts are absent or report generation failed. Consumers may read
  `SCORECARD.json`, but must treat the run as an incomplete artifact set.
- `failed`: the audit could not complete successfully. The receipt includes a
  non-empty `reason` and any known `failed_tools`.

Required artifacts for completeness are `SCORECARD.json`,
`SCORECARD_RECEIPTS.json`, and `AUDIT_REPORT.md`. The receipt records each
required artifact under `required_artifacts` and lists missing files in
`missing_required_artifacts`.

## Scorecard Receipts and Count Reconciliation

`SCORECARD_RECEIPTS.json.count_reconciliation` records the file-count surface
used by the scorecard. Existing consumers can continue reading:

- `status`
- `authoritative_total_files`
- `pre_scan_total_files`
- `maturity_total_files`
- `dna_total_files`
- `note`

The authoritative total is the auditor-pruned analysis/scorecard denominator:
files counted after repo-auditor excludes its default non-analysis path classes
and any active `.auditorignore` rules. The metadata is descriptive only and does
not change count behavior.

Additive metadata fields:

- `denominator_semantics.name`:
  `auditor_pruned_analysis_scorecard_denominator`
- `denominator_semantics.authoritative_total_files_meaning`: a plain-language
  description of the authoritative count surface
- `denominator_semantics.source`: the pre-scan total reconciled with maturity
  and DNA totals
- `denominator_semantics.count_behavior`: states that the metadata is
  descriptive only and does not change existing counts
- `excluded_path_classes.default_pruned_directories`: `.git`, `.venv`, `venv`,
  `node_modules`, `.tox`, `.mypy_cache`, `__pycache__`, `vendor`, and `.eggs`
- `excluded_path_classes.default_excluded_files`: `.DS_Store`
- `excluded_path_classes.auditorignore`: active state, entry count, and an
  `entry_count_status` of `known`, `unknown`, or `none`; it also includes an
  explicit `entries_emitted=false` marker so scorecard receipts do not enumerate
  target-private ignored paths

When `SCORECARD.json` exists, its `meta` object mirrors the run state with:

- `audit_status`: `completed`, `partial`, or `failed`
- `artifact_status`: `completed` or `partial`
- `missing_required_artifacts`: required artifacts absent at closeout
- `audit_status_reason`: present when the status is not `completed`

## Dual Inventory Receipts

Every standard audit with scorecard artifacts adds inventory metadata to
`SCORECARD_RECEIPTS.json` and a compact pointer at
`SCORECARD.json.receipts.dual_inventory`.

`SCORECARD_RECEIPTS.json.primary_surface_inventory` records a bounded inventory
of primary AI, instruction, agent, skill, governance, validation, and workflow
surfaces. It includes:

- `status`: `available`, `available_empty`, `available_limited`, or
  `unavailable`
- `scan_limit` and `scan_limit_reached`
- `total_unique_paths`
- `categories` with bounded path samples and omitted-path counts
- `non_authorization_statement`

`SCORECARD_RECEIPTS.json.full_facts_inventory` records the broader
auditor-pruned fact surface by coarse class counts. It includes:

- `status`: `available`, `available_limited`, or `unavailable`
- `scan_limit` and `scan_limit_reached`
- `total_files_scanned`
- `class_counts`
- `.auditorignore` active/count state without ignored path values
- `paths_emitted=false`
- `non_authorization_statement`

Inventory receipts are evidence context only. Missing, empty, limited, or
unavailable inventory means insufficient evidence for stronger downstream claims;
it never authorizes deletion, archiving, compression, or rewriting of target
files. The default inventory scan limit is 200 auditor-pruned files per target.

## Target-Native Quality Gates

When a target already retains a recognizable local quality gate artifact, the
auditor emits `TARGET_NATIVE_QUALITY_GATES.json` and adds pointers to
`SCORECARD.json.receipts.target_native_quality_gates` and
`SCORECARD_RECEIPTS.json.target_native_quality_gates`.

This receipt is parallel evidence only. It does not replace
`SCORECARD.json.composite`, dimensions, or Tier-1/Tier-2 checks. If the generic
audit output is partial or missing required artifacts, the contradiction is
`partial_run_no_verdict` and the receipt states that the partial diagnostic is
not a target-quality verdict. If gate-like evidence is present but unclassified,
the contradiction is `unclassified_requires_amendment`.

Provisional contradiction values:

- `target_policy_explained`
- `unresolved`
- `true_target_risk`
- `fleet_metric_stale`
- `partial_run_no_verdict`
- `unclassified_requires_amendment`

## Invocation Examples

### Bash (direct)
```bash
bash scripts/repo-auditor.sh /path/to/target /path/to/output
```

### Agent (copilot CLI)
```bash
cd ~/repos/repo-auditor && copilot --model claude-haiku-4.5 \
  -p "Read .agents/repo-auditor.agent.md. Audit /path/to/target. Output: /path/to/output/." \
  --allow-all --no-ask-user
```

## Version
- Contract: 1.0
- Compatible with: repo-auditor.sh, repo-auditor.agent.md
