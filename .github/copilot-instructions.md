# GitHub Copilot Instructions — nix-home

Cross-platform home-manager modules for developer shell configuration and CLI
tools. Keep modules flakes-only and compatible with Darwin and Linux.

## Boundaries

- User shell, editor, CLI, language, and security tooling belongs here.
- System-level macOS configuration belongs in `nix-darwin`.
- AI tools belong in `nix-ai`.
- Reusable project development shells belong in `nix-devenv`.

## Validation

Run `nix flake check` for every change and use `nix fmt` for Nix formatting.
Never use `nix-env` or commit directly to a default branch.

Infrastructure plans and applies run in homelab-hosted Terrakube workspaces.
OpenBao supplies their short-lived credentials through the native Terrakube
integration; local home-manager configuration must not embed workspace secrets.
