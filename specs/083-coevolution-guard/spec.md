# Feature Specification: Co-Evolution Guard

**Feature Branch**: `briancl2/auditor-coevo-check-20260510T0330`
**Spec Directory**: `specs/083-coevolution-guard`
**Status**: Draft
**Input**: BMA advisor run against repo-auditor produced PASS-scored
recommendation "Raise co-evolution ratio with paired surface+test edits" after
fresh scorecard evidence reported D2 co-evolution ratio 0.22 and
`T2-COEVO-LOW`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Block unpaired governed surface edits (Priority: P1)

As a repo-auditor maintainer, I need changes to agent specs, detection
signatures, and schemas to carry a paired test or fixture delta so surface
growth does not outrun executable proof.

**Independent Test**: Run the focused co-evolution guard test and verify
governed surface-only changes fail while the same changes pass when paired with
`tests/` or `fixtures/` deltas.

### User Story 2 - Preserve normal checks for unrelated changes (Priority: P1)

As a contributor, I need docs-only and ordinary implementation changes outside
the governed surface set to avoid false-positive failures from the new guard.

**Independent Test**: Run the focused guard test and verify docs-only changes
pass without requiring a test delta.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `make check` MUST run a deterministic co-evolution guard.
- **FR-002**: The guard MUST treat `.agents/`, `.github/agents/`,
  `scripts/detect-*.sh`, and `schemas/*.json` as governed surfaces.
- **FR-003**: Governed surface changes MUST fail unless the same change set
  includes a `tests/` or `fixtures/` delta.
- **FR-004**: The guard MUST support staged pre-commit checks and post-commit
  checks against the latest commit.
- **FR-005**: Documentation MUST name the co-evolution expectation and the
  governed surface set.
- **FR-006**: The change MUST NOT mutate target repositories or alter audit
  scoring semantics.

## Success Criteria *(mandatory)*

- **SC-001**: Focused co-evolution guard tests pass.
- **SC-002**: `make test` passes.
- **SC-003**: `make check` passes.
- **SC-004**: A fresh repo-auditor self-audit no longer reports
  `T2-COEVO-LOW` for the current change when evaluated with this paired
  surface+test delta.
