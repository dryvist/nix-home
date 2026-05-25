# Monitoring Infrastructure Module
#
# Provides deployment scripts and OTEL configuration for the monitoring stack.
# Kubernetes manifests are managed in the orbstack-kubernetes repository:
#   https://github.com/JacobPEvans/orbstack-kubernetes
#
# Usage:
#   imports = [ ./modules/monitoring ];
{
  config,
  lib,
  pkgs,
  orbstackKubernetesSrc,
  ...
}:

let
  cfg = config.monitoring;
in
{
  options.monitoring = {
    enable = lib.mkEnableOption "Monitoring infrastructure";

    kubernetes = {
      enable = lib.mkEnableOption "Kubernetes-based monitoring stack";

      repoPath = lib.mkOption {
        type = lib.types.str;
        default = "${orbstackKubernetesSrc}";
        description = ''
          Path to the orbstack-kubernetes source tree.

          Defaults to the `orbstack-kubernetes` flake input (a Nix store
          path), which makes deploys reproducible against this nix-home
          generation. Override to point at a local checkout if you need to
          test manifest changes against a deploy, or use
          `--override-input orbstack-kubernetes path:<checkout>` on the
          consuming flake for the same effect at the flake level.
        '';
      };

      namespace = lib.mkOption {
        type = lib.types.str;
        default = "monitoring";
        description = "Kubernetes namespace for monitoring components";
      };

      context = lib.mkOption {
        type = lib.types.str;
        default = "orbstack";
        description = "kubectl context to use for deployments";
      };
    };

    otel = {
      enable = lib.mkEnableOption "OpenTelemetry Collector";

      endpoint = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:30317";
        description = "OTLP endpoint (defaults to gRPC NodePort for OrbStack K8s; use :30318 for http/* protocols)";
      };

      protocol = lib.mkOption {
        type = lib.types.enum [
          "grpc"
          "http/protobuf"
          "http/json"
        ];
        default = "grpc";
        description = "OTLP exporter protocol";
      };

      logPrompts = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Include user prompt content in OTEL events (privacy-sensitive).
          WARNING: This logs full conversation content including potentially sensitive data.
          Only enable in trusted environments where you control the OTEL pipeline.
        '';
      };

      logToolDetails = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Include MCP server/tool names in OTEL events";
      };

      resourceAttributes = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "OTEL resource attributes (key=value pairs). Values must not contain commas.";
      };
    };

    cribl = {
      enable = lib.mkEnableOption "Cribl Edge log shipper";

      cloudUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Cribl Cloud organization URL (e.g., https://your-org.cribl.cloud:4200)";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      # Helper scripts for Kubernetes-based monitoring
      packages = lib.mkIf cfg.kubernetes.enable [
        # NOTE: There is no `monitoring-deploy` wrapper here on purpose.
        # The deploy pipeline lives in orbstack-kubernetes/Makefile (which
        # calls scripts/deploy-doppler.sh → scripts/deploy.sh). Wrapping
        # it from nix-home added no abstraction value beyond putting a
        # name on $PATH — and the underlying scripts mutate the source
        # tree (`generate-overlay.sh` writes back to `k8s/overlays/local/`),
        # which conflicts with serving the source from the read-only Nix
        # store. To deploy: `cd <orbstack-kubernetes worktree> && make
        # deploy-doppler`. The `orbstack-kubernetes` flake input above
        # keeps the manifests pinned + reachable for any downstream
        # consumer that needs the path (e.g. `monitoring.kubernetes.repoPath`).

        (pkgs.writeShellScriptBin "monitoring-status" ''
          set -euo pipefail

          CONTEXT="${cfg.kubernetes.context}"
          NAMESPACE="${cfg.kubernetes.namespace}"

          echo "=== Monitoring Stack Status ==="
          echo ""
          kubectl --context "$CONTEXT" -n "$NAMESPACE" get all
          echo ""
          echo "=== Pod Logs (last 10 lines each) ==="
          kubectl --context "$CONTEXT" -n "$NAMESPACE" get pods -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | while IFS= read -r pod; do
            echo ""
            echo "--- $pod ---"
            kubectl --context "$CONTEXT" -n "$NAMESPACE" logs "$pod" --tail=10 2>/dev/null || echo "(no logs yet)"
          done
        '')

        (pkgs.writeShellScriptBin "monitoring-logs" ''
          set -euo pipefail

          CONTEXT="${cfg.kubernetes.context}"
          NAMESPACE="${cfg.kubernetes.namespace}"

          kubectl --context "$CONTEXT" -n "$NAMESPACE" logs \
            -l app.kubernetes.io/part-of=claude-monitoring \
            --all-containers --tail=50 -f
        '')
      ];

      # Set OTEL environment variables for Claude Code
      sessionVariables = lib.mkIf cfg.otel.enable (
        {
          CLAUDE_CODE_ENABLE_TELEMETRY = "1";
          OTEL_EXPORTER_OTLP_ENDPOINT = cfg.otel.endpoint;
          OTEL_EXPORTER_OTLP_PROTOCOL = cfg.otel.protocol;
          OTEL_METRICS_EXPORTER = "otlp";
          OTEL_LOGS_EXPORTER = "otlp";
          OTEL_SERVICE_NAME = "claude-code";
          OTEL_METRICS_INCLUDE_SESSION_ID = "true";
          OTEL_METRICS_INCLUDE_VERSION = "true";
          OTEL_METRICS_INCLUDE_ACCOUNT_UUID = "true";
        }
        // lib.optionalAttrs cfg.otel.logPrompts { OTEL_LOG_USER_PROMPTS = "1"; }
        // lib.optionalAttrs cfg.otel.logToolDetails { OTEL_LOG_TOOL_DETAILS = "1"; }
        // lib.optionalAttrs (cfg.otel.resourceAttributes != { }) {
          OTEL_RESOURCE_ATTRIBUTES = lib.concatStringsSep "," (
            lib.mapAttrsToList (k: v: "${k}=${v}") cfg.otel.resourceAttributes
          );
        }
      );
    };
  };
}
