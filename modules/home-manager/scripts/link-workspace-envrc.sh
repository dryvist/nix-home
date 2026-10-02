# shellcheck shell=bash
# Symlink the workspace .envrc into every grouping directory of the git
# workspace: the root, the public and private roots, each public family, each
# private owner and each owner's family.
#
# Usage: link-workspace-envrc <target> <git-home> <public-root> <private-root>
target=$1 root=$2 public=$3 private=$4

for dir in "$root" "$public" "$private" "$public"/*/ "$private"/*/ "$private"/*/*/; do
  dir=${dir%/}
  envrc=$dir/.envrc

  [[ -d $dir ]] || continue
  # A repository (work tree or bare), not a grouping directory.
  [[ -e $dir/.git || -f $dir/HEAD ]] && continue
  # Already linked.
  [[ $envrc -ef $target ]] && continue
  # A hand-written .envrc is never overwritten.
  if [[ -e $envrc && ! -L $envrc ]]; then
    echo "workspace .envrc: $envrc is a regular file; move its extra lines to .envrc.local, then delete it" >&2
    continue
  fi

  ln -sfn "$target" "$envrc"
done
