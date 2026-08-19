---
name: session-close
description: >
  Use when the user says "close session", "end session", "wrap up", "session done",
  "what do we do before closing", or asks about session-close steps.
  Runs the full session-close sequence: tracking file audit, handoff regeneration,
  unstaged file review, and final commit.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# session-close: Full Session Close Sequence

## What this skill does

1. Runs `session_close.sh`: tracking file audit + handoff regeneration (`--archive`)
2. Reads the output and flags any warnings
3. Reviews all remaining unstaged files: shows each briefly, asks whether to include
4. Asks for the resume point text
5. Creates the session-close commit with the correct format

**Hard rule:** Never skip the commit format. It must be:
`session close: <task being closed>: awaiting <next gate>`
Example: `session close: OD resolution complete: no pending gates`

---

## Step 1: Run session_close.sh

```bash
bash __VAULT_ROOT__/.claudian/scripts/session_close.sh
```

Read the full output. Note:
- Any `WARNING:` warnings about stale tracking files: address before committing if significant
- Any `[!] IMMEDIATE` items still open: surface them to the user
- What tracking files were staged (SESSION_HANDOFF, PHASE_STATE, NEXT_ACTIONS, etc.)
- Whether the project repo (your-stack) has uncommitted changes

---

## Step 2b: Reconcile session transcript against agent_memory

Run the L-1 reconcile loop (IH-3 / OD-16). This diffs the current session's
JSONL transcript against `agent_memory.py` captures and surfaces decisions that
were discussed but never captured.

```bash
python3 __VAULT_ROOT__/.claudian/scripts/reconcile_session.py
```

Read the output:
- **0 miss candidates** -> agent_memory is complete for this session. Proceed.
- **N miss candidates** -> Show the list to the user. For each item, ask whether
  it should be captured via `record_decision()`. Do NOT auto-capture: user must
  confirm each one. After user review, run any approved captures:
  ```bash
  python3 __VAULT_ROOT__/.claudian/scripts/agent_memory.py \
    decide "<text>" "<topic>"
  ```
- If the script errors or exits non-zero for reasons other than miss count,
  report the error verbatim. A missing transcript file is non-fatal: skip this
  step and note it in the commit message.

---

## Step 2: Review remaining unstaged files

After the script runs, check what's still unstaged:

```bash
git -C __VAULT_ROOT__ status --short
```

For each unstaged file that is NOT noise (noise = `.ajson`, `.meta.json`, `workspace.json`, `knowledge.db`):

- Show the file path and a one-line description of what it likely is
- For deleted files: check if they were deleted by the user intentionally in Obsidian (common for 10_active/ files)
- For modified files: show a brief `git diff --stat` for that file
- For untracked directories (like `00_inbox/`): list the new files briefly

Then use AskUserQuestion to let the user decide which to include in this commit.
Group related files into logical choices (e.g. "10_active/ deletions: 7 files" as one option).

---

## Step 3: Stage chosen files

For each file/group the user approved:

```bash
git -C __VAULT_ROOT__ add <file-or-pattern>
```

---

## Step 4: Ask for resume point

Ask the user (via AskUserQuestion or direct question):

> What is the resume point for this session?
> Format: `<task completed>: awaiting <gate or next step>`
> Example: `all 6 OD-N resolved: no pending gates`

---

## Step 5: Create the commit

```bash
git -C __VAULT_ROOT__ commit -m "session close: <resume-point>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

Then confirm the commit hash and report the final state.

---

## Step 6: Project repo check (if needed)

If `session_close.sh` reported uncommitted files in `~/Projects/your-stack/`:

```bash
git -C __STACK_ROOT__ status --short
```

Report to user. Do NOT auto-commit the project repo: changes there are typically infrastructure that the user reviews separately.

---

## Safety rules for this skill

- NEVER commit files matching sensitive patterns: canonical list: `VAULT_OPERATOR_FULL.md §2` (OD-39).
  Core: `*CRM*, *password*, *recovery*, *backup*, *ancestry*, *finance*, *paystub*, *SSN*, *W-2*, *tax*, *Offer_Letter*, *I-9*, *passport*`
- NEVER commit `.env`, `data.json`, or any file in `.obsidian/plugins/copilot/`
- NEVER skip the AskUserQuestion for unstaged files: always get explicit per-group approval
- NEVER create an empty commit (if nothing staged, report "nothing to commit" and stop)
- If `session_close.sh` errors, report the error verbatim: do not paper over it
