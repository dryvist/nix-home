# Claude Document-Skills Runtime
#
# The /document-skills:{docx,pptx} skills generate JavaScript that imports
# `docx` and `pptxgenjs` — neither is in nixpkgs. Rather than add a second
# JS runtime (nodejs), we use the globally-available `bun` (see
# modules/common/packages.nix) to install these as bun globals on every
# home-manager activation.
#
# Returns `{ activation }` for merging into home.activation in common.nix.

{ pkgs, lib, ... }:

{
  activation = {
    # `bun add -g` is idempotent — it's a no-op when the requested version
    # is already present. BUN_INSTALL is set explicitly so bun writes to a
    # predictable location that does not depend on the caller's env.
    installDocumentSkillNpmDeps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export BUN_INSTALL="$HOME/.bun"
      export PATH="${pkgs.bun}/bin:$BUN_INSTALL/bin:$PATH"
      $DRY_RUN_CMD ${pkgs.bun}/bin/bun add -g docx@^9 pptxgenjs@^3
    '';
  };
}
