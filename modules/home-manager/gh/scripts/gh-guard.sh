#!/usr/bin/env bash
# gh-guard — publish-boundary gate for the gh CLI.
#
# Installed on PATH as `gh`, ahead of the real binary. Inspects RESOLVED argv,
# stdin, and referenced files at exec time, so it sees content a static
# command-string parser cannot: BODY="$(...)", heredocs, --body-file, --input -.
#
# Two tiers, both fully automated. No `ask`, no human, no override:
#   1. identifiers  -> deterministic regex, blocks, no bypass
#   2. narrative    -> local on-machine judge, blocks on its verdict
#
# Fails CLOSED everywhere: unresolvable visibility, unreachable judge, or a
# verdict outside {allow,block} all block.

set -euo pipefail

# MUST be an absolute path. The shim is installed on PATH *as* `gh`, so a bare
# "gh" here would re-invoke the shim and recurse forever. Nix bakes the real
# store path in at build time; the env var exists for tests.
GH_REAL="${GH_GUARD_REAL_GH:-/etc/profiles/per-user/jevans/bin/gh}"

# Recursion backstop in case GH_REAL is ever misconfigured to point at us.
if [ -n "${GH_GUARD_ACTIVE:-}" ]; then exec "$GH_REAL" "$@"; fi
export GH_GUARD_ACTIVE=1
DENYLIST="${GH_GUARD_DENYLIST:-$HOME/.config/gh-guard/identifiers.txt}"
ALLOWLIST="${GH_GUARD_ALLOWLIST:-$HOME/.config/gh-guard/allowed.txt}"
JUDGE_URL="${GH_GUARD_JUDGE_URL:-http://127.0.0.1:11434/v1/chat/completions}"
# Must name a RESIDENT (ttl=0, non-swappable) model. A swap-class model is
# evicted or TTL-expired mid-scan, and llama-swap answers 429 for the whole
# cold load, which outlasts the retry budget below and fails the gate closed.
# Every host carries the "judge" alias on its own resident model.
JUDGE_MODEL="${GH_GUARD_JUDGE_MODEL:-judge}"
LOG="${GH_GUARD_LOG:-$HOME/.local/state/gh-guard/decisions.log}"

# ---------------------------------------------------------------- logging ---
# Records the RULE that fired, never the matched string: quoting the match
# would re-leak the value into a log file.
audit() { # tier verdict repo verb
  mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" "${3:-?}" "${4:-?}" >>"$LOG" 2>/dev/null || true
}

die() { # tier repo verb message
  audit "$1" BLOCK "$2" "$3"
  printf 'gh-guard: BLOCKED (%s tier)\n\n%s\n\n' "$1" "$4" >&2
  printf 'This artifact targets a PUBLIC repository. Public text states WHAT,\n' >&2
  printf 'never why, what broke, or internal topology. Route incident narrative\n' >&2
  printf 'to Zammad and follow-ups to Vikunja.\n' >&2
  exit 1
}

# ------------------------------------------------------------ verb triage ---
# Anything not a publish verb execs straight through with zero added latency.
is_publish_verb() {
  case "${1:-}" in
    issue|pr)
      case "${2:-}" in create|edit|comment) return 0 ;; esac ;;
    release)
      case "${2:-}" in create|edit) return 0 ;; esac ;;
    gist)
      case "${2:-}" in create) return 0 ;; esac ;;
    repo)
      case "${2:-}" in edit) return 0 ;; esac ;;
    api) return 0 ;;   # inspected further below
  esac
  return 1
}

# `gh api` only matters when it MUTATES an issue/PR/comment surface.
api_is_publish() {
  local method="" path="" mutating=0 graphql=0 a
  for a in "$@"; do
    case "$a" in
      -X|--method) method="NEXT" ;;
      POST|PATCH|PUT) [ "$method" = "NEXT" ] && { mutating=1; method=""; } ;;
      graphql) graphql=1 ;;
      */issues|*/issues/*|*/pulls|*/pulls/*|*/comments|*/comments/*) path="$a" ;;
    esac
  done
  # A body/field flag on graphql implies a mutation payload we must inspect.
  [ "$graphql" = 1 ] && return 0
  [ -n "$path" ] && { [ "$mutating" = 1 ] && return 0; }
  return 1
}

# ------------------------------------------------- content reconstruction ---
# Collects every channel a body can arrive through. This is the whole point of
# the shim: by the time we run, "$BODY" has already been expanded by the shell.
collect_content() {
  local out="" next="" a v
  for a in "$@"; do
    if [ -n "$next" ]; then
      case "$next" in
        literal) out+="$a"$'\n' ;;
        file)
          if [ "$a" = "-" ]; then
            out+="$(cat)"$'\n'
          elif [ -r "$a" ]; then
            out+="$(cat -- "$a")"$'\n'
          fi ;;
        field) out+="${a#*=}"$'\n' ;;
      esac
      next=""; continue
    fi
    case "$a" in
      --body|-b|--title|-t|--notes|--description) next="literal" ;;
      --body-file|-F|--notes-file|--input) next="file" ;;
      -f|--raw-field) next="field" ;;
      --body=*|--title=*|--notes=*|--description=*) out+="${a#*=}"$'\n' ;;
      --body-file=*|--notes-file=*|--input=*)
        v="${a#*=}"
        if [ "$v" = "-" ]; then out+="$(cat)"$'\n'
        elif [ -r "$v" ]; then out+="$(cat -- "$v")"$'\n'; fi ;;
    esac
  done
  # Body piped with no explicit flag (e.g. `... --input -` already handled;
  # this catches `printf ... | gh api ... --input -` variants and heredocs).
  if [ -z "$out" ] && [ ! -t 0 ]; then out+="$(cat)"$'\n'; fi
  printf '%s' "$out"
}

# --------------------------------------------------- repo + visibility ------
resolve_repo() {
  local next="" a
  for a in "$@"; do
    if [ -n "$next" ]; then printf '%s' "$a"; return 0; fi
    case "$a" in
      -R|--repo) next=1 ;;
      --repo=*) printf '%s' "${a#*=}"; return 0 ;;
    esac
  done
  # `gh api repos/OWNER/REPO/...` names its target in the path, not via -R.
  for a in "$@"; do
    case "$a" in
      repos/*/*)
        a="${a#repos/}"
        printf '%s/%s' "${a%%/*}" "$(x="${a#*/}"; printf '%s' "${x%%/*}")"
        return 0 ;;
    esac
  done
  [ -n "${GH_REPO:-}" ] && { printf '%s' "$GH_REPO"; return 0; }
  git rev-parse --show-toplevel >/dev/null 2>&1 || return 1
  "$GH_REAL" repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || return 1
}

# UNKNOWN must block. The pre-existing Write/Edit guard returns "not public" on
# an unresolved lookup and therefore silently never fires; that polarity is the
# bug this inverts.
#
# Auth note: interactively, the zsh `gh` function mints a token and re-execs via
# `command gh`, so GITHUB_TOKEN is already set by the time we run. In a
# non-interactive shell (Claude Code's Bash tool, scripts, cron) no function is
# loaded and no token exists, so mint one here — otherwise every lookup returns
# UNKNOWN and the gate blocks everything, which reads as "broken" and gets it
# disabled. Owner is parseable without auth, so there is no chicken-and-egg.
repo_is_public() {
  local repo="$1" vis tok
  if [ -z "${GITHUB_TOKEN:-}${GH_TOKEN:-}" ] && command -v openbao-github-creds >/dev/null 2>&1; then
    tok="$(openbao-github-creds token read "${repo%%/*}" 2>/dev/null)" || tok=""
    [ -n "$tok" ] && export GITHUB_TOKEN="$tok"
  fi
  vis="$("$GH_REAL" repo view "$repo" --json visibility -q .visibility 2>/dev/null)" || return 0
  case "$vis" in
    PUBLIC) return 0 ;;
    PRIVATE|INTERNAL) return 1 ;;
    *) return 0 ;;   # unknown -> screen it
  esac
}

# ------------------------------------------------------------- detectors ---
# Tier 1, part A: exact identifiers from the PRIVATE layer (apex domain, internal
# zone label, physical node names, workstation names, live VMIDs). Calibration
# against 102 real bodies from the two worst-subject-matter repos measured 0%
# false positives and full recall on every hard identifier leak in the corpus.
# These are real values, which is exactly why this file cannot ship in a public
# repo next to this script.
#
# ALLOWLIST first: some literals on the real domain are deliberately public (the
# docs site host), and must not block legitimate cross-references.
hits_denylist() {
  local content="$1" stripped="$1"
  [ -r "$DENYLIST" ] || return 1
  if [ -r "$ALLOWLIST" ]; then
    stripped="$(grep -vFf <(grep -vE '^[[:space:]]*(#|$)' "$ALLOWLIST") <<<"$content" || true)"
  fi
  grep -qiFf <(grep -vE '^[[:space:]]*(#|$)' "$DENYLIST") <<<"$stripped"
}

# Tier 1, part B: the one generic pattern worth running — a private HOST address.
# Zero false positives observed across the corpus. A CIDR *range* (prefix < 32)
# describes policy rather than naming a host, so it stays legitimate; the
# documented placeholder block is likewise excluded.
# NOTE: -q must NOT be combined with -o here — -q suppresses the very output the
# exclusion filter downstream needs, so the whole pattern silently never fires.
hits_private_host_addr() {
  local found
  found="$(grep -oE '(10\.([0-9]{1,3}\.){2}[0-9]{1,3}(/[0-9]{1,2})?)|(172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?)|(192\.168\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?)' <<<"$1" || true)"
  [ -n "$found" ] || return 1
  # Drop CIDR ranges (policy, not a host) and the documented placeholder block.
  found="$(grep -vE '/[0-9]{1,2}$' <<<"$found" | grep -vE '^192\.168\.0\.' || true)"
  [ -n "$found" ]
}

hits_identifier() {
  hits_denylist "$1" && return 0
  hits_private_host_addr "$1" && return 0
  return 1
}

# Tier 2 prescreen: cheap keyword pass. Only a hit here pays for the judge, so
# the common clean path costs no model call at all.
smells_narrative() {
  grep -qiE '\b(outage|root cause|blast radius|postmortem|incident|regression|broke|broken|degraded|unavailable|failed over|credential|token scope|app install|approle|default password|rotate[d]? the)\b' <<<"$1"
}

# Local judge. On-machine only: its input IS the candidate disclosure, so a
# cloud call would perform the very leak this gate prevents.
# The local server serializes requests and answers a concurrent call with
# {"error":"Too many requests"}. That is transient, not a screening failure, so
# retry briefly before falling through to fail-closed — otherwise an unrelated
# local inference job would block every commit and the gate dies of fatigue.
judge_verdict() {
  local content="$1" payload result verdict attempt
  payload="$(jq -n --arg m "$JUDGE_MODEL" --arg c "$content" '{
    model:$m, max_tokens:4, temperature:0,
    messages:[
      {role:"system",content:"You screen text that is about to be published to a PUBLIC GitHub repository.\nAnswer with exactly one word: \"block\" or \"allow\".\n\nAnswer \"block\" if the text contains ANY of:\n- why something broke, failed, or was fixed (incident/outage/root-cause narrative)\n- internal system topology: clusters, nodes, voters, leaders, VLANs, ports, hosts\n- hostnames, IP addresses, or internal service names\n- credential detail: token/policy/role scope, TTLs, where a secret is stored\n\nAnswer \"allow\" only if the text merely states WHAT changed, with no operational detail: feature descriptions, dependency bumps, docs edits, config field names.\n\nExamples:\nText: \"Adds a retry to the upload helper and bumps the client to 2.1.\" -> allow\nText: \"The node lost quorum because the leader was fenced, so writes stalled.\" -> block\nText: \"The role grants read on the secret mount with a 30 minute TTL.\" -> block\nText: \"chore(deps): update the lockfile.\" -> allow\n\nOne word only."},
      {role:"user",content:$c}]}')" || return 1

  for attempt in 1 2 3 4 5; do
    result="$(curl -sS --max-time 60 -H 'content-type: application/json' \
              -d "$payload" "$JUDGE_URL" 2>/dev/null)" || { sleep 2; continue; }
    case "$result" in
      *'Too many requests'*|'') sleep $((attempt * 2)); continue ;;
    esac
    verdict="$(jq -r '.choices[0].message.content // empty' <<<"$result" 2>/dev/null)"
    verdict="$(tr '[:upper:]' '[:lower:]' <<<"${verdict:-}" | tr -d '[:space:]')"
    case "$verdict" in
      allow) return 0 ;;
      block) return 2 ;;
      *) return 1 ;;   # a reachable judge giving nonsense is a real failure
    esac
  done
  return 1   # exhausted retries: unscreenable -> caller fails closed
}

# ------------------------------------------------------------------ main ---
# `--scan FILE` screens arbitrary text against the same two tiers and exits
# 0 (clean) or 1 (blocked). This is the entry point for git's commit-msg and
# pre-push hooks: `gh` is not involved in a commit, but the content discipline
# is identical, so both callers share ONE detection implementation rather than
# drifting copies. Repo/visibility comes from the cwd's origin remote.
if [ "${1:-}" = "--scan" ]; then
  [ -r "${2:-}" ] || { printf 'gh-guard: --scan needs a readable file\n' >&2; exit 2; }
  SCAN_CONTENT="$(cat -- "$2")"
  SCAN_REPO="$(resolve_repo || true)"
  [ -z "$SCAN_REPO" ] && die visibility "?" "git" \
    "Cannot resolve this repository, so its visibility is unknown."
  repo_is_public "$SCAN_REPO" || exit 0
  hits_identifier "$SCAN_CONTENT" && die identifier "$SCAN_REPO" "git" \
    "Content matches a known internal identifier. There is no override for this tier."
  if smells_narrative "$SCAN_CONTENT"; then
    set +e; judge_verdict "$SCAN_CONTENT"; rc=$?; set -e
    case "$rc" in
      0) : ;;
      2) die narrative "$SCAN_REPO" "git" "The local judge classified this as operational-security narrative." ;;
      *) die judge-unavailable "$SCAN_REPO" "git" "The local judge is unreachable; fail-closed by design." ;;
    esac
  fi
  audit clean ALLOW "$SCAN_REPO" "git"
  exit 0
fi

if ! is_publish_verb "${1:-}" "${2:-}"; then exec "$GH_REAL" "$@"; fi
if [ "${1:-}" = "api" ] && ! api_is_publish "$@"; then exec "$GH_REAL" "$@"; fi

VERB="${1:-}${2:+ $2}"
REPO="$(resolve_repo "$@" || true)"

[ -z "$REPO" ] && die visibility "?" "$VERB" \
  "Cannot resolve the target repository, so its visibility is unknown. Pass -R OWNER/REPO, or run from inside the repo."

repo_is_public "$REPO" || exec "$GH_REAL" "$@"

CONTENT="$(collect_content "$@")"
[ -z "$CONTENT" ] && exec "$GH_REAL" "$@"

hits_identifier "$CONTENT" && die identifier "$REPO" "$VERB" \
  "Content matches a known internal identifier (hostname, address, node, or domain). There is no override for this tier."

if smells_narrative "$CONTENT"; then
  set +e; judge_verdict "$CONTENT"; rc=$?; set -e
  case "$rc" in
    0) : ;;
    2) die narrative "$REPO" "$VERB" "The local judge classified this as operational-security narrative." ;;
    *) die judge-unavailable "$REPO" "$VERB" \
         "The local judge is unreachable or returned an unusable verdict, so this cannot be screened. Fail-closed by design: start the local model server and retry." ;;
  esac
fi

audit clean ALLOW "$REPO" "$VERB"
exec "$GH_REAL" "$@"
