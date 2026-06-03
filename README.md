# nix-home

## Your dev environment, declared once. Works everywhere

Dotfiles, but better. Instead of fragile symlinks and install scripts,
**nix-home** declares your development environment as code using [Nix](https://nixos.org/).
Switch machines? One command. Everything's back.

---

## What it manages

| Tool | What you get |
|------|-------------|
| **Git** | Aliases, GPG signing, hooks, merge drivers |
| **Zsh** | Oh-my-zsh, aliases, autosuggestions, syntax highlighting, custom functions |
| **VS Code** | Writable settings merge, extensions, keybindings |
| **Tmux** | Session management configuration |
| **Direnv** | Automatic per-project environments |
| **Monitoring** | Kubernetes manifests, OpenTelemetry, Cribl Edge |
| **Linters** | markdownlint, pre-commit configurations |
| **npm / AWS** | Configuration file management |

## Installation

Prerequisites:

- [Nix](https://nixos.org/) (Determinate Nix installer recommended)
- [home-manager](https://github.com/nix-community/home-manager)
- Compatible platforms: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, `aarch64-linux`

Add to your Nix flake:

```nix
{
  inputs.nix-home = {
    url = "github:JacobPEvans/nix-home";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };
}
```

Then in your home-manager config:

```nix
sharedModules = [ nix-home.homeManagerModules.default ];
```

## Usage

### Flake outputs

| Output | Description |
|--------|-------------|
| `homeManagerModules.default` | Full cross-platform module |
| `overlays.default` | Python package overrides |
| `checks` | Formatting, linting, dead code, module eval (4 systems) |
| `devShells.default` | Nix development tools |
| `formatter` | nixfmt-tree |

## Dev shells

Per-repo dev shells have moved to [nix-devenv](https://github.com/JacobPEvans/nix-devenv).
Scaffold a new repo or use a pre-built shell from there:

```sh
# Scaffold a new repo's dev environment from a nix-devenv template
nix flake init -t github:JacobPEvans/nix-devenv#mkshell

# Or use a pre-built shell directly
nix develop github:JacobPEvans/nix-devenv?dir=shells/ansible

# Or use community templates for standard languages
nix flake init -t github:the-nix-way/dev-templates#go
```

### Monitoring

The `modules/monitoring/` module deploys a Kubernetes-based observability stack for
AI development workflows. It includes OpenTelemetry Collector for traces and log ingestion,
and Cribl Edge for log shipping. See [`modules/monitoring/README.md`](modules/monitoring/README.md)
for architecture details, components, and quick start instructions.

## Related Repos

**nix-home** manages your user-level development environment using home-manager modules.
It provides shell config, editor settings, CLI dev tools, linters, and dotfiles.
Consumed as a flake input by nix-darwin (macOS) and usable standalone on Linux.

| Repo | Scope | Installs via |
|------|-------|-------------|
| **nix-home** (you are here) | User environment (dotfiles, dev tools, LaunchAgents) | home-manager |
| [nix-ai](https://github.com/JacobPEvans/nix-ai) | AI CLI ecosystem (Claude, Gemini, Copilot, MCP) | home-manager |
| [nix-devenv](https://github.com/JacobPEvans/nix-devenv) | Reusable dev shells (OpenTofu, Ansible, K8s, AI/ML) | nix develop / flake init |
| [nix-darwin](https://github.com/JacobPEvans/nix-darwin) | macOS system config (Dock, Finder, Homebrew, security) | nix-darwin |

## License

MIT
