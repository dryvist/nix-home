# Cross-platform Home-Manager Common Configuration
#
# Non-AI settings shared across all platforms.
# AI settings are provided by nix-ai.homeManagerModules.default.

{
  config,
  pkgs,
  lib,
  # Standalone fallback identity/state. On a real machine nix-darwin passes its
  # own userConfig; this default lives in one place (see lib/user-defaults.nix).
  userConfig ? import ../../lib/user-defaults.nix,
  ...
}:

let
  # Resolved feature toggles from the host profile (modules/home-manager/profiles).
  features = config.home-profile.features;

  # Universal packages, composed from domain groups and gated by the profile.
  # The `workstation` preset enables every group (parity with the old flat list).
  commonPackages = import ../common/packages.nix { inherit pkgs lib features; };

  # Git aliases
  gitAliases = import ./git/aliases.nix;

  # Git hooks
  gitHooks = import ./git/hooks.nix { inherit config pkgs; };

  # Git configuration
  gitConfig = import ./git/config.nix { inherit config userConfig gitAliases; };

  # Git merge driver for flake.lock
  gitMergeDrivers = {
    ".local/bin/git-merge-flakelock" = {
      source = ./git/merge-flakelock.sh;
      executable = true;
    };
  };

  # Shell aliases
  shellAliases = import ./zsh/aliases.nix;

  # VS Code writable config
  vscodeWritableConfig = import ./vscode/writable-config.nix { inherit config lib pkgs; };

  # Claude document-skills runtime (bun-installed npm libs)
  documentSkillsConfig = import ./document-skills.nix { inherit pkgs lib; };

  # npm configuration
  npmFiles = import ./npm/config.nix { inherit config; };

  # AWS CLI configuration (account ID substituted from keychain at shell init)
  awsConfig = import ./aws/config.nix {
    inherit
      pkgs
      userConfig
      ;
  };

  # Linter configurations
  linterFiles = import ./linters/markdownlint.nix { inherit config; };
in
{
  home = {
    stateVersion = userConfig.nix.homeManagerStateVersion;

    # User dev tools (pre-commit, linters, Python, AWS, etc.)
    packages = commonPackages;

    file = npmFiles // awsConfig.files // linterFiles // gitHooks // gitMergeDrivers;

    sessionVariables = {
      EDITOR = "vim";
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      # Workspace roots. Reference these in docs, scripts, and commands
      # instead of hard-coding /Users/<you>/git/...
      GIT_HOME = "${config.home.homeDirectory}/git";
      GIT_HOME_PUBLIC = "${config.home.homeDirectory}/git/public";
      GIT_HOME_PRIVATE = "${config.home.homeDirectory}/git/dryvist-private";
    }
    // lib.optionalAttrs (pkgs.stdenv.isDarwin && config.home-profile.preset == "workstation") {
      # Workstation-only: external HuggingFace volume + local build-cache tuning.
      # A headless server has neither the /Volumes mount nor the sccache workload.
      HF_HOME = "/Volumes/HuggingFace";
      SCCACHE_CACHE_SIZE = "5G";
    };

    activation =
      (lib.optionalAttrs features.vscode.enable vscodeWritableConfig.activation)
      // (lib.optionalAttrs features.documentSkills.enable documentSkillsConfig.activation);
  };

  programs = {
    vscode = {
      enable = features.vscode.enable;
      profiles.default.userSettings = { };
    };

    zsh = {
      enable = true;
      inherit shellAliases;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;
      history = {
        size = 100000;
        save = 100000;
        ignoreDups = true;
        ignoreAllDups = true;
        ignoreSpace = true;
      };

      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
        plugins = [
          "git"
          "docker"
          "z"
          "colored-man-pages"
        ];
      };

      # Cross-platform shell init (NO macOS-specific content)
      # macOS-specific content (Keychain, macos-setup.zsh, macos oh-my-zsh plugin)
      # is added by nix-darwin's home.nix
      initContent = ''
        # --- Environment ---
        export GPG_TTY=$(tty)

        # --- PATH ---
        export PATH="$HOME/.npm-packages/bin:$PATH"
        export NODE_PATH="$HOME/.npm-packages/lib/node_modules"
        export PATH="$HOME/.local/bin:$PATH"

        # --- Shell modules ---
        ${lib.optionalString (
          pkgs.stdenv.isDarwin && features.awsConfig.enable
        ) "source ${awsConfig.initScript}"}
        source ${./zsh/git-functions.zsh}
        source ${./zsh/docker-functions.zsh}
        source ${./zsh/process-cleanup.zsh}
        ${lib.optionalString features.sessionLogging.enable "source ${./zsh/session-logging.zsh}  # MUST be last"}
      '';
    };

    git = gitConfig;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    gh = {
      enable = true;
      package = pkgs.gh;
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
      };
    };

    home-manager.enable = true;
  };
}
