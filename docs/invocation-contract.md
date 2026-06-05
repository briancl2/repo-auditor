# repo-auditor Invocation Contract v1.0

## Inputs

| Parameter | Required | Description |
|---|---|---|
| TARGET | Yes | Path to target repository (absolute recommended) |
| OUTPUT_DIR | Yes | Path to output directory (will be created; absolute recommended) |
| MODE | No | `standard` (default) or `deep` |
| SNAPSHOT_DIR | Snapshot mode only | Directory to create for an explicit clean HEAD snapshot |

## Additive Pilot

The repo also exposes an additive token-efficiency replay path:

```bash
make token-efficiency-measure SOURCE_PACK=<path> OUTPUT_DIR=<dir>
```

This pilot does not modify `SCORECARD.json` semantics. It replays a retained
token-efficiency source pack into additive artifacts and fails closed when
labels, hotspot fields, or exact attribution receipts are missing.

## Clean HEAD Snapshot Mode

Dirty git targets still fail the standard audit guard. When an operator needs
committed-state evidence from a dirty real-world target, use the explicit
snapshot mode:

```bash
make audit-snapshot TARGET=<path> OUTPUT_DIR=<dir> SNAPSHOT_DIR=<dir>
```

Snapshot mode clones the target's committed HEAD into `SNAPSHOT_DIR` with local
clone optimizations disabled, runs the unchanged standard auditor against that
snapshot, and writes provenance to `CLEAN_HEAD_SNAPSHOT_RECEIPT.json`. It does
not include untracked or modified source worktree files, does not mutate the
source target, does not change score semantics, and does not change dual
inventory scan limits.

## Outputs (all written to OUTPUT_DIR/)

| Artifact | Format | Description |
|---|---|---|
| SCORECARD.json | JSON (schemas/SCORECARD.schema.json) | 5-dimension composite score (0-100) |
| SCORECARD_RECEIPTS.json | JSON | Raw dimension receipts plus count reconciliation and inventory metadata |
| AUDIT_RUN_RECEIPT.json | JSON | Run-level receipt with `status`, `reason`, required artifact presence, and exit code |
| TARGET_NATIVE_QUALITY_GATES.json | JSON | Additive target-local quality gate receipt emitted only when retained local gate evidence is present |
| CLEAN_HEAD_SNAPSHOT_RECEIPT.json | JSON | Snapshot-mode provenance receipt emitted only by explicit clean HEAD snapshot invocation |
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

Run receipts also include `started_at`, `completed_at`, and integer
`elapsed_seconds` fields. `timestamp` remains present for compatibility and is
the same value as `completed_at`.

## Closure-Run Identity

Local validation gates and GitHub Actions runs expose a comparable
closure-run identity surface with these fields: `closure_run_id`,
`closure_phase`, `closure_trigger`, `evidence_reuse_key`, `parent_command`,
`github_run_id`, and `github_run_attempt`.

Local defaults use `closure_run_id=${CLOSURE_RUN_ID:-local-<UTC>-<pid>}`,
the invoked gate as `closure_phase`, and `manual` as `closure_trigger`.
GitHub Actions sets `closure_run_id` to `${{ github.run_id }}-${{
github.run_attempt }}` and also exposes `github_run_id` and
`github_run_attempt`. Local runs do not create receipt files unless
`CLOSURE_IDENTITY_RECEIPT_PATH` or `--receipt` is provided.

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
- `git_tracked_file_count` when the target path is its own git worktree root
- `denominator_mode`, `auditor_pruned_total_files`, and
  `scan_coverage_ratio` when the caller opts in to full denominator measurement
- `scan_limit_guidance`, an additive action receipt for scan-limited runs
- `non_authorization_statement`

Inventory receipts are evidence context only. Missing, empty, limited, or
unavailable inventory means insufficient evidence for stronger downstream claims;
it never authorizes deletion, archiving, compression, or rewriting of target
files. The default inventory scan limit is 1000 auditor-pruned files per target.

By default, dual inventory keeps denominator fields unmeasured to preserve the
bounded scan contract. Operators that need cap-curve evidence may set
`REPO_AUDITOR_DUAL_INVENTORY_MEASURE_DENOMINATOR=1` to add a full auditor-pruned
file denominator and coverage ratio. Operators may set
`REPO_AUDITOR_DUAL_INVENTORY_MAX_FILES=<n>` to choose the bounded inventory cap.
Caps above the default are trusted-local measurement policy: they require that
explicit environment override and do not weaken dirty-target guards, mutate the
target, or authorize downstream cleanup. These fields are descriptive evidence
only and do not change scoring, scan status, or non-authorization semantics.

When `scan_limit_reached=true`, `scan_limit_guidance.status` tells consumers the
next safe action without changing score semantics:

- `measure_denominator`: denominator measurement was not enabled, so consumers
  should rerun with `REPO_AUDITOR_DUAL_INVENTORY_MEASURE_DENOMINATOR=1` or use
  `make measure-dual-inventory-cap-curve` before claiming complete inventory.
- `rerun_with_higher_cap`: denominator measurement found the auditor-pruned
  total. `minimum_complete_cap` records that exact measured floor, and
  `recommended_rerun_cap=ceil(minimum_complete_cap * 1.10)` adds a small churn
  buffer. The corresponding `trusted_local_override` is still explicit
  trusted-local policy and does not authorize unbounded scans.
- `not_needed`: the inventory completed within the configured cap.
- `not_applicable`: the inventory was unavailable.

`SCORECARD.json.receipts.dual_inventory` mirrors the compact guidance status,
minimum measured complete cap, recommended rerun cap, and trusted-local override
for consumers that do not read the full receipt.

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

## Clean HEAD Snapshot Receipts

When `make audit-snapshot` is used, `CLEAN_HEAD_SNAPSHOT_RECEIPT.json` records:

- `mode=clean-head-snapshot`
- source path, branch, HEAD, tree, dirty state, and status counts
- snapshot path, HEAD, tree, clone arguments, and clean status
- audit output directory and audit exit code
- explicit non-authorization and scan-cap statements

Completed snapshot audits also add compact pointers at
`SCORECARD_RECEIPTS.json.clean_head_snapshot` and
`SCORECARD.json.receipts.clean_head_snapshot`. Consumers must treat these runs
as committed-HEAD snapshot evidence, not live dirty-worktree evidence. Snapshot
mode does not authorize target cleanup and does not convert scan-limited
inventory into complete evidence.

## Invocation Examples

### Bash (direct)
```bash
bash scripts/repo-auditor.sh /path/to/target /path/to/output
```

### Bash (clean HEAD snapshot)
```bash
python3 scripts/audit-clean-head-snapshot.py /path/to/target /path/to/output --snapshot-dir /path/to/snapshot
```

### Agent (copilot CLI)
```bash
cd ~/repos/repo-auditor && copilot --model claude-haiku-4.5 \
  -p "Read .agents/repo-auditor.agent.md. Audit /path/to/target. Output: /path/to/output/." \
  --allow-all --no-ask-user
```

## Version
- Contract: 1.0
- Compatible with: repo-auditor.sh, audit-clean-head-snapshot.py, repo-auditor.agent.md
