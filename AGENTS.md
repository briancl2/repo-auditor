# AGENTS.md — repo-auditor

> Standalone repo health auditor — produces machine-readable scorecards for any AI-native repository.
> Read this file FIRST.

## Purpose

`repo-auditor` audits any repository and produces a **SCORECARD.json** with 5 health dimensions (Governance, Surface Health, Skill Maturity, Measurement, Self-Improvement). It provides the diagnostic foundation for the repo-agent fleet.

## Architecture

**Orchestrator → 6 domain subagents → synthesis → SCORECARD.json**

| Subagent | Domain | Output |
|---|---|---|
| governance-auditor | AGENTS.md, LEARNINGS.md, CI, protocols | governance_findings.json |
| surface-auditor | AI surfaces, drift, co-evolution ratio | surface_findings.json |
| skill-auditor | Skill maturity, density, organicity | skill_findings.json |
| measurement-auditor | Scoring tools, layers, machine-readable output | measurement_findings.json |
| improvement-auditor | Stall risk, trajectory, plan infrastructure | improvement_findings.json |
| theater-auditor | DS-21 signals, enforcement depth | theater_findings.json |

## Invocation

**Mode A — Outbound (from this repo):**
```bash
make audit TARGET=~/repos/some-target-repo
```

**Mode B — Inbound (from a target repo):**
```
@repo-auditor at briancl2/repo-auditor, audit this repo
```

## Key Conventions

- Every change goes through `make review` before committing
- `--no-verify` is NEVER permitted (L102)
- Pre-commit hook blocks by default (L105)
- 0-token pre-scan runs first, then LLM subagents (L65)
- Tiered output: T1 (blocking) vs T2 (warning) (P3)

## Skills

| # | Skill | Purpose |
|---|---|---|
| 1 | reviewing-code-locally | Pre-commit code review via Copilot CLI |

## Token Budget

~30K tokens per standard audit (6 subagents × ~5K each). Pre-scan is 0 tokens.

## Modes

| Mode | Tokens | Description |
|---|---|---|
| Quick | 0 | Pre-scan only (deterministic) |
| Standard | ~30K | Pre-scan + LLM audit |
| Deep | ~45K | + session log analysis |
| Comprehensive | ~60K | + paired surface runs |
