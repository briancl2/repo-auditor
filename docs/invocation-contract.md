# repo-auditor Invocation Contract v1.0

## Inputs

| Parameter | Required | Description |
|---|---|---|
| TARGET | Yes | Path to target repository (absolute recommended) |
| OUTPUT_DIR | Yes | Path to output directory (will be created; absolute recommended) |
| MODE | No | `standard` (default) or `deep` |

## Additive Pilot

The repo also exposes an additive token-efficiency replay path:

```bash
make token-efficiency-measure SOURCE_PACK=<path> OUTPUT_DIR=<dir>
```

This pilot does not modify `SCORECARD.json` semantics. It replays a retained
token-efficiency source pack into additive artifacts and fails closed when
labels, hotspot fields, or exact attribution receipts are missing.

## Outputs (all written to OUTPUT_DIR/)

| Artifact | Format | Description |
|---|---|---|
| SCORECARD.json | JSON (schemas/SCORECARD.schema.json) | 5-dimension composite score (0-100) |
| AUDIT_REPORT.md | Markdown | Human-readable audit summary |
| pre-scan/PRE_SCAN.md | Markdown | File inventory and AI surface analysis |
| maturity.txt | Plain text | Maturity phase classification |
| stall-risk.txt | Plain text | 6-signal stall risk assessment |
| dna.txt | Plain text | 10-feature repo DNA fingerprint |
| drift.txt | Plain text | Capability drift analysis |
| TOKEN_MEASUREMENT_SUMMARY.json | JSON | Additive token-efficiency replay summary |
| HOTSPOT_EVIDENCE_PACKETS.json | JSON | Additive hotspot evidence packets |
| AGENTIC_ROOT_CAUSE_BRIEFS.json | JSON | Additive bounded advisory handoff briefs |
| WORKFLOW_INVESTIGATIONS.json | JSON | Additive workflow evidence support |

## Error Codes

| Code | Meaning |
|---|---|
| 0 | Success — all artifacts produced |
| 1 | Invalid arguments (missing TARGET or OUTPUT_DIR) |
| 2 | Target not found or not a directory |
| 3 | Tool failure (partial artifacts may exist) |

## Invocation Examples

### Bash (direct)
```bash
bash scripts/repo-auditor.sh /path/to/target /path/to/output
```

### Agent (copilot CLI)
```bash
cd ~/repos/repo-auditor && copilot --model claude-haiku-4.5 \
  -p "Read .agents/repo-auditor.agent.md. Audit /path/to/target. Output: /path/to/output/." \
  --allow-all --no-ask-user
```

## Version
- Contract: 1.0
- Compatible with: repo-auditor.sh, repo-auditor.agent.md
