# Workspace roots: one input, everything else derived.
#
# `workspace.gitHome` is the only place the workspace root is set; it defaults
# under the home directory and any consumer (a host, an automation identity)
# may override it. The public and private roots, and the session variables
# docs and scripts reference instead of literal paths, all derive from it.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.workspace;

  linkWorkspaceEnvrc = pkgs.writeShellApplication {
    name = "link-workspace-envrc";
    text = builtins.readFile ./scripts/link-workspace-envrc.sh;
  };
in
{
  options.workspace = {
    gitHome = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/git";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/git"'';
      description = "Workspace root ($GIT_HOME). Public and private roots derive from it.";
    };
    gitHomePublic = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "${cfg.gitHome}/public";
      description = "Derived: $GIT_HOME_PUBLIC.";
    };
    gitHomePrivate = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "${cfg.gitHome}/private";
      description = "Derived: $GIT_HOME_PRIVATE.";
    };
    notes = {
      obsidianHome = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/obsidian";
        example = "${config.home.homeDirectory}/notes";
        description = "Root directory for Obsidian vaults and personal knowledge bases ($NOTES_HOME).";
      };

      dictationNotesDirectory = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
      dictationNotesDirectory = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "${cfg.notes.obsidianHome}/dictation-notes";
        example = "${config.home.homeDirectory}/dictation-notes";
        description = ''
          Directory where dictation notes are mirrored.
          Provides an easily configurable parameter for macOS and Linux workstations.
        '';
      };
    };
  };

  config = {
    home.sessionVariables = {
      GIT_HOME = cfg.gitHome;
      GIT_HOME_PUBLIC = cfg.gitHomePublic;
      GIT_HOME_PRIVATE = cfg.gitHomePrivate;
      NOTES_HOME = cfg.notes.obsidianHome;
    }
    // lib.optionalAttrs (cfg.notes.dictationNotesDirectory != null) {
      DICTATION_NOTES_DIR = cfg.notes.dictationNotesDirectory;
    };

    # The one definition of a grouping directory's .envrc (see the file's header).
    xdg.configFile."direnv/workspace.envrc".source = ./direnv/workspace.envrc;

    # Symlink it into every grouping directory of the workspace.
    home.activation.workspaceEnvrc = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${lib.getExe linkWorkspaceEnvrc} \
        ${lib.escapeShellArgs [
          "${config.xdg.configHome}/direnv/workspace.envrc"
          cfg.gitHome
          cfg.gitHomePublic
          cfg.gitHomePrivate
        ]}
    '';
  };
}
