import React, {type ReactNode} from 'react';
import Link from '@docusaurus/Link';
import DocVersionBanner from '@theme-original/DocVersionBanner';
import type DocVersionBannerType from '@theme/DocVersionBanner';
import type {WrapperProps} from '@docusaurus/types';
import {
  useActiveDocContext,
  useActivePlugin,
  useLatestVersion,
  useVersions,
} from '@docusaurus/plugin-content-docs/client';

type Props = WrapperProps<typeof DocVersionBannerType>;

const RELEASES = 'https://github.com/rossoctl/moca/releases';

// Every Moca page says which moca it describes (see "=== Moca ===" in
// docusaurus.config.ts):
//   - the newest release: "These pages document moca vX.Y.Z", linking the
//     same page in "next";
//   - "next" (main) once a release is published: it can describe changes not
//     in vX.Y.Z yet, linking the same page in the release;
//   - main with no release published: it tracks main.
// Each link goes to the same page in the other version when it exists there,
// and to that version's home page otherwise. Every other docs instance keeps
// the stock version banner.
function MocaBanner({className}: {className?: string}): ReactNode {
  const {activeVersion, alternateDocVersions} = useActiveDocContext('moca');
  const latest = useLatestVersion('moca');
  const next = useVersions('moca').find((v) => v.name === 'current');
  const linkTo = (version: {name: string; path: string}) =>
    alternateDocVersions[version.name]?.path ?? version.path;
  const isRelease = activeVersion !== undefined && activeVersion.name !== 'current';

  let body: ReactNode;
  let level: 'info' | 'warning';
  if (isRelease) {
    level = 'info';
    body = (
      <>
        These pages document moca <b>{activeVersion.label}</b>, the latest{' '}
        <a href={RELEASES}>release</a>.
        {next && (
          <>
            {' '}
            For changes made since, see the <Link to={linkTo(next)}>next</Link> docs.
          </>
        )}
      </>
    );
  } else if (latest.name !== 'current') {
    level = 'warning';
    body = (
      <>
        These pages track moca&apos;s <code>main</code> branch and can describe changes that
        are not in <b>{latest.label}</b> yet. For the release, see the{' '}
        <Link to={linkTo(latest)}>{latest.label} docs</Link>.
      </>
    );
  } else {
    level = 'warning';
    body = (
      <>
        These pages track moca&apos;s <code>main</code> branch and can describe changes that
        are not in a release yet. See the <a href={RELEASES}>moca releases</a>.
      </>
    );
  }
  return (
    <div className={`${className ?? ''} alert alert--${level} margin-bottom--md`} role="alert">
      {body}
    </div>
  );
}

export default function DocVersionBannerWrapper(props: Props): ReactNode {
  const plugin = useActivePlugin();
  if (plugin?.pluginId === 'moca') {
    return <MocaBanner className={props.className} />;
  }
  return <DocVersionBanner {...props} />;
}
