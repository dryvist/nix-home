# shellcheck shell=bash
# Usage (in the .envrc of a directory that groups several repositories):
#
#   use children
#
# Loads every immediate child directory's .envrc into the parent, so a shell
# or agent session started in the parent gets each child's dev shell.
#
# - Dot-directories are skipped. A child that calls source_up re-enters the
#   parent, where the guard below makes `use children` a no-op.
# - PATH from each nix-direnv shell stacks. Any other variable that two
#   children both export takes the value from the alphabetically last child.
# - Generates the parent's .mcp.json (children's mcpServers merged) and
#   .claude/settings.json (children's enabledPlugins merged). Both are
#   overwritten on change; put hand edits in .claude/settings.local.json.
use_children() {
  [[ -n ${_USE_CHILDREN_ACTIVE:-} ]] && return 0
  local _USE_CHILDREN_ACTIVE=1
  local _uc_dir _uc_name
  local -a _uc_loaded=() _uc_mcp=() _uc_settings=()

  for _uc_dir in "$PWD"/*/; do
    _uc_dir=${_uc_dir%/}
    _uc_name=${_uc_dir##*/}
    watch_file "$_uc_dir/.envrc" "$_uc_dir/.mcp.json" "$_uc_dir/.claude/settings.json"
    [[ -f $_uc_dir/.mcp.json ]] && _uc_mcp+=("$_uc_dir/.mcp.json")
    [[ -f $_uc_dir/.claude/settings.json ]] && _uc_settings+=("$_uc_dir/.claude/settings.json")
    [[ -f $_uc_dir/.envrc ]] || continue
    if source_env "$_uc_dir/.envrc"; then
      _uc_loaded+=("$_uc_name")
    else
      log_error "use_children: $_uc_name failed to load"
    fi
  done
  log_status "use_children: loaded ${#_uc_loaded[@]}: ${_uc_loaded[*]}"

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
