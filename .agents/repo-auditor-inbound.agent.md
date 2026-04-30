---
name: repo-auditor-inbound
description: >
  Inbound invocation: audit the current repository. Reads context from pwd,
  resolves skills from this agent repo.
model: claude-opus-4.7
tools: [read, search, execute]
stop_rules:
  max_files: 200
  timeout_seconds: 900
---

# Repo Auditor — Inbound Mode

Audit the repository at the current working directory.

## Steps

1. Use pre-scanning skill first (0 tokens)
2. Score all 5 dimensions
3. Write SCORECARD.json and AUDIT_REPORT.md to `./audit_output/`

## Invocation

This agent is invoked from within a target repo that references it:

```markdown
## External Agents
- Audit: @repo-auditor at briancl2/repo-auditor, audit this repo
```
