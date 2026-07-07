#!/usr/bin/env bash
# sync-docs.sh — populate this site from the SOURCE OF TRUTH in kagenti/kagenti:
#   1. docs-temp/       -> the site's docs-temp/ (rendered as the Docs section)
#   2. CONTRIBUTING.md  -> the site's contributing/index.md (Contributing page)
#
# Both destinations are git-ignored here and regenerated on every build (CI runs
# this before `npm run build`; see .github/workflows/deploy.yaml). The canonical
# content lives in kagenti/kagenti — edit it there, not here.
#
# Usage:
#   ./scripts/sync-docs.sh [git-ref]                       # clone from GitHub (default: main)
#   SRC_REPO=/path/to/local/kagenti ./scripts/sync-docs.sh # use an existing local clone

set -euo pipefail

REF="${1:-main}"
REPO_URL="https://github.com/kagenti/kagenti.git" # source of truth
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE_DIR="$(dirname "$SCRIPT_DIR")"
SUBDIR="docs-temp"
DEST="$SITE_DIR/$SUBDIR"

# --- Obtain the source -------------------------------------------------------
if [[ -n "${SRC_REPO:-}" ]]; then
  SRC="$SRC_REPO"
  echo "==> Syncing from local clone: $SRC"
else
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  # Sparse, blobless checkout. Cone mode also includes root files (CONTRIBUTING.md).
  git clone --depth 1 --branch "$REF" --filter=blob:none --sparse "$REPO_URL" "$TMP"
  git -C "$TMP" sparse-checkout set "$SUBDIR"
  SRC="$TMP"
  echo "==> Syncing from kagenti/kagenti@$REF"
fi

# --- 1. Docs: mirror docs-temp/ ---------------------------------------------
UP="$SRC/$SUBDIR"
if [[ ! -d "$UP" ]]; then
  echo "!! source folder not found: $UP" >&2
  exit 1
fi
mkdir -p "$DEST"
rsync -a --delete --exclude '.DS_Store' "$UP"/ "$DEST"/

# Rewrite links to README.md -> index.md (Docusaurus folder-index convention).
find "$DEST" -name '*.md' -type f -print0 | while IFS= read -r -d '' f; do
  sed -i.bak -E 's#\]\(([^)]*)README\.md#](\1index.md#g' "$f" && rm -f "$f.bak"
done
echo "==> docs-temp/ mirrors kagenti/kagenti:$SUBDIR ($(find "$DEST" -type f | wc -l | tr -d ' ') files)."

# --- 2. Contributing: generate contributing/index.md from CONTRIBUTING.md ----
# Transforms applied to the upstream body:
#   - rebrand "Kagenti" -> "rossoctl" (prose only; URLs use lowercase "kagenti")
#   - rewrite repo-relative links (./path, LICENSE) to absolute GitHub URLs
#   - normalise the top H1 to "Contributing"
CONTRIB_SRC="$SRC/CONTRIBUTING.md"
CONTRIB_DEST_DIR="$SITE_DIR/contributing"
CONTRIB_DEST="$CONTRIB_DEST_DIR/index.md"
GH_BASE="https://github.com/kagenti/kagenti"
if [[ -f "$CONTRIB_SRC" ]]; then
  mkdir -p "$CONTRIB_DEST_DIR"
  {
    printf -- '---\n'
    printf -- 'id: index\n'
    printf -- 'sidebar_label: Contributing\n'
    printf -- 'slug: /\n'
    printf -- 'description: How to contribute to rossoctl.\n'
    printf -- '---\n\n'
    sed -E \
      -e 's/Kagenti/rossoctl/g' \
      -e "s#\]\(\./#](${GH_BASE}/tree/main/#g" \
      -e "s#\]\(LICENSE\)#](${GH_BASE}/blob/main/LICENSE)#g" \
      -e 's/^# Contributing to this project.*/# Contributing/' \
      "$CONTRIB_SRC"
  } > "$CONTRIB_DEST"
  echo "==> contributing/index.md generated from kagenti/kagenti:CONTRIBUTING.md."
else
  echo "!! CONTRIBUTING.md not found at $CONTRIB_SRC (skipped Contributing page)." >&2
fi
