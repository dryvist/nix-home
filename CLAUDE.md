# nix-home - AI Agent Instructions

Cross-platform home-manager modules for development environment tools.

## Critical Constraints

1. **Flakes-only**: Never use `nix-env` or imperative Nix commands
2. **Cross-platform**: Modules must work on Darwin and Linux (4 systems)
3. **Worktrees required**: work in a worktree before any changes
4. **No direct main commits**: Always use feature branches

## Build Validation

```bash
nix flake check    # Runs formatting, statix, deadnix, shellcheck checks
nix fmt            # Fix formatting
```

## Separation Guidelines

### What belongs here (nix-home)

- User shell config (zsh, git, direnv)
- Editor settings (VS Code, Vim config)
- CLI dev tools (bat, ripgrep, jq, fzf, etc.)
- Linters and formatters (shellcheck, statix, deadnix)
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
[ai-assistant-instructions/agentsmd/rules/nix-package-placement.md](https://github.com/JacobPEvans/ai-assistant-instructions/blob/main/agentsmd/rules/nix-package-placement.md)
and auto-loads via path-scoping when `.nix` / `flake.*` files are in context.
Contains the full decision matrix for the nix repos including homebrew constraints
and on-demand patterns.

## Architecture

This repo exports home-manager modules consumed by nix-darwin:

- `homeManagerModules.default` -- Full cross-platform module (git, zsh, VS Code, tmux, monitoring)
- `overlays.default` -- Python package overrides
- `checks` -- Quality checks on 4 systems
- `devShells.default` -- Nix development tools

Per-repo devShells replace the old centralized `shells/` directory. Each repo owns its own `flake.nix`:

```bash
# Scaffold a new repo's dev environment from a nix-devenv template
nix flake init -t github:JacobPEvans/nix-devenv#mkshell

# Or use a pre-built shell directly
nix develop github:JacobPEvans/nix-devenv?dir=shells/ansible

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
sudo darwin-rebuild switch --flake . --override-input nix-home /Users/you/git/nix-home/main
```

## Related Repos

| Repo | Purpose |
|------|---------|
| [nix-ai](https://github.com/JacobPEvans/nix-ai) | AI coding tools (Claude, Gemini, Copilot) |
| **nix-home** (this repo) | Dev environment |
| [nix-devenv](https://github.com/JacobPEvans/nix-devenv) | Reusable dev shells (OpenTofu, Ansible, K8s, AI/ML) |
| [nix-darwin](https://github.com/JacobPEvans/nix-darwin) | macOS system config (consumes nix-ai + nix-home) |
