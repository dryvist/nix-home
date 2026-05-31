# Python Package Overlays
#
# Replaces python314 with nixpkgs-unstable's version where all packages
# are Python 3.14-compatible. nixpkgs-26.05 ships outdated PyO3/pydantic-core/
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
  # overlays/darwin-test-skips.nix for the rationale.
  pkgsUnstable = import nixpkgs-unstable {
    inherit (prev.stdenv.hostPlatform) system;
    overlays = [ (import ./darwin-test-skips.nix) ];
  };

  # Skip flaky audio tests/import-checks on aarch64-darwin. Multiple python
  # audio packages get SIGKILLed in the macOS Nix sandbox during their test
  # or pythonImportsCheck phases — same sandbox issue as the kvazaar/
  # chromaprint overlay in darwin-test-skips.nix.
  #
  # Affected and the failure mode:
  #   - openai-whisper: test_audio.py::test_audio fails to load JFK sample
  #   - av (PyAV ffmpeg bindings): pythonImportsCheckPhase SIGKILLed on
  #     `import av` (sandbox kills the av subprocess that loads ffmpeg libs)
  #   - faster-whisper: same sandbox kill on its import / test phases (av is
  #     a runtime dep, so disable proactively)
  #   - speechrecognition: pytestCheckPhase SIGKILLed during test collection
  #     (newer 3.16.x ships a pytest suite that exercises audio subprocesses)
  #
  # Setting both doCheck and doInstallCheck = false skips checkPhase and
  # the python-imports-check setup-hook (which lives in installCheckPhase).
  skipDarwinChecks =
    python-prev: name:
    python-prev.${name}.overridePythonAttrs (_: {
      doCheck = false;
      doInstallCheck = false;
      pythonImportsCheck = [ ];
    });

  pythonPackageOverrides = python-final: python-prev: {
    grip = python-final.callPackage ../packages/grip.nix { };
    openai-whisper = skipDarwinChecks python-prev "openai-whisper";
    av = skipDarwinChecks python-prev "av";
    faster-whisper = skipDarwinChecks python-prev "faster-whisper";
    speechrecognition = skipDarwinChecks python-prev "speechrecognition";
  };
in
{
  # Replace python314 with unstable's version where pydantic-core, astor,
  # and other packages are updated for Python 3.14 compatibility.
  # Consumers should reference python314 explicitly (not python3).
  python314 = pkgsUnstable.python314.override {
    packageOverrides = pythonPackageOverrides;
  };
  python314Packages = final.python314.pkgs;
}
