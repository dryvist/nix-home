# npm Configuration
#
# Configures npm to use a user-writable prefix directory for global packages.
# This works around Nix's immutable store while keeping packages manageable.
#
# Strategy:
# - ~/.npmrc sets prefix to ~/.npm-packages
# - PATH includes ~/.npm-packages/bin (configured in common.nix zsh initContent)
# - NODE_PATH includes ~/.npm-packages/lib/node_modules
#
# Usage:
#   npm install -g <package>    # Install globally to ~/.npm-packages
#   npm update -g <package>     # Update a global package
#   npm list -g --depth=0       # List installed global packages
#
# Why this approach:
# - Nix store is read-only, npm can't install there
# - User-writable prefix allows normal npm workflows
# - Packages are still version-controlled via npm itself

{ config, ... }:
let
  # Bun reads one of these global paths, based on XDG_CONFIG_HOME.
  bunfig = ''
    [install]
    minimumReleaseAge = 604800 # seconds
  '';
in
{
  # ~/.npmrc - npm configuration file
  ".npmrc".text = ''
    # Global package prefix (writable directory)
    # Packages installed with: npm install -g <package>
    prefix=''${HOME}/.npm-packages

    # Resolve only package versions that are at least seven days old.
    min-release-age=7
  '';

  # Bun's documented global config locations are ~/.bunfig.toml and
  # $XDG_CONFIG_HOME/.bunfig.toml. Keep one shared config for both cases.
  ".bunfig.toml".text = bunfig;
  ".config/.bunfig.toml".text = bunfig;

  # User-level resolver settings for uv and pip.
  ".config/uv/uv.toml".text = ''
    exclude-newer = "7 days"
  '';

  ".config/pip/pip.conf".text = ''
    [install]
    uploaded-prior-to = P7D

    [lock]
    uploaded-prior-to = P7D
  '';
}
