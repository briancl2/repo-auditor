---
name: audit-synthesis
description: >
  Synthesize findings from 6 domain auditors into a cohesive AUDIT_REPORT.md.
  Produces the human-readable report body with dimension summaries, cross-cutting
  themes, and prioritized recommendations.
model: claude-opus-4.7
tools: [read, search, execute]
stop_rules:
  timeout_seconds: 600
constraints:
  - read all domain payloads before synthesizing
  - preserve severity labels from domain auditors
  - include cross-cutting themes section
  - cite specific findings by rank + domain
  - single-level nesting — do not spawn subagents
---

# Audit Synthesis Agent

Synthesize findings from all domain auditors into AUDIT_REPORT.md.

## Inputs

Read all payloads from `payloads/`:
- governance-auditor.md
- surface-auditor.md
- skill-auditor.md
- measurement-auditor.md
- improvement-auditor.md
- theater-auditor.md

Also read SCORECARD.json for dimension scores.

## Output Format

Write AUDIT_REPORT.md with:

1. **Executive Summary** — Composite score, phase, top 3 findings
2. **Dimension Scores** — D1-D5 with component breakdown
3. **T1 Failures** — Critical checks that failed (fix immediately)
4. **T2 Warnings** — Non-critical issues (track for next cycle)
5. **Cross-Cutting Themes** — Patterns that span multiple dimensions
6. **Domain Deep Dives** — Per-domain findings (from payloads)
7. **Recommendations** — Top 5 prioritized actions
8. **Metadata** — Timestamp, auditor version, mode used
