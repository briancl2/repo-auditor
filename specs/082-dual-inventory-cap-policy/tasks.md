# Tasks: Dual-Inventory Cap Policy

1. Update `scripts/collect-dual-inventory.py` so the default dual-inventory cap
   is 1000 auditor-pruned files.
2. Extend `tests/test-dual-inventory-receipts.sh` to prove default scans remain
   bounded at 1000 and higher-cap completion requires an explicit
   `REPO_AUDITOR_DUAL_INVENTORY_MAX_FILES` override.
3. Update `docs/invocation-contract.md`, `AGENTS.md`, and the constitution with
   the cap-1000 default and trusted-local high-cap opt-in policy.
4. Run focused dual-inventory validation, `make test`, and `make check`.
