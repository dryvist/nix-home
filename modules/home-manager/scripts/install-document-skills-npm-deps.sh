#!/usr/bin/env bash
# Install pinned npm libs required by Claude's /document-skills:{docx,pptx}.
#
# Fast-path: only call npm when an installed version does not match the exact
# pin from the environment. This keeps normal home-manager activations offline
# and fast; the network hit only happens when the pin in document-skills.nix
# changes.
#
# Required environment (exported by the caller):
#   DOCX_VERSION       - exact docx version to install
#   PPTXGENJS_VERSION  - exact pptxgenjs version to install
#   NPM_GLOBAL_PREFIX  - npm global prefix directory
#
# npm must be on PATH (provided by writeShellApplication runtimeInputs).

set -euo pipefail

: "${DOCX_VERSION:?DOCX_VERSION must be set}"
: "${PPTXGENJS_VERSION:?PPTXGENJS_VERSION must be set}"
: "${NPM_GLOBAL_PREFIX:?NPM_GLOBAL_PREFIX must be set}"

check_installed() {
  local pkg_name="$1"
  local want_version="$2"
  local pkg_json="${NPM_GLOBAL_PREFIX}/lib/node_modules/${pkg_name}/package.json"

  [[ -f "$pkg_json" ]] || return 1
  jq -e --arg v "$want_version" '.version == $v' "$pkg_json" >/dev/null
}

if check_installed docx "$DOCX_VERSION" \
  && check_installed pptxgenjs "$PPTXGENJS_VERSION"; then
  exit 0
fi

export npm_config_prefix="$NPM_GLOBAL_PREFIX"
npm install -g --silent \
  "docx@${DOCX_VERSION}" \
  "pptxgenjs@${PPTXGENJS_VERSION}"
