#!/usr/bin/env python3
"""Emit Prometheus exposition text for what the Claude Code OTEL exporter does not.

Native OTEL gives cost, tokens by coarse type, sessions, tool decisions. It does
NOT give: the 5m vs 1h ephemeral cache split, thinking tokens, per-repo
attribution, or subagent cost. This reads the session transcripts for those.

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
import sys
import urllib.request

PROJECTS = pathlib.Path.home() / ".claude" / "projects"
STATE = pathlib.Path.home() / ".cache" / "claude-jsonl-etl" / "state.json"

# metric -> help text. Counters only; all are monotonic totals.
METRICS = {
    "claude_jsonl_cache_creation_tokens_total": "Cache-creation input tokens, split by ephemeral TTL",
    "claude_jsonl_cache_read_tokens_total": "Cache-read input tokens",
    "claude_jsonl_input_tokens_total": "Uncached input tokens",
    "claude_jsonl_output_tokens_total": "Output tokens",
    "claude_jsonl_thinking_tokens_total": "Thinking tokens (subset of output)",
    "claude_jsonl_messages_total": "Assistant messages seen",
    "claude_jsonl_context_injection_bytes_total": "Bytes of context injected before the conversation (skill listings, MCP instructions, hook output)",
    "claude_jsonl_context_injections_total": "Count of injected-context attachments",
}
# Gauge, not counter: the bytes of each injected kind seen before a session's
# first request, i.e. what the harness front-loads. The exporter's own
# `token.usage` metric gives the first request's TOTAL per session but
# nothing itemizes it; this is the itemization. Latest session per label set.
BASELINE_METRIC = "claude_jsonl_baseline_injection_bytes"


def load_state() -> dict:
    try:
        return json.loads(STATE.read_text())
    except (OSError, ValueError):
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


def scan_file(path: pathlib.Path, offset: int, bump, set_gauge=lambda *a: None) -> int:
    """Fold new records from `path` into `bump`. Returns the new offset.

    `set_gauge(labels, value, timestamp)` receives the per-kind injected bytes
    once the first request of a file is seen; a file scanned from its start is
    the only time that is knowable, so a mid-file watermark yields nothing.

    Subagent transcripts live in a `subagents/` subdirectory and are the ONLY
    place their usage is recorded — the parent transcript's `isSidechain` is
    false for every record, so it cannot be used for this.
    """
    kind = "subagent" if path.parent.name == "subagents" else "main"
    size = path.stat().st_size
    if offset > size:  # truncated or rotated; start over
        offset = 0
    pre: dict[str, int] | None = {} if offset == 0 else None
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
            if rec.get("type") == "attachment":
                # Injected context: skill listings, MCP instructions, hook output.
                # This is the only record of what is consuming the window before
                # the conversation itself starts — no counter reports it.
                att = rec.get("attachment") or {}
                # NB: distinct names — reusing `kind`/`size` here silently
                # relabels every later message record in the same file.
                att_kind = att.get("type") or (next(iter(att), "unknown"))
                att_bytes = len(json.dumps(att, separators=(",", ":")))
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
            cc = usage.get("cache_creation") or {}
            bump("claude_jsonl_cache_creation_tokens_total", labels + ("5m",),
                 cc.get("ephemeral_5m_input_tokens", 0))
            bump("claude_jsonl_cache_creation_tokens_total", labels + ("1h",),
                 cc.get("ephemeral_1h_input_tokens", 0))
            bump("claude_jsonl_cache_read_tokens_total", labels,
                 usage.get("cache_read_input_tokens", 0))
            bump("claude_jsonl_input_tokens_total", labels,
                 usage.get("input_tokens", 0))
            bump("claude_jsonl_output_tokens_total", labels,
                 usage.get("output_tokens", 0))
            bump("claude_jsonl_thinking_tokens_total", labels,
                 (usage.get("output_tokens_details") or {}).get("thinking_tokens", 0))
            bump("claude_jsonl_messages_total", labels, 1)
    return offset


def collect(projects: pathlib.Path, state: dict) -> dict:
    totals: dict[str, int] = dict(state.get("totals", {}))
    gauges: dict[str, list] = dict(state.get("gauges", {}))  # key -> [value, timestamp]

    def bump(metric: str, labels: tuple, value) -> None:
        if not value:
            return
        key = metric + "\x00" + "\x00".join(labels)
        totals[key] = totals.get(key, 0) + int(value)

    def set_gauge(labels: tuple, value, ts: str) -> None:
        key = BASELINE_METRIC + "\x00" + "\x00".join(labels)
        if ts >= gauges.get(key, [0, ""])[1]:  # newest session wins, not last file visited
            gauges[key] = [int(value), ts]

    offsets = dict(state.get("offsets", {}))
    for path in projects.rglob("*.jsonl"):
        sp = str(path)
        try:
            offsets[sp] = scan_file(path, offsets.get(sp, 0), bump, set_gauge)
        except OSError:
            continue
    return {"offsets": offsets, "totals": totals, "gauges": gauges}


def escape(v: str) -> str:
    return v.replace("\\", "\\\\").replace('"', '\\"')


def render(totals: dict, gauges: dict | None = None) -> str:
    by_metric: dict[str, list] = {}
    for key, value in totals.items():
        parts = key.split("\x00")
        by_metric.setdefault(parts[0], []).append((parts[1:], value))
    for key, (value, _ts) in (gauges or {}).items():
        parts = key.split("\x00")
        by_metric.setdefault(parts[0], []).append((parts[1:], value))
    out = []
    for metric in sorted(by_metric):
        is_gauge = metric == BASELINE_METRIC
        out.append(f"# HELP {metric} {METRICS.get(metric, 'Injected-context bytes before the first request, by kind')}")
        out.append(f"# TYPE {metric} {'gauge' if is_gauge else 'counter'}")
        for labels, value in sorted(by_metric[metric]):
            if is_gauge:
                names = ["repo", "agent", "kind"]
            elif metric.startswith("claude_jsonl_context_"):
                names = ["repo", "kind"]
            else:
                names = ["model", "repo", "agent", "ttl"][: len(labels)]
            rendered = ",".join(f'{n}="{escape(v)}"' for n, v in zip(names, labels))
            out.append(f"{metric}{{{rendered}}} {value}")
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

        st = collect(root, {"offsets": {}, "totals": {}})
        t = st["totals"]

        def get(metric, *labels):
            return t.get(metric + "\x00" + "\x00".join(labels), 0)

        # the 5m/1h split survives, keyed separately
        assert get("claude_jsonl_cache_creation_tokens_total", "opus", "tofu-proxmox", "main", "1h") == 655
        assert get("claude_jsonl_cache_creation_tokens_total", "opus", "tofu-proxmox", "main", "5m") == 0
        # subagents are attributed by PATH, not by isSidechain (which is false here)
        assert get("claude_jsonl_cache_creation_tokens_total", "fable", "tofu-proxmox", "subagent", "5m") == 20
        assert get("claude_jsonl_thinking_tokens_total", "opus", "tofu-proxmox", "main") == 3

        # incremental: re-running over unchanged files must NOT double-count
        st2 = collect(root, st)
        assert st2["totals"] == t, "re-scan double-counted"

        # appending only adds the new record
        with main.open("a") as fh:
            fh.write(rec("opus", str(GIT_HOME / "public/homelab/tofu-proxmox/main"), 7, 0, 1, 0) + "\n")
        st3 = collect(root, st2)
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
        st4 = collect(root, st3)
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
        st5 = collect(root, st4)
        assert st5["totals"].get(
            "claude_jsonl_cache_creation_tokens_total\x00opus\x00tofu-proxmox\x00main\x001h") == 655 + 42, \
            "attachment clobbered the agent label of a later message"
        assert not any("skill_listing" in k for k in st5["totals"]
                       if k.startswith("claude_jsonl_cache_")), "agent label polluted"
        st3 = st5

        # attachments before the first request are itemized as a gauge; a
        # second request in the same file must not change it
        gk = BASELINE_METRIC + "\x00tofu-proxmox\x00main\x00skill_listing"
        assert st5["gauges"][gk][0] > 10 and st5["gauges"][gk][1] == ""
        body = render(st3["totals"], st5["gauges"])
        assert "# TYPE claude_jsonl_baseline_injection_bytes gauge" in body
        assert 'claude_jsonl_baseline_injection_bytes{repo="tofu-proxmox",agent="main",kind="skill_listing"}' in body
        assert 'ttl="1h"' in body and 'agent="subagent"' in body
        assert "# TYPE claude_jsonl_cache_creation_tokens_total counter" in body
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

    state = collect(PROJECTS, load_state())
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
