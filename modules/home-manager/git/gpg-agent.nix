# Native gpg-agent for unattended commit signing (Darwin).
#
# Replaces a hand-written ~/.gnupg/gpg-agent.conf + manual `gpgconf --reload`
# with home-manager's `services.gpg-agent`, which writes the same conf AND
# manages a launchd agent so the agent stays warm across long AI-driven
# sessions (the whole reason for the 24h cache TTL).
#
# The pinentry program follows the host profile: GUI pinentry-mac on a
# workstation (uses the Keychain UI, survives a closed stdin), TTY
# pinentry-curses on a headless server where no GUI prompt can appear.
#
# Only managed on Darwin — Linux gpg-agent defaults stay untouched, matching the
# scope of the previous hand-written module.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.gpg-agent = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    defaultCacheTtl = 86400;
    maxCacheTtl = 86400;
    pinentry.package =
      if config.home-profile.features.pinentryGui.enable then pkgs.pinentry_mac else pkgs.pinentry-curses;
  };
}
