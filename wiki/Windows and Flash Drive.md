---
title: Windows and Flash Drive
created: 2026-08-18
meta_status: active
purpose: Prerequisites and steps to install and run the system on Windows and from a portable USB drive.
update_trigger: Update when a prerequisite version or a portability caveat changes.
---

# Windows and Flash Drive

The scripts are written for a Unix-style shell (bash) with Python and git. This
page shows how to meet those needs on Windows, and how to run from a USB drive.

Short version for Windows: install Obsidian, Git for Windows, and Python. Use
Git Bash. That is the whole requirement. WSL2 is not needed unless you run a
local AI model.

## Part A: Windows

Obsidian itself runs on Windows with no extra work. The AI scripts need three
things Windows does not ship by default.

### Prerequisites

1. **Obsidian**: install from the Obsidian website.
2. **Git**: install "Git for Windows". It includes **Git Bash**, a program that
   runs the `.sh` scripts. This is the key piece.
3. **Python 3.11 or newer**: install from the Python website. Tick "Add Python
   to PATH" in the installer.
4. **A code assistant**: pick one:
   - The **Claudian Obsidian plugin** (`realclaudian`). Simplest on Windows. It
     runs inside Obsidian. See [[Plugins]].
   - Or the **Claude Code command-line tool**, which needs **Node.js**. Harder to
     set up, more control.

### Two ways to run the shell scripts

**Git Bash is enough. You do not need WSL2.**

- **Git Bash** (use this): right-click in the vault folder and choose "Git Bash
  Here", then run `./setup.sh`. Git Bash comes with Git for Windows. It runs every
  script in this project.
- **WSL2** (only for a local model): WSL means Windows Subsystem for Linux. It
  runs a real Linux inside Windows. You need it ONLY if you choose to run a local
  AI model with Docker and Ollama. That is an optional extra. If you use a cloud
  model, which is the default, WSL2 is not required and adds nothing.

### Steps

1. Install the four prerequisites above.
2. Copy this folder to your drive (for example `C:\Vaults\claudian-starter`).
3. Open Git Bash in that folder.
4. Run `./setup.sh`.
5. Open the folder in Obsidian as a vault.
6. Install the plugins. See [[Plugins]].
7. Set up the backup. See [[Git Backup]].

## Part B: Run from a USB flash drive

You can run the whole system from a USB drive. This makes it portable between
computers. There are real limits; read the caveats.

### Prerequisites

1. **A fast USB drive**, 3.0 or newer, 32 GB or more.
2. **Drive format:** use **exFAT** (works on Windows, Mac, Linux) or **NTFS**
   (Windows only). Do not use FAT32. FAT32 cannot hold a file over 4 GB.
3. **Portable Git**: "PortableGit" (the portable build of Git for Windows). Put
   it on the drive. It brings Git Bash with it.
4. **Portable Python**: "WinPython" or the Python embeddable build. Put it on
   the drive.
5. **Obsidian**: either install Obsidian on each computer you use, or use a
   portable-app launcher. The vault itself (this folder) is already portable; its
   settings live in the `.obsidian` folder inside it.

### The big caveat: drive letters change

On Windows a USB drive gets a letter, like `E:` on one computer and `F:` on the
next. The setup step writes full paths into the config. Those paths break when
the letter changes.

Two ways to handle this:

- **Simple:** run `./setup.sh` again each time you move to a new computer. It
  rewrites the paths for the current letter. Fast and safe.
- **Advanced:** keep paths relative to the vault where the scripts allow it, so
  the letter does not matter. This needs manual edits and is not the default.

### More caveats

- exFAT and FAT do not support Unix links or file permissions. The starter uses
  plain files, so this is fine. Do not try to use the symlink layout from the
  full system on these formats.
- Running Python and git off USB is slower than off an internal disk.
- The optional local model stack (Docker, Ollama) is not practical from a USB
  drive. Use cloud-only mode on portable setups.

### Portable steps

1. Format the drive as exFAT.
2. Put PortableGit and portable Python on the drive.
3. Copy this folder onto the drive.
4. Open Git Bash (from PortableGit) in the folder.
5. Run `./setup.sh`. Re-run it whenever the drive letter changes.
6. Open the vault in Obsidian and install the plugins.

## Related

- [[Getting Started]]: the plain overview.
- [[Plugins]]: what to install in Obsidian.
- [[Git Backup]]: set up the backup after install.
- `SETUP.md`: the command-line setup detail.
