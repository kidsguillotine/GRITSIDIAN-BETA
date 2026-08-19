#!/usr/bin/env python3
"""
generate_tag_schema.py: Generate _handoff/TAG_SCHEMA.md from vocab.yaml.

GENERATED FILE: do not hand-edit TAG_SCHEMA.md. Edit vocab.yaml instead.

Usage:
  python3 generate_tag_schema.py
  python3 generate_tag_schema.py --vault /path/to/vault
"""

import sys
from datetime import date
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("ERROR: PyYAML required. Run: pip install pyyaml")

VAULT = Path(__file__).resolve().parent.parent.parent
if "--vault" in sys.argv:
    idx = sys.argv.index("--vault")
    VAULT = Path(sys.argv[idx + 1]).resolve()

VOCAB_PATH = VAULT / ".claudian" / "config" / "vocab.yaml"
OUTPUT_PATH = VAULT / "_handoff" / "TAG_SCHEMA.md"

if not VOCAB_PATH.exists():
    sys.exit(f"ERROR: vocab.yaml not found at {VOCAB_PATH}")

with VOCAB_PATH.open(encoding="utf-8") as f:
    data = yaml.safe_load(f)

voc = data.get("vocabulary", {})
areas = data.get("areas", {})
wip = voc.get("wip_limits", {})
aliases = data.get("tag_aliases", {})
candidates = data.get("candidates", {})

today = date.today().isoformat()

lines = [
    "---",
    "title: Tag Schema",
    f"generated: {today}",
    "meta_status: generated",
    "generation_note: \"DO NOT EDIT. Generated from .claudian/config/vocab.yaml by generate_tag_schema.py. Edit vocab.yaml instead.\"",
    "---",
    "",
    "# Tag Schema",
    "",
    f"> Generated {today} from `.claudian/config/vocab.yaml`. Do not hand-edit this file.",
    "",
    "---",
    "",
    "## `#area/*`: Domain Assignment (closed)",
    "",
    "| Tag | Primary Anchors |",
    "|---|---|",
]

for name in voc.get("area", []):
    spec = areas.get(name, {})
    anchors = spec.get("anchors") or []
    sample = ", ".join(anchors[:6])
    if len(anchors) > 6:
        sample += f", ... (+{len(anchors) - 6})"
    lines.append(f"| `#area/{name}` | {sample} |")

lines += [
    "",
    "---",
    "",
    "## `#type/*`: Note Kind (closed)",
    "",
    "| Tag | Use for |",
    "|---|---|",
]

type_descriptions = {
    "task": "Things to do. Has a checkbox or action item.",
    "reflection": "Journal, feelings, processing, thinking-through.",
    "project": "Multi-step effort with a goal and timeline.",
    "routine": "Recurring process (weekly review, morning routine, etc.)",
    "log": "Record of something that happened (daily log, workout log).",
    "reference": "Something you look up, not process. Recipes, specs, cheat sheets.",
    "scrap": "Fragment. Quick capture. Needs processing before routing.",
}

for t in voc.get("type", []):
    desc = type_descriptions.get(t, "")
    lines.append(f"| `#type/{t}` | {desc} |")

lines += [
    "",
    "---",
    "",
    "## `#status/*`: Lifecycle State (closed)",
    "",
    "| Tag | Meaning |",
    "|---|---|",
]

status_descriptions = {
    "now": f"Active right now. **Hard WIP limit: max {wip.get('now', 3)}.**",
    "next": "Ready to start; waiting for your attention.",
    "waiting": "Blocked on something external.",
    "today": "Do today specifically.",
    "daily": "Recurring daily.",
    "weekly": "Recurring weekly.",
    "monthly": "Recurring monthly.",
    "quarterly": "Recurring quarterly.",
    "yearly": "Recurring yearly.",
    "someday": "Maybe, eventually. No commitment.",
    "reference": "Not actionable. Lookup item.",
    "unsorted": "Newly injected. Pending classification.",
    "archived": "Done or superseded. Not deleted.",
}

for s in voc.get("status", []):
    desc = status_descriptions.get(s, "")
    lines.append(f"| `#status/{s}` | {desc} |")

lines += [
    "",
    "---",
    "",
    "## `#priority/*`: Urgency (closed)",
    "",
    "| Tag | Use for |",
    "|---|---|",
    "| `#priority/urgent` | Blocks everything else. |",
    "| `#priority/high` | Important, do soon. |",
    "| `#priority/medium` | Default level. |",
    "| `#priority/low` | Nice to have. |",
    "",
    "---",
    "",
]

topics = data.get("topics", {})
if topics:
    lines += [
        "",
        "---",
        "",
        "## `#topic/*`: Content Topics (extensible)",
        "",
        "Human-approved via SA-1 vocabulary gate. New topics require cluster discovery approval.",
        "",
        "| Tag | Description |",
        "|---|---|",
    ]
    for slug, info in topics.items():
        desc = info.get("description", "") if isinstance(info, dict) else str(info)
        lines.append(f"| `#topic/{slug}` | {desc} |")
    lines += [
        "",
        "Add new topics: edit `vocab.yaml` -> `topics:` -> re-run `generate_tag_schema.py`.",
        "",
        "---",
        "",
    ]
else:
    lines += [
        "",
        "---",
        "",
        "## `#topic/*`: Open Namespace",
        "",
        "Free-form. Never validated. Use for content-specific topics: `#topic/stoicism`, `#topic/obsidian`, etc.",
        "",
        "---",
        "",
    ]

if aliases:
    lines += [
        "## Tag Aliases",
        "",
        "| Alias | Canonical |",
        "|---|---|",
    ]
    for alias, canonical in aliases.items():
        lines.append(f"| `{alias}` | `{canonical}` |")
    lines += ["", "---", ""]

if candidates:
    lines += [
        "## Candidates (pending promotion)",
        "",
        f"Promotion threshold: {data.get('candidate_promotion_threshold', 5)} uses. Expiry: {data.get('candidate_expiry_days', 90)} days.",
        "",
        "| Tag | Count |",
        "|---|---|",
    ]
    for tag, info in candidates.items():
        count = info.get("count", 0) if isinstance(info, dict) else info
        lines.append(f"| `{tag}` | {count} |")
    lines += ["", "---", ""]

lines += [
    "## Straggler / Legacy Tags",
    "",
    "Bare tags (pre-namespace) still accepted by `validate_frontmatter.py` for backward compatibility.",
    "Do not use in new notes. Migrate to namespaced form on next touch.",
    "",
    "```",
    "daily  finance  hardware  tech-setup  music  car  comp  maintenance",
    "errand  project  yearly  what  why  high_priority_to-do  routine",
    "urgent  waiting  health  digital  today  now",
    "```",
    "",
]

output = "\n".join(lines)
OUTPUT_PATH.write_text(output, encoding="utf-8")
print(f"Generated: {OUTPUT_PATH}")
print(f"  Areas: {len(voc.get('area', []))}")
print(f"  Types: {len(voc.get('type', []))}")
print(f"  Statuses: {len(voc.get('status', []))}")
print(f"  Priorities: {len(voc.get('priority', []))}")
print(f"  Topics: {len(topics)}")
