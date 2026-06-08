# Feature Specification: Target-Native Quality Gate Receipts

**Feature Branch**: `078-target-native-quality-gates`  
**Created**: 2026-05-08  
**Status**: Draft  
**Input**: User description: "Add a P2 target-native quality-gate adapter that keeps the generic fleet score visible, reports target-local quality gates as parallel truth, labels partial evidence as research-mode/non-verdict, preserves non-Vault behavior, and routes unclassified cases to amendment."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Preserve Generic Score While Reporting Local Gate (Priority: P1)

An audit consumer can see the normal fleet scorecard and, when a target exposes
a retained local quality gate artifact, a separate target-native receipt that
describes the local gate state.

**Why this priority**: The core P2 risk is replacing or hiding the portable
fleet score with target-local truth. The adapter must be additive.

**Independent Test**: Run the adapter against an audit output with a local gate
fixture and verify `SCORECARD.json.composite` remains unchanged while
`TARGET_NATIVE_QUALITY_GATES.json` and receipt pointers are added.

**Acceptance Scenarios**:

1. **Given** a target with a parseable retained quality-gate report and a generic
   scorecard, **When** the adapter runs, **Then** the generic composite remains
   present and unchanged.
2. **Given** a target with local gate evidence, **When** the adapter runs,
   **Then** target-native status is emitted as a parallel receipt, not as a
   replacement score.

---

### User Story 2 - Label Partial Evidence as Research Mode (Priority: P1)

A retained partial Vault-shaped diagnostic can be studied without becoming a
target-quality verdict.

**Why this priority**: The admission proof is a research-mode partial fixture.
It must not create a strong contradiction claim.

**Independent Test**: Run the adapter against a partial audit output missing the
contracted report surface and verify contradiction is `partial_run_no_verdict`
with a bounded non-claim.

**Acceptance Scenarios**:

1. **Given** a partial audit output with a local gate report, **When** the
   adapter runs, **Then** it emits `partial_run_no_verdict`.
2. **Given** a partial audit output, **When** the adapter emits receipts,
   **Then** the receipt states the partial diagnostic is not a target-quality
   verdict.

---

### User Story 3 - Preserve Non-Vault and Unknown-Gate Behavior (Priority: P2)

Targets without local gates receive explicit no-gate receipts, and gate-like
artifacts that the adapter cannot classify require amendment instead of silent
success.

**Why this priority**: The adapter must not hardcode Vault doctrine or force all
targets into Vault-shaped categories.

**Independent Test**: Run the adapter against a no-gate fixture and an
unclassified gate-like fixture; verify the no-gate fixture emits
`no_retained_gate` and the unclassified fixture emits
`unclassified_requires_amendment`.

**Acceptance Scenarios**:

1. **Given** a non-Vault target with no retained local gate, **When** the adapter
   runs, **Then** a `no_retained_gate` target-native receipt is emitted without
   changing the generic score.
2. **Given** a target with a gate-like artifact that cannot be classified,
   **When** the adapter runs, **Then** it emits
   `unclassified_requires_amendment`.

### Edge Cases

- Missing `SCORECARD.json` or `SCORECARD_RECEIPTS.json` emits `partial_run`
  evidence from the run receipt without fabricating a target-quality verdict.
- Multiple local gate candidates are recorded as sources; classification uses
  parseable evidence only.
- Completed generic audits with local gate conflicts use provisional enums and
  keep bounded non-claims.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST keep `SCORECARD.json.composite`, dimensions, and
  Tier-1/Tier-2 fields available and unchanged by target-native receipt
  collection.
- **FR-002**: The system MUST emit target-native gate evidence as a parallel
  receipt when a retained local gate artifact is found.
- **FR-003**: The system MUST label incomplete audit outputs as
  `partial_run_no_verdict` and state that partial diagnostics are not
  target-quality verdicts.
- **FR-004**: The system MUST emit explicit `no_retained_gate` target-native
  detail for targets with no local gate evidence.
- **FR-005**: The system MUST route unclassified gate-like evidence to
  `unclassified_requires_amendment`.
- **FR-006**: The system MUST use only deterministic retained artifact parsing
  and MUST NOT run target-local quality commands.
- **FR-007**: The contradiction values MUST remain provisional and limited to
  `target_policy_explained`, `unresolved`, `true_target_risk`,
  `fleet_metric_stale`, `partial_run_no_verdict`, and
  `unclassified_requires_amendment`.

### Key Entities

- **TargetNativeQualityGateReceipt**: Parallel receipt containing adapter
  version, status, sources, local gate state, generic score summary,
  contradiction enum, amendment flag, and bounded non-claim.
- **Gate Source**: A retained target artifact that appears to describe a quality
  gate and can be parseable, unclassified, or absent.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Targeted tests pass for research-mode partial, no-gate, and
  unclassified gate-like fixtures.
- **SC-002**: In the partial fixture, `SCORECARD.json.composite` remains `28`
  and contradiction is `partial_run_no_verdict`.
- **SC-003**: In the no-gate fixture, `TARGET_NATIVE_QUALITY_GATES.json` is
  emitted with `target_gate_state=no_retained_gate` and `SCORECARD.json`
  carries a target-native pointer.
- **SC-004**: In the unclassified fixture, contradiction is
  `unclassified_requires_amendment` and amendment is required.
