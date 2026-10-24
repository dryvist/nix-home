# Git Configuration Module
#
# Programs.git settings for home-manager.
# Imported by common.nix
{
  config,
  pkgs,
  commitMessagePattern,
  userConfig,
  gitAliases,
}:

{
  enable = true;

  # Global ignore patterns (written to the XDG global excludes file).
  # `.worktrees/` is where a linked worktree belongs. The per-tool paths below
  # are written by tools that hardcode their own location and offer no setting
  # to move it. `.omo/` is per-session runtime state from the omo agent.
  ignores = [
    ".worktrees/"
    ".omo/"
    ".claude/worktrees/"
    ".claude-wt/"
    ".gemini/worktrees/"
    ".gemini/antigravity-cli/worktrees/"
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

    # Global commit-msg lint via git's config-based hooks: runs in every repo
    # alongside per-repo .git/hooks, without core.hooksPath (see core above).
    # The subject regex is the org ruleset's own copy (commitMessagePattern,
    # see the tofu-github input in flake.nix); every other gitlint rule is
    # ignored. gitlint skips merge, fixup and squash commits.
    hook.commit-subject = {
      event = "commit-msg";
      command = "${pkgs.gitlint}/bin/gitlint --ignore T1,T2,T3,T4,T5,T6,T8,B1,B2,B3,B4,B5,B6,B7,B8 -c ${pkgs.lib.escapeShellArg "title-match-regex.regex=${commitMessagePattern}"} --msg-filename";
    };

    # Pull behavior - rebase keeps history linear when using plain git pull.
    pull.rebase = true;

    # Rebase behavior - preserve related local branches and include open changes.
    rebase = {
      updateRefs = true;
      autoStash = true;
    };

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

    # Git Town workflow defaults. No global main-branch: each repo sets its own
    # (develop on git-flow repos), so an unset repo fails instead of branching from main.
    git-town = {
      sync-feature-strategy = "rebase";
      sync-perennial-strategy = "rebase";
      perennial-regex = "^(main|develop)$";
      ship-strategy = "api";
    };

    # Merge & diff improvements
    merge = {
      conflictstyle = "diff3"; # Show original in conflicts (easier resolution)
      ff = "only"; # Only fast-forward merges (use rebase for others)

      # flake.lock has no safe text merge; require explicit regeneration.
      flakelock = {
        name = "Require explicit flake.lock regeneration";
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

    # Helpful features
    help.autocorrect = 10; # Auto-correct typos after 1 second
    status.showStash = true; # Show stash count in git status
    log.date = "iso"; # Use ISO date format in logs
    branch.sort = "-committerdate"; # Sort branches by recent commits

    # Git aliases - see git-aliases.nix for full list
    alias = gitAliases;
  };
}
