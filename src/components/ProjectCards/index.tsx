import React, {type ReactNode} from 'react';
import Link from '@docusaurus/Link';
import styles from './styles.module.css';

// Project card grid for the landing page's project directory. Each card names
// a focus project, carries a one- to two-line essence of what the project
// does, and always shows a "Get started" link to the project's GitHub
// repository — where the details, instructions, and examples live — plus any
// further links (sibling repos in a family, a project site) in a muted footer
// row.

export type ProjectLink = {
  label: string;
  href: string;
};

export type ProjectCard = {
  name: string;
  // GitHub repository path, e.g. 'rossoctl/moca'; the card title links there.
  repo: string;
  description: string;
  links?: ProjectLink[];
};

export default function ProjectCards({items}: {items: ProjectCard[]}): ReactNode {
  return (
    <div className={styles.grid}>
      {items.map((item) => {
        const repoUrl = `https://github.com/${item.repo}`;
        return (
          <div className={styles.card} key={item.repo}>
            <h3 className={styles.name}>
              <Link href={repoUrl} target="_blank" rel="noopener noreferrer">
                {item.name}
              </Link>
            </h3>
            <p className={styles.desc}>{item.description}</p>
            <div className={styles.links}>
              <Link href={repoUrl} target="_blank" rel="noopener noreferrer">
                Get started ↗
              </Link>
              {item.links?.map((link) => (
                <Link key={link.href} href={link.href} target="_blank" rel="noopener noreferrer">
                  {link.label} ↗
                </Link>
              ))}
            </div>
          </div>
        );
      })}
    </div>
  );
}
