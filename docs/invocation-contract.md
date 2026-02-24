# repo-auditor Invocation Contract v1.0

## Inputs

| Parameter | Required | Description |
|---|---|---|
| TARGET | Yes | Absolute path to target repository |
| OUTPUT_DIR | Yes | Absolute path to output directory (will be created) |
| MODE | No | `standard` (default) or `deep` |

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
