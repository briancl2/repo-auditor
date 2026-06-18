# repo-auditor

Standalone **repo health auditor** — produces machine-readable scorecards (SCORECARD.json) for any AI-native repository. Part of the [repo-agent fleet](https://github.com/briancl2/repo-agent-core).

## Quick Start

```bash
# Audit a target repository
make audit TARGET=~/repos/some-target-repo

# Explicitly audit a clean HEAD snapshot when the live target is dirty
make audit-snapshot TARGET=~/repos/some-target-repo OUTPUT_DIR=./audit-output SNAPSHOT_DIR=./audit-snapshot

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
7. **Optionally audits** an explicit clean HEAD snapshot of a dirty target with
   provenance receipts

## Outputs

| File | Format | Consumer |
|---|---|---|
| `SCORECARD.json` | Machine-readable | repo-upgrade-advisor, repo-optimizer, continuous loop |
| `AUDIT_REPORT.md` | Human-readable | Developer |
| `DS-34-plus-results.json` | Machine-readable | DS-34+ and AS-* signature-level diagnostics |
| `TARGET_NATIVE_QUALITY_GATES.json` | Machine-readable | Additive target-local quality gate classification, including retained gates, no retained gate, and partial-run states |
| `CLEAN_HEAD_SNAPSHOT_RECEIPT.json` | Machine-readable | Provenance for explicit clean HEAD snapshot audits of dirty targets |
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

## Live Capability Inventory

The [live capability inventory](docs/live-capability-inventory.md) records
repo-auditor's live agents, detectors, scripts, Speckit helpers, and tracking
decisions for calibrated capability-drift checks. It is documentation, not a
runtime registry or generated control plane.

Issue #164 Deep Research/source-intelligence native corpus detector coverage is
provided by AS-46 through
`scripts/detect-as-deep-research-source-intelligence-native-corpus-gap.sh`.
It checks portable corpus evidence fields and bounded non-claims; it does not
run a live Deep Research API task, Codex Cloud task, Codex remote task, crawler,
registry, watcher, controller, scheduler, queue, daemon, or downstream mutation.

Issue #164 standalone external-intelligence sidecar detector coverage is
provided by AS-48 through
`scripts/detect-as-standalone-external-intelligence-sidecar-gap.sh`.
It checks sidecar prompts for embedded standalone context, defined terms,
clear Prompt A/B or Deep Research mode shape, advisory-only boundaries, and no
load-bearing local/private/GitHub context assumptions.

## Self-Management

- `make check` — shellcheck + inventory + co-evolution + trailer validation
- `make work DESC="..."` — open work contract with baseline
- `make work-close WORK=work/<dir>` — close with post-audit + learnings gate

## License

MIT
