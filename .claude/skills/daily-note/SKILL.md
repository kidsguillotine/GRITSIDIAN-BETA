# /daily-note

Open or create today's daily note. Optionally append a quick capture.

## Usage

```
/daily-note
/daily-note task: buy milk
/daily-note buy milk
/daily-note idea: look into X
```

- No args -> create today's note if missing, show the wikilink.
- With args -> create if missing, then append to the right section.
  - Starts with `task:` -> appends `- [ ] <text>` to ## Tasks
  - Anything else -> appends `- <text>` to ## Quick scraps

## Steps

1. Get today's date:
   ```bash
   date +%Y-%m-%d
   ```

2. Set `NOTE_PATH=20_personal/daily/<date>.md` (relative vault path).

3. If the file does not exist, create it from this template (substitute real date):

```markdown
---
date: <date>
created: <date>T<HH:MM>
tags:
  - "#type/log"
  - "#status/daily"
  - "#area/general"
meta_status: active
---

# <date>

> Free-form top. Whatever: ideas, reflection, what happened, half-finished
> sentences, fragments. Don't classify. Capture is the job.



---

## Tasks

- [ ] 

---

## Quick scraps

> One-line dumps. Errands, contacts, places, links, story seeds, buy-list items.
> Atomic and scannable: Claudian can route these in a batch later.

-
```

4. If args were provided:
   - Strip leading `task: ` or `idea: ` prefix label if present (keep the rest as the text).
   - If prefix was `task:` -> find the `## Tasks` section and append `- [ ] <text>` before the next `---` or end of section.
   - Otherwise -> find the `## Quick scraps` section and append `- <text>` after the last `-` line in that section.

5. Respond with:
   - The wikilink: `[[20_personal/daily/<date>]]`
   - If a capture was appended: one line confirming what was added and where.
   - Nothing else. No preamble.

## Rules

- NEVER overwrite an existing daily note: only append to it.
- NEVER modify any section other than Tasks or Quick scraps when appending.
- Use the vault root as the working directory for all file paths.
- If the date cannot be determined, ask once before proceeding.
