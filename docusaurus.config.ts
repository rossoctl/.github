import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: 'rossoctl',
  tagline:
    'A framework-neutral, scalable, secure platform for deploying, securing, and governing AI agents.',
  favicon: 'img/favicon.svg',

  // Note: the `future.v4`/`experimental_faster` (Rspack) bundler is intentionally
  // NOT enabled — it requires the extra @docusaurus/faster native package. The
  // default webpack bundler keeps this setup minimal and portable. Re-add
  // `@docusaurus/faster` + `future: { experimental_faster: true }` if build
  // speed becomes a concern.

  // === GitHub Pages: deployed from the kagenti/.github repo ===
  // Served today at https://kagenti.github.io/.github/ (project-page path =
  // repo name ".github"). When a custom domain is added, flip baseUrl to '/'
  // and drop a static/CNAME file (change all four below together).
  url: 'https://kagenti.github.io',
  baseUrl: '/.github/',
  organizationName: 'kagenti', // GitHub org that owns the repo
  projectName: '.github', // repo name -> drives the Pages path

  // Relaxed to 'warn' so the docs synced from kagenti/kagenti:docs-temp/ (which
  // still contain some cross-repo relative links) don't fail the Pages build.
  // Tighten to 'throw' once the upstream docs-temp links are cleaned up.
  onBrokenLinks: 'warn',

  markdown: {
    // 'detect' = .md files render as (lenient) CommonMark, .mdx as MDX. Lets the
    // synced upstream GitHub-flavored .md render without MDX parse errors on bare
    // '<', '{', or raw HTML. Our own .mdx pages keep MDX powers.
    format: 'detect',
    mermaid: true, // render ```mermaid fenced blocks as diagrams (used by the docs)
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          // Read docs from a local docs-temp/ folder that mirrors the source of
          // truth 1:1. This folder is NOT committed — scripts/sync-docs.sh syncs
          // it from kagenti/kagenti:docs-temp/ at build time. routeBasePath keeps
          // the public URLs at /docs/* and the navbar label is "Docs".
          path: 'docs-temp',
          routeBasePath: 'docs',
          sidebarPath: './sidebars.ts',
          // "Edit this page" points at the source of truth upstream.
          editUrl: 'https://github.com/kagenti/kagenti/tree/main/docs-temp/',
          // Versioning: the current (un-versioned) docs are the in-progress
          // "dev" docs, shown in the header version dropdown. No released
          // versions exist yet. When the first is cut
          // (`npm run docusaurus docs:version 0.7`), it becomes the default
          // "latest" and "dev" stays as the work-in-progress version.
          versions: {
            current: {
              label: 'dev',
            },
          },
        },
        // Blog is an EXTERNAL Medium link (see navbar) — no local blog.
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
        sitemap: {
          changefreq: 'weekly',
          priority: 0.5,
          filename: 'sitemap.xml',
        },
      } satisfies Preset.Options,
    ],
  ],

  plugins: [
    // Offline, build-time full-text search. No external service.
    [require.resolve('docusaurus-lunr-search'), {languages: ['en']}],
    // Dedicated docs instance for the Contributing section, so /contributing
    // renders with the SAME layout as docs (breadcrumb, content position,
    // typography) instead of a bespoke standalone page. Same pattern llm-d
    // uses for its Community section.
    [
      '@docusaurus/plugin-content-docs',
      {
        id: 'contributing',
        path: 'contributing',
        routeBasePath: 'contributing',
        sidebarPath: './sidebarsContributing.ts',
        editUrl: 'https://github.com/Ibrahim2595/rossoctl-website/tree/main/',
      },
    ],
    // "Ecosystem Guide" — a faithful recreation of kagenti/ecosystem-guide,
    // rebranded to rossoctl. This instance IS the site landing experience:
    // routeBasePath '/' serves it at the site root, and welcome.md (slug '/')
    // is the homepage, reproducing the upstream Welcome/README page inside the
    // normal docs layout (left sidebar + content), NOT a custom hero. The
    // sidebar groups mirror that repo's mkdocs.yml nav. Pages: About,
    // Onboarding, Workstreams, Key Dates, Content, Resources.
    [
      '@docusaurus/plugin-content-docs',
      {
        id: 'ecosystem',
        path: 'ecosystem',
        routeBasePath: '/',
        sidebarPath: './sidebarsEcosystem.ts',
        editUrl:
          'https://github.com/kagenti/ecosystem-guide/tree/main/content/',
      },
    ],
  ],

  // Enables Mermaid diagram rendering (paired with markdown.mermaid: true).
  themes: ['@docusaurus/theme-mermaid'],

  themeConfig: {
    image: 'img/logo.svg',
    colorMode: {
      respectPrefersColorScheme: true,
    },
    // Understated, dismissible "work in progress" notice — a thin bar above the
    // navbar. Replaces the earlier large in-page banner; keeps the doc layout
    // itself untouched.
    announcementBar: {
      id: 'wip',
      content: 'This site is a work in progress.',
      backgroundColor: '#ee0000', // rossoctl brand red
      textColor: '#ffffff',
      isCloseable: true,
    },
    navbar: {
      title: 'rossoctl',
      logo: {
        alt: 'rossoctl',
        src: 'img/logo.svg',
        // clicking the logo/title goes to '/', the landing page
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Docs',
        },
        {
          // Single "Contributing" page rendered from the contributing docs
          // instance (docs layout + breadcrumbs). Content mirrors kagenti's
          // CONTRIBUTING.md.
          type: 'docSidebar',
          sidebarId: 'contributingSidebar',
          docsPluginId: 'contributing',
          position: 'left',
          label: 'Contributing',
        },
        {
          // EXTERNAL blog — opens in a new tab.
          href: 'https://medium.com/kagenti-the-agentic-platform',
          label: 'Blog',
          position: 'left',
          target: '_blank',
          rel: 'noopener noreferrer',
        },
        {
          // Docs version selector, on the left after Blog. Rendered as an
          // explicit dropdown (caret + menu) because Docusaurus collapses its
          // built-in `docsVersionDropdown` to a plain link while only one
          // version exists. Selecting "dev" opens the first docs page
          // (Getting Started). When v0.7 is cut, replace this with
          // `{ type: 'docsVersionDropdown', position: 'left' }` — it will then
          // auto-list v0.7 (latest) and dev.
          type: 'dropdown',
          label: 'dev',
          position: 'left',
          items: [
            {
              label: 'dev',
              to: '/docs/category/getting-started',
            },
          ],
        },
        {
          // Rendered as a GitHub icon (see .header-github-link in custom.css).
          href: 'https://github.com/kagenti/kagenti',
          position: 'right',
          className: 'header-github-link',
          'aria-label': 'GitHub repository',
        },
        {
          // Slack icon + small "Join Slack" label (see .header-slack-link in custom.css).
          href: 'https://ibm.biz/kagenti-slack',
          position: 'right',
          className: 'header-slack-link',
          label: 'Join Slack',
          'aria-label': 'Slack community',
        },
      ],
    },
    footer: {
      style: 'dark',
      logo: {
        alt: 'rossoctl',
        src: 'img/logo.svg',
        width: 22,
        height: 22,
      },
      links: [
        {
          items: [
            {label: 'GitHub', href: 'https://github.com/kagenti/kagenti'},
            {label: 'Docs', to: '/docs/category/getting-started'},
            {
              label: 'Blog',
              href: 'https://medium.com/kagenti-the-agentic-platform',
            },
            {
              label: 'Contributing',
              href: 'https://github.com/kagenti/kagenti/blob/main/CONTRIBUTING.md',
            },
            {
              label: 'Apache 2.0',
              href: 'https://github.com/kagenti/kagenti/blob/main/LICENSE',
            },
          ],
        },
      ],
      copyright: `© ${new Date().getFullYear()} rossoctl Contributors`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'yaml', 'json', 'go'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
