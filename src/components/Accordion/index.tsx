import React, {useState, type ReactNode} from 'react';
import styles from './styles.module.css';

// Accordion used on the landing page for "Key capabilities" and "Rossoctl
// services", adapted from the designer's mock: numbered rows, a section title, a
// rotating chevron, row dividers, and the first item open by default. `redTitles`
// renders the item titles in the question-title red (#ef3030). An optional
// `status` renders a Ready / In progress / Next pill on the right of the row.

export type AccordionItem = {
  number: string;
  title: string;
  description?: string;
  status?: 'Ready' | 'In progress' | 'Next';
};

// Map a status label to its pill style.
const STATUS_CLASS: Record<string, string> = {
  'Ready': styles.pillReady,
  'beta in 0.7': styles.pillProgress,
  'alpha in 0.7': styles.pillNext,
};

function Chevron({open}: {open: boolean}): ReactNode {
  // Exact chevron glyph from the designer's mock (filled path, viewBox 0 0 10 5.7).
  return (
    <svg
      className={`${styles.chevron} ${open ? '' : styles.chevronClosed}`}
      width="12"
      height="7"
      viewBox="0 0 10 5.7"
      fill="none"
      aria-hidden="true">
      <path d="M5 5.7L0 0.7L0.7 0L5 4.3L9.3 0L10 0.7L5 5.7Z" fill="currentColor" />
    </svg>
  );
}

export default function Accordion({
  title,
  items,
  redTitles = false,
  previewWhenClosed = false,
}: {
  title?: string;
  items: AccordionItem[];
  redTitles?: boolean;
  // When closed: previewWhenClosed shows a truncated one-line description
  // (Open questions); otherwise the description is hidden (Key capabilities).
  previewWhenClosed?: boolean;
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
                {item.description && (open || previewWhenClosed) && (
                  <span
                    className={`${styles.desc} ${
                      !open && previewWhenClosed ? styles.descPreview : ''
                    }`}>
                    {item.description}
                  </span>
                )}
              </span>
              {item.status && (
                <span className={`${styles.pill} ${STATUS_CLASS[item.status] ?? ''}`}>
                  {item.status}
                </span>
              )}
              <Chevron open={open} />
            </button>
          );
        })}
      </div>
    </section>
  );
}
