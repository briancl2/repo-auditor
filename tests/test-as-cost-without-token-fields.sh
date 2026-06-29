#!/usr/bin/env bash
# Verify AS-09 flags genuine cost claims that lack token fields, without
# false-positiving on shell/Makefile/awk positional parameters ($1, $$1, $2).
# Precision guard for repo-auditor#173.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

FP_REPO="$TMPDIR/cost-positional-fp"       # shell/Makefile positionals only -> must NOT fire
REAL_REPO="$TMPDIR/cost-real-claim"        # genuine money claim, no tokens   -> must fire
GROUNDED_REPO="$TMPDIR/cost-with-tokens"   # money claim WITH token fields    -> must NOT fire
mkdir -p "$FP_REPO/scripts" "$REAL_REPO/docs" "$GROUNDED_REPO/docs"

# --- False-positive control: positional parameters are not money ---
cat > "$FP_REPO/scripts/release.sh" <<'EOF'
#!/usr/bin/env bash
# Deploy helper: positional args are NOT cost estimates.
set -euo pipefail
target=$1
environment=$2
echo "deploying ${target} to ${environment} (slot ${3})"
awk '{print $1, $2, $$3}' manifest.txt
EOF

cat > "$FP_REPO/Makefile" <<'EOF'
deploy:
	@echo "arg1=$$1 arg2=$$2"
	@./scripts/release.sh $$1 $$2
EOF

# --- True positive: a real money cost claim without token accounting ---
cat > "$REAL_REPO/docs/cost-note.md" <<'EOF'
# Cost note

The estimated cost is $5.00 per run, and last month the total spend reached
$88.40 across all models. No token accounting was recorded.
EOF

# --- Grounded: a money claim that DOES carry token fields is not a gap ---
cat > "$GROUNDED_REPO/docs/benchmark.md" <<'EOF'
# Benchmark

Run cost was $88.40 with input_tokens=1200 and output_tokens=300
(total_tokens=1500) recorded per model.
EOF

python3 - "$REPO_ROOT" "$FP_REPO" "$REAL_REPO" "$GROUNDED_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

repo_root, fp_repo, real_repo, grounded_repo = map(Path, sys.argv[1:])


def run(repo: Path) -> dict:
    completed = subprocess.run(
        ["bash", str(repo_root / "scripts/detect-as-cost-without-token-fields.sh"), str(repo)],
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr or completed.stdout)
    return json.loads(completed.stdout)


fp = run(fp_repo)
assert fp["ds_id"] == "AS-09", fp
assert fp["fired"] is False, fp  # positionals ($1/$$1/$2) must not read as cost

real = run(real_repo)
assert real["ds_id"] == "AS-09", real
assert real["fired"] is True, real  # genuine money claim without tokens still fires

grounded = run(grounded_repo)
assert grounded["ds_id"] == "AS-09", grounded
assert grounded["fired"] is False, grounded  # money + token fields is grounded
PY

echo "PASS: AS-09 cost-without-token-fields precision (positionals vs money) covered"
