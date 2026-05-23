# Pre-Scan Report: 20260522T235758Z.post-audit.snapshot.X5uv9b

> Generated: 2026-05-23T00:02:38Z
> Method: deterministic bash scan

## Repo Metadata

| field | value |
|---|---|
| Repo name | 20260522T235758Z.post-audit.snapshot.X5uv9b |
| Path | /var/folders/z6/9qtjbknd5zs4cnjh5psjb5680000gn/T/20260522T235758Z.post-audit.snapshot.X5uv9b |
| Total files | 362 |
| Commits | 103 |
| Last commit | 2026-05-22 |
| Tier | medium (single session recommended) |
| Recommended scan budget | 300 |
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
- **LEARNINGS.md**: 22L

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
work
work/20260224T024716Z
work/20260418T150604Z
work/20260429T122040Z
work/20260509T114820Z
work/20260522T233748Z
```

## File Distribution

| extension | count |
|---|---|
| .md | 133 |
| .sh | 95 |
| .json | 60 |
| .txt | 43 |
| .py | 16 |
| .learnings_baseline_count | 5 |
| .yml | 3 |
| .start_sha | 3 |
| .yaml | 1 |
| .jsonl | 1 |
| .gitignore | 1 |

