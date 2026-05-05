# Cross-platform Home-Manager Common Configuration
#
# Non-AI settings shared across all platforms.
# AI settings are provided by nix-ai.homeManagerModules.default.

{
  config,
  pkgs,
  lib,
  userConfig ? {
    nix = {
      homeManagerStateVersion = "25.11";
    };
    user = {
      name = "jevans";
      email = "20714140+JacobPEvans@users.noreply.github.com";
      fullName = "JacobPEvans";
    };
    git = {
      editor = "vim";
      defaultBranch = "main";
    };
    gpg = {
      signingKey = "";
    };
  },
  ...
}:

let
  # Universal packages (pre-commit, linters, dev tools) shared across all systems
  commonPackages = import ../common/packages.nix { inherit pkgs; };

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

  # gpg-agent config (long cache TTL + pinentry-mac on Darwin)
  gpgAgentFiles = import ./git/gpg-agent.nix { inherit pkgs lib; };

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

    file = npmFiles // awsConfig.files // linterFiles // gitHooks // gitMergeDrivers // gpgAgentFiles;

    sessionVariables = {
      EDITOR = "vim";
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      HF_HOME = "/Volumes/HuggingFace";
      SCCACHE_CACHE_SIZE = "5G";
    };

    activation = vscodeWritableConfig.activation // documentSkillsConfig.activation;
  };

  programs = {
    vscode = {
      enable = true;
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
        ${lib.optionalString pkgs.stdenv.isDarwin "source ${awsConfig.initScript}"}
        source ${./zsh/git-functions.zsh}
        source ${./zsh/docker-functions.zsh}
        source ${./zsh/process-cleanup.zsh}
        source ${./zsh/session-logging.zsh}  # MUST be last
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
