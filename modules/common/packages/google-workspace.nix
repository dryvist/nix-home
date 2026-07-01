# Google Workspace CLIs.
#
# Gated by `home-profile.features.googleWorkspace`. Personal Gmail/Drive
# tooling not needed on a headless server.

{ pkgs }:

with pkgs;
[
  gmailctl # Declarative Gmail filter management via Jsonnet (apply/diff/test)
  rclone # Cloud storage sync — Google Drive, S3, and 70+ backends
  gdrive3 # Google Drive CLI — upload, download, list, share, sync
]
