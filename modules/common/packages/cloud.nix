# Cloud CLIs — installed on every host.
#
# AWS credential/session tooling. `awscli2` doubles as the S3-compatible client
# for object storage (e.g. rustfs), so no dedicated object-storage CLI is
# shipped here (minio-client was dropped with the migration off MinIO).

{ pkgs, homelabContracts }:

let
  # Single-writer lease + gated credential injection for shared desired-state
  # objects (deployment.json). Guests get these vendored inside the
  # inventory_resolve Ansible role; a workstation has no equivalent path, so
  # without this they are absent from PATH and read as missing tooling.
  inherit (homelabContracts.packages.${pkgs.stdenv.hostPlatform.system}) flow-lock;
in
(with pkgs; [
  aws-vault # AWS credential management — session credentials backed by the OS keychain/credential store (used by av/avl/avd/ava/avr aliases)
  awscli2 # AWS CLI v2 — provides the `aws` command (also the S3 client for rustfs)
])
++ [
  flow-lock # flow-lock + deployment-json: leased writes to shared desired-state objects
]
