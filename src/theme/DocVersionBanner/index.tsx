import React, {type ReactNode} from 'react';
import DocVersionBanner from '@theme-original/DocVersionBanner';
import type DocVersionBannerType from '@theme/DocVersionBanner';
import type {WrapperProps} from '@docusaurus/types';
import {useActivePlugin} from '@docusaurus/plugin-content-docs/client';

type Props = WrapperProps<typeof DocVersionBannerType>;

// The Moca docs are unversioned and track rossoctl/moca's main branch, so they
// can describe changes that are not in a release yet. Say so on every Moca
// page; every other docs instance keeps the stock version banner.
export default function DocVersionBannerWrapper(props: Props): ReactNode {
  const plugin = useActivePlugin();
  if (plugin?.pluginId === 'moca') {
    return (
      <div
        className={`${props.className ?? ''} alert alert--warning margin-bottom--md`}
        role="alert">
        These pages track moca&apos;s <code>main</code> branch and can describe changes that
        are not in a release yet. See the{' '}
        <a href="https://github.com/rossoctl/moca/releases">moca releases</a>.
      </div>
    );
  }
  return <DocVersionBanner {...props} />;
}
