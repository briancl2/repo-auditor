# Pre-Scan Report: repo-auditor

> Generated: 2026-04-18T15:06:04Z
> Method: deterministic bash scan

## Repo Metadata

| field | value |
|---|---|
| Repo name | repo-auditor |
| Path | /Users/briancl/repos/repo-auditor |
| Total files | 812 |
| Commits | 45 |
| Last commit | 2026-04-16 |
| Tier | large (multi session recommended) |
| Recommended scan budget | 400 |
| Co-Evolution Ratio | 0.22 |

## AI Surface Inventory (32 surfaces)

| type | count | files |
|---|---|---|
| Agents | 18 | .agents/governance-auditor.agent.md,.agents/skill-auditor.agent.md,.agents/speckit.taskstoissues.agent.md,.agents/speckit.tasks.agent.md,.agents/audit-synthesis.agent.md |
| Skills | 4 | .agents/skills/pre-scanning/SKILL.md,.agents/skills/detection-signatures/SKILL.md,.agents/skills/reviewing-code-locally/SKILL.md,.agents/skills/scoring/SKILL.md |
| Instructions | 1 | AGENTS.md |
| Prompts | 9 | .github/prompts/speckit.plan.prompt.md,.github/prompts/speckit.taskstoissues.prompt.md,.github/prompts/speckit.specify.prompt.md,.github/prompts/speckit.constitution.prompt.md,.github/prompts/speckit.tasks.prompt.md |
| Scoring | 15 | tests/test-deep-audit.sh,tests/test-grader-golden.sh,tests/test-auditor-t10.sh,tests/test-detect-closeout-control-drift.sh,tests/test-newsletter-calibration-detectors.sh |

## Governance Docs

- **AGENTS.md**: 167L
- **LEARNINGS.md**: 14L

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
```

## File Distribution

| extension | count |
|---|---|
| .md | 276 |
| .txt | 252 |
| .json | 164 |
| .sh | 60 |
| .learnings_baseline_count | 23 |
| .start_sha | 21 |
| .py | 10 |
| .yml | 3 |
| .yaml | 1 |
| .jsonl | 1 |
| .gitignore | 1 |

