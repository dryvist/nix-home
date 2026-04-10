# Claude Document-Skills Runtime
#
# The /document-skills:{docx,pptx} skills generate JavaScript that imports
# `docx` and `pptxgenjs`. Neither is in nixpkgs. Install them as npm globals
# into ~/.npm-packages (prefix configured in npm/config.nix) so the skills
# can `require('docx')` / `require('pptxgenjs')` via node out of the box.
#
# Returns `{ activation }` for merging into home.activation in common.nix.

{ pkgs, lib, ... }:

{
  activation = {
    # `npm install -g` is idempotent for matching versions — it's a no-op
    # when the requested package@version is already present. Path is set
    # explicitly so activation doesn't depend on the caller's shell init.
    installDocumentSkillNpmDeps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="${pkgs.nodejs}/bin:$HOME/.npm-packages/bin:$PATH"
      export npm_config_prefix="$HOME/.npm-packages"
      $DRY_RUN_CMD ${pkgs.nodejs}/bin/npm install -g --silent docx@^9 pptxgenjs@^3
    '';
  };
}
