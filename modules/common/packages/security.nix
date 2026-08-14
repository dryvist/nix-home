# Security & credential managers — installed on every host.
#
# Password and secret management CLIs. AWS/cloud credential tooling lives in
# cloud.nix.

{ pkgs }:

let
  # Keep BWS declarative while avoiding nixpkgs' expensive Rust source build.
  # The vendor-binary package documents the measured 7–13 minute regression and
  # why this deliberate nixpkgs exception must remain in place.
  bws = pkgs.callPackage ./bws.nix { };
in
with pkgs;
[
  bitwarden-cli # CLI for Bitwarden password manager (bw command)
  bws # Official Bitwarden release; never `pkgs.bws` (see ./bws.nix).
  doppler # Doppler secrets manager CLI (for CI/CD and team secrets)
]
