# Workspace roots: one input, everything else derived.
#
# `workspace.gitHome` is the only place the workspace root is set; it defaults
# under the home directory and any consumer (a host, an automation identity)
# may override it. The public and private roots, and the session variables
# docs and scripts reference instead of literal paths, all derive from it.
{ config, lib, ... }:

let
  cfg = config.workspace;
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
  };

  config.home.sessionVariables = {
    GIT_HOME = cfg.gitHome;
    GIT_HOME_PUBLIC = cfg.gitHomePublic;
    GIT_HOME_PRIVATE = cfg.gitHomePrivate;
  };
}
