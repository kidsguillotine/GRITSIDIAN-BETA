#!/usr/bin/env python3
"""
inject_frontmatter.py: Add minimal frontmatter stubs to .md files that have none.

Usage:
  python3 inject_frontmatter.py --dry-run    # preview only, no writes
  python3 inject_frontmatter.py --apply      # write changes

Adds to files without frontmatter:
  ---
  title: <derived from filename>
  created: <from git log first commit, or file mtime as fallback>
  status: unprocessed
  ---

Safe: skips any file that already has a frontmatter block (starts with ---).
"""

import os
import re
import sys
import subprocess
from pathlib import Path
from datetime import datetime

VAULT = Path("__VAULT_ROOT__")

TARGET_FOLDERS = [
    "20_personal",
    "30_career",
    "40_technical",
    "50_notes",
    "60_creative",
]

def has_frontmatter(text: str) -> bool:
    """True if file starts with a YAML frontmatter block."""
    return text.lstrip().startswith("---")

def title_from_filename(path: Path) -> str:
    """Derive a human-readable title from the filename."""
    stem = path.stem
    # Strip date prefix patterns like 2025-06-24_
    stem = re.sub(r"^\d{4}-\d{2}-\d{2}[_\s-]*", "", stem)
    # Replace underscores and hyphens with spaces
    stem = stem.replace("_", " ").replace("-", " ")
    # Collapse multiple spaces
    stem = re.sub(r"\s+", " ", stem).strip()
    # Title case, but preserve all-caps acronyms
    words = stem.split()
    titled = " ".join(w.capitalize() if not w.isupper() else w for w in words)
    return titled or path.stem

def git_created_date(path: Path) -> str:
    """Get the date of the first git commit for this file. Falls back to mtime."""
    try:
        result = subprocess.run(
            ["git", "-C", str(VAULT), "log", "--follow", "--diff-filter=A",
             "--format=%as", "--", str(path.relative_to(VAULT))],
            capture_output=True, text=True, timeout=5
        )
        lines = result.stdout.strip().splitlines()
        if lines:
            return lines[-1]  # oldest commit date
    except Exception:
        pass
    # Fallback: file modification time
    mtime = path.stat().st_mtime
    return datetime.fromtimestamp(mtime).strftime("%Y-%m-%d")

def build_frontmatter(title: str, created: str) -> str:
    # status: unsorted (was: unprocessed: invalid per validate_frontmatter.py _STATUS_VALUES)
    # tags: populated with #status/unsorted so validate_frontmatter no_tags check passes
    return f"---\ntitle: {title}\ncreated: {created}\nstatus: unsorted\ntags:\n  - '#status/unsorted'\n---\n\n"

def process_file(path: Path, dry_run: bool) -> bool:
    """Returns True if file was (or would be) modified."""
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        print(f"  ERROR reading {path.relative_to(VAULT)}: {e}")
        return False

    if has_frontmatter(text):
        return False

    title = title_from_filename(path)
    created = git_created_date(path)
    stub = build_frontmatter(title, created)

    if dry_run:
        print(f"  [DRY] {path.relative_to(VAULT)}")
        print(f"        title: {title} | created: {created}")
    else:
        path.write_text(stub + text, encoding="utf-8")
        print(f"  [OK]  {path.relative_to(VAULT)}")

    return True

def main():
    dry_run = "--dry-run" in sys.argv
    apply   = "--apply"   in sys.argv

    if not dry_run and not apply:
        print("Usage: inject_frontmatter.py --dry-run | --apply")
        sys.exit(1)

    mode = "DRY RUN" if dry_run else "APPLYING"
    print(f"\n=== inject_frontmatter.py: {mode} ===")
    print(f"Vault: {VAULT}")
    print(f"Folders: {', '.join(TARGET_FOLDERS)}\n")

    total_checked = 0
    total_modified = 0

    for folder_name in TARGET_FOLDERS:
        folder = VAULT / folder_name
        if not folder.exists():
            print(f"SKIP {folder_name}/: not found")
            continue

        md_files = sorted(folder.rglob("*.md"))
        folder_modified = 0

        print(f"--- {folder_name}/ ({len(md_files)} .md files) ---")
        for path in md_files:
            total_checked += 1
            if process_file(path, dry_run):
                folder_modified += 1
                total_modified += 1

        print(f"  -> {folder_modified} {'would be' if dry_run else ''} modified\n")

    print(f"=== DONE ===")
    print(f"Checked:  {total_checked} files")
    print(f"{'Would modify' if dry_run else 'Modified'}: {total_modified} files")

    if dry_run and total_modified > 0:
        print(f"\nRun with --apply to write changes.")

if __name__ == "__main__":
    main()
