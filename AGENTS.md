# nix-home - AI Agent Instructions

Cross-platform home-manager modules for development environment tools.

## Critical Constraints

1. **Flakes-only**: Never use `nix-env` or imperative Nix commands.
2. **Cross-platform**: Modules must work on Darwin and Linux (4 systems).
3. **Worktrees required**: Run `/init-worktree` before any work.
4. **No direct main commits**: Always use feature branches.

## Build Validation

```bash
nix flake check    # Runs formatting, statix, deadnix checks
nix fmt            # Fix formatting
```

## Separation Guidelines

### What belongs here (nix-home)

- User shell config (zsh, git, direnv)
- Editor settings (VS Code, Vim config)
- CLI dev tools (bat, ripgrep, jq, fzf, etc.)
- Linters and formatters (statix, deadnix)
- Programming languages (Python, Bun)
- Security tools (password manager CLIs, aws-vault)
- macOS user-level LaunchAgents (under `modules/home-manager/darwin/`)
- Dotfiles and config files (`home.file`)
- Per-repo devShell scaffolding (via nix-devenv)

### What does NOT belong here

- macOS system settings (Dock, Finder, keyboard) -> nix-darwin
- Homebrew casks and brews -> nix-darwin
- System-level LaunchDaemons -> nix-darwin
- AI tools (Claude, Gemini, Copilot, MCP) -> nix-ai
- GUI apps managed at system level -> nix-darwin

### Package placement

See the `nix-package-placement` rule — lives in
[ai-assistant-instructions][nix-pkg-placement] and auto-loads via
path-scoping when `.nix` / `flake.*` files are in context. Contains the
full decision matrix for the nix repos including homebrew constraints
and on-demand patterns.

[nix-pkg-placement]: https://github.com/JacobPEvans/ai-assistant-instructions/blob/main/agentsmd/rules/nix-package-placement.md

## Architecture

This repo exports home-manager modules consumed by nix-darwin:

- `homeManagerModules.default` -- Full cross-platform module (git, zsh, VS Code, tmux, monitoring)
- `overlays.default` -- Python package overrides
- `checks` -- Quality checks on 4 systems
- `devShells.default` -- Nix development tools

Per-repo devShells replace the old centralized `shells/` directory. Each
repo owns its own `flake.nix`:

```bash
# Scaffold a new repo's dev environment from a nix-devenv template
nix flake init -t github:dryvist/nix-devenv#mkshell

# Or use a pre-built shell directly
nix develop github:dryvist/nix-devenv?dir=shells/ansible

# Or use community templates for standard languages
nix flake init -t github:the-nix-way/dev-templates#go
```

## Key Files

- `modules/home-manager/common.nix` -- Shared configuration (zsh, git, direnv, npm, AWS, linters)
- `modules/home-manager/tmux.nix` -- Tmux configuration
- `modules/monitoring/` -- Kubernetes monitoring stack
- `overlays/python-packages.nix` -- Custom Python package overlays
- `lib/checks.nix` -- Quality check definitions

## Testing Locally

From nix-darwin, test changes with:

```bash
sudo darwin-rebuild switch --flake . \
  --override-input nix-home ${GIT_HOME_PUBLIC}/nix-home/main
```

## Tooling baseline (inherited from dryvist/.github)

- **Markdown lint:** `markdownlint-cli2` with the canonical
  `.markdownlint-cli2.yaml` synced from
  [`dryvist/.github`](https://github.com/dryvist/.github).
  `MD013 line_length: 160`; no 80-char heading/code restrictions.
  `CHANGELOG.md` and `.github/aw/**` are ignored. `MD024`
  strict-by-default everywhere actually linted — never disabled across
  the board.
- **Pre-commit hooks**: see `.pre-commit-config.yaml`. Stack includes
  the canonical `pre-commit/pre-commit-hooks@v6.0.0`,
  `DavidAnson/markdownlint-cli2@v0.22+`, and
  `gitleaks/gitleaks@v8.30.1`.
- **Out of scope this PR**: adopting `nix-devenv` `flakeModules.dev-hygiene`
  to centralize treefmt/pre-commit/zizmor declaratively — requires
  migrating to `flake-parts`, larger architectural change.

Do NOT commit `.markdownlint-cli2.jsonc` again. Keep
`.markdownlint-cli2.yaml` aligned with the dryvist canonical baseline,
and do NOT re-introduce leniency rules to work around stale tooling.

## Related Repos

| Repo | Purpose |
| --- | --- |
| [nix-ai](https://github.com/dryvist/nix-ai) | AI coding tools (Claude, Gemini, Copilot) |
| **nix-home** (this repo) | Dev environment |
| [nix-devenv](https://github.com/dryvist/nix-devenv) | Reusable dev shells (Terraform, Ansible, K8s, AI/ML) |
| [nix-darwin](https://github.com/dryvist/nix-darwin) | macOS system config (consumes nix-ai + nix-home) |
