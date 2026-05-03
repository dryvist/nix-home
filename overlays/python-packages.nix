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
  # Construct pkgsUnstable with the kvazaar test-skip overlay applied so
  # markitdown's transitive ffmpeg-headless build doesn't pull in a kvazaar
  # whose CMake test suite gets SIGKILLed by the macOS Nix sandbox.
  # legacyPackages doesn't accept overlays, so import directly. See
  # overlays/kvazaar-skip-tests.nix for the rationale.
  pkgsUnstable = import nixpkgs-unstable {
    inherit (prev.stdenv.hostPlatform) system;
    overlays = [ (import ./kvazaar-skip-tests.nix) ];
  };

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
