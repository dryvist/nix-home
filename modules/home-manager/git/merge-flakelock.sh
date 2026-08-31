#!/usr/bin/env bash
# Fail-closed Git merge driver for flake.lock
#
# Usage in .gitattributes:
#   flake.lock merge=flakelock
#
# Usage in git config:
#   [merge "flakelock"]
#     name = Require explicit flake.lock regeneration
#     driver = ~/.local/bin/git-merge-flakelock %O %A %B

set -euo pipefail

echo "ERROR: flake.lock cannot be merged safely; resolve it with nix flake lock" >&2
exit 1
