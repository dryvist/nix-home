---
engine: copilot
imports:
  - githubnext/agentics/workflows/sub-issue-closer.md@main
on:
  schedule: daily
  workflow_dispatch:
permissions:
  contents: read
  issues: read
---

# Sub-Issue Closer

Close parent issues when all sub-issues reach 100% completion.
