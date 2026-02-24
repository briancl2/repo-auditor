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

## Scripts (14)

| Script | Purpose |
|---|---|
| `scripts/repo-auditor.sh` | Main orchestrator — pre-scan → score → report |
| `scripts/score-audit-dimensions.sh` | 5-dimension scorer → SCORECARD.json |
| `scripts/compare-scorecards.sh` | Pre/post delta computation |
| `scripts/classify-repo-maturity.sh` | AI maturity phase classifier |
| `scripts/stall-risk-score.sh` | 6-signal stall risk predictor (0-100) |
| `scripts/extract-repo-dna.sh` | 10-feature Repo DNA fingerprint |
| `scripts/detect-capability-drift.sh` | DS-20 undocumented tool detector |
| `scripts/detect-automation-theater.sh` | DS-21 7-signal scanner |
| `scripts/check.sh` | Gate 2 — shellcheck + inventory + trailer validation |
| `scripts/work-init.sh` | Gate 1 — work contract init with baseline SCORECARD |
| `scripts/work-close.sh` | Gate 3 — post-audit + delta + learnings gate |
| `scripts/score-session.sh` | 4-dimension 15-point session grader |
| `scripts/pre-commit-hook.sh` | Pre-commit hook — runs `make check` |
| `scripts/pre-push-hook.sh` | Pre-push hook — additional validation |

## How to Use

```bash
# Mode A — Outbound (from this repo)
make audit TARGET=~/repos/some-repo

# Mode B — Inbound (from target repo, reference this agent)
# Add to target's AGENTS.md: @repo-auditor at briancl2/repo-auditor

# Quick test
make test

# Deep mode
make audit-deep TARGET=~/repos/some-repo

# Self-management
make check                        # Gate 2 — shellcheck + inventory + trailer
make work DESC="what you're doing" # Gate 1 — open work contract
make work-close WORK=work/<dir>    # Gate 3 — close with post-audit + learnings
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
