# shellcheck shell=bash
# Usage (in the .envrc of a directory that groups several repositories):
#
#   use children
#
# Loads every immediate child directory's .envrc into the parent, so a shell
# or agent session started in the parent gets each child's dev shell. A child
# that also says `use children` loads its own children, so every level below
# the starting directory is reached.
#
# - Dot-directories are skipped.
# - Only the directory direnv is loading, and directories beneath it, gather
#   children. A repository whose .envrc calls source_up re-enters its parent;
#   there `use children` is a no-op, so entering one repository never loads
#   its siblings.
# - Each child's watched files are checked in isolation, so a change in one
#   repository does not invalidate every other repository's nix-direnv cache.
# - PATH from each nix-direnv shell stacks. Any other variable that two
#   children both export takes the value from the alphabetically last child.
# - Generates the parent's .mcp.json (children's mcpServers merged) and
#   .claude/settings.json (children's enabledPlugins merged). Both are
#   overwritten on change; put hand edits in .claude/settings.local.json.

# direnv sources this library from the directory it is loading.
_use_children_root=$PWD

use_children() {
  [[ $PWD == "$_use_children_root" || $PWD == "$_use_children_root"/* ]] || return 0
  [[ :${_USE_CHILDREN_ACTIVE:-}: == *:"$PWD":* ]] && return 0
  local _USE_CHILDREN_ACTIVE=${_USE_CHILDREN_ACTIVE:-}:$PWD
  local _uc_dir _uc_name _uc_watches _uc_line
  local -a _uc_loaded=() _uc_mcp=() _uc_settings=() _uc_paths

  for _uc_dir in "$PWD"/*/; do
    _uc_dir=${_uc_dir%/}
    _uc_name=${_uc_dir##*/}
    _uc_paths=("$_uc_dir/.envrc" "$_uc_dir/.mcp.json" "$_uc_dir/.claude/settings.json")
    if [[ -f $_uc_dir/.envrc ]]; then
      _uc_watches=${DIRENV_WATCHES:-}
      unset DIRENV_WATCHES
      if source_env "$_uc_dir/.envrc"; then
        _uc_loaded+=("$_uc_name")
      else
        log_error "use_children: $_uc_name failed to load"
      fi
      if [[ -n ${DIRENV_WATCHES:-} ]]; then
        while IFS= read -r _uc_line; do
          [[ $_uc_line =~ \"[Pp]ath\":\ \"(.+)\"$ ]] && _uc_paths+=("${BASH_REMATCH[1]}")
        done < <("$direnv" show_dump "$DIRENV_WATCHES")
      fi
      export DIRENV_WATCHES=$_uc_watches
    fi
    watch_file "${_uc_paths[@]}"
    [[ -f $_uc_dir/.mcp.json ]] && _uc_mcp+=("$_uc_dir/.mcp.json")
    [[ -f $_uc_dir/.claude/settings.json ]] && _uc_settings+=("$_uc_dir/.claude/settings.json")
  done
  log_status "use_children: $(user_rel_path "$PWD") loaded ${#_uc_loaded[@]}: ${_uc_loaded[*]}"

  if ((${#_uc_mcp[@]})); then
    local dupes
    dupes=$(@jq@ -rs '[.[] | .mcpServers // {} | to_entries[]] | group_by(.key)[]
      | select((map(.value) | unique | length) > 1) | .[0].key' "${_uc_mcp[@]}")
    [[ -n $dupes ]] && log_error "use_children: MCP servers defined differently by several children (last wins): ${dupes//$'\n'/ }"
    _use_children_write .mcp.json \
      "$(@jq@ -s '{mcpServers: (map(.mcpServers // {}) | add)}' "${_uc_mcp[@]}")"
  fi

  if ((${#_uc_settings[@]})); then
    if [[ -f .claude/settings.json ]] && ! @jq@ -e 'keys == ["enabledPlugins"]' .claude/settings.json >/dev/null; then
      log_error "use_children: .claude/settings.json has hand-written keys; not overwriting"
    else
      _use_children_write .claude/settings.json \
        "$(@jq@ -s '{enabledPlugins: (map(.enabledPlugins // {}) | add)}' "${_uc_settings[@]}")"
    fi
  fi
}

# Write $2 to $1 only when it differs, so unchanged loads leave mtimes alone.
_use_children_write() {
  [[ -f $1 && "$(<"$1")" == "$2" ]] && return 0
  mkdir -p "$(dirname "$1")"
  printf '%s\n' "$2" >"$1"
  log_status "use_children: wrote $1"
}
