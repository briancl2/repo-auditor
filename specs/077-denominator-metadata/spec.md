# Feature Specification: Scorecard Denominator Metadata

**Feature Branch**: `bma-phase3a-denominator-metadata`
**Spec Directory**: `specs/077-denominator-metadata`
**Created**: 2026-05-08
**Status**: Draft
**Input**: BMA Phase 3A P7: add explicit denominator semantics and excluded path-class metadata to `SCORECARD_RECEIPTS.json` count reconciliation without changing current count behavior.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Explain the scorecard denominator (Priority: P1)

As a downstream consumer of repo-auditor artifacts, I need
`SCORECARD_RECEIPTS.json.count_reconciliation` to state which file denominator
the scorecard uses, so I can compare auditor totals with other fleet tools
without guessing exclusion semantics.

**Why this priority**: BMA Phase 2 found a real denominator mismatch between
repo-auditor and repo-optimizer. The mismatch was explainable, but the auditor
receipt did not machine-state its denominator semantics.

**Independent Test**: Run the scorer against a fixture receipt bundle and verify
the count reconciliation metadata names the auditor-pruned analysis/scorecard
denominator, includes the default excluded classes, records `.auditorignore`
state, and preserves existing count fields.

**Acceptance Scenarios**:

1. **Given** a scorecard receipt, **When** a consumer reads
   `count_reconciliation`, **Then** it includes denominator semantics naming the
   auditor-pruned analysis/scorecard denominator.
2. **Given** default pruning classes, **When** receipts are written, **Then**
   metadata includes `.git`, `.venv`, `venv`, `node_modules`, `.tox`,
   `.mypy_cache`, `__pycache__`, `vendor`, `.eggs`, and `.DS_Store`.
3. **Given** a target with `.auditorignore`, **When** receipts are written,
   **Then** metadata records active/count state without enumerating ignored path
   values in the scorecard receipts.
4. **Given** existing count reconciliation fields, **When** metadata is added,
   **Then** `status`, `authoritative_total_files`, `pre_scan_total_files`,
   `maturity_total_files`, and `dna_total_files` remain unchanged.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `SCORECARD_RECEIPTS.json.count_reconciliation` MUST include
  machine-readable denominator semantics.
- **FR-002**: The semantics MUST name the auditor-pruned analysis/scorecard
  denominator.
- **FR-003**: The receipt MUST include the default excluded path classes:
  `.git`, `.venv`, `venv`, `node_modules`, `.tox`, `.mypy_cache`,
  `__pycache__`, `vendor`, `.eggs`, and `.DS_Store`.
- **FR-004**: The receipt MUST include `.auditorignore` state without
  enumerating target-private ignored path values.
- **FR-005**: Existing count reconciliation fields and consumers MUST remain
  compatible.
- **FR-006**: The change MUST NOT alter current count behavior.
- **FR-007**: `docs/invocation-contract.md` MUST document the receipt metadata.

### Key Entities

- **Count Reconciliation**: The `SCORECARD_RECEIPTS.json` object comparing
  pre-scan, maturity, and DNA file totals.
- **Denominator Semantics**: Metadata describing what counted file surface the
  authoritative total represents.
- **Excluded Path Classes**: Default path classes pruned or filtered before the
  authoritative scorecard denominator is counted.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Focused denominator metadata tests pass.
- **SC-002**: `make test` passes.
- **SC-003**: `make check` passes.
- **SC-004**: Local review reports no unresolved CRITICAL/HIGH findings.
