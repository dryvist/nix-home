{
  # Nix Validate runs via the reusable _nix-validate.yml workflow.
  # As of #135 this repo opts into the RunsOn self-hosted runner via the
  # runner_label input — see .github/workflows/ci-gate.yml.
  description = "Cross-platform home-manager modules (Nix flake)";

  inputs = {
    # Channel branch = intended major-version pin (26.05, stable). Renovate
    # CANNOT bump this: it updates an input when its ref changes, and a
    # channel branch's ref never changes. deps-flake-lock.yml relocks the whole
    # file on a schedule instead, so nixpkgs-unstable — which feeds
    # overlays/python-packages.nix — moves with it (deps-update-flake.yml only
    # updates packaged programs, never flake.lock).
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Source-only input: orbstack-kubernetes manifests + deploy scripts that
    # modules/monitoring/monitoring-deploy executes. Pinned via flake.lock so
    # deploys are reproducible across this nix-home generation. Override
    # locally with `--override-input orbstack-kubernetes path:<checkout>` for
    # development.
    orbstack-kubernetes = {
      url = "github:dryvist/orbstack-kubernetes";
      flake = false;
    };

    # flow-lock / deployment-json: single-writer lease + gated credential
    # injection for shared desired-state objects. Guests receive these vendored
    # inside the inventory_resolve Ansible role; a workstation has no such path,
    # so without this they are absent from PATH.
    homelab-contracts = {
      url = "github:dryvist/homelab-contracts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Source-only, like orbstack-kubernetes above: this repo needs exactly one
    # file (modules/litellm-local/aliases.nix, the committed router capability
    # alias list) and nothing else nix-ai exports, so `flake = false` skips
    # locking nix-ai's own transitive inputs (nix-claude-code, nix-codex,
    # nix-agy, ...) into this repo's flake.lock.
    #
    # Pinned to the commit that merged dryvist/nix-ai#2151 (which adds this
    # file and its lib.litellmAliases output) into nix-ai's default branch.
    nix-ai = {
      url = "github:dryvist/nix-ai/d61512914d0a206f41a238d0769e4680677c5f15";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      orbstack-kubernetes,
      homelab-contracts,
      nix-ai,
      ...
    }:
    let
      # Systems to generate outputs for
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # Main home-manager module (cross-platform non-AI config)
      # Darwin modules imported unconditionally - they use mkEnableOption + mkIf,
      # so launchd config is only evaluated when explicitly enabled on macOS.
      #
      # `_module.args.orbstackKubernetesSrc` exposes the pinned source-only
      # flake input to modules that need it (modules/monitoring), so the
      # deploy commands resolve manifests from the Nix store rather than
      # requiring a local clone of orbstack-kubernetes.
      homeManagerModules.default = {
        imports = [
          ./modules/home-manager/profiles
          ./modules/home-manager/common.nix
          ./modules/home-manager/workspace.nix
          ./modules/home-manager/tmux.nix
          ./modules/monitoring
          ./modules/home-manager/darwin
          ./modules/home-manager/git/gpg-agent.nix
        ];
        _module.args = {
          orbstackKubernetesSrc = orbstack-kubernetes;
          homelabContracts = homelab-contracts;
          # The one committed router capability alias list nix-ai owns
          # (modules/litellm-local/aliases.nix) — see the `nix-ai` input
          # comment above for why this is a direct file import rather than a
          # full flake dependency.
          litellmAliases = import "${nix-ai}/modules/litellm-local/aliases.nix";
          # options.nix declares its options in isolation ({ config, lib, ... },
          # no other imports), so evalModules on that one file resolves its own
          # option defaults (loopback base URL, placeholder client token)
          # without pulling in the rest of nix-ai's home-manager module (which
          # `flake = false` above exists to avoid). Raycast's provider file
          # reads these instead of a hand-typed literal, so a port change in
          # nix-ai's module stays a single edit.
          litellmLocalDefaults =
            (nixpkgs.lib.evalModules {
              modules = [ "${nix-ai}/modules/litellm-local/options.nix" ];
            }).config.programs.litellmLocal;
        };
      };

      # Python packages overlay
      overlays.default = nixpkgs.lib.composeManyExtensions [
        (import ./overlays/python-packages.nix { inherit nixpkgs-unstable; })
        (import ./overlays/merge-json-settings.nix)
        (import ./overlays/install-document-skills-npm-deps.nix)
      ];

      # Quality checks (formatting, linting, dead code, module-eval).
      #
      # Scoped to x86_64-linux only so `nix flake check --all-systems` succeeds
      # from a single linux runner. All checks here are either source-only
      # (formatting, statix, deadnix, shellcheck — identical source across
      # systems) or wrap evaluation in a writeText (module-eval), so running
      # them once is sufficient and produces a derivation buildable on the
      # runner. Other systems intentionally have no `checks` entries.
      #
      # Cross-platform breakage (e.g. darwin-only `meta.broken` in nixpkgs) is
      # still caught by `--all-systems` evaluating `packages.<system>`,
      # `devShells.<system>`, `formatter.<system>`, and `overlays` for every
      # declared system — those outputs continue to be defined via
      # `forAllSystems` below.
      checks =
        let
          system = "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          ${system} = import ./lib/checks.nix {
            inherit pkgs nixpkgs home-manager;
            src = ./.;
            homeModule = self.homeManagerModules.default;
            overlay = self.overlays.default;
          };
        };

      # Development shells
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nixfmt
              statix
              deadnix
              treefmt
            ];
          };
        }
      );

      # Expose custom packages. nix-update manages git-flow-next and grip; BWS
      # is an intentionally pinned official binary archive (not nixpkgs source).
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # Official Bitwarden release binary: never replace with `pkgs.bws`.
          # Its nixpkgs Rust build/test graph made activation builds exceed the
          # hard 20-minute CI budget; see modules/common/packages/bws.nix.
          bws = pkgs.callPackage ./modules/common/packages/bws.nix { };
          git-flow-next = pkgs.callPackage ./modules/common/git-flow-next.nix { };
          grip = pkgs.python314.pkgs.callPackage ./packages/grip.nix { };
          gh-stack = pkgs.callPackage ./packages/gh-stack.nix { };
        }
      );

      # Formatter
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # Library exports
      lib = {
        security-policies = import ./lib/security-policies.nix;
      };
    };
}
