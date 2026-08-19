---
title: Skill Specs
created: 2026-08-19
meta_status: active
purpose: >
  Design specs for skills. A spec explains why a skill works the way it does. It
  is documentation, not an executable skill.
update_trigger: Add a spec when a skill grows complex enough to need one.
---

# Skill Specs

## The folder-consistency problem (read before adding anything here)

There are two places a "skill" can live, and only one of them runs.

| Location | Loaded by the agent? | Holds |
|---|---|---|
| `.claude/skills/<name>/SKILL.md` | YES | The real, executable skill. |
| `99_system/skill-specs/<name>/SKILL.md` | NO | A design spec about a skill. |

A file in this folder is never executed. It is reference material only.

### The naming trap

In the source vault this split had drifted into THREE locations: `.claude/skills`
(executable), `99_system/skill-specs` (specs), and `99_system/skills` (prose
documents with no frontmatter, so nothing loaded them). Two folders whose names
differ only by the word "specs" is a trap: nobody can tell which one runs.

### Decision needed for this starter

Pick one and apply it. Do not leave both.

Option A (recommended). One executable location, one spec location.
- Everything runnable moves to `.claude/skills/`, with `name` and `description`
  in the frontmatter so the agent can load it.
- Everything explanatory stays here, and every file here is named `*_SPEC.md`
  so it can never be mistaken for a runnable skill.

Option B. Specs live next to their skill, inside
`.claude/skills/<name>/SPEC.md`, and this folder is deleted. Fewer folders, but
it mixes reference text into the executable path.

Tracked in `PROJECT_TODO.md`. Until it is decided, treat `.claude/skills/` as the
only thing that runs.
