# Single source of truth for the standalone fallback `userConfig`.
#
# On a real machine, nix-darwin passes its own `userConfig` (identity, state
# version, git/gpg settings). This default only applies when nix-home is
# consumed WITHOUT one — standalone evaluation and the module-eval check.
#
# `homeManagerStateVersion` is a FROZEN home-manager compatibility marker. It is
# NOT a nixpkgs release and must not be bumped to track 26.05.

{
  nix.homeManagerStateVersion = "25.11";

  user = {
    name = "jevans";
    # Renamed account: noreply email must be ...+JacobPEvans-personal@ or commits
    # built from this standalone fallback fail signature verification (bad_email).
    # On the live machine nix-darwin's user-config.nix overrides this default.
    email = "20714140+JacobPEvans-personal@users.noreply.github.com";
    fullName = "JacobPEvans";
  };

  git = {
    editor = "vim";
    defaultBranch = "main";
  };

  gpg.signingKey = "";
}
