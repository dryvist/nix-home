# Security & credential managers — installed on every host.
#
# Password and secret management CLIs. AWS/cloud credential tooling lives in
# cloud.nix.

{ pkgs }:

with pkgs;
[
  bitwarden-cli # CLI for Bitwarden password manager (bw command)
  bws # Bitwarden Secrets Manager CLI (for machine secrets)
  doppler # Doppler secrets manager CLI (for CI/CD and team secrets)
]
