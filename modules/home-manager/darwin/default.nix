# macOS-Specific Home-Manager Modules
#
# User-level modules that use macOS-only APIs (LaunchAgents, osascript, etc.)
# Conditionally imported via lib.optionals pkgs.stdenv.isDarwin in flake.nix.
#
# These modules are safe cross-platform because:
# - They define options with mkEnableOption (defaults to false)
# - Config sections are gated with mkIf (only evaluated when enabled)
# - They are only imported on Darwin (via platform guard in flake.nix)

{
  imports = [
    ./nix-activation-recovery.nix
    ./tmux-session-autostart.nix
  ];
}
