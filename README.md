# GRITSIDIAN-BETA

Obsidian and Claudian / Claude Code integration framework.

This is a project and a tool, not a product. It gives an AI helper a set of rules
so it can safely sort, link, and back up your notes.

ALL INFORMATION SHOULD BE IN THE README AT THE FOLDER ROOT. OPEN AN ISSUE IF
SOMETHING IS MISSING OR CONFUSING.

## What you are getting

The vault is now in this repository directly, unpacked. There is no zip to
download and extract. The whole folder IS the Obsidian vault.

Read `wiki/Home` first if you want the guided tour. Read `SETUP.md` if you just
want to install it.

## 1. Install Obsidian

Get it from https://obsidian.md/

On Ubuntu, Flatpak is easier:

```
flatpak install flathub md.obsidian.Obsidian
```

## 2. Install git

On Ubuntu:

```
sudo apt install git
```

Git is how your notes get backed up off your machine. Every change becomes
reversible, so a mistake cannot destroy your work. Do not skip this. The full
explanation is in `wiki/Git Backup`.

## 3. Get the vault

Clone it:

```
git clone git@github.com:kidsguillotine/GRITSIDIAN-BETA.git my-vault
cd my-vault
```

Or use the green Code button above and choose Download ZIP, then extract it.

Cloning is better: you can pull fixes later with `git pull`. A downloaded zip
cannot receive updates.

## 4. Open it as a vault

In Obsidian choose "Open folder as vault" and pick the folder you just cloned.
Pick that folder itself, not its parent.

## 5. Run setup

From inside the folder, in a terminal:

```
./setup.sh
```

This replaces the machine-specific paths with yours. `SETUP.md` explains every
step and every option. On Windows, use Git Bash and read
`wiki/Windows and Flash Drive` first.

## 6. Install the plugins

`wiki/Plugins` lists what to install and what each one does. Dataview and the
Local REST API are the two that matter most.

## Choosing a model

You can use whichever model you want. The easiest is a commercial cloud model
(Claude, Codex, Grok, and similar). With the right plugins, routing, and servers
you can call almost anything.

For a local model: use https://ollama.com/ to run models from
https://huggingface.co/, served through https://www.docker.com/ if you want the
full stack. About 8 GB of VRAM is enough for low-level vault tasks. WSL2 is only
needed on Windows if you go the local-model route.

A caution about the Vault Operator community plugin: it is useful, but in the
source vault it once reclassified about 700 files into folders that did not exist,
because it read a tag name as a folder path. 661 files had to be restored from
git. That is written up as G03 in `_handoff/GOTCHAS.md`. The move script in this
starter now blocks that specific failure. If you use Vault Operator, keep the git
backup running and check its proposed moves before you accept them.

## Where things are

| Path | What it is |
|---|---|
| `README.md` | This file |
| `SETUP.md` | Step-by-step install |
| `setup.sh` | The script that does the path replacement |
| `CLAUDE.md` | The rules the AI follows |
| `wiki/` | The full guide in plain English |
| `_handoff/GOTCHAS.md` | 26 real failures and how each is defended against |
| `99_system/` | Format specs and the architecture map |
| `.claudian/scripts/` | The pipeline scripts |
| `00_inbox` .. `80_archive` | Your notes go here |

## Feedback

Open an issue. The most useful report is any point where the instructions did not
match what you saw on screen.
