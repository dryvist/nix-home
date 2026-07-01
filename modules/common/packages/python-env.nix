# Python environment + tooling.
#
# Gated by `home-profile.features.heavyPython`. `pyright` (type checker) is
# grouped here alongside the interpreter env it checks against. The single
# python314 interpreter has all modules importable at once and pulls
# document-skills deps (pandas, pillow, markitdown) which transitively drag
# arrow-cpp — heavy, and unwanted on a headless server. This repo's flake also
# exports `grip` as a standalone package (nix run .#grip) via
# overlays/python-packages.nix + packages/grip.nix.
#
# NOTE: python3 cannot be overridden at the overlay level on Darwin because it's
# used by stdenv bootstrapping. Reference python314 explicitly.

{ pkgs }:

with pkgs;
[
  pyright # Static type checker for Python
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
