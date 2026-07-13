import React, {useState, type ReactNode} from 'react';
import styles from './styles.module.css';

// Accordion used on the landing page for "Open questions" and "Key capabilities",
// adapted from the designer's mock: numbered rows, a section title, a rotating
// chevron, row dividers, and the first item open by default. `redTitles` renders
// the item titles in the question-title red (#ef3030) — used for Open questions.

export type AccordionItem = {
  number: string;
  title: string;
  description?: string;
};

function Chevron({open}: {open: boolean}): ReactNode {
  return (
    <svg
      className={`${styles.chevron} ${open ? '' : styles.chevronClosed}`}
      width="16"
      height="16"
      viewBox="0 0 10 6"
      fill="none"
      aria-hidden="true">
      <path d="M1 1l4 4 4-4" stroke="currentColor" strokeWidth="1.5" fill="none" />
    </svg>
  );
}

export default function Accordion({
  title,
  items,
  redTitles = false,
}: {
  title?: string;
  items: AccordionItem[];
  redTitles?: boolean;
}): ReactNode {
  const [openIndex, setOpenIndex] = useState<number>(0);

  return (
    <section className={styles.section}>
      {title && <h2 className={styles.sectionTitle}>{title}</h2>}
      <div className={styles.list}>
        {items.map((item, i) => {
          const open = openIndex === i;
          return (
            <button
              key={item.number}
              type="button"
              className={styles.row}
              aria-expanded={open}
              onClick={() => setOpenIndex(open ? -1 : i)}>
              <span className={styles.num}>{item.number}</span>
              <span className={styles.col}>
                <span
                  className={`${styles.title} ${redTitles ? styles.titleRed : ''}`}>
                  {item.title}
                </span>
                {item.description && open && (
                  <span className={styles.desc}>{item.description}</span>
                )}
              </span>
              <Chevron open={open} />
            </button>
          );
        })}
      </div>
    </section>
  );
}
