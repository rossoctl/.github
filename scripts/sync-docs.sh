#!/usr/bin/env bash
# sync-docs.sh — populate this site from the SOURCE OF TRUTH in rossoctl/rossoctl:
#   1. docs/       -> the site's docs/ (rendered as the Docs section)
#   2. CONTRIBUTING.md  -> the site's contributing/index.md (Contributing page)
#
# Both destinations are git-ignored here and regenerated on every build (CI runs
# this before `npm run build`; see .github/workflows/deploy.yaml). The canonical
# content lives in rossoctl/rossoctl — edit it there, not here.
#
# Usage:
#   ./scripts/sync-docs.sh [git-ref]                       # clone from GitHub (default: main)
#   SRC_REPO=/path/to/local/rossoctl ./scripts/sync-docs.sh # use an existing local clone

set -euo pipefail

REF="${1:-main}"
REPO_URL="https://github.com/rossoctl/rossoctl.git" # source of truth
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE_DIR="$(dirname "$SCRIPT_DIR")"
SUBDIR="docs"
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
  echo "==> Syncing from rossoctl/rossoctl@$REF"
fi

# --- 1. Docs: mirror docs/ ---------------------------------------------
# docs/ may not exist upstream yet: the Docs section is currently hidden in
# docusaurus.config (docs: false) and the source lands in a separate PR. Because
# docs are disabled in the build, a missing docs/ is NOT fatal — warn and
# skip so the deploy still succeeds. Once docs/ lands upstream and docs are
# re-enabled, this syncs normally with no change needed here.
UP="$SRC/$SUBDIR"
if [[ -d "$UP" ]]; then
  mkdir -p "$DEST"
  rsync -a --delete --exclude '.DS_Store' "$UP"/ "$DEST"/

  # The /docs/ root is a GENERATED INDEX (see sidebars.ts), not a markdown file.
  # By default Docusaurus maps docs/README.md to the /docs/ route, which would
  # collide with that generated index. Give README a slug so it ships as an
  # ordinary page (/docs/readme) and frees the root route. Prepend frontmatter
  # (upstream README has none). Skip if it somehow already has frontmatter.
  README="$DEST/README.md"
  if [[ -f "$README" ]] && ! head -1 "$README" | grep -q '^---$'; then
    printf -- '---\nslug: /readme\nsidebar_label: Overview\n---\n\n%s' "$(cat "$README")" > "$README.tmp"
    mv "$README.tmp" "$README"
  fi

  # Rewrite links to README.md -> index.md (Docusaurus folder-index convention).
  # (README is no longer the folder index, but existing ./README.md links across
  # the docs still resolve to the same page; keep this so cross-links don't break.)
  find "$DEST" -name '*.md' -type f -print0 | while IFS= read -r -d '' f; do
    sed -i.bak -E 's#\]\(([^)]*)README\.md#](\1index.md#g' "$f" && rm -f "$f.bak"
  done
  echo "==> docs/ mirrors rossoctl/rossoctl:$SUBDIR ($(find "$DEST" -type f | wc -l | tr -d ' ') files)."
else
  echo "==> docs/ not found upstream ($UP) — skipping docs sync (docs are hidden)." >&2
fi

# --- 2. Contributing: generate contributing/index.md from CONTRIBUTING.md ----
# Transforms applied to the upstream body:
#   - rewrite repo-relative links (./path, LICENSE) to absolute GitHub URLs
#   - normalise the top H1 to "Contributing"
CONTRIB_SRC="$SRC/CONTRIBUTING.md"
CONTRIB_DEST_DIR="$SITE_DIR/contributing"
CONTRIB_DEST="$CONTRIB_DEST_DIR/index.md"
GH_BASE="https://github.com/rossoctl/rossoctl"
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
      -e "s#\]\(\./#](${GH_BASE}/tree/main/#g" \
      -e "s#\]\(LICENSE\)#](${GH_BASE}/blob/main/LICENSE)#g" \
      -e 's/^# Contributing to this project.*/# Contributing/' \
      "$CONTRIB_SRC"
  } > "$CONTRIB_DEST"
  echo "==> contributing/index.md generated from rossoctl/rossoctl:CONTRIBUTING.md."
else
  echo "!! CONTRIBUTING.md not found at $CONTRIB_SRC (skipped Contributing page)." >&2
fi
