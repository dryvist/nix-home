#!/usr/bin/env bash
# Fetch at runtime; ProxMan remains the writer of its own connection stores.
set -euo pipefail
set +x

die() { printf 'proxman-setup: %s\n' "$1" >&2; exit 1; }
copy_password=false
case "${1:-}" in
  "") ;;
  --copy-password) copy_password=true; shift ;;
  --help)
    printf 'Usage: proxman-setup [--copy-password]\nRequires openbao-run and runtime PROXMAN_VAULT_ROLE_ID/PROXMAN_VAULT_SECRET_ID.\n'
    exit 0 ;;
  *) die 'Expected --copy-password or --help.' ;;
esac
[ "$#" -eq 0 ] || die 'Unexpected argument.'
command -v openbao-run >/dev/null || die 'Install the existing openbao-run helper first.'

profile=$(openbao-run --domain proxman --secrets "${PROXMAN_PROFILE_SPEC:-config:proxman/main}" -- \
  jq -n 'env | {url, type, auth_method, credential_mount, credential_path}')
printf '%s' "$profile" | jq -e '
  .type == "pve" and .auth_method == "traditional" and
  (.url | type == "string" and test("^https://[A-Za-z0-9.-]+(:[0-9]+)?/?$")) and
  (.credential_mount | type == "string" and test("^[A-Za-z0-9_-]+$")) and
  (.credential_path | type == "string" and test("^[A-Za-z0-9_-]+(/[A-Za-z0-9_-]+)*$"))
' >/dev/null || die 'Missing or invalid connection profile.'
url=$(printf '%s' "$profile" | jq -r '.url | rtrimstr("/")')
mount=$(printf '%s' "$profile" | jq -r '.credential_mount')
path=$(printf '%s' "$profile" | jq -r '.credential_path')

status=$(/usr/bin/curl --silent --show-error --max-time 15 --output /dev/null \
  --write-out '%{http_code}' "$url/api2/json/version") || die 'Endpoint connection or TLS verification failed.'
case "$status" in 200|401) ;; *) die 'Endpoint did not respond as a Proxmox API.' ;; esac
username=$(openbao-run --domain proxman --secret "$mount:PROXMAN_USERNAME=$path#username" -- printenv PROXMAN_USERNAME)
[[ "$username" =~ ^[A-Za-z0-9._-]+@[A-Za-z0-9._-]+$ ]] || die 'Invalid Proxmox username.'
printf 'Configure one cluster connection in ProxMan:\nURL: %s\nServer type: pve\nAuthentication: traditional (username/password)\nUsername: %s\n' "$url" "$username"
if "$copy_password"; then
  # The child expands the injected password, keeping it out of argv.
  # shellcheck disable=SC2016
  openbao-run --domain proxman --secret "$mount:PROXMAN_PASSWORD=$path#password" -- \
    /bin/bash -c 'set +x; [ -n "$PROXMAN_PASSWORD" ] || exit 1; printf "%s" "$PROXMAN_PASSWORD" | /usr/bin/pbcopy'
  printf 'Password copied to the clipboard. Paste it into ProxMan, then clear the clipboard.\n'
else
  printf 'Run with --copy-password to copy the password for entry.\n'
fi
/usr/bin/open -a ProxMan
