#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_DIR="/Users/kennethnygren/Cursor/Template/apple-app-meta-template"

if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo "Template directory not found: $TEMPLATE_DIR" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Syncing template into: $ROOT_DIR"
echo "From: $TEMPLATE_DIR"

# Copy template operational folders (docs/scripts/release/legal/support_site/modules) into repo root.
# This keeps app source separate while still benefiting from the template's operational infra.
#
# Notes:
# - Uses rsync if available for cleaner merges; falls back to cp.
# - Does not delete files from your repo.
if command -v rsync >/dev/null 2>&1; then
  rsync -av --no-perms --no-owner --no-group \
    --exclude ".DS_Store" \
    "$TEMPLATE_DIR/" \
    "$ROOT_DIR/_template_upstream/"
else
  mkdir -p "$ROOT_DIR/_template_upstream"
  cp -R "$TEMPLATE_DIR/." "$ROOT_DIR/_template_upstream/"
fi

echo
echo "Done."
echo "Upstream template content copied to: $ROOT_DIR/_template_upstream"
echo "Next: replace placeholders in _template_upstream (search for '{{')."
