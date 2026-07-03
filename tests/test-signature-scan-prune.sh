#!/usr/bin/env bash
# test-signature-scan-prune.sh — #184 regression (walk pruning).
#
# as_signature_scan.py must prune SKIP_PARTS directories during the filesystem
# walk (not merely filter after a full rglob), so a repo with a heavy vendored
# tree (node_modules/, .git internals) scans bounded and the eligible file set
# ignores the skipped trees. This guards the never-hang perf half of #184.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCAN="$REPO_ROOT/scripts/as_signature_scan.py"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; exit 1; }

echo "=== test-signature-scan-prune.sh ==="

TARGET="$TMP_ROOT/target"
mkdir -p "$TARGET/src" "$TARGET/node_modules/pkg" "$TARGET/.venv/lib"
printf 'x = 1\n' > "$TARGET/src/a.py"
printf 'y = 2\n' > "$TARGET/src/b.py"
printf '# doc\n'  > "$TARGET/README.md"

# Populate the skip trees heavily enough that an unpruned walk would dominate.
for i in $(seq 1 8000); do
    printf 'junk %s\n' "$i" > "$TARGET/node_modules/pkg/file-$i.js"
done
for i in $(seq 1 4000); do
    printf 'junk %s\n' "$i" > "$TARGET/.venv/lib/mod-$i.py"
done

TIMEOUT_BIN="timeout"
command -v "$TIMEOUT_BIN" >/dev/null 2>&1 || TIMEOUT_BIN="gtimeout"
RUNNER=(bash "$REPO_ROOT/scripts/run-with-timeout.sh" 30)
if command -v "$TIMEOUT_BIN" >/dev/null 2>&1; then
    RUNNER=("$TIMEOUT_BIN" 30)
fi

OUT="$TMP_ROOT/scan.json"
if ! "${RUNNER[@]}" python3 "$SCAN" AS-01 "$TARGET" > "$OUT" 2>"$TMP_ROOT/scan.err"; then
    cat "$TMP_ROOT/scan.err" >&2
    fail "signature scan did not finish within the bounded budget on a heavy skip-tree fixture"
fi

ELIGIBLE="$(python3 -c "import json;print(json.load(open('$OUT')).get('eligible_files'))")"
# Only src/a.py, src/b.py, README.md are eligible; the 12000 vendored/venv
# files must be pruned, not counted.
if [ "$ELIGIBLE" != "3" ]; then
    fail "expected 3 eligible files (skip trees pruned), got ${ELIGIBLE:-missing}"
fi
pass "signature scan prunes node_modules/.venv and counts only eligible source (${ELIGIBLE} files)"

echo "=== test-signature-scan-prune.sh: PASS ==="
