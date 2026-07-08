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

Issue #164 scheduled-readback owner proof detector coverage is provided by
AS-49 through `scripts/detect-as-scheduled-readback-owner-proof-gap.sh`. It
checks owner issue, candidate id, event filter, cadence, blocker, gate,
kill-switch, and bounded non-claim fields; it does not run or install a
scheduler, queue, daemon, registry, controller, automatic GitHub mutation, or
auto-merge path.

Issue #164 Hermes foreground failure disposition detector coverage is provided
by AS-50 through
`scripts/detect-as-hermes-foreground-failure-disposition-gap.sh`. It checks
failure issue, primary object, command family, failure code, merged repair PR,
provider-policy, GitHub truth, and bounded non-claim fields; it does not close
issues, retry Hermes, install schedulers, create queues, add controllers, or
auto-merge.

External closure coupling detector coverage is provided by AS-56 through
`scripts/detect-as-external-closure-coupling.sh`. It checks default closure
surfaces for sibling-repo local paths such as `$HOME/repos/...`; reciprocal
cross-repo audit remains opt-in/advisory rather than default closure truth.

Native-evidence-before-verdict detector coverage is provided by AS-57 through
`scripts/detect-as-native-evidence-before-verdict.sh`. It fires when a
verdict-bearing surface decides adoption/readiness/fallback/production/GA/
cutover/architecture from docs-readback or substitute proof (local doctor,
local tests, retained reports, model summaries, validation receipts, prompt
contracts) without a native attempt or a concrete owner-surface blocker, per
repo-agent-core `docs/native-evidence-before-verdict-contract.md`. It does not
create controllers, schedulers, queues, registries, or auto-issue creators.

Instruction-contradiction detector coverage is provided by AS-58 through
`scripts/detect-as-instruction-contradiction.sh`. It fires when a repo's
instruction surfaces (`AGENTS.md`, `.github/copilot-instructions.md`,
`.agents/skills/**/SKILL.md`, `docs/**`) carry contradictory or self-invalidating
guidance: a named reference is cited live/canonical in one surface while another
surface marks that same reference dead/dormant/archived/deprecated (the "cited
live while dead" class), or the same action token is both absolutely mandated
and absolutely forbidden within one surface. It is lexical and read-only; it
does not create controllers, schedulers, queues, registries, auto-issue
creators, or any target-repo mutation.

Re-work recurrence detector coverage is provided by DS-49 through
`scripts/detect-rework-recurrence.sh`. It is a git-history-observable,
read-only detector that fires when a substantive file (code, tests, schemas,
specs, config) that a finalize/closeout/issue-close commit touched is
re-modified shortly afterward by a corrective (fix/revert/redo/regress) commit —
the git-visible fingerprint of declared-done work that recurred. Finalize is
classified from the finalize act (subject-initial closeout verb, "mark as
done", "work complete", "closeout the {work,issue,task}", or
`(close|fix|resolve) #N`), not topic mentions; ceremony/doc/tracking files are
excluded from finalized areas. Because it reads real commit history it is
**live-checkout only** — it structurally no-ops on snapshot-mode inputs, which
collapse to a single synthetic clean-HEAD commit (an accepted DS-29-precedent
limitation). It is the detector complement to the method-dimension proposal in
`briancl2/repo-agent-core#103`, and is a MEDIUM/T2 n=1 keep-candidate (both the
severity/tier and graduation are operator-gated). It does not create
controllers, schedulers, queues, registries, or any target-repo mutation.

## Self-Management

- `make check` — shellcheck + inventory + co-evolution + trailer validation
- `make work DESC="..."` — open work contract with baseline
- `make work-close WORK=work/<dir>` — close with post-audit + learnings gate

## License

MIT
