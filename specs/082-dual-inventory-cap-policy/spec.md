# Feature Specification: Dual-Inventory Cap Policy

**Feature Branch**: `briancl2/bma-cap-policy-20260509T134457Z`
**Spec Directory**: `specs/082-dual-inventory-cap-policy`
**Status**: Draft
**Input**: BMA Burst 1B high-cap/P5 receipt exercise and prior cap-curve evidence
showed current repo-star owner repos complete at cap 1000 while larger
Vault/BMA-scale targets require explicit high-cap trusted-local measurement.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Bounded default covers repo-star owner repos (Priority: P1)

As a fleet operator, I need repo-auditor's default dual-inventory receipt cap to
cover current repo-star owner repos without classifying them as scan-limited.

**Independent Test**: Run the focused dual-inventory receipt test and verify the
default receipt reports `scan_limit=1000` while a fixture larger than 1000 files
still reports `available_limited`.

### User Story 2 - Larger local targets remain opt-in (Priority: P1)

As a fleet operator auditing trusted local large targets, I need the higher-cap
path to require an explicit environment override so default audits remain
bounded.

**Independent Test**: Run the focused dual-inventory receipt test and verify the
same >1000-file fixture is complete only when
`REPO_AUDITOR_DUAL_INVENTORY_MAX_FILES` is explicitly set above the fixture
denominator.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The default dual-inventory scan cap MUST be 1000 auditor-pruned
  files.
- **FR-002**: Default scans MUST remain bounded; targets above the default cap
  MUST report limited inventory rather than silently scanning all files.
- **FR-003**: Any cap above the default MUST require the existing explicit
  `REPO_AUDITOR_DUAL_INVENTORY_MAX_FILES=<n>` override.
- **FR-004**: The change MUST NOT alter dirty-target guards, mutate targets,
  implement a sampler/selector, or change score semantics.
- **FR-005**: Documentation and policy surfaces MUST describe the default cap
  and trusted-local opt-in high-cap boundary.

## Success Criteria *(mandatory)*

- **SC-001**: Focused dual-inventory receipt tests pass.
- **SC-002**: `make test` passes.
- **SC-003**: `make check` passes.
