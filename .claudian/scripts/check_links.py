#!/usr/bin/env python3
"""
check_links.py: wikilink resolver + auditor for the your-scripts vault.

Modes:
  (default)                       Print short summary: total / broken.
  --audit                         4-bucket split: OK / EXTENSION_ONLY / PATH_DRIFT / ORPHAN.
  --audit --json                  Same, JSON-formatted (for script consumers).
  --count-broken                  Print single int: total broken (EXT + DRIFT + ORPHAN).
  --count-broken-extensions       Print single int: just EXTENSION_ONLY count.
  --fix --scope FILE [FILE ...]   Strip trailing (.md)+ sequences from wikilink targets in
                                  the listed files. Dry-run default: emits unified diff
                                  to stdout. Add --apply to actually rewrite files.

Authority:
  Resolver logic mirrors 99_system/audits/wikilink_audit_20260627.py (the frozen
  baseline-as-code). Re-running --audit here should produce the same buckets
  the baseline did, modulo session-drift in handoff regen.

Wired into:
  - validate_system.sh c10_check (--count-broken)
  - gen_session_boot.sh broken-wikilink line (--audit --json)
  - .git/hooks/pre-commit wikilink lint (independent regex)

GOTCHAS:
  G44: wikilinks must be extension-free. This script is the measurement layer.
"""
import argparse
import difflib
import json
import os
import re
import sys
from collections import Counter, defaultdict

VAULT = "__VAULT_ROOT__"

# Excludes mirror the audit baseline so counts stay comparable.
# .vault-operator/skills/ was INCLUDED per orphan-scope decision 2026-06-27,
# REVERSED 2026-06-28 (W1 fix): SKILL.md wikilinks are template placeholders
# (`[[<basename>#Page <N>|^]]`, `[[Agentic AI]]`, `[[<Cluster>]]`) and example
# refs in plugin documentation, not vault links. ~101 broken matches dropped.
# Diverges from frozen baseline by design: baseline is historical.
EXCLUDE_PREFIXES = (
    "_handoff/handoff_history/",
    "_handoff/erosion_audit/",
    "_handoff/imported/",
    "_handoff/reconcile_",  # auto-generated state snapshots; contain stale wikilinks by design
    ".trash/",
    ".obsidian/",
    ".claudian/",
    ".git/",
    ".smart-env/",
    "99_system/archive/",
    ".vault-operator/skills/",
    ".vault-operator/plugin-skills/",  # plugin asset files; not vault navigation content
    "99_system/obsilo-memory/",  # generated files; contains illustration wikilinks from CLAUDE.md rule text
    "_handoff/archive/",  # archived handoff records; consistent with _handoff/handoff_history/ exclusion
)

# Individual files excluded from audit (documentation with intentional example wikilinks,
# or pre-commit-hook-whitelisted documentation files)
EXCLUDE_FILES = {
    "CLAUDE.md",  # constitution; wikilink format section contains [[folder/note]] examples
    "_handoff/GOTCHAS.md",  # append-only lesson log; documents wikilink corruption with intentional examples
    "_handoff/claudian-migration-decisions-20260628.md",  # historical migration decision log
    "random chat history.md",  # chat history export; full of example/placeholder wikilinks, not navigation
    "99_system/DOC_STANDARD.md",  # documents the wikilink rule; contains pattern examples
    "_handoff/UNREVIEWED_TRIAGE.md",  # auto-generated; contains raw agent_memory snippets with [[wikilinks]] in record text (not vault navigation)
}

WIKILINK_RE = re.compile(r'\[\[([^\]\n|]+?)(\|[^\]\n]*)?\]\]')
# For --fix: matches the whole `[[target|alias]]` token so we can rewrite target in place.
WIKILINK_TOKEN_RE = re.compile(r'\[\[([^\]\n|]+?)(\|[^\]\n]*)?\]\]')


def is_excluded(rel_path):
    if rel_path in EXCLUDE_FILES:
        return True
    return any(rel_path.startswith(p) for p in EXCLUDE_PREFIXES)


def strip_md_extensions(target):
    """Strip trailing (.md)+ sequences: '.md', '.md.md', '.md.md.md', etc."""
    return re.sub(r'(\.md)+$', '', target)


def build_index():
    """Walk the vault, return (basename_to_paths, all_md_paths)."""
    basename_to_paths = defaultdict(list)
    all_md_paths = set()
    for root, dirs, files in os.walk(VAULT):
        rel_root = os.path.relpath(root, VAULT)
        if rel_root != '.' and is_excluded(rel_root + '/'):
            dirs[:] = []
            continue
        dirs[:] = [
            d for d in dirs
            if not is_excluded(os.path.join(rel_root, d) + '/') and not d.startswith('.git')
        ]
        for fn in files:
            if not fn.endswith('.md'):
                continue
            rel = os.path.normpath(os.path.join(rel_root, fn))
            if is_excluded(rel):
                continue
            all_md_paths.add(rel)
            basename_to_paths[fn[:-3]].append(rel)
    return basename_to_paths, all_md_paths


def classify_target(target, basename_to_paths, all_md_paths):
    """Return (bucket, optional_fix_target).
    bucket ∈ {'OK', 'EXTENSION_ONLY', 'PATH_DRIFT', 'ORPHAN'}.
    fix_target is the suggested rewrite if bucket == 'EXTENSION_ONLY', else None.
    """
    target_with_md = target if target.endswith('.md') else target + '.md'
    target_norm = os.path.normpath(target_with_md)

    if target_norm in all_md_paths:
        # File exists at the exact path the wikilink names. If user wrote .md
        # inside the brackets, it's still EXT (resolver fails on .md suffix).
        if target.endswith('.md') or re.search(r'(\.md){2,}$', target):
            return 'EXTENSION_ONLY', strip_md_extensions(target)
        return 'OK', None

    stripped = strip_md_extensions(target)
    stripped_norm = os.path.normpath(stripped + '.md')
    if stripped_norm in all_md_paths:
        return 'EXTENSION_ONLY', stripped

    base = os.path.basename(stripped)
    candidates = basename_to_paths.get(base, [])
    if candidates:
        return 'PATH_DRIFT', None
    return 'ORPHAN', None


def scan_all_files(basename_to_paths, all_md_paths):
    """Scan every active .md file. Return buckets dict + per-file counter."""
    buckets = {'OK': 0, 'EXTENSION_ONLY': 0, 'PATH_DRIFT': 0, 'ORPHAN': 0}
    per_file = defaultdict(lambda: Counter())
    for rel in sorted(all_md_paths):
        abs_path = os.path.join(VAULT, rel)
        try:
            with open(abs_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
        except Exception:
            continue
        for m in WIKILINK_RE.finditer(content):
            target = m.group(1).strip()
            bucket, _ = classify_target(target, basename_to_paths, all_md_paths)
            buckets[bucket] += 1
            per_file[rel][bucket] += 1
    return buckets, per_file


def cmd_audit(as_json):
    basename_to_paths, all_md_paths = build_index()
    buckets, _ = scan_all_files(basename_to_paths, all_md_paths)
    total = sum(buckets.values())
    broken = buckets['EXTENSION_ONLY'] + buckets['PATH_DRIFT'] + buckets['ORPHAN']
    if as_json:
        print(json.dumps({
            'total': total,
            'ok': buckets['OK'],
            'extension_only': buckets['EXTENSION_ONLY'],
            'path_drift': buckets['PATH_DRIFT'],
            'orphan': buckets['ORPHAN'],
            'broken': broken,
            'ok_rate_pct': round(buckets['OK'] * 100.0 / total, 1) if total else 0.0,
        }))
    else:
        print(f"Total wikilinks scanned: {total}")
        for bucket in ('OK', 'EXTENSION_ONLY', 'PATH_DRIFT', 'ORPHAN'):
            n = buckets[bucket]
            pct = (n * 100.0 / total) if total else 0.0
            print(f"  {bucket:18s}: {n:5d}  ({pct:5.1f}%)")
        print(f"  {'BROKEN total':18s}: {broken:5d}  ({(broken*100.0/total):5.1f}%)" if total else "")
    return 0


def cmd_count_broken():
    basename_to_paths, all_md_paths = build_index()
    buckets, _ = scan_all_files(basename_to_paths, all_md_paths)
    print(buckets['EXTENSION_ONLY'] + buckets['PATH_DRIFT'] + buckets['ORPHAN'])
    return 0


def cmd_count_broken_extensions():
    basename_to_paths, all_md_paths = build_index()
    buckets, _ = scan_all_files(basename_to_paths, all_md_paths)
    print(buckets['EXTENSION_ONLY'])
    return 0


def cmd_fix(scope_files, apply_changes):
    """Strip (.md)+ from wikilink targets in the named files.
    Default: emit unified diff to stdout, do not write.
    With --apply: write files in place.
    Refuses to operate on files outside the vault.
    """
    if not scope_files:
        print("ERROR: --fix requires --scope FILE [FILE ...]", file=sys.stderr)
        return 2

    changed_count = 0
    for rel in scope_files:
        abs_path = os.path.join(VAULT, rel) if not os.path.isabs(rel) else rel
        # Safety: refuse anything outside the vault
        try:
            abs_real = os.path.realpath(abs_path)
            vault_real = os.path.realpath(VAULT)
            if not abs_real.startswith(vault_real + os.sep):
                print(f"REFUSED (outside vault): {rel}", file=sys.stderr)
                continue
        except Exception:
            print(f"REFUSED (path error): {rel}", file=sys.stderr)
            continue
        if not os.path.isfile(abs_path):
            print(f"SKIP (not a file): {rel}", file=sys.stderr)
            continue

        with open(abs_path, 'r', encoding='utf-8') as f:
            original = f.read()

        def replace_token(m):
            target = m.group(1)
            alias = m.group(2) or ''
            stripped = strip_md_extensions(target)
            if stripped == target:
                return m.group(0)  # no change
            return f'[[{stripped}{alias}]]'

        rewritten = WIKILINK_TOKEN_RE.sub(replace_token, original)
        if rewritten == original:
            continue

        changed_count += 1
        if apply_changes:
            with open(abs_path, 'w', encoding='utf-8') as f:
                f.write(rewritten)
            print(f"REWROTE: {rel}", file=sys.stderr)
        else:
            diff = difflib.unified_diff(
                original.splitlines(keepends=True),
                rewritten.splitlines(keepends=True),
                fromfile=f'a/{rel}',
                tofile=f'b/{rel}',
            )
            sys.stdout.writelines(diff)

    if apply_changes:
        print(f"Applied to {changed_count} file(s).", file=sys.stderr)
    else:
        print(f"\n# {changed_count} file(s) would be changed. Re-run with --apply to write.",
              file=sys.stderr)
    return 0


def cmd_default():
    """Backward-compatible behavior: print total + broken count summary."""
    basename_to_paths, all_md_paths = build_index()
    buckets, _ = scan_all_files(basename_to_paths, all_md_paths)
    total = sum(buckets.values())
    broken = buckets['EXTENSION_ONLY'] + buckets['PATH_DRIFT'] + buckets['ORPHAN']
    print(f"Total links found: {total}")
    print(f"Broken links: {broken}")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    parser.add_argument('--audit', action='store_true',
                        help='4-bucket split (OK/EXT/DRIFT/ORPHAN)')
    parser.add_argument('--json', action='store_true',
                        help='JSON output (only with --audit)')
    parser.add_argument('--count-broken', action='store_true',
                        help='Print single int: total broken')
    parser.add_argument('--count-broken-extensions', action='store_true',
                        help='Print single int: EXTENSION_ONLY count')
    parser.add_argument('--fix', action='store_true',
                        help='Strip trailing .md from wikilink targets (requires --scope)')
    parser.add_argument('--scope', nargs='+', default=None,
                        help='Vault-relative file paths to operate on (--fix only)')
    parser.add_argument('--apply', action='store_true',
                        help='With --fix: write changes (default = dry-run)')
    args = parser.parse_args()

    if args.fix:
        return cmd_fix(args.scope or [], args.apply)
    if args.count_broken:
        return cmd_count_broken()
    if args.count_broken_extensions:
        return cmd_count_broken_extensions()
    if args.audit:
        return cmd_audit(args.json)
    return cmd_default()


if __name__ == '__main__':
    sys.exit(main())
