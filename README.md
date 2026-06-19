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

## Monitoring

The `modules/monitoring/` module deploys a Kubernetes-based observability stack for
AI development workflows. It includes OpenTelemetry Collector for traces and log ingestion,
and Cribl Edge for log shipping. See [`modules/monitoring/README.md`](modules/monitoring/README.md)
for architecture details, components, and quick start instructions.

## License

MIT

---

> Part of a [larger ecosystem of ~40 repos](https://docs.jacobpevans.com) — see how it all fits together.
