---
title: Claude Code Tool Manifest
created: 2026-06-15
meta_status: active
purpose: >
  Single source of truth for Claude Code tools available in this vault's
  Claude Code environment. Read by skill authors specifying allowed-tools
  and by agents checking tool availability. Corrected via workflow audit
  wf_40616415-215 (2026-06-14).
update_trigger: >
  Claude Code tool schema changes, or an audit workflow discovers discrepancies
  between this manifest and the actual tool list (check system-reminder messages
  for the current deferred-tool list).
---

# Claude Code Tool Manifest

> Last verified: workflow audit wf_40616415-215 (2026-06-14)
> Source of truth for deferred tools: system-reminder injected at session start

---

## Always-Available Tools

Load at session start with full schemas. Call directly without ToolSearch.

| Tool | Primary use | Notes |
|------|-------------|-------|
| Bash | Execute shell commands | Stateless between calls; no interactive input. Docker, systemctl, crontab unavailable in sandbox (G01, G22) |
| Read | Read file by absolute path | Default 2000-line limit; use offset+limit for large files |
| Write | Write/overwrite file | Must Read first if file exists |
| Edit | Exact-string replacement in file | Requires prior Read. Preferred over Write for partial edits |
| Glob | Find files by glob pattern | Returns paths sorted by mtime |
| Grep | Ripgrep content search | Regex supported. Use instead of Bash grep |
| Agent | Spawn a subagent | Types: claude, Explore, general-purpose, Plan |
| Workflow | Launch deterministic multi-agent workflow | Required when user message contains "workflow" keyword |
| Skill | Invoke a named Claude Code skill | Skills at .claude/skills/<name>/SKILL.md |
| ToolSearch | Fetch schemas for deferred tools | Required before calling any deferred tool |
| AskUserQuestion | Ask user a structured question | 1-4 questions, 2-4 options each |
| ScheduleWakeup | Schedule wakeup in /loop dynamic mode | Only valid inside an active /loop |

---

## Deferred Tools (ToolSearch required before calling)

Appear by name in system-reminder messages but schemas are not loaded at start.
Call ToolSearch first: ToolSearch({query: "select:<ToolName>"})

### Task Management

| Tool | Description |
|------|-------------|
| TaskCreate | Create a tracked background task |
| TaskGet | Get status of a task |
| TaskList | List all tasks |
| TaskUpdate | Update task status or notes |
| TaskStop | Stop a running task |
| TaskOutput | Get task output |

### Scheduling

| Tool | Description |
|------|-------------|
| CronCreate | Create a recurring cron-style task |
| CronDelete | Delete a cron task |
| CronList | List active cron tasks |

### Web

| Tool | Description |
|------|-------------|
| WebFetch | Fetch a URL (HTML/text only: no image support) |
| WebSearch | Web search |

### Planning and Isolation

| Tool | Description |
|------|-------------|
| EnterPlanMode | Switch to plan mode |
| ExitPlanMode | Exit plan mode and show plan for approval |
| EnterWorktree | Create isolated git worktree for agent |
| ExitWorktree | Exit worktree (auto-cleaned if no changes) |

### Other

| Tool | Description |
|------|-------------|
| Monitor | Stream events from a background process |
| NotebookEdit | Edit Jupyter notebooks |
| PushNotification | Send notification to user |

---

## allowed-tools Routing Guide (for SKILL.md authors)

| Skill type | Allowed tools |
|------------|---------------|
| Read-only gate (classify, audit) | Bash, Read, Glob, Grep |
| Content creation / edit | add Edit, Write |
| Agent-orchestrating skill | add Agent, Workflow |
| Web-capable skill | add WebFetch, WebSearch (require ToolSearch at runtime) |

Rule: Never add tools to allowed-tools that the skill does not explicitly use.
Over-permissioning defeats the safety gate.

---

## Vault-Specific Constraints

| Constraint | Detail | Gotcha ref |
|------------|--------|------------|
| Docker unavailable in sandbox | Use curl to port-probe services | G01 |
| trash-put unavailable | Use mv file $VAULT/.trash/ | G05 |
| crontab / systemctl unavailable | Run from user terminal | G22 |
| sudo on vault files | Risk NFS root-squash (nfsnobody ownership) | G25 |
| rm on .md/.txt/.csv | BANNED: blocked by rm-guard PreToolUse hook | CLAUDE.md |

---

## Correction Notes (from audit wf_40616415-215)

- trigger: field is NOT a valid SKILL.md frontmatter key. Zero occurrences
  across 27 marketplace SKILLs. Do not add to new skills.
- model: sonnet in skill frontmatter force-pins the model to Sonnet regardless
  of session context. Omit model: to inherit from session (correct default).
- Deferred tools require explicit ToolSearch before calling: calling them
  directly raises InputValidationError.
