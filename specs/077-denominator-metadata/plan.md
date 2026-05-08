# Implementation Plan: Scorecard Denominator Metadata

**Branch**: `bma-phase3a-denominator-metadata` | **Date**: 2026-05-08 | **Spec**: `specs/077-denominator-metadata/spec.md`

## Summary

Add descriptive denominator metadata inside
`SCORECARD_RECEIPTS.json.count_reconciliation`. Preserve existing counts and
status fields exactly; this is an additive receipt/schema documentation change,
not a scanning behavior change.

## Technical Context

**Language/Version**: Bash 3.2-compatible shell with Python 3 for JSON checks
**Primary Dependencies**: Existing repo-auditor shell/Python scripts
**Storage**: File artifacts in caller-provided `OUTPUT_DIR`
**Testing**: Existing shell tests under `tests/test-*.sh`
**Target Platform**: macOS/Linux shell environments
**Constraints**: No target repo mutation; no count behavior change; no BMA shared-surface edits
**Scale/Scope**: P7 denominator metadata only

## Constitution Check

- Keep target repositories read-only.
- Preserve score and count semantics.
- Keep metadata machine-readable and additive.
- Do not enumerate target-private `.auditorignore` path values in scorecard receipts.

## Project Structure

```text
scripts/
└── score-audit-dimensions.sh

docs/
└── invocation-contract.md

tests/
└── test-denominator-metadata.sh

specs/077-denominator-metadata/
├── spec.md
└── plan.md
```

**Structure Decision**: Implement inside the existing scorecard receipt writer
and focused shell test suite; do not introduce a shared config loader or new
runtime dependency for this additive metadata.

## Validation

1. `bash tests/test-denominator-metadata.sh`
2. `make test`
3. `make check`
4. `make review`
