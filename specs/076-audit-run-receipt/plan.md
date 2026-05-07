# Implementation Plan: Audit Run Receipt and Partial Artifact Metadata

**Branch**: `bma-phase1-audit-receipt` | **Date**: 2026-05-07 | **Spec**: `specs/076-audit-run-receipt/spec.md`

## Summary

Add a small run-finalization layer to `scripts/repo-auditor.sh` that writes `AUDIT_RUN_RECEIPT.json` and updates `SCORECARD.json.meta` after required artifacts are known. Keep scoring logic unchanged.

## Technical Context

**Language/Version**: Bash 3.2-compatible shell with Python 3 for JSON updates  
**Primary Dependencies**: Existing repo-auditor shell/Python scripts  
**Storage**: File artifacts in caller-provided `OUTPUT_DIR`  
**Testing**: Existing shell tests under `tests/test-*.sh`  
**Target Platform**: macOS/Linux shell environments  
**Constraints**: No target repo mutation; standard mode remains deterministic; no P2-P7 work  
**Scale/Scope**: PR 1A only: receipt artifact, scorecard metadata, documentation, focused tests

## Constitution Check

- Keep target repositories read-only.
- Preserve current score semantics for complete audits.
- Prefer deterministic shell/Python tests already used by the repo.
- Do not implement downstream optimizer, target-native adapters, or coverage verdicts.

## Project Structure

```text
scripts/
└── repo-auditor.sh

docs/
└── invocation-contract.md

tests/
└── test-audit-run-receipt.sh

specs/076-audit-run-receipt/
├── spec.md
└── plan.md
```

**Structure Decision**: Implement within the existing standard audit orchestrator and shell test suite; no new runtime package or broad refactor.

## Validation

1. `bash tests/test-audit-run-receipt.sh`
2. `make check`
