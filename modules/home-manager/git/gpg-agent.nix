# gpg-agent configuration for unattended commit signing.
#
# Long cache TTL (24h) prevents pinentry prompts during AI-driven sessions
# that span hours. On Darwin, pinentry-mac is wired in so the prompt uses
# the system Keychain UI instead of a TTY-only prompt that fails when
# stdin is closed.
#
# Returns { files; activation; } matching the awsConfig pattern. The
# activation step runs `gpgconf --reload gpg-agent` after home-manager
# switch so changes take effect without requiring a logout. Both fields
# are empty on non-Darwin so Linux gpg-agent defaults stay untouched.

{ pkgs, lib }:

let
  inherit (pkgs.stdenv) isDarwin;
in
{
  files = lib.optionalAttrs isDarwin {
    ".gnupg/gpg-agent.conf" = {
      text = ''
        default-cache-ttl 86400
        max-cache-ttl 86400
        pinentry-program ${pkgs.pinentry_mac}/bin/pinentry-mac
      '';
    };
  };

  activation = lib.optionalAttrs isDarwin {
    reloadGpgAgent = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Picks up TTL/pinentry changes without requiring logout.
      # Failure is non-fatal — agent isn't always running and starts on demand.
      ${pkgs.gnupg}/bin/gpgconf --reload gpg-agent || true
    '';
  };
}
