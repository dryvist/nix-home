# gpg-agent configuration for unattended commit signing.
#
# Long cache TTL (24h) prevents pinentry prompts during AI-driven sessions
# that span hours. On Darwin, pinentry-mac is wired in so the prompt uses
# the system Keychain UI instead of a TTY-only prompt that fails when
# stdin is closed.
#
# Returns a home.file attrset (merged in common.nix). Empty on non-Darwin
# so Linux gpg-agent defaults remain untouched.

{ pkgs, lib }:

lib.optionalAttrs pkgs.stdenv.isDarwin {
  ".gnupg/gpg-agent.conf" = {
    text = ''
      default-cache-ttl 86400
      max-cache-ttl 86400
      pinentry-program ${pkgs.pinentry_mac}/bin/pinentry-mac
    '';
  };
}
