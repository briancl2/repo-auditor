# Repo-Auditor Agent Operations

This document holds the operational inventory that used to live in `AGENTS.md`.
`AGENTS.md` remains the compact bootloader; this file is reference material.

## Agents

| Agent | Model | Purpose |
|---|---|---|
| repo-auditor | claude-opus-4.6 | Orchestrator for standard and deep audit modes |
| repo-auditor-inbound | claude-opus-4.6 | Inbound invocation |
| governance-auditor | claude-sonnet-4.5 | D1 Governance dimension |
| surface-auditor | claude-sonnet-4.5 | D2 Surface Health dimension |
| skill-auditor | claude-sonnet-4.5 | D3 Skill Maturity dimension |
| measurement-auditor | claude-sonnet-4.5 | D4 Measurement dimension |
| improvement-auditor | claude-sonnet-4.5 | D5 Self-Improvement dimension |
| theater-auditor | claude-sonnet-4.5 | Automation theater detection |
| audit-synthesis | claude-opus-4.6 | Deep-mode report synthesis |

## Skills

| Skill | Purpose |
|---|---|
| reviewing-code-locally | Pre-commit code review through Copilot CLI |
| pre-scanning | Deterministic inventory and AI-surface scan |
| detection-signatures | DS-34 through DS-48 plus AS-* signature runner |
| scoring | Five-dimension scoring, stall risk, and maturity classification |

## Core Pipeline Scripts

| Script | Purpose |
|---|---|
| `scripts/repo-auditor.sh` | Main orchestrator: pre-scan, score, report |
| `scripts/score-audit-dimensions.sh` | Five-dimension scorer |
| `scripts/compare-scorecards.sh` | Pre/post scorecard deltas |
| `scripts/classify-repo-maturity.sh` | AI maturity phase classifier |
| `scripts/stall-risk-score.sh` | Six-signal stall risk predictor |
| `scripts/extract-repo-dna.sh` | Repo DNA fingerprint |
| `scripts/score-session.sh` | Operating-model scorecard for ordinary session-local work |

## Detection Signatures

The deterministic signature family includes capability drift, automation
theater, warning noise, ceremony ratio, grader ceiling, content staleness,
feed-forward stall, measurement disconnect, stale TODOs, unused dependencies,
green-only CI, README drift, config proliferation, silent errors, commit
entropy, test theater, broken links, velocity bypass, closeout-control drift,
workflow-contract drift, LLM validation gaps, summary/source parity gaps, and
GitHub Actions concurrency gaps, and agent-surface AS-* checks for instruction root drift, docs-vs-observed host
drift, missing runtime heartbeat, validator live-path gaps, memory authority
confusion, prompt-only optimization, unused platform surfaces, critique health,
cost/token evidence boundaries, pricing provenance, copied evidence boundaries,
unauthorized default enablement, rollback proof, aggregate-only readiness,
stale direct-token evidence, forbidden public `CustomerNewsletter` mutation,
Goal-mode runtime evidence gaps, reactive self-healing loops, and shell
reserved status-variable launch snippets.

## Helper Scripts

| Script | Purpose |
|---|---|
| `scripts/assemble_ds_results.py` | Assemble DS-34+ results |
| `scripts/audit-clean-head-snapshot.py` | Clean-HEAD snapshot wrapper |
| `scripts/as_signature_scan.py` | Shared AS-* evaluator |
| `scripts/backtest_ds34_42.py` | Backtest deterministic signatures |
| `scripts/collect-dual-inventory.py` | Primary-surface and full-facts inventory receipt |
| `scripts/collect-target-native-quality-gates.py` | Target-local quality-gate receipt |
| `scripts/deep-audit.py` | Deep-audit known-defect validation |
| `scripts/ds_json_helper.py` | Safe JSON output helper |
| `scripts/prepare-clean-audit-snapshot.py` | Clean snapshot helper |
| `scripts/token-efficiency-measure.py` | Token-efficiency replay pilot |
| `scripts/write_context_score_manifest.py` | Context, git, and artifact preflight manifest |

## Gates And Hooks

| Script | Purpose |
|---|---|
| `scripts/check.sh` | Gate 2: shellcheck, inventory, co-evolution, trailers |
| `scripts/check-coevolution.sh` | Governed-surface co-evolution guard |
| `scripts/work-init.sh` | Gate 1 work-contract init |
| `scripts/work-close.sh` | Gate 3 post-audit, delta, and learnings; runs the session grader by default and writes `score-session-bypass.json` for explicit GitHub-native issue/PR closeout |
| `scripts/pre-commit-hook.sh` | Runs `make check` |
| `scripts/pre-push-hook.sh` | Additional validation |

## Modes And Budgets

| Mode | Token posture | Description |
|---|---|---|
| Standard | 0 | Deterministic pre-scan and scoring |
| Deep | about 30K | Pre-scan plus domain subagents and synthesis |

## Operator Notes

- `AGENTS.md` is the canonical startup surface.
- `LEARNINGS.md` is append-only operational memory.
- `.specify/memory/constitution.md` carries governance principles.
- Scan caps, timeouts, and target-read-only boundaries are safety controls, not
  suggestions.
