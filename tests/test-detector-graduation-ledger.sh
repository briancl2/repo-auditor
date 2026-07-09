#!/usr/bin/env bash
# test-detector-graduation-ledger.sh — Guard the detector graduation ledger.
#
# The ledger (docs/detector-graduation-ledger.md) is a hand-maintained,
# git-observable record that makes the append-only detector inventory prunable.
# This test is its rot-prevention gate: it asserts the retire rule + threshold
# are stated, every row is well-formed, the Retire-eligible flag equals the
# retire arithmetic (keep-candidate AND attempts>=K) so the actionable core
# cannot silently drift, and every currently graduation-tracked detector is
# listed. No detector behavior is exercised here.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LEDGER="$REPO_ROOT/docs/detector-graduation-ledger.md"

echo "=== Detector graduation ledger integrity ==="

if [ ! -f "$LEDGER" ]; then
  echo "FAIL: ledger not found at $LEDGER"
  exit 1
fi

# Required graduation-tracked detector set. When a new graduation-tracked
# detector is added, add its id here AND a row in the ledger (see the ledger's
# "How this stays current" section). Keep this list in sync deliberately.
REQUIRED_IDS="AS-51 AS-52 AS-53 AS-54 AS-55 AS-56 AS-57 AS-58 AS-59 DS-49"

python3 - "$LEDGER" "$REQUIRED_IDS" <<'PY'
import re
import sys

ledger_path, required_ids = sys.argv[1], sys.argv[2].split()
text = open(ledger_path, encoding="utf-8").read()

errors = []

# 1. Retire rule + threshold K must be stated.
if "## Retire rule" not in text:
    errors.append("missing '## Retire rule' section")
if "## Graduation rule" not in text:
    errors.append("missing '## Graduation rule' section")

m = re.search(r"K\s*=\s*(\d+)", text)
if not m:
    errors.append("retire threshold 'K = <int>' not stated")
    K = None
else:
    K = int(m.group(1))

VALID_STATUS = {"graduated", "keep-candidate", "retire-candidate"}

# 2. Parse ledger rows: lines like "| AS-58 | AS | keep-candidate | 0 | 1 | N | ... |"
row_re = re.compile(r"^\|\s*((?:AS|DS)-\d+)\s*\|")
seen = {}
for line in text.splitlines():
    if not row_re.match(line):
        continue
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    if len(cells) < 6:
        errors.append(f"row {line[:40]!r}: expected >=6 columns, got {len(cells)}")
        continue
    det, family, status, fires_s, attempts_s, retire = cells[0], cells[1], cells[2], cells[3], cells[4], cells[5]

    if not re.fullmatch(r"(AS|DS)-\d+", det):
        errors.append(f"{det}: malformed detector id")
    if family not in {"AS", "DS"}:
        errors.append(f"{det}: family must be AS or DS, got {family!r}")
    if status not in VALID_STATUS:
        errors.append(f"{det}: status {status!r} not in {sorted(VALID_STATUS)}")
    if not re.fullmatch(r"\d+", fires_s):
        errors.append(f"{det}: confirmed-fires must be an integer, got {fires_s!r}")
    if not re.fullmatch(r"\d+", attempts_s):
        errors.append(f"{det}: non-graduating-attempts must be an integer, got {attempts_s!r}")
    if retire not in {"Y", "N"}:
        errors.append(f"{det}: retire-eligible must be Y or N, got {retire!r}")

    # 3. Retire arithmetic: Y iff keep-candidate AND attempts >= K.
    if K is not None and re.fullmatch(r"\d+", attempts_s) and status in VALID_STATUS and retire in {"Y", "N"}:
        expected = "Y" if (status == "keep-candidate" and int(attempts_s) >= K) else "N"
        if retire != expected:
            errors.append(
                f"{det}: retire-eligible={retire} but retire rule "
                f"(status={status}, attempts={attempts_s}, K={K}) requires {expected}"
            )
    seen[det] = True

# 4. Coverage: every currently graduation-tracked detector must be listed.
for rid in required_ids:
    if rid not in seen:
        errors.append(f"required graduation-tracked detector {rid} missing from ledger")

if not seen:
    errors.append("no ledger rows parsed — table format changed?")

if errors:
    print("LEDGER INTEGRITY FAILURES:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)

print(f"OK: {len(seen)} rows well-formed; retire arithmetic consistent (K={K}); "
      f"all {len(required_ids)} required detectors present.")
PY

echo "=== All ledger integrity checks passed ==="
