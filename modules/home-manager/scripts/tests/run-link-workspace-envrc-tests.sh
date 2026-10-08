#!/usr/bin/env bash
# Checks that link-workspace-envrc links real grouping directories, skips
# symlinks and repositories, and survives a directory it cannot write to.
#
# Usage: run-link-workspace-envrc-tests.sh <link-workspace-envrc.sh>
set -euo pipefail

work=$(cd "$(mktemp -d)" && pwd -P)
trap 'chmod -R u+w "$work"; rm -rf "$work"' EXIT
root=$work/git public=$work/git/public private=$work/git/private
mkdir -p "$public/fam" "$public/locked" "$private/own/fam" "$work/store/out" "$public/repo/.git"
ln -s "$work/store/out" "$public/result"
chmod a-w "$public/locked"
target=$work/workspace.envrc
: >"$target"

stderr=$(bash "$1" "$target" "$root" "$public" "$private" 2>&1 >/dev/null)

fail=0
expect() { # <description> <condition-exit-status>
  if [[ $2 -eq 0 ]]; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi
}
[[ $public/fam/.envrc -ef $target ]]
expect "family dir linked" $?
[[ $private/own/fam/.envrc -ef $target ]]
expect "private owner family linked" $?
[[ ! -e $work/store/out/.envrc ]]
expect "symlinked entry skipped" $?
[[ ! -e $public/repo/.envrc ]]
expect "repository skipped" $?
# Running as root ignores the write bit, so only assert the log when it failed.
if [[ ! -e $public/locked/.envrc ]]; then
  grep -q "could not link $public/locked/.envrc" <<<"$stderr"
  expect "unwritable dir logged, run continued" $?
fi
exit $fail
