# Feature Specification: External Critique Profile Drift

**Feature Branch**: `briancl2-detect-critique-profile-drift`
**Spec Directory**: `specs/084-external-critique-profile-drift`
**Status**: Active
**Input**: Issue #212 and repo-agent-core external-critique capability contract
v1.2 at merge `8ea9f753bf1b1f9a8ad5a28730ec8bf11f315a50`.

## User Scenarios & Testing

### User Story 1 - Detect stale configured critique slots (Priority: P1)

As a repo auditor, I need AS-08 to compare live external-critique mechanism
slots with the portable profile so active legacy GPT-5.5 critique routing and
implicit effort are evidence-backed findings.

**Independent Test**: Run the focused AS-08 test and verify legacy BMA-style
`gpt-5.5|xhigh` and vault-style implicit-effort GPT-5.5 configurations fire.

### User Story 2 - Preserve bounded precision (Priority: P1)

As a target owner, I need AS-08 to ignore compatibility examples, unrelated
review/Hermes/P11 model uses, prose-only mentions, and historical artifacts so
profile drift does not become generic model scanning.

**Independent Test**: Run the negative fixtures and the read-only upgraded BMA
precision gate and verify no profile-drift evidence is emitted.

## Requirements

- **FR-001**: Extend AS-08 only; do not add a detector wrapper or updater.
- **FR-002**: Inspect only live external-critique mechanism paths, existing
  AS-08 capability surfaces, or surfaces carrying
  `EXTERNAL_CRITIQUE_CAPABILITY`.
- **FR-003**: Treat `claude-opus-4.8|max` as the default slot and
  `claude-opus-4.8|max`, `gemini-3.1-pro-preview|high`, and
  `gpt-5.6-sol|max` as the canonical latest-panel slots.
- **FR-004**: Emit `stale_critique_profile`,
  `legacy_gpt_critique_slot`, and `missing_explicit_critique_effort`
  evidence, live mechanism paths, and detected model-effort pairs.
- **FR-005**: Do not treat `xhigh` without an active critique model slot as
  stale.
- **FR-006**: Exclude archive, history, work, receipt, report, example, fixture,
  and output evidence from configured-profile findings.
- **FR-007**: Do not infer runtime availability or mutate target repositories.
- **FR-008**: Preserve the detector script-count invariant.

## Success Criteria

- **SC-001**: All seven requested profile fixture outcomes pass.
- **SC-002**: Upgraded BMA emits no new profile-drift class.
- **SC-003**: Untouched vault emits the known active GPT-5.5 and missing-effort
  findings without unrelated GPT-5.5 paths.
- **SC-004**: Focused tests, `make check`, `make test`, and `make validate` pass.
