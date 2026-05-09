#!/usr/bin/env bash
# detect-as-model-effort-binding-gap.sh - AS-19: model/effort claim binding gap
set -euo pipefail

REPO="${1:?Usage: detect-as-model-effort-binding-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-19" "$REPO"
