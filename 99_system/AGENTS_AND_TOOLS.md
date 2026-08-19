---
title: Agents and Tools
created: 2026-08-19
meta_status: active
purpose: >
  What agents exist, what tools each may use, and the rules a subagent inherits.
  Replaces SUBAGENT_SPECS.md and CLAUDE_TOOL_MANIFEST.md, which described this in
  prose while the real configuration lived in .claude/agents/.
update_trigger: >
  Add a row when you add an agent or a skill. Keep it in step with .claude/agents/
  and .claude/skills/.
authority: >
  Rank 4. The files in .claude/ are ground truth. This is their index and the
  reasoning behind them.
---

# Agents and Tools

## Ground truth lives in .claude

| Thing | Where it really lives |
|---|---|
| Agent definitions | `.claude/agents/<name>.md` (frontmatter sets model and tools) |
| Skills | `.claude/skills/<name>/SKILL.md` |
| Hook wiring | `.claude/settings.json` |
| Entry point for any agent | `AGENTS.md` at the vault root |

If this page and a file in `.claude/` disagree, the file wins.

## Shipped agents

| Agent | Job | Tools | Can it write? |
|---|---|---|---|
| `vault-classifier` | Proposes one destination folder for one note | Read, Grep, Bash | NO. It proposes only. |

The classifier proposes and never moves. That separation is deliberate: the agent
that decides is not the agent that acts, so a bad decision cannot execute itself.

## Shipped skills

| Skill | Trigger | Job |
|---|---|---|
| `session-close` | "close session", "wrap up" | Audit, regenerate the handoff, review unstaged files, commit |
| `daily-note` | "/daily-note" | Open or create today's note, append to the right section |
| `drain` | "/drain" | Route captures from the daily note to a review queue |
| `api-lookup` | "is there an API for X" | Search the local API catalog before any web search |
| `chunk-and-categorize` | A noisy multi-topic document | Split, classify each chunk, mark for review, never auto-merge |

## Choosing tools for a new agent

Give the fewest tools that let the agent finish. The reasoning:

- Read and Grep only: the agent can analyze and report. It cannot damage anything.
  Use this for anything that classifies, audits, or proposes.
- Add Bash: the agent can now run scripts. It can also delete. The rm-guard hook
  covers the common case, not every case.
- Add Edit or Write: the agent changes content. Only for agents whose whole job is
  writing, and only with the confirmation gate in force.

An agent that proposes needs no write tools. Most agents propose.

## Rules a subagent inherits

Every rule in `CLAUDE.md` applies to every subagent with no weakening. In
particular:

- The batch rule: more than five items means one dry-run script, then one apply.
  Never per-item calls.
- The confirmation gate: a subagent may not commit a decision to memory or to a
  file that implies policy.
- The writing rules: ASD-STE100, no emojis, no em dashes.
- The trash rule: never `rm` a content file.

If a subagent prompt contradicts these, say so before launching it rather than
papering over the conflict.

## Subagents and context

A subagent runs in its own context window. The parent sees only what it returns.
That makes a subagent the right tool for a job that needs many file reads and
produces a short answer, for example scanning a folder to surface candidate tags.

The failure mode to guard: a returned summary is not verified. Read the body
before you report its numbers as fact. See gotcha G22 item 1.
