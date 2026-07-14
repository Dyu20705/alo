# ADR 0001: Project Scope

## Status

Proposed for owner approval.

## Decision

ALO's first product is a local userspace evidence engine for one developer or release engineer and one repository/release. It uses SQLite and a CLI for ingestion, trace, verification, and reporting. Runtime evidence, Kubernetes, SaaS, dashboards, plugin runtimes, AI, and ML lineage are excluded from the first year.

## Rationale

The durable problem is evidence correlation, not a specific sensor or standard. A narrow source/build/artifact workflow can prove the model and operating discipline on one machine. Runtime/platform work before identity, temporal, conflict, and migration semantics would create technology-driven scope and privileged attack surface.

## Rejected alternatives

- Start with eBPF.
- Start with Kubernetes.
- Start with a web dashboard.
- Build a broad GUAC-like supply-chain graph.
- Build multiple microservices.

## Consequences

The first strong demo is evidence correctness and explainability, not a live runtime map.
