# Implementation Plan: Cap-Curve Receipt Fields

## Scope

Add additive measurement metadata to existing receipts: run-level elapsed time
in `AUDIT_RUN_RECEIPT.json` and opt-in denominator/coverage fields in
dual-inventory receipts.

## Touch Surface

- `scripts/repo-auditor.sh`
- `scripts/collect-dual-inventory.py`
- `tests/test-audit-run-receipt.sh`
- `tests/test-dual-inventory-receipts.sh`
- `docs/invocation-contract.md`

## Non-Goals

- No scoring changes.
- No default cap increase.
- No sampler or selector implementation.
- No dirty-target guard change.
- No target-private full path emission.

## Validation

- Focused audit-run receipt test.
- Focused dual-inventory test.
- `make test`.
- `make check`.
