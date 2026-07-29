# AGENTS.md — repo-auditor

Read root `CONSTITUTION.md` first. It is the exact shared semantic floor. This
bootloader is subordinate repo-auditor policy and cannot change constitutional
meaning.

## Product boundary

`repo-auditor` is a read-only repository audit product. Standard mode is
deterministic; deep mode is opt-in. It emits bounded findings, scorecards,
pre-scan evidence, and human-readable reports. Scores and maturity labels are
diagnostic proxies, never constitutional authority or target mutation
authority.

- Never edit, format, commit, clean, or otherwise mutate a target repository.
- Preserve deterministic detection signatures, finding/schema semantics,
  privacy-safe receipts, bounded scans, and fail-closed audit behavior.
- Do not infer exhaustive target truth from scan-limited, snapshot-only, failed,
  or partial evidence.
- The core-five repositories may be reciprocal read-only proving grounds. Each
  repository still changes only through its own owner issue, branch, pull
  request, checks, review, and merge.

## Owner route

`.agents/skills/repo-auditor-owner-settlement/SKILL.md` is the one lifecycle
route for an authorized change to this repository. Current cached Git bytes and
live GitHub issue, pull request, check, review, merge, and readback evidence
outrank retained plans, reports, memory, and prior sessions.

For every owner change:

1. Name one owner issue and exact base.
2. Use one branch, one preserved worktree, and one pull request.
3. Inspect direct callers before mutation and delete obsolete machinery instead
   of adding compatibility scaffolding.
4. Run the smallest focused checks, then `make check`, `make test`, and
   `make validate`.
5. Run `make review` on the whole staged diff. Resolve CRITICAL and HIGH
   findings; disposition lower-severity advice without widening scope.
6. Require the applicable GitHub checks and review on the exact head.
7. Merge only with owner authority, then verify issue, pull request, merge,
   default-branch, and immutable behavior readback.

Never use `--no-verify`. Do not add a controller, registry, dashboard, roadmap,
execution ledger, updater, scheduler, queue, daemon, background process,
automatic target mutation, or auto-merge route.

## Shared-core boundary

The compatible repo-agent-core baseline and every retained direct caller/export
are recorded in `docs/live-capability-inventory.md`.
`scripts/validate_owner_convergence.py` validates that inventory from the exact
cached index and blobs. Copy-synced tools and owner-extended schemas remain
independently runnable here; convergence work must not redesign their semantics.

Advisory GBrain records require source/citation provenance and never override
operator intent, GitHub truth, repository evidence, or these instructions.
Authentication failures follow the owning credential boundary; they do not
authorize browser, cookie, scraping, or alternate-account fallbacks.

## Native commands

```bash
make audit TARGET=~/repos/some-repo
make audit-snapshot TARGET=~/repos/some-repo OUTPUT_DIR=./audit-output SNAPSHOT_DIR=./audit-snapshot
make audit-quick TARGET=~/repos/some-repo
make audit-deep TARGET=~/repos/some-repo
make measure-dual-inventory-cap-curve TARGET=~/repos/some-repo OUTPUT_DIR=<dir> CAPS=200,1000,2500,5000
make token-efficiency-measure OUTPUT_DIR=<dir>
make check
make test
make validate
make validate-owner-convergence
make review
make install-hooks
```

## Output and scan limits

- Primary outputs: `SCORECARD.json`, `AUDIT_REPORT.md`, `PRE_SCAN.md`,
  `DS-34-plus-results.json`, and `TARGET_NATIVE_QUALITY_GATES.json`.
- Default target cap: 1000 files. A higher cap requires an explicit
  trusted-local override.
- Deep-mode domain auditors inspect at most 30 files each.
- Maximum audit run: 900 seconds.
- Halt on pre-scan failure.

Detailed runtime inventory is in `docs/agent-operations.md`; invocation and
output semantics are in `docs/invocation-contract.md`; detector lifecycle
decisions are in `docs/detector-graduation-ledger.md`. `README.md` is the user
entrypoint, `docs/core-five-owner-surface-contract.md` bounds reciprocal
read-only use, and stable historical learning remains in `LEARNINGS.md`.
