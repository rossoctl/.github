# rossoctl website

The **rossoctl** website — a [Docusaurus](https://docusaurus.io/) site deployed to
GitHub Pages from this repository (`rossoctl/.github`). It hosts the landing /
ecosystem guide and the product **Docs**.

> This repo also holds the rossoctl org's community-health files (`profile/`,
> `.github/ISSUE_TEMPLATE/`, `.github/pull_request_template.md`, and the org
> reusable workflows). Those are unrelated to the website — leave them in place.

## Docs are synced, not authored here

The **Docs** section is **not** committed in this repo. It is synced at build time
from the source of truth — the **`docs-temp/`** folder in
[`rossoctl/rossoctl`](https://github.com/rossoctl/rossoctl). Edit docs there, not here.

- `scripts/sync-docs.sh` mirrors `rossoctl/rossoctl:docs-temp/` → `docs/` (git-ignored).
- CI runs `npm run sync-docs` before every build (see `.github/workflows/deploy.yaml`).
- Auto-sync: a push to `docs-temp/` in `rossoctl/rossoctl` fires a `repository_dispatch`
  (`docs-temp-updated`) that rebuilds and redeploys this site. A daily cron is the fallback.

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

# 3. Run the dev server with hot reload (docs must be synced first — step 2)
npm start            # http://localhost:3000/.github/  (Ctrl+C to stop)
```

To verify a production build the way CI does — this is the check that matters
before pushing, since `npm start` is more lenient than a real build:

```sh
npm run build        # production build into build/  (fails on broken links, type errors)
npm run serve        # preview that build locally
npm run typecheck    # TypeScript check only (tsc, no emit)
```

## Deployment

`.github/workflows/deploy.yaml` builds and publishes to GitHub Pages on push to
`main`, on the `docs-temp-updated` dispatch, on a daily schedule, and manually via
`workflow_dispatch`. It uploads the Docusaurus `build/` output as the Pages artifact.

Served today at `https://rossoctl.github.io/.github/`. To move to a custom domain,
set `baseUrl: '/'` in `docusaurus.config.ts` and add `static/CNAME`.

## Structure

| Path | Purpose |
|------|---------|
| `ecosystem/` | Landing + ecosystem guide (served at `/`) |
| `docs/` | **Synced** from `rossoctl/rossoctl:docs-temp/` (git-ignored) |
| `contributing/` | Contributing docs instance |
| `src/`, `static/` | Theme customizations, CSS, and assets |
| `scripts/sync-docs.sh` | Docs sync from the source repo |

## Contributing

Commits require **DCO sign-off** (`git commit -s`). See [`CLAUDE.md`](./CLAUDE.md)
for the sign-off and attribution policy, and enable the hook with
`git config core.hooksPath scripts/hooks`.
