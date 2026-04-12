#!/usr/bin/env bash
# Check if release-please created a release on the current commit.
#
# Compares the latest non-draft release tag's resolved commit SHA against
# COMMIT_SHA. Only the latest release is checked because release-please
# always creates releases on the merge commit of its release PR.
#
# Required env: GH_TOKEN, GITHUB_REPOSITORY, COMMIT_SHA, GITHUB_OUTPUT
set -euo pipefail

TAG=$(gh api "repos/${GITHUB_REPOSITORY}/releases" --jq \
  "[.[] | select(.draft == false)] | first | .tag_name // empty")

if [[ -z "$TAG" ]]; then
  echo "No releases found"
  echo "released=false" >> "$GITHUB_OUTPUT"
  exit 0
fi

# Resolve the tag ref to a SHA. Lightweight tags point directly at the
# commit; annotated tags point at a tag object that must be dereferenced.
REF_OBJ=$(gh api "repos/${GITHUB_REPOSITORY}/git/ref/tags/${TAG}" --jq '.object')
REF_TYPE=$(echo "$REF_OBJ" | jq -r '.type')
REF_SHA=$(echo "$REF_OBJ" | jq -r '.sha')

if [[ "$REF_TYPE" == "tag" ]]; then
  # Annotated tag — dereference to the underlying commit
  TAG_SHA=$(gh api "repos/${GITHUB_REPOSITORY}/git/tags/${REF_SHA}" --jq '.object.sha')
else
  # Lightweight tag — ref points directly at the commit
  TAG_SHA="$REF_SHA"
fi

if [[ "$TAG_SHA" == "$COMMIT_SHA" ]]; then
  echo "Release ${TAG} matches current commit"
  echo "released=true" >> "$GITHUB_OUTPUT"
  echo "tag=${TAG}" >> "$GITHUB_OUTPUT"
else
  echo "Latest release ${TAG} (${TAG_SHA}) does not match current commit (${COMMIT_SHA})"
  echo "released=false" >> "$GITHUB_OUTPUT"
fi
