# Pre-Scan Report: repo-auditor

> Generated: 2026-02-24T02:47:17Z
> Method: deterministic bash scan

## Repo Metadata

| field | value |
|---|---|
| Repo name | repo-auditor |
| Path | /Users/briancl2/repos/repo-auditor |
| Total files | 77 |
| Commits | 6 |
| Last commit | 2026-02-23 |
| Tier | small (single session recommended) |
| Recommended scan budget | 200 |
| Co-Evolution Ratio | 0.11 |

## AI Surface Inventory (30 surfaces)

| type | count | files |
|---|---|---|
| Agents | 18 | .agents/governance-auditor.agent.md,.agents/skill-auditor.agent.md,.agents/audit-synthesis.agent.md,.agents/improvement-auditor.agent.md,.agents/surface-auditor.agent.md |
| Skills | 2 | .agents/skills/pre-scanning/SKILL.md,.agents/skills/reviewing-code-locally/SKILL.md |
| Instructions | 1 | AGENTS.md |
| Prompts | 9 | .github/prompts/speckit.plan.prompt.md,.github/prompts/speckit.taskstoissues.prompt.md,.github/prompts/speckit.specify.prompt.md,.github/prompts/speckit.constitution.prompt.md,.github/prompts/speckit.tasks.prompt.md |
| Scoring | 5 | tests/test-auditor-t10.sh,tests/test-auditor-schemas.sh,tests/test-tier-checks.sh,scripts/score-session.sh,scripts/score-audit-dimensions.sh |

## Governance Docs

- **AGENTS.md**: 112L
- **LEARNINGS.md**: 6L

## Directory Structure (depth 2)

```

.agents
.agents/skills
.github
.github/agents
.github/prompts
.specify
.specify/memory
.specify/scripts
.specify/templates
.vscode
detection-signatures
docs
hooks
schemas
scripts
specs
specs/001-automated-testing
tests
work
work/20260224T024716Z
```

## File Distribution

| extension | count |
|---|---|
| .md | 45 |
| .sh | 24 |
| .json | 6 |
| .txt | 1 |
| .learnings_baseline_count | 1 |

