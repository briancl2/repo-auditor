# AGENTS.md — repo-auditor

> Machine-readable repository health scorer. Standard mode is deterministic;
> deep mode adds LLM domain auditors. Target repositories are never modified.

## Purpose

`repo-auditor` evaluates a repository's AI-native maturity across five
dimensions and emits `SCORECARD.json`, `AUDIT_REPORT.md`, pre-scan artifacts,
and optional governed receipts. Keep this file as the live bootloader; detailed
agent, skill, script, output, and token-budget inventories live in
`docs/agent-operations.md`.

## Operating Rules

- Standard mode is default and deterministic. Deep mode is opt-in through
  `make audit-deep`.
- Target repos are read-only. Do not edit, format, commit, or clean targets.
- The core-five repos are reciprocal proving grounds for ordinary validation:
  build-meta-analysis, repo-agent-core, repo-auditor, repo-upgrade-advisor, and
  repo-optimizer may validate against each other as read-only targets. This
  validation is not downstream adoption or write authority; each core-five repo
  changes only through its own owner issue, branch, PR, checks, and merge.
- `--no-verify` is never permitted.
- `make check` runs before every commit; `make review` is recommended for
  larger or governed changes.
- Raw command output stays in receipts/logs. Governed artifacts summarize
  command, outcome, and retained path instead of copying transcripts.
- `score-session.sh` remains the default local closeout scorer. For explicit
  GitHub issue/PR-backed work, use `scripts/work-close.sh
  --github-native-closeout` so GitHub closure truth is not re-graded as local
  session ceremony.
- Advisory GBrain distribution into repo-local instructions consumes
  repo-agent-core `docs/gbrain-repo-local-instruction-distribution-contract.md`
  and `templates/gbrain-repo-local-instruction-distribution.md` by copy-sync or
  citation only. GBrain remains advisory: use records only with
  source/citation/provenance or GitHub surface references, never as canonical
  truth, and never to override operator intent, GitHub issue/PR/check/merge
  truth, target/repo evidence, or repo-local instructions. Route stale,
  missing, uncited, or overclaiming guidance to the owner surface. Do not use
  GBrain bulk import, sync/watch, cron, autopilot, dream, jobs worker, MCP
  serving, minions, daemons, schedulers, queues, hidden registries, or
  background memory behavior.
- Governed surface edits under `.agents/`, `.github/agents/`,
  `scripts/detect-*.sh`, or `schemas/*.json` require paired `tests/` or
  `fixtures/` changes in the same change set.

## Commands

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
make review
make work DESC="..."
make work-close WORK=work/<dir>
bash scripts/work-close.sh work/<dir> --github-native-closeout "rationale"
make install-hooks
```

## Key Outputs

- `SCORECARD.json`: five-dimension scorecard, composite score, T1/T2 checks,
  and maturity phase.
- `AUDIT_REPORT.md`: human-readable findings and recommendations.
- `PRE_SCAN.md`: file inventory and AI-surface analysis.
- `DS-34-plus-results.json`: extended deterministic signature bundle.
- `TARGET_NATIVE_QUALITY_GATES.json`: additive target-local quality-gate
  classification for retained gates, no retained gate, or partial-run states.

## Stop Rules

- Max 1000 target files scanned by default; higher caps require an explicit
  trusted-local override.
- Deep-mode domain subagents inspect at most 30 files each.
- Max 900 seconds per run.
- Halt on pre-scan failure.
- Do not infer exhaustive target truth from scan-limited or snapshot-only
  evidence.

## References

- Invocation contract: `docs/invocation-contract.md`
- Current program status: `docs/current-program-status.md`
- Agent operations inventory: `docs/agent-operations.md`
- Constitution: `.specify/memory/constitution.md`
