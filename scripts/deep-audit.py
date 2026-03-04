#!/usr/bin/env python3
"""deep-audit.py -- Semantic cross-reference analyzer for repo-auditor deep mode.

Runs 5 deterministic semantic checks that require correlating information across
multiple files -- the class of findings that line-by-line bash tools cannot detect.

Checks:
  1. Schema orphan detection -- schema files with no validation consumer
  2. Cross-reference audit -- doc tables vs filesystem reality
  3. Dead script detection -- scripts never referenced from callers
  4. Constitution enforcement -- T1 claims without backing enforcement
  5. Count staleness -- numerical claims in docs vs actual values

Usage:
  python3 scripts/deep-audit.py <repo_path> [--output-dir <dir>] [--json]

Output:
  DEEP_FINDINGS.json in output_dir (or stdout with --json)
  Human-readable summary to stdout (default)

Exit codes:
  0 -- analysis complete (findings may be empty)
  1 -- invalid arguments or repo path
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path


def find_files(repo: Path, pattern: str, exclude_dirs: set[str] | None = None) -> list[Path]:
    """Recursively find files matching a glob pattern, excluding dirs.

    Currently unused — checks implement their own traversal.
    Retained for future check implementations.
    """
    if exclude_dirs is None:
        exclude_dirs = {".git", "node_modules", "__pycache__", ".venv", "venv"}
    results = []
    for root, dirs, files in os.walk(repo):
        dirs[:] = [d for d in dirs if d not in exclude_dirs]
        for f in files:
            p = Path(root) / f
            if p.match(pattern):
                results.append(p)
    return results


def read_text(path: Path) -> str:
    """Read file as text, returning empty string on failure."""
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except (OSError, UnicodeDecodeError):
        return ""


def grep_in_files(
    files: list[Path], pattern: str, exclude_self: Path | None = None
) -> list[tuple[Path, int, str]]:
    """Search for pattern in files, returning (path, line_number, line) tuples."""
    hits = []
    pat = re.compile(pattern, re.IGNORECASE)
    for f in files:
        if f == exclude_self:
            continue
        text = read_text(f)
        for i, line in enumerate(text.splitlines(), 1):
            if pat.search(line):
                hits.append((f, i, line.strip()))
    return hits


# ── Check 1: Schema Orphan Detection ─────────────────────────────────

def check_schema_orphans(repo: Path) -> list[dict]:
    """Find schema files (.schema.json) never referenced in executable code."""
    findings = []
    schemas_dir = repo / "schemas"
    if not schemas_dir.is_dir():
        return findings

    schema_files = list(schemas_dir.glob("*.schema.json"))
    if not schema_files:
        return findings

    # Gather all executable/code files (not .md, not schemas themselves)
    code_exts = {".sh", ".py", ".js", ".ts", ".yaml", ".yml", ".toml"}
    code_files = []
    exclude_dirs = {".git", "node_modules", "__pycache__", ".venv", "venv",
                    "targets", "runs", "work"}
    for root, dirs, files in os.walk(repo):
        dirs[:] = [d for d in dirs if d not in exclude_dirs]
        for f in files:
            p = Path(root) / f
            if p.suffix in code_exts:
                code_files.append(p)

    # Also check Makefile
    makefile = repo / "Makefile"
    if makefile.exists():
        code_files.append(makefile)

    for schema in schema_files:
        schema_name = schema.name
        # Search for schema name in code files (not docs)
        refs = grep_in_files(code_files, re.escape(schema_name), exclude_self=schema)
        # Filter out pure comments/docstrings -- keep actual validation references
        real_refs = []
        for path, lnum, line in refs:
            # Lines that are just comments/echoes referencing the schema name
            # still count as referencing it in code
            if path.suffix == ".md":
                continue
            real_refs.append((path, lnum, line))

        if not real_refs:
            findings.append({
                "check": "schema-orphan",
                "severity": "HIGH",
                "finding": f"Schema '{schema_name}' has no validation consumer in executable code",
                "file": str(schema.relative_to(repo)),
                "evidence": f"grep -rn '{schema_name}' scripts/ Makefile .github/ --include='*.sh' --include='*.py' shows 0 validation calls",
                "verification": f"grep -rn '{schema_name}' scripts/ Makefile .github/ --include='*.sh' --include='*.py'",
            })

    return findings


# ── Check 2: Cross-Reference Audit ───────────────────────────────────

def check_cross_references(repo: Path) -> list[dict]:
    """Check AGENTS.md/doc tables vs filesystem reality."""
    findings = []
    agents_md = repo / "AGENTS.md"
    if not agents_md.exists():
        return findings

    text = read_text(agents_md)

    # --- Agent files vs AGENTS.md ---
    # Find all .agent.md references in AGENTS.md (exact filename)
    agent_refs_exact = set(re.findall(r'(\b[\w.-]+\.agent\.md)\b', text))

    # Find actual agent files on disk
    agent_dirs = [
        repo / ".github" / "agents",
        repo / ".github" / "agents" / "archive",
        repo / ".agents",
    ]
    actual_agents = set()
    for d in agent_dirs:
        if d.is_dir():
            for f in d.iterdir():
                if f.name.endswith(".agent.md"):
                    actual_agents.add(f.name)

    # Orphan agent files (on disk but not referenced in AGENTS.md)
    # Check both exact filename AND agent name stem (e.g., "critic" for "critic.agent.md")
    for agent_file in sorted(actual_agents):
        if agent_file in agent_refs_exact:
            continue
        # Extract agent name stem (strip .agent.md)
        stem = agent_file.replace(".agent.md", "")
        # Check if the stem appears in AGENTS.md (case-insensitive word boundary)
        if re.search(rf'\b{re.escape(stem)}\b', text, re.IGNORECASE):
            continue
        # Also check short name (after last dot) for prefixed names like "speckit.clarify"
        short_name = stem.rsplit(".", 1)[-1] if "." in stem else None
        if short_name and re.search(rf'\b{re.escape(short_name)}\b', text, re.IGNORECASE):
            continue
        # Find where the file actually lives
        loc = "unknown"
        for d in agent_dirs:
            if (d / agent_file).exists():
                loc = str((d / agent_file).relative_to(repo))
                break
        findings.append({
            "check": "cross-reference",
            "severity": "MEDIUM",
            "finding": f"Agent file '{agent_file}' exists on disk but not referenced in AGENTS.md",
            "file": loc,
            "evidence": f"File exists at {loc} but AGENTS.md does not mention '{stem}' or '{agent_file}'",
            "verification": f"grep -ci '{stem}' AGENTS.md",
        })

    # --- Skills table vs disk ---
    skills_root = None
    for candidate in [repo / ".agents" / "skills", repo / ".github" / "skills"]:
        if candidate.is_dir():
            skills_root = candidate
            break

    if skills_root:
        disk_skills = set()
        for d in skills_root.iterdir():
            if d.is_dir() and not d.name.startswith("."):
                disk_skills.add(d.name)

        # Extract skills mentioned in AGENTS.md Skills table
        # Look for table rows with skill names
        table_skills = set()
        in_skills_table = False
        for line in text.splitlines():
            if "## Skills" in line or "Skills (" in line:
                in_skills_table = True
                continue
            if in_skills_table:
                if line.startswith("## ") or line.startswith("---"):
                    break
                # Parse table row: | # | name | purpose |
                m = re.match(r'\|\s*\d+\s*\|\s*\*?\*?([\w-]+)\*?\*?\s*\|', line)
                if m:
                    table_skills.add(m.group(1))

        # Skills on disk but not in table
        missing_from_table = disk_skills - table_skills
        for skill in sorted(missing_from_table):
            findings.append({
                "check": "cross-reference",
                "severity": "MEDIUM",
                "finding": f"Skill '{skill}' exists on disk but missing from AGENTS.md Skills table",
                "file": str(skills_root.relative_to(repo) / skill),
                "evidence": f"Directory exists at {skills_root.relative_to(repo)}/{skill}/ but not in Skills table",
                "verification": f"ls -d {skills_root.relative_to(repo)}/{skill}/ && grep -c '{skill}' AGENTS.md",
            })

        # Skills in table but not on disk
        missing_from_disk = table_skills - disk_skills
        for skill in sorted(missing_from_disk):
            findings.append({
                "check": "cross-reference",
                "severity": "HIGH",
                "finding": f"Skill '{skill}' listed in AGENTS.md but does not exist on disk",
                "file": "AGENTS.md",
                "evidence": f"AGENTS.md lists skill but {skills_root.relative_to(repo)}/{skill}/ does not exist",
                "verification": f"ls -d {skills_root.relative_to(repo)}/{skill}/",
            })

    return findings


# ── Check 3: Dead Script Detection ───────────────────────────────────

def check_dead_scripts(repo: Path) -> list[dict]:
    """Find scripts never referenced from Makefile, agents, skills, or other scripts."""
    findings = []
    scripts_dir = repo / "scripts"
    if not scripts_dir.is_dir():
        return findings

    # Gather scripts (non-archive, non-lib)
    scripts = []
    for f in scripts_dir.iterdir():
        if f.is_file() and f.suffix in (".sh", ".py") and f.name != "__init__.py":
            scripts.append(f)
    # Also check scripts/lib/
    lib_dir = scripts_dir / "lib"
    if lib_dir.is_dir():
        for f in lib_dir.iterdir():
            if f.is_file() and f.suffix in (".sh", ".py") and f.name != "__init__.py":
                scripts.append(f)

    if not scripts:
        return findings

    # Gather all reference sources
    ref_sources: list[Path] = []
    # Makefile
    makefile = repo / "Makefile"
    if makefile.exists():
        ref_sources.append(makefile)
    # AGENTS.md
    agents_md = repo / "AGENTS.md"
    if agents_md.exists():
        ref_sources.append(agents_md)

    # All scripts (for cross-references)
    ref_sources.extend(scripts)

    # Agent files
    for agent_dir in [repo / ".github" / "agents", repo / ".agents"]:
        if agent_dir.is_dir():
            for root, dirs, files in os.walk(agent_dir):
                for f in files:
                    ref_sources.append(Path(root) / f)

    # Skill files
    skills_dir = None
    for candidate in [repo / ".agents" / "skills", repo / ".github" / "skills"]:
        if candidate.is_dir():
            skills_dir = candidate
            break
    if skills_dir:
        for root, dirs, files in os.walk(skills_dir):
            for f in files:
                ref_sources.append(Path(root) / f)

    # CI workflow files
    workflows_dir = repo / ".github" / "workflows"
    if workflows_dir.is_dir():
        for f in workflows_dir.iterdir():
            if f.is_file():
                ref_sources.append(f)

    # Test files
    tests_dir = repo / "tests"
    if tests_dir.is_dir():
        for f in tests_dir.iterdir():
            if f.is_file():
                ref_sources.append(f)

    # Check each script for references
    for script in scripts:
        script_name = script.name
        stem = script.stem

        # Direct filename reference
        refs = grep_in_files(ref_sources, re.escape(script_name), exclude_self=script)

        if not refs:
            # Also check for stem reference (without extension) -- use word boundaries
            refs = grep_in_files(ref_sources, rf'\b{re.escape(stem)}\b', exclude_self=script)

        if not refs:
            # Check for glob/bracket patterns (e.g., "ground-truth-t[1-7].sh")
            # Convert script_name into a regex that matches bracket-glob patterns
            # E.g., "ground-truth-t3.sh" should match "ground-truth-t[1-7].sh"
            found_via_glob = False
            for src in ref_sources:
                if src == script:
                    continue
                src_text = read_text(src)
                # Find bracket patterns in source text
                for m in re.finditer(r'[\w.-]*\[[\w-]+\][\w.-]*\.(?:sh|py)', src_text):
                    glob_pat = m.group(0)
                    # Convert glob to regex: keep brackets as-is, escape the rest
                    # Split on brackets, escape non-bracket parts
                    regex_parts = []
                    i = 0
                    gpat = glob_pat
                    while i < len(gpat):
                        if gpat[i] == '[':
                            end = gpat.index(']', i)
                            regex_parts.append(gpat[i:end+1])  # keep bracket expr
                            i = end + 1
                        else:
                            # Accumulate non-bracket chars
                            chunk = ""
                            while i < len(gpat) and gpat[i] != '[':
                                chunk += gpat[i]
                                i += 1
                            regex_parts.append(re.escape(chunk))
                    regex_pat = "".join(regex_parts)
                    try:
                        if re.match(regex_pat + "$", script_name):
                            found_via_glob = True
                            break
                    except re.error:
                        pass
                if found_via_glob:
                    break

            if not found_via_glob:
                rel = script.relative_to(repo)
                findings.append({
                    "check": "dead-script",
                    "severity": "MEDIUM",
                    "finding": f"Script '{script_name}' is never referenced from Makefile, agents, skills, tests, or other scripts",
                    "file": str(rel),
                    "evidence": f"grep -rn '{script_name}' Makefile AGENTS.md scripts/ .github/ .agents/ tests/ shows 0 external references",
                    "verification": f"grep -rn '{script_name}' Makefile AGENTS.md scripts/ .github/ .agents/ tests/",
                })

    return findings


# ── Check 4: Constitution Enforcement Audit ──────────────────────────

def check_constitution_enforcement(repo: Path) -> list[dict]:
    """Check T1 enforcement claims in constitution have backing scripts."""
    findings = []
    constitution = repo / ".specify" / "memory" / "constitution.md"
    if not constitution.exists():
        return findings

    text = read_text(constitution)
    makefile = repo / "Makefile"
    makefile_text = read_text(makefile) if makefile.exists() else ""

    # Find T1 enforcement claims that reference specific make targets or scripts
    # Pattern: "T1" ... "`make <target>`" or "`bash scripts/<script>`"
    for i, line in enumerate(text.splitlines(), 1):
        if "T1" not in line:
            continue

        # Find make target references
        make_refs = re.findall(r'`make\s+([\w-]+)`', line)
        for target in make_refs:
            # Check if target exists in Makefile
            # Look for "target:" at start of line
            if not re.search(rf'^{re.escape(target)}\s*:', makefile_text, re.MULTILINE):
                findings.append({
                    "check": "constitution-enforcement",
                    "severity": "HIGH",
                    "finding": f"Constitution claims T1 via `make {target}` but target does not exist in Makefile",
                    "file": str(constitution.relative_to(repo)),
                    "evidence": f"Line {i}: {line.strip()[:100]}...",
                    "verification": f"grep -n '^{target}:' Makefile",
                })

        # Find script references
        script_refs = re.findall(r'`(?:bash\s+)?scripts/([\w./-]+)`', line)
        for script_name in script_refs:
            script_path = repo / "scripts" / script_name
            if not script_path.exists():
                findings.append({
                    "check": "constitution-enforcement",
                    "severity": "HIGH",
                    "finding": f"Constitution claims T1 via script '{script_name}' but script does not exist",
                    "file": str(constitution.relative_to(repo)),
                    "evidence": f"Line {i}: {line.strip()[:100]}...",
                    "verification": f"ls scripts/{script_name}",
                })

    return findings


# ── Check 5: Count Staleness Detection ───────────────────────────────

def check_count_staleness(repo: Path) -> list[dict]:
    """Detect stale counts in documentation vs actual filesystem."""
    findings = []

    agents_md = repo / "AGENTS.md"
    if not agents_md.exists():
        return findings
    text = read_text(agents_md)

    # Count actual scripts
    scripts_dir = repo / "scripts"
    archive_dir = scripts_dir / "archive"
    if scripts_dir.is_dir():
        actual_scripts = []
        for f in scripts_dir.iterdir():
            if f.is_file() and f.suffix in (".sh", ".py"):
                actual_scripts.append(f)
        lib_dir = scripts_dir / "lib"
        if lib_dir.is_dir():
            for f in lib_dir.iterdir():
                if f.is_file() and f.suffix in (".sh", ".py"):
                    actual_scripts.append(f)

        # Find script count claims in AGENTS.md
        # Pattern: "NN active scripts" or "Scripts (NN)"
        count_match = re.search(r'(\d+)\s+active\s+scripts', text)
        if count_match:
            claimed = int(count_match.group(1))
            actual = len(actual_scripts)
            if abs(claimed - actual) > 2:  # Tolerance of 2 for minor drift
                findings.append({
                    "check": "count-staleness",
                    "severity": "LOW",
                    "finding": f"AGENTS.md claims {claimed} active scripts but {actual} found on disk (delta: {actual - claimed})",
                    "file": "AGENTS.md",
                    "evidence": f"Claimed: '{count_match.group(0)}'. Actual: find scripts -type f \\( -name '*.sh' -o -name '*.py' \\) = {actual}",
                    "verification": "find scripts -type f \\( -name '*.sh' -o -name '*.py' \\) ! -path 'scripts/archive/*' | wc -l",
                })

    # Count actual specs
    specs_dir = repo / "specs"
    if specs_dir.is_dir():
        actual_specs = [d for d in specs_dir.iterdir()
                        if d.is_dir() and not d.name.startswith(".")
                        and d.name != "archive"]
        spec_archive = specs_dir / "archive"
        archived_specs = []
        if spec_archive.is_dir():
            archived_specs = [d for d in spec_archive.iterdir() if d.is_dir()]

        spec_match = re.search(r'(\d+)\s+(?:active\s+)?specs?\b', text)
        if spec_match:
            claimed = int(spec_match.group(1))
            actual = len(actual_specs)
            if abs(claimed - actual) > 2:
                findings.append({
                    "check": "count-staleness",
                    "severity": "LOW",
                    "finding": f"AGENTS.md claims {claimed} specs but {actual} active found on disk",
                    "file": "AGENTS.md",
                    "evidence": f"Claimed: '{spec_match.group(0)}'. Actual active: {actual}",
                    "verification": "ls -d specs/*/ | wc -l",
                })

    # Count actual learnings
    learnings_md = repo / "LEARNINGS.md"
    if learnings_md.exists():
        learnings_text = read_text(learnings_md)
        # Always count L### entries as ground truth
        actual_learnings = len(re.findall(r'^#+\s+L\d+', learnings_text, re.MULTILINE))
        # If header has a total, cross-check but prefer entry count
        total_match = re.search(r'(\d+)\s+total', learnings_text)
        if total_match and actual_learnings == 0:
            # Archived partition: entries may be in a separate file
            actual_learnings = int(total_match.group(1))

        # Find learnings claims in AGENTS.md
        # Multiple patterns: "NNN learnings", "L1-LNNN"
        claims = []
        for m in re.finditer(r'(\d{2,4})\s+learnings', text):
            claims.append(("header", int(m.group(1)), m.group(0)))
        for m in re.finditer(r'L1-L(\d+)', text):
            claims.append(("range", int(m.group(1)), m.group(0)))

        # Check claims against each other and actual
        if len(claims) >= 2:
            vals = set(c[1] for c in claims)
            if len(vals) > 1:
                claims_str = ", ".join(f"{c[2]}={c[1]}" for c in claims)
                findings.append({
                    "check": "count-staleness",
                    "severity": "LOW",
                    "finding": f"AGENTS.md has inconsistent learnings counts: {claims_str} (actual: ~{actual_learnings})",
                    "file": "AGENTS.md",
                    "evidence": f"Multiple learnings count values disagree: {claims_str}",
                    "verification": "grep -n 'learnings\\|L1-L' AGENTS.md | head -5",
                })

    return findings


# ── Main ─────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Semantic cross-reference analyzer for repo-auditor deep mode"
    )
    parser.add_argument("repo_path", help="Path to repository to audit")
    parser.add_argument("--output-dir", help="Directory to write DEEP_FINDINGS.json")
    parser.add_argument("--json", action="store_true", help="Output JSON to stdout")
    args = parser.parse_args()

    repo = Path(args.repo_path).resolve()
    if not repo.is_dir():
        print(f"ERROR: {args.repo_path} is not a directory", file=sys.stderr)
        return 1

    # Run all checks
    all_findings: list[dict] = []
    checks = [
        ("schema-orphan", check_schema_orphans),
        ("cross-reference", check_cross_references),
        ("dead-script", check_dead_scripts),
        ("constitution-enforcement", check_constitution_enforcement),
        ("count-staleness", check_count_staleness),
    ]

    for name, func in checks:
        try:
            results = func(repo)
            all_findings.extend(results)
        except Exception as e:
            all_findings.append({
                "check": name,
                "severity": "ERROR",
                "finding": f"Check '{name}' raised exception: {e}",
                "file": "",
                "evidence": str(e),
                "verification": "",
            })

    # Sort by severity
    severity_order = {"HIGH": 0, "MEDIUM": 1, "LOW": 2, "ERROR": 3}
    all_findings.sort(key=lambda f: severity_order.get(f["severity"], 99))

    # Build output
    output = {
        "repo": str(repo),
        "mode": "deep",
        "checks_run": len(checks),
        "total_findings": len(all_findings),
        "findings_by_severity": {
            "HIGH": sum(1 for f in all_findings if f["severity"] == "HIGH"),
            "MEDIUM": sum(1 for f in all_findings if f["severity"] == "MEDIUM"),
            "LOW": sum(1 for f in all_findings if f["severity"] == "LOW"),
            "ERROR": sum(1 for f in all_findings if f["severity"] == "ERROR"),
        },
        "findings": all_findings,
    }

    if args.json or args.output_dir:
        json_str = json.dumps(output, indent=2)

    if args.output_dir:
        out_dir = Path(args.output_dir)
        out_dir.mkdir(parents=True, exist_ok=True)
        out_file = out_dir / "DEEP_FINDINGS.json"
        out_file.write_text(json_str + "\n")
        print(f"  [deep-audit] Wrote {out_file}")

    if args.json:
        print(json_str)
        return 0

    # Human-readable output
    print("")
    print("--- Deep Semantic Analysis ---")
    print("")
    print(f"  Checks run: {len(checks)}")
    print(f"  Findings:   {len(all_findings)} ({output['findings_by_severity']['HIGH']}H / {output['findings_by_severity']['MEDIUM']}M / {output['findings_by_severity']['LOW']}L)")
    print("")

    for i, f in enumerate(all_findings, 1):
        sev = f["severity"]
        marker = {"HIGH": "!!!", "MEDIUM": "!!", "LOW": "!", "ERROR": "ERR"}.get(sev, "?")
        print(f"  [{marker}] {sev}: {f['finding']}")
        print(f"       File: {f['file']}")
        print(f"       Verify: {f['verification']}")
        print("")

    return 0


if __name__ == "__main__":
    sys.exit(main())
