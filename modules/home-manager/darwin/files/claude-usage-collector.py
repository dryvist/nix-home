#!/usr/bin/env python3
"""Emit Prometheus exposition text for what the Claude Code OTEL exporter does not.

Native OTEL gives cost, tokens by coarse type, sessions, tool decisions -- but
none of it split by repo or by main-vs-subagent. It also does NOT give the 5m
vs 1h ephemeral cache split or thinking tokens. This reads the session
transcripts for those, and separately models per-message cost (tokens x
LiteLLM's public price table) so that cost, unlike the native metric, can
carry the same repo/agent attribution.

Incremental by (path -> byte offset) watermark; counters are cumulative so the
output matches the cumulative temporality VictoriaMetrics needs.

Usage:
    claude-jsonl-etl.py                 # print exposition text to stdout
    claude-jsonl-etl.py --push URL      # POST it to /api/v1/import/prometheus
    claude-jsonl-etl.py --selfcheck     # run assertions, touch no real state
"""
from __future__ import annotations

import argparse
import json
import pathlib
import socket
import sys
import time
import urllib.request

PROJECTS = pathlib.Path.home() / ".claude" / "projects"

# Cumulative counter state lives under XDG_STATE_HOME (~/.local/state), NOT
# XDG_CACHE_HOME (~/.cache) -- a `.cache` directory is fair game for
# disk-cleanup tooling to delete on a whim, and this file IS the cumulative
# counter, not a memo of one. Losing it resets every counter to 0 while the
# already-reported total is still sitting in VictoriaMetrics as the prior
# sample; Prometheus's `increase()` treats that drop as a counter reset and
# ADDS the pre-reset value back into the range sum, so a single silent wipe
# inflates a query by the entire historical total, and repeated wipes
# compound. Found live: a 7-day `increase()` over 1h cache writes for `main`
# returned ~609B tokens against a real weekly total near 110M -- ~5000x,
# consistent with exactly this failure mode recurring across a series of
# `.cache` wipes. `LEGACY_STATE` is read once, as a one-time migration, so
# shipping this fix does not itself trigger the same reset it fixes.
STATE = pathlib.Path.home() / ".local" / "state" / "claude-jsonl-etl" / "state.json"
LEGACY_STATE = pathlib.Path.home() / ".cache" / "claude-jsonl-etl" / "state.json"

# The price table, unlike the counter state, is genuinely disposable: a miss
# just means one re-fetch, so it stays under .cache on purpose.
CACHE_DIR = pathlib.Path.home() / ".cache" / "claude-jsonl-etl"
# LiteLLM's public price table -- the same source ccusage uses -- rather than
# a hand-maintained model->$/token map that would silently drift every time a
# provider changes pricing.
PRICE_URL = "https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json"
PRICE_CACHE = CACHE_DIR / "prices.json"
PRICE_MAX_AGE_SECONDS = 86400  # refetch at most daily; the cache covers everything between

# Short hostname, resolved once. Short rather than the FQDN so the value
# matches the `host_name` the OTEL exporter already sets, letting a panel join
# the two sources on one label instead of normalising at query time.
HOST = socket.gethostname().split(".")[0]

# metric -> help text. Monotonic counters, plus the one gauge named below.
METRICS = {
    "claude_jsonl_cache_creation_tokens_total": "Cache-creation input tokens, split by ephemeral TTL",
    "claude_jsonl_cache_read_tokens_total": "Cache-read input tokens",
    "claude_jsonl_input_tokens_total": "Uncached input tokens",
    "claude_jsonl_output_tokens_total": "Output tokens",
    "claude_jsonl_thinking_tokens_total": "Thinking tokens (subset of output)",
    "claude_jsonl_messages_total": "Assistant messages seen",
    "claude_jsonl_context_injection_bytes_total": "Bytes of context injected before the conversation (skill listings, MCP instructions, hook output)",
    "claude_jsonl_context_injections_total": "Count of injected-context attachments",
    # Gauge, not counter: the bytes of each injected kind seen before a
    # session's first request, i.e. what the harness front-loads. The
    # exporter's own `token.usage` metric gives the first request's TOTAL per
    # session but nothing itemizes it; this is the itemization. Latest
    # session per label set.
    "claude_jsonl_baseline_injection_bytes": "Injected-context bytes before the first request, by kind; newest session per label set",
    "claude_jsonl_cost_usd_total": "Modeled USD cost per message (tokens x LiteLLM's public price table); absent entirely when no price table is available",
    "claude_jsonl_cost_unpriced_messages_total": "Messages whose model was missing from the price table (counted as $0 cost, never silently dropped)",
    # Approximate: transcripts carry the tool result's bytes, never a token
    # count for it, so this is bytes/4 rather than an exact count -- good
    # enough to rank which tools flood the context, not to bill against.
    "claude_jsonl_tool_result_tokens_total": "Tool-result size fed back into context, approximated as bytes/4, by tool name",
    "claude_jsonl_turn_pause_total": "Turns whose gap since the same transcript's prior turn falls in this bucket (5m-60m or over 1h; TTL-relevant pauses only)",
    "claude_jsonl_subagents_total": "Subagent transcripts started (one per subagent file, counted the first time it is scanned)",
}
BASELINE_METRIC = "claude_jsonl_baseline_injection_bytes"
COST_METRIC = "claude_jsonl_cost_usd_total"
UNPRICED_METRIC = "claude_jsonl_cost_unpriced_messages_total"
TOOL_RESULT_METRIC = "claude_jsonl_tool_result_tokens_total"
PAUSE_METRIC = "claude_jsonl_turn_pause_total"
SUBAGENT_METRIC = "claude_jsonl_subagents_total"

_TIME_FMT = "%Y-%m-%dT%H:%M:%S"


def _parse_ts(ts: str) -> float | None:
    """Epoch seconds from an ISO8601 `Z` timestamp, or None if unparseable."""
    if not ts:
        return None
    try:
        return time.mktime(time.strptime(ts[:19], _TIME_FMT)) - time.timezone
    except ValueError:
        return None


def pause_bucket(gap_seconds: float) -> str | None:
    """Bucket a gap since the transcript's prior turn. None = not TTL-relevant
    (under 5 minutes: still inside the 5m cache window, nothing to explain)."""
    if gap_seconds < 300:
        return None
    return "over_1h" if gap_seconds > 3600 else "5m_60m"


def load_prices() -> tuple[dict | None, str | None]:
    """Return (price table, warning). Table is None only when neither a fresh
    fetch nor a cached copy is available -- callers must then emit NO cost
    series at all, never a fabricated zero.
    """
    cached = None
    fresh = False
    try:
        stat = PRICE_CACHE.stat()
        cached = json.loads(PRICE_CACHE.read_text())
        fresh = (time.time() - stat.st_mtime) < PRICE_MAX_AGE_SECONDS
    except (OSError, ValueError):
        pass
    if fresh:
        return cached, None
    try:
        with urllib.request.urlopen(PRICE_URL, timeout=10) as resp:
            data = json.loads(resp.read())
        PRICE_CACHE.parent.mkdir(parents=True, exist_ok=True)
        tmp = PRICE_CACHE.with_suffix(".tmp")
        tmp.write_text(json.dumps(data))
        tmp.replace(PRICE_CACHE)
        return data, None
    except (OSError, ValueError) as exc:
        if cached is not None:
            return cached, f"price fetch failed ({exc}); using cached table"
        return None, f"price fetch failed ({exc}); no cached table, no price table"


def message_cost(price: dict, input_tok: int, output_tok: int, cache_read: int,
                  cache_5m: int, cache_1h: int) -> float:
    rate_1h = price.get("cache_creation_input_token_cost_above_1hr")
    if rate_1h is None:
        # Not every model lists a 1h rate; Anthropic's published pricing sets
        # it at 2x the 5m ephemeral-cache rate.
        rate_1h = 2 * price.get("cache_creation_input_token_cost", 0)
    return (
        input_tok * price.get("input_cost_per_token", 0)
        + output_tok * price.get("output_cost_per_token", 0)
        + cache_read * price.get("cache_read_input_token_cost", 0)
        + cache_5m * price.get("cache_creation_input_token_cost", 0)
        + cache_1h * rate_1h
    )


def load_state(primary: pathlib.Path = STATE, legacy: pathlib.Path = LEGACY_STATE) -> dict:
    # Prefer the current (XDG_STATE_HOME) path; fall back to the legacy
    # .cache path exactly once, so the watermark and totals this fix inherits
    # are not themselves lost by moving where they live. Once save_state runs
    # the state is written back to `primary`, and this fallback stops
    # mattering. (`primary`/`legacy` are parameters, not bare globals, only so
    # selfcheck can exercise the migration without touching the real paths.)
    for path in (primary, legacy):
        try:
            return json.loads(path.read_text())
        except (OSError, ValueError):
            continue
    return {"offsets": {}, "totals": {}}


def save_state(state: dict) -> None:
    STATE.parent.mkdir(parents=True, exist_ok=True)
    tmp = STATE.with_suffix(".tmp")
    tmp.write_text(json.dumps(state))
    tmp.replace(STATE)  # atomic; a torn state file would double-count


GIT_HOME = pathlib.Path.home() / "git"
# Workspace families (AGENTS.local.md). Adding one is an edit here, not a guess.
FAMILIES = frozenset(
    "nix homelab cloud ai cribl docs mlx governance profile visicore".split()
)


def repo_of(rec: dict) -> str:
    """Attribute a record to a repo, resolved against the workspace layout.

    `Path(cwd).name` is WRONG: a worktree lives at `<repo>/main` or
    `<repo>/.worktrees/<name>`, so the basename is the worktree, not the repo —
    measured over real transcripts that lumped 59% of all traffic under a
    single fake repo called "main".

    Resolving against the layout also bounds label cardinality. Raw basenames
    produced 874 values, 829 of which carried under 0.1% each; anything outside
    the workspace now folds into "other" rather than minting a series.
    """
    cwd = rec.get("cwd") or ""
    if not cwd:
        return "unknown"
    try:
        parts = pathlib.PurePath(cwd).relative_to(GIT_HOME).parts
    except ValueError:
        return "other"
    # Current layout groups by family; transcripts predating it are flat, so
    # the family segment is optional and detected rather than assumed.
    if parts[:1] == ("public",):
        rest = parts[1:]
    elif parts[:1] == ("private",) and len(parts) >= 2:
        rest = parts[2:]  # skip <owner>
    else:
        return "other"
    if rest and rest[0] in FAMILIES:
        rest = rest[1:]
    return rest[0] if rest else "other"


def scan_file(path: pathlib.Path, offset: int, bump, set_gauge=lambda *_args: None,
              prices: dict | None = None, last_ts: float | None = None) -> tuple[int, float | None]:
    """Fold new records from `path` into `bump`. Returns (new offset, new last_ts).

    `set_gauge(labels, value, timestamp)` receives the per-kind injected bytes
    once the first request of a file is seen; a file scanned from its start is
    the only time that is knowable, so a mid-file watermark yields nothing.

    Subagent transcripts live in a `subagents/` subdirectory and are the ONLY
    place their usage is recorded — the parent transcript's `isSidechain` is
    false for every record, so it cannot be used for this.

    `last_ts` is this transcript's previous turn timestamp (persisted across
    runs, per path) so a pause spanning two ETL runs is still bucketed.
    """
    kind = "subagent" if path.parent.name == "subagents" else "main"
    size = path.stat().st_size
    if offset > size:  # truncated or rotated; start over
        offset = 0
        last_ts = None
    pre: dict[str, int] | None = {} if offset == 0 else None
    subagent_uncounted = offset == 0 and kind == "subagent"
    # tool_use_id -> tool name, so a later tool_result can be attributed. Reset
    # per file: a result never spans two transcripts, and this dict never
    # needs to survive a run since a partial trailing tool_use with no result
    # yet is simply dropped, not miscounted.
    tool_names: dict[str, str] = {}
    with path.open("r", errors="replace") as fh:
        fh.seek(offset)
        for line in fh:
            if not line.endswith("\n"):  # partial trailing write; leave it
                break
            offset += len(line.encode("utf-8", "replace"))
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            msg_content = (rec.get("message") or {}).get("content")
            if isinstance(msg_content, list):
                for c in msg_content:
                    if not isinstance(c, dict):
                        continue
                    if c.get("type") == "tool_use":
                        tool_id = c.get("id")
                        if isinstance(tool_id, str):
                            tool_names[tool_id] = c.get("name") or "unknown"
                    elif c.get("type") == "tool_result":
                        result_id = c.get("tool_use_id")
                        tool_name = (
                            tool_names.get(result_id, "unknown")
                            if isinstance(result_id, str) else "unknown"
                        )
                        result_content = c.get("content")
                        if result_content is not None:
                            nbytes = len(json.dumps(
                                result_content, separators=(",", ":")).encode("utf-8"))
                            bump(TOOL_RESULT_METRIC, (tool_name, repo_of(rec), kind), nbytes // 4)
            if rec.get("type") == "attachment":
                # Injected context: skill listings, MCP instructions, hook output.
                # This is the only record of what is consuming the window before
                # the conversation itself starts — no counter reports it.
                att = rec.get("attachment") or {}
                # NB: distinct names — reusing `kind`/`size` here silently
                # relabels every later message record in the same file.
                att_kind = att.get("type") or (next(iter(att), "unknown"))
                att_bytes = len(json.dumps(att, separators=(",", ":")).encode("utf-8"))
                ctx = (repo_of(rec), att_kind)
                bump("claude_jsonl_context_injection_bytes_total", ctx, att_bytes)
                bump("claude_jsonl_context_injections_total", ctx, 1)
                if pre is not None:
                    pre[att_kind] = pre.get(att_kind, 0) + att_bytes
                continue

            msg = rec.get("message") or {}
            usage = msg.get("usage")
            if not usage:
                continue
            labels = (msg.get("model") or "unknown", repo_of(rec), kind)
            if pre is not None and msg.get("model") != "<synthetic>":
                ts = rec.get("timestamp") or ""
                for att_kind, nbytes in pre.items():
                    set_gauge((repo_of(rec), kind, att_kind), nbytes, ts)
                pre = None
            if subagent_uncounted:
                bump(SUBAGENT_METRIC, (repo_of(rec),), 1)
                subagent_uncounted = False
            now = _parse_ts(rec.get("timestamp") or "")
            if now is not None:
                if last_ts is not None:
                    bucket = pause_bucket(now - last_ts)
                    if bucket:
                        bump(PAUSE_METRIC, (kind, bucket), 1)
                last_ts = now
            cc = usage.get("cache_creation") or {}
            cache_5m = cc.get("ephemeral_5m_input_tokens", 0)
            cache_1h = cc.get("ephemeral_1h_input_tokens", 0)
            cache_read = usage.get("cache_read_input_tokens", 0)
            input_tok = usage.get("input_tokens", 0)
            output_tok = usage.get("output_tokens", 0)
            bump("claude_jsonl_cache_creation_tokens_total", labels + ("5m",), cache_5m)
            bump("claude_jsonl_cache_creation_tokens_total", labels + ("1h",), cache_1h)
            bump("claude_jsonl_cache_read_tokens_total", labels, cache_read)
            bump("claude_jsonl_input_tokens_total", labels, input_tok)
            bump("claude_jsonl_output_tokens_total", labels, output_tok)
            bump("claude_jsonl_thinking_tokens_total", labels,
                 (usage.get("output_tokens_details") or {}).get("thinking_tokens", 0))
            bump("claude_jsonl_messages_total", labels, 1)
            # Cost only when a price table is available at all -- with none,
            # emit nothing rather than a wall of "unpriced" noise (see
            # load_prices). With a table, a model missing from it is counted
            # as $0 cost but the gap stays visible via the unpriced counter.
            if prices:
                price = prices.get(labels[0])
                if price:
                    bump(COST_METRIC, labels, message_cost(
                        price, input_tok, output_tok, cache_read, cache_5m, cache_1h))
                else:
                    bump(UNPRICED_METRIC, (labels[0],), 1)
    return offset, last_ts


def collect(projects: pathlib.Path, state: dict, prices: dict | None = None) -> dict:
    # int for every counter except COST_METRIC, which needs float precision (USD)
    totals: dict[str, int | float] = dict(state.get("totals", {}))
    gauges: dict[str, list] = dict(state.get("gauges", {}))  # key -> [value, timestamp]

    def bump(metric: str, labels: tuple, value) -> None:
        if not value:
            return
        key = metric + "\x00" + "\x00".join(labels)
        if metric == COST_METRIC:
            totals[key] = totals.get(key, 0.0) + float(value)  # USD needs float precision
        else:
            totals[key] = totals.get(key, 0) + int(value)

    def set_gauge(labels: tuple, value, ts: str) -> None:
        key = BASELINE_METRIC + "\x00" + "\x00".join(labels)
        # Newest session wins, not the last file visited. A record with no
        # timestamp cannot claim to be newer than anything already recorded.
        if key not in gauges or (ts and ts >= gauges[key][1]):
            gauges[key] = [int(value), ts]

    offsets = dict(state.get("offsets", {}))
    last_ts_by_path = dict(state.get("last_ts", {}))
    for path in projects.rglob("*.jsonl"):
        sp = str(path)
        try:
            new_offset, new_last_ts = scan_file(
                path, offsets.get(sp, 0), bump, set_gauge, prices, last_ts_by_path.get(sp))
        except OSError:
            continue
        offsets[sp] = new_offset
        if new_last_ts is not None:
            last_ts_by_path[sp] = new_last_ts
    return {"offsets": offsets, "totals": totals, "gauges": gauges, "last_ts": last_ts_by_path}


def escape(v: str) -> str:
    return v.replace("\\", "\\\\").replace('"', '\\"')


def render(totals: dict, gauges: dict | None = None) -> str:
    by_metric: dict[str, list] = {}
    for key, value in totals.items():
        parts = key.split("\x00")
        by_metric.setdefault(parts[0], []).append((parts[1:], value))
    for key, gauge_entry in (gauges or {}).items():
        value = gauge_entry[0]  # [value, timestamp]; timestamp unused here
        parts = key.split("\x00")
        by_metric.setdefault(parts[0], []).append((parts[1:], value))
    out = []
    for metric in sorted(by_metric):
        is_gauge = metric == BASELINE_METRIC
        out.append(f"# HELP {metric} {METRICS.get(metric, metric)}")
        out.append(f"# TYPE {metric} {'gauge' if is_gauge else 'counter'}")
        for labels, value in sorted(by_metric[metric]):
            if is_gauge:
                names = ["repo", "agent", "kind"]
            elif metric.startswith("claude_jsonl_context_"):
                names = ["repo", "kind"]
            elif metric == TOOL_RESULT_METRIC:
                names = ["tool", "repo", "agent"]
            elif metric == PAUSE_METRIC:
                names = ["agent", "bucket"]
            elif metric == SUBAGENT_METRIC:
                names = ["repo"]
            else:
                names = ["model", "repo", "agent", "ttl"][: len(labels)]
            pairs = list(zip(names, labels))
            # `host` on EVERY series, and it is load-bearing rather than
            # decorative. Each machine runs its own collector with its own
            # watermark and emits its own cumulative totals. Without a label
            # that differs between them, two machines produce the SAME series
            # identity, so each push overwrites the other's value instead of
            # adding to it -- the stored number becomes whichever machine
            # wrote last, and a query summing it oscillates between their two
            # totals rather than climbing. Measured over three hours before
            # this label existed: ~316.4B, 359.2B, 316.6B, 359.6B, 316.7B.
            #
            # That also makes `increase()` meaningless over the merged series,
            # so every panel built on this data was wrong in a way no panel
            # could reveal.
            pairs.append(("host", HOST))
            rendered = ",".join(f'{n}="{escape(v)}"' for n, v in pairs)
            # Cost is a float (USD); %.10g avoids float-sum repr artifacts
            # like 0.0002499999999999999 while staying within Prometheus's
            # accepted number syntax. Everything else stays a plain int.
            value_str = f"{value:.10g}" if isinstance(value, float) else str(value)
            out.append(f"{metric}{{{rendered}}} {value_str}")
    return "\n".join(out) + "\n"


def selfcheck() -> None:
    import tempfile

    with tempfile.TemporaryDirectory() as td:
        root = pathlib.Path(td)
        (root / "repo-a").mkdir()
        (root / "repo-a" / "subagents").mkdir()

        def rec(model, cwd, m5, h1, out_tok, think):
            return json.dumps({
                "cwd": cwd,
                "isSidechain": False,  # false even for real subagent parents
                "message": {"model": model, "usage": {
                    "input_tokens": 1,
                    "cache_read_input_tokens": 100,
                    "output_tokens": out_tok,
                    "output_tokens_details": {"thinking_tokens": think},
                    "cache_creation": {
                        "ephemeral_5m_input_tokens": m5,
                        "ephemeral_1h_input_tokens": h1,
                    },
                }},
            })

        main = root / "repo-a" / "s1.jsonl"
        main.write_text(rec("opus", str(GIT_HOME / "public/homelab/tofu-proxmox/main"), 0, 655, 10, 3) + "\n")
        sub = root / "repo-a" / "subagents" / "agent-1.jsonl"
        sub.write_text(rec("fable", str(GIT_HOME / "public/homelab/tofu-proxmox/.worktrees/deploy"), 20, 0, 5, 0) + "\n")
        unpriced = root / "repo-a" / "s0.jsonl"
        unpriced.write_text(rec("atlas", str(GIT_HOME / "public/homelab/tofu-proxmox/main"), 0, 0, 2, 0) + "\n")

        # "opus" is priced with an explicit 1h rate; "fable" is priced but with
        # NO 1h rate listed, so it must fall back to 2x the 5m rate; "atlas"
        # never appears in the table at all.
        prices = {
            "opus": {
                "input_cost_per_token": 5e-06, "output_cost_per_token": 2.5e-05,
                "cache_read_input_token_cost": 5e-07,
                "cache_creation_input_token_cost": 6.25e-06,
                "cache_creation_input_token_cost_above_1hr": 1e-05,
            },
            "fable": {
                "input_cost_per_token": 1e-06, "output_cost_per_token": 5e-06,
                "cache_read_input_token_cost": 1e-07,
                "cache_creation_input_token_cost": 1.25e-06,
                # no *_above_1hr key
            },
        }

        # no price table at all -> no cost series, ever (never fabricate a $0)
        st_nop = collect(root, {"offsets": {}, "totals": {}}, prices=None)
        assert not any(k.startswith(COST_METRIC) or k.startswith(UNPRICED_METRIC)
                       for k in st_nop["totals"])
        print("selfcheck: no price table -> cost series skipped (as expected)")

        st = collect(root, {"offsets": {}, "totals": {}}, prices=prices)
        t = st["totals"]

        def get(metric, *labels):
            return t.get(metric + "\x00" + "\x00".join(labels), 0)

        # the 5m/1h split survives, keyed separately
        assert get("claude_jsonl_cache_creation_tokens_total", "opus", "tofu-proxmox", "main", "1h") == 655
        assert get("claude_jsonl_cache_creation_tokens_total", "opus", "tofu-proxmox", "main", "5m") == 0
        # subagents are attributed by PATH, not by isSidechain (which is false here)
        assert get("claude_jsonl_cache_creation_tokens_total", "fable", "tofu-proxmox", "subagent", "5m") == 20
        assert get("claude_jsonl_thinking_tokens_total", "opus", "tofu-proxmox", "main") == 3

        # cost is modeled from the price table, per (model, repo, agent) --
        # a priced model with an explicit 1h rate...
        opus_cost = get(COST_METRIC, "opus", "tofu-proxmox", "main")
        assert abs(opus_cost - 0.006855) < 1e-9, opus_cost
        # ...a priced model with NO 1h rate listed, falling back to 2x the 5m rate...
        fable_cost = get(COST_METRIC, "fable", "tofu-proxmox", "subagent")
        assert abs(fable_cost - 0.000061) < 1e-9, fable_cost
        # ...and a model absent from the table entirely: no cost series, but
        # the gap is visible via the unpriced counter, never silent.
        assert get(COST_METRIC, "atlas", "tofu-proxmox", "main") == 0
        assert get(UNPRICED_METRIC, "atlas") == 1

        # incremental: re-running over unchanged files must NOT double-count
        st2 = collect(root, st, prices=prices)
        assert st2["totals"] == t, "re-scan double-counted"

        # appending only adds the new record
        with main.open("a") as fh:
            fh.write(rec("opus", str(GIT_HOME / "public/homelab/tofu-proxmox/main"), 7, 0, 1, 0) + "\n")
        st3 = collect(root, st2, prices=prices)
        assert st3["totals"][
            "claude_jsonl_cache_creation_tokens_total\x00opus\x00tofu-proxmox\x00main\x005m"] == 7

        # a path outside the workspace must fold into "other", never mint a series
        assert repo_of({"cwd": "/tmp/whatever"}) == "other"
        # flat pre-family layout must not resolve to the worktree name
        assert repo_of({"cwd": str(GIT_HOME / "public/terraform-proxmox/main")}) == "terraform-proxmox"
        assert repo_of({"cwd": str(GIT_HOME / "public/homelab/tofu-proxmox/.worktrees/x")}) == "tofu-proxmox"
        assert repo_of({"cwd": str(GIT_HOME / "private/dryvist/nix/nix-ai/main")}) == "nix-ai"
        assert repo_of({}) == "unknown"

        # injected context is measured from attachment records, not messages
        ctx = root / "repo-a" / "s2.jsonl"
        ctx.write_text(json.dumps({
            "type": "attachment", "cwd": str(GIT_HOME / "public/homelab/tofu-proxmox/main"),
            "attachment": {"type": "skill_listing", "body": "x" * 500},
        }) + "\n")
        st4 = collect(root, st3, prices=prices)
        k = "claude_jsonl_context_injection_bytes_total\x00tofu-proxmox\x00skill_listing"
        assert st4["totals"][k] > 500, st4["totals"].get(k)
        assert st4["totals"]["claude_jsonl_context_injections_total\x00tofu-proxmox\x00skill_listing"] == 1
        assert 'kind="skill_listing"' in render(st4["totals"])
        # an attachment must not relabel later messages in the SAME file
        mixed = root / "repo-a" / "s3.jsonl"
        mixed.write_text(
            json.dumps({"type": "attachment",
                        "cwd": str(GIT_HOME / "public/homelab/tofu-proxmox/main"),
                        "attachment": {"type": "skill_listing", "body": "y" * 10}}) + "\n"
            + rec("opus", str(GIT_HOME / "public/homelab/tofu-proxmox/main"), 0, 42, 1, 0) + "\n")
        st5 = collect(root, st4, prices=prices)
        assert st5["totals"].get(
            "claude_jsonl_cache_creation_tokens_total\x00opus\x00tofu-proxmox\x00main\x001h") == 655 + 42, \
            "attachment clobbered the agent label of a later message"
        assert not any("skill_listing" in k for k in st5["totals"]
                       if k.startswith("claude_jsonl_cache_")), "agent label polluted"
        st3 = st5

        # subagent count: the one subagent file written above (agent-1.jsonl)
        # must be counted exactly once, keyed by ITS OWN repo (the worktree,
        # not the parent transcript's)
        assert st3["totals"].get(SUBAGENT_METRIC + "\x00tofu-proxmox") == 1
        # re-scanning must not double-count it
        st3b = collect(root, st3, prices=prices)
        assert st3b["totals"].get(SUBAGENT_METRIC + "\x00tofu-proxmox") == 1
        st3 = st3b

        # tool_result bytes: a tool_use establishes the name, the matching
        # tool_result is attributed to it; an unmatched tool_use_id falls
        # back to "unknown" rather than being dropped
        tool = root / "repo-a" / "s4.jsonl"
        tool.write_text("\n".join([
            json.dumps({"cwd": str(GIT_HOME / "public/homelab/tofu-proxmox/main"),
                        "type": "assistant",
                        "message": {"content": [
                            {"type": "tool_use", "id": "t1", "name": "Bash"}]}}),
            json.dumps({"cwd": str(GIT_HOME / "public/homelab/tofu-proxmox/main"),
                        "type": "user",
                        "message": {"content": [
                            {"type": "tool_result", "tool_use_id": "t1",
                             "content": "x" * 400}]}}),
            json.dumps({"cwd": str(GIT_HOME / "public/homelab/tofu-proxmox/main"),
                        "type": "user",
                        "message": {"content": [
                            {"type": "tool_result", "tool_use_id": "unmatched",
                             "content": "y" * 40}]}}),
        ]) + "\n")
        st6 = collect(root, st3, prices=prices)
        assert st6["totals"].get(
            TOOL_RESULT_METRIC + "\x00Bash\x00tofu-proxmox\x00main") == 100  # 400 bytes / 4
        assert st6["totals"].get(
            TOOL_RESULT_METRIC + "\x00unknown\x00tofu-proxmox\x00main") == 10
        body6 = render(st6["totals"])
        assert 'claude_jsonl_tool_result_tokens_total{tool="Bash",repo="tofu-proxmox",agent="main"' in body6
        st3 = st6

        # pause bucket: a gap under 5m is silent, 5m-60m and over 1h each bump
        # their own bucket, keyed by nothing but the transcript's own prior turn
        assert pause_bucket(60) is None
        assert pause_bucket(299) is None
        assert pause_bucket(300) == "5m_60m"
        assert pause_bucket(3600) == "5m_60m"
        assert pause_bucket(3601) == "over_1h"
        pause = root / "repo-a" / "s5.jsonl"

        def timed_rec(ts, out_tok=1):
            d = json.loads(rec("opus", str(GIT_HOME / "public/homelab/tofu-proxmox/main"), 0, 0, out_tok, 0))
            d["timestamp"] = ts
            return json.dumps(d)

        pause.write_text("\n".join([
            timed_rec("2026-01-01T00:00:00Z"),
            timed_rec("2026-01-01T00:10:00Z"),  # +10m -> 5m_60m
            timed_rec("2026-01-01T02:10:00Z"),  # +2h  -> over_1h
        ]) + "\n")
        st7 = collect(root, st3, prices=prices)
        assert st7["totals"].get(PAUSE_METRIC + "\x00main\x005m_60m") == 1
        assert st7["totals"].get(PAUSE_METRIC + "\x00main\x00over_1h") == 1
        # a pause spanning two separate ETL runs is still caught, via last_ts
        # persisted in state rather than only in-memory during one scan_file call
        with pause.open("a") as fh:
            fh.write(timed_rec("2026-01-01T04:10:00Z") + "\n")  # +2h from prior run
        st8 = collect(root, st7, prices=prices)
        assert st8["totals"].get(PAUSE_METRIC + "\x00main\x00over_1h") == 2
        st3 = st8

        # gauge ordering: an undated record never overwrites a dated one, a
        # dated one overwrites an undated one, and a newer date wins
        probe = {}
        def sg(labels, value, ts):
            key = BASELINE_METRIC + "\x00" + "\x00".join(labels)
            if key not in probe or (ts and ts >= probe[key][1]):
                probe[key] = [int(value), ts]
        sg(("r", "main", "k"), 1, "2026-01-02T00:00:00Z")
        sg(("r", "main", "k"), 2, "")
        assert probe[BASELINE_METRIC + "\x00r\x00main\x00k"][0] == 1, "undated overwrote dated"
        sg(("r", "main", "k"), 3, "2026-01-01T00:00:00Z")
        assert probe[BASELINE_METRIC + "\x00r\x00main\x00k"][0] == 1, "older date overwrote newer"
        sg(("r", "main", "k2"), 4, "")
        sg(("r", "main", "k2"), 5, "2026-01-01T00:00:00Z")
        assert probe[BASELINE_METRIC + "\x00r\x00main\x00k2"][0] == 5, "dated did not replace undated"
        # attachments before the first request are itemized as a gauge; a
        # second request in the same file must not change it
        gk = BASELINE_METRIC + "\x00tofu-proxmox\x00main\x00skill_listing"
        assert st5["gauges"][gk][0] > 10 and st5["gauges"][gk][1] == ""
        body = render(st3["totals"], st5["gauges"])
        assert "# TYPE claude_jsonl_baseline_injection_bytes gauge" in body
        assert (
            'claude_jsonl_baseline_injection_bytes{repo="tofu-proxmox",agent="main",'
            f'kind="skill_listing",host="{HOST}"'
        ) in body
        assert 'ttl="1h"' in body and 'agent="subagent"' in body
        assert "# TYPE claude_jsonl_cache_creation_tokens_total counter" in body
        assert f'{COST_METRIC}{{model="opus",repo="tofu-proxmox",agent="main",host="{HOST}"}}' in body
        assert f'{COST_METRIC}{{model="fable",repo="tofu-proxmox",agent="subagent",host="{HOST}"}}' in body
        # EVERY series carries host, not just the ones spelled out above. Two
        # machines emitting the same label set share one series identity and
        # overwrite each other's cumulative value, so a missing host label here
        # silently corrupts every number downstream while every component
        # reports healthy. Assert it on all of them, counters and gauge alike.
        series = [ln for ln in body.splitlines() if ln and not ln.startswith("#")]
        assert series, "render produced no series to check"
        missing = [ln for ln in series if f'host="{HOST}"' not in ln]
        assert not missing, f"series without a host label: {missing[:3]}"

        # end-to-end: the ETL's rendered totals must match a hand-computed sum
        # over the SAME known transcripts, independent of the ETL's own
        # bump()/render() machinery -- catches exactly the "totals don't match
        # what's on disk" failure mode a live 5000x inflation would trip.
        expected_1h = 655 + 42  # main's two 1h writes: s1.jsonl (655) + mixed s3.jsonl (42)
        expected_5m = 20 + 7    # subagent's 5m write (20) + main's appended 5m write (7)
        got_1h = sum(v for k, v in st3["totals"].items()
                     if k.startswith("claude_jsonl_cache_creation_tokens_total") and k.endswith("\x001h"))
        got_5m = sum(v for k, v in st3["totals"].items()
                     if k.startswith("claude_jsonl_cache_creation_tokens_total") and k.endswith("\x005m"))
        assert got_1h == expected_1h, f"1h total {got_1h} != known transcript sum {expected_1h}"
        assert got_5m == expected_5m, f"5m total {got_5m} != known transcript sum {expected_5m}"

        # state lives under XDG_STATE_HOME, not XDG_CACHE_HOME -- a wipeable
        # cache dir losing this file is the live 5000x-inflation bug (see the
        # STATE/LEGACY_STATE comment): each wipe resets every counter to 0
        # while VictoriaMetrics still holds the pre-wipe value, and
        # Prometheus's increase() adds that whole pre-wipe value back in as a
        # counter-reset compensation.
        assert ".cache" not in STATE.parts, f"counter state must not live under .cache: {STATE}"
        assert ".local" in STATE.parts and "state" in STATE.parts

        # migration: a legacy .cache-path state file is read exactly once
        # when no file exists yet at the new path, so shipping this fix does
        # not itself trigger the reset it exists to prevent.
        mig_new = root / "migrated" / "state.json"
        mig_legacy = root / "legacy" / "state.json"
        mig_legacy.parent.mkdir()
        mig_legacy.write_text(json.dumps({"offsets": {"x": 5}, "totals": {"k": 9}}))
        loaded = load_state(primary=mig_new, legacy=mig_legacy)
        assert loaded == {"offsets": {"x": 5}, "totals": {"k": 9}}, "legacy state not migrated"
        # once the new path exists, it wins over the legacy one
        mig_new.parent.mkdir()
        mig_new.write_text(json.dumps({"offsets": {}, "totals": {"k": 1}}))
        assert load_state(primary=mig_new, legacy=mig_legacy) == {"offsets": {}, "totals": {"k": 1}}
    print("selfcheck OK")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--push", metavar="URL", help="VictoriaMetrics /api/v1/import/prometheus")
    ap.add_argument("--selfcheck", action="store_true")
    ap.add_argument("--dry-run", action="store_true", help="do not persist the watermark")
    args = ap.parse_args()

    if args.selfcheck:
        selfcheck()
        return 0

    prices, price_warning = load_prices()
    if price_warning:
        print(price_warning, file=sys.stderr)
    state = collect(PROJECTS, load_state(), prices)
    body = render(state["totals"], state["gauges"])
    if args.push:
        req = urllib.request.Request(args.push, data=body.encode(), method="POST")
        with urllib.request.urlopen(req, timeout=30) as resp:
            if resp.status >= 300:
                print(f"push failed: {resp.status}", file=sys.stderr)
                return 1
    else:
        sys.stdout.write(body)
    if not args.dry_run:
        save_state(state)  # only after a successful push, so a failure retries
    return 0


if __name__ == "__main__":
    sys.exit(main())
