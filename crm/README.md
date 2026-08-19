# crm

One note per person. CRM means Customer Relationship Management, but here it just
means "people notes".

OPTIONAL FOLDER. If you do not track people, delete this folder. Nothing breaks.

## How to use it

Copy `_templates/person.md` for each new person. One file per person, named after
them, for example `jane-smith.md`.

## Why one note per person

A person note collects everything about one human in one place: how you met, what
they work on, and every conversation. Wikilinks do the rest. When you write
`[[jane-smith]]` in a meeting note, her page shows that meeting in its Backlinks
pane automatically.

## Privacy warning

People notes are personal data about other people. The pre-commit hook blocks any
filename containing `CRM` from being committed, on purpose. Decide deliberately
whether this folder belongs in your git backup, and keep the remote private
either way. See `wiki/Sensitivity and Security`.
