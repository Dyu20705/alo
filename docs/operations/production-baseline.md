# Production Baseline

## Correctness

- Canonicalization is deterministic and idempotent.
- Evidence ID excludes volatile ingestion fields.
- Duplicate, corroborating, conflicting, and superseding evidence have distinct behavior.
- Validity intervals are half-open and observation time is separate.
- Ingestion is atomic and idempotent; fault injection proves no partial batch.
- Migrations are ordered, checksummed, immutable, and tested against historical databases.
- JSON output is deterministic and schema-versioned.
- Stable fixtures and golden outputs are reviewed as semantic assets.

## Security

- Every v0.1 input crosses a named trust boundary.
- Parsers have explicit byte, depth, element, relation, string, and alias limits.
- Repository paths are normalized; repository code and hooks are never executed.
- Archives and layers are not extracted by default.
- Signature validity, signer identity, builder claim, and policy trust remain separate.
- Collectors use least privilege; network is opt-in.
- Tokens are never persisted and are redacted from logs/errors.
- SECURITY.md defines supported versions and private reporting.
- Third-party CI actions are immutable-pinned and permissions are explicit.

## Reliability and operations

- SQLite writes are atomic and one-writer behavior is documented.
- Backup and restore preserve equivalent trace/report semantics.
- Corrupt or unsupported-newer databases are refused without modification.
- Interrupted ingestion and stale batch metadata have tested recovery.
- Parser, query, batch, and output resources are bounded.
- Errors have stable classes/codes; logs are structured and redacted.
- Product telemetry is disabled by default.
- Upgrade requires documented backup; downgrade safety is explicit.
- Runbooks cover migration failure, corruption, collector failure, invalid evidence, and release-verification failure.

## Verification classes

- Unit: canonicalization, validation, status aggregation, render model.
- Integration: collectors, SQLite transactions, migrations, backup/restore.
- End-to-end: empty directory through complete fixture report.
- Golden: JSON, terminal no-color, Markdown, canonical identities.
- Property: idempotent normalization, evidence ID stability, conflict symmetry.
- Fuzz: YAML/JSON parsers and identity inputs.
- Benchmark: deterministic datasets with raw results and environment.
- Release smoke: packaged artifacts, checksums/signatures, migration, fixture workflow, self-evidence bundle.

## Supply-chain dogfooding

### Before M1 implementation merges

CI and dependency policy begin as soon as relevant code exists.

### M2

The complete fixture workflow and deterministic reports are release-candidate prerequisites.

### v0.1

Each release should provide:

- checksums for every artifact;
- SPDX SBOM bound to exact artifacts;
- provenance bound to exact artifacts and source revision;
- signed artifacts or signed manifest with documented trust assumptions;
- ingestible ALO release evidence bundle;
- reproducibility report where achievable, otherwise explicit blockers and variance.

## Numeric budgets

CPU, memory, latency, DB growth, parser limits, and backup budgets must be approved in the benchmark issue before v0.1. Until then, documentation must not claim “fast,” “lightweight,” or “scalable.”
