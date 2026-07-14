# Canonical Evidence Model

## Objective

Preserve what a source claimed, which canonical identities it refers to, when the claim was observed and valid, how the record was produced, what checks were performed, and where evidence conflicts. The model is an auditable evidence graph, not a truth database.

## Design-level record

| Field | Requirement |
|---|---|
| `evidence_id` | Deterministic identifier derived from schema version and canonical semantic content; excludes ingestion time and storage row IDs. |
| `subject` | Canonical identity reference. |
| `predicate` | Versioned relationship type with defined direction and temporal semantics. |
| `object` | Canonical identity or typed literal reference. |
| `observed_at` | Time the collector observed the source. |
| `valid_from` | Earliest stated or derived validity time. |
| `valid_until` | Exclusive upper bound; null means open-ended, not eternal truth. |
| `source` | Source kind plus immutable source material digest/reference. |
| `source_instance` | Scope for provider-local identifiers such as a workflow-run ID. |
| `content_digest` | Digest of canonical evidence content or exact source material, with purpose stated. |
| `signature_ref` | Optional signature-material reference, never a trust boolean. |
| `verification_status` | `unverified`, `verified`, `failed`, `unsupported`, or `indeterminate`. |
| `confidence` | Controlled qualitative claim such as `asserted` or `derived-exact`; never silently averaged. |
| `record_provenance` | Collector name/version, normalizer version, input digest, and parent evidence IDs. |
| `schema_version` | Canonical evidence schema version. |
| `ingested_at` | Storage event time; excluded from semantic evidence ID. |
| `conflict_of` | Links evidence in a contradiction group. |
| `supersedes` | Directional correction link preserving the prior record. |

## Initial relationship vocabulary

Initial names remain subject to ADR approval, but each accepted predicate must define endpoint types, direction, cardinality expectations, and temporal meaning.

- `repository_has_commit`
- `commit_defines_workflow`
- `workflow_run_uses_definition`
- `workflow_run_uses_commit`
- `workflow_run_claims_production_of`
- `spdx_document_describes`
- `provenance_statement_has_subject`
- `provenance_statement_claims_source`
- `provenance_statement_claims_builder`
- `artifact_has_digest`
- v0.2: `deployment_snapshot_observes_container`
- v0.2: `container_observation_uses_image`

## Initial identity types

### Git repository

Canonical host plus owner/path. For GitHub, strip optional `.git` and equate proven SSH and HTTPS forms. Never equate repositories across hosts. A local path is an observation, not a global identity.

### Git commit

Repository identity plus full object ID and algorithm. An abbreviated object ID is accepted only as input syntax and must resolve uniquely within the source repository.

### Workflow definition

Repository identity, commit identity, and normalized repository-relative workflow path. Content digest is recorded. A path without commit is a mutable alias/observation.

### Workflow run

Source instance plus repository and provider-local run ID, including attempt where applicable.

### Generic artifact or file

Digest algorithm plus normalized digest. Name, path, media type, and tag are observations. A file without a supported digest cannot be globally correlated.

### OCI image

Manifest digest plus algorithm. Tag and platform metadata are observations. Index digest and platform manifest digest are distinct identities.

### SPDX document

Exact document content digest plus supported document namespace. SPDX element IDs remain document-scoped aliases.

### SLSA/in-toto statement

Exact statement digest plus supported statement/predicate version. Subjects are separate artifact identities.

## Equality, aliases, ambiguity, and invalid input

- Strict equality compares canonical type and all required canonical components.
- Aliases are evidence-backed mappings and never redefine strict equality.
- Candidate matches remain ambiguous until exact evidence exists.
- Invalid syntax is rejected before storage.
- Unsupported algorithms produce unsupported/invalid outcomes, not guessed normalization.
- Mutable names such as branches, tags, and paths without commit are time-scoped observations.

## Collision handling

Identity and evidence digests include the algorithm. If different canonical bytes are presented under the same algorithm/digest, ALO records a collision/conflict condition and refuses silent equality.

## Deduplication

Same schema version and same canonical semantic content produce the same evidence ID. Re-ingestion may add a corroborating source observation or batch outcome, but not a duplicate semantic edge.

## Contradiction and supersession

A contradiction is two overlapping, incompatible claims under the same subject/predicate/source scope. Non-overlapping time-varying observations are not automatically conflicts. Supersession is explicit and never deletes history.

## Confidence

Initial values:

- `asserted`: directly claimed by source material.
- `derived-exact`: deterministic transform such as digest equality.
- `unknown`: source cannot support a stronger classification.
- `derived-heuristic`: reserved and disabled by default until separately approved.

Confidence is not a probability.

## Rejected alternatives

- Property graph database first.
- Opaque JSON blobs as the primary semantic model.
- Last-write-wins mutable facts.
- Event log without canonical identity/equality rules.
- Provider URLs as universal identity.
- Database row IDs as domain identity.
