import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

/**
 * Sidebar for the "Ecosystem Guide" docs instance (see the plugin-content-docs
 * entry with id 'ecosystem' in docusaurus.config.ts). Order:
 *   Welcome to rossoctl (the landing page, /, holds the "about" content)
 *   Planning   -> Key Dates
 *   Project    -> Workstreams
 *   Community  -> Onboarding, Content, Resources
 *
 * `collapsible: false` renders each group as a permanent section header (no
 * collapse toggle), matching the upstream `navigation.sections` mkdocs feature.
 */
const sidebars: SidebarsConfig = {
  ecosystemSidebar: [
    {type: 'doc', id: 'welcome', label: 'Welcome to rossoctl'},
    {
      type: 'category',
      label: 'Planning',
      collapsible: false,
      items: [{type: 'doc', id: 'key-dates', label: 'Key Dates'}],
    },
    {
      type: 'category',
      label: 'Project',
      collapsible: false,
      items: [{type: 'doc', id: 'workstreams', label: 'Workstreams'}],
    },
    {
      type: 'category',
      label: 'Community',
      collapsible: false,
      items: [
        {type: 'doc', id: 'onboarding', label: 'Onboarding'},
        {type: 'doc', id: 'content', label: 'Content'},
        {type: 'doc', id: 'resources', label: 'Resources'},
      ],
    },
  ],
};

export default sidebars;
