# System Context

## Actors

- **Developer or release engineer:** runs ALO locally, supplies explicit inputs, and reviews traces and verification status.
- **Repository owner:** chooses trust policy, supported platforms, release cadence, and unresolved product decisions.
- **Collector adapter:** reads one source and emits canonical candidate evidence through a bounded interface.
- **Verifier:** performs a named check over exact bytes or claims and emits a verification record.

## Architecture decision table

| Decision | Approved direction | Boundary or trigger |
|---|---|---|
| Primary user | One developer or release engineer responsible for one repository/release. | Broader team workflows require external-user evidence after v0.1. |
| Primary use case | Ingest local release evidence, trace an artifact to source/build, verify named checks, expose conflicts, and report deterministically. | No safety/compliance verdict. |
| Initial deployment | On-demand CLI plus one user-owned SQLite database; no required daemon. | A daemon requires a measured continuous-ingestion need. |
| Initial platform | Linux amd64 is the primary release target; Windows/macOS are best-effort. | Owner approves additional guaranteed targets only with CI and release-smoke evidence. |
| Main language | Go for first-year application code. | A contrary choice requires a pre-implementation ADR with operational and ecosystem evidence. |
| Storage | SQLite relational schema with append-oriented evidence and derived indexes. | PostgreSQL only after measured concurrency/server-mode demand; no graph database in v0.1. |
| Identity strategy | Strict type-specific canonical identities; mutable names are observations; aliases require evidence. | Ambiguous candidates are retained, never silently linked. |
| Schema versioning | Explicit model/output versions; additive compatible changes within a major version; checked migrations for storage. | Unknown newer incompatible versions are refused without database modification. |
| Temporal model | Separate `observed_at` from half-open `[valid_from, valid_until)`; null upper bound means open-ended. | Collection time must never be substituted silently for claimed event time. |
| Trust/confidence | Source trust, cryptographic verification, claim confidence, and evidence provenance are separate. | A valid signature is not an authorization or truth verdict. |
| Collector boundary | Bounded adapters read explicit inputs and emit candidate evidence; core validates and commits. | Collectors do not write the database, execute repository code, or define global identity equality. |
| Query boundary | Bounded traversal over canonical identities/evidence with depth/result/time limits and explicit truncation. | No custom query language in the first year. |
| Policy boundary | Core exposes facts, verification outcomes, and conflicts. | Generic policy packs/enforcement are deferred until stable evidence/query contracts and user demand. |
| Cryptographic verification | Verify exact digests/signatures/statements using named verifier and trust context; persist outcome as evidence. | No embedded CA, key management service, or universal signer trust list. |
| Local privacy | Telemetry disabled by default; network collectors opt-in; tokens are ephemeral and redacted; no secrets/environment capture. | Any remote transmission requires explicit command/config and documented fields. |
| Compatibility | Version public schemas/outputs; keep fixtures for supported historical versions; adapters declare accepted upstream versions. | Compatibility is not claimed for untested provider/standard versions. |
| Upgrade/migration | Backup before upgrade, transactional checksummed forward migrations, post-migration integrity check, documented rollback boundary. | Automatic destructive downgrade is not supported. |

## v0.1 boundary

```text
Local Git repository ----\
Workflow definitions -----\
SPDX document ------------- > collectors -> validation/canonicalization -> transaction -> SQLite
SLSA provenance ----------/
Workflow-run fixture/API -/

SQLite -> bounded trace/query -> result model -> JSON / terminal / Markdown
Exact local bytes/claims -> verifier -> verification evidence -> SQLite
```

ALO does not execute repository code, workflows, actions, packages, or artifacts. Network access is opt-in and limited to explicit remote collectors.

## Durable layers

1. Identity and evidence model.
2. Validation and normalization.
3. Transactional append-oriented storage.
4. Bounded trace and temporal query semantics.
5. Verification records.
6. Output renderers.

## Replaceable adapter layers

- Git repository and commit.
- GitHub Actions workflow definition and workflow run.
- SPDX document.
- SLSA/in-toto statement.
- OCI image metadata in v0.2.
- Docker snapshot in v0.2.
- Future adapters only after roadmap entry criteria.

## Why ALO is not an adjacent product

- **Not a repository scanner:** it records evidence and relationships instead of issuing a score.
- **Not an SBOM viewer:** SPDX is one adapter and no vulnerability/license database is built.
- **Not an observability backend:** v0.1 and v0.2 store no application telemetry.
- **Not a SIEM:** no alert ingestion, SOC workflow, or event correlation at SIEM scale.
- **Not a GUAC implementation:** local-first temporal source-to-deployment correlation is the differentiated path; future interoperability is preferred.
- **Not an eBPF or WASM experiment:** neither belongs to first-year implementation.

## Initial deployment model

One CLI process and one SQLite database owned by one user. No daemon is required. Telemetry is disabled by default. Network collectors are opt-in.

## Initial platform decision

The conservative primary support target is Linux amd64 on a developer workstation. Windows and macOS remain best-effort until the owner approves a tested release matrix. Core userspace design must avoid unnecessary Linux-specific assumptions.
