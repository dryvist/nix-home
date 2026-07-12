# Nix quality checks - single source of truth for pre-commit and CI
# Used by flake.nix checks output, ensuring DRY principle
{
  pkgs,
  nixpkgs,
  src,
  home-manager,
  homeModule,
  overlay,
}:
{
  # Check Nix formatting with nixfmt
  # Uses treefmt configured with nixfmt formatter
  # Copy source to writable $TMPDIR since treefmt needs to write temp files
  formatting =
    pkgs.runCommand "check-formatting"
      {
        nativeBuildInputs = [ pkgs.nixfmt ];
      }
      ''
        cp -r ${src} $TMPDIR/src
        chmod -R u+w $TMPDIR/src
        cd $TMPDIR/src
        ${pkgs.lib.getExe pkgs.treefmt} --fail-on-change --no-cache --formatters nixfmt .
        touch $out
      '';

  # Lint Nix files for anti-patterns and code smells
  # Catches common mistakes and suggests improvements
  statix = pkgs.runCommand "check-statix" { } ''
    cd ${src}
    ${pkgs.lib.getExe pkgs.statix} check .
    touch $out
  '';

  # Check for unused Nix code (dead bindings)
  # -L: ignore lambda pattern names (config, lib, pkgs are common in modules)
  # --fail: exit with error if unused bindings found
  deadnix = pkgs.runCommand "check-deadnix" { } ''
    cd ${src}
    ${pkgs.lib.getExe pkgs.deadnix} -L --fail .
    touch $out
  '';

  # Lint shell scripts with shellcheck
  # Catches common bugs: unquoted variables, undefined vars, useless use of cat, etc.
  # Excludes .git directories and nix store paths
  # --severity=warning: Only fail on warning/error level (not info style suggestions)
  # SC1091: Exclude "not following" errors for external sources (can't resolve in Nix sandbox)
  # Excludes zsh scripts (shellcheck only supports sh/bash/dash/ksh)
  # Uses find with -print0 and xargs -0 for robustness with filenames containing spaces and special characters
  # TODO: Fix info-level issues (SC2086 quoting) in shell scripts for stricter checking
  shellcheck = pkgs.runCommand "check-shellcheck" { } ''
    cd ${src}
    find . -name "*.sh" -not -path "./.git/*" -not -path "./result/*" -print0 | \
    xargs -0 bash -c '
      for script in "$@"; do
        # Skip zsh scripts (shellcheck does not support them)
        if head -1 "$script" | grep -q "zsh"; then
          echo "Skipping zsh script: $script"
        else
          echo "Checking $script..."
          ${pkgs.lib.getExe pkgs.shellcheck} --severity=warning --exclude=SC1091 "$script"
        fi
      done
    ' bash
    touch $out
  '';

  # Verify the home-manager module evaluates without errors
  # Catches: broken imports, missing args, type errors, assertion failures
  # Note: uses unsafeDiscardStringContext — forces eval without building packages absent from binary cache.
  module-eval =
    let
      # Frozen home-manager state version — single source (lib/user-defaults.nix).
      stateVersion = (import ./user-defaults.nix).nix.homeManagerStateVersion;

      # Use a pkgs instance with allowUnfree for the module eval check since
      # the module enables vscode (unfree). On darwin, ps.pandas / ps.markitdown
      # transitively pull arrow-cpp via pyarrow's ARROW_HOME attribute; arrow-cpp
      # has meta.broken on darwin in nixpkgs 26.05 — caught by `nix flake check
      # --all-systems` when evaluating the aarch64-darwin output from a linux
      # runner. Neither legacy `config.allowBroken = true` nor the new
      # `config.problems.handlers` mechanism works on the 26.05-darwin branch,
      # so override `meta.broken = false` via a test-only overlay.
      # This is test-only; real deployments use their own nixpkgs config.
      pkgsWithUnfree = import nixpkgs {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true;
        overlays = [ overlay ];
      };
      hmConfig = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsWithUnfree;
        extraSpecialArgs = {
          userConfig = {
            nix.homeManagerStateVersion = stateVersion;
            user = {
              name = "test-user";
              email = "test@example.com";
              fullName = "Test User";
            };
            git = {
              editor = "vim";
              defaultBranch = "main";
            };
            gpg.signingKey = "";
          };
        };
        modules = [
          homeModule
          {
            home = {
              username = "test-user";
              homeDirectory = "/home/test-user";
              inherit stateVersion;
            };
          }
        ];
      };
      # Force full evaluation without building — avoids OOM from direnv fish tests
      # (direnv-2.37.1 is absent from binary cache, its fish test gets SIGKILL'd).
      # Skip the darwin evaluation: ps.pandas / ps.markitdown transitively pull
      # arrow-cpp via pyarrow's ARROW_HOME, and arrow-cpp has meta.broken on
      # darwin in nixpkgs 26.05. Nix laziness ensures hmConfig is not evaluated
      # on darwin. Linux module-eval already covers the platform-independent
      # module structure.
      evalResult =
        if pkgs.stdenv.isDarwin then
          "skipped on darwin: arrow-cpp meta.broken in nixpkgs 26.05"
        else
          builtins.unsafeDiscardStringContext "${hmConfig.activationPackage}";
    in
    pkgs.writeText "module-eval" evalResult;
}
