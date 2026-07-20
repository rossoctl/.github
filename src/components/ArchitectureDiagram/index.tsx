import React from 'react';
import styles from './styles.module.css';

// Vertical, layered architecture overview modeled on the RossoCortex platform
// diagram (aios-beyondharness.pdf, p.1): RossoCortex on top (intercept points +
// a full-width Common Intercept Abstraction), which mediates calls out to the
// MCP Tool / API/CLI Tool / Agent targets below it; then the SDK / Hooks /
// Gateways integration layer, Orchestration, and the rossoctl services
// foundation. Pure HTML + CSS, colored through Infima theme variables so it
// adapts to light/dark and inherits the site's IBM Plex Sans.

const interceptPoints = [
  'Agent identity',
  'Authorization and access',
  'Intent-based access',
  'Tool semantic validation',
  'Context compaction',
  'Data-flow analysis',
  'Failure recovery',
  'User interaction',
];

const targets = ['MCP Tool', 'API/CLI Tool', 'Agent'];
const integrations = ['SDK', 'Hooks', 'Gateways'];
const services = ['Skills', 'Platform tools', 'Knowledge base', 'Memory', 'Sandboxes'];

function DownArrow() {
  return (
    <svg
      className={styles.downArrow}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <line x1="12" y1="4" x2="12" y2="18" />
      <polyline points="6 12 12 18 18 12" />
    </svg>
  );
}

function UpArrow() {
  return (
    <svg
      className={styles.upArrow}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <line x1="12" y1="20" x2="12" y2="6" />
      <polyline points="6 12 12 6 18 12" />
    </svg>
  );
}

export default function ArchitectureDiagram() {
  return (
    <figure
      className={styles.diagram}
      role="group"
      aria-label="RossoCortex intercepts every agent call to models, tools, users, and other agents; agents plug in through an SDK, hooks, or gateways, over orchestration and rossoctl services."
    >
      {/* RossoCortex — the intercept */}
      <div className={`${styles.band} ${styles.cortexBand}`}>
        <span className={styles.bandTitle}>RossoCortex</span>
        <div className={styles.capRow}>
          {interceptPoints.map((c) => (
            <span className={styles.capBox} key={c}>
              {c}
            </span>
          ))}
        </div>
        <div className={styles.abstractionBar}>Common Intercept Abstraction</div>
      </div>

      {/* Mediated targets — outside the RossoCortex box */}
      <div className={styles.targetsOut}>
        {targets.map((t) => (
          <div className={styles.targetOut} key={t}>
            <DownArrow />
            <span className={styles.targetTag}>{t}</span>
          </div>
        ))}
      </div>

      {/* Integration layer — an agent connects through one of these */}
      <div className={styles.integWrap}>
        <span className={styles.layerLabel}>Agents integrate via</span>
        <div className={styles.integRow}>
          {integrations.map((i) => (
            <div className={styles.integBox} key={i}>
              <span className={styles.integTitle}>{i}</span>
              <UpArrow />
              <span className={styles.agentTag}>Agent</span>
            </div>
          ))}
        </div>
      </div>

      {/* Orchestration */}
      <div className={styles.orchestration}>Orchestration</div>

      {/* rossoctl services foundation */}
      <div className={`${styles.band} ${styles.servicesBand}`}>
        <span className={styles.bandTitle}>Rossoctl services</span>
        <div className={styles.svcRow}>
          {services.map((s) => (
            <span className={styles.svcBox} key={s}>
              {s}
            </span>
          ))}
        </div>
      </div>
    </figure>
  );
}
