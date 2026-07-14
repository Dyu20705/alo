# Storage and Migrations

## Decision

SQLite is the only required v0.1 storage engine. ALO runs as one local process against one database. PostgreSQL remains a future adapter only after measured concurrency demand.

## Logical mapping

The relational design must separately represent:

- canonical identities;
- aliases and ambiguity candidates;
- sources and source instances;
- immutable evidence records;
- relationship endpoints;
- verification records;
- conflict groups and supersession;
- ingestion batches and outcomes;
- schema and migration metadata.

Core semantics must not be hidden in an unconstrained JSON blob. Bounded adapter-specific source payloads may be retained by digest or reference.

## Transactions

One ingestion unit is validated and canonicalized before commit. Identities, evidence, conflicts, verification records, and batch outcome become visible atomically. Failure before commit leaves no visible partial batch. Identical retries are semantic no-ops.

## Concurrency

v0.1 supports one writer. Reader concurrency is limited to tested SQLite behavior. WAL mode, busy timeout, checkpointing, and backup interaction must be measured and documented before release.

## Migrations

- Ordered, checksummed, and immutable after release.
- Applied using the safest supported transaction behavior.
- Database records current schema, application compatibility range, and migration checksums.
- Newer unsupported database is never modified.
- Downgrade migrations are not required.
- Restore from a pre-upgrade backup is the default rollback mechanism.
- Historical database fixtures are retained for migration tests.

## Backup and restore

Backup must capture a consistent database including relevant WAL state, carry schema/application metadata, and never overwrite a target without an explicit flag. Restore validates integrity and compatibility before use. Corrupt databases are preserved and not automatically repaired.

## Numeric budgets

Before v0.1, the benchmark issue must approve numeric limits for:

- migration and open time;
- 10k and 100k evidence ingestion;
- common trace latency;
- DB bytes per evidence record;
- transaction batch size;
- peak memory;
- backup and restore time;
- parser input limits.

## Rejected alternatives

- Graph database.
- PostgreSQL first.
- Embedded key-value store without measured need.
- In-memory-only graph.
