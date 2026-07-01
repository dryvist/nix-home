# Cloud CLIs — installed on every host.
#
# AWS credential/session tooling. `awscli2` doubles as the S3-compatible client
# for object storage (e.g. rustfs), so no dedicated object-storage CLI is
# shipped here (minio-client was dropped with the migration off MinIO).

{ pkgs }:

with pkgs;
[
  aws-vault # AWS credential management — session credentials backed by the OS keychain/credential store (used by av/avl/avd/ava/avr aliases)
  awscli2 # AWS CLI v2 — provides the `aws` command (also the S3 client for rustfs)
]
