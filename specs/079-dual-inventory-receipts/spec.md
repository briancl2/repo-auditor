# Feature Specification: Dual Inventory Receipts

**Feature Branch**: `bma-p5-dual-inventory`  
**Spec Directory**: `specs/079-dual-inventory-receipts`  
**Created**: 2026-05-08  
**Status**: Draft  
**Input**: BMA repo-star P5 companion batch: expose primary-surface and full-facts inventory receipts, or explicit unavailable states, without changing score semantics.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Separate primary surfaces from full facts (Priority: P1)

As an optimizer or advisor consumer, I need to know whether the auditor saw
primary instruction/agent/skill/governance surfaces separately from the broader
fact corpus so cleanup and recommendation contracts do not treat missing
inventory as authorization.

**Independent Test**: Run the inventory collector against a fixture target with
AGENTS.md, agent, skill, docs, and code files; verify primary and full-facts
inventory receipts are present and score fields are unchanged.

**Acceptance Scenarios**:

1. **Given** primary AI surfaces exist, **When** audit receipts are finalized,
   **Then** `SCORECARD_RECEIPTS.json.primary_surface_inventory` records them by
   category with bounded path samples.
2. **Given** broader target files exist, **When** audit receipts are finalized,
   **Then** `SCORECARD_RECEIPTS.json.full_facts_inventory` records fact-class
   counts without enumerating every target-private path.
3. **Given** existing scorecard fields, **When** inventory metadata is added,
   **Then** composite, dimensions, tier checks, and count reconciliation stay
   unchanged.

### User Story 2 - Fail informationally, not authoritatively (Priority: P1)

As a downstream cleanup consumer, I need unavailable or empty inventory states
to mean "insufficient evidence", not "safe to mutate."

**Independent Test**: Run the collector against a target with no primary
surfaces and verify status is available-empty plus an explicit non-authorization
statement.

**Acceptance Scenarios**:

1. **Given** no primary surfaces are detected, **When** receipts are written,
   **Then** the primary inventory status is explicit and non-authorizing.
2. **Given** inventory collection cannot run, **When** receipts are written,
   **Then** the unavailable status blocks stronger downstream claims.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST add `primary_surface_inventory` to
  `SCORECARD_RECEIPTS.json`.
- **FR-002**: The system MUST add `full_facts_inventory` to
  `SCORECARD_RECEIPTS.json`.
- **FR-003**: The primary inventory MUST distinguish instruction roots, agent
  definitions, skill definitions, governance/spec surfaces, validation surfaces,
  and workflow surfaces where present.
- **FR-004**: The full-facts inventory MUST report fact-class counts without
  enumerating every target-private path.
- **FR-005**: Missing, empty, scan-limited, or unavailable inventory MUST be
  represented as insufficient evidence, not cleanup authorization.
- **FR-006**: `SCORECARD.json` MUST preserve current scoring semantics and may
  add only a compact receipt pointer/status.
- **FR-007**: `docs/invocation-contract.md` MUST document the new receipt fields.

### Key Entities

- **Primary Surface Inventory**: Bounded inventory of target surfaces that most
  directly carry AI instructions, agent behavior, governance, validation, or
  workflow authority.
- **Full Facts Inventory**: Counted inventory of the broader auditor-pruned fact
  corpus by coarse file class.

## Success Criteria *(mandatory)*

- **SC-001**: Focused dual-inventory tests pass.
- **SC-002**: `make test` passes.
- **SC-003**: `make check` passes.
- **SC-004**: Local review reports no unresolved CRITICAL/HIGH findings.
