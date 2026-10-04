#!/usr/bin/env bash
# gh-guard — publish-boundary gate for the gh CLI.
#
# Installed on PATH as `gh`, ahead of the real binary. Inspects RESOLVED argv,
# stdin, and referenced files at exec time, so it sees content a static
# command-string parser cannot: BODY="$(...)", heredocs, --body-file, --input -.
#
# Publish requests require an active per-repository OpenBao claim before content
# screening. The two content tiers are fully automated; no `ask` or override:
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
DENYLIST="${GH_GUARD_DENYLIST:-${GH_GUARD_DENYLIST_DEFAULT:-$HOME/.config/gh-guard/identifiers.txt}}"
ALLOWLIST="${GH_GUARD_ALLOWLIST:-$HOME/.config/gh-guard/allowed.txt}"
LIMITS_FILE="${MLX_RESIDENT_MODEL_LIMITS_FILE:-$HOME/.config/mlx/resident-model-limits.json}"
# The `judge` alias selects the resident fast model.
JUDGE_MODEL="${GH_GUARD_JUDGE_MODEL:-judge}"
LOG="${GH_GUARD_LOG:-$HOME/.local/state/gh-guard/decisions.log}"

if [ ! -r "$DENYLIST" ] || [ ! -f "$DENYLIST" ]; then
  printf '%s\n' \
    'gh-guard: WARNING: identifier file is missing or unreadable; exact identifier checks are unavailable. Private-shape screening and the narrative judge remain active.' \
    >&2
fi

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
# Auth: the lookup uses the GH_TOKEN / GITHUB_TOKEN the caller already exported
# for the gh command itself. With neither set the lookup is UNKNOWN and the
# text is screened.
repo_is_public() {
  local repo="$1" vis
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
  [ -r "$DENYLIST" ] && [ -f "$DENYLIST" ] || return 2
  if [ -r "$ALLOWLIST" ]; then
    stripped="$(grep -vFf <(grep -vE '^[[:space:]]*(#|$)' "$ALLOWLIST") <<<"$content" || true)"
  fi
  grep -qiFf <(grep -vE '^[[:space:]]*(#|$)' "$DENYLIST") <<<"$stripped"
}

# Tier 1, part B: private-name shapes are deterministic identifiers too. The
# judge must never decide whether an internal-only suffix names a private host.
hits_private_hostname() {
  grep -qiE '(^|[^[:alnum:]_-])([[:alnum:]][[:alnum:]-]*\.)+(internal|lan|local|corp)([^[:alnum:]_-]|$)|(^|[^[:alnum:]_-])([[:alnum:]][[:alnum:]-]*\.)+home\.arpa([^[:alnum:]_-]|$)' <<<"$1"
}

# Tier 1, part C: reject private host addresses, including shared, loopback,
# and link-local ranges. CIDR policy ranges remain allowed; host routes (/32 or
# /128) are addresses. Python's stdlib parser handles compressed IPv6 safely.
hits_private_host_addr() {
  local rc
  if python3 -c '
import ipaddress
import re
import sys

text = sys.stdin.read()
tokens = re.compile(
    r"(?<![A-Za-z0-9_.])(?:[0-9]{1,3}(?:\.[0-9]{1,3}){3}|[0-9A-Fa-f:.]{2,})"
    r"(?:/[0-9]{1,3})?(?![A-Za-z0-9_.])"
)
private_v4 = tuple(map(ipaddress.ip_network, (
    "0.0.0.0/8", "10.0.0.0/8", "100.64.0.0/10", "127.0.0.0/8",
    "169.254.0.0/16", "172.16.0.0/12", "192.168.0.0/16",
)))
private_v6 = tuple(map(ipaddress.ip_network, (
    "::/128", "::1/128", "fc00::/7", "fe80::/10",
)))

for token in tokens.findall(text):
    address_text, slash, prefix_text = token.partition("/")
    try:
        address = ipaddress.ip_address(address_text)
        if slash and int(prefix_text) < address.max_prefixlen:
            continue
    except ValueError:
        continue
    if isinstance(address, ipaddress.IPv6Address):
        address = address.ipv4_mapped or address
    networks = private_v4 if address.version == 4 else private_v6
    if any(address in network for network in networks):
        sys.exit(0)
sys.exit(1)
' <<<"$1"
  then
    return 0
  else
    rc=$?
    [ "$rc" -eq 1 ] && return 1
    return 2
  fi
}

hits_identifier() {
  local rc
  if hits_denylist "$1"; then return 0; else rc=$?; fi
  [ "$rc" -eq 1 ] || return 2
  if hits_private_hostname "$1"; then return 0; else rc=$?; fi
  [ "$rc" -eq 1 ] || return 2
  hits_private_host_addr "$1"
}

screen_identifiers() { # content repo verb
  local rc
  if hits_identifier "$1"; then
    die identifier "$2" "$3" \
      "Content matches a known internal identifier or private target shape. There is no override for this tier."
  else
    rc=$?
  fi
  [ "$rc" -eq 1 ] || die identifier "$2" "$3" \
    "The deterministic identifier tier is unavailable; failing closed."
}

# Tier 2 prescreen: screens OUT, not in. A missed keyword must never let
# narrative content bypass the judge, so the default is to consult it.
# Only content matching this NARROW allowlist of recognizably-trivial shapes
# skips the judge — everything else falls through to judge_verdict
# unconditionally. This is deliberately conservative: a false trip to the
# judge costs one local model call, a false skip costs a permanent public
# disclosure, and those costs are not symmetric.
#
# The one shape allowed through: a single-line, Renovate/Dependabot-style
# dependency bump ("bump X from A to B" / "chore(deps): bump X from A to B").
# That is the bulk of ordinary publish-verb traffic and it has no room for
# narrative, topology, or credential detail — anything else, including a
# bump line with extra prose attached, falls through to the judge.
allows_trivial_fastpath() {
  local content="$1"
  [ "$(grep -c . <<<"$content")" -le 1 ] || return 1
  grep -qiE '^(chore(\(deps[a-zA-Z0-9_.-]*\))?: )?bumps? [][[:alnum:]/_.@-]+ from [[:alnum:]._+-]+ to [[:alnum:]._+-]+\.?$' <<<"$content"
}

# Local judge. On-machine only: its input IS the candidate disclosure, so a
# cloud call would perform the very leak this gate prevents.
# The local server serializes requests and answers a concurrent call with
# {"error":"Too many requests"}. That is transient, not a screening failure, so
# retry briefly before falling through to fail-closed — otherwise an unrelated
# local inference job would block every commit and the gate dies of fatigue.
judge_verdict() {
  local content="$1" payload result verdict attempt config judge_url judge_timeout deadline remaining delay

  if [[ -f "$LIMITS_FILE" ]]; then
    config="$(jq -er '
      .clients.ghGuard as $client
      | select(
          ($client.url | type) == "string"
          and ($client.timeoutSeconds | type) == "number"
          and $client.timeoutSeconds > 0
          and ($client.timeoutSeconds % 1) == 0
        )
      | "\($client.url)\t\($client.timeoutSeconds|tostring)"
    ' "$LIMITS_FILE")" || return 1
    IFS=$'\t' read -r judge_url judge_timeout <<< "$config"
  else
    judge_url="http://127.0.0.1:11434/v1/chat/completions"
    judge_timeout=30
  fi
  judge_url="${GH_GUARD_JUDGE_URL:-$judge_url}"
  judge_timeout="${GH_GUARD_JUDGE_TIMEOUT:-$judge_timeout}"
  [[ "$judge_url" =~ ^http://(127\.0\.0\.1|localhost):[0-9]+/ ]] || return 1
  [[ "$judge_timeout" =~ ^[1-9][0-9]*$ ]] || return 1

  payload="$(jq -n --arg m "$JUDGE_MODEL" --arg c "$content" '{
    model:$m, max_tokens:4, temperature:0,
    messages:[
      {role:"system",content:"You screen text that is about to be published to a PUBLIC GitHub repository.\nAnswer with exactly one word: \"block\" or \"allow\". Judge the meaning of the content, not its formatting or presentation: prose, a table, a bulleted list, a fenced code block, a diff block, and an ASCII or arrow diagram all disclose exactly as much as each other when they carry the same information -- placing a value inside a fence, a diagram, or a diff does not make it safe. Judge by what a value IS, not by whether the surrounding text sounds routine -- housekeeping language does not make a disclosed internal name safe.\n\nAnswer \"block\" only when the text contains an ACTUAL INSTANCE of one of the categories below: a real cause, name, value, or reasoning about one. A bare LABEL for a category -- a heading, a section title, an index entry, or a rule/policy description that names the category by word without stating any instance of it -- discloses nothing and must be \"allow\", even when it uses the same words as a category below. If the text explains, argues, or reasons about a real situation -- even briefly, even without alarm words -- that is an instance, not a label.\n\nAnswer \"block\" if the text discloses an instance of ANY of:\n- why something broke, failed, was fixed, or was decided (incident/outage/root-cause/rationale narrative)\n- internal system topology: clusters, nodes, voters, leaders, VLANs, ports, hosts\n- hostnames, IP addresses, or internal service names, including one disclosed only by stating what real value something was renamed from or replaced with\n- credential detail: token/policy/role scope, TTLs, where a secret is stored\n\nAnswer \"allow\" if the text merely states WHAT changed with no operational detail (feature descriptions, dependency bumps, docs edits, config field names), or merely labels one of the categories above without disclosing a real instance of it.\n\nExamples:\nText: \"Adds a retry to the upload helper and bumps the client to 2.1.\" -> allow\nText: \"The node lost quorum because the leader was fenced, so writes stalled.\" -> block\nText: \"The role grants read on the secret mount with a 30 minute TTL.\" -> block\nText: \"chore(deps): update the lockfile.\" -> allow\nText: \"This cleanup renamed db-node-3 to db-example throughout the fixtures.\" -> block\nText: \"This runbook template has sections for Root Cause, Credential Scope, and Topology -- fill each in during a real incident.\" -> allow\n\nOne word only."},
      {role:"user",content:$c}]}')" || return 1

  deadline=$(( $(date +%s) + judge_timeout ))
  attempt=1
  while :; do
    remaining=$(( deadline - $(date +%s) ))
    (( remaining > 0 )) || return 1
    result="$(curl -sS --max-time "$remaining" -H 'content-type: application/json' \
              -d "$payload" "$judge_url" 2>/dev/null)" || result=""
    # An error body (429/503 from the proxy, or the local server) is transient.
    case "$result" in
      *'Too many requests'*|'') ;;
      *)
        if jq -e 'type == "object" and has("error")' <<<"$result" >/dev/null 2>&1; then
          :
        else
          verdict="$(jq -r '.choices[0].message.content // empty' <<<"$result" 2>/dev/null)"
          verdict="$(tr '[:upper:]' '[:lower:]' <<<"${verdict:-}" | tr -d '[:space:]')"
          case "$verdict" in
            allow) return 0 ;;
            block) return 2 ;;
            *) return 1 ;;   # a reachable judge giving nonsense is a real failure
          esac
        fi
        ;;
    esac
    remaining=$(( deadline - $(date +%s) ))
    (( remaining > 0 )) || return 1
    delay=$(( attempt * 2 ))
    (( delay > 10 )) && delay=10
    (( delay > remaining )) && delay=$remaining
    sleep "$delay"
    attempt=$(( attempt + 1 ))
  done
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
  screen_identifiers "$SCAN_CONTENT" "$SCAN_REPO" "git"
  if ! allows_trivial_fastpath "$SCAN_CONTENT"; then
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
if [ -z "${OPENBAO_GH_CLAIM:-}" ]; then
  die auth "?" "$VERB" "An active OpenBao write claim is required for this operation."
fi
if [ -z "${GITHUB_TOKEN:-}" ]; then
  die auth "$OPENBAO_GH_CLAIM" "$VERB" "The active OpenBao write claim has no credential."
fi
# `gh` prefers GH_TOKEN when both are set. Pin it to the token created by the
# active claim so an older ambient GH_TOKEN cannot replace that credential.
GH_TOKEN="$GITHUB_TOKEN"
export GH_TOKEN

REPO="$(resolve_repo "$@" || true)"

[ -z "$REPO" ] && die visibility "?" "$VERB" \
  "Cannot resolve the target repository, so its visibility is unknown. Pass -R OWNER/REPO, or run from inside the repo."

if [ "$OPENBAO_GH_CLAIM" != "$REPO" ]; then
  die auth "$REPO" "$VERB" "The active OpenBao write claim is for a different repository."
fi

repo_is_public "$REPO" || exec "$GH_REAL" "$@"

CONTENT="$(collect_content "$@")"
[ -z "$CONTENT" ] && exec "$GH_REAL" "$@"

screen_identifiers "$CONTENT" "$REPO" "$VERB"

if ! allows_trivial_fastpath "$CONTENT"; then
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
