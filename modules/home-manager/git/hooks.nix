# Git Hooks (Template via init.templateDir)
#
# These hooks are seeded into new clones / `git init` runs via
# init.templateDir (set in git/config.nix). They are NOT set as
# core.hooksPath — see the comment in git/config.nix for why.
# They delegate to pre-commit framework if .pre-commit-config.yaml exists.
#
# Layer 1 of 3-layer defense:
#   1. Template hooks (this) - seeded on new clones; pre-commit install
#      (run by per-repo Nix dev shells) handles existing repos
#   2. AI deny list - blocks --no-verify bypass attempts
#   3. GitHub branch protection - server-side guarantee

{ config, pkgs, ... }:

let
  # Pre-commit hook: runs on every commit
  preCommitHook = pkgs.writeShellScript "pre-commit" ''
    # Skip if no pre-commit config
    if [ ! -f .pre-commit-config.yaml ]; then
      exit 0
    fi

    # Check for pre-commit framework
    # NOTE: Warning only (not blocking) - pre-commit may not be installed in all environments
    # Layer 2 (AI deny list) and Layer 3 (GitHub branch protection) provide enforcement
    if ! command -v pre-commit &> /dev/null; then
      echo "Warning: .pre-commit-config.yaml exists but pre-commit is not installed" >&2
      echo "Add pre-commit to your Nix configuration and rebuild" >&2
      exit 0
    fi

    # Run pre-commit hooks
    exec pre-commit run --hook-stage commit
  '';

  # Pre-push hook: runs before push (secondary gate)
  prePushHook = pkgs.writeShellScript "pre-push" ''
    # Skip if no pre-commit config
    if [ ! -f .pre-commit-config.yaml ]; then
      exit 0
    fi

    # Check for pre-commit framework
    # NOTE: Warning only - don't block push, but inform user checks were skipped
    if ! command -v pre-commit &> /dev/null; then
      echo "Warning: pre-commit not found, skipping pre-push checks." >&2
      exit 0
    fi

    # Run pre-commit hooks only on files changed in the push (not all files).
    # Using --from-ref/--to-ref prevents heavy hooks (e.g. provider validation)
    # from running when only unrelated files (e.g. YAML) are pushed.
    # Reads the ref pairs from stdin as per the git pre-push hook protocol.
    z40=0000000000000000000000000000000000000000
    exit_code=0
    while IFS=' ' read -r local_ref local_sha remote_ref remote_sha; do
      # Skip branch deletions (local_sha is all zeros — not a valid commit ref)
      if [ "$local_sha" = "$z40" ]; then
        continue
      fi

      if [ "$remote_sha" = "$z40" ]; then
        # New branch: compare against merge-base with the remote's default branch
        # so we check only files changed in this branch, not the entire repo history.
        # Detect the actual default branch, then fall back to common names.
        default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
        if [ -n "$default_branch" ]; then
          from=$(git merge-base "$local_sha" "origin/$default_branch" 2>/dev/null \
                 || git hash-object -t tree /dev/null)
        else
          from=$(git merge-base "$local_sha" origin/main 2>/dev/null \
                 || git merge-base "$local_sha" origin/master 2>/dev/null \
                 || git hash-object -t tree /dev/null)
        fi
      else
        from="$remote_sha"
      fi
      to="$local_sha"
      pre-commit run --from-ref "$from" --to-ref "$to" --hook-stage push || exit_code=$?
    done
    exit $exit_code
  '';
  # Return file definitions directly (merged into home.file in common.nix)
in
{
  ".git-templates/hooks/pre-commit" = {
    source = preCommitHook;
    executable = true;
  };
  ".git-templates/hooks/pre-push" = {
    source = prePushHook;
    executable = true;
  };
}
