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
# Declare the identifier-file option and install the guard and its tests.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.ghGuard;

  ghGuardPkg = pkgs.writeShellApplication {
    name = "gh";
    runtimeInputs = [
      pkgs.jq
      pkgs.curl
      pkgs.gnugrep
      pkgs.coreutils
      pkgs.python3
    ];
    runtimeEnv.GH_GUARD_DENYLIST_DEFAULT = cfg.identifierFile;
    text = builtins.replaceStrings [ "/etc/profiles/per-user/jevans/bin/gh" ] [ "${pkgs.gh}/bin/gh" ] (
      builtins.readFile ./scripts/gh-guard.sh
    );
  };
in
{
  options.programs.ghGuard.identifierFile = lib.mkOption {
    type = lib.types.str;
    default = "${config.xdg.configHome}/gh-guard/identifiers.txt";
    defaultText = lib.literalExpression ''"''${config.xdg.configHome}/gh-guard/identifiers.txt"'';
    description = "Path to the exact-identifier file checked before publishing.";
  };

  config.home.file = {
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
  };
}
