# ADR 0003: Local-First SQLite

## Status

Proposed for owner approval.

## Decision

Use SQLite as the only required v0.1 storage engine and run ALO primarily as an on-demand CLI. Keep storage boundaries compatible with a future PostgreSQL adapter, but do not implement server mode without measured demand.

## Rationale

SQLite satisfies one-machine deployment, offline use, transactions, migrations, backup, and inspectability without external services. First-year workload is bounded metadata, not full telemetry.

## Rejected alternatives

- PostgreSQL first.
- Distributed graph database.
- Embedded graph store without measured need.
- Memory-only graph.

## Consequences

v0.1 documents one-writer behavior, bounded queries, backup/WAL handling, and resource limits.
