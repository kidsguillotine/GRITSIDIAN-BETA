# _MOCs

MOC means Map of Content. Each file here is an index note that links to many
notes on one topic. A MOC is how you find things without folders.

THIS FOLDER IS MACHINE-MANAGED. Do not hand-edit a generated index file; the
rebuild will erase your change.

One exception ships with the starter: `Examples.md` is a hand-written list of MOC
names you might want. It is a suggestion list, not an index. Delete it once you
have made your own.

Build or rebuild them:

    python3 .claudian/scripts/rebuild_mocs.py

The folder is empty on a fresh vault, which is correct: there is nothing to index
yet. Write some notes first, then run the command. Spec:
`99_system/SCRIPT_SPECS.md`.

Obsidian shows related notes in other ways too: the Backlinks pane, the Graph
view, and the Smart Connections plugin. See `wiki/Plugins`.
