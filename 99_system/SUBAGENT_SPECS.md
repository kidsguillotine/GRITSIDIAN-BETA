---
title: Subagent Specs
created: 2026-06-06
meta_status: active
purpose: >
  Defines subagent contracts for tasks that benefit from context isolation.
  Each spec gives: trigger condition, input, output schema, tool access,
  and how the orchestrator uses the result.
update_trigger: New subagent spec added or existing spec revised
---

# Subagent Specs

Subagents run in isolated context windows. The orchestrator (Claudian main session)
receives only the structured output: the full read pass stays out of context.

---

## SA-1: Cluster Discovery (Vocabulary Candidate Surfacing)

**Purpose:** Surface candidate tag clusters from vault content without polluting
the main session context with ~950 file reads.

**Trigger:** Before any vocabulary consolidation pass, tag audit, or TAG_SCHEMA.md
update. Also trigger when `unique_tags` in SESSION_HANDOFF exceeds 1000.

**Input:**
```
vault_root: __VAULT_ROOT__
folders: [50_notes, 60_creative, 20_personal, 30_career, 40_technical]
min_cluster_size: 3
```

**Task prompt (pass to subagent):**
> "Read all .md files in the specified folders. Identify groups of notes
> that share a clear conceptual theme but do NOT yet have a shared tag in
> their frontmatter. Output only a YAML block of candidate clusters: no
> file moves, no edits, no side effects.
> Format:
>   candidates:
>     - theme: <label>
>       example_files: [<path>, <path>, ...]
>       suggested_tag: '#area/<slug>'
>       confidence: high|medium|low"

**Output schema:**
```yaml
candidates:
  - theme: string
    example_files: [string, ...]
    suggested_tag: string    # must start with #area/ or #type/
    confidence: high|medium|low
```

**Tool access:** Read, Glob, Grep: NO Edit, Write, Bash, or MCP tools.
No side effects. Output only.

**Orchestrator use:**
1. Filter to `confidence: high` candidates
2. Cross-reference against `_handoff/TAG_SCHEMA.md`: discard any that already exist
3. Present new candidates to user for vocabulary approval gate
4. Approved candidates -> add to TAG_SCHEMA.md
5. Write VO task to apply new tags to the cluster files

---

## SA-2: Pre-sweep Index (future)

**Purpose:** Before any bulk structural operation (folder move, dedup pass),
generate a complete index of affected files with key metadata, without
committing to any action.

**Status:** Spec placeholder: define when first bulk sweep is needed.

---
*Last updated: 2026-06-06*
