# Claudian Starter: Setup

This is a clean, genericized version of the Claudian Obsidian-agent system: the
operating rules (`CLAUDE.md`), the skills, the pipeline scripts, and an empty
vault taxonomy. It carries no personal content. Follow the steps below to wire it
to your own machine.

## What you get

- `CLAUDE.md`: the agent's operating constitution (rules that govern behavior).
- `.claude/skills/`: trigger-fired skills (`/session-close`, `/daily-note`, `/drain`, `/api-lookup`, `chunk-and-categorize`).
- `.claudian/scripts/`: the pipeline: handoff generation, link checking, classification, safe moves, dedup, capture routing, logging.
- `.claudian/hooks/`: git `pre-commit` guard and installer; `rm-guard` lives in scripts.
- Empty vault folders (`00_inbox` ... `80_archive`, `crm`, `_MOCs`) with a README each.
- `99_system/` and `_handoff/` doc templates.

## 1. Place the vault

Copy or move this `claudian-starter/` directory to wherever you want your vault
to live, and (optionally) rename it. Open that folder as a vault in Obsidian.

## 2. Run setup.sh

```
cd claudian-starter
./setup.sh
```

It replaces the following placeholders in-place:

| Placeholder | Meaning | Default |
|---|---|---|
| `__VAULT_ROOT__` | Absolute path to this vault | the starter directory |
| `__SCRIPTS_ROOT__` | Canonical scripts directory | `<vault>/.claudian/scripts` |
| `__SENSITIVE_STORE__` | Where sensitive files are routed (kept out of git) | `<vault>/_sensitive` |
| `__STACK_ROOT__` | Local Docker stack dir (only if you use the optional local-model stack) | unused |
| `__HOME__` | Your home directory | `$HOME` |

Non-interactive: `VAULT_ROOT=/abs/path ./setup.sh --yes`.

## 3. Hooks

A hook is a small script that runs automatically at a set moment. You do not call
it yourself. This system uses two separate hook layers, and they are wired in
different places.

### Layer 1: Claude Code hooks (already wired, nothing to run)

These live in `.claude/settings.json`. Claude Code loads them when you open this
folder as the project. `setup.sh` corrects the file path inside that file, so
after you run setup they work with no further action.

| When it fires | What runs | Why |
|---|---|---|
| Before a Bash command | `rm-guard.sh` | Blocks `rm` on a note file. |
| At session end | `generate_handoff.sh --quick` | Refreshes the state digest. |

### Layer 2: Git hooks (you must install these once)

These run at commit time. They block a commit that would leak a secret, commit a
private filename, or add a broken wikilink.

Type these two lines in a terminal, one at a time, from inside the vault folder.
The lines below are commands to run, not a file to save.

```bash
git init
bash .claudian/hooks/install.sh
```

Skip `git init` if this folder is already a git repository. To check, run
`git status`: an error means it is not a repository yet.

Confirm it worked:

```bash
ls -l .git/hooks/pre-commit
```

You should see one file. If the path does not exist, the install did not run.
Full explanation of what the hook checks: `wiki/Sensitivity and Security`.

## 4. Choose your model configuration

**Cloud-only (simplest).** Run the agent (Claude) with `CLAUDE.md` as the project
instruction file. Everything in the rules layer works. Skip the local stack.

**Cloud + local model (reference config).** The `Model boundary policy` in
`CLAUDE.md` routes content operations to a local model and infrastructure to the
cloud model. To use it you need, at minimum:

- Ollama (`systemctl --user start ollama`) with a small instruct model pulled.
- Optionally a vector store (ChromaDB) if you want semantic dedup/reconcile. FFmpeg is also recommended.
- Optionally the Docker stack under `__STACK_ROOT__`.

These are all optional. The scripts degrade gracefully when a service is absent;
the rules layer does not require any of them.

## 5. First session

Open a Claudian/Claude session in the vault. It will:

1. Read `_handoff/SESSION_BOOT.md` (regenerate it any time with
   `bash .claudian/scripts/gen_session_boot.sh`).
2. Read `_handoff/BOOT_DELTA.md`.
3. Scan `_handoff/vip_next_session/`.

At session end the Stop hook (if configured) runs
`generate_handoff.sh --quick` to refresh the boot digest.

## After setup.sh: verify

```
grep -rE "__(VAULT_ROOT|SCRIPTS_ROOT|STACK_ROOT|SENSITIVE_STORE|HOME)__" . \
  || echo "no placeholders left"
python3 .claudian/scripts/check_links.py --count-broken   # baseline: 0 on an empty vault
```

## Notes for testers

- The rules ban emojis and em/en dashes in agent output. That is intentional
  (anti-AI-slop). Leave it unless you have a reason to change it.
- Scripts assume Python 3.11+ and a POSIX shell. `requirements.txt` lists Python
  deps for the pipeline scripts that need them.
- Nothing here touches your existing files. It only operates inside this vault.
- Feedback: note anything confusing in this doc; the goal is that a tester can go
  from copy to first working session without asking questions.
