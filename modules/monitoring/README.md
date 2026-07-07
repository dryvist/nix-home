# Monitoring Module

Kubernetes-based observability infrastructure for Claude Code autonomous agents and AI development workflows.

## Architecture

```text
┌────────────────────────────────────────────────────────────────┐
│                        Log Sources                              │
├────────────────────────────────────────────────────────────────┤
│  Claude Logs          Ollama Logs          Terminal Logs        │
│  ~/.claude/logs/      ~/Library/Logs/      ~/logs/              │
└────────┬──────────────────┬────────────────────┬───────────────┘
         │                  │                    │
         ▼                  ▼                    ▼
┌────────────────────────────────────────────────────────────────┐
│                    OrbStack Kubernetes                          │
├────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │ OTEL Collector  │───▶│ Cribl Edge      │                    │
│  │ (traces/logs)   │    │ (log shipping)  │                    │
│  └─────────────────┘    └────────┬────────┘                    │
│                                  │                              │
└──────────────────────────────────┼──────────────────────────────┘
                                   ▼
                          ┌─────────────────┐
                          │ Cribl Cloud     │
                          │ (optional)      │
                          └─────────────────┘
```

## Components

| Directory | Purpose | Status |
| --- | --- | --- |
| `k8s/otel-collector/` | OpenTelemetry Collector for traces and log ingestion | Active |
| `k8s/cribl-edge/` | Cribl Edge for log shipping to Cribl Cloud | Active |
| `k8s/splunk/` | Local Splunk SIEM (disabled - ARM64 incompatible) | Disabled |

## Quick Start

```bash
# Ensure OrbStack K8s is running
orb status

# Deploy the stack
kubectl apply -k modules/monitoring/k8s/

# Check status
kubectl -n monitoring get pods
```

## Services

| Service | Ports | Access |
| --- | --- | --- |
| OTEL Collector | 4317 (gRPC), 4318 (HTTP), 13133 (health) | `kubectl port-forward svc/otel-collector 4317:4317` |
| Cribl Edge | 9420 (API), 9000 (UI) | `kubectl port-forward svc/cribl-edge 9000:9000` |

## Configuration

- **OTEL**: See `k8s/otel-collector/configmap.yaml` for receiver/exporter config
- **Cribl**: Runs in standalone "edge" mode by default; configure `CRIBL_DIST_MODE=managed-edge` for cloud connection

## Related Documentation

- [Main Monitoring Docs](../../docs/MONITORING.md)
- [Kubernetes Setup](../../docs/monitoring/KUBERNETES.md)
