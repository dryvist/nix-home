#!/usr/bin/env bash
# Negative-first test suite for gh-guard. Every case asserts the guard FIRES;
# a passing clean command proves nothing on its own.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# GH_GUARD_BIN lets a post-install run target the installed PATH shim
# instead of the checked-out script; unset, it falls back to the sibling
# scripts/ copy (used at build/dev time).
GUARD="${GH_GUARD_BIN:-$HERE/../scripts/gh-guard.sh}"

export GH_GUARD_REAL_GH="$HERE/fakegh"
export GH_GUARD_DENYLIST="$HERE/deny.txt"
export GH_GUARD_LOG="$HERE/decisions.log"
: >"$GH_GUARD_LOG"

LEAK="node-alpha-7 is unreachable"
NARR="The outage began at 04:00; root cause was a failed token scope on the app install."
CLEAN="fix(auth): correct refresh interval"

pass=0; fail=0

# Asserts BOTH the exit code and the tier that fired. Exit code alone lets a
# case pass for the wrong reason — e.g. an identifier test that actually
# blocked on unresolved visibility.
check3() { # name expect_rc expect_tier
  local name="$1" want_rc="$2" want_tier="$3" rc tier
  shift 3
  : >"$GH_GUARD_LOG"
  "$GUARD" "$@" >/dev/null 2>&1; rc=$?
  tier="$(awk -F'\t' 'END{print $2}' "$GH_GUARD_LOG" 2>/dev/null)"
  if [ "$rc" -eq "$want_rc" ] && [ "${tier:-none}" = "$want_tier" ]; then
    printf 'PASS  %-38s [%s]\n' "$name" "$want_tier"; pass=$((pass + 1))
  else
    printf 'FAIL  %-38s expected rc=%s tier=%s, got rc=%s tier=%s\n' \
      "$name" "$want_rc" "$want_tier" "$rc" "${tier:-none}"; fail=$((fail + 1))
  fi
}

printf '%s\n' "$LEAK" >"$HERE/leak.md"
# The shell expands this BEFORE the guard runs — the case a static
# command-string parser structurally cannot see.
BODY="$(cat "$HERE/leak.md")"

# --- identifier tier: must block, and must block AS the identifier tier --
check3 "identifier via --body"          1 identifier issue create -R dryvist/pub --body "$LEAK"
check3 "identifier via --body=inline"   1 identifier issue create -R dryvist/pub --body="$LEAK"
check3 "identifier via --body-file"     1 identifier issue create -R dryvist/pub --body-file "$HERE/leak.md"
check3 "identifier via -F"              1 identifier pr create -R dryvist/pub -F "$HERE/leak.md"
check3 "identifier via \$BODY expansion" 1 identifier issue create -R dryvist/pub --body "$BODY"
check3 "identifier via gh api -f"       1 identifier api -X POST repos/dryvist/pub/issues -f body="$LEAK"

# --- visibility tier ----------------------------------------------------
check3 "unresolvable visibility"        1 visibility issue create --body "$CLEAN"

# --- narrative tier: a reachable judge must return an actual verdict -----
check3 "narrative -> judge blocks"      1 narrative issue create -R dryvist/pub --body "$NARR"

# --- must pass through --------------------------------------------------
check3 "non-publish verb"               0 none pr list -R dryvist/pub
check3 "clean body on public repo"      0 clean issue create -R dryvist/pub --body "$CLEAN"
check3 "private repo not screened"      0 none issue create -R dryvist/privaterepo --body "$LEAK"

# --- fail-closed when the judge is genuinely absent ---------------------
GH_GUARD_JUDGE_URL="http://127.0.0.1:9/nope" \
  check3 "judge absent -> fail closed"  1 judge-unavailable issue create -R dryvist/pub --body "$NARR"

# --- calibrated classes: private host addresses -------------------------
# Derived from measuring 102 real bodies in the two topology-heavy repos.
check3 "private host addr 10.x"         1 identifier issue create -R dryvist/pub --body "host 10.4.7.22 is down"
check3 "private host addr 172.16-31"    1 identifier issue create -R dryvist/pub --body "reached 172.20.3.9 ok"
check3 "private host addr 192.168.x"    1 identifier issue create -R dryvist/pub --body "gateway 192.168.7.1"
# Calibration's key finding: leaks arrive inside PASTED EVIDENCE (transcripts,
# tables, repro blocks), not composed prose. Quoted output must be scanned at
# full strength, never down-weighted as "just logs".
PASTED="$(printf 'command output follows:\n    PING 10.9.9.9: 56 data bytes\n    request timed out\n')"
check3 "identifier in pasted output"    1 identifier issue create -R dryvist/pub --body "$PASTED"

# --- MUST NOT block: measured false-positive traps ----------------------
# A CIDR range describes policy, not a host. Placeholder and doc ranges,
# semver, ports, and issue refs all collided with naive rules in the corpus.
check3 "CIDR range is policy not host"  0 clean issue create -R dryvist/pub --body "allow 10.0.0.0/8 in the firewall rule"
check3 "documented placeholder block"   0 clean issue create -R dryvist/pub --body "use 192.168.0.10 as the placeholder"
check3 "semver is not an address"       0 clean issue create -R dryvist/pub --body "bump to v1.24.3 and 10.2.1 tooling"
check3 "ports and issue refs"           0 clean issue create -R dryvist/pub --body "closes #1771, exposes :8088 and :49152"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
