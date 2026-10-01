# Symlink the workspace .envrc into every grouping directory of the git
# workspace: the root, the public and private roots, each public family, each
# private owner and each owner's family.
#
# Usage: link-workspace-envrc <target> <git-home> <public-root> <private-root>
#
# Repositories are skipped. An existing regular .envrc is left in place with a
# warning, so hand-written lines are never lost.
target=$1 root=$2 public=$3 private=$4

for dir in "$root" "$public" "$private" "$public"/*/ "$private"/*/ "$private"/*/*/; do
  dir=${dir%/}
  [[ -d $dir ]] || continue
  [[ -e $dir/.git || -f $dir/HEAD ]] && continue
  if [[ -L $dir/.envrc || ! -e $dir/.envrc ]]; then
    ln -sfn "$target" "$dir/.envrc"
  else
    echo "workspace .envrc: $dir/.envrc is a regular file; move its extra lines to .envrc.local, then delete it" >&2
  fi
done
