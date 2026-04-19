# repo-auditor

Standalone **repo health auditor** — produces machine-readable scorecards (SCORECARD.json) for any AI-native repository. Part of the [repo-agent fleet](https://github.com/briancl2/repo-agent-core).

## Quick Start

```bash
# Audit a target repository
make audit TARGET=~/repos/some-target-repo

# Replay the additive token-efficiency pilot
make token-efficiency-measure

# Review staged changes
make review
```

## What It Does

1. **Pre-scans** the target (deterministic) — AI surfaces, .gitignore, large files
2. **Dispatches 6 domain subagents** — governance, surfaces, skills, measurement, improvement, theater
3. **Synthesizes** findings into SCORECARD.json (5 dimensions, 0-100 composite)
4. **Produces** AUDIT_REPORT.md (human-readable) + per-domain findings
5. **Optionally replays** a frozen token-efficiency corpus into additive pilot artifacts
6. **Runs** the DS-34+ bundle plus the AS-* owner-surface health family

## Outputs

| File | Format | Consumer |
|---|---|---|
| `SCORECARD.json` | Machine-readable | repo-upgrade-advisor, repo-optimizer, continuous loop |
| `AUDIT_REPORT.md` | Human-readable | Developer |
| `DS-34-plus-results.json` | Machine-readable | DS-34+ and AS-* signature-level diagnostics |
| `*_findings.json` | Per-domain details | Internal |
| `TOKEN_MEASUREMENT_SUMMARY.json` | Machine-readable | additive measurement-mode pilot |
| `HOTSPOT_EVIDENCE_PACKETS.json` | Machine-readable | additive measurement-mode pilot |
| `AGENTIC_ROOT_CAUSE_BRIEFS.json` | Machine-readable | bounded advisor handoff pilot |
| `WORKFLOW_INVESTIGATIONS.json` | Machine-readable | additive measurement-mode pilot support |

## Invocation Modes

- **Mode A (Outbound):** Run from this repo targeting an external repo
- **Mode B (Inbound):** Invoked from within a target repo pointing at this repo

## Dependencies

Shared primitives from [repo-agent-core](https://github.com/briancl2/repo-agent-core) (copied, not symlinked).

## Self-Management

- `make check` — shellcheck + inventory + trailer validation
- `make work DESC="..."` — open work contract with baseline
- `make work-close WORK=work/<dir>` — close with post-audit + learnings gate

## License

MIT
