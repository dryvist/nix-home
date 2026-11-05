# Wiring checks split from lib/checks.nix to keep each file under the shared
# file-size gate. checks.nix merges this attribute set into its output.
{
  pkgs,
  lib ? pkgs.lib,
}:
{
  # Exercise the publish gate's fail-closed behavior without requiring a live judge.
  gh-guard =
    pkgs.runCommand "check-gh-guard"
      {
        nativeBuildInputs = [
          pkgs.bash
          pkgs.coreutils
          pkgs.curl
          pkgs.gawk
          pkgs.git
          pkgs.gnugrep
          pkgs.jq
          pkgs.python3
        ];
      }
      ''
        cp -r ${../modules/home-manager/gh} "$TMPDIR/gh-guard"
        chmod -R u+w "$TMPDIR/gh-guard"
        patchShebangs "$TMPDIR/gh-guard/tests/fakegh"
        patchShebangs "$TMPDIR/gh-guard/tests/fakecurl"
        GH_GUARD_TEST_CI=1 bash "$TMPDIR/gh-guard/tests/run-gh-guard-tests.sh"
        touch $out
      '';

  # The publish gate takes its judge endpoint and model from module options: a
  # wrapper built with them set carries them, and one built without exports none.
  gh-guard-judge-options =
    let
      wrapperFor =
        judgeUrl: judgeModel:
        (lib.evalModules {
          specialArgs = {
            inherit pkgs;
            commitMessagePattern = "^$";
          };
          modules = [
            ../modules/home-manager/gh
            {
              options.xdg.configHome = lib.mkOption {
                type = lib.types.str;
                default = "/nonexistent";
              };
              options.home.file = lib.mkOption {
                type = lib.types.attrsOf lib.types.raw;
                default = { };
              };
              config.programs.ghGuard = { inherit judgeUrl judgeModel; };
            }
          ];
        }).config.home.file.".local/bin/gh".source;
      judgeUrl = "http://judge-fixture/v1/chat/completions";
      judgeModel = "fixture-model";
      configured = wrapperFor judgeUrl judgeModel;
      unconfigured = wrapperFor "" "";
      # The exact export lines the module writes. `${VAR:-value}` keeps a caller's
      # variable winning, so the check pins that form, not just the value.
      urlExport = "export GH_GUARD_JUDGE_URL=\${GH_GUARD_JUDGE_URL:-${lib.escapeShellArg judgeUrl}}";
      modelExport = "export GH_GUARD_JUDGE_MODEL=\${GH_GUARD_JUDGE_MODEL:-${lib.escapeShellArg judgeModel}}";
    in
    pkgs.runCommand "check-gh-guard-judge-options" { } ''
      grep -qF ${lib.escapeShellArg urlExport} ${configured}
      grep -qF ${lib.escapeShellArg modelExport} ${configured}
      ! grep -q 'export GH_GUARD_JUDGE_' ${unconfigured}
      touch $out
    '';

  # `use children` loads each directory once and skips non-default worktrees.
  direnv-use-children =
    pkgs.runCommand "check-direnv-use-children"
      {
        nativeBuildInputs = [
          pkgs.direnv
          pkgs.git
        ];
      }
      ''
        bash ${../modules/home-manager/direnv/tests/run-use-children-tests.sh} \
          ${
            pkgs.replaceVars ../modules/home-manager/direnv/use-children.sh {
              jq = lib.getExe pkgs.jq;
              git = lib.getExe pkgs.git;
            }
          } \
          ${pkgs.nix-direnv}/share/nix-direnv/direnvrc \
          ${../modules/home-manager/direnv/workspace.envrc}
        touch $out
      '';

  # The workspace .envrc linker acts only on real grouping directories.
  workspace-envrc-linker = pkgs.runCommand "check-workspace-envrc-linker" { } ''
    bash ${../modules/home-manager/scripts/tests/run-link-workspace-envrc-tests.sh} \
      ${../modules/home-manager/scripts/link-workspace-envrc.sh}
    touch $out
  '';

  # Telemetry wiring regression.
  #
  # `monitoring.otel` exports OTEL_* through home.sessionVariables, i.e. into
  # the login shell that launches Claude Code. Both the endpoint and the
  # protocol previously defaulted to a loopback gRPC NodePort that no collector
  # served, so enabling telemetry produced a complete, plausible-looking export
  # that went nowhere — silently, with nothing in the config to show for it.
  #
  # Evaluates the monitoring module on its own rather than the full home
  # configuration: the assertions here are about this module's own options, and
  # a standalone evalModules keeps the check cheap enough to run everywhere the
  # heavyweight module-eval cannot.
  monitoring-otel-wiring =
    let
      evalMonitoring =
        settings:
        (lib.evalModules {
          modules = [
            ../modules/monitoring
            { _module.args = { inherit pkgs; }; }
            # Minimal stand-ins for the two home-manager options this module
            # writes to. Declaring them here keeps the check independent of a
            # full home-manager evaluation, which is what makes it cheap.
            {
              options.home = {
                packages = lib.mkOption {
                  type = lib.types.listOf lib.types.package;
                  default = [ ];
                };
                sessionVariables = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = { };
                };
              };
            }
            { monitoring = settings; }
          ];
          specialArgs.orbstackKubernetesSrc = "/nonexistent-test-src";
        }).config;

      withEndpoint = evalMonitoring {
        enable = true;
        otel = {
          enable = true;
          endpoint = "https://otel.test.invalid";
        };
      };

      withoutEndpoint = evalMonitoring {
        enable = true;
        otel.enable = true;
      };

      vars = c: c.home.sessionVariables or { };
      has = c: k: builtins.hasAttr k (vars c);

      results = [
        {
          name = "protocol defaults to http/protobuf";
          actual = withEndpoint.monitoring.otel.protocol;
          expected = "http/protobuf";
        }
        {
          name = "endpoint defaults to null";
          actual = withoutEndpoint.monitoring.otel.endpoint;
          expected = null;
        }
        {
          name = "endpoint exported verbatim when set";
          actual = (vars withEndpoint).OTEL_EXPORTER_OTLP_ENDPOINT or null;
          expected = "https://otel.test.invalid";
        }
        {
          name = "protocol exported when endpoint is set";
          actual = (vars withEndpoint).OTEL_EXPORTER_OTLP_PROTOCOL or null;
          expected = "http/protobuf";
        }
        # The black-hole guard: enable alone must export nothing at all.
        {
          name = "no endpoint exported when endpoint is null";
          actual = has withoutEndpoint "OTEL_EXPORTER_OTLP_ENDPOINT";
          expected = false;
        }
        {
          name = "telemetry not enabled when endpoint is null";
          actual = has withoutEndpoint "CLAUDE_CODE_ENABLE_TELEMETRY";
          expected = false;
        }
      ];

      failures = builtins.filter (r: r.actual != r.expected) results;
      failureMsg = lib.concatStringsSep "\n" (
        map (
          r: "  ${r.name}: expected ${builtins.toJSON r.expected}, got ${builtins.toJSON r.actual}"
        ) failures
      );
    in
    assert failures == [ ] || throw "monitoring.otel regression:\n${failureMsg}";
    pkgs.runCommand "check-monitoring-otel-wiring" { } ''
      echo "monitoring.otel wiring: ${toString (builtins.length results)} assertions verified"
      touch $out
    '';
}
