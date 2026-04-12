---
engine: copilot
imports:
  - githubnext/agentics/workflows/ci-doctor.md@main
on:
  workflow_run:
    workflows: ["CI Gate"]
    types: [completed]
    branches: [main]
if: ${{ github.event.workflow_run.conclusion == 'failure' || github.event.workflow_run.conclusion == 'cancelled' }}
---

# CI Doctor

Investigate CI workflow failures, analyze logs, and create issues with root cause analysis.
