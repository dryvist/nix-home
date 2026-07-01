# Cloud & object-storage CLIs — installed on every host.
#
# AWS credential/session tooling and S3-compatible object storage clients.

{ pkgs }:

with pkgs;
[
  aws-vault # AWS credential management — session credentials backed by the OS keychain/credential store (used by av/avl/avd/ava/avr aliases)
  awscli2 # AWS CLI v2 — provides the `aws` command
  minio-client # MinIO/S3 client (mc) — upload, download, manage objects + bucket policies
]
