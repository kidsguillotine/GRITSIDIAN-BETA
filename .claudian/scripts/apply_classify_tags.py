#!/usr/bin/env python3
"""
apply_classify_tags.py: Apply classify.py manifest tags to vault files.

Usage:
  python3 apply_classify_tags.py --manifest PATH [--dry-run] [--overwrite]

Reads the JSON manifest produced by classify.py --output and writes
#area/* and #type/* tags into the frontmatter of each "tagged" file.

Modes:
  --dry-run    Preview changes, no writes (default)
  --apply      Write changes to disk

Options:
  --overwrite  Replace existing area/type tags (default: skip if tags present)
  --filter     Comma-separated basenames to process (e.g. Bills.md,debts.md)
"""

import argparse
import json
import re
import sys
from pathlib import Path

VAULT = Path("__VAULT_ROOT__")


def read_file(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def parse_frontmatter(text: str):
    """Return (frontmatter_dict_raw, body_after_fence) or (None, text)."""
    if not text.lstrip().startswith("---"):
        return None, text
    lines = text.split("\n")
    # Find closing ---
    close = None
    for i, line in enumerate(lines[1:], 1):
        if line.strip() == "---":
            close = i
            break
    if close is None:
        return None, text
    fm_lines = lines[1:close]
    body = "\n".join(lines[close + 1:])
    return fm_lines, body


def build_tag_list(fm_lines: list[str], new_area: str | None, new_type: str | None, overwrite: bool) -> list[str]:
    """
    Return updated fm_lines with area/type tags injected or replaced.
    Preserves all other frontmatter keys.
    """
    # Check if tags: block exists
    in_tags = False
    has_tags_key = any(l.strip().startswith("tags:") for l in fm_lines)

    if not has_tags_key:
        # Inject tags block at end
        result = list(fm_lines)
        result.append("tags:")
        if new_area:
            result.append(f'  - "{new_area}"')
        if new_type:
            result.append(f'  - "{new_type}"')
        return result

    # Tags block exists: update it
    result = []
    i = 0
    while i < len(fm_lines):
        line = fm_lines[i]
        if line.strip().startswith("tags:"):
            result.append(line)
            i += 1
            # Collect existing tag lines
            existing_tags = []
            while i < len(fm_lines) and fm_lines[i].startswith("  "):
                existing_tags.append(fm_lines[i])
                i += 1
            # Filter/replace area and type tags
            filtered = []
            for t in existing_tags:
                stripped = t.strip().strip('"').strip("'").lstrip("- ")
                is_area = stripped.startswith("#area/")
                is_type = stripped.startswith("#type/")
                if is_area and overwrite and new_area:
                    continue  # will be replaced
                if is_type and overwrite and new_type:
                    continue
                filtered.append(t)
            # Add new tags
            if new_area and (overwrite or not any("#area/" in t for t in existing_tags)):
                filtered.insert(0, f'  - "{new_area}"')
            if new_type and (overwrite or not any("#type/" in t for t in existing_tags)):
                filtered.insert(1 if new_area else 0, f'  - "{new_type}"')
            result.extend(filtered)
        else:
            result.append(line)
            i += 1
    return result


def apply_tags_to_file(path: Path, area: str | None, type_: str | None, overwrite: bool, dry_run: bool) -> str | None:
    """
    Returns a diff-style description of changes, or None if no change.
    Writes if not dry_run.
    """
    text = read_file(path)
    fm_lines, body = parse_frontmatter(text)

    if fm_lines is None:
        # No frontmatter: create minimal block
        new_fm = ["---"]
        new_fm.append(f"title: {path.stem}")
        new_fm.append("tags:")
        if area:
            new_fm.append(f'  - "{area}"')
        if type_:
            new_fm.append(f'  - "{type_}"')
        new_fm.append("---")
        new_text = "\n".join(new_fm) + "\n" + body
        change = f"  NEW frontmatter with area={area} type={type_}"
    else:
        updated = build_tag_list(fm_lines, area, type_, overwrite)
        new_text = "---\n" + "\n".join(updated) + "\n---" + ("\n" + body if body.strip() else "\n")
        if updated == fm_lines:
            return None  # no change
        change = f"  tags updated: area={area} type={type_}"

    if not dry_run:
        path.write_text(new_text, encoding="utf-8")

    return change


def main():
    ap = argparse.ArgumentParser(description="Apply classify.py manifest tags to vault files.")
    ap.add_argument("--manifest", required=True, help="Path to classify.py --output JSON")
    ap.add_argument("--dry-run", action="store_true", default=True)
    ap.add_argument("--apply", dest="dry_run", action="store_false")
    ap.add_argument("--overwrite", action="store_true", default=False)
    ap.add_argument("--filter", default="", help="Comma-separated basenames to process")
    args = ap.parse_args()

    manifest = json.loads(Path(args.manifest).read_text())
    filter_set = {f.strip() for f in args.filter.split(",") if f.strip()}

    tagged = manifest.get("tagged", [])
    if not tagged:
        print("No tagged files in manifest.")
        return

    mode = "DRY RUN" if args.dry_run else "APPLY"
    print(f"\n=== apply_classify_tags.py: {mode} ===")
    print(f"Manifest: {args.manifest}")
    print(f"Overwrite existing tags: {args.overwrite}")
    print()

    changed = 0
    skipped = 0
    errors = 0

    for entry in tagged:
        basename = entry["file"]
        if filter_set and basename not in filter_set:
            continue

        area = entry.get("area")
        type_ = entry.get("type")
        if not area and not type_:
            skipped += 1
            continue

        path = Path(entry["path"])
        if not path.exists():
            print(f"  MISSING: {basename}")
            errors += 1
            continue

        try:
            result = apply_tags_to_file(path, area, type_, args.overwrite, args.dry_run)
            if result:
                print(f"  {'[DRY]' if args.dry_run else '[WROTE]'} {basename}")
                print(f"    area={area}  type={type_}")
                changed += 1
            else:
                print(f"  [SKIP: no change] {basename}")
                skipped += 1
        except Exception as e:
            print(f"  ERROR {basename}: {e}")
            errors += 1

    print(f"\nSummary: {changed} changed, {skipped} skipped, {errors} errors")
    if args.dry_run and changed:
        print("Run with --apply --overwrite to write changes.")


if __name__ == "__main__":
    main()
