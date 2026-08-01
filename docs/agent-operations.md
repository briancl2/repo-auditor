# Agent and runtime operations

This is a descriptive inventory of the retained audit product. It does not
create a second owner route. Delivery authority remains the owner issue,
`AGENTS.md`, `.agents/skills/repo-auditor-owner-settlement/SKILL.md`, and live
GitHub settlement evidence.

## Runtime entrypoints

| Surface | Role |
|---|---|
| `Makefile` | Native audit, validation, review, and test commands |
| `scripts/repo-auditor.sh` | Deterministic audit entrypoint |
| `.agents/skills/pre-scanning/` | Bounded pre-scan implementation |
| `scripts/assemble_ds_results.py` | DS/AS detector bundle runner |
| `scripts/score-audit-dimensions.sh` | Five-dimension bounded scorecard |
| `scripts/score-operation.sh` | Audit-output quality check, not owner authority |
| `scripts/operation-guard.sh` | Read-only target and concurrency guard |
| `scripts/closure_identity.py` | Local/CI run identity evidence |
| `scripts/validate_owner_convergence.py` | Cached-index owner convergence guard |

The deterministic detectors live under `scripts/detect-*.sh`; supporting
signature documentation lives under `detection-signatures/`. The inventory and
graduation status of the currently graduated/retained detector subset are in
`docs/detector-graduation-ledger.md`.

## Deep-mode agents

The retained `.agents/*.agent.md` files are deep-mode domain auditors and the
audit synthesis surface. They are single-level, bounded, read-only target
inspectors. Deep mode is opt-in and each domain auditor inspects at most 30
files.

The retained skills are:

- `.agents/skills/pre-scanning/` for deterministic target inventory;
- `.agents/skills/detection-signatures/` for signature semantics;
- `.agents/skills/scoring/` for bounded audit scoring;
- `.agents/skills/reviewing-code-locally/` for staged-diff review; and
- `.agents/skills/repo-auditor-owner-settlement/` for the one repository-change
  lifecycle route.

## Shared-core consumers

The exact compatible repo-agent-core baseline is
`9da7b41b83a10b9fd71ad24b0529a50425a8d373`. The retained direct exports and
caller tokens are frozen in `docs/live-capability-inventory.md`.

- `scripts/validate-floor-receipt.sh` and
  `scripts/compare-scorecards.sh` remain exact copied bytes.
- `schemas/FINDINGS.schema.json` and `schemas/SCORECARD.schema.json` remain
  owner-extended compatible bytes unchanged from the repo-auditor rollback
  base.
- `schemas/OPPORTUNITIES.schema.json` and
  `schemas/OPTIMIZATION_SCORECARD.schema.json` remain exact shared bytes.
- `make install-hooks` is an explicit foreground call to the core installer; it
  is not a runtime link or background updater.

## Tests, fixtures, and privacy

`tests/test-*.sh` is the native suite. `tests/fixtures/` contains deterministic
audit fixtures, not active owner state. Fixture references to plans, work
directories, closeout artifacts, Spec Kit paths, or Issue #164 vocabulary are
detector inputs only; they do not reactivate those local lifecycle families.

Ordinary-task fixtures use the compact update, terminal, coordinator, and
sparse-continuation behavior in `AGENTS.md`. They intentionally carry no
campaign-runtime payload. AS-25 remains scoped to runtime-improvement claims,
AS-26 to failures diverted from direct owner repair, and AS-43 to capability
placement or authority-overclaim material.

`config/policy.yaml` is a target-native quality-gate classification input.
`.gitignore` excludes generated audit/work noise. Installed harness discovery
for skills, agents, instructions, and prompts is count-only: validators must not
emit private names or content.

## Review and recovery

`make review` reads the staged diff, suppresses inherited stdin, and fails closed
at its bounded timeout. It is review evidence, not merge authority.

Recovery for an owner change is ordinary Git revert from the owner PR. Audit
target recovery is out of scope because repo-auditor never mutates targets.
