#!/usr/bin/env bash
# detect-as-docs-vs-observed-host-drift.sh — AS-02: docs-vs-observed host drift
set -euo pipefail

REPO="${1:?Usage: detect-as-docs-vs-observed-host-drift.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-02" "$REPO"
