# ALO Roadmap

## M0 — Product, Trust, and Architecture Baseline

Freeze the product contract, canonical evidence and identity semantics, threat model, compatibility policy, CLI contract, and measurable production baseline. No application implementation belongs here.

## M1 — Local Evidence Core

Implement SQLite lifecycle, atomic/idempotent evidence storage, stable fixtures, local Git and GitHub Actions workflow-definition ingestion, and bounded trace queries with deterministic JSON.

## M2 — Verifiable Ingestion and Trace Queries

Add bounded SPDX, SLSA/in-toto, and opt-in GitHub workflow-run ingestion; verification status; conflict/supersession behavior; terminal/Markdown reporting; and the complete offline fixture workflow.

## M3 — Production-Ready v0.1

Add security and dependency policy, CI gates, fuzz/property testing, reproducible benchmarks, backup/restore and corruption handling, release integrity dogfooding, and upgrade/rollback smoke verification.

## M4 — Deployment Correlation v0.2

Add OCI digest metadata, one-shot local Docker snapshots, temporal correlation/diff queries, and a reproducible source-to-deployment benchmark. This milestone still makes no observed-runtime claim.

## Later entry criteria

### Runtime evidence research baseline

May begin only when:

- v0.2 false-link rate is measured and acceptable on the reference corpus;
- temporal query semantics are stable;
- collector permissions and privacy model have passed review;
- storage benchmarks show headroom for sampled runtime evidence;
- one narrow research hypothesis demonstrates why runtime data is required.

The first runtime work should use an offline adapter or replayable dataset. A privileged live eBPF sensor is not the first step.

### OpenTelemetry adapter

May begin only when a concrete resource-identity mapping can connect service/deployment/image evidence without turning ALO into a telemetry backend. ALO should retain correlation evidence and references, not full traces, logs, and metrics.

### eBPF sensor

May begin only after a replayable userspace runtime-evidence format, Linux threat model, privacy controls, event-loss semantics, and measured overhead target exist.

### WASI plugin runtime

May begin only after at least three independent collector implementations demonstrate a stable extension need that cannot be met safely by an out-of-process adapter protocol.

### PostgreSQL server mode

May begin when a real adopter or measured multi-process workload exceeds SQLite's documented limits.

### ML lineage

May begin after source/build/artifact/deployment identities are stable and a concrete model-serving use case requires dataset/model/training identities.

### GUAC interoperability

Prefer import/export and identity mapping over reimplementation. Begin only after ALO's source-to-deployment differentiation is demonstrated.
