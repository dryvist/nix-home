# Heavy Python environment — credential/GitHub automation + document-skills.
#
# Gated by `home-profile.features.heavyPython`. A single python314 interpreter
# with all modules importable at once. Pulls document-skills deps (pandas,
# pillow, markitdown) which transitively drag arrow-cpp — heavy, and unwanted on
# a headless server. This repo's flake also exports `grip` as a standalone
# package (nix run .#grip) via overlays/python-packages.nix + packages/grip.nix.
#
# NOTE: python3 cannot be overridden at the overlay level on Darwin because it's
# used by stdenv bootstrapping. Reference python314 explicitly.

{ pkgs }:

with pkgs;
[
  (python314.withPackages (ps: [
    ps.cryptography # Cryptographic recipes and primitives
    ps.pygithub # GitHub API v3 Python library
    ps.pyyaml # YAML parser/emitter for Python automation
    # Claude document-skills dependencies
    ps.pandas # xlsx: data manipulation
    ps.openpyxl # xlsx: formulas and formatting
    ps.pillow # pptx: thumbnail grids
    ps.markitdown # pptx: text extraction
  ]))
]
