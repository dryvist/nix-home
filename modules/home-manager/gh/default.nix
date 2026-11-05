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
# Declare the identifier-file and judge options and install the guard and its
# tests. The judge options are baked in as defaults the script reads, so a
# caller needs no environment.

{
  config,
  lib,
  pkgs,
  commitMessagePattern,
  ...
}:

let
  cfg = config.programs.ghGuard;

  # Exported only when the option is set, so an empty option keeps the script's
  # own discovery. `${VAR:-value}` keeps a caller-supplied variable winning.
  judgeExports = lib.concatStrings [
    (lib.optionalString (cfg.judgeUrl != "") ''
      export GH_GUARD_JUDGE_URL=''${GH_GUARD_JUDGE_URL:-${lib.escapeShellArg cfg.judgeUrl}}
    '')
    (lib.optionalString (cfg.judgeModel != "") ''
      export GH_GUARD_JUDGE_MODEL=''${GH_GUARD_JUDGE_MODEL:-${lib.escapeShellArg cfg.judgeModel}}
    '')
  ];

  ghGuardPkg = pkgs.writeShellApplication {
    name = "gh";
    runtimeInputs = [
      pkgs.jq
      pkgs.curl
      pkgs.gnugrep
      pkgs.coreutils
      pkgs.python3
    ];
    runtimeEnv = {
      GH_GUARD_DENYLIST_DEFAULT = cfg.identifierFile;
      GH_GUARD_TITLE_PATTERN = commitMessagePattern;
    };
    text =
      judgeExports
      + builtins.replaceStrings [ "/etc/profiles/per-user/jevans/bin/gh" ] [ "${pkgs.gh}/bin/gh" ] (
        builtins.readFile ./scripts/gh-guard.sh
      );
  };
in
{
  options.programs.ghGuard = {
    identifierFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.configHome}/gh-guard/identifiers.txt";
      defaultText = lib.literalExpression ''"''${config.xdg.configHome}/gh-guard/identifiers.txt"'';
      description = "Path to the exact-identifier file checked before publishing.";
    };

    judgeUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Judge endpoint for the publish gate. Empty keeps the script's own endpoint; GH_GUARD_JUDGE_URL overrides it.";
    };

    judgeModel = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Judge model for the publish gate. Empty keeps the script's default; GH_GUARD_JUDGE_MODEL overrides it.";
    };
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
