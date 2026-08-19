---
title: "Design by Limitation: why restraint is the safety property"
created: 2026-07-27
ts: 2026-07-28T00:25:53+00:00
meta_status: active
purpose: >
  Historical + engineering context for why software written WITH limitations
  (bounded scope, refusal, dry-run, least privilege) is safer than software
  written for completeness. Grounds CLAUDE.md's Coding rules and the recovery
  discipline. Read when a locally-relevant decision tempts overreach.
update_trigger: >
  Append when a new local decision class is governed by this principle, or when
  a session discovers a new failure that restraint would have prevented.
authority: >
  Rank 6 (reference/rationale). Does NOT create new operative rules: those live
  in CLAUDE.md (Coding, Hard prohibitions) and RULE_D4. This doc is the WHY.
basis: >
  Session 2026-07-27 (SanDisk recovery). Additive-bias finding verified against
  this session's own behavior; historical canon is standard CS/SE literature.
---

# Design by Limitation

> **Principle:** Good software is defined as much by what it REFUSES to do as by
> what it does. Limitation is not a shortfall: it is the safety property.
> Restraint is invisible (its payoff is the failure that never happens) and
> counterfactual, which is exactly why it must be imposed deliberately, not
> discovered by default.

## Why this matters for AI specifically (the local reason)

An LLM's default posture is ADDITIVE, and this is structural, not incidental:
- It was optimized for helpful completion: "here is a full solution" is rewarded;
  "this should refuse that input / you don't need this feature / delete this"
  reads as unhelpful. The gradient pushes against restraint.
- Its training corpus is additive: tutorials show how to DO things. The wisdom of
  "don't build it," "least privilege," "make illegal states unrepresentable" is
  learned from incidents and maintenance pain: it lives in scars, under-represented
  in text.
- It bears no cost for the code it writes (no pager, no maintenance, no future it
  inhabits), so the counterfactual value of a limitation: the exploit that didn't
  happen: is invisible to it.

Conclusion: the model can EXECUTE bounded software when the bound is given, but it
will not CHOOSE the bound. The restraint must come from the room (the constitution,
the reviewer, the spec), never from the model's judgment. CLAUDE.md's "write the
minimum code, nothing speculative" exists because the default is the opposite.
Future agents: do not trust your own instinct toward completeness: it is a trained
bias, not engineering.

## Historical lineage (the canon this rests on)

- **Dijkstra**: "The competent programmer is fully aware of the limited size of
  his own skull." Structured programming / "GOTO considered harmful": restricting
  control flow to gain correctness. Self-imposed limitation as method.
- **Hoare**: "Two ways to build a design: so simple there are obviously no
  deficiencies, or so complex there are no obvious deficiencies. The first is far
  harder." His null reference: the "billion-dollar mistake": is permissiveness
  (an unbounded feature) causing decades of harm.
- **Parnas**: information hiding: a module exposes the MINIMUM; hide every design
  decision that can change. Small interface = maintainability.
- **UNIX philosophy** (Thompson/Ritchie/McIlroy): "Do one thing and do it well."
  Small, composable, bounded tools.
- **Saltzer & Schroeder (1975)**: least privilege; minimize attack surface. Every
  capability is a liability. Security IS limitation.
- **YAGNI / KISS** (Extreme Programming): "You Aren't Gonna Need It." No
  speculative generality. This is CLAUDE.md's "nothing speculative," verbatim in
  spirit.
- **Postel's Law reversal**: "be liberal in what you accept" was later recognized
  as a security/interop LIABILITY; modern protocol design tightens acceptance.
  The field LEARNED that unbounded permissiveness is a bug.
- **Gall's Law**: "A complex system that works evolved from a simple system that
  worked." You cannot design an unbounded complex system into correctness; start
  limited.
- **Type systems / Rust borrow checker**: the compiler as an imposed refusal that
  eliminates whole bug classes. The machine made to say no.
- **Failure cases**: Ariane 5 (reused code run beyond its validated envelope),
  Therac-25 (hardware interlocks removed, trusting software), Mars Climate Orbiter
  (unchecked unit assumption). Each: a limitation absent or violated.

## Where it binds locally (apply the principle to these decision classes)

- **Failing-drive / irreplaceable-data recovery** (2026-07-27 SanDisk): COPY-ONLY,
  read-only, dry-run BEFORE any write, subfolder-scoped, never `fsck` a failing
  source. Every constraint = safety on data that cannot be re-fetched.
- **Bulk operations**: RULE_D4: >5 files = ONE scripted dry-run manifest, then ONE
  apply. Never per-item. Dedup threshold never below 0.99 (a limitation protecting
  distinct records).
- **Destructive operations**: never `rm` content (trash only); sensitive-file
  routing; rm-guard. Reversibility over reclaim.
- **Model boundary**: cloud Claudian does not touch vault CONTENT; local models do.
  A deliberate capability limit.
- **Coding**: write the minimum that solves the problem; touch only what the
  request requires (CLAUDE.md Coding). This doc is that rule's rationale.

## Relationship to operative rules (do not duplicate)

Operative force lives in CLAUDE.md (Coding, Hard prohibitions) and RULE_D4. This
doc supplies the WHY and the history so the rules are understood, not merely obeyed.
When a local decision tempts you to add, handle-more, or reclaim-fast: the default
is wrong: prefer the bounded, refusing, reversible option, and make the limitation
explicit.

---

## The YAGNI ladder (folded in from the ponytail reference, 2026-08-19)

YAGNI means "you are not going to need it". The best code is the code never
written. The best doc is the doc never created. Every line, file, folder,
dependency, and rule costs something forever: reading it, debugging it, updating
it, and loading it into the next session's context.

When you want to add code, a doc, a dependency, or an abstraction, walk this
ladder from the top. Stop at the first rung that solves the real problem.

1. Do not. First confirm the problem is real and current, not hypothetical.
2. Use the standard library, a shell builtin, or a native Obsidian feature.
3. Use the platform you already run (Obsidian, the scripts you have).
4. Use a dependency already present somewhere in the project.
5. Only now add something new. Write down why rungs 1 to 4 failed.

### When to break the ladder

Add the thing anyway when all three are true:

- The problem has happened at least twice, for real.
- The lighter option was tried and failed, and you can say how.
- The new thing has one owner and one place to live.

### How this applies to docs

This project has many small docs. That is a cost, not a feature. Before adding
another one, try appending a section to an existing doc instead. Two docs that
each explain half of one idea are worse than one doc that explains it. That is
why the ponytail reference was folded into this file rather than shipped on its
own.
