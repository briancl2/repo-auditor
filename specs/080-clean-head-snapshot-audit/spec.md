# Feature Specification: Clean HEAD Snapshot Audit

**Feature Branch**: `briancl2/clean-head-snapshot-audit`  
**Spec Directory**: `specs/080-clean-head-snapshot-audit`  
**Status**: Draft  
**Input**: BMA overnight readiness evidence showed the real Vault target failed the default audit guard because the live worktree had pre-existing untracked files, while a clean HEAD clone produced valid receipts without target mutation.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Keep dirty-target protection by default (Priority: P1)

As an auditor operator, I need the standard audit command to continue failing on
dirty git targets so accidental contaminated audits are not normalized.

**Independent Test**: Run `scripts/repo-auditor.sh` against a dirty fixture repo
and verify it exits non-zero before writing scorecard artifacts.

**Acceptance Scenarios**:

1. **Given** a target git repo has untracked or modified files, **When** the
   standard audit is invoked, **Then** the operation guard fails.
2. **Given** the standard audit fails on a dirty target, **When** outputs are
   inspected, **Then** consumers do not see a completed scorecard receipt set.

### User Story 2 - Audit a clean HEAD snapshot explicitly (Priority: P1)

As a BMA or fleet operator, I need an explicit read-only clean-HEAD snapshot path
for dirty real-world targets so I can collect committed-state receipts without
mutating the target or weakening the standard guard.

**Independent Test**: Run the clean-HEAD snapshot wrapper against a dirty fixture
repo and verify it succeeds against a separate clean snapshot while the source
repo stays dirty and at the same HEAD.

**Acceptance Scenarios**:

1. **Given** a dirty source repo, **When** the snapshot wrapper is invoked with a
   caller-owned snapshot directory, **Then** it clones the committed HEAD into
   that directory without local hardlinks.
2. **Given** the wrapper completes, **When** `SCORECARD_RECEIPTS.json` is read,
   **Then** it contains a compact `clean_head_snapshot` pointer and the full
   provenance is retained in `CLEAN_HEAD_SNAPSHOT_RECEIPT.json`.
3. **Given** the source repo has untracked files, **When** the wrapper completes,
   **Then** those files remain outside the snapshot and the receipt states the
   audit mode is `clean-head-snapshot`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The standard `scripts/repo-auditor.sh` invocation MUST keep the
  existing dirty git target failure behavior.
- **FR-002**: The system MUST provide an explicit clean-HEAD snapshot invocation
  that writes outputs to the caller-provided output directory.
- **FR-003**: The snapshot invocation MUST clone without local hardlinks and MUST
  refuse to reuse an existing snapshot directory.
- **FR-004**: The snapshot invocation MUST write
  `CLEAN_HEAD_SNAPSHOT_RECEIPT.json` with source path, source HEAD, source dirty
  status/counts, snapshot path, snapshot HEAD, snapshot tree, and audit exit
  status.
- **FR-005**: Completed snapshot audits MUST add compact snapshot provenance to
  `SCORECARD_RECEIPTS.json` and `SCORECARD.json.receipts` without changing score
  semantics.
- **FR-006**: Snapshot mode MUST not claim to solve scan-limit pressure or
  authorize cleanup/deletion/archival/rewrite of target files.
- **FR-007**: Documentation MUST distinguish live-target audit evidence from
  clean-HEAD snapshot evidence.

### Key Entities

- **Clean HEAD Snapshot**: A separate cloned repository at the source target's
  committed HEAD, excluding uncommitted and untracked source worktree state.
- **Snapshot Provenance Receipt**: Machine-readable metadata that prevents
  downstream consumers from treating snapshot metrics as live dirty-tree metrics.

## Success Criteria *(mandatory)*

- **SC-001**: Focused snapshot wrapper tests pass.
- **SC-002**: `make test` passes.
- **SC-003**: `make check` passes.
- **SC-004**: Local review reports no unresolved CRITICAL/HIGH findings.
