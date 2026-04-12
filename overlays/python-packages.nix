# Python Package Overlays
#
# Replaces python314 with nixpkgs-unstable's version where all packages
# are Python 3.14-compatible. nixpkgs-25.11 ships outdated PyO3/pydantic-core/
# astor that can't build against Python 3.14's C API changes.
#
# Using the entire python314 (not individual packages) avoids Python derivation
# store-path mismatch between nixpkgs instances.
#
# NOTE: python3 cannot be overridden at the overlay level on Darwin because
# it is used by stdenv bootstrapping (AvailabilityVersions). Overriding it
# triggers infinite recursion in the stdenv boot chain. Instead, we only
# override python314/python314Packages and reference python314 explicitly.

{ nixpkgs-unstable }:
final: prev:
let
  pkgsUnstable = nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system};

  gripOverride = python-final: _python-prev: {
    grip = python-final.callPackage ../packages/grip.nix { };
  };
in
{
  # Replace python314 with unstable's version where pydantic-core, astor,
  # and other packages are updated for Python 3.14 compatibility.
  # Consumers should reference python314 explicitly (not python3).
  python314 = pkgsUnstable.python314.override {
    packageOverrides = gripOverride;
  };
  python314Packages = final.python314.pkgs;
}
