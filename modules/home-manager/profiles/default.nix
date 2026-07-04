# Host role profiles + feature toggles
#
# nix-home is consumed by every host (MacBook daily-driver, headless Mac Studio,
# ...). This module lets a host pick a `preset` and get a sensible set of feature
# defaults, while still allowing per-feature overrides.
#
#   home-profile.preset = "server";                       # headless defaults
#   home-profile.features.vscode.enable = true;           # ...but keep VS Code
#
# Presets only set defaults (via `mkDefault`), so an explicit feature assignment
# in a consuming host always wins. `workstation` mirrors the historical
# behaviour (everything on); `server` drops GUI/desktop/document features that a
# headless SSH box does not need.
#
# Consumers set the preset in nix-darwin's host config (see the mac-studio host).

{ config, lib, ... }:

let
  cfg = config.home-profile;
  workstation = cfg.preset == "workstation";

  mkFeature =
    description:
    lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ${description}.";
    };
in
{
  options.home-profile = {
    preset = lib.mkOption {
      type = lib.types.enum [
        "workstation"
        "server"
      ];
      default = "workstation";
      description = ''
        Host role preset. `workstation` enables all daily-driver features (GUI
        editor, document-skills runtime, GUI pinentry, ...). `server` disables
        those for a headless SSH host. Individual `features.*` toggles override
        the preset default regardless of which preset is selected.
      '';
    };

    features = {
      vscode.enable = mkFeature "VS Code editor and settings management";
      documentSkills.enable = mkFeature "Claude document-skills runtime (docx/pptx npm deps + pandoc/poppler)";
      heavyPython.enable = mkFeature "the python314.withPackages document env (pandas/pillow/markitdown)";
      googleWorkspace.enable = mkFeature "Google Workspace CLIs (gmailctl, rclone, gdrive3)";
      pinentryGui.enable = mkFeature "GUI pinentry (pinentry-mac); disable for headless TTY pinentry";
      awsConfig.enable = mkFeature "AWS ~/.aws/config generation from the macOS Keychain at shell init";
    };
  };

  # Preset drives the per-feature defaults. `mkDefault` keeps these overridable
  # by a consuming host. All features track the preset: on for workstation, off
  # for server.
  config.home-profile.features = {
    vscode.enable = lib.mkDefault workstation;
    documentSkills.enable = lib.mkDefault workstation;
    heavyPython.enable = lib.mkDefault workstation;
    googleWorkspace.enable = lib.mkDefault workstation;
    pinentryGui.enable = lib.mkDefault workstation;
    awsConfig.enable = lib.mkDefault workstation;
  };
}
