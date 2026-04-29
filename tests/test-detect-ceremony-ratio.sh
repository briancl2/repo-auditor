#!/usr/bin/env bash
# test-detect-ceremony-ratio.sh — Validate DS-29 commit and file-weighted signals.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/detect-ceremony-ratio.sh"
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT

echo "=== DS-29 Ceremony Ratio Fixtures ==="

init_repo() {
  local repo="$1"
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" config user.email "test@example.com"
  git -C "$repo" config user.name "DS29 Test"
}

write_file() {
  local repo="$1"
  local path="$2"
  mkdir -p "$(dirname "$repo/$path")"
  printf 'fixture %s\n' "$path" > "$repo/$path"
}

commit_all() {
  local repo="$1"
  local msg="$2"
  git -C "$repo" add .
  git -C "$repo" commit -q -m "$msg"
}

add_delivery_file() {
  local repo="$1"
  local commit_idx="$2"
  local file_idx="$3"
  write_file "$repo" "scripts/feature_${commit_idx}_${file_idx}.sh"
}

add_ceremony_file() {
  local repo="$1"
  local commit_idx="$2"
  local file_idx="$3"
  case $((file_idx % 4)) in
    0) write_file "$repo" "work/20260429T${commit_idx}${file_idx}000Z/WORK.md" ;;
    1) write_file "$repo" "research/reports/report_${commit_idx}_${file_idx}.md" ;;
    2) write_file "$repo" "docs/roadmap/roadmap_${commit_idx}_${file_idx}.md" ;;
    *) write_file "$repo" "specs/${commit_idx}${file_idx}-selector/spec.md" ;;
  esac
}

build_fixture() {
  local repo="$1"
  local delivery_per_commit="$2"
  local ceremony_per_commit="$3"
  local commit_idx
  local file_idx

  init_repo "$repo"
  for commit_idx in 1 2 3 4 5; do
    for file_idx in $(seq 1 "$delivery_per_commit"); do
      add_delivery_file "$repo" "$commit_idx" "$file_idx"
    done
    for file_idx in $(seq 1 "$ceremony_per_commit"); do
      add_ceremony_file "$repo" "$commit_idx" "$file_idx"
    done
    commit_all "$repo" "fixture commit $commit_idx"
  done
}

assert_json() {
  local json="$1"
  local python_check="$2"
  printf '%s' "$json" | python3 -c "$python_check"
}

BMA_SHAPED="$TMP_ROOT/bma-shaped"
build_fixture "$BMA_SHAPED" 1 8

commit_json=$(bash "$SCRIPT" "$BMA_SHAPED" --commits 5 --threshold 65 --mode commit --json)
assert_json "$commit_json" '
import json, sys
data = json.load(sys.stdin)
assert data["fires"] is False
assert data["commit_fires"] is False
assert data["file_fires"] is True
assert data["ceremony_pct"] == 0
assert data["file_ceremony_pct"] > 65
'
echo "  ✓ commit mode preserves legacy non-fire on BMA-shaped mixed commits"

set +e
combined_json=$(bash "$SCRIPT" "$BMA_SHAPED" --commits 5 --threshold 65 --json)
combined_status=$?
set -e
[ "$combined_status" -eq 1 ]
assert_json "$combined_json" '
import json, sys
data = json.load(sys.stdin)
assert data["mode"] == "combined"
assert data["fires"] is True
assert data["commit_fires"] is False
assert data["file_fires"] is True
assert data["fire_reason"] == "file-ratio"
assert data["file_delivery"] == 5
assert data["file_ceremony"] == 40
'
echo "  ✓ combined mode catches file-weighted ceremony dominance"

NEAR_MISS="$TMP_ROOT/near-miss"
build_fixture "$NEAR_MISS" 2 3
near_miss_json=$(bash "$SCRIPT" "$NEAR_MISS" --commits 5 --threshold 65 --json)
assert_json "$near_miss_json" '
import json, sys
data = json.load(sys.stdin)
assert data["fires"] is False
assert data["file_fires"] is False
assert data["file_ceremony_pct"] == 60
'
echo "  ✓ independent near-miss baseline stays below threshold"

HEALTHY_MIXED="$TMP_ROOT/healthy-mixed"
build_fixture "$HEALTHY_MIXED" 3 1
healthy_json=$(bash "$SCRIPT" "$HEALTHY_MIXED" --commits 5 --threshold 65 --json)
assert_json "$healthy_json" '
import json, sys
data = json.load(sys.stdin)
assert data["fires"] is False
assert data["commit_fires"] is False
assert data["file_fires"] is False
assert data["file_ceremony_pct"] == 25
'
echo "  ✓ healthy mixed-commit baseline stays quiet"

echo "  VERDICT: PASS"
