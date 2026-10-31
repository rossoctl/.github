## Rossoctl

Open source infrastructure for running, connecting, and benchmarking AI coding agents — built in the open at [rossoctl.dev](https://www.rossoctl.dev/).

### Repositories

#### Core projects

- **[moca](https://github.com/rossoctl/moca)** - Dense, warm process-manager runtime for stateful AI coding agents — sessions resume exactly where they left off (Go)
- **[cortex](https://github.com/rossoctl/cortex)** - The proxy layer between coding agents and everything they touch — see what your agent sends and pay less for it (Go) — [install stats](https://rossoctl.github.io/cortex/install-stats/) (estimated from GitHub download counts, not from user machines)
- **[eventing-lab](https://github.com/rossoctl/eventing-lab)** - Signed-event agent wake path: a Kafka message wakes a coding agent and every step streams back as CloudEvents (Python)
- **[autobench](https://github.com/rossoctl/autobench)** - Automated benchmarking of agentic AI workloads — deploys the workload, collects per-task telemetry, publishes durable artifacts (Python)
- **[state-lab](https://github.com/rossoctl/state-lab)** - Demo flows exploring state requirements for distributed agents, from durability to passability

#### Context & governance

- **[context-guru](https://github.com/rossoctl/context-guru)** - Provider-agnostic context engineering for LLM agents — lower token cost and latency without sacrificing accuracy (Go)
- **[aiac](https://github.com/rossoctl/aiac)** - AI-based access control — translates natural-language policy into enforced permissions on OPA (Python)
- **[lab-data-governance](https://github.com/rossoctl/lab-data-governance)** - Data-aware governance: observes how data flows across agents, tools, and sessions, and derives interactions, classifications, and lineage (Python)
- **[context-service](https://github.com/rossoctl/context-service)** - Agent context infrastructure: durable storage and lifecycle management for agent state, memory, knowledge, workspaces, and artifacts (Go)

#### Automation & repo maintenance

- **[automation](https://github.com/rossoctl/automation)** - Automated org maintenance programs using a scanner/fixer pattern (Shell)
- **[repoman](https://github.com/rossoctl/repoman)** - RepoMan: automated repo-maintenance programs across enrolled GitHub repos (Shell)

#### Platform & docs

- **[rossoctl](https://github.com/rossoctl/rossoctl)** - Installer, web console, and documentation (Python)
- **[.github](https://github.com/rossoctl/.github)** - Project website and documentation (Docusaurus)

### Get involved

- 📖 Start with the [CONTRIBUTING](https://github.com/rossoctl/rossoctl/blob/main/CONTRIBUTING.md) guide
- 👥 Meet the [maintainers](https://github.com/rossoctl/rossoctl/blob/main/MAINTAINERS.md)
- 🌐 Learn more at [rossoctl.dev](https://www.rossoctl.dev/)
- 💬 Or just come say hi in the [Rossoctl Slack](https://ibm.biz/rossoctl-slack)
