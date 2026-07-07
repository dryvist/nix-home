# Markdownlint Configuration
#
# Provides global markdownlint-cli2 configuration for all markdown validation.
# This configuration is used by:
# - Pre-commit hooks during git commit
# - Claude Code markdown validation plugin
# - Manual markdown validation runs
#
# Configuration:
# - MD013: Line length set to 160 characters
# - MD013 tables: true
# - strict: true
# - ignores: CHANGELOG.md and .github/aw/**
#
# Usage:
#   markdownlint-cli2 --config ~/.markdownlint-cli2.yaml <file>
#   pre-commit run markdownlint-cli2 --all-files

{ config, ... }:

{
  # ~/.markdownlint-cli2.yaml - Markdownlint configuration (YAML format)
  ".markdownlint-cli2.yaml".source = ../../../.markdownlint-cli2.yaml;
}
