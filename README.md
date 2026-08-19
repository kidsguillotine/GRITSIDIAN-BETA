# Claudian Starter Vault

A clean, shareable copy of the Claudian Obsidian-agent system. It gives an AI
helper (Claude) a set of rules, safety guards, skills, and scripts for managing
an Obsidian vault as a "second brain."

This is a **project and a tool**, not a product. There is no roadmap and no
release. It exists so one person can run a vault with an AI helper and not lose
data. It carries no personal content.

## Read the wiki first

The full guide is a wiki. Open `wiki/Home` in Obsidian and follow the links.

- [[wiki/Home]]: the front page.
- [[wiki/Getting Started]]: for people who use Word, Excel, and folders.
- [[wiki/The Rules (Simple English)]]: what the AI may and may not do, in plain English.
- [[wiki/Git Backup]]: why the automatic backup is the core safety net.
- [[wiki/Sensitivity and Security]]: how private files stay out of the backup.
- [[wiki/Windows and Flash Drive]]: install on Windows or run from a USB drive.
- [[wiki/Glossary]]: every technical word in one line.

## Quick start

```
cd claudian-starter
./setup.sh                                # replace machine-specific placeholders
git init && .claudian/hooks/install.sh    # optional: safety hooks
```

Then open the folder as a vault in Obsidian and start a Claudian session.

## The three top-level files people confuse

- **`README.md`** (this file): the map. What the project is and where to go. Read
  it first. It does nothing on its own.
- **`SETUP.md`**: the instructions. A human-readable, step-by-step guide to
  installing and wiring the system. You read it and follow it.
- **`setup.sh`**: the tool. A script you run once. It edits the config files and
  replaces the machine-specific placeholders (like the vault path) for you. You
  execute it; you do not read it.

Short version: `README.md` tells you what this is, `SETUP.md` tells you how to set
it up, and `setup.sh` does one setup step automatically.

## What is inside

- `CLAUDE.md`: the AI's operating rules (the constitution).
- `.claude/skills/`: trigger-fired workflows (session close, daily note, drain, api lookup, chunk-and-categorize).
- `.claudian/scripts/`: the pipeline (handoff generation, link checking, classification, safe moves, dedup, logging).
- `.claudian/hooks/`: git pre-commit guard + installer.
- `99_system/`: the formal specs: `FOLDER_SCHEMA.md`, `DOC_STANDARD.md`, `SYSTEM_DOC_MAP.md`.
- `_handoff/`: session-state templates.
- `wiki/`: this guide.
- `PROJECT_TODO.md`: the running task list.
- Empty vault folders (`00_inbox` .. `80_archive`, `crm`, `_MOCs`).

## Core ideas

- **Safety first.** Content files are never deleted; they go to `.trash/`.
  Private files are routed, never committed. See [[wiki/Sensitivity and Security]].
- **Backup over memory.** Each session writes state to `_handoff/`, and a
  schedule commits and pushes the whole vault. See [[wiki/Git Backup]].
- **Deterministic over per-item.** Bulk changes run as one dry-run-then-apply
  script, not many single steps.
- **Connection surfacing.** The Smart Connections plugin suggests related notes;
  the AI follows links and keeps `_MOCs/` current. See [[wiki/Plugins]].
- **Plain output.** No emojis, no em-dashes.
