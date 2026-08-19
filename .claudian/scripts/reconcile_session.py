#!/usr/bin/env python3
"""
reconcile_session.py: L-1 reconcile loop (IH-3 / OD-16 resolved 2026-06-22)

At session close, diffs the live JSONL transcript against agent_memory.py
captures. Surfaces text snippets that look like decisions/facts/gotchas
that were discussed but never captured. Output is a human-readable miss-list.

HOW IT WORKS
1. Find the current session transcript (.jsonl with latest mtime).
2. Extract the session start timestamp (first 'user' turn).
3. Load agent_memory captures logged this session (ts >= session_start).
4. Scan 'assistant' turns for HIGH-SIGNAL patterns:
     OD-N references, G-N GOTCHA references, explicit rule additions,
     "resolved", "committed", "added to CLAUDE.md", "new hard rule".
5. For each matched snippet, run am.search() to check if it's already
   captured. Uncaptured snippets -> miss-list.
6. Write report to stdout (or --output <file>).

SIGNAL PATTERNS (high-confidence only: avoids general assistant prose)
  OD-[0-9]+           Open Decision reference
  G[0-9]+             GOTCHA reference (G13, G34, etc.)
  RESOLVED            Decision status marker
  hard rule           CLAUDE.md rule addition signal
  added to CLAUDE.md  Explicit rule commit signal
  record_decision     Direct capture API call mention
  capture(            Direct capture API call mention
  MIGRATION_LOG       Log append signal
  [X]                 Checklist completion marker (MIGRATION_LOG style)

CROSS-REFERENCE
  am.search(keyword): FTS5 lexical search, status-filtered to 'active'.
  A miss is a snippet whose extracted keywords return zero results AND
  whose text doesn't match any captured text from this session.

INTEGRATION
  Called by /session-close §2b. Output written to:
    _handoff/reconcile_<session_id>.md
  or piped to stdout for inline display.

DEPENDENCIES
  Python stdlib only. agent_memory.py must be on sys.path (same directory).
  No Ollama required.

OVERRIDE ENV VARS
  TRANSCRIPT_DIR   path to Claude Code project transcript directory
  AGENT_MEM_JSONL  path to agent_memory JSONL mirror
  VAULT            path to vault root (for output path resolution)
"""
import json, os, re, sys
from datetime import datetime, timezone

# -- Paths --------------------------------------------------------------------
TRANSCRIPT_DIR = os.path.expanduser(os.environ.get(
    "TRANSCRIPT_DIR",
    "~/.claude/projects/-home-youruser-Projects-your-vault"))

MIRR = os.environ.get(
    "AGENT_MEM_JSONL",
    os.path.expanduser("~/.local/share/agent_memory/memory.jsonl"))

VAULT = os.environ.get("VAULT", "__VAULT_ROOT__")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import agent_memory as am

# -- High-signal decision patterns --------------------------------------------
# Each pattern must individually be a strong signal that a decision/fact/
# rule was produced. General assistant prose is excluded.
SIGNAL_RE = re.compile(
    r'OD-\d+'                          # Open Decision reference
    r'|G\d{1,3}\b'                     # GOTCHA reference (G13, G34)
    r'|\bRESOLVED\b'                   # Decision status marker
    r'|hard rule'                      # CLAUDE.md rule addition
    r'|added to CLAUDE\.md'            # Explicit rule commit
    r'|record_decision\('              # Capture API call
    r'|capture\('                      # Capture API call
    r'|MIGRATION_LOG'                  # Log append signal
    r'|\[X\]',                         # Checklist completion (MIGRATION_LOG style)
    re.IGNORECASE,
)

# Snippet window: take N chars around the match for context.
SNIPPET_RADIUS = 120
MIN_SNIPPET    = 30   # ignore matches shorter than this after stripping


# -- Helpers -------------------------------------------------------------------
def _ts_now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f+00:00")


def _extract_text(rec):
    """Pull plain text from a JSONL record (matches gate_and_archive.py logic)."""
    msg = rec.get("message", rec)
    content = msg.get("content") if isinstance(msg, dict) else None
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for b in content:
            if isinstance(b, dict) and b.get("type") == "text":
                parts.append(b.get("text", ""))
            elif isinstance(b, str):
                parts.append(b)
        return "\n".join(parts)
    return ""


def _iter_session(path):
    """Yield (type, text, timestamp) for each record in a transcript file."""
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            yield rec.get("type", ""), _extract_text(rec), rec.get("timestamp", "")


def _latest_transcript():
    """Return path to the most recently modified .jsonl in TRANSCRIPT_DIR."""
    try:
        files = [f for f in os.listdir(TRANSCRIPT_DIR) if f.endswith(".jsonl")]
    except FileNotFoundError:
        return None
    if not files:
        return None
    files.sort(key=lambda f: os.path.getmtime(os.path.join(TRANSCRIPT_DIR, f)),
               reverse=True)
    return os.path.join(TRANSCRIPT_DIR, files[0])


def _session_start(path):
    """Return ISO timestamp of the first 'user' turn, or None."""
    for rtype, _, ts in _iter_session(path):
        if rtype == "user" and ts:
            return ts
    return None


def _captured_this_session(since_ts):
    """Return set of lowercased capture texts logged after since_ts."""
    captured = set()
    if not os.path.exists(MIRR):
        return captured
    with open(MIRR, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            if rec.get("event"):            # skip diagnostic events
                continue
            if since_ts and rec.get("ts", "") < since_ts:
                continue
            text = rec.get("text", "")
            if text:
                captured.add(re.sub(r'\s+', ' ', text.lower()).strip())
    return captured


def _extract_snippets(text):
    """Yield unique context snippets around each SIGNAL_RE match in text."""
    seen = set()
    for m in SIGNAL_RE.finditer(text):
        start = max(0, m.start() - SNIPPET_RADIUS)
        end   = min(len(text), m.end() + SNIPPET_RADIUS)
        snippet = text[start:end].strip()
        # Trim to nearest sentence boundary if possible
        if start > 0:
            cut = snippet.find('. ')
            if 0 < cut < 30:
                snippet = snippet[cut + 2:]
        if len(snippet) < MIN_SNIPPET:
            continue
        key = re.sub(r'\s+', ' ', snippet.lower())[:80]
        if key in seen:
            continue
        seen.add(key)
        yield snippet


def _log_search_failure(token, exc):
    """OD-44A R5: surface FTS5 search failures instead of swallowing them.

    Writes a diagnostic record to the JSONL mirror (event field excludes it from
    capture-set computation) and emits a stderr warning. Never raises: defense
    against cascade failures on a degraded DB.
    """
    try:
        with open(MIRR, "a", encoding="utf-8") as f:
            f.write(json.dumps({
                "event": "reconcile_search_failure",
                "ts": _ts_now(),
                "token": token,
                "error": f"{type(exc).__name__}: {exc}",
            }) + "\n")
    except Exception:
        pass  # diagnostic write is best-effort; don't cascade
    print(f"WARN reconcile_session: am.search({token!r}) failed: "
          f"{type(exc).__name__}: {exc}", file=sys.stderr)


def _is_captured(snippet, captured_texts):
    """Return True if snippet appears to be in agent_memory (FTS or direct match)."""
    key = re.sub(r'\s+', ' ', snippet.lower()).strip()

    # Direct text proximity against this-session captures
    for ct in captured_texts:
        # Substring overlap of ≥40 chars = likely same content
        if len(key) >= 40 and key[:40] in ct:
            return True
        if len(ct) >= 40 and ct[:40] in key:
            return True

    # FTS5 search for high-signal keywords (OD numbers, GOTCHA IDs)
    for token in re.findall(r'OD-\d+|G\d{1,3}', snippet, re.IGNORECASE):
        try:
            hits = am.search(token)
        except Exception as exc:
            _log_search_failure(token, exc)
            hits = []
        if hits:
            return True

    return False


# -- Main reconcile pass -------------------------------------------------------
def reconcile(session_file=None, output=None):
    """Run the reconcile pass. Returns (miss_count, candidate_count)."""
    if session_file is None:
        session_file = _latest_transcript()
    if not session_file or not os.path.exists(session_file):
        msg = f"ERROR: transcript not found (TRANSCRIPT_DIR={TRANSCRIPT_DIR})"
        print(msg, file=sys.stderr)
        return 0, 0

    session_id  = os.path.splitext(os.path.basename(session_file))[0]
    since_ts    = _session_start(session_file)
    captured    = _captured_this_session(since_ts)

    misses, candidates = [], 0

    for rtype, text, _ in _iter_session(session_file):
        if rtype != "assistant" or not text:
            continue
        for snippet in _extract_snippets(text):
            candidates += 1
            if not _is_captured(snippet, captured):
                misses.append(snippet)

    # -- Report ----------------------------------------------------------------
    out = open(output, "w", encoding="utf-8") if output else sys.stdout
    try:
        out.write(f"# reconcile_session: {_ts_now()}\n")
        out.write(f"transcript:            {session_id}\n")
        out.write(f"session_start:         {since_ts or 'unknown'}\n")
        out.write(f"captured_this_session: {len(captured)}\n")
        out.write(f"signal_candidates:     {candidates}\n")
        out.write(f"miss_candidates:       {len(misses)}\n")
        out.write("=" * 72 + "\n\n")

        if not misses:
            out.write("No missed decisions detected.\n")
            out.write("agent_memory appears complete for this session.\n")
        else:
            out.write("REVIEW REQUIRED\n")
            out.write("The following signal-pattern snippets were NOT found in\n")
            out.write("agent_memory. Add via record_decision() or capture() if\n")
            out.write("they should be preserved across sessions.\n\n")
            for i, snippet in enumerate(misses, 1):
                display = snippet.replace("\n", " ")[:200]
                out.write(f"[{i:02d}] {display}\n\n")

        out.write("=" * 72 + "\n")
        out.write("To capture a miss: python3 agent_memory.py decide \"<text>\" \"<topic>\"\n")
    finally:
        if output:
            out.close()

    return len(misses), candidates


# -- CLI ------------------------------------------------------------------------
if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser(description="Reconcile session transcript against agent_memory captures.")
    p.add_argument("--session", help="Path to a specific transcript .jsonl file (default: latest)")
    p.add_argument("--output",  help="Write report to this file instead of stdout")
    p.add_argument("--vault-output", action="store_true",
                   help="Write report to _handoff/reconcile_<session_id>.md inside VAULT")
    args = p.parse_args()

    session_file = args.session
    output_path  = args.output

    if args.vault_output and not output_path:
        sid = os.path.splitext(os.path.basename(
            session_file or _latest_transcript() or "unknown"))[0]
        output_path = os.path.join(VAULT, "_handoff", f"reconcile_{sid}.md")
        os.makedirs(os.path.dirname(output_path), exist_ok=True)

    miss_count, candidate_count = reconcile(session_file=session_file, output=output_path)

    if output_path:
        print(f"Report written to: {output_path}")
        print(f"Miss candidates: {miss_count} / {candidate_count} signal hits")

    sys.exit(0 if miss_count == 0 else 1)
