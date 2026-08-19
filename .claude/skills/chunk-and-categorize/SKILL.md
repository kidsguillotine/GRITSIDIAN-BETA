---
name: chunk-and-categorize
description: >
  Use when processing a noisy multi-topic document: notebook pages,
  brain dumps, unsorted raw text: that contains content belonging to
  multiple categories. Splits the document into separator-marked chunks,
  classifies each chunk to a target domain note, and appends each with a
  MANUAL_REVIEW marker so the user scans and confirms before content is
  treated as permanent. Never auto-merges content without the review marker.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Edit
  - Write
---

# chunk-and-categorize: Messy Document Intake

## When to use this skill

A document qualifies for chunk-and-categorize when:
- It contains 2+ distinct topics with no clear domain boundary
- It is a transcription, brain dump, or notebook scan
- Running it through classify.py would produce a single noisy classification

Documents with one coherent topic -> use the classify skill instead.

## Step 0: Consult STANDING GOTCHAS

Before executing, scan the `## STANDING GOTCHAS` section of
`_handoff/SESSION_BOOT.md` (loaded at session boot). For any G-numbered entry
that describes the imminent operation class (bulk classify, MANUAL_REVIEW
workflow, tag write, append to domain notes), expand the full entry:

    grep -A 6 '^### G<num>: ' _handoff/GOTCHAS.md

Halt and surface to the user if a hazard entry describes the imminent
operation without a documented workaround.

Rationale: standing hazards are structurally invisible to BOOT_DELTA.
This step closes the boot-visibility-only failure mode.
(D-B-skills, 2026-07-06)

## Step 1: Read the source document in full

Use the three-section read protocol (CLAUDE.md § File reading protocol):
- HEAD 60 lines
- MID 30 lines (centred on file midpoint)
- TAIL 60 lines

Identify how many distinct topics the document contains and where topic
boundaries fall. Note total line count.

## Step 2: Insert separator comments at topic boundaries

Mark chunk boundaries in your working copy:

```markdown
<!-- CHUNK 1: <one-line topic summary> -->
[content for chunk 1]

<!-- CHUNK 2: <one-line topic summary> -->
[content for chunk 2]
```

Rules:
- Each chunk MUST include a one-line topic summary in its separator comment.
- Minimum chunk size: 3 meaningful lines.
- Single-line fragments belong in the nearest relevant chunk, not standalone.

## Step 3: Classify and route each chunk

For each chunk:
1. Identify the target domain using TAG_SCHEMA.md and classify.py output
   from Step 1 (which gives the overall document domain as context).
2. Identify the target note: an existing note to append to, or a new note
   to create in the correct domain folder.
3. Verify the target folder exists (see confirmed folders list in
   99_system/VO_TOOL_MANIFEST.md §write_vault).

## Step 4: Append chunks with review markers

Append each chunk to its target note with this exact structure:

```markdown
<!-- MANUAL_REVIEW: from <source_filename>, chunk N: confirm and remove this marker -->
[chunk content]
```

**Never remove the MANUAL_REVIEW marker yourself.** The user removes it
after reviewing and confirming the content belongs in the target note.

## Step 5: Log and move source

After all chunks are confirmed written:

1. Append to _handoff/MIGRATION_LOG.txt:
   ```
   chunk-and-categorize: <source_file> -> N chunks -> [target1, target2, ...] (YYYY-MM-DD)
   ```

2. Move source to .trash/:
   ```bash
   mv <source_file> __VAULT_ROOT__/.trash/<basename>_<YYYYMMDD>.md
   ```

Do NOT move the source until all chunk writes are verified.

## Safety gates

- Never remove MANUAL_REVIEW markers: those are for the user to clear.
- Never auto-merge chunks without the review marker present.
- Sensitive content (CRM, finance, passwords, recovery, credentials, paystub, SSN, tax, W-2, I-9, etc.) ->
  route to __SENSITIVE_STORE__/<category>/ and log. Never append to vault notes.
  Canonical pattern list: VAULT_OPERATOR_FULL.md §2 "Sensitive File Routing" (OD-39 resolved 2026-06-26).
- Low-confidence chunk (domain unclear) -> route to 60_manual_review/ with
  a note explaining the ambiguity. Do not force-classify.
- Confirm source file exists and is fully readable before starting.

## Reference

- classify.py: .claudian/scripts/classify.py
- Tag vocabulary: _handoff/TAG_SCHEMA.md
- Safety policy: _handoff/SAFETY_POLICY.md
- Migration log: _handoff/MIGRATION_LOG.txt
- Confirmed vault folders: 99_system/VO_TOOL_MANIFEST.md §write_vault
