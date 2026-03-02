#!/usr/bin/env python3
"""ds_json_helper.py — Safe JSON output for detection signature scripts.

Usage in bash:
  python3 scripts/ds_json_helper.py '{"ds_id":"DS-34"}' key1=val1 key2=val2 evidence="some text"

All values are auto-typed: true/false become booleans, integers stay integers,
everything else is a string. The 'evidence' key is always truncated to 500 chars.
"""

import json
import sys

def main():
    if len(sys.argv) < 2:
        print('{"error":"no base JSON provided"}')
        sys.exit(1)

    # Parse base JSON
    try:
        base = json.loads(sys.argv[1])
    except json.JSONDecodeError:
        base = {}

    # Parse key=value pairs
    for arg in sys.argv[2:]:
        if '=' not in arg:
            continue
        key, _, value = arg.partition('=')
        # Auto-type
        if value.lower() == 'true':
            base[key] = True
        elif value.lower() == 'false':
            base[key] = False
        else:
            try:
                base[key] = int(value)
            except ValueError:
                try:
                    base[key] = float(value)
                except ValueError:
                    base[key] = value

    # Truncate evidence
    if 'evidence' in base and isinstance(base['evidence'], str):
        base['evidence'] = base['evidence'][:500]

    print(json.dumps(base, ensure_ascii=True))

if __name__ == '__main__':
    main()
