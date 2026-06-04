# Pre-commit Hook Tools Module
#
# Provides a comprehensive set of pre-commit tools organized into logical groups:
# - Format & Style: Code formatting and style enforcement
# - Lint & Analysis: Code quality and pattern checking
# - Content Quality: Documentation and link validation (includes lychee)
# - Security: Security-focused checks
#
# These tools run via .pre-commit-config.yaml during git commit.
# Installation: per-repo `pre-commit install`, typically invoked from the
# repo's Nix dev shellHook (e.g. cachix/git-hooks.nix installationScript).
# Manual run: `pre-commit run --all-files`
#
# This module is a single source of truth for all pre-commit tooling,
# consolidating definitions that previously lived in multiple locations.
#
# Usage:
#   This module exports tool definitions as reference material.
#   Tools are installed via home-manager in the main home.nix configuration.

{ lib, pkgs, ... }:

# Export tool definitions and metadata as a reference library
{
  # Tool definitions organized by purpose/group
  # Used by .pre-commit-config.yaml and documentation

  groups = {
    # ========================================================================
    # GROUP 1: FORMAT & STYLE
    # Purpose: Enforce consistent code formatting and whitespace rules
    # Run: Automatic (block commits if formatting issues found)
    # ========================================================================
    formatAndStyle = {
      description = "Code formatting and style enforcement";
      tools = [
        {
          id = "trailing-whitespace";
          name = "Trailing whitespace (pre-commit)";
          description = "Fixes trailing whitespace in files";
          package = "pre-commit/pre-commit-hooks";
        }
        {
          id = "end-of-file-fixer";
          name = "End-of-file fixer (pre-commit)";
          description = "Ensures files end with newline";
          package = "pre-commit/pre-commit-hooks";
        }
        {
          id = "nix-fmt-check";
          name = "Nix formatting (nixfmt-rfc-style)";
          command = "nixfmt --check";
          description = "Formats Nix code to RFC style";
          fileTypes = [ "nix" ];
          package = "pkgs.nixfmt-rfc-style";
        }
        {
          id = "markdownlint-cli2";
          name = "Markdown linting";
          command = "markdownlint-cli2";
          description = "Lints markdown files; auto-fixes enabled in config";
          fileTypes = [ "markdown" ];
          package = "pkgs.markdownlint-cli2";
          configFile = ".markdownlint-cli2.jsonc";
        }
      ];
    };

    # ========================================================================
    # GROUP 2: LINT & ANALYSIS
    # Purpose: Catch code quality issues, anti-patterns, and dead code
    # Run: Automatic (block commits if issues found)
    # ========================================================================
    lintAndAnalysis = {
      description = "Code quality and pattern checking";
      tools = [
        {
          id = "check-yaml";
          name = "YAML syntax check (pre-commit)";
          description = "Validates YAML file syntax";
          package = "pre-commit/pre-commit-hooks";
        }
        {
          id = "check-json";
          name = "JSON syntax check (pre-commit)";
          description = "Validates JSON file syntax";
          package = "pre-commit/pre-commit-hooks";
        }
        {
          id = "nix-statix";
          name = "Nix linting (statix)";
          command = "statix check";
          description = "Catches Nix anti-patterns and code smells";
          fileTypes = [ "nix" ];
          package = "pkgs.statix";
        }
        {
          id = "nix-deadnix";
          name = "Nix dead code (deadnix)";
          command = "deadnix -L --fail";
          description = "Detects unused Nix bindings";
          fileTypes = [ "nix" ];
          package = "pkgs.deadnix";
        }
      ];
    };

    # ========================================================================
    # GROUP 3: CONTENT QUALITY
    # Purpose: Validate documentation integrity, links, and content correctness
    # Run: Automatic (blocks commits if issues found)
    # ========================================================================
    contentQuality = {
      description = "Documentation and content validation";
      tools = [
        {
          id = "lychee";
          name = "Lychee link checker";
          command = "lychee";
          description = "Checks links in markdown and HTML files for validity (async, cached for performance)";
          fileTypes = [
            "markdown"
            "html"
          ];
          package = "pkgs.lychee";
          stage = "automatic";
          notes = "Runs automatically on every commit. All hooks execute in parallel.";
        }
        {
          id = "file-size-check";
          name = "File size check";
          command = "scripts/workflows/check-file-sizes.sh";
          description = "Warns on large files (6KB), fails over 12KB";
          stage = "automatic";
        }
      ];
    };

    # ========================================================================
    # GROUP 4: SECURITY
    # Purpose: Prevent committing secrets and sensitive data
    # Run: Automatic (block commits if secrets detected)
    # ========================================================================
    security = {
      description = "Secret and sensitive data detection";
      tools = [
        {
          id = "detect-private-key";
          name = "Detect private keys (pre-commit)";
          description = "Prevents committing private keys and credentials";
          package = "pre-commit/pre-commit-hooks";
        }
        {
          id = "check-merge-conflict";
          name = "Check merge conflict markers (pre-commit)";
          description = "Detects unresolved merge conflicts";
          package = "pre-commit/pre-commit-hooks";
        }
        {
          id = "check-added-large-files";
          name = "Check large files (pre-commit)";
          command = "check-added-large-files --maxkb=500";
          description = "Prevents committing files over 500KB";
          package = "pre-commit/pre-commit-hooks";
        }
      ];
    };
  };

  # Quick reference: tool metadata for documentation
  toolReference = {
    lychee = {
      name = "Lychee";
      description = "Fast, async link checker for markdown and HTML";
      homepage = "https://github.com/lycheeverse/lychee";
      package = "pkgs.lychee";
      language = "Rust";
    };
    statix = {
      name = "statix";
      description = "Lints and suggests improvements for Nix code";
      homepage = "https://github.com/nerdypepper/statix";
      package = "pkgs.statix";
      language = "Rust";
    };
    deadnix = {
      name = "deadnix";
      description = "Finds and removes dead code in Nix";
      homepage = "https://github.com/astro/deadnix";
      package = "pkgs.deadnix";
      language = "Rust";
    };
    nixfmtRfcStyle = {
      name = "nixfmt-rfc-style";
      description = "Opinionated Nix formatter following RFC style";
      homepage = "https://github.com/NixOS/nixfmt";
      package = "pkgs.nixfmt-rfc-style";
      language = "Rust";
    };
    markdownlintCli2 = {
      name = "markdownlint-cli2";
      description = "Fast, flexible Node.js markdown linter";
      homepage = "https://github.com/DavidAnson/markdownlint-cli2";
      package = "pkgs.markdownlint-cli2";
      language = "JavaScript";
    };
  };
}
