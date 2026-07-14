# Collector Boundaries

## Collector responsibility

A collector reads one explicit source, enforces source-specific limits, records source material digest and source instance, and emits candidate identities/evidence through the canonical validation interface.

A collector must not:

- write directly to storage;
- execute repository content, workflows, actions, packages, or artifacts;
- decide organizational trust policy;
- resolve contradictions silently;
- perform unbounded network enumeration;
- hide parser truncation or unsupported fields;
- treat successful parsing as verification.

## Pipeline

```text
source selection
-> bounded read or fetch
-> source digest and source-instance metadata
-> parser-specific validation
-> canonical identity/evidence normalization
-> cross-record invariant validation
-> atomic storage transaction
-> structured ingestion result
```

## Initial adapters

### Git

Local-only. Reads repository metadata and selected commit graph. Never runs hooks. Remote URLs are aliases subject to conservative normalization.

### GitHub Actions workflow definition

Reads only `.github/workflows` files from an explicit repository/commit. Enforces byte, depth, alias, scalar, job, and step limits. Does not evaluate expressions or actions.

### SPDX

Reads a documented JSON subset. Does not dereference external references. Document-scoped IDs remain scoped.

### SLSA/in-toto

Reads a documented statement/predicate subset. Builder and source claims remain assertions until separately verified.

### GitHub workflow run

Opt-in network collector for one explicit repository/run. Credentials are never persisted. Pagination, retries, and rate behavior are bounded.

### OCI and Docker in v0.2

OCI reads digest-addressed metadata without layer execution/extraction. Docker performs one-shot read-only snapshot collection and excludes secrets/environment by default.

## Query boundary

Queries operate only over persisted canonical data. They never fetch missing evidence implicitly. Results are bounded, deterministic, and include supporting evidence IDs, source, temporal scope, verification, conflict, ambiguity, and truncation.

## Policy boundary

v0.1 has no general policy engine. A command may aggregate required verification checks under explicit configuration. Organizational allow/deny policy is future work.

## Cryptographic verification boundary

Verification consumes exact bytes or claims and a stated trust context, then emits a verification record. Signature validity, signer identity, builder claim, and policy trust are separate facts.
