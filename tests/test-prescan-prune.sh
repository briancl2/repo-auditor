#!/usr/bin/env bash
# test-prescan-prune.sh — .auditorignore paths must be pruned, not merely filtered.
set -euo pipefail

AUDITOR_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PRESCAN_SCRIPT="$AUDITOR_DIR/.agents/skills/pre-scanning/scripts/pre-scan-target.sh"
TMP_DIR="$(mktemp -d)"
TARGET_DIR="$TMP_DIR/target"
OUTPUT_DIR="$TMP_DIR/output"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$TARGET_DIR/.github" "$TARGET_DIR/work/bulk"

cat > "$TARGET_DIR/.auditorignore" <<'EOF'
work/
EOF

cat > "$TARGET_DIR/AGENTS.md" <<'EOF'
# Fixture
EOF

cat > "$TARGET_DIR/.github/copilot-instructions.md" <<'EOF'
# Instructions
EOF

cat > "$TARGET_DIR/demo.prompt.md" <<'EOF'
Prompt fixture
EOF

# Populate the excluded tree heavily enough that traversal dominates without prune.
for i in $(seq 1 12000); do
  printf 'archived %s\n' "$i" > "$TARGET_DIR/work/bulk/file-$i.txt"
done

TIMEOUT_BIN="timeout"
if ! command -v "$TIMEOUT_BIN" >/dev/null 2>&1; then
  TIMEOUT_BIN="gtimeout"
fi

if ! command -v "$TIMEOUT_BIN" >/dev/null 2>&1; then
  echo "SKIP: timeout/gtimeout not available"
  exit 0
fi

if ! "$TIMEOUT_BIN" 10 bash "$PRESCAN_SCRIPT" "$TARGET_DIR" "$OUTPUT_DIR" > "$TMP_DIR/prescan.log" 2>&1; then
  echo "FAIL: pre-scan did not finish within 10s on an auditorignore-heavy fixture"
  cat "$TMP_DIR/prescan.log"
  exit 1
fi

TOTAL_FILES=$(grep "^Total files:" "$TMP_DIR/prescan.log" | sed 's/.*: *//' | tr -d ' ' || true)
if [ "$TOTAL_FILES" != "4" ]; then
  echo "FAIL: expected Total files to ignore the excluded work tree (wanted 4, got ${TOTAL_FILES:-missing})"
  cat "$TMP_DIR/prescan.log"
  exit 1
fi

if grep -q "work/bulk" "$OUTPUT_DIR/PRE_SCAN.md" "$OUTPUT_DIR/LARGE_FILES.md" "$OUTPUT_DIR/AI_SURFACES_FULL.md" 2>/dev/null; then
  echo "FAIL: auditorignore-pruned work tree leaked into pre-scan artifacts"
  exit 1
fi

echo "PASS: pre-scan prunes auditorignore-heavy trees and finishes within the bounded fixture budget"
