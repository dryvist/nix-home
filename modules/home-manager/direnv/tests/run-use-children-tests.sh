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
printf '[whitelist]\nprefix = ["%s"]\n' "$work" >"$DIRENV_CONFIG/direnv.toml"

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

# Nested copies of the workspace envrc start only one background fetch and
# leave linked worktree paths out of the fetch list.
workspace_envrc=$(cd "$(dirname "$0")/.." && pwd -P)/workspace.envrc
fetch_workspace=$work/nhfetch-git
fetch_root=$fetch_workspace/public/owner
fetch_group=$fetch_root/group
fetch_repo_a=$fetch_group/repo-a
fetch_repo_b=$fetch_group/repo-b
fetch_worktree=$fetch_repo_a/.worktrees/linked
fetch_bin=$work/nhfetch-bin
fetch_log=$work/nhfetch-fetches
mkdir -p "$fetch_group" "$fetch_repo_a" "$fetch_repo_b" "$fetch_worktree" "$fetch_bin"
cp "$workspace_envrc" "$fetch_root/.envrc"
cp "$workspace_envrc" "$fetch_group/.envrc"
cat >"$fetch_bin/ghq" <<'EOF'
#!/usr/bin/env bash
[[ ${GHQ_ROOT:-} == "$FETCH_EXPECTED_ROOT" ]] || exit 1
printf '%s\n' "$FETCH_REPO_A" "$FETCH_REPO_B" "$FETCH_WORKTREE"
EOF
cat >"$fetch_bin/git" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$FETCH_LOG"
EOF
chmod +x "$fetch_bin/ghq" "$fetch_bin/git"
export FETCH_EXPECTED_ROOT=$fetch_workspace FETCH_REPO_A=$fetch_repo_a FETCH_REPO_B=$fetch_repo_b
export FETCH_WORKTREE=$fetch_worktree FETCH_LOG=$fetch_log PATH=$fetch_bin:$PATH

if (
  unset GIT_HOME GIT_TERMINAL_PROMPT GIT_SSH_COMMAND
  cd "$fetch_root"
  direnv exec . bash -c "[[ -z \${GIT_TERMINAL_PROMPT:-} && -z \${GIT_SSH_COMMAND:-} ]]"
); then
  echo "ok   workspace envrc: detached fetch kept git auth settings private"
else
  echo "FAIL workspace envrc: detached fetch exported git auth settings"
  fail=1
fi

for ((attempt = 0; attempt < 50; attempt++)); do
  if [[ -f $fetch_log ]] && [[ $(wc -l <"$fetch_log") -eq 2 ]]; then
    break
  fi
  sleep 0.1
done
if [[ -f $fetch_log ]]; then
  actual=$(LC_ALL=C sort "$fetch_log")
else
  actual=
fi
expected=$(printf '%s\n' \
  "-C $fetch_repo_a fetch --all --quiet" \
  "-C $fetch_repo_b fetch --all --quiet" | LC_ALL=C sort)
if [[ $actual == "$expected" ]]; then
  echo "ok   workspace envrc: nested copies fetched each repo once and skipped .worktrees"
else
  echo "FAIL workspace envrc: nested fetch list did not match"
  fail=1
fi
exit "$fail"
