# Per-project roles, grouped by the base identity each assumes from (no MFA).
# `tf-<name>` -> assumes `role/tf-<name>`. Add new projects under `tofu`; legacy
# projects stay under `terraform` until migrated. One-line edit per project.
{
  terraform = [
    "splunk-aws"
    "proxmox"
    "bedrock"
    "static-website"
    "runs-on"
  ];
  tofu = [
    "unifi"
  ];
}
