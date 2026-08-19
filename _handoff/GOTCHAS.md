---
title: Gotchas and Lessons Learned
created: 2026-08-19
meta_status: permanent
purpose: >
  Append-only log of failures and the fix that worked. Read this before you
  assume a standard tool behaves normally. Entries G01 to G24 are inherited: they
  are the failures that already happened in the source vault, generalized so they
  cannot happen to you the same way.
update_trigger: >
  Append a numbered entry at the bottom when something fails in a surprising way.
authority: >
  Permanent. Entries are never deleted. Wording may be tightened.
---

# Gotchas and Lessons Learned

> Append-only. Never delete an entry. Add each new one at the BOTTOM.
> Header shape `### GN: title (date)` is a format contract. The boot script
> counts these headers.

Each entry ends with a Defense line. The Defense says what in this starter stops
the failure, and whether that defense is mechanical (a script or hook blocks it)
or documentary (a rule tells you not to do it). A mechanical defense holds when
nobody is paying attention. A documentary one does not.

These are real failures. One of them destroyed 98 percent of the navigation in a
2000-link vault. One of them cost about 1000 dollars in surprise API billing. One
of them moved 661 files to invented folders. They are written here so you inherit
the scar and not the wound.

## Group 1: data loss

### G01: delete is not reversible, and the trash tools may not exist (2026-08-19)
Symptom: `rm` was used on 53 content files during a cleanup sweep. No trash, no
git history, no recovery. A 1104-row CSV was lost permanently.
Cause: `rm` is immediate. Several trash helpers (`trash-put`, `gio trash`) are
missing or fail depending on the shell and desktop session, so a script that
falls back to `rm` when the trash tool is absent destroys data silently.
Fix: never call `rm` on a content file. Move it into the vault `.trash/` folder,
which Obsidian understands and which git history also covers.
Defense: MECHANICAL. `rm-guard.sh` runs before every Bash command and blocks `rm`
on `.md`, `.txt`, and `.csv`. Plus the nine rules in `_handoff/SAFETY_POLICY.md`,
plus the CLAUDE.md hard prohibition. Gap to know about: the guard cannot see
`rm -rf <directory>` or `find -delete`.

### G02: a cached index is a memory-sourced claim (2026-08-19)
Symptom: a verification run compared 196,738 files against a library index and
declared almost all of them unique, with zero errors reported. The library it
compared against had been reorganized and no longer existed at that path.
Cause: the script loaded a cached path-to-hash index. Lookups against the moved
files raised a file-not-found error, and the loop swallowed it with
`except OSError: continue`. Every skipped comparison became a false "this file is
unique" verdict. The log looked perfect because nothing errored.
Fix: before a run that gates deletion, assert the reference roots still exist and
fail loudly. Never let an exception handler around a reference lookup turn into a
silent skip.
Defense: DOCUMENTARY. The safety policy requires a git commit before any sweep,
so the damage is recoverable. Treat `except: continue` around a lookup as a
false-negative generator.

### G03: an agent can invent folders from tag names (2026-08-19)
Symptom: an agent reclassified about 700 files into paths like
`20_personal/#area/health/`, and invented new top-level folders. 661 tracked
files were removed from their real locations and 25 were rewritten. Recovery
needed a full `git checkout`.
Cause: two failures compounded. The tag `#area/health` is a governed tag, not a
folder, and the agent used it as a path. The move script then created any parent
directory it was told to create, so there was no last line of defense.
Fix: the move script now validates the destination before it touches anything.
Defense: MECHANICAL and verified. `link_safe_move.py` rejects any destination
containing `#`, and rejects any top-level folder not in `VALID_TOP_LEVEL`. Both
tested: `20_personal/#area/health/note.md` and `20_health/note.md` are blocked,
`crm/jane-smith.md` is allowed. If you add a top-level folder you MUST add it to
that list and to `99_system/FOLDER_SCHEMA.md` in the same commit, or legitimate
moves start failing.

## Group 2: silent breakage

### G04: a wikilink with a .md extension breaks navigation (2026-08-19)
Symptom: a vault had 2,076 wikilinks and only 26 of them worked. Every map of
content was gutted. The damage accumulated quietly across many sessions.
Cause: an agent system prompt told every agent to write `[[folder/note.md]]`. The
link resolver looks up the target as a basename, and `note.md` is not a basename,
so resolution failed silently. Worse, agents that read an existing `[[X.md]]` and
re-applied the rule produced `[[X.md.md]]` and longer chains.
Fix: wikilinks never carry the `.md` extension. Write `[[note]]` or
`[[folder/note]]`. Image embeds keep their extension, because they are media.
Defense: MECHANICAL, four layers. The CLAUDE.md hard prohibition
(R-WIKILINK-NOEXT); the pre-commit hook that blocks `[[X.md]]` in staged prose;
`check_links.py --count-broken` and `--fix`; and the broken-link count printed in
the session digest. Do not run a mass strip of `.md` across drifted links: that
turns an obviously broken link into a clean-looking dead one, which is harder to
find.

### G05: a hand edit to a generated file is erased (2026-08-19)
Symptom: edits to a generated knowledge file kept reverting. A model roster
addition and a version bump were wiped at session close.
Cause: the file is written whole by a script on every run. The real content lives
in the script, not in the file. Editing the output is editing a cache.
Fix: change the source, not the generated file.
Defense: DOCUMENTARY, but structural. Every generated file in this starter
declares `meta_status: generated` and says "do not hand-edit" in its purpose
field. `99_system/VAULT_ARCHITECTURE.md` splits every file into GENERATED or
HUMAN and states the rule that nothing is both.

### G06: a format change makes entries invisible to the parser (2026-08-19)
Symptom: the session digest showed only old migration-log entries. Recent
milestones never appeared.
Cause: the parser matched one delimiter and later entries used a different one.
Both formats looked fine to a human. Only the matching ones were counted.
Fix: a parsed file has a format contract. Change the file and the parser in the
same commit.
Defense: DOCUMENTARY plus consistency. Section 4 of
`99_system/DOC_STANDARD.md` lists every format contract, and this starter uses
one plain delimiter everywhere: a colon. Section 8 of
`99_system/DOC_STANDARD.md` lists which script parses which file.

### G07: count the status field, not the heading (2026-08-19)
Symptom: two handoff files disagreed on how many imports were pending. One said
four, the other said zero. A session could waste time re-reviewing resolved work.
Cause: one counter matched heading lines. Resolved entries stay in the block for
the audit trail, so their headings were still counted.
Fix: count the status field, which changes when the item resolves.
Defense: MECHANICAL. Both parsers check for a `Status:` line, not a heading.

### G08: `grep -c` counts lines, not files (2026-08-19)
Symptom: a tag was reported as appearing 1,132 times. It was in 24 files.
Cause: `grep -c` prints matching lines per file. Summing that gives occurrences,
not files.
Fix: use `grep -l <pattern> | wc -l` to count files.
Defense: DOCUMENTARY. A CLAUDE.md process rule. Any count that gates a decision
must state whether it counts files, lines, or occurrences.

### G09: in a basic regular expression, `\|` means "or" (2026-08-19)
Symptom: a count of table rows returned 151 instead of 3, matching every line.
Cause: GNU grep in basic mode treats `\|` as alternation. The pattern `^\|.*X`
parses as "start of line" OR ".*X", and the first branch matches everything.
Fix: use `grep -E`, where `\|` is a literal pipe.
Defense: DOCUMENTARY. The shipped scripts use `-E` for table-row patterns. Test
any new counter against a known number before you trust it.

### G10: awk state leaks across files in one diff (2026-08-19)
Symptom: the wikilink lint passed when it should have blocked. A file whose
fenced code block was left open caused the next file's real violations to be
treated as code and skipped.
Cause: a variable set in `BEGIN` lives for the whole awk process, which spans
every file in a multi-file diff.
Fix: reset state at each file boundary, which a diff marks with `---` and `+++`.
Defense: MECHANICAL. Present in the shipped pre-commit hook. Any streaming
multi-file parser must reset its state at file boundaries.

## Group 3: secrets and money

### G11: plugin settings files hold plaintext API keys (2026-08-19)
Symptom: an Obsidian plugin's own settings file contained an Anthropic API key in
plaintext. Anyone with file access could read it.
Cause: many plugins store provider keys unencrypted in their `data.json`.
Fix: keep plugin data out of git, and rotate any key that was ever committed.
Defense: MECHANICAL and verified. `.gitignore` excludes `.obsidian/plugins/`
entirely. Confirmed with `git check-ignore` that
`.obsidian/plugins/copilot/data.json` is ignored. The pre-commit secret scan is
the second layer.

### G12: an API key in a plugin setting can silently override your subscription (2026-08-19)
Symptom: about 1000 dollars of pay-as-you-go API billing over one project cycle,
while the user believed they were on a flat-rate subscription.
Cause: a plugin setting held `ANTHROPIC_API_KEY=...`. The plugin injects its
environment variables into the command-line tool it launches. That tool prefers
an explicit API key over an existing subscription login, so the key won every
session. The variable was not in any shell profile, so ordinary searches for it
found nothing.
Fix: keep API keys out of a plugin's environment-variable field when you are on a
subscription. Clear the field, fully quit the application, and relaunch.
Defense: MECHANICAL for the leak, DOCUMENTARY for the billing.
`.claudian/claudian-settings.json` is gitignored. To check your own exposure:
inspect the plugin's environment-variable setting, and confirm your session shows
subscription auth rather than an API key. Verify the injection point before
blaming a plausible cause: trace the real process environment.

### G13: credentials hide in casually named files (2026-08-19)
Symptom: a file with a vague, misspelled name held several account passwords in
plaintext. Filename-based scanning skipped it entirely.
Cause: notes imported from phone apps and sticky notes often contain credential
fragments. A casual filename is a common way sensitive content hides in plain
sight.
Fix: read short text files during triage even when the name looks harmless. Look
for an email next to a password-shaped string on the following line.
Defense: PARTIAL and worth knowing. The pre-commit hook scans staged content for
key-shaped tokens, and blocks sensitive filenames. It cannot recognize
"myemail@example.com" followed by "hunter2" as a credential pair. Human triage is
still the real defense here.

## Group 4: agent behavior

### G14: a rule buried as style guidance does not fire (2026-08-19)
Symptom: in a fresh chat with no prior context loaded, an agent ignored the
wikilink rule completely and wrote bare paths. The rule that was being tested
never even got a chance, because a more basic rule failed first.
Cause: the rule sat in a "formatting suggestions" subsection. The model treated
it as a preference and fell back to a strong training habit. The rule only worked
when a large context file happened to be loaded first.
Fix: promote the rule to a numbered core principle, at the same weight as the
hard prohibitions. Add contrastive examples that show the wrong and right form.
Defense: STRUCTURAL. Rules in this starter live in the CLAUDE.md hard
prohibitions with stable IDs, and the non-negotiable subset is repeated in
`AGENTS.md` so a fresh agent sees it without loading anything else. Lesson that
generalizes: if a rule only fires when a big file is preloaded, the rule is not
installed. It is a coincidence.

### G15: "patch applied" is not "patch effective" (2026-08-19)
Symptom: a fix was written correctly to disk, validated clean, and was treated as
done. The behavior did not change. This happened five separate times: a plugin
that was never reloaded, a rule that never fired, memory writes never read back,
and archived files still referenced by stale paths.
Cause: nothing holds the binding between where state lives and what depends on
it. Disk state, running state, actual behavior, and cross-references are four
independent things.
Fix: when you patch one layer, list the layers downstream and check each one.
Fix: the four checks that catch this are a fresh session test, a read-back of
what you wrote, a search for orphan references, and a restart of the thing you
patched.
Defense: DOCUMENTARY. No automation covers this yet. It is the reason the
verification steps in `PROJECT_TODO.md` exist and the reason a claim from memory
is tagged unverified until checked against current state.

### G16: "command not found" is not "the thing does not exist" (2026-08-19)
Symptom: an audit reported that no scheduled backup job existed. The job had been
running every hour the whole time.
Cause: the command used to list scheduled jobs was not available in that
restricted shell. It produced no output. No output was read as "no jobs", when it
actually meant "cannot check from here".
Fix: confirm the tool exists before you trust a negative result:
`command -v crontab && crontab -l || echo "cannot check from this shell"`.
Defense: DOCUMENTARY. This is the highest-value analytical rule here, because it
manufactures confident false conclusions. Any negative finding that depends on a
system command must state which shell it ran in.

### G17: an agent will report a generated file as updated without running the generator (2026-08-19)
Symptom: an agent said the handoff was updated. The file was unchanged except for
a trailing newline. No archive snapshot existed.
Cause: the agent lacked the ability to run the script it was told to run. Rather
than reporting that, it edited the file directly, had nothing new to write,
touched it, and claimed success.
Fix: a generated file has exactly one correct writer, which is its script. Verify
with the file's git log, not with the agent's summary.
Defense: DOCUMENTARY plus structure. `99_system/VAULT_ARCHITECTURE.md` names the
writer for every generated file. Generalizes to: when an agent cannot do what it
was asked, the failure mode is often a confident claim rather than an error.

### G18: check the ground truth before repeating a "blocked" claim (2026-08-19)
Symptom: a boot summary reported work as blocked for two sessions after it had
been finished and committed.
Cause: the summary was re-derived from the body text of a document instead of
checked against the commit history. Stale body text produces a stale summary
forever.
Fix: before repeating any blocked or pending claim, run `git log --oneline -5` on
the relevant repository and confirm the blocking work has not already landed. It
takes about five seconds.
Defense: DOCUMENTARY. The CLAUDE.md identity rule that a memory-sourced claim is
tagged unverified until it is confirmed against current state.

### G19: bulk approval inverts the review gate (2026-08-19)
Symptom: a pipeline designed for per-item human approval had all 45 items flipped
to approved in one scripted line, then spot-checked afterwards. The user's later
corrections caught four wrong destinations.
Cause: the review stage was skipped under a "let us just see what it would do"
framing. Flipping 45 items to approved IS the decision, not scaffolding for it.
Fix: if the design says per-item approval is the gate, do not build a shortcut
that approves everything. A real review produces a mix of approve, skip, and
edit. A manifest that is 100 percent approved was not reviewed.
Defense: PARTIAL. The batch rule (RULE_D4) requires a dry-run manifest before an
apply, and the Explicit Confirmation Gate requires per-decision consent. Neither
mechanically detects a uniform approval distribution. Candidate improvement: warn
when every status in a manifest is the same value.

### G20: check the governed vocabulary before inventing a new structure (2026-08-19)
Symptom: a design pass proposed a new frontmatter field, then a new tag
namespace, to hold a concept that the existing tag vocabulary already covered.
Cause: the reflex reaches for a new mechanism. The question was framed as "what
should the new key be" instead of "what already covers this".
Fix: before proposing any new tag, field, registry, or index, read
`.claudian/config/vocab.yaml` and `99_system/SYSTEM_DOC_MAP.md`. If a governed
structure exists, extend it rather than fork it.
Defense: DOCUMENTARY, reinforced by the YAGNI ladder in
`99_system/DESIGN_BY_LIMITATION.md`. Two structures that each cover half a
concept are worse than one that covers all of it.

### G21: treat AI-generated documentation as marketing, not ground truth (2026-08-19)
Symptom: an AI-generated wiki was cited as confirmed technical architecture. A
person running the actual software contradicted it.
Cause: the page presented invented specifics in the visual style of official
documentation. Precision reads as authority.
Fix: use this source order. A running instance first. Then the raw source code.
Then official primary documentation. Then maintainer replies in issue trackers.
Everything else last.
Defense: DOCUMENTARY. Presenting a low-confidence source as fact is a trust
violation, not a small mistake.

### G22: six recurring agent behavior failures (2026-08-19)
Each was verified against a real session transcript.

1. False completion passed along. A delegated result is reported as fact without
   reading the body. Rule: "done" from a subagent is not verified.
2. Sprawl answered with more sprawl. A finding about too much structure is
   answered by adding more structure. Rule: if the finding is sprawl, the answer
   is one question or one action.
3. Duplicate written without checking. A note is added to one file when the same
   note already exists in a sibling. Rule: search the target and its siblings
   first.
4. A rule broken while implementing that same rule, because the surrounding file
   used the old style. Rule: the active rule beats the file's existing style.
5. Verification by search. Confirming a line exists and calling it verified.
   Rule: presence is not correctness. Read the surrounding section.
6. "Fix everything" answered with a menu of options instead of action. Rule: it
   means one clarifying question, or execute.

Defense: DOCUMENTARY. These map onto the Identity and Coding sections of
CLAUDE.md. They are habits, so they need re-reading rather than a hook.

## Group 5: environment

### G23: exported filenames can contain invisible characters (2026-08-19)
Symptom: shell patterns silently missed exported files that were plainly visible
in the file manager.
Cause: some export tools prepend an invisible left-to-right mark to the filename.
The name looks normal and does not match.
Fix: match on a substring rather than the whole name, and strip the character on
import.
Defense: DOCUMENTARY. Recorded in the failure-modes section of
`_handoff/USER_CONTEXT.md`. If a file you can see does not match a pattern,
suspect invisible characters before you doubt the pattern.

### G24: machine cache files will exhaust an agent's context (2026-08-19)
Symptom: reading one plugin index file consumed the entire available context.
Cause: semantic-search plugins write dense vector index files that reach tens of
thousands of tokens. They are cache, not content.
Fix: never read them. Read the source note instead.
Defense: MECHANICAL for git, DOCUMENTARY for reading. `.gitignore` excludes
`.smart-env/`, verified. No mechanism stops an agent from reading one, so the
rule matters: if a file is machine-written cache, read its source instead.

### G25: a generated digest can report another project's history (2026-08-19)
Symptom: the session digest showed a resume point describing work from a
different project, including paths outside the vault.
Cause: the generator reads `git log`. Git searches upward for a repository. When
the vault sits inside another repository and has none of its own, git returns the
outer one, and the digest states another project's state as fact.
Fix: the script now compares the repository root against the vault path and
refuses to read history unless they match. Run `git init` inside the vault.
Defense: MECHANICAL. Present in `gen_session_boot.sh`. Also a warning about
generated files generally: check what a generator read before you believe it.

### G26: an unquoted colon in a generated title breaks the properties block (2026-08-19)
Symptom: Obsidian showed a properties error on `SESSION_BOOT.md`, and a YAML parse
of the frontmatter failed with "mapping values are not allowed here". The file
looked fine to read.
Cause: the generator wrote `title: Session Boot: fast-load orientation`. In YAML a
second colon in an unquoted value ends the key, so the line is invalid. Because a
script wrote it, every regeneration reintroduced the fault.
Fix: quote any frontmatter value that contains a colon. Fixed at the source in
`gen_session_boot.sh` and `generate_handoff.sh`, not in the output file.
Defense: DOCUMENTARY, with one caution worth remembering: fixing a generated file
instead of its generator lasts until the next run. Fix the writer. Related to G05.

## Template for a new entry

```
### GNN: short title of the failure (YYYY-MM-DD)
Symptom: what you saw, including the exact error text.
Cause: why it happened.
Fix: the command or change that worked.
Defense: what now stops it, and whether that is mechanical or documentary.
```

## Where an entry belongs

- A tool, shell, or platform trap goes here.
- A failure in how a session was run goes in the Operational Failure Modes
  section of `_handoff/USER_CONTEXT.md`.
- A security problem goes in `_handoff/vip_next_session/SECURITY_FIRES.md`.
