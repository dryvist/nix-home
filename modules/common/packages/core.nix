# Core packages — installed on every host regardless of profile.
#
# Git tooling, JS runtimes, modern CLI replacements, universal linters, and the
# baseline Python tooling (interpreter helpers, not the heavy document env).

{ pkgs }:

with pkgs;
[
  # ==========================================================================
  # Git & Pre-commit Hooks
  # ==========================================================================
  # Framework for managing git pre-commit hooks - essential for code quality.
  #
  # The upstream derivation embeds dotnet-sdk's store path literally inside
  # `preCheck` (`export DOTNET_ROOT="<store path>"`), so dotnet stays an input
  # even with the test phases disabled -- and dotnet pulls the whole Swift
  # toolchain. On aarch64-darwin that closure is not in the binary cache, so
  # every rebuild compiles swift/LLVM from source (3308 targets) and any job
  # with a wall-clock cap is killed part way. Clearing `preCheck` is what
  # actually cuts the edge; disabling the phases alone does not.
  #
  # This skips UPSTREAM's own test suite for a third-party tool. It disables no
  # check that guards code in this estate.
  (pre-commit.overrideAttrs (_: {
    doCheck = false;
    doInstallCheck = false;
    nativeCheckInputs = [ ];
    preCheck = "";
    postCheck = "";
  }))

  # Lefthook: Some upstream repos (e.g., docs.jacobpevans.com via Mintlify
  # tooling) drop `lefthook`-generated hook stubs into `.git/hooks/`. Those
  # stubs print "Can't find lefthook in PATH" warnings during ordinary git
  # operations when the binary isn't installed. Keep it on PATH globally so
  # the stubs run as intended (lefthook is a no-op without a `lefthook.yml`,
  # matching pre-commit's behavior without `.pre-commit-config.yaml`).
  lefthook

  # Git Workflow
  (pkgs.callPackage ../git-flow-next.nix { }) # git-flow branching workflow — required for all non-personal repos
  git-bug # Distributed bug tracker embedded in git (git bug command)

  # ==========================================================================
  # JavaScript Runtimes
  # ==========================================================================
  # bun: fast all-in-one runtime (provides bunx) — general CLI/script use.
  # nodejs: general-purpose runtime; also required by Claude document-skills,
  # which generate scripts executed with `node` (the docx/pptxgenjs npm libs
  # are installed separately when the documentSkills feature is enabled).
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
  # Universal Linters
  # ==========================================================================
  # These are the most common linters used across projects. They support
  # pre-commit hooks and should be available on any development machine.

  # Shell
  shellcheck # Shell script static analysis (POSIX, bash)
  shfmt # Shell script formatter

  # Documentation
  lychee # Link checker — kept global: consumed by downstream repo pre-commit hooks (`language: system`)
  markdownlint-cli2 # Markdown linter (README, docs exist everywhere)

  # Nix (2025 official tooling)
  nixfmt # Official Nix formatter (RFC 166, v1.1.0+; formerly pkgs.nixfmt-rfc-style)
  statix # Nix linter - catches anti-patterns
  deadnix # Find unused code in .nix files
  treefmt # Multi-language formatter runner
  nix-tree # Browse Nix store dependencies interactively

  # JSON
  check-jsonschema # JSON Schema validator CLI (for settings validation)

  # ==========================================================================
  # Remote Shell
  # ==========================================================================
  # Resilient mobile shell using UDP - survives network handoffs.
  mosh

  # ==========================================================================
  # Python Tools
  # ==========================================================================
  # On-demand interpreter management. Type checking (pyright) and the heavy
  # document env (python314.withPackages) are grouped together in python-env.nix.

  # uv: For running alternate Python versions on-demand (EOL or pinned)
  # Usage: uv run --python 3.9 pytest tests/
  uv
]
