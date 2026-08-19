---
title: "Token Discipline: Deterministic Scripts Over Per-Item Agent Calls"
created: 2026-07-23
meta_status: standing-rule
purpose: >
  Documents the pattern of preferring a single deterministic script over
  per-item LLM/agent tool calls for repeatable or bulk work, and states the
  precise principle so downstream agents apply it without over-reading it as
  "save tokens at the expense of correctness." Worked instance: reorg_by_type.py
  (2026-07-23), written once instead of moving ~29k files via per-item calls.
update_trigger: >
  Revise if RULE_D4 or the model-boundary policy changes. Wording is
  user-confirmed (2026-07-23); do not weaken to "token saving over verification."
authority: >
  Standing rule (user-confirmed 2026-07-23). Binding on Claudian and all
  subagents. Expands RULE_D4 and the model-boundary policy with rationale and a
  worked example. Does NOT override verification-first discipline: when cheap and
  correct diverge, correct wins.
---

# Token Discipline

## The principle (precise)

**Prefer a single deterministic script over per-item LLM/agent tool calls for any
repeatable or bulk operation.** The token savings are a *consequence* of the
script also being more correct: deterministic, inspectable, reversible, unable
to hallucinate. The savings are never the justification for skipping a check.

**When "cheap" and "correct" diverge, correct wins.** Verifying against ground
truth, reading a file in full before a content decision, and producing a dry-run
manifest all cost more tokens than guessing. Spend them. A wrong cheap answer is
the most expensive thing an agent can produce, because a human then pays to find
and undo it.

## What this is NOT

Not "token saving is the top priority." That reading is dangerous and this
session disproves it: the highest-value actions cost the most tokens. Do not cut
verification, ground-truth checks, or dry-runs to save tokens.

## Why the script beats per-item calls (both axes)

| | Per-item agent/LLM calls | One deterministic script |
|---|---|---|
| Cost | N model round-trips | 1 invocation |
| Correctness | Each call can hallucinate | Cannot hallucinate; same input -> same output |
| Reviewability | N opaque decisions | 1 manifest a human reads |
| Reversibility | Ad hoc | Undo script generated with the manifest |
| Reconcile | None | files-in == files-out or it aborts |

The point is that cheap and correct **align** in this pattern. That alignment is
why it is the right default: not the cost alone.

## Already codified

This is an instance of existing law, not a new rule:
- **RULE_D4** (CLAUDE.md): any operation touching > 5 files/records runs as ONE
  script producing a dry-run manifest, then ONE apply: never per-item tool calls.
- **Model-boundary policy** (CLAUDE.md): content ops route through local scripts
  (`vault_agent.py`, `agent_runner.py`), not the cloud agent.

If an agent finds itself about to loop a tool call over a batch, it is about to
violate RULE_D4. Write the script instead.

## Worked instance (2026-07-23)

Task: collapse ~29,000 provenance-split images into type folders. The wrong path
was ~29k per-item move calls (expensive AND each fallibly judged). The right path
was `~/reorg/reorg_by_type.py`: one script, dry-run by default, category
classification, collision-safe, reconcile guard, generated undo script,
provenance preserved in the manifest. Verified on a throwaway fixture (8 files,
collision handled, source untouched) before being offered for real use. Not run
on live data: the apply trigger stays with the user.

## Heuristic for downstream agents

1. Repeatable or > 5 items? -> write a script, not a loop of tool calls.
2. Script defaults to dry-run; a human reads the manifest before `--apply`.
3. Every apply is reversible (undo script) and reconciled (counts must match).
4. Never trade a verification step for tokens. The savings are supposed to come
   from *not re-deriving*, not from *not checking*.


---

## The routing ladder (extracted from MODEL_ROUTING.md, 2026-08-19)

Every RECURRING operation is placed at the lowest tier that meets its acceptance
criteria. Going above the tier needs a one-line logged reason. One-off work is
exempt: this governs things that repeat.

| Tier | Executor | Cost | Use when |
|---|---|---|---|
| 0 | A deterministic script | free | The criteria need no judgment. |
| 1 | A local model | cheap | Judgment needed, and a wrong answer is cheap to fix. |
| 2 | A cloud model | costly | Judgment needed, and a wrong answer is expensive. |
| 3 | A human | slowest | The decision is irreversible or sets policy. |

Most work that feels like it needs tier 2 is really tier 0 with an unclear
specification. Write the specification and the tier drops.

If you run cloud-only, tiers 0 and 2 are your whole ladder. The principle does
not change: a script beats a model whenever the criteria are mechanical.
