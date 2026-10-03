# AWS profile options a host can set. The rest of ~/.aws/config is generated
# by ./config.nix.
{ lib, ... }:

{
  options.programs.awsProfiles.credentialProcess = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    example = {
      tf-example = "my-sts-helper tf-example";
    };
    description = ''
      Profile name -> `credential_process` command. A tf-* project profile
      listed here uses the command instead of assuming its role through the
      base identity. Any other name adds a profile of its own.
    '';
  };
}
