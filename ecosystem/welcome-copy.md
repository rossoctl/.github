---
draft: true
sidebar_label: Welcome (previous version)
---

<!--
  BACKUP of the previous landing page content, kept so we can revert if needed.
  `draft: true` keeps it out of the production build; it is not linked in the
  sidebar. To restore, move this content back into welcome.md.
-->

# Welcome to rossoctl

rossoctl is an open source platform for deploying and governing AI agents on Kubernetes. It's framework-neutral — agents built with LangGraph, CrewAI, AG2, AutoGen, or any A2A-compatible framework all run on rossoctl. Communication uses open standards (A2A and MCP) so teams aren't locked into any vendor's stack.

The project started in early 2025 out of IBM Research with deep collaboration from Red Hat, and has grown to 12 repos, 43 org members, and 80+ contributors across both organizations.

## Where we're headed

Agents are changing. The tools developers reach for daily — Claude Code, Codex, OpenClaw — run continuously, rewrite their own files, and act without being asked. rossoctl's direction is the **secure deployment of autonomous agents on Kubernetes**.

The goal is a platform where always-on, self-modifying agents can run on your own infrastructure with real identity, governance, and isolation. Even companies using cloud-hosted agents will have workloads that can't leave their network — agents touching internal databases, proprietary code, secrets, internal APIs. rossoctl is intended to be where those agents run.

## The Problem

Frameworks and harnesses for building agents are maturing fast. But there is no widely adopted platform that gives you identity, governance, sandboxing, and audit for agents on Kubernetes — especially autonomous ones that make their own decisions and run unsupervised.

This is the same gap Kubernetes filled for containers a decade ago. Agents are the new workload.

## Who it's for

**Platform Engineer** — "People are deploying agents. I need to govern them." They need to enforce safety policies, scope permissions, audit what agents do, and isolate tenants.

**AI Engineer** — "I have an agent and I need to run it securely." Their agent needs to touch internal systems that can't leave their network, and cloud platforms can't give them the identity, governance, and audit their company requires.

## Differentiating capabilities

What rossoctl is building toward:

| Capability | What it solves |
|------------|---------------|
| **Workload Identity** | Cryptographic identity for agents via SPIFFE/SPIRE, not just API keys |
| **Tool Governance** | Deterministic filtering between agents and external services, with audit trails and human-in-the-loop approval |
| **Guardrails Enforcement** | Content safety and compliance policies for agents making autonomous decisions |
| **Sandboxing** | Isolated execution environments for agents running arbitrary code |
| **Authorization & Policy** | Scoped permissions with runtime policy enforcement |
| **Audit Trail** | Full record of agent actions for compliance |
| **Workspace Isolation** | Multi-tenant filesystem isolation for self-modifying agents |
| **State Management** | Persistent state and session management across restarts |
| **Agent Trust** | Signed agent cards, attestation of capabilities |
| **Skills Governance** | Skills as versioned, signed, governed artifacts |

## What the ecosystem covers today

| Area | What it does |
|------|-------------|
| **Developer Tooling** | ADK — CLI, Python + TypeScript SDKs, and a local dev environment. Build and test agents without a cluster. |
| **Lifecycle Orchestration** | Deploy agents and tools as containers via AgentCard CRDs. Auto-build with Shipwright. Discovery and registration handled by the operator. |
| **Networking** | MCP Gateway routes tool calls across agents. Istio service mesh for mTLS. Gateway API for ingress. |
| **Security** | Zero-trust from the ground up. SPIFFE/SPIRE for cryptographic workload identity. Keycloak for OAuth/OIDC. AuthBridge for token exchange. No static credentials. |
| **Observability** | Distributed tracing via MLflow, Langflow, and Phoenix. Network visualization through Kiali. Token cost attribution. OpenTelemetry auto-instrumentation. |
| **Security Testing** | Capture the Flag — red-team scenarios with real AI agents probing for policy violations. |
| **Benchmarking** | Agent benchmarking and test infrastructure for evaluating agent behavior at scale. |

## Community

The community ships weekly, publishes on [Medium](https://medium.com/kagenti-the-agentic-platform), and has presented at KubeCon NA 2025, KubeCon EU 2026, and The Cloudcast podcast.

See [Content](content.md) for the full list of blogs, demos, and coverage.
