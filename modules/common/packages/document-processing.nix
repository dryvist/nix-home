# Document-processing packages — runtime for Claude /document-skills.
#
# Gated by `home-profile.features.documentSkills`. Text extraction and
# PDF conversion tools; the npm libs (docx, pptxgenjs) are installed separately
# in modules/home-manager/document-skills.nix, and the Python libs live in
# python-env.nix.

{ pkgs, lib }:

with pkgs;
# LibreOffice: CLI soffice for docx/xlsx/pptx → PDF conversion.
# Not built for aarch64-darwin in nixpkgs — macOS uses the homebrew cask instead.
lib.optionals pkgs.stdenv.isLinux [
  libreoffice
]
++ [
  pandoc # Universal document converter (docx text extraction)
  poppler-utils # `pdftoppm` for PDF → image thumbnails
]
