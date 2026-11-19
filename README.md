# rossoctl website

The **rossoctl** website — a [Docusaurus](https://docusaurus.io/) site deployed to
GitHub Pages from this repository (`rossoctl/.github`). It hosts the landing /
ecosystem guide and the product **Docs**.

> This repo also holds the rossoctl org's community-health files (`profile/`,
> `.github/ISSUE_TEMPLATE/`, `.github/pull_request_template.md`, and the org
> reusable workflows). Those are unrelated to the website — leave them in place.

## Docs are synced, not authored here

The **Docs** section is **not** committed in this repo. It is synced at build time
from the source of truth — the **`docs/`** folder in
[`rossoctl/rossoctl`](https://github.com/rossoctl/rossoctl). Edit docs there, not here.

- `scripts/sync-docs.sh` mirrors `rossoctl/rossoctl:docs/` → `docs/` (git-ignored).
- CI runs `npm run sync-docs` before every build (see `.github/workflows/deploy.yaml`).
- Auto-sync: a push to `docs/` in `rossoctl/rossoctl` fires a `repository_dispatch`
  (`docs-updated`) that rebuilds and redeploys this site. A daily cron is the fallback.

### The Moca section

The **Moca** section (`/moca/*`) is synced the same way, from the `docs/` folder of
[`rossoctl/moca`](https://github.com/rossoctl/moca), into `moca/` (git-ignored):

- The sync leaves out moca's design records: `specs/`, `notes/`, `plans/`, `archive/`, `demos/`,
  and `adrs/`. They are kept off the pages and out of search.
- Relative links that leave the published tree are rewritten to the file on GitHub
  (`scripts/rewrite-repo-links.mjs`).
- **Publish guard.** If any file to be published matches moca's denylist, the whole Moca section
  is skipped and the matching files are listed in the build log. The denylist is the built-in
  `SBX[0-9]` plus the patterns in `docs/.publish-denylist`. With no `moca/index.md`, the site
  builds without the Moca instance and its navbar item. Fix the content in `rossoctl/moca`: there
  is no bypass.
- **Versions.** The sync also publishes moca's newest release (GitHub's "latest", a `vX.Y.Z`
  tag), through the same guard. It is served at `/moca/*`, and `main` moves to `/moca/next/*`,
  which search does not index. The sync writes the version files (`moca_versions.json`,
  `moca_versioned_docs/`, `moca_versioned_sidebars/`, git-ignored), so a new release needs no
  change here. Until a release passes the guard (v0.10.0 does not), `main` is the only version,
  at `/moca/*`. A failed lookup of the latest release fails the sync, so the deployed site stays
  as it was. A banner on every Moca page says which version it is, and links the same page in the
  other (`src/theme/DocVersionBanner`).
- A push to `docs/` in `rossoctl/moca`, and a published moca release, send the same
  `docs-updated` dispatch.

## Running and testing locally

### Prerequisites

- **Node.js 20 or newer** (see `engines` in `package.json`).
- **npm** — this project is npm-based; a `package-lock.json` is committed. There is
  no `yarn.lock`/`pnpm-lock.yaml`, so don't use yarn or pnpm (they'd generate a
  competing lockfile). Every command below is an `npm run` script from `package.json`.

### Repositories to clone

| Repo | Why you need it |
|------|-----------------|
| [`rossoctl/.github`](https://github.com/rossoctl/.github) (this repo) | The website itself. **Required.** |
| [`rossoctl/moca`](https://github.com/rossoctl/moca) | Source of truth for the **Moca** section. **Optional**, like `rossoctl/rossoctl`. |
| [`rossoctl/rossoctl`](https://github.com/rossoctl/rossoctl) | Source of truth for the **Docs** and **Contributing** content. **Optional** — only clone it if you want to preview local, unpushed doc edits. Otherwise the sync step fetches published docs straight from GitHub. |

### Steps

```sh
# 1. Install dependencies (clean, lockfile-exact install)
npm ci

# 2. Pull the Docs + Contributing content (git-ignored, regenerated each build).
#    a) From GitHub — no rossoctl clone needed (default branch: main):
npm run sync-docs
#    b) ...or from a local rossoctl clone, to preview edits you haven't pushed:
SRC_REPO=/path/to/rossoctl npm run sync-docs
#    c) Moca from a local clone or another ref (default: rossoctl/moca@main),
#       and a release (default: the latest, none with MOCA_SRC_REPO):
MOCA_SRC_REPO=/path/to/moca npm run sync-docs
MOCA_REF=<branch-or-tag> npm run sync-docs
MOCA_RELEASE=<vX.Y.Z|none> npm run sync-docs

# 3. Run the dev server with hot reload (docs must be synced first — step 2)
npm start            # http://localhost:3000/.github/  (Ctrl+C to stop)
```

We do not use `npm start` to run the dev server with hot reload, because we make heavy use of the `draft` feature, which is not suppressed by `start`.

```sh
npm run build        # production build into build/  (fails on broken links, type errors)
npm run serve        # preview that build locally
npm run typecheck    # TypeScript check only (tsc, no emit)
```

## Deployment

`.github/workflows/deploy.yaml` builds and publishes to GitHub Pages on push to
`main`, on the `docs-updated` dispatch, on a daily schedule, and manually via
`workflow_dispatch`. It uploads the Docusaurus `build/` output as the Pages artifact.

Served today at `https://rossoctl.github.io/.github/`. To move to a custom domain,
set `baseUrl: '/'` in `docusaurus.config.ts` and add `static/CNAME`.

## Structure

| Path | Purpose |
|------|---------|
| `ecosystem/` | Landing + ecosystem guide (served at `/`) |
| `docs/` | **Synced** from `rossoctl/rossoctl:docs/` (git-ignored) |
| `moca/` | **Synced** from `rossoctl/moca:docs/` behind the publish guard (git-ignored) |
| `moca_versions.json`, `moca_versioned_*/` | **Synced** moca release, from its tag (git-ignored) |
| `contributing/` | Contributing docs instance |
| `src/`, `static/` | Theme customizations, CSS, and assets |
| `scripts/sync-docs.sh` | Docs sync from the source repos |
| `scripts/rewrite-repo-links.mjs` | Rewrites links that leave a synced tree to GitHub URLs |

## Contributing

Commits require **DCO sign-off** (`git commit -s`). See [`CLAUDE.md`](./CLAUDE.md)
for the sign-off and attribution policy, and enable the hook with
`git config core.hooksPath scripts/hooks`.

