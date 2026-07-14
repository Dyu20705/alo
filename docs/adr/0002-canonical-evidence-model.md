# ADR 0002: Canonical Evidence Model

## Status

Proposed for owner approval.

## Decision

Use a versioned, append-oriented evidence record connecting canonical subject and object identities with a typed predicate, observation and validity time, source/source instance, deterministic digest/ID, verification status, qualitative confidence, record provenance, and explicit conflict/supersession links.

## Rationale

The model preserves both lifecycle relationships and why ALO believes each relationship exists. It supports deterministic deduplication, time-aware queries, contradictory sources, adapter replacement, and export independent of SQLite row IDs.

## Rejected alternatives

- Opaque adapter JSON as the primary model.
- Last-write-wins truth table.
- Mutable graph edges without history.
- Provider URLs as universal identity.
- Probability-like confidence without calibration.

## Consequences

Collectors map to a small core vocabulary and report unsupported semantics. Storage/query code preserves original evidence.
