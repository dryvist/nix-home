{
  # Nix Validate runs via the reusable _nix-validate.yml workflow.
  # As of #135 this repo opts into the RunsOn self-hosted runner via the
  # runner_label input — see .github/workflows/ci-gate.yml.
  description = "Cross-platform home-manager modules (Nix flake)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
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
      homeManagerModules.default = {
        imports = [
          ./modules/home-manager/common.nix
          ./modules/home-manager/tmux.nix
          ./modules/monitoring
          ./modules/home-manager/darwin
        ];
      };

      # Python packages overlay
      overlays.default = nixpkgs.lib.composeManyExtensions [
        (import ./overlays/python-packages.nix { inherit nixpkgs-unstable; })
        (import ./overlays/merge-json-settings.nix)
      ];

      # Quality checks (formatting, linting, dead code)
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./lib/checks.nix {
          inherit pkgs nixpkgs home-manager;
          src = ./.;
          homeModule = self.homeManagerModules.default;
          overlay = self.overlays.default;
        }
      );

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
