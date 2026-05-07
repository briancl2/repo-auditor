# Feature Specification: Audit Run Receipt and Partial Artifact Metadata

**Feature Branch**: `bma-phase1-audit-receipt`  
**Spec Directory**: `specs/076-audit-run-receipt`  
**Created**: 2026-05-07  
**Status**: Draft  
**Input**: Repo-star Phase 1 P1 / PR 1A: add an audit run receipt and partial-artifact metadata so auditor consumers can distinguish completed, partial, and failed audits.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Distinguish audit outcomes from machine artifacts (Priority: P1)

As a downstream consumer of repo-auditor output, I need a machine-readable run receipt that tells me whether an audit completed, partially produced artifacts, or failed, so I do not infer status from missing files.

**Why this priority**: Repo-star Phase 1 P1 depends on reliable audit receipts before downstream fleet orchestration can consume auditor artifacts safely.

**Independent Test**: Run the auditor against a clean fixture, a fixture whose report path cannot be written, and a missing target path; verify `AUDIT_RUN_RECEIPT.json` status and reason fields.

**Acceptance Scenarios**:

1. **Given** a clean auditable repository, **When** the audit completes, **Then** `AUDIT_RUN_RECEIPT.json` has `status=completed`.
2. **Given** a run that produces a scorecard but cannot write `AUDIT_REPORT.md`, **When** the audit exits, **Then** `AUDIT_RUN_RECEIPT.json` has `status=partial`.
3. **Given** an invalid target repository path, **When** the audit exits, **Then** `AUDIT_RUN_RECEIPT.json` has `status=failed` and a non-empty `reason`.

### Edge Cases

- Report path exists but is not a regular file.
- Target path is missing before any audit tools run.
- `SCORECARD.json` exists while one or more required report artifacts are absent.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Standard audit runs MUST write `AUDIT_RUN_RECEIPT.json` in the requested output directory whenever an output directory is available.
- **FR-002**: Completed audits MUST write receipt `status` as `completed`.
- **FR-003**: Report-generation failures after scorecard creation MUST write receipt `status` as `partial`.
- **FR-004**: Failed audits MUST write receipt `status` as `failed` with a non-empty `reason`.
- **FR-005**: `SCORECARD.json.meta` MUST carry partial artifact metadata when required artifacts are absent.
- **FR-006**: Added metadata MUST NOT change existing dimension scores, composite score, tier checks, or score receipt semantics for complete audits.
- **FR-007**: `docs/invocation-contract.md` MUST document receipt fields and partial-artifact semantics.

### Key Entities

- **Audit Run Receipt**: JSON artifact describing run status, reason, exit code, required artifact presence, and failed tools.
- **Scorecard Metadata**: `SCORECARD.json.meta` fields that mirror run/artifact status for consumers already reading the scorecard.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Focused tests cover completed, partial report-generation failure, and failed target cases.
- **SC-002**: `make check` passes.
- **SC-003**: Relevant audit receipt tests pass locally.
