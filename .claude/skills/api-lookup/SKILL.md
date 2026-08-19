---
name: api-lookup
description: Use when the user asks "is there an API for X", "find me a free API", or needs a data source for an integration/workflow. Searches the local 99_system/API_CATALOG.md (1,585 free/public APIs with Auth/HTTPS/CORS fields) BEFORE any web search.
---

# /api-lookup: local-first API discovery

Procedure (in order, stop at the first step that satisfies the request):

1. **Search the local catalog.** One grep pass, not per-item reads:
   ```
   grep -in "<keyword>" 99_system/API_CATALOG.md | head -30
   ```
   Try synonyms in the same pass (`grep -inE "weather|forecast|climate"`). Category
   headings are `### <Category>` lines: grep those first to scope broad asks.

2. **Present matches as a table**: Name (linked), Description, Auth, HTTPS, CORS.
   Prefer `Auth = No` (keyless) entries when the user wants zero-setup; flag
   `apiKey`/`OAuth` entries with what signup they imply.

3. **US-government data ask?** Point at the api.data.gov quick-facts section at the
   top of the catalog note (one free key, 25 agencies, 450+ APIs, 1,000 req/hr,
   `X-Api-Key` header). Key storage: PAS `.env` ONLY: and note the catalog's
   caution that api.data.gov keys evade the canonical secret-scan patterns.

4. **No local match -> web.** Only then WebSearch/WebFetch. If a good API is found
   that the catalog lacks, say so: the catalog regenerates from upstream via
   `python3 .claudian/scripts/api_catalog_build.py --apply`, it is not hand-edited.

Rules that bind here:
- Never write an API key into any vault file (canonical storage: PAS `.env`).
- Any resulting integration work (n8n workflow, fetch script) is a NEW decision -
  Explicit Confirmation Gate applies; do not build it as a side effect of lookup.
- Catalog staleness: check the `<!-- generated <ts> ... -->` line inside the note;
  if it is months old, offer a regen before trusting coverage claims.
