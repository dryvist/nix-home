# Git Configuration Module
#
# Programs.git settings for home-manager.
# Imported by common.nix
{
  config,
  userConfig,
  gitAliases,
}:

{
  enable = true;

  # Global ignore patterns (written to the XDG global excludes file).
  # AI tools create native worktrees in their own dotdirs; never track them.
  ignores = [
    ".claude/worktrees/"
    ".gemini/worktrees/"
  ];

  # GPG signing configuration
  # NOTE: Key ID is a public identifier, not the private key (safe to commit)
  signing = {
    key = userConfig.gpg.signingKey;
    signByDefault = true; # Enforced by security policy
  };

  # All git settings (new unified syntax)
  settings = {
    # User identity
    user = {
      name = userConfig.user.fullName;
      inherit (userConfig.user) email;
    };

    # Core settings
    core = {
      inherit (userConfig.git) editor;
      autocrlf = "input"; # LF on commit, unchanged on checkout (Unix-style)
      whitespace = "trailing-space,space-before-tab"; # Highlight whitespace issues
      # core.hooksPath intentionally NOT set globally. Setting it makes
      # `pre-commit install` (cachix/git-hooks.nix installationScript) refuse
      # to install per-repo hooks with "Cowardly refusing to install hooks
      # with core.hooksPath set". Pre-commit-using repos rely on per-repo
      # .git/hooks/ populated by their dev shell. Repos without a Nix dev
      # shell still get template hooks via init.templateDir below.
    };

    # Repository initialization
    init = {
      inherit (userConfig.git) defaultBranch;
      # Seed new clones/inits with template hooks via git's native template
      # mechanism. Files in ~/.git-templates/hooks are copied into .git/hooks/
      # on `git init`/`git clone`. Passive — doesn't override per-repo hooks.
      templateDir = "${config.home.homeDirectory}/.git-templates";
    };

    # Pull behavior - rebase keeps history cleaner than merge commits
    #pull.rebase = true;
    # Pull behavior - hard error on non-linear history which can then be manually rebased
    pull.ff = "only";

    # Push behavior
    push = {
      autoSetupRemote = true; # Auto-track remote branches
      default = "current"; # Push current branch to same-named remote
    };

    # Fetch behavior
    fetch = {
      prune = true; # Auto-remove deleted remote branches
      pruneTags = true; # Auto-remove deleted remote tags
    };

    # Merge & diff improvements
    merge = {
      conflictstyle = "diff3"; # Show original in conflicts (easier resolution)
      ff = "only"; # Only fast-forward merges (use rebase for others)

      # Custom merge driver for flake.lock - auto-regenerate on conflict
      # Instead of 3-way merge, just regenerate the lock file
      flakelock = {
        name = "Regenerate flake.lock";
        # %O = ancestor, %A = current (write result here), %B = other
        # Regenerate lock and copy to merge result
        driver = "${config.home.homeDirectory}/.local/bin/git-merge-flakelock %O %A %B";
      };
    };
    diff = {
      algorithm = "histogram"; # Better diff algorithm than default
      colorMoved = "default"; # Highlight moved lines in different color
      mnemonicPrefix = true; # Use i/w/c/o instead of a/b in diffs
    };

    # Rerere - remember merge conflict resolutions
    rerere = {
      enabled = true; # Remember how you resolved conflicts
      autoupdate = true; # Auto-stage rerere resolutions
    };

    # Sign all tags (security policy)
    tag.gpgSign = true;

    # Git-flow branch model, read by git-flow-next (installed in
    # packages/core.nix). See the git-flow rule:
    # https://github.com/JacobPEvans/ai-assistant-instructions/blob/main/agentsmd/rules/git-flow.md
    #
    # home-manager's git settings type only nests section -> subsection -> key
    # (3 levels), so each `gitflow.branch.<name>` subsection is written as a
    # single quoted attribute name here — renders as `[gitflow "branch.main"]`,
    # which is exactly what the dotted key `gitflow.branch.main.type` (as used
    # in git-flow-next's own docs) parses to under git's own section/subsection
    # rules (subsection is just a literal string, dots and all).
    # upstreamStrategy belongs on the CHILD branch type, not the parent — it's
    # how that branch type merges into its own `parent` on finish (see
    # git-flow-next's cmd/finish.go: it reads the branch-being-finished's own
    # UpstreamStrategy as the merge strategy into branchConfig.Parent).
    gitflow = {
      "branch.main" = {
        type = "base";
        # No parent, so no upstreamStrategy — main only ever receives
        # merge-commit PRs, enforced by GitHub branch protection, not this file.
      };
      "branch.develop" = {
        type = "base";
        parent = "main";
        autoUpdate = true;
      };
      "branch.feature" = {
        type = "topic";
        parent = "develop";
        prefix = "feature/";
        upstreamStrategy = "squash"; # ordinary feature PRs squash-merge into develop
      };
      "branch.release" = {
        type = "topic";
        parent = "main"; # release branches finish (merge-commit) into main
        startPoint = "develop"; # but branch off develop
        prefix = "release/";
        tag = true;
        upstreamStrategy = "merge";
      };
      "branch.hotfix" = {
        type = "topic";
        parent = "main";
        prefix = "hotfix/";
        tag = true;
        upstreamStrategy = "merge";
      };
    };

    # Helpful features
    help.autocorrect = 10; # Auto-correct typos after 1 second
    status.showStash = true; # Show stash count in git status
    log.date = "iso"; # Use ISO date format in logs
    branch.sort = "-committerdate"; # Sort branches by recent commits

    # Git aliases - see git-aliases.nix for full list
    alias = gitAliases;
  };
}
