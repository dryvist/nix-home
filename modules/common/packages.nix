# Common Packages — profile-gated composer
#
# Canonical source of truth for user-level development packages, split into
# domain groups under ./packages/ so a host profile can drop the groups a
# headless server does not need.
#
# Usage:
#   - nix-home: imported in home-manager/common.nix → home.packages, with the
#     resolved `home-profile.features` passed in as `features`.
#   - nix-darwin: consumed via nix-home (no local copy)
#
# Always installed: core, security, cloud.
# Gated by feature toggle: document-processing, python-env, google-workspace.
# The `workstation` preset enables every feature, so its package set is
# identical to the pre-split flat list.

{
  pkgs,
  lib,
  features,
}:

let
  core = import ./packages/core.nix { inherit pkgs; };
  security = import ./packages/security.nix { inherit pkgs; };
  cloud = import ./packages/cloud.nix { inherit pkgs; };
  documentProcessing = import ./packages/document-processing.nix { inherit pkgs lib; };
  pythonEnv = import ./packages/python-env.nix { inherit pkgs; };
  googleWorkspace = import ./packages/google-workspace.nix { inherit pkgs; };
in
core
++ security
++ cloud
++ lib.optionals features.documentSkills.enable documentProcessing
++ lib.optionals features.heavyPython.enable pythonEnv
++ lib.optionals features.googleWorkspace.enable googleWorkspace
