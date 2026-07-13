# AWS CLI Configuration
#
# Manages ~/.aws/config via shell init (not home.activation).
# Profile structure defined here in Nix (single source of truth).
# Account ID injected from macOS Keychain at shell startup via ensure-config.zsh.
# Credentials: use aws-vault (backed by macOS Keychain), never ~/.aws/credentials.

{
  pkgs,
  userConfig ? { },
  ...
}:

let
  defaultRegion = "us-east-2";
  defaultOutput = "json";

  # Placeholder replaced at shell init by keychain lookup
  accountIdPlaceholder = "__AWS_ACCOUNT_ID__";

  # Base identities — heterogeneous, not role-assuming.
  baseProfiles = [
    {
      name = "default";
      comment = "Default profile - used when no --profile is specified";
    }
    {
      name = "dev";
      comment = "Development environment";
    }
    {
      name = "test";
      comment = "Test environment";
    }
    {
      name = "terraform";
      comment = "Terraform base identity - only sts:AssumeRole, no resource permissions";
    }
    {
      name = "cribl";
      comment = "Cribl environment";
    }
    {
      name = "splunk";
      comment = "Splunk environment";
    }
    {
      name = "iam-user";
      comment = "IAM admin - bootstrap only, not for daily use";
    }
    {
      name = "tofu";
      comment = "tofu base identity - new projects; assumes tf-* roles, no resource permissions";
    }
    {
      name = "tofu-admin";
      comment = "tofu-admin - standalone one-time state-bucket bootstrap user (own creds)";
    }
  ];

  # Per-project profiles, generated from ./tf-projects.nix and grouped by the
  # base identity each assumes from (no MFA). New projects live under `tofu`;
  # legacy projects stay under `terraform` until migrated.
  tfProjects = import ./tf-projects.nix;

  # Projects migrated off the static aws-vault base key onto OpenBao's AWS
  # secrets engine (dynamic STS, assumed_role). A project listed here gets a
  # `credential_process` profile instead of source_profile/role_arn — the
  # wrapper (nix-darwin `openbao-aws-creds`, on PATH system-wide) reads the
  # terraform-apply AppRole secret-zero from the ambient environment (injected
  # by running terragrunt under `doppler run`) and mints short-lived creds on
  # demand, so no static AWS key exists on the machine. Move a project here
  # once its aws/roles/<name> exists in OpenBao.
  openbaoStsProjects = {
    proxmox = "openbao-aws-creds tf-proxmox";
  };

  mkTfProfiles =
    base: names:
    map (
      name:
      if openbaoStsProjects ? ${name} then
        {
          name = "tf-${name}";
          comment = "tf-${name}: dynamic STS creds from OpenBao (credential_process, no static key)";
          credential_process = openbaoStsProjects.${name};
        }
      else
        {
          name = "tf-${name}";
          comment = "tf-${name}: assumes role/tf-${name} via the ${base} base identity";
          source_profile = base;
          role_arn = "arn:aws:iam::${accountIdPlaceholder}:role/tf-${name}";
        }
    ) names;
  tfProfiles =
    (mkTfProfiles "terraform" tfProjects.terraform) ++ (mkTfProfiles "tofu" tfProjects.tofu);

  profiles = baseProfiles ++ tfProfiles;

  generateProfile =
    profile:
    let
      # AWS CLI format: default profile has no "profile " prefix
      base = ''
        # ${profile.comment}
        [${if profile.name == "default" then "default" else "profile ${profile.name}"}]
        region = ${defaultRegion}
        output = ${defaultOutput}
      '';
      role = ''
        source_profile = ${profile.source_profile}
        role_arn = ${profile.role_arn}
      '';
      credProcess = ''
        credential_process = ${profile.credential_process}
      '';
    in
    if profile ? credential_process then
      base + credProcess
    else if profile ? role_arn && profile ? source_profile then
      base + role
    else
      base;

  configContent = builtins.concatStringsSep "\n\n" (map generateProfile profiles);
  configContentFile = pkgs.writeText "aws-config-template" configContent;
  kcAccount = (userConfig.keychain or { }).aiAccount or "";
  kcDb = (userConfig.keychain or { }).aiDb or "";

  ensureScript = pkgs.replaceVars ./ensure-config.zsh {
    templatePath = configContentFile;
    inherit kcAccount kcDb;
    placeholder = accountIdPlaceholder;
    sed = "${pkgs.gnused}/bin/sed";
  };
in
{
  initScript = ensureScript;
  files =
    if pkgs.stdenv.isDarwin then
      { }
    else
      {
        ".aws/config".text = configContent;
      };
}
