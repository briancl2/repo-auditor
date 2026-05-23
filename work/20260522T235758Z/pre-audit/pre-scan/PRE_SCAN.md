# Pre-Scan Report: repo-auditor

> Generated: 2026-05-22T23:57:59Z
> Method: deterministic bash scan

## Repo Metadata

| field | value |
|---|---|
| Repo name | repo-auditor |
| Path | /Users/briancl/repos/repo-auditor |
| Total files | 1068 |
| Commits | 103 |
| Last commit | 2026-05-22 |
| Tier | xlarge (multi session recommended) |
| Recommended scan budget | 500 |
| Co-Evolution Ratio | 0.22 |

## AI Surface Inventory (32 surfaces)

| type | count | files |
|---|---|---|
| Agents | 18 | .agents/governance-auditor.agent.md,.agents/skill-auditor.agent.md,.agents/speckit.taskstoissues.agent.md,.agents/speckit.tasks.agent.md,.agents/audit-synthesis.agent.md |
| Skills | 4 | .agents/skills/pre-scanning/SKILL.md,.agents/skills/detection-signatures/SKILL.md,.agents/skills/reviewing-code-locally/SKILL.md,.agents/skills/scoring/SKILL.md |
| Instructions | 1 | AGENTS.md |
| Prompts | 9 | .github/prompts/speckit.plan.prompt.md,.github/prompts/speckit.taskstoissues.prompt.md,.github/prompts/speckit.specify.prompt.md,.github/prompts/speckit.constitution.prompt.md,.github/prompts/speckit.tasks.prompt.md |
| Scoring | 30 | tests/test-audit-run-receipt.sh,tests/test-deep-audit.sh,tests/test-detect-summary-source-parity-gap.sh,tests/test-denominator-metadata.sh,tests/test-grader-golden.sh |

## Governance Docs

- **AGENTS.md**: 71L
- **LEARNINGS.md**: 21L

## Directory Structure (depth 2)

```

.agents
.agents/skills
.github
.github/prompts
.github/workflows
.specify
.specify/memory
.specify/scripts
.specify/templates
.vscode
config
detection-signatures
docs
schemas
scripts
specs
specs/001-automated-testing
specs/072-fix-documentation-drift
specs/073-fix-prescan-find-excludes
specs/074-port-zero-match-counting-guardrails
specs/075-ds29-file-weighted-ceremony-ratio
specs/076-audit-run-receipt
specs/077-denominator-metadata
specs/078-target-native-quality-gates
specs/079-dual-inventory-receipts
specs/080-clean-head-snapshot-audit
specs/081-cap-curve-receipt-fields
specs/082-dual-inventory-cap-policy
specs/083-coevolution-guard
tests
tests/fixtures
tests/test-output-t10
work
work/20260224T024716Z
work/20260315T205849Z
work/20260315T215414Z
work/20260315T225825Z
work/20260315T234601Z
work/20260316T030443Z
work/20260316T233348Z
work/20260316T235641Z
work/20260317T035934Z
work/20260317T041737Z
work/20260317T152849Z
work/20260317T232936Z
work/20260318T003312Z
work/20260320T000559Z
work/20260415T121633Z
work/20260415T152434Z
work/20260415T200149Z
work/20260415T234216Z
work/20260416T010616Z
work/20260416T010828Z
work/20260416T023311Z
work/20260418T150604Z
work/20260419T125925Z
work/20260426T212046Z
work/20260429T122040Z
work/20260509T000944Z
```

## File Distribution

| extension | count |
|---|---|
| .md | 358 |
| .txt | 323 |
| .json | 214 |
| .sh | 95 |
| .learnings_baseline_count | 29 |
| .start_sha | 27 |
| .py | 16 |
| .yml | 3 |
| .yaml | 1 |
| .jsonl | 1 |
| .gitignore | 1 |

