#!/usr/bin/env bash
# detect-as-pricing-provenance-gap.sh — AS-12: pricing provenance gap
set -euo pipefail

REPO="${1:?Usage: detect-as-pricing-provenance-gap.sh <repo_path>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/as_signature_scan.py" "AS-12" "$REPO"
