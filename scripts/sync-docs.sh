#!/usr/bin/env bash
# sync-docs.sh — populate this site from the SOURCE OF TRUTH in rossoctl/rossoctl:
#   1. docs/       -> the site's docs/ (rendered as the Docs section)
#   2. CONTRIBUTING.md  -> the site's contributing/index.md (Contributing page)
# and from rossoctl/cortex:
#   3. scripts/install.sh -> the site's cortex/install.sh (served at /cortex/install.sh)
# and from rossoctl/moca:
#   4. docs/       -> the site's moca/ (the Moca section, served at /moca/*), behind a
#                     publish guard (see step 4)
#
# All destinations are git-ignored here and regenerated on every build (CI runs
# this before `npm run build`; see .github/workflows/deploy.yaml). The canonical
# content lives in those upstream repos — edit it there, not here.
#
# Usage:
#   ./scripts/sync-docs.sh [git-ref]                       # clone from GitHub (default: main)
#   SRC_REPO=/path/to/local/rossoctl ./scripts/sync-docs.sh # use an existing local clone
#   CORTEX_SRC_REPO=/path/to/local/cortex ./scripts/sync-docs.sh # likewise for cortex
#   MOCA_SRC_REPO=/path/to/local/moca ./scripts/sync-docs.sh     # likewise for moca
#   MOCA_REF=<branch|tag> ./scripts/sync-docs.sh                   # moca ref (default: main)

set -euo pipefail

REF="${1:-main}"
REPO_URL="https://github.com/rossoctl/rossoctl.git" # source of truth
CORTEX_REPO_URL="${CORTEX_REPO_URL:-https://github.com/rossoctl/cortex.git}"
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
  # _internal/ holds the team's engineering notes (plans, research, retrospectives,
  # QA matrices, developer setup). Docusaurus would ignore them anyway via its
  # default '**/_*/**' exclude, but keeping them out of the site tree entirely
  # matters for versioning: `docusaurus docs:version` snapshots whatever is in
  # docs/ into a COMMITTED versioned_docs/ folder, so without this every release
  # would freeze a copy of those notes into this repo.
  # '/_internal' is anchored to the top of the transfer, so it excludes exactly
  # docs/_internal/ and not a directory of that name at any other depth.
  rsync -a --delete --exclude '.DS_Store' --exclude '/_internal' "$UP"/ "$DEST"/

  # MIGRATION WINDOW: the restructured docs tree provides docs/index.md with
  # `slug: /` as the /docs/ landing page (see sidebars.ts, which no longer wraps
  # everything in a generated-index category). Until that lands upstream,
  # synthesise a minimal one so the /docs/ route — and the navbar's
  # "Documentation" link — still resolves. This becomes a no-op the moment
  # upstream ships its own index.md, and can then be deleted.
  if [[ ! -f "$DEST/index.md" ]]; then
    printf -- '---\ntitle: Rossoctl documentation\nslug: /\n---\n\nChoose a section from the sidebar.\n' \
      > "$DEST/index.md"
    echo "==> synthesised docs/index.md (upstream does not provide one yet)."
  fi

  # Rewrite any remaining links to README.md -> index.md (Docusaurus folder-index
  # convention), so a cross-link written against a folder README still resolves.
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

# --- 3. Cortex installer: copy scripts/install.sh -> cortex/install.sh -------
# Fatal if missing: a published URL without the file would serve HTML to `sh`.
if [[ -n "${CORTEX_SRC_REPO:-}" ]]; then
  CORTEX_SRC="$CORTEX_SRC_REPO"
else
  CORTEX_SRC="$(mktemp -d)"
  trap 'rm -rf ${TMP:+"$TMP"} "$CORTEX_SRC"' EXIT
  git clone --depth 1 --filter=blob:none --sparse "$CORTEX_REPO_URL" "$CORTEX_SRC"
  git -C "$CORTEX_SRC" sparse-checkout set scripts
fi
mkdir -p "$SITE_DIR/cortex"
rsync -a "$CORTEX_SRC/scripts/install.sh" "$SITE_DIR/cortex/install.sh"
echo "==> cortex/install.sh copied from ${CORTEX_SRC_REPO:-$CORTEX_REPO_URL}@$(git -C "$CORTEX_SRC" rev-parse --short HEAD)."

# --- 4. Moca docs: rossoctl/moca:docs/ -> moca/ (served at /moca/*) -----------
# moca/ is git-ignored and rebuilt on every sync. docusaurus.config.ts adds the
# moca docs instance and its navbar item only when moca/index.md exists, so a
# skipped sync leaves the site exactly as it was without Moca.
#
# Published from moca's docs/ is the user documentation only. Its design
# records (specs/, notes/, plans/, archive/, demos/, adrs/) stay
# in that repository; excluding them here keeps them out of the pages AND the
# search index, not just the sidebar.
#
# PUBLISH GUARD: moca's docs/.publish-denylist lists extended regular expressions
# (one per line, '#' comments) that must never appear on the public site, e.g.
# the names of internal deployments. Any match in the files to be published
# skips the whole moca section, with the matching files listed: nothing is
# published partly. The guard has no bypass; fix the content in rossoctl/moca.
MOCA_REPO_URL="${MOCA_REPO_URL:-https://github.com/rossoctl/moca.git}"
MOCA_REF="${MOCA_REF:-main}"
MOCA_GH_BASE="https://github.com/rossoctl/moca/blob/$MOCA_REF"
MOCA_DEST="$SITE_DIR/moca"
MOCA_EXCLUDED=(specs notes plans archive demos adrs)
if [[ -n "${MOCA_SRC_REPO:-}" ]]; then
  MOCA_SRC="$MOCA_SRC_REPO"
  MOCA_DESC="$MOCA_SRC_REPO (local)"
else
  MOCA_SRC="$(mktemp -d)"
  # Temp clones only: a local CORTEX_SRC_REPO / MOCA_SRC_REPO is never removed.
  trap 'rm -rf ${TMP:+"$TMP"} "$MOCA_SRC" ${MOCA_STAGE:+"$MOCA_STAGE"}; [[ -n "${CORTEX_SRC_REPO:-}" ]] || rm -rf "$CORTEX_SRC"' EXIT
  git clone --depth 1 --branch "$MOCA_REF" --filter=blob:none --sparse "$MOCA_REPO_URL" "$MOCA_SRC"
  git -C "$MOCA_SRC" sparse-checkout set docs
  MOCA_DESC="rossoctl/moca@$MOCA_REF ($(git -C "$MOCA_SRC" rev-parse --short HEAD))"
fi
rm -rf "$MOCA_DEST"
if [[ ! -f "$MOCA_SRC/docs/index.md" ]]; then
  echo "!! moca: docs/index.md not found in $MOCA_DESC: Moca section skipped." >&2
else
  MOCA_STAGE="$(mktemp -d)"
  excludes=(--exclude '.DS_Store' --exclude '/_internal')
  for x in "${MOCA_EXCLUDED[@]}"; do excludes+=(--exclude "/$x"); done
  rsync -a "${excludes[@]}" "$MOCA_SRC/docs/" "$MOCA_STAGE/"

  # The guard always checks the internal-deployment names (SBXn), with or
  # without a denylist file upstream.
  patterns="$(mktemp)"
  echo 'SBX[0-9]' > "$patterns"
  if [[ -f "$MOCA_STAGE/.publish-denylist" ]]; then
    grep -vE '^[[:space:]]*(#|$)' "$MOCA_STAGE/.publish-denylist" >> "$patterns" || true
    rm -f "$MOCA_STAGE/.publish-denylist"
  fi
  # grep's status decides: 0 = a match (a leak), 1 = no match (clean), 2 or more = the scan
  # itself failed (a malformed pattern in the denylist, an unreadable file), which says
  # nothing about the content. Only 1 publishes: a failed scan is never a clean one.
  scan_status=0
  leaks="$(grep -rIlE -f "$patterns" "$MOCA_STAGE")" || scan_status=$?
  rm -f "$patterns"
  if ((scan_status > 1)); then
    echo "::error title=Moca docs not published::the publish-denylist scan of $MOCA_DESC failed (grep exit $scan_status; a malformed pattern in docs/.publish-denylist?); the Moca section is skipped." >&2
    rm -rf "$MOCA_STAGE"
  elif ((scan_status == 0)); then
    leaks="$(printf '%s\n' "$leaks" | sed "s#^$MOCA_STAGE/#docs/#" | sort)"
    count="$(printf '%s\n' "$leaks" | wc -l | tr -d ' ')"
    echo "::warning title=Moca docs not published::$count file(s) in $MOCA_DESC match the publish denylist (SBXn, plus docs/.publish-denylist); the Moca section is skipped." >&2
    printf '%s\n' "$leaks" | sed 's/^/!!   /' >&2
    rm -rf "$MOCA_STAGE"
  else
    # Relative links that leave the published tree (to ../../deploy/..., the
    # packages, or an excluded folder) would break on the site: point them at
    # the file on GitHub instead.
    node "$SCRIPT_DIR/rewrite-repo-links.mjs" "$MOCA_STAGE" docs "$MOCA_GH_BASE" "${MOCA_EXCLUDED[@]}"
    mv "$MOCA_STAGE" "$MOCA_DEST"
    echo "==> moca/ mirrors $MOCA_DESC:docs ($(find "$MOCA_DEST" -type f | wc -l | tr -d ' ') files)."
  fi
fi
