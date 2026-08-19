---
title: Plugins
created: 2026-08-18
meta_status: active
purpose: List the Obsidian core and community plugins the system uses, and what each is for.
update_trigger: Update when a plugin is added, dropped, or replaced.
---

# Plugins

Obsidian has two kinds of add-on. A **core plugin** ships with Obsidian; you turn
it on in settings. A **community plugin** comes from other authors; you install it
from the community store or with BRAT (see below).

## Core plugins to turn on

Settings > Core plugins. Turn on:

- Daily notes: one note per day.
- Templates: reusable note shapes.
- Backlinks: shows which notes link to this one.
- Outgoing links: shows where this note links to.
- Graph view: a picture of all links.
- Tag pane: a list of your tags.
- Properties: edits the data block at the top of a note. See [[Frontmatter and Structure]].
- Bookmarks, Outline, Word count: helpful extras.

## Community plugins: required for the AI system

Settings > Community plugins > Browse. Install and enable:

- **Dataview**: runs small queries inside notes. The index notes in `_MOCs`
  need it. Required.
- **Local REST API** (`obsidian-local-rest-api`): opens a local door so the AI
  helper and tools can read and write notes. Required for any automation.
- **Templater**: advanced templates with dates and logic. Used by the capture
  and daily-note steps.
- **Tasks** (`obsidian-tasks-plugin`): checkbox tasks with dates. Used by the
  task pipeline scripts.
- **Obsidian Linter**: keeps note formatting and frontmatter tidy.

## Community plugins: the connection and AI layer

- **Smart Connections**: suggests related notes as you write. This is the
  "connection suggestions" feature. Recommended.
- **Smart Lookup**: semantic search over your notes.
- **Omnisearch**: fast full-text search.
- **MCP Tools** (`mcp-tools-istefox`): lets an AI agent call tools through a
  standard interface. MCP means Model Context Protocol, a shared way for AI
  tools to talk to programs.
- **Claudian** (`realclaudian`) and/or **Vault Operator** (`vault-operator`): the in-Obsidian agent surfaces. Some of these install through BRAT, not the
  main store.

**BRAT** (`obsidian42-brat`) means Beta Reviewers Auto-update Tool. It installs
community plugins that are not yet in the official store, by their GitHub name.
Install BRAT first if a plugin above is not in the store.

## Community plugins: optional helpers

- Calendar: a month view for daily notes.
- QuickAdd: one-key capture of a task or idea.
- Tag Wrangler: rename and merge tags.
- MetaEdit: edit frontmatter fields with a menu.
- Notebook Navigator: a folder-and-file side panel.
- Excalidraw: hand-drawn diagrams.
- Table Editor: easier markdown tables.

## Note on trust

Community plugins are third-party code. Install only the ones you need. The AI
system works with the required set above; the rest are comfort.

## Related

- [[Getting Started]]: where plugin install fits in the setup order.
- [[Frontmatter and Structure]]: the data block the Properties plugin edits.
