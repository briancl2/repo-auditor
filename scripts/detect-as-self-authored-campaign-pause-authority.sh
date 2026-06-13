#!/usr/bin/env bash
# detect-as-self-authored-campaign-pause-authority.sh - AS-38: self-authored campaign pause authority
set -euo pipefail
REPO="${1:?Usage: detect-as-self-authored-campaign-pause-authority.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-38" "$REPO"
