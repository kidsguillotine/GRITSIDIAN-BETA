---
title: Symlink Registry
created: 2026-08-19
meta_status: active
purpose: >
  Records every symlink in the vault. This starter ships NO symlinks: every file
  is real. The registry exists so the integrity check (C2 and C3) has something to
  read, and so the first symlink you create gets recorded instead of forgotten.
update_trigger: >
  Add a row when you create a symlink. Remove it when the link is deleted.
authority: Rank 4 registry. The filesystem is ground truth; this is its index.
---

# Symlink Registry

## Active symlinks

None. Every file in this starter is a real file.

| Link path | Points to | Why |
|---|---|---|
| (none yet) | | |

## The standard, if you adopt symlinks

One canonical file. Every other location is a link to it. Never a copy, because
copies drift silently and nothing tells you.

1. Edit the canonical file only. Never edit through a link.
2. Never copy a script to share it. Link it, and add a row above.
3. Do not use symlinks if the vault lives on a USB drive: exFAT and FAT cannot
   store them. See `wiki/Windows and Flash Drive` and section 8 of
   `99_system/DOC_STANDARD.md`.
