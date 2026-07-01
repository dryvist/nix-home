{
  # Nix Validate runs via the reusable _nix-validate.yml workflow.
  # As of #135 this repo opts into the RunsOn self-hosted runner via the
  # runner_label input — see .github/workflows/ci-gate.yml.
  description = "Cross-platform home-manager modules (Nix flake)";

  inputs = {
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
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      orbstack-kubernetes,
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
          ./modules/home-manager/tmux.nix
          ./modules/monitoring
          ./modules/home-manager/darwin
          ./modules/home-manager/git/gpg-agent.nix
        ];
        _module.args.orbstackKubernetesSrc = orbstack-kubernetes;
      };

      # Python packages overlay
      overlays.default = nixpkgs.lib.composeManyExtensions [
        (import ./overlays/python-packages.nix { inherit nixpkgs-unstable; })
        (import ./overlays/merge-json-settings.nix)
        (import ./overlays/install-document-skills-npm-deps.nix)
        (import ./overlays/darwin-test-skips.nix)
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
              nixfmt-rfc-style
              statix
              deadnix
              treefmt
            ];
          };
        }
      );

      # Expose custom packages for nix-update automation
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          git-flow-next = pkgs.callPackage ./modules/common/git-flow-next.nix { };
          grip = pkgs.python314.pkgs.callPackage ./packages/grip.nix { };
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
