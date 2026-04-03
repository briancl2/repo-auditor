# AGENTS.md — repo-auditor

> Produce machine-readable SCORECARD.json for any repository.
> Two modes: standard (deterministic) and deep (LLM domain subagents).
> `make check` runs on every commit (pre-commit hook). `make review` recommended for large changes. `--no-verify` NEVER permitted.

## Purpose

`repo-auditor` evaluates any repository's AI-native maturity across 5 dimensions,
producing a SCORECARD.json with composite score (0-100), T1/T2 tiered checks, and
maturity phase classification.

## Key Conventions

- **Standard mode** (default) — deterministic, bash scripts only
- **Deep mode** (`--mode deep`) — LLM-powered domain auditors for richer analysis
- Pre-commit hook runs `make check` (shellcheck + inventory + trailer)
- `make review` recommended before committing large changes
- `--no-verify` is NEVER permitted (L102)
- AGENTS.md is the canonical instruction surface (L104)
- Target repos are NEVER modified

## Agents (9)

| # | Agent | Model | Purpose |
|---|---|---|---|
| 1 | repo-auditor | claude-opus-4.6 | Orchestrator — standard/deep mode dispatch |
| 2 | repo-auditor-inbound | claude-opus-4.6 | Inbound invocation (Mode B) |
| 3 | governance-auditor | claude-sonnet-4.5 | D1 Governance dimension (deep mode) |
| 4 | surface-auditor | claude-sonnet-4.5 | D2 Surface Health dimension (deep mode) |
| 5 | skill-auditor | claude-sonnet-4.5 | D3 Skill Maturity dimension (deep mode) |
| 6 | measurement-auditor | claude-sonnet-4.5 | D4 Measurement dimension (deep mode) |
| 7 | improvement-auditor | claude-sonnet-4.5 | D5 Self-Improvement dimension (deep mode) |
| 8 | theater-auditor | claude-sonnet-4.5 | DS-21 Automation Theater detection (deep mode) |
| 9 | audit-synthesis | claude-opus-4.6 | Report synthesis from domain findings (deep mode) |

## Skills (2)

| # | Skill | Purpose |
|---|---|---|
| 1 | reviewing-code-locally | Pre-commit code review via Copilot CLI |
| 2 | pre-scanning | Deterministic pre-scan — file inventory, AI surfaces |

## Scripts (37)

### Core Pipeline

| Script | Purpose |
|---|---|
| `scripts/repo-auditor.sh` | Main orchestrator -- pre-scan, score, report |
| `scripts/score-audit-dimensions.sh` | 5-dimension scorer, SCORECARD.json |
| `scripts/compare-scorecards.sh` | Pre/post delta computation |
| `scripts/classify-repo-maturity.sh` | AI maturity phase classifier |
| `scripts/stall-risk-score.sh` | 6-signal stall risk predictor (0-100) |
| `scripts/extract-repo-dna.sh` | 10-feature Repo DNA fingerprint |
| `scripts/score-session.sh` | 4-dimension 15-point session grader |

### Detection Signatures

| Script | DS | Purpose |
|---|---|---|
| `scripts/detect-capability-drift.sh` | DS-20 | Undocumented tool detector |
| `scripts/detect-automation-theater.sh` | DS-21 | 7-signal automation theater scanner |
| `scripts/detect-warning-noise.sh` | DS-27 | Warning ledger noise ratio |
| `scripts/detect-ceremony-ratio.sh` | DS-29 | Ceremony commit ratio detection |
| `scripts/detect-grader-ceiling.sh` | DS-30 | Grader ceiling lock detection |
| `scripts/detect-content-staleness.sh` | DS-31 | Instruction surface content drift |
| `scripts/detect-feed-forward-stall.sh` | DS-32 | Feed-forward stall detection |
| `scripts/detect-measurement-disconnect.sh` | DS-33 | Measurement-action disconnect |
| `scripts/detect-stale-todos.sh` | DS-34 | Stale TODO/FIXME detection |
| `scripts/detect-unused-deps.sh` | DS-35 | Unused dependency detection |
| `scripts/detect-green-only-ci.sh` | DS-36 | Green-only CI detection |
| `scripts/detect-readme-drift.sh` | DS-37 | README capability drift |
| `scripts/detect-config-proliferation.sh` | DS-38 | Config format proliferation |
| `scripts/detect-silent-errors.sh` | DS-39 | Silent error handling detection |
| `scripts/detect-commit-entropy.sh` | DS-40 | Commit message entropy |
| `scripts/detect-test-theater.sh` | DS-41 | Test theater detection |
| `scripts/detect-broken-links.sh` | DS-42 | Broken internal link detection |
| `scripts/detect-velocity-bypass.sh` | DS-43 | Autonomous velocity bypass |
| `scripts/detect-closeout-control-drift.sh` | DS-44 | Stage 15 closeout-control drift detection |
| `scripts/detect-workflow-contract-drift.sh` | DS-45 | Helper vs agent/prompt/skill workflow-contract drift |
| `scripts/detect-llm-validation-gap.sh` | DS-46 | Validation coverage misses live LLM workflow path |
| `scripts/detect-new-signatures.sh` | -- | Unified runner for DS-34+ |

### Helpers

| Script | Purpose |
|---|---|
| `scripts/assemble_ds_results.py` | Assemble DS-34+ results |
| `scripts/backtest_ds34_42.py` | Backtest DS-34 through DS-42 against targets |
| `scripts/ds_json_helper.py` | Safe JSON output for detection scripts |

### Gates and Hooks

| Script | Purpose |
|---|---|
| `scripts/check.sh` | Gate 2 -- shellcheck + inventory + trailer validation |
| `scripts/work-init.sh` | Gate 1 -- work contract init with baseline SCORECARD |
| `scripts/work-close.sh` | Gate 3 -- post-audit + delta + learnings gate |
| `scripts/pre-commit-hook.sh` | Pre-commit hook -- runs make check |
| `scripts/pre-push-hook.sh` | Pre-push hook -- additional validation |

## How to Use

```bash
# Mode A -- Outbound (from this repo)
make audit TARGET=~/repos/some-repo

# Mode B -- Inbound (from target repo, reference this agent)
# Add to target's AGENTS.md: @repo-auditor at briancl2/repo-auditor

# Quick audit (fewer checks)
make audit-quick TARGET=~/repos/some-repo

# Deep mode
make audit-deep TARGET=~/repos/some-repo

# Validate artifacts
make validate

# Quick test
make test

# Self-management
make check                         # Gate 2 -- shellcheck + inventory + trailer
make review                        # Code review of staged changes
make work DESC="what you're doing" # Gate 1 -- open work contract
make work-close WORK=work/<dir>    # Gate 3 -- close with post-audit + learnings

# Setup
make install-hooks                 # Install pre-commit + pre-push hooks
make help                          # Show all available targets
```

## Key Files

| File | Purpose |
|---|---|
| AGENTS.md | AI instruction surface (this file) |
| LEARNINGS.md | Operational learnings (append-only) |
| docs/invocation-contract.md | Formal I/O contract for auditor invocation |

## Outputs

| Artifact | Format | Description |
|---|---|---|
| SCORECARD.json | JSON | 5-dimension scores, composite, T1/T2 checks |
| AUDIT_REPORT.md | Markdown | Human-readable report with findings |
| PRE_SCAN.md | Markdown | File inventory and AI surface analysis |
| DS-34-plus-results.json | JSON | Extended signature bundle for DS-34 and later |

## Token Budget

| Mode | Tokens | Description |
|---|---|---|
| Standard | 0 | Pre-scan + deterministic scoring (bash only, no LLM) |
| Deep | ~30K | Pre-scan + 6 LLM domain subagents + synthesis |

## Stop Rules

- Max 200 files scanned per target
- Max 30 files per domain subagent
- Max 900 seconds per run
- Halt on pre-scan failure
