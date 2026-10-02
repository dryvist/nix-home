#!/usr/bin/env bash
# Checks that `use children` loads each directory once: no re-run of a parent
# through a child's source_up, and only the default-branch worktree of a repo.
#
# Usage: run-use-children-tests.sh <use-children.sh> <nix-direnv direnvrc>
set -euo pipefail

work=$(cd "$(mktemp -d)" && pwd -P) # use_children compares physical paths
trap 'rm -rf "$work"' EXIT
root=$work/root
export HOME=$work XDG_DATA_HOME=$work/data XDG_CACHE_HOME=$work/cache DIRENV_CONFIG=$work/config
mkdir -p "$DIRENV_CONFIG" "$root/a" "$root/grp/b"
printf 'source %s\nsource %s\n' "$2" "$1" >"$DIRENV_CONFIG/direnvrc"
printf '[whitelist]\nprefix = ["%s"]\n' "$root" >"$DIRENV_CONFIG/direnv.toml"

# Each parent appends an x per run; a parent re-run by a child shows as xx.
cat >"$root/.envrc" <<'EOF'
export ROOT_RUNS=${ROOT_RUNS:-}x; use children
EOF
echo 'source_up; export A=1' >"$root/a/.envrc"
cat >"$root/grp/.envrc" <<'EOF'
source_up_if_exists; export GRP_RUNS=${GRP_RUNS:-}x; use children
EOF
echo 'source_up; export B=1' >"$root/grp/b/.envrc"

# A repository outside the tree with two worktrees inside it.
git init -q -b main "$work/repo"
git -C "$work/repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
git -C "$work/repo" checkout -q --detach
git -C "$work/repo" worktree add -q "$root/grp/wt-main" main
git -C "$work/repo" worktree add -q -b feat "$root/grp/wt-feat"
echo 'source_up; export WT_MAIN=1' >"$root/grp/wt-main/.envrc"
echo 'source_up; export WT_FEAT=1' >"$root/grp/wt-feat/.envrc"

fail=0
check() { # <dir> <var> <expected>
  local got
  got=$(cd "$1" && direnv exec . sh -c "printf %s \"\${$2:-}\"" 2>/dev/null)
  if [[ $got == "$3" ]]; then
    echo "ok   ${1#"$root"}: $2=$3"
  else
    echo "FAIL ${1#"$root"}: $2=$got, want $3"
    fail=1
  fi
}

check "$root" ROOT_RUNS x
check "$root" GRP_RUNS x
check "$root" A 1
check "$root" B 1
check "$root" WT_MAIN 1
check "$root" WT_FEAT ""
# Entered directly, a child still gets its parents and a feature worktree loads.
check "$root/grp/b" ROOT_RUNS x
check "$root/grp/b" B 1
check "$root/grp/wt-feat" WT_FEAT 1
exit "$fail"
