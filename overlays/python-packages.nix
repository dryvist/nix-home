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
  # legacyPackages doesn't accept overlays, so import directly.
  #
  # This used to carry overlays/darwin-test-skips.nix (kvazaar/chromaprint
  # doCheck = false) because markitdown dragged in ffmpeg-headless. Trimming
  # markitdown to the pptx converter (below) removed that whole chain, so the
  # overlay became dead code and was deleted — verified hash-neutral: the
  # resulting python3-3.14.7-env drvPath is byte-identical with and without it.
  pkgsUnstable = import nixpkgs-unstable {
    inherit (prev.stdenv.hostPlatform) system;
  };

  # Skip flaky audio tests/import-checks on aarch64-darwin. Multiple python
  # audio packages get SIGKILLed in the macOS Nix sandbox during their test
  # or pythonImportsCheck phases.
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

  # nixpkgs builds markitdown with every converter's dependency propagated
  # unconditionally — upstream makes them optional extras, but the derivation
  # exposes no `optional-dependencies`, so there is nothing to select. The only
  # consumer here is Claude's pptx document-skill, which shells out to
  # `python -m markitdown presentation.pptx`.
  #
  # Those unused converters are expensive, and two of them dominated a CI
  # timeout:
  #   pdfplumber   -> pandas-stubs -> pyarrow -> arrow-cpp   (C++, ~20 min)
  #   speechrecognition -> ffmpeg-headless -> kvazaar, chromaprint
  # plus the Azure SDK, mammoth, xlrd, olefile, pydub, youtube-transcript-api.
  #
  # Every converter imports its backend lazily inside a try/except that records
  # `_dependency_exc_info` and raises MissingDependencyException on use (see
  # markitdown/converters/_pptx_converter.py). So trimming the propagated set
  # leaves the package importable and the pptx path fully working; only the
  # converters we do not use degrade, and they degrade with a clear message.
  #
  # The retained set is what markitdown's core and the pptx/html converters
  # actually import: bs4, charset_normalizer, magika, requests (core),
  # defusedxml, markdownify (html), pptx (pptx).
  #
  # This forfeits markitdown's upstream narinfo — but markitdown has no darwin
  # binary cache coverage anyway, so nothing is lost.
  markitdownPptxOnly =
    python-prev:
    python-prev.markitdown.overridePythonAttrs (old: {
      dependencies = builtins.filter (
        p:
        builtins.elem (p.pname or p.name or "") [
          "beautifulsoup4"
          "charset-normalizer"
          "defusedxml"
          "magika"
          "markdownify"
          "python-pptx"
          "requests"
        ]
      ) (old.dependencies or old.propagatedBuildInputs or [ ]);
      # The test suite exercises every converter, including the ones just removed.
      doCheck = false;
      doInstallCheck = false;
      pythonImportsCheck = [ "markitdown" ];
    });

  pythonPackageOverrides = python-final: python-prev: {
    grip = python-final.callPackage ../packages/grip.nix { };
    openai-whisper = skipDarwinChecks python-prev "openai-whisper";
    av = skipDarwinChecks python-prev "av";
    faster-whisper = skipDarwinChecks python-prev "faster-whisper";
    speechrecognition = skipDarwinChecks python-prev "speechrecognition";
    markitdown = markitdownPptxOnly python-prev;
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
