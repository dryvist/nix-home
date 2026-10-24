# Git Aliases (Cross-Platform)
#
# Git command aliases (used as: git st, git lg, etc.)
# Imported by home.nix for programs.git.aliases

{
  # Git Town workflow
  hack = "town hack";
  sync = "town sync";
  propose = "town propose";
  ship = "town ship";

  # Info
  last = "log -1 HEAD --stat"; # Show last commit with stats

  # Branch info
  br = "branch -vv"; # Verbose branch list with tracking

  # Diff info
  dfn = "diff --name-only"; # Just show changed files

  # Undo operations
  undo = "reset --soft HEAD~1"; # Undo last commit, keep changes staged

  # Cleanup
  cleanup = "!git branch --merged | grep -Ev '^\\*|^[[:space:]]*(main|develop|master)$' | xargs -n 1 git branch -d";
}
