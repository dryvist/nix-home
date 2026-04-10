# Claude Document-Skills Runtime
#
# The /document-skills:{docx,pptx} skills generate JavaScript that imports
# `docx` and `pptxgenjs`. Neither is in nixpkgs. Install them as npm globals
# into ~/.npm-packages (prefix configured in npm/config.nix) so the skills
# can `require('docx')` / `require('pptxgenjs')` via node out of the box.
#
# The actual install logic lives in
#   modules/home-manager/scripts/install-document-skills-npm-deps.sh
# exposed as the `install-document-skills-npm-deps` overlay package. Version
# pins are passed via env so they stay declarative in this file (bump them
# deliberately, not via semver drift).
#
# Returns `{ activation }` for merging into home.activation in common.nix.

{ pkgs, lib, ... }:

let
  # Exact pins for reproducibility — bump deliberately.
  docxVersion = "9.6.1";
  pptxgenjsVersion = "4.0.1";

  installScript = "${pkgs.install-document-skills-npm-deps}/bin/install-document-skills-npm-deps";
in
{
  activation = {
    installDocumentSkillNpmDeps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export DOCX_VERSION="${docxVersion}"
      export PPTXGENJS_VERSION="${pptxgenjsVersion}"
      export NPM_GLOBAL_PREFIX="$HOME/.npm-packages"
      $DRY_RUN_CMD ${installScript}
    '';
  };
}
