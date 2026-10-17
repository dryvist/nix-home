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

# Recursion backstop in case GH_REAL is ever misconfigured to point at us. It
# compares resolved paths, so no environment flag can switch screening off.
if [ "$(realpath "$GH_REAL" 2>/dev/null)" = "$(realpath "${BASH_SOURCE[0]}" 2>/dev/null)" ]; then
  printf 'gh-guard: the real gh path resolves to gh-guard itself\n' >&2
  exit 2
fi
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

# Set by repo_is_public: public, private, or unknown (lookup failed, screened).
REPO_VIS=""

die() { # tier repo verb message
  audit "$1" BLOCK "$2" "$3"
  printf 'gh-guard: BLOCKED (%s tier)\n\n%s\n\n' "$1" "$4" >&2
  # An auth or visibility refusal says nothing about content, so the disclosure
  # text belongs only to a repository confirmed public.
  case "$1" in
    auth|visibility|title) [ "$REPO_VIS" = public ] || exit 1 ;;
  esac
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

# Parses `gh api` arguments: the endpoint positional, the method, every
# field ("raw:k=v" for -f, "typed:k=v" for -F, attached forms included), and
# the --input source. Values of flags that take one are never the endpoint.
api_parse() {
  API_ENDPOINT="" API_METHOD="" API_INPUT="" API_FIELDS=()
  local a next=""
  shift
  for a in "$@"; do
    case "$next" in
      method) API_METHOD="$a"; next=""; continue ;;
      raw|typed) API_FIELDS+=("$next:$a"); next=""; continue ;;
      input) API_INPUT="$a"; next=""; continue ;;
      skip) next=""; continue ;;
    esac
    # Clustered shorthand: -i is gh api's only boolean short flag, so
    # -ifk=v is -i -fk=v.
    while [[ "$a" == -i?* ]]; do a="-${a#-i}"; done
    case "$a" in
      -X|--method) next=method ;;
      --method=*) API_METHOD="${a#*=}" ;;
      -X?*) a="${a#-X}"; API_METHOD="${a#=}" ;;
      -f|--raw-field) next=raw ;;
      --raw-field=*) API_FIELDS+=("raw:${a#*=}") ;;
      -f?*) a="${a#-f}"; API_FIELDS+=("raw:${a#=}") ;;
      -F|--field) next=typed ;;
      --field=*) API_FIELDS+=("typed:${a#*=}") ;;
      -F?*) a="${a#-F}"; API_FIELDS+=("typed:${a#=}") ;;
      --input) next=input ;;
      --input=*) API_INPUT="${a#*=}" ;;
      -H|--header|-t|--template|-q|--jq|--hostname|--cache|-p|--preview) next=skip ;;
      -H?*|-t?*|-q?*|-p?*|-i|--*) : ;;
      # Any other short-flag word may carry a body: screen it as one.
      -?*) API_FIELDS+=("raw:unparsed=$a") ;;
      *) [ -n "$API_ENDPOINT" ] || API_ENDPOINT="$a" ;;
    esac
  done
}

# True when the graphql document in file $1 holds a mutation token. An
# unreadable file counts as one: it cannot be shown to be a read.
gql_file_mutates() {
  [ -r "$1" ] && [ -f "$1" ] || return 0
  grep -qi 'mutation' -- "$1"
}

api_is_graphql() { case "$API_ENDPOINT" in graphql|/graphql) return 0 ;; esac; return 1; }

# `gh api` only matters when it MUTATES an issue/PR/comment surface, or runs a
# graphql mutation. A graphql query whose text cannot be inspected here (from
# --input or a file) counts as a mutation.
api_is_publish() {
  local f
  api_parse "$@"
  if api_is_graphql; then
    if [ -n "$API_INPUT" ]; then
      # stdin cannot be inspected; a file counts only when it holds no mutation.
      [ "$API_INPUT" = "-" ] && return 0
      gql_file_mutates "$API_INPUT" && return 0
    fi
    for f in ${API_FIELDS[@]+"${API_FIELDS[@]}"}; do
      case "$f" in
        *mutation*) return 0 ;;
        # -F query=@file: the document is in the file, so read it.
        typed:query=@*) gql_file_mutates "${f#typed:query=@}" && return 0 ;;
        typed:*=@*) return 0 ;;
      esac
    done
    return 1
  fi
  case "$API_ENDPOINT" in
    */issues|*/issues/*|*/pulls|*/pulls/*|*/comments|*/comments/*) ;;
    *) return 1 ;;
  esac
  case "${API_METHOD^^}" in
    POST|PATCH|PUT) return 0 ;;
    # gh api sends a POST when fields or --input are given without a method.
    "") [ "${#API_FIELDS[@]}" -gt 0 ] || [ -n "$API_INPUT" ] ;;
    *) return 1 ;;
  esac
}

# Mutations whose arguments are node IDs only. A string in one is a valid ID
# or a GitHub error, never published text.
TEXT_FREE_MUTATIONS='mutation|resolveReviewThread|unresolveReviewThread'

# True when the single inline graphql query calls only TEXT_FREE_MUTATIONS.
# Strings and comments are removed and lines joined before every `name(` call
# is collected, so a call split across lines or comments is still seen.
gql_is_text_free() {
  local f q="" n=0 calls
  for f in ${API_FIELDS[@]+"${API_FIELDS[@]}"}; do
    f="${f#*:}"
    [ "${f%%=*}" = query ] || continue
    q="${f#*=}"; n=$((n + 1))
  done
  [ "$n" = 1 ] || return 1
  # A carriage return ends a comment, so a query holding one is judged.
  case "$q" in @*|*'"""'*|*$'\r'*) return 1 ;; esac
  # GraphQL ignores a byte-order mark like whitespace; any non-ASCII byte is judged.
  LC_ALL=C grep -q '[^[:print:][:space:]]' <<<"$q" && return 1
  calls="$(sed -E 's/"([^"\\]|\\.)*"//g; s/#.*$//' <<<"$q" | tr '\n' ' ' |
    grep -oE '[_A-Za-z][_A-Za-z0-9]*[[:space:],]*\(' | sed -E 's/[[:space:],]*\($//')"
  [ -n "$calls" ] || return 1
  ! grep -qvxE "$TEXT_FREE_MUTATIONS" <<<"$calls"
}

# Every value a `gh api` call sends. With GQL_PROSE=1 on a graphql call, the
# query contributes only its string literals (judged whole if it holds a block
# string), so the judge sees prose, not syntax.
api_content() {
  local f kind kv key v out=""
  api_parse "$@"
  for f in ${API_FIELDS[@]+"${API_FIELDS[@]}"}; do
    kind="${f%%:*}" kv="${f#*:}"
    key="${kv%%=*}" v="${kv#*=}"
    # Only -F reads a file; -f sends "@path" literally.
    if [ "$kind" = typed ]; then
      if [ "$v" = "@-" ]; then v="$(cat)"
      elif [ "${v:0:1}" = @ ] && [ -r "${v#@}" ]; then v="$(cat -- "${v#@}")"; fi
    fi
    if [ "${GQL_PROSE:-0}" = 1 ] && api_is_graphql && [ "$key" = query ] &&
      [[ "$v" != *'"""'* ]]; then
      v="$(grep -oE '"([^"\\]|\\.)*"' <<<"$v" | sed -E 's/^"//; s/"$//')"
    fi
    out+="$v"$'\n'
  done
  if [ "$API_INPUT" = "-" ]; then out+="$(cat)"$'\n'
  elif [ -n "$API_INPUT" ] && [ -r "$API_INPUT" ]; then out+="$(cat -- "$API_INPUT")"$'\n'; fi
  printf '%s' "$out"
}

# ------------------------------------------------- content reconstruction ---
# Collects every channel a body can arrive through. This is the whole point of
# the shim: by the time we run, "$BODY" has already been expanded by the shell.
collect_content() {
  local out="" next="" a v
  if [ "${1:-}" = api ]; then
    out="$(api_content "$@")"
    if [ -z "$out" ] && [ ! -t 0 ]; then out="$(cat)"; fi
    printf '%s' "$out"
    return
  fi
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
# GitHub hides private repositories behind 404s on anonymous REST reads. Retry
# only that case through gh, which uses the caller's exported GH_TOKEN or
# GITHUB_TOKEN without putting the credential on argv.
repo_is_public() {
  local repo="$1" response status body token vis
  REPO_VIS=unknown
  response="$(
    unset GH_TOKEN GITHUB_TOKEN
    "${GH_GUARD_CURL:-curl}" -q --silent --show-error \
      --header 'Accept: application/vnd.github+json' \
      --write-out $'\n%{http_code}' \
      "https://api.github.com/repos/$repo" 2>/dev/null
  )" || { REPO_VIS=unknown; return 0; }

  status="${response##*$'\n'}"
  body="${response%$'\n'*}"
  case "$status" in
    200)
      vis="$(printf '%s' "$body" | python3 -c '
import json
import sys

value = json.load(sys.stdin).get("visibility")
print(value if isinstance(value, str) else "")
' 2>/dev/null)" || return 0
      ;;
    # Any other answer (404 for a private repo, 403 or 429 once the anonymous
    # rate limit is spent, a server error) is resolved with the caller's token.
    *)
      token="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
      [ -n "$token" ] || return 0
      vis="$("$GH_REAL" api "repos/$repo" --jq .visibility 2>/dev/null)" || return 0
      ;;
  esac

  case "$vis" in
    private|PRIVATE) REPO_VIS=private; return 1 ;;
    public|PUBLIC) REPO_VIS=public; return 0 ;;
    *) REPO_VIS=unknown; return 0 ;;   # unknown -> screen it
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
  local content stripped
  # grep -w treats underscore as a word character; normalize it on both sides
  # so underscores, like the other punctuation separators, bound identifiers.
  content="${1//_/ }"
  stripped="$content"
  [ -r "$DENYLIST" ] && [ -f "$DENYLIST" ] || return 2
  if [ -r "$ALLOWLIST" ]; then
    stripped="$(grep -viwFf <(grep -vE '^[[:space:]]*(#|$)' "$ALLOWLIST" | tr '_' ' ') <<<"$content" || true)"
  fi
  grep -qiwFf <(grep -vE '^[[:space:]]*(#|$)' "$DENYLIST" | tr '_' ' ') <<<"$stripped"
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

# A checkbox toggle on a bot-written PR or issue body (a Renovate rebase or
# Dependency Dashboard request) publishes no new text: the body is already
# public and only "[ ]"/"[x]" states change. Any other difference, a non-bot
# author, any flag besides the repo and the body, or a selector that is not
# the first argument after "edit" falls through to normal screening.
is_bot_checkbox_toggle() { # content repo gh-args...
  local content="$1" repo="$2" kind sel current
  shift 2
  case "${1:-} ${2:-}" in "pr edit"|"issue edit") kind="$1" ;; *) return 1 ;; esac
  case "${3:-}" in ""|-*) return 1 ;; esac
  sel="$3"
  shift 3
  # Only the repo and one body flag may follow: any other flag (a title, a
  # label, an assignee) carries text this check never compares.
  while [ $# -gt 0 ]; do
    case "$1" in
      -R|--repo|--body|-b|--body-file|-F) [ $# -ge 2 ] || return 1; shift 2 ;;
      --repo=*|--body=*|--body-file=*) shift ;;
      *) return 1 ;;
    esac
  done
  current="$("$GH_REAL" "$kind" view "$sel" -R "$repo" --json body,author \
    --jq 'select(.author.is_bot == true) | .body' 2>/dev/null)" || return 1
  [ -n "$current" ] || return 1
  [ "$(sed -E 's/\[[xX ]\]/[ ]/g' <<<"$content")" = "$(sed -E 's/\[[xX ]\]/[ ]/g' <<<"$current")" ]
}

# Local judge. On-machine only: its input IS the candidate disclosure, so a
# cloud call would perform the very leak this gate prevents.
# The local server serializes requests and answers a concurrent call with
# {"error":"Too many requests"}. That is transient, not a screening failure, so
# retry briefly before falling through to fail-closed — otherwise an unrelated
# local inference job would block every commit and the gate dies of fatigue.
judge_verdict() {
  local content="$1" payload result verdict attempt config judge_url judge_timeout deadline remaining delay
  local max_tokens=4 widened=0

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

  # Reasoning models spend a small budget thinking and return no content, so
  # the request asks the chat template to skip thinking. A server that
  # ignores it gets one retry with a budget large enough to finish reasoning.
  build_payload() {
    jq -n --arg m "$JUDGE_MODEL" --arg c "$content" --argjson n "$max_tokens" '{
    model:$m, max_tokens:$n, temperature:0,
    chat_template_kwargs:{enable_thinking:false},
    messages:[
      {role:"system",content:"You screen text that is about to be published to a PUBLIC GitHub repository.\nAnswer with exactly one word: \"block\" or \"allow\". Judge the meaning of the content, not its formatting or presentation: prose, a table, a bulleted list, a fenced code block, a diff block, and an ASCII or arrow diagram all disclose exactly as much as each other when they carry the same information -- placing a value inside a fence, a diagram, or a diff does not make it safe. Judge by what a value IS, not by whether the surrounding text sounds routine -- housekeeping language does not make a disclosed internal name safe.\n\nAnswer \"block\" only when the text contains an ACTUAL INSTANCE of one of the categories below: a real cause, name, value, or reasoning about one. A bare LABEL for a category -- a heading, a section title, an index entry, or a rule/policy description that names the category by word without stating any instance of it -- discloses nothing and must be \"allow\", even when it uses the same words as a category below. If the text explains, argues, or reasons about a real situation -- even briefly, even without alarm words -- that is an instance, not a label.\n\nAnswer \"block\" if the text discloses an instance of ANY of:\n- why something broke, failed, was fixed, or was decided (incident/outage/root-cause/rationale narrative)\n- internal system topology: clusters, nodes, voters, leaders, VLANs, ports, hosts\n- hostnames, IP addresses, or internal service names, including one disclosed only by stating what real value something was renamed from or replaced with\n- credential detail: what a token, policy or role is permitted to read, write or do (paths, capabilities, grants), its TTLs or use limits, or where a secret is stored\n\nAnswer \"allow\" if the text merely states WHAT changed with no operational detail (feature descriptions, dependency bumps, docs edits, config field names, the NAME of a secret or variable and which workflow step receives it -- a name is not a value, a scope, or a storage location, the infrastructure-as-code constructs a change adds or edits -- resource addresses, renamed resources, and moved, removed or import blocks with their arguments such as destroy = false -- which are code in the diff, not operational detail), or merely names the variables, policies, roles, lists or tests that the change adds, removes, renames or attaches -- those identifiers are already public in the diff, and saying which named policies are added to a named list, or that a test checks such a list, is not credential detail unless the text also says what those policies permit -- or merely labels one of the categories above without disclosing a real instance of it.\n\nExamples:\nText: \"Adds a retry to the upload helper and bumps the client to 2.1.\" -> allow\nText: \"The node lost quorum because the leader was fenced, so writes stalled.\" -> block\nText: \"The role grants read on the secret mount with a 30 minute TTL.\" -> block\nText: \"chore(deps): update the lockfile.\" -> allow\nText: \"Passes the DEPLOY_KEY secret to the reusable release workflow, which uses it to post a status check.\" -> allow\nText: \"fix(review): pass the bot App private key (BOT_APP_PRIVATE_KEY) to the reusable review workflow\" -> allow\nText: \"DEPLOY_KEY is kept in the ops vault under the ci path and can write to every repository.\" -> block\nText: \"fix(sync): exclude the deploy token\u0027s policies from reconcile. Adds the deploy and backup policies to `reconcile_excluded_policies`; a test asserts every policy on the deploy token is in that list.\" -> allow\nText: \"The deploy token can write every secret under the apps mount, so reconcile could grant itself more.\" -> block\nText: \"Moves the sync token to the shared platform path, where every read-only identity can read it.\" -> block\nText: \"This cleanup renamed db-node-3 to db-example throughout the fixtures.\" -> block\nText: \"Renames `aws_s3_bucket.logs` to `aws_s3_bucket.audit`; a `removed` block (`destroy = false`) forgets the old resource and an `import` block adopts the existing bucket under the new name.\" -> allow\nText: \"The last apply destroyed the production bucket, so this import block restores it after the outage.\" -> block\nText: \"This runbook template has sections for Root Cause, Credential Scope, and Topology -- fill each in during a real incident.\" -> allow\n\nOne word only."},
      {role:"user",content:$c}]}'
  }
  payload="$(build_payload)" || return 1

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
          verdict="$(tr '[:upper:]' '[:lower:]' <<<"${verdict:-}" | tr -d '[:space:][:punct:]')"
          case "$verdict" in
            allow) return 0 ;;
            block) return 2 ;;
            '')
              # Reasoning only, cut off by the budget: widen once, then fail.
              if [ "$widened" -eq 0 ] &&
                jq -e '(.choices[0].message.reasoning_content // "") != ""' <<<"$result" >/dev/null 2>&1; then
                widened=1
                max_tokens=512
                payload="$(build_payload)" || return 1
                continue
              fi
              return 1
              ;;
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

# PR title gate: the same commit-subject pattern the org's PR Title check
# enforces, applied before the PR exists instead of after CI runs.
pr_title() { # prints the --title/-t value, if any
  local next=""
  for a in "$@"; do
    if [ -n "$next" ]; then printf '%s' "$a"; return 0; fi
    case "$a" in
      --title|-t) next=1 ;;
      --title=*) printf '%s' "${a#*=}"; return 0 ;;
    esac
  done
  return 1
}
if [ "${1:-}" = pr ] && { [ "${2:-}" = create ] || [ "${2:-}" = edit ]; } \
  && [ -n "${GH_GUARD_TITLE_PATTERN:-}" ] && TITLE="$(pr_title "$@")" \
  && ! [[ "$TITLE" =~ $GH_GUARD_TITLE_PATTERN ]]; then
  die title "$(resolve_repo "$@" || echo '?')" "$VERB" "$(printf 'Check failed: the PR title is not a conventional commit subject.\nTitle:   %s\nPattern: %s\nNext: retry with a title like "feat(scope): add the thing" or "fix: correct the thing".' "$TITLE" "$GH_GUARD_TITLE_PATTERN")"
fi
CLAIM="${OPENBAO_GH_CLAIM:-}"
# `gh` prefers GH_TOKEN when both are set. Pin it to the token created by the
# active claim so an older ambient GH_TOKEN cannot replace that credential.
if [ -n "${GITHUB_TOKEN:-}" ]; then GH_TOKEN="$GITHUB_TOKEN"; export GH_TOKEN; fi

# Resolve the repository and its visibility BEFORE the claim check, so every
# refusal and its log line name the repo and say whether screening applies.
REPO="$(resolve_repo "$@" || true)"
if [ -n "$REPO" ]; then
  repo_is_public "$REPO" && PUBLIC_REPO=1 || PUBLIC_REPO=0
else
  PUBLIC_REPO=1
fi

owner_kind() { # everyday unless the environment names a WORK owner
  local owner="${REPO%%/*}" work="${OPENBAO_GITHUB_WORK_OWNER:-}"
  if [ -n "$work" ] && [ -n "$REPO" ] && [ "${owner,,}" = "${work,,}" ]; then echo WORK; else echo everyday; fi
}

# What the refusal shows: the values it judged and the exact next command.
observed() {
  printf 'Observed: OPENBAO_GH_CLAIM=%s  GITHUB_TOKEN=%s  repo=%s  visibility=%s  owner=%s  content-screening=%s\n' \
    "${CLAIM:-unset}" "$([ -n "${GITHUB_TOKEN:-}" ] && echo set || echo unset)" \
    "${REPO:-unresolved}" "${REPO_VIS:-unchecked}" "$(owner_kind)" \
    "$([ "$PUBLIC_REPO" = 1 ] && echo applies || echo skipped-private)"
}
claim_howto() { # repo
  printf "Next: in the SAME shell as the write, run\n  eval \"\$(doppler run -- openbao-github-creds claim %s)\"\nor wrap the command:\n  doppler run -- openbao-github-creds run %s -- <command>\n" "$1" "$1"
  [ "$(owner_kind)" = WORK ] && printf 'The WORK owner takes no lease: each claim or run is one gated mint.\n'
  return 0
}

if [ -z "$REPO" ]; then
  die visibility "?" "$VERB" "$(printf 'Check failed: target repository unresolved, so visibility and the claim cannot be checked.\n%s\nNext: pass -R OWNER/REPO, set GH_REPO, or run inside the clone.' "$(observed)")"
fi
if [ -z "$CLAIM" ]; then
  die auth "$REPO" "$VERB" "$(printf 'Check failed: no OpenBao write claim (OPENBAO_GH_CLAIM is unset).\n%s\n%s' "$(observed)" "$(claim_howto "$REPO")")"
fi
if [ -z "${GITHUB_TOKEN:-}" ]; then
  die auth "$REPO" "$VERB" "$(printf 'Check failed: the claim has no credential (GITHUB_TOKEN is unset).\n%s\n%s' "$(observed)" "$(claim_howto "$REPO")")"
fi
if [ "$CLAIM" != "$REPO" ]; then
  die auth "$REPO" "$VERB" "$(printf "Check failed: the claim is for %s but this write targets %s.\n%s\nNext: eval \"\$(openbao-github-creds release)\"; then eval \"\$(doppler run -- openbao-github-creds claim %s)\", or run just this command:\n  doppler run -- openbao-github-creds run %s -- <command>" "$CLAIM" "$REPO" "$(observed)" "$REPO" "$REPO")"
fi

[ "$PUBLIC_REPO" = 1 ] || exec "$GH_REAL" "$@"

CONTENT="$(collect_content "$@")"
[ -z "$CONTENT" ] && exec "$GH_REAL" "$@"

if is_bot_checkbox_toggle "$CONTENT" "$REPO" "$@"; then
  audit checkbox ALLOW "$REPO" "$VERB"
  exec "$GH_REAL" "$@"
fi

screen_identifiers "$CONTENT" "$REPO" "$VERB"

# The judge reads prose: for a graphql mutation, its string literals and field
# values, not its syntax. Stdin cannot be read twice, so a body from stdin is
# judged whole. A text-free mutation (resolving a thread) skips the judge.
PROSE="$CONTENT"
if [ "${1:-}" = api ]; then
  api_parse "$@"
  if api_is_graphql && [ "$API_INPUT" != "-" ] && [[ " ${API_FIELDS[*]-} " != *"=@- "* ]]; then
    if gql_is_text_free; then
      PROSE=""
    else
      PROSE="$(GQL_PROSE=1 collect_content "$@" </dev/null)"
      [ -n "$PROSE" ] || PROSE="$CONTENT"
    fi
  fi
fi

if [ -n "$PROSE" ] && ! allows_trivial_fastpath "$PROSE"; then
  set +e; judge_verdict "$PROSE"; rc=$?; set -e
  case "$rc" in
    0) : ;;
    2) die narrative "$REPO" "$VERB" "The local judge classified this as operational-security narrative." ;;
    *) die judge-unavailable "$REPO" "$VERB" \
         "The local judge is unreachable or returned an unusable verdict, so this cannot be screened. Fail-closed by design: start the local model server and retry." ;;
  esac
fi

audit clean ALLOW "$REPO" "$VERB"
exec "$GH_REAL" "$@"
