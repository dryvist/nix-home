# Per-project Terraform roles. Each name here generates an aws-vault profile
# `tf-<name>` that assumes `role/tf-<name>` from the shared `terraform` base
# identity (no MFA). Adding a project is a one-line edit: append its name.
[
  "splunk-aws"
  "proxmox"
  "bedrock"
  "static-website"
  "runs-on"
  "unifi"
]
