#!/usr/bin/env bash
# detect-as-codex-native-runtime-readiness-evidence-gap.sh — AS-45: Codex native runtime readiness evidence gap
set -euo pipefail
REPO="${1:?Usage: detect-as-codex-native-runtime-readiness-evidence-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-45" "$REPO"
