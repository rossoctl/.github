import React, {type ReactNode} from 'react';
import styles from './styles.module.css';

// Project card grid for the landing page's project directory. Each card names
// a focus project (the name links to its GitHub repository, where the details,
// instructions, and examples live), carries a one- to two-line essence of what
// the project does, and optionally lists further links — sibling repos in a
// family, a project site — in a muted footer row.

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
      {items.map((item) => (
        <div className={styles.card} key={item.repo}>
          <h3 className={styles.name}>
            <a
              href={`https://github.com/${item.repo}`}
              target="_blank"
              rel="noopener noreferrer">
              {item.name}
            </a>
          </h3>
          <p className={styles.desc}>{item.description}</p>
          {item.links && item.links.length > 0 && (
            <div className={styles.links}>
              {item.links.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  target="_blank"
                  rel="noopener noreferrer">
                  {link.label} ↗
                </a>
              ))}
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
