#!/usr/bin/env bash
# test-clean-head-snapshot-audit.sh — Validate explicit clean HEAD snapshot audit mode.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REAL_GIT="$(command -v git)"
TMP_PARENT="${TMPDIR:-$REPO_ROOT/work/test-tmp}"
TMP_ROOT="$TMP_PARENT/clean-head-snapshot.$$"
rm -rf "$TMP_ROOT"
mkdir -p "$TMP_ROOT"
trap 'rm -rf "$TMP_ROOT"' EXIT

SOURCE="$TMP_ROOT/source"
DEFAULT_OUT="$TMP_ROOT/default-out"
SNAPSHOT="$TMP_ROOT/snapshot"
SNAPSHOT_OUT="$TMP_ROOT/snapshot-out"

mkdir -p "$SOURCE/docs"
git -C "$TMP_ROOT" init -q source
git -C "$SOURCE" config user.email "test@example.com"
git -C "$SOURCE" config user.name "Test User"
cat > "$SOURCE/AGENTS.md" <<'EOF'
# Fixture instructions
EOF
cat > "$SOURCE/README.md" <<'EOF'
# Snapshot fixture
EOF
cat > "$SOURCE/docs/usage.md" <<'EOF'
# Usage
EOF
git -C "$SOURCE" add AGENTS.md README.md docs/usage.md
git -C "$SOURCE" commit -q -m "initial fixture"
SOURCE_HEAD_BEFORE="$(git -C "$SOURCE" rev-parse HEAD)"
mkdir -p "$SOURCE/Projects"
cat > "$SOURCE/Projects/local-note.md" <<'EOF'
# Local untracked note
EOF

if bash "$REPO_ROOT/scripts/repo-auditor.sh" "$SOURCE" "$DEFAULT_OUT" > "$TMP_ROOT/default-stdout.txt" 2> "$TMP_ROOT/default-stderr.txt"; then
    echo "expected dirty default audit to fail" >&2
    exit 1
fi
test ! -f "$DEFAULT_OUT/SCORECARD.json"

if python3 "$REPO_ROOT/scripts/audit-clean-head-snapshot.py" "$SOURCE" "$SOURCE/audit-output" --snapshot-dir "$TMP_ROOT/source-outside-snapshot" > "$TMP_ROOT/in-target-output-stdout.txt" 2> "$TMP_ROOT/in-target-output-stderr.txt"; then
    echo "expected snapshot audit with in-target output dir to fail" >&2
    exit 1
fi
grep -q 'output dir must not be inside the target repo' "$TMP_ROOT/in-target-output-stderr.txt"
test ! -e "$SOURCE/audit-output"

if make -C "$REPO_ROOT" audit-snapshot TARGET="$SOURCE" OUTPUT_DIR="$SOURCE/make-output" SNAPSHOT_DIR="$TMP_ROOT/make-snapshot" > "$TMP_ROOT/make-in-target-output-stdout.txt" 2> "$TMP_ROOT/make-in-target-output-stderr.txt"; then
    echo "expected make audit-snapshot with in-target output dir to fail" >&2
    exit 1
fi
grep -q 'output dir must not be inside the target repo' "$TMP_ROOT/make-in-target-output-stderr.txt"
test ! -e "$SOURCE/make-output"

if python3 "$REPO_ROOT/scripts/audit-clean-head-snapshot.py" "$SOURCE" "$TMP_ROOT/overlap" --snapshot-dir "$TMP_ROOT/overlap/snapshot" > "$TMP_ROOT/overlap-stdout.txt" 2> "$TMP_ROOT/overlap-stderr.txt"; then
    echo "expected snapshot audit with overlapping output/snapshot dirs to fail" >&2
    exit 1
fi
grep -q 'output dir and snapshot dir must be separate' "$TMP_ROOT/overlap-stderr.txt"

CLONE_TIMEOUT_OUT="$TMP_ROOT/clone-timeout-out"
CLONE_TIMEOUT_SNAPSHOT="$TMP_ROOT/clone-timeout-snapshot"
FAKE_BIN="$TMP_ROOT/fake-bin"
mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/git" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "clone" ]]; then
    sleep 5
fi
exec "$REAL_GIT" "\$@"
EOF
chmod +x "$FAKE_BIN/git"
if PATH="$FAKE_BIN:$PATH" CLEAN_HEAD_SNAPSHOT_CLONE_TIMEOUT_SECONDS=1 python3 "$REPO_ROOT/scripts/audit-clean-head-snapshot.py" "$SOURCE" "$CLONE_TIMEOUT_OUT" --snapshot-dir "$CLONE_TIMEOUT_SNAPSHOT" > "$TMP_ROOT/clone-timeout-stdout.txt" 2> "$TMP_ROOT/clone-timeout-stderr.txt"; then
    echo "expected snapshot audit clone timeout to fail" >&2
    exit 1
fi
grep -q 'git clone timed out' "$TMP_ROOT/clone-timeout-stderr.txt"
test -f "$CLONE_TIMEOUT_OUT/CLEAN_HEAD_SNAPSHOT_RECEIPT.json"
test ! -f "$CLONE_TIMEOUT_OUT/SCORECARD.json"
python3 - "$CLONE_TIMEOUT_OUT" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
receipt = json.load(open(out / "CLEAN_HEAD_SNAPSHOT_RECEIPT.json"))
assert receipt["snapshot"]["head"] is None, receipt
assert receipt["snapshot"]["status_clean"] is None, receipt
assert receipt["snapshot"]["clone_timeout_seconds"] == 1.0, receipt
assert receipt["snapshot"]["clone_failure"]["type"] == "timeout", receipt
assert receipt["snapshot"]["clone_failure"]["command"][:2] == ["git", "clone"], receipt
assert receipt["audit"]["exit_code"] is None, receipt
assert "completed_at" in receipt, receipt
PY

python3 "$REPO_ROOT/scripts/audit-clean-head-snapshot.py" "$SOURCE" "$SNAPSHOT_OUT" --snapshot-dir "$SNAPSHOT" > "$TMP_ROOT/snapshot-stdout.txt" 2> "$TMP_ROOT/snapshot-stderr.txt"

SOURCE_HEAD_AFTER="$(git -C "$SOURCE" rev-parse HEAD)"
test "$SOURCE_HEAD_BEFORE" = "$SOURCE_HEAD_AFTER"
git -C "$SOURCE" status --short | grep -q '?? Projects/'
test ! -e "$SNAPSHOT/Projects"
test -f "$SNAPSHOT_OUT/SCORECARD.json"
test -f "$SNAPSHOT_OUT/SCORECARD_RECEIPTS.json"
test -f "$SNAPSHOT_OUT/CLEAN_HEAD_SNAPSHOT_RECEIPT.json"

python3 - "$SNAPSHOT_OUT" "$SOURCE_HEAD_BEFORE" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
head = sys.argv[2]
receipt = json.load(open(out / "CLEAN_HEAD_SNAPSHOT_RECEIPT.json"))
receipts = json.load(open(out / "SCORECARD_RECEIPTS.json"))
scorecard = json.load(open(out / "SCORECARD.json"))

assert receipt["mode"] == "clean-head-snapshot", receipt
assert receipt["source"]["head"] == head, receipt
assert receipt["source"]["dirty"] is True, receipt
assert receipt["source"]["untracked_count"] == 1, receipt
assert receipt["snapshot"]["head"] == head, receipt
assert receipt["snapshot"]["status_clean"] is True, receipt
assert receipt["audit"]["exit_code"] == 0, receipt
assert "does not change dual-inventory scan limits" in receipt["scan_cap_statement"], receipt

pointer = receipts["clean_head_snapshot"]
assert pointer["mode"] == "clean-head-snapshot", pointer
assert pointer["file"] == "CLEAN_HEAD_SNAPSHOT_RECEIPT.json", pointer
assert pointer["source_dirty"] is True, pointer
assert pointer["source_untracked_count"] == 1, pointer
assert pointer["snapshot_head"] == head, pointer
assert pointer["non_authorization"] is True, pointer
assert scorecard["receipts"]["clean_head_snapshot"] == pointer, scorecard
assert "primary_surface_inventory" in receipts, receipts
PY

MISSING_SNAPSHOT="$TMP_ROOT/missing-snapshot"
MISSING_OUT="$TMP_ROOT/missing-out"
mkdir -p "$MISSING_OUT"
cat > "$MISSING_OUT/SCORECARD.json" <<'EOF'
{"receipts": {}}
EOF
cat > "$MISSING_OUT/SCORECARD_RECEIPTS.json" <<'EOF'
{}
EOF
if python3 "$REPO_ROOT/scripts/audit-clean-head-snapshot.py" "$TMP_ROOT/not-a-repo" "$MISSING_OUT" --snapshot-dir "$MISSING_SNAPSHOT" > "$TMP_ROOT/missing-stdout.txt" 2> "$TMP_ROOT/missing-stderr.txt"; then
    echo "expected missing target snapshot audit to fail" >&2
    exit 1
fi
python3 - "$MISSING_OUT" "$REPO_ROOT" <<'PY'
import json
import importlib.util
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
repo_root = pathlib.Path(sys.argv[2])
(out / "AUDIT_RUN_RECEIPT.json").write_text(json.dumps({"status": "failed"}) + "\n")
receipts = json.load(open(out / "SCORECARD_RECEIPTS.json"))
scorecard = json.load(open(out / "SCORECARD.json"))

script = repo_root / "scripts" / "audit-clean-head-snapshot.py"
spec = importlib.util.spec_from_file_location("audit_clean_head_snapshot", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)
module.augment_scorecard_outputs(
    out,
    {
        "source": {
            "head": "source-head",
            "dirty": True,
            "status_entry_count": 1,
            "untracked_count": 1,
            "modified_count": 0,
        },
        "snapshot": {
            "head": "snapshot-head",
            "tree": "snapshot-tree",
            "status_clean": True,
        },
        "audit": {"exit_code": 3},
    },
)

receipts = json.load(open(out / "SCORECARD_RECEIPTS.json"))
scorecard = json.load(open(out / "SCORECARD.json"))

assert "clean_head_snapshot" not in receipts, receipts
assert "clean_head_snapshot" not in scorecard.get("receipts", {}), scorecard
PY

echo "  VERDICT: PASS"
