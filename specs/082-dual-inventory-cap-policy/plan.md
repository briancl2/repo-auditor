# Implementation Plan: Dual-Inventory Cap Policy

## Scope

Raise the default dual-inventory scan cap from 200 to 1000 and document that
larger trusted-local runs remain opt-in through the existing max-files
environment override.

## Evidence Basis

- Prior cap-curve evidence showed repo-auditor, repo-optimizer, and
  repo-upgrade-advisor complete at cap 1000 while cap 200 is scan-limited.
- Burst 1B receipts showed two Vault and two BMA high-cap runs completed with
  full coverage, admitting policy scoping only.
- The evidence does not admit a sampler/selector, dirty-target guard weakening,
  target mutation, or default unbounded scan.

## Touch Surface

- `scripts/collect-dual-inventory.py`
- `tests/test-dual-inventory-receipts.sh`
- `docs/invocation-contract.md`
- `AGENTS.md`
- `.specify/memory/constitution.md`

## Non-Goals

- No scoring changes.
- No sampler or selector implementation.
- No dirty-target guard changes.
- No target-private full path emission.
- No target mutation.

## Validation

- `bash tests/test-dual-inventory-receipts.sh`
- `make test`
- `make check`
