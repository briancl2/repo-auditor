# Feature Specification: Cap-Curve Receipt Fields

**Feature Branch**: `briancl2/cap-curve-receipts`  
**Spec Directory**: `specs/081-cap-curve-receipt-fields`  
**Status**: Draft  
**Input**: BMA cap-curve measurements showed external ledgers were required to
pair repo-auditor scan-limit status with wall time and the full
auditor-pruned denominator.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Measure audit wall time (Priority: P1)

As a fleet operator, I need every audit run receipt to include elapsed wall time
so large-target cap decisions can compare runtime without relying on external
shell wrappers.

**Independent Test**: Run the existing audit-run receipt test and verify
completed, partial, missing-target, and guard-failed receipts include
`started_at`, `completed_at`, and integer `elapsed_seconds`.

### User Story 2 - Opt into denominator evidence (Priority: P1)

As a repo-auditor consumer, I need an explicit opt-in way to measure the full
auditor-pruned file denominator and scan coverage ratio so `available_limited`
can be interpreted as measured coverage rather than vague incompleteness.

**Independent Test**: Run the dual-inventory collector with
`REPO_AUDITOR_DUAL_INVENTORY_MEASURE_DENOMINATOR=1` and a low cap against a
fixture with more files than the cap; verify the receipt reports the cap, files
scanned, full denominator, coverage ratio, and non-authorization.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `AUDIT_RUN_RECEIPT.json` MUST include `started_at`,
  `completed_at`, and `elapsed_seconds`.
- **FR-002**: `timestamp` MUST remain available for existing consumers.
- **FR-003**: Dual inventory MUST keep denominator measurement disabled by
  default.
- **FR-004**: When
  `REPO_AUDITOR_DUAL_INVENTORY_MEASURE_DENOMINATOR=1`, full-facts inventory MUST
  report `auditor_pruned_total_files` and `scan_coverage_ratio`.
- **FR-005**: Denominator measurement MUST preserve scan-limit status and
  non-authorization semantics.
- **FR-006**: Documentation MUST describe the opt-in environment variables and
  compatibility fields.

## Success Criteria *(mandatory)*

- **SC-001**: Focused audit-run receipt tests pass.
- **SC-002**: Focused dual-inventory tests pass.
- **SC-003**: `make test` passes.
- **SC-004**: `make check` passes.
