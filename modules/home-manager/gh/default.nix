# gh-guard — publish-boundary gate for the gh CLI
#
# Installs the guard as ~/.local/bin/gh. That directory is prepended to PATH
# ahead of the real `gh` (programs.gh.package, common.nix), so every
# interactive and scripted `gh` call is inspected before it reaches GitHub.
# The guard's own contract, detectors, and fail-closed behavior are documented
# in scripts/gh-guard.sh; this file only wires it into home-manager.
#
# The script's own fallback for GH_GUARD_REAL_GH (used only when the env var
# is unset) is baked to the real gh store path here, so the shim never
# resolves `gh` through PATH (that would recurse into itself). A plain string
# substitution, not runtimeEnv: runtimeEnv would `export` unconditionally and
# clobber a caller-supplied override, defeating the script's own
# `${GH_GUARD_REAL_GH:-default}` design (and the test suite's use of it).
#
# Return file definitions directly (merged into home.file in common.nix).

{ pkgs, ... }:

let
  ghGuardPkg = pkgs.writeShellApplication {
    name = "gh";
    runtimeInputs = [
      pkgs.jq
      pkgs.curl
      pkgs.gnugrep
      pkgs.coreutils
    ];
    text =
      builtins.replaceStrings
        [ "/etc/profiles/per-user/jevans/bin/gh" ]
        [
          "${pkgs.gh}/bin/gh"
        ]
        (builtins.readFile ./scripts/gh-guard.sh);
  };
in
{
  ".local/bin/gh".source = "${ghGuardPkg}/bin/gh";

  # Test suite, installed alongside so the gate is verifiable after a rebuild:
  #   GH_GUARD_BIN=$HOME/.local/bin/gh ~/.local/state/gh-guard/tests/run-gh-guard-tests.sh
  ".local/state/gh-guard/scripts" = {
    source = ./scripts;
    recursive = true;
  };
  ".local/state/gh-guard/tests" = {
    source = ./tests;
    recursive = true;
  };
}
