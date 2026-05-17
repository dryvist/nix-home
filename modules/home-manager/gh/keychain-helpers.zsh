# GitHub PAT helpers for the macOS keychain.
#
# Reads GitHub Personal Access Tokens from a custom macOS keychain so that
# multi-token workflows (cross-org admin, per-scope PATs) don't require
# pasting tokens into env vars or files.
#
# Sourced from zsh initContent — runs as the user with full keychain access.
# @-prefixed tokens are replaced by pkgs.replaceVars at Nix build time.
#
# One-time setup (per machine):
#
#   1. Create the keychain (Keychain Access.app → File → New Keychain) or
#      reuse an existing one. Default name: "@elevateKeychain@".
#   2. Add each PAT as a generic password:
#        Service name: GH_PAT_<NAME>  (e.g., GH_PAT_ORG_ADMIN)
#        Account:      @elevateAccount@
#        Password:     <the PAT>
#   3. Set the keychain auto-lock window to something workable:
#        security set-keychain-settings -t 28800 -l \
#          "$HOME/Library/Keychains/@elevateKeychain@.keychain-db"
#   4. First time each PAT is read, the OS prompts for keychain unlock and
#      asks "Allow / Always Allow / Deny". Click "Always Allow" so
#      subsequent reads run silently for the keychain's timeout window.

_GH_PAT_ACCOUNT="@elevateAccount@"
_GH_PAT_KEYCHAIN_NAME="@elevateKeychain@"
_GH_PAT_DB="$HOME/Library/Keychains/$_GH_PAT_KEYCHAIN_NAME.keychain-db"

# Fetch a GitHub PAT by suffix.
# Usage: gh_pat ORG_ADMIN  →  reads service "GH_PAT_ORG_ADMIN" from the keychain
gh_pat() {
  local pat_suffix="$1"
  if [[ -z "$pat_suffix" ]]; then
    echo "usage: gh_pat <SUFFIX>   e.g.: gh_pat ORG_ADMIN" >&2
    return 1
  fi
  if [[ -z "$_GH_PAT_ACCOUNT" ]]; then
    echo "gh_pat: keychain account not configured (userConfig.keychain.elevateAccount)" >&2
    return 1
  fi
  security find-generic-password \
    -a "$_GH_PAT_ACCOUNT" \
    -s "GH_PAT_$pat_suffix" \
    -w "$_GH_PAT_DB" 2>/dev/null
}

# Run a command with a specific PAT exported as GITHUB_TOKEN + GH_TOKEN.
# Usage: with_gh_pat ORG_ADMIN -- gh pr list --repo dryvist/...
#        with_gh_pat ORG_ADMIN tofu apply
with_gh_pat() {
  local pat_suffix="$1"; shift
  if [[ "${1:-}" == "--" ]]; then
    shift
  fi
  if [[ $# -eq 0 ]]; then
    echo "usage: with_gh_pat <SUFFIX> [--] cmd [args...]" >&2
    return 1
  fi
  local token
  token="$(gh_pat "$pat_suffix")" || return 1
  if [[ -z "$token" ]]; then
    echo "with_gh_pat: empty token for GH_PAT_$pat_suffix" >&2
    return 1
  fi
  GITHUB_TOKEN="$token" GH_TOKEN="$token" "$@"
}

# Unlock the elevate-access keychain (GUI password prompt via Security Agent).
# Subsequent reads within the keychain's auto-lock window run silently if
# the user has clicked "Always Allow" on each item.
elevate_unlock() {
  if [[ ! -f "$_GH_PAT_DB" ]]; then
    echo "elevate_unlock: keychain not found at $_GH_PAT_DB" >&2
    return 1
  fi
  security unlock-keychain "$_GH_PAT_DB"
}
