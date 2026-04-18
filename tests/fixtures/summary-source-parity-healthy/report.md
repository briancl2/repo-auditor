# Healthy Summary Source Surface

The current retained summary in `audit/session-log-summary.md` is used as
behavior evidence for `total events`, `tool calls`, and `tool distribution`.

That behavior use is bounded by the full same-surface parity stack:

- summary-provenance receipt shows the retained summary matches a fresh replay
- session-parser receipt confirms the direct parser values
- raw-event receipt cross-checks the same bundle through `events.jsonl` and
  `tool.execution_start`
