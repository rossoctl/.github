import React, {type ReactNode} from 'react';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import {useThemeConfig} from '@docusaurus/theme-common';

// Custom site footer (overrides the classic theme Footer for ALL pages).
// A single dark bar: logo + wordmark on the left, links centered, copyright on
// the right. Content is read from `themeConfig.footer` in docusaurus.config.ts.

type FooterLinkItem = {label?: string; to?: string; href?: string};

function FooterLink({item}: {item: FooterLinkItem}): ReactNode {
  return (
    <Link className="rosso-footer__link" to={item.to} href={item.href}>
      {item.label}
    </Link>
  );
}

export default function Footer(): ReactNode {
  const {footer} = useThemeConfig();
  const homeUrl = useBaseUrl('/');
  const logoSrc = useBaseUrl((footer?.logo?.src as string) || 'img/logo.svg');

  if (!footer) {
    return null;
  }

  const {copyright, links = [], logo} = footer;
  // Flatten whether links are simple items or grouped columns.
  const items: FooterLinkItem[] = (links as any[]).flatMap((entry) =>
    entry && Array.isArray(entry.items) ? entry.items : [entry],
  );

  return (
    <footer className="rosso-footer">
      <div className="rosso-footer__inner">
        <Link className="rosso-footer__brand" to={homeUrl}>
          {logo && (
            <img
              src={logoSrc}
              alt={logo.alt || 'rossoctl'}
              width={(logo.width as number) || 22}
              height={(logo.height as number) || 22}
            />
          )}
          <span>rossoctl</span>
        </Link>

        <nav className="rosso-footer__links" aria-label="Footer">
          {items.filter((i) => i && i.label).map((item, i) => (
            <FooterLink key={i} item={item} />
          ))}
        </nav>

        {copyright && (
          <div className="rosso-footer__copyright">{copyright}</div>
        )}
      </div>
    </footer>
  );
}
