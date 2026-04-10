# Common Packages
#
# Universal dev tools installed on ALL systems (macOS, Linux, etc.)
# Canonical source of truth for user-level development packages.
#
# Usage:
#   - nix-home: imported in home-manager/common.nix → home.packages
#   - nix-darwin: consumed via nix-home (no local copy)
#
# NOTE: This file returns a function that takes pkgs and returns a list of packages.

{ pkgs }:

with pkgs;
lib.optionals pkgs.stdenv.isLinux [
  # LibreOffice: CLI soffice for docx/xlsx/pptx → PDF conversion (document-skills).
  # Not built for aarch64-darwin in nixpkgs — macOS uses the homebrew cask instead.
  libreoffice
]
++ [
  # ==========================================================================
  # Git & Pre-commit Hooks
  # ==========================================================================
  # Framework for managing git pre-commit hooks - essential for code quality
  pre-commit

  # Git Workflow
  (pkgs.callPackage ./git-flow-next.nix { }) # git-flow branching workflow — required for all non-personal repos
  git-bug # Distributed bug tracker embedded in git (git bug command)

  # ==========================================================================
  # JavaScript Runtimes
  # ==========================================================================
  # bun: fast all-in-one runtime (provides bunx) — general CLI/script use.
  # nodejs: needed globally for Claude document-skills, which generate scripts
  # that `require('docx')` / `require('pptxgenjs')` and are executed with
  # `node`. Those npm libs are installed to ~/.npm-packages via npm install -g
  # in a home.activation entry (see modules/home-manager/document-skills.nix).
  bun
  nodejs

  # ==========================================================================
  # Modern CLI Tools
  # ==========================================================================
  # Popular alternatives to traditional Unix tools. Enhance productivity
  # for both humans and AI assistants (syntax highlighting, fuzzy finding).

  bat # Better cat with syntax highlighting
  delta # Better git diff viewer with syntax highlighting
  eza # Modern ls replacement with git integration
  fd # Faster, user-friendly find alternative
  fzf # Fuzzy finder for interactive selection
  gnugrep # GNU grep with zgrep for compressed files
  gnutar # GNU tar as 'gtar' (Mac-safe tar without ._* files)
  btop # Modern process monitor with graphs (replaces htop for daily use)
  htop # Interactive process viewer (better top)
  jq # JSON parsing for config files and API responses
  ncdu # NCurses disk usage analyzer
  ripgrep # Fast grep alternative (rg) - essential for AI agents
  tldr # Simplified, community-driven man pages
  tree # Directory tree visualization
  watchexec # File watcher that re-executes commands on changes
  yq # YAML parsing (like jq but for YAML/XML/TOML)
  zellij # Modern terminal multiplexer (Rust, layout engine)

  # ==========================================================================
  # Visualization & Diagramming
  # ==========================================================================
  # CLI tools for generating diagrams from text/code.

  d2 # Modern diagram scripting language (D2lang)
  mermaid-cli # Mermaid diagram generator CLI (mmdc)

  # ==========================================================================
  # Document Processing (Claude document-skills)
  # ==========================================================================
  # Runtime dependencies for /document-skills:{docx,xlsx,pptx} — text
  # extraction, PDF conversion, and PDF→image thumbnails. Python libs live
  # in the python314.withPackages env below; npm libs (docx, pptxgenjs) are
  # installed via bun in modules/home-manager/document-skills.nix.
  # NOTE: libreoffice is Linux-only here — see conditional block at top of
  # this file. On macOS it's installed as a homebrew cask by nix-darwin.
  pandoc # Universal document converter (docx text extraction)
  poppler-utils # `pdftoppm` for PDF → image thumbnails

  # ==========================================================================
  # Universal Linters
  # ==========================================================================
  # These are the most common linters used across projects. They support
  # pre-commit hooks and should be available on any development machine.

  # Shell
  shellcheck # Shell script static analysis (POSIX, bash)
  shfmt # Shell script formatter
  bats # Bash Automated Testing System for shell script testing

  # Documentation
  cspell # Spell checker for code and documentation
  lychee # Link checker for markdown and HTML (validates URLs in docs)
  markdownlint-cli2 # Markdown linter (README, docs exist everywhere)

  # CI/CD
  actionlint # GitHub Actions workflow linter

  # Nix (2025 official tooling)
  nixfmt-rfc-style # Official Nix formatter (RFC 166, v1.1.0+)
  statix # Nix linter - catches anti-patterns
  deadnix # Find unused code in .nix files
  treefmt # Multi-language formatter runner
  nix-tree # Browse Nix store dependencies interactively

  # JSON
  check-jsonschema # JSON Schema validator CLI (for settings validation)

  # ==========================================================================
  # Security & Credential Management
  # ==========================================================================
  # Password management and secure credential storage for all environments.

  bitwarden-cli # CLI for Bitwarden password manager (bw command)
  bws # Bitwarden Secrets Manager CLI (for machine secrets)
  doppler # Doppler secrets manager CLI (for CI/CD and team secrets)
  aws-vault # AWS credential management — session credentials backed by the OS keychain/credential store (used by av/avl/avd/ava/avr aliases)

  # ==========================================================================
  # Remote Shell
  # ==========================================================================
  # Resilient mobile shell using UDP - survives network handoffs.
  mosh

  # ==========================================================================
  # Google Workspace CLI Tools
  # ==========================================================================
  # CLI tools for managing Gmail filters, Google Drive sync, and file management.

  gmailctl # Declarative Gmail filter management via Jsonnet (apply/diff/test)
  rclone # Cloud storage sync — Google Drive, S3, and 70+ backends
  gdrive3 # Google Drive CLI — upload, download, list, share, sync

  # ==========================================================================
  # Object Storage CLIs
  # ==========================================================================
  # S3-compatible object storage clients for upload, download, and bucket management.

  minio-client # MinIO/S3 client (mc) — upload, download, manage objects + bucket policies

  # ==========================================================================
  # HTTP & API Tools
  # ==========================================================================
  # Tools for testing and working with HTTP APIs and web services.
  # NOTE: RapidAPI (GUI) moved to home.packages for macOS with copyApps.
  # See hosts/macbook-m4/home.nix

  # ==========================================================================
  # Python Tools
  # ==========================================================================
  # Type checking and analysis tools for Python development.
  pyright # Static type checker for Python

  # Python interpreters: Multiple versions via Nix (no pip - packages via Nix only)
  # Available: python314 (with grip via overlay), python312
  # NOTE: python3 cannot be overridden at the overlay level on Darwin because
  # it is used by stdenv bootstrapping (AvailabilityVersions). Reference
  # python314 explicitly instead.
  # For Python 3.9 (Splunk, EOL): Use `uv run --python 3.9` (on-demand download)
  # python310 available per-repo via devShells
  # Individual interpreters at lower meta.priority to avoid /bin/idle conflict
  # with the python314.withPackages environment below and each other.
  # Priority: python314.withPackages (5, default) > python312 (10)
  # Version-specific binaries (python3.12, python3.14) are always available.
  (python312.overrideAttrs (old: {
    meta = old.meta // {
      priority = 10;
    };
  })) # Python 3.12: General development and testing

  # uv: For running EOL Python versions (3.9) not in nixpkgs
  # Usage: uv run --python 3.9 pytest tests/
  uv

  # ==========================================================================
  # Python Environment
  # ==========================================================================
  # Create a unified Python environment with all required packages.
  # This ensures all modules can be imported in the same interpreter.
  # Using python314.withPackages (overlay provides grip package).
  (python314.withPackages (ps: [
    ps.cryptography # Cryptographic recipes and primitives
    ps.grip # Preview GitHub Markdown files locally
    ps.pipx # Install and run Python CLI apps in isolated environments
    ps.pygithub # GitHub API v3 Python library
    # Claude document-skills dependencies
    ps.pandas # xlsx: data manipulation
    ps.openpyxl # xlsx: formulas and formatting
    ps.pillow # pptx: thumbnail grids
    ps.markitdown # pptx: text extraction
  ]))
]
