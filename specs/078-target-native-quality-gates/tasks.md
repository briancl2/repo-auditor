# Tasks: Target-Native Quality Gate Receipts

**Input**: Design documents from `/specs/078-target-native-quality-gates/`
**Prerequisites**: plan.md, spec.md

## Phase 1: Setup

- [x] T001 Create feature spec and plan under `specs/078-target-native-quality-gates/`.
- [x] T002 Open work contract for the implementation branch.

## Phase 2: Tests

- [x] T003 Add targeted fixture test in `tests/test-target-native-quality-gates.sh`.
- [x] T004 Cover research-mode partial, no-gate, and unclassified gate-like cases.

## Phase 3: Implementation

- [x] T005 Add `scripts/collect-target-native-quality-gates.py`.
- [x] T006 Hook the helper into `scripts/repo-auditor.sh` as an additive post-report receipt step.
- [x] T007 Update `schemas/SCORECARD.schema.json` for the optional receipt pointer.

## Phase 4: Documentation

- [x] T008 Update `docs/invocation-contract.md`, `README.md`, and owner repo instruction inventory.

## Phase 5: Validation

- [x] T009 Run targeted tests.
- [x] T010 Run `make test`.
- [x] T011 Run `make check`.
- [x] T012 Run retained review.
