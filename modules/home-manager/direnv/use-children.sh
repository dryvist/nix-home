# shellcheck shell=bash
# `use children`: source every child directory's .envrc into this one, and
# merge the children's .mcp.json and .claude/settings.json into ours.
#
# - Recursive: a child that also says `use children` loads its own children.
# - Runs only in the directory direnv is loading or below it (entering one
#   repository never loads its siblings).
# - Each repository loads once: a linked worktree loads only when it is on the
#   repository's default branch, and a child's source_up is skipped because
#   the directories it would reach are the ones already loading it.
# - Each child is sourced with an empty DIRENV_WATCHES, because nix-direnv
#   rebuilds a dev shell when any watched file is newer than its cache. The
#   child's watched files are then watched here too.
# - PATH stacks; any other variable: the alphabetically last child wins.
# - Locals that exist while a child .envrc runs are named _use_children_*,
#   so a child exporting e.g. `name` cannot overwrite them.

# direnv sources this library from the directory it is loading.
_use_children_root=$PWD

use_children() {
  # Skip an ancestor of the loaded directory, reached through source_up.
  [[ $PWD/ == "$_use_children_root"/* ]] || return 0
  # Skip a directory that is already gathering its children further up the stack.
  [[ :${_use_children_stack:-}: == *:"$PWD":* ]] && return 0

  local _use_children_stack=${_use_children_stack:-}:$PWD
  local -a _use_children_loaded=() _use_children_watched=()
  local _use_children_dir

  for _use_children_dir in "$PWD"/*/; do
    _use_children_load "${_use_children_dir%/}"
  done
  watch_file "${_use_children_watched[@]}"
  log_status "use_children: $(user_rel_path "$PWD") loaded ${#_use_children_loaded[@]}: ${_use_children_loaded[*]}"

  _use_children_merge .mcp.json mcpServers
  _use_children_merge .claude/settings.json enabledPlugins
}

# Source child directory $1 with its own watch list, and remember what it watched.
_use_children_load() {
  _use_children_watched+=("$1/.envrc" "$1/.mcp.json" "$1/.claude/settings.json")
  [[ -f $1/.envrc ]] || return 0
  _use_children_default_worktree "$1" || return 0

  local _use_children_saved=${DIRENV_WATCHES:-} _use_children_source_up
  _use_children_source_up=$(declare -f source_up source_up_if_exists)
  source_up() { :; }
  source_up_if_exists() { :; }
  unset DIRENV_WATCHES
  if source_env "$1/.envrc"; then
    _use_children_loaded+=("${1##*/}")
  else
    log_error "use_children: ${1##*/} failed to load"
  fi
  eval "$_use_children_source_up"
  _nix_direnv_watches _use_children_watched # nix-direnv's own DIRENV_WATCHES reader
  export DIRENV_WATCHES=$_use_children_saved
}

# True unless $1 is a linked worktree on a branch other than its repository's
# default (origin/HEAD, else main).
_use_children_default_worktree() {
  [[ -f $1/.git ]] || return 0
  local branch default
  branch=$(@git@ -C "$1" symbolic-ref -q --short HEAD) || return 1
  default=$(@git@ -C "$1" rev-parse -q --abbrev-ref origin/HEAD 2>/dev/null) || default=origin/main
  [[ $branch == "${default#origin/}" ]]
}

# Merge key $2 from every child's file $1 into our own $1.
_use_children_merge() {
  local out=$1 key=$2 file dupes
  local -a files=()
  for file in */"$out"; do
    [[ -f $file ]] && files+=("$file")
  done
  ((${#files[@]})) || return 0

  if [[ -f $out ]] && ! @jq@ -e --arg k "$key" 'keys == [$k]' "$out" >/dev/null; then
    log_error "use_children: $out has hand-written keys; not overwriting"
    return 0
  fi

  dupes=$(@jq@ -rs --arg k "$key" '[.[][$k] // {} | to_entries[]] | group_by(.key)
    | map(select(map(.value) | unique | length > 1) | .[0].key) | join(" ")' "${files[@]}")
  [[ -n $dupes ]] && log_error "use_children: $out: children define these differently (last wins): $dupes"

  _use_children_write "$out" "$(@jq@ -s --arg k "$key" '{($k): (map(.[$k] // {}) | add)}' "${files[@]}")"
}

# Write $2 to $1 only when it differs, so unchanged loads leave mtimes alone.
_use_children_write() {
  [[ -f $1 && "$(<"$1")" == "$2" ]] && return 0
  mkdir -p "$(dirname "$1")"
  printf '%s\n' "$2" >"$1"
  log_status "use_children: wrote $1"
}
