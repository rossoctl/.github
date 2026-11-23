#!/usr/bin/env bash
# sync-docs.sh — populate this site from the SOURCE OF TRUTH in rossoctl/rossoctl:
#   1. docs/       -> the site's docs/ (rendered as the Docs section)
#   2. CONTRIBUTING.md  -> the site's contributing/index.md (Contributing page)
# and from rossoctl/cortex:
#   3. scripts/install.sh and scripts/install.ps1 -> the site's cortex/ (served at
#      /cortex/install.sh and /cortex/install.ps1)
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
#   MOCA_REF=<branch|tag> ./scripts/sync-docs.sh                   # moca "next" ref (default: main)
#   MOCA_RELEASE=<vX.Y.Z|none> ./scripts/sync-docs.sh              # moca release (default: the latest)

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

# --- 3. Cortex installers: copy scripts/install.sh and install.ps1 -> cortex/ --
# Fatal if missing: a published URL without the file would serve HTML to `sh` or `iex`.
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
rsync -a "$CORTEX_SRC/scripts/install.ps1" "$SITE_DIR/cortex/install.ps1"
echo "==> cortex/install.sh and cortex/install.ps1 copied from ${CORTEX_SRC_REPO:-$CORTEX_REPO_URL}@$(git -C "$CORTEX_SRC" rev-parse --short HEAD)."


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
#
# VERSIONS: two refs are published, each through the same guard.
#   - MOCA_REF (default: main) -> moca/, the "next" version. With no release
#     published, it is the only version and is served at /moca/*.
#   - The newest moca release (GitHub's "latest", a vX.Y.Z tag) ->
#     moca_versioned_docs/version-X.Y.Z/, served at /moca/*, which moves "next"
#     to /moca/next/*. The version files Docusaurus reads (moca_versions.json,
#     moca_versioned_sidebars/) are written here too: nothing is committed, so
#     a new release needs no change in this repository.
# A release whose docs/ cannot be published (no docs/index.md, as in releases
# older than the docs site, or a guard match) is skipped with a warning, and
# the site publishes "next" alone. A failed lookup of the latest release fails
# the sync, so a GitHub API outage never moves every page from /moca/* to
# /moca/next/* and back: the deployed site stays as it was.
#   MOCA_RELEASE=vX.Y.Z  publish that release instead of the latest one
#   MOCA_RELEASE=none    publish "next" only (the default with MOCA_SRC_REPO)
# The lookup uses GITHUB_TOKEN when set: without it, GitHub allows 60 calls an
# hour per address, which a shared runner can run out of.
MOCA_REPO_URL="${MOCA_REPO_URL:-https://github.com/rossoctl/moca.git}"
MOCA_REF="${MOCA_REF:-main}"
MOCA_DEST="$SITE_DIR/moca"
MOCA_EXCLUDED=(specs notes plans archive demos adrs)
MOCA_VERSIONS_FILE="$SITE_DIR/moca_versions.json"
MOCA_VERSIONED_DOCS="$SITE_DIR/moca_versioned_docs"
MOCA_VERSIONED_SIDEBARS="$SITE_DIR/moca_versioned_sidebars"
# Temp dirs and files of this step. A local MOCA_SRC_REPO is never on the list.
MOCA_TMPS=()
trap 'rm -rf ${TMP:+"$TMP"} ${MOCA_TMPS[@]+"${MOCA_TMPS[@]}"}; [[ -n "${CORTEX_SRC_REPO:-}" ]] || rm -rf "$CORTEX_SRC"' EXIT

# moca_clone REF DIR: a sparse clone of rossoctl/moca's docs/ at REF, into DIR.
moca_clone() {
  git clone --depth 1 --branch "$1" --filter=blob:none --sparse "$MOCA_REPO_URL" "$2"
  git -C "$2" sparse-checkout set docs
}

# moca_publish SRC DESC GH_BASE DEST: guard SRC/docs and, if it passes, move it to
# DEST with its out-of-tree links pointed at GH_BASE. Sets MOCA_PUBLISHED=1 when
# DEST was written, 0 when the content was skipped.
moca_publish() {
  local src="$1" desc="$2" gh_base="$3" dest="$4" stage patterns leaks count x
  local scan_status=0
  local excludes=(--exclude '.DS_Store' --exclude '/_internal')
  MOCA_PUBLISHED=0
  if [[ ! -f "$src/docs/index.md" ]]; then
    echo "!! moca: docs/index.md not found in $desc: skipped." >&2
    return 0
  fi
  stage="$(mktemp -d)"
  MOCA_TMPS+=("$stage")
  for x in "${MOCA_EXCLUDED[@]}"; do excludes+=(--exclude "/$x"); done
  rsync -a "${excludes[@]}" "$src/docs/" "$stage/"

  # The guard always checks the internal-deployment names (SBXn), with or
  # without a denylist file upstream.
  patterns="$(mktemp)"
  MOCA_TMPS+=("$patterns")
  echo 'SBX[0-9]' > "$patterns"
  if [[ -f "$stage/.publish-denylist" ]]; then
    grep -vE '^[[:space:]]*(#|$)' "$stage/.publish-denylist" >> "$patterns" || true
    rm -f "$stage/.publish-denylist"
  fi
  # grep's status decides: 0 = a match (a leak), 1 = no match (clean), 2 or more = the scan
  # itself failed (a malformed pattern in the denylist, an unreadable file), which says
  # nothing about the content. Only 1 publishes: a failed scan is never a clean one.
  leaks="$(grep -rIlE -f "$patterns" "$stage")" || scan_status=$?
  if ((scan_status > 1)); then
    echo "::error title=Moca docs not published::the publish-denylist scan of $desc failed (grep exit $scan_status; a malformed pattern in docs/.publish-denylist?); it is skipped." >&2
  elif ((scan_status == 0)); then
    leaks="$(printf '%s\n' "$leaks" | sed "s#^$stage/#docs/#" | sort)"
    count="$(printf '%s\n' "$leaks" | wc -l | tr -d ' ')"
    echo "::warning title=Moca docs not published::$count file(s) in $desc match the publish denylist (SBXn, plus docs/.publish-denylist); it is skipped." >&2
    printf '%s\n' "$leaks" | sed 's/^/!!   /' >&2
  else
    # Relative links that leave the published tree (to ../../deploy/..., the
    # packages, or an excluded folder) would break on the site: point them at
    # the file on GitHub instead, at the ref the pages come from.
    node "$SCRIPT_DIR/rewrite-repo-links.mjs" "$stage" docs "$gh_base" "${MOCA_EXCLUDED[@]}"
    mkdir -p "$(dirname "$dest")"
    mv "$stage" "$dest"
    echo "==> $(basename "$dest") mirrors $desc:docs ($(find "$dest" -type f | wc -l | tr -d ' ') files)."
    MOCA_PUBLISHED=1
  fi
}

# moca_latest_release: prints the tag of rossoctl/moca's latest release, or
# nothing when it has none. Fails when GitHub cannot be asked.
moca_latest_release() {
  local out code
  local auth=()
  # Runs in a command substitution, so it removes its own temp file.
  out="$(mktemp)"
  [[ -z "${GITHUB_TOKEN:-}" ]] || auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
  code="$(curl -sSL -o "$out" -w '%{http_code}' ${auth[@]+"${auth[@]}"} \
    -H 'Accept: application/vnd.github+json' \
    https://api.github.com/repos/rossoctl/moca/releases/latest)" || code=000
  case "$code" in
    200) node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")).tag_name ?? "")' "$out" ;;
    404) ;; # no release published yet
    *)
      rm -f "$out"
      echo "::error title=Moca release lookup failed::GitHub answered HTTP $code for rossoctl/moca's latest release (403: the rate limit without GITHUB_TOKEN?); the sync stops, so the deployed site is unchanged." >&2
      return 1
      ;;
  esac
  rm -f "$out"
}

rm -rf "$MOCA_DEST" "$MOCA_VERSIONS_FILE" "$MOCA_VERSIONED_DOCS" "$MOCA_VERSIONED_SIDEBARS"

# 4a. "next": MOCA_REF, or a local clone.
if [[ -n "${MOCA_SRC_REPO:-}" ]]; then
  moca_publish "$MOCA_SRC_REPO" "$MOCA_SRC_REPO (local)" \
    "https://github.com/rossoctl/moca/blob/$MOCA_REF" "$MOCA_DEST"
else
  MOCA_SRC="$(mktemp -d)"
  MOCA_TMPS+=("$MOCA_SRC")
  moca_clone "$MOCA_REF" "$MOCA_SRC"
  moca_publish "$MOCA_SRC" "rossoctl/moca@$MOCA_REF ($(git -C "$MOCA_SRC" rev-parse --short HEAD))" \
    "https://github.com/rossoctl/moca/blob/$MOCA_REF" "$MOCA_DEST"
fi

# 4b. The release.
if [[ -n "${MOCA_RELEASE:-}" ]]; then
  MOCA_TAG="$MOCA_RELEASE"
elif [[ -n "${MOCA_SRC_REPO:-}" ]]; then
  MOCA_TAG=none
else
  MOCA_TAG="$(moca_latest_release)"
fi
if [[ -z "$MOCA_TAG" || "$MOCA_TAG" == none ]]; then
  echo "==> moca: no release to publish; the docs at $MOCA_REF are the only version."
elif [[ ! "$MOCA_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::warning title=Moca release not published::the latest release tag '$MOCA_TAG' is not vX.Y.Z; only $MOCA_REF is published." >&2
else
  MOCA_VERSION="${MOCA_TAG#v}"
  MOCA_RELEASE_SRC="$(mktemp -d)"
  MOCA_TMPS+=("$MOCA_RELEASE_SRC")
  moca_clone "$MOCA_TAG" "$MOCA_RELEASE_SRC"
  moca_publish "$MOCA_RELEASE_SRC" "rossoctl/moca@$MOCA_TAG" \
    "https://github.com/rossoctl/moca/blob/$MOCA_TAG" "$MOCA_VERSIONED_DOCS/version-$MOCA_VERSION"
  if ((MOCA_PUBLISHED)); then
    printf '["%s"]\n' "$MOCA_VERSION" > "$MOCA_VERSIONS_FILE"
    mkdir -p "$MOCA_VERSIONED_SIDEBARS"
    # The same autogenerated sidebar as sidebarsMoca.ts, frozen for the version.
    printf '{"mocaSidebar":[{"type":"autogenerated","dirName":"."}]}\n' \
      > "$MOCA_VERSIONED_SIDEBARS/version-$MOCA_VERSION-sidebars.json"
    echo "==> moca $MOCA_TAG is the default version at /moca/*; $MOCA_REF moves to /moca/next/*."
  fi
fi
