#!/usr/bin/env python3
"""api_catalog_build.py: deterministic public-apis catalog -> vault reference note.

Parses the public-apis/public-apis README (categorized markdown tables with
Auth/HTTPS/CORS fields) into 99_system/API_CATALOG.md. No LLM calls; same
input -> same output. TOKEN_DISCIPLINE: one script, not per-item calls.

Usage:
    python3 api_catalog_build.py              # dry-run: category/API counts only
    python3 api_catalog_build.py --apply      # write/refresh the vault note
    python3 api_catalog_build.py --src FILE   # parse a local README copy (offline)

Regeneration: content between BEGIN_GENERATED/END_GENERATED markers is
replaced; any hand-written preamble above BEGIN_GENERATED is preserved
(same contract as rebuild_mocs.py). Exit 0 ok, 1 parse produced no rows.
"""
import argparse
import os
import re
import sys
import urllib.request
from datetime import datetime, timezone

VAULT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
NOTE_PATH = os.path.join(VAULT_ROOT, "99_system", "API_CATALOG.md")
SRC_URL = "https://raw.githubusercontent.com/public-apis/public-apis/master/README.md"
BEGIN = "<!-- BEGIN_GENERATED: api-catalog -->"
END = "<!-- END_GENERATED: api-catalog -->"

ROW_RE = re.compile(
    r"^\|\s*\[([^\]]+)\]\(([^)]+)\)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*$"
)

DEFAULT_PREAMBLE = """---
title: API Catalog: free/public APIs reference
created: {date}
meta_status: active
purpose: >
  Local, greppable reference of free/public APIs (name, description, auth,
  HTTPS, CORS) generated deterministically from public-apis/public-apis.
  Consulted by the /api-lookup skill before any web search.
update_trigger: >
  Re-run `python3 .claudian/scripts/api_catalog_build.py --apply` when the
  catalog feels stale. Generated block only; this preamble is hand-editable
  and preserved across regenerations.
---

# API Catalog

Source: `public-apis/public-apis` (MIT, community-maintained). Regenerate via
`api_catalog_build.py --apply`. Auth values: `No` = keyless, `apiKey` = free
key required, `OAuth` = full auth flow.

## api.data.gov quick facts (verified 2026-07-23)

One free key covers 25 US federal agencies, 450+ APIs (NASA, EPA, FDA, NIH,
NPS, USGS, LoC). Key via `X-Api-Key` header (or `api_key` query param).
Default 1,000 req/hr; HTTP 429 on exceed, rolling hourly reset; usage in
`X-RateLimit-Limit` / `X-RateLimit-Remaining` response headers.
CAUTION: keys are 40-char alphanumeric: matched by NO pattern in the
canonical secret-scan set (SYSTEM_CONSTANTS.md). Store only in
`__STACK_ROOT__/.env`; the hook will NOT catch a leak.

"""


def fetch(src):
    if src:
        with open(src, encoding="utf-8") as fh:
            return fh.read()
    with urllib.request.urlopen(SRC_URL, timeout=30) as resp:
        return resp.read().decode("utf-8")


def parse(text):
    """Return list of (category, [(name, link, desc, auth, https, cors), ...])."""
    cats, current, rows = [], None, []
    for line in text.splitlines():
        h = re.match(r"^###\s+(.+?)\s*$", line)
        if h:
            if current and rows:
                cats.append((current, rows))
            current, rows = h.group(1), []
            continue
        m = ROW_RE.match(line)
        if m and current and m.group(1).lower() != "api":
            rows.append(tuple(s.strip() for s in m.groups()))
    if current and rows:
        cats.append((current, rows))
    return cats


def render(cats):
    ts = datetime.now(timezone.utc).isoformat()
    total = sum(len(r) for _, r in cats)
    out = [BEGIN, f"<!-- generated {ts}: {len(cats)} categories, {total} APIs -->", ""]
    for cat, rows in cats:
        out.append(f"### {cat}")
        out.append("")
        out.append("| API | Description | Auth | HTTPS | CORS |")
        out.append("|---|---|---|---|---|")
        for name, link, desc, auth, https, cors in rows:
            desc = desc.replace("|", "/")
            out.append(f"| [{name}]({link}) | {desc} | {auth} | {https} | {cors} |")
        out.append("")
    out.append(END)
    return "\n".join(out) + "\n", len(cats), total


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="write the vault note")
    ap.add_argument("--src", help="local README file instead of network fetch")
    args = ap.parse_args()

    cats = parse(fetch(args.src))
    if not cats:
        sys.stderr.write("parse produced no rows: README format changed?\n")
        sys.exit(1)
    body, ncat, napi = render(cats)

    if not args.apply:
        print(f"DRY-RUN: {ncat} categories, {napi} APIs. --apply to write {NOTE_PATH}")
        for cat, rows in cats[:5]:
            print(f"  {cat}: {len(rows)}")
        print("  ...")
        sys.exit(0)

    if os.path.exists(NOTE_PATH):
        with open(NOTE_PATH, encoding="utf-8") as fh:
            existing = fh.read()
        idx = existing.find(BEGIN)
        preamble = existing[:idx] if idx != -1 else existing.rstrip() + "\n\n"
    else:
        preamble = DEFAULT_PREAMBLE.format(date=datetime.now(timezone.utc).date().isoformat())

    with open(NOTE_PATH, "w", encoding="utf-8") as fh:
        fh.write(preamble + body)
    print(f"WROTE {NOTE_PATH}: {ncat} categories, {napi} APIs")


if __name__ == "__main__":
    main()
