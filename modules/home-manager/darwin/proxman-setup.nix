{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.proxmanSetup;
in
{
  options.programs.proxmanSetup = {
    enable = lib.mkEnableOption "assisted ProxMan cluster connection setup";
    profile = lib.mkOption {
      type = lib.types.str;
      default = "config:proxman/main";
      description = "OpenBao KV v2 mount:path containing the managed non-secret connection profile.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "programs.proxmanSetup requires macOS.";
      }
    ];
    home.packages = [
      (pkgs.writeShellApplication {
        name = "proxman-setup";
        runtimeInputs = [ pkgs.jq ];
        text = ''
          export PROXMAN_PROFILE_SPEC=${lib.escapeShellArg cfg.profile}
          ${builtins.readFile ./scripts/proxman-setup.sh}
        '';
      })
    ];
  };
}
