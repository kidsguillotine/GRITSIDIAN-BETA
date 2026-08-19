---
title: API Catalog
created: 2026-08-18
meta_status: active
purpose: >
  Local, greppable catalog of free/public APIs. The /api-lookup skill searches
  this file BEFORE any web search. Empty in the starter: populate it once.
update_trigger: Regenerate with api_catalog_build.py when you want to refresh the list.
---

# API Catalog

This file is empty in the starter. To populate it, run the builder, which pulls
from the public-apis dataset:

```
python3 .claudian/scripts/api_catalog_build.py
```

Until you populate it, the `/api-lookup` skill will find no local matches and
fall back to a web search. That is expected behavior, not an error.

<!-- catalog rows go below this line -->
