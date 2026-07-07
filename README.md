# rossoctl website

The **rossoctl** website — a [Docusaurus](https://docusaurus.io/) site deployed to
GitHub Pages from this repository (`kagenti/.github`). It hosts the landing /
ecosystem guide and the product **Docs**.

> This repo also holds the kagenti org's community-health files (`profile/`,
> `.github/ISSUE_TEMPLATE/`, `.github/pull_request_template.md`, and the org
> reusable workflows). Those are unrelated to the website — leave them in place.

## Docs are synced, not authored here

The **Docs** section is **not** committed in this repo. It is synced at build time
from the source of truth — the **`docs-temp/`** folder in
[`kagenti/kagenti`](https://github.com/kagenti/kagenti). Edit docs there, not here.

- `scripts/sync-docs.sh` mirrors `kagenti/kagenti:docs-temp/` → `docs/` (git-ignored).
- CI runs `npm run sync-docs` before every build (see `.github/workflows/deploy.yaml`).
- Auto-sync: a push to `docs-temp/` in `kagenti/kagenti` fires a `repository_dispatch`
  (`docs-temp-updated`) that rebuilds and redeploys this site. A daily cron is the fallback.

## Local development

```sh
npm ci

# Pull the docs. Use a local kagenti clone if you have one:
SRC_REPO=/path/to/kagenti npm run sync-docs
# ...or fetch from GitHub (default branch main):
npm run sync-docs

npm start            # dev server (docs/ must be synced first)
npm run build        # production build into build/
npm run serve        # preview the production build
```

## Deployment

`.github/workflows/deploy.yaml` builds and publishes to GitHub Pages on push to
`main`, on the `docs-temp-updated` dispatch, on a daily schedule, and manually via
`workflow_dispatch`. It uploads the Docusaurus `build/` output as the Pages artifact.

Served today at `https://kagenti.github.io/.github/`. To move to a custom domain,
set `baseUrl: '/'` in `docusaurus.config.ts` and add `static/CNAME`.

## Structure

| Path | Purpose |
|------|---------|
| `ecosystem/` | Landing + ecosystem guide (served at `/`) |
| `docs/` | **Synced** from `kagenti/kagenti:docs-temp/` (git-ignored) |
| `contributing/` | Contributing docs instance |
| `src/`, `static/` | Theme customizations, CSS, and assets |
| `scripts/sync-docs.sh` | Docs sync from the source repo |

## Contributing

Commits require **DCO sign-off** (`git commit -s`). See [`CLAUDE.md`](./CLAUDE.md)
for the sign-off and attribution policy, and enable the hook with
`git config core.hooksPath scripts/hooks`.
