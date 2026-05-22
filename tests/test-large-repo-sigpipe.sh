#!/usr/bin/env bash
# test-large-repo-sigpipe.sh — Large file-set regression for pipefail-safe discovery.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/repo-auditor-large-repo-sigpipe.XXXXXX")"
TARGET="$TEST_ROOT/target"
OUT="$TEST_ROOT/out"

cleanup() {
    chmod -R u+w "$TEST_ROOT" 2>/dev/null || true
    attempt=1
    while [ "$attempt" -le 5 ]; do
        rm -rf "$TEST_ROOT" 2>/dev/null && return 0
        sleep 1
        attempt=$((attempt + 1))
    done
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

mkdir -p "$TARGET/plans" "$TARGET/scripts" "$TARGET/tests" "$TARGET/.github/workflows" "$OUT"

printf '%s\n' '# Fixture Agents' > "$TARGET/AGENTS.md"
printf '%s\n' '# Fixture Learnings' > "$TARGET/LEARNINGS.md"
printf '%s\n' 'test:' '	@echo ok' > "$TARGET/Makefile"
printf '%s\n' 'name: ci' 'on: [push]' > "$TARGET/.github/workflows/ci.yml"
printf '%s\n' '#!/usr/bin/env bash' 'echo check' > "$TARGET/scripts/check-demo.sh"
printf '%s\n' '#!/usr/bin/env bash' 'echo test' > "$TARGET/tests/test-demo.sh"
chmod +x "$TARGET/scripts/check-demo.sh" "$TARGET/tests/test-demo.sh"

index=1
while [ "$index" -le 2000 ]; do
    printf 'plan %s delta metric sha abcdef%s\n' "$index" "$index" > "$TARGET/plans/plan-$index.md"
    index=$((index + 1))
done

(
    cd "$TARGET"
    git init -q
    git config user.name "Fixture"
    git config user.email "fixture@example.com"
    git config gc.auto 0
    git config maintenance.auto false
    git add .
    git commit -qm "fixture"
)

bash "$REPO_ROOT/scripts/stall-risk-score.sh" "$TARGET" > "$OUT/stall-risk.txt"
bash "$REPO_ROOT/scripts/extract-repo-dna.sh" "$TARGET" > "$OUT/dna.txt"

grep -q "Stall Risk" "$OUT/stall-risk.txt"
grep -q "Repo DNA Fingerprint" "$OUT/dna.txt"

echo "large repo SIGPIPE regression: PASS"
