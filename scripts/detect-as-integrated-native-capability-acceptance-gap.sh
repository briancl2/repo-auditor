#!/usr/bin/env bash
# detect-as-integrated-native-capability-acceptance-gap.sh - AS-47: Integrated native capability acceptance evidence gap
set -euo pipefail
REPO="${1:?Usage: detect-as-integrated-native-capability-acceptance-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-47" "$REPO"
