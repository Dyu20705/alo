# ALO Planning Completion Report
## 1. Repository state inspected
On 2026-07-11, `Dyu20705/alo` was public with default branch `main`. The observed history contained one commit (`56ee6b3fe0a341c42291287756b561ff2bee5701`, `first commit`) and one committed file, `README`, containing only `# Artifact Lineage Observatory`. Repository searches returned no open/closed issues and no pull requests. No application code, tests, workflows, configuration, or planning documents were present in the observed tree. Labels, milestones, releases, tags, and all branch refs could not be authoritatively enumerated through the available connector and were not guessed.
## 2. Final product definition
Artifact Lineage Observatory (ALO) is an open-source, local-first command-line evidence engine for developers and release engineers. It ingests bounded lifecycle evidence from source, CI/build metadata, SBOMs, provenance, and later local deployment snapshots; normalizes it into a versioned canonical evidence model in SQLite; and produces deterministic traces, verification outcomes, conflict annotations, and reports without requiring Kubernetes, cloud infrastructure, or a hosted service.
## 3. Durable value
ALO's durable value is the ability to answer what artifact or deployment exists, where it came from, which evidence supports the link, what was verified, when relationships were valid, and where sources disagree. Its durable assets are identity rules, temporal evidence semantics, conflict/trust representation, fixtures, compatibility history, and measured integration knowledge—not eBPF, WASI, SPDX, OpenTelemetry, or any other replaceable adapter.
## 4. First target user and complete use case
The first user is one developer or release engineer investigating one release from one repository on one workstation. The complete v0.1 workflow ingests a local Git repository, workflow definition/run metadata, SPDX, and SLSA/in-toto provenance; persists idempotently in SQLite; traces an artifact digest to workflow and commit; exposes failed/unsupported/indeterminate verification and conflicting evidence; and emits deterministic JSON, terminal, and Markdown output.
## 5. Major architecture decisions
- Go is the presumed first-year implementation language; changing it requires a pre-implementation ADR.
- SQLite is the only required v0.1 store; PostgreSQL remains a measured future adapter.
- The core is a canonical identity/evidence model with separate observation and validity time.
- Source trust, cryptographic verification, confidence, and record provenance are independent.
- Collectors emit bounded candidate evidence and cannot define equality or write storage directly.
- Queries are bounded traversals with explicit truncation; no custom query language.
- Telemetry is disabled by default; network collectors are opt-in; tokens are not persisted.
- Forward migrations are transactional and checksummed; unknown newer schemas are refused without modification.
## 6. Explicit first-year non-goals
eBPF sensors, WASI/WASM plugins, Kubernetes, multi-tenant SaaS, distributed graph databases, web dashboards, custom query languages, vulnerability databases, telemetry backends, AI analysis/autofix, ML lineage implementation, generic policy enforcement, and broad SIEM/observability behavior.
## 7. Planning documents created
`VISION.md`, `PRODUCT.md`, `NON_GOALS.md`, `ROADMAP.md`, four architecture/collector/storage documents, a threat model, research plan, production baseline, GitHub plan, three ADRs, repository inspection, adversarial review, and script validation report.
## 8. Milestones and outcomes
- **M0 — Product, Trust, and Architecture Baseline** — A design review can trace a sample claim through identity, evidence, trust, time, and output semantics without application code.
- **M1 — Local Evidence Core** — Initialize a clean database, ingest the fixture repository twice, and trace commit/workflow evidence without duplicates.
- **M2 — Verifiable Ingestion and Trace Queries** — Ingest the complete fixture bundle, trace an artifact to source, verify it, and emit terminal, JSON, and Markdown reports.
- **M3 — Production-Ready v0.1** — Install a packaged v0.1 candidate, verify its evidence bundle, run the fixture workflow, back up/restore, and test one migration rollback boundary.
- **M4 — Deployment Correlation v0.2** — Trace a Docker container snapshot to image digest, provenance, workflow run, and commit, then compare before/after snapshots.

## 9. Label taxonomy
Twenty-four labels: seven `type:*`, nine `area:*`, three `priority:*`, three `risk:*`, and two exceptional `status:*` labels. Every issue has exactly one type, one or two areas, and exactly one priority; risk/status labels are conditional rather than substitutes for milestones.
## 10. Issue count by milestone
- M0 — Product, Trust, and Architecture Baseline: 7 issues.
- M1 — Local Evidence Core: 7 issues.
- M2 — Verifiable Ingestion and Trace Queries: 7 issues.
- M3 — Production-Ready v0.1: 7 issues.
- M4 — Deployment Correlation v0.2: 4 issues.

## 11. Ordered issue index
| Order | Title | Milestone | Labels | Dependencies |
|---:|---|---|---|---|
| 1 | Define the v0.1 product contract and first-year non-goals | M0 | `type:decision, area:product, priority:p0` | `None` |
| 2 | Define the v0.1 threat model and trust boundaries | M0 | `type:security, area:verification, priority:p0, risk:security` | `product-contract` |
| 3 | Specify canonical evidence invariants and initial relationship vocabulary | M0 | `type:decision, area:model, priority:p0, risk:data-integrity` | `product-contract, threat-model` |
| 4 | Define v0.1 identity canonicalization, equality, aliases, and ambiguity | M0 | `type:decision, area:model, priority:p0, risk:data-integrity, risk:compatibility` | `evidence-invariants` |
| 5 | Define schema versioning and compatibility policy | M0 | `type:decision, area:model, area:storage, priority:p0, risk:compatibility` | `evidence-invariants, identity-rules` |
| 6 | Specify staged CLI, deterministic output, and structured error contracts | M0 | `type:decision, area:cli, priority:p0, risk:compatibility` | `product-contract, evidence-invariants, identity-rules, schema-compatibility` |
| 7 | Approve the measurable production baseline and release-integrity plan | M0 | `type:decision, area:release, priority:p0, risk:security` | `product-contract, threat-model, schema-compatibility` |
| 8 | Design the SQLite relational mapping and append-oriented evidence store | M1 | `type:decision, area:storage, area:model, priority:p0, risk:data-integrity` | `evidence-invariants, identity-rules, schema-compatibility` |
| 9 | Implement database initialization and checksummed migration framework | M1 | `type:feature, area:storage, area:cli, priority:p0, risk:data-integrity, risk:compatibility` | `cli-contract, sqlite-mapping` |
| 10 | Implement atomic evidence writes, idempotent ingestion, and interruption recovery | M1 | `type:feature, area:storage, area:ingestion, priority:p0, risk:data-integrity` | `evidence-invariants, sqlite-mapping, migration-framework` |
| 11 | Create the versioned evidence fixture and golden-output corpus | M1 | `type:quality, area:model, area:research, priority:p0` | `evidence-invariants, identity-rules, schema-compatibility` |
| 12 | Implement local Git repository and commit evidence ingestion | M1 | `type:feature, area:ingestion, priority:p0, risk:security` | `identity-rules, migration-framework, transaction-idempotency, fixture-corpus` |
| 13 | Implement GitHub Actions workflow-definition ingestion | M1 | `type:feature, area:ingestion, priority:p1, risk:security, risk:compatibility` | `identity-rules, migration-framework, transaction-idempotency, fixture-corpus` |
| 14 | Implement bounded trace traversal and deterministic JSON output | M1 | `type:feature, area:cli, area:model, priority:p0, risk:data-integrity` | `evidence-invariants, identity-rules, cli-contract, sqlite-mapping, migration-framework, transaction-idempotency, fixture-corpus` |
| 15 | Implement bounded SPDX SBOM document ingestion | M2 | `type:feature, area:ingestion, priority:p0, risk:security, risk:compatibility` | `identity-rules, schema-compatibility, migration-framework, transaction-idempotency, fixture-corpus` |
| 16 | Implement bounded SLSA/in-toto provenance statement ingestion | M2 | `type:feature, area:ingestion, area:verification, priority:p0, risk:security, risk:compatibility` | `identity-rules, schema-compatibility, migration-framework, transaction-idempotency, fixture-corpus` |
| 17 | Implement opt-in GitHub Actions workflow-run metadata ingestion | M2 | `type:feature, area:ingestion, priority:p1, risk:security` | `identity-rules, schema-compatibility, migration-framework, transaction-idempotency, fixture-corpus, workflow-definition-ingestion` |
| 18 | Implement digest and provenance verification status evaluation | M2 | `type:security, area:verification, priority:p0, risk:security, risk:data-integrity` | `evidence-invariants, identity-rules, schema-compatibility, transaction-idempotency, spdx-ingestion, slsa-ingestion` |
| 19 | Implement evidence conflict, ambiguity, and supersession behavior | M2 | `type:feature, area:model, area:storage, priority:p0, risk:data-integrity` | `evidence-invariants, identity-rules, schema-compatibility, transaction-idempotency, fixture-corpus` |
| 20 | Implement deterministic terminal and Markdown evidence reports | M2 | `type:feature, area:cli, priority:p1, risk:compatibility` | `cli-contract, trace-json` |
| 21 | Deliver the complete fixture release ingest–trace–verify workflow | M2 | `type:quality, area:cli, area:verification, priority:p0` | `git-ingestion, workflow-definition-ingestion, trace-json, spdx-ingestion, slsa-ingestion, workflow-run-ingestion, verification-status, conflict-supersession, human-markdown-report` |
| 22 | Publish security policy, vulnerability reporting, and secret-handling rules | M3 | `type:security, area:release, priority:p0, risk:security` | `threat-model, production-baseline` |
| 23 | Establish CI quality gates and dependency policy | M3 | `type:quality, area:release, priority:p0, risk:security, risk:compatibility` | `production-baseline, fixture-corpus, git-ingestion, workflow-definition-ingestion, spdx-ingestion, slsa-ingestion, workflow-run-ingestion, verification-status, conflict-supersession, e2e-release-fixture` |
| 24 | Add parser fuzzing and identity/property test suites | M3 | `type:quality, area:ingestion, area:model, priority:p0, risk:security, risk:data-integrity` | `identity-rules, fixture-corpus, workflow-definition-ingestion, spdx-ingestion, slsa-ingestion, conflict-supersession` |
| 25 | Establish reproducible performance benchmarks and resource budgets | M3 | `type:research, area:research, area:storage, priority:p1` | `identity-rules, fixture-corpus, spdx-ingestion, slsa-ingestion, conflict-supersession, trace-json` |
| 26 | Implement backup, restore, integrity checking, and corruption recovery runbook | M3 | `type:operations, area:storage, priority:p0, risk:data-integrity` | `sqlite-mapping, migration-framework, transaction-idempotency, fixture-corpus, trace-json, e2e-release-fixture` |
| 27 | Produce checksums, SBOM, provenance, signatures, and an ALO release evidence bundle | M3 | `type:operations, area:release, area:verification, priority:p0, risk:security` | `threat-model, production-baseline, migration-framework, transaction-idempotency` |
| 28 | Document and test upgrade, rollback, and end-to-end v0.1 release verification | M3 | `type:operations, area:release, area:storage, priority:p0, risk:compatibility` | `schema-compatibility, e2e-release-fixture, ci-dependency-gates, backup-recovery, release-dogfooding` |
| 29 | Implement OCI image digest identity and local metadata ingestion | M4 | `type:feature, area:deployment, area:ingestion, priority:p0, risk:data-integrity` | `identity-rules, schema-compatibility, sqlite-mapping, migration-framework, transaction-idempotency, fixture-corpus, verification-status` |
| 30 | Implement local Docker deployment snapshot ingestion | M4 | `type:feature, area:deployment, area:ingestion, priority:p0, risk:security` | `oci-adapter, fixture-corpus, migration-framework, transaction-idempotency` |
| 31 | Implement temporal deployment correlation and before/after diff queries | M4 | `type:feature, area:deployment, area:cli, priority:p0, risk:data-integrity` | `evidence-invariants, identity-rules, schema-compatibility, trace-json, conflict-supersession, oci-adapter, docker-snapshots` |
| 32 | Publish the v0.2 deployment-correlation benchmark and limitations report | M4 | `type:research, area:research, area:deployment, priority:p1` | `bench-resource-budgets, upgrade-release-verification, oci-adapter, docker-snapshots, deployment-trace-diff` |

## 12. Script path
`scripts/bootstrap-github.sh`
## 13. Script validation
`bash -n`, help, empty-state dry-run, fully-existing idempotent dry-run, malformed-repository rejection, read-failure fail-closed behavior, dependency ordering, label discipline, and absence of external `jq` were validated. ShellCheck was unavailable. Apply mode was not executed.
## 14. Remaining owner decisions
1. Approve Linux amd64 as the only guaranteed initial release target or fund a broader tested matrix.
2. Confirm the staged CLI spelling before implementation begins.
3. Choose the initial trusted-signature policy and supported verification tools before M2 verification implementation.
4. Approve numeric parser/resource/benchmark budgets using measurements before v0.1 claims.
5. Decide whether remote workflow-run ingestion relies on the user's existing `gh` session or a separate ephemeral credential interface.
## 15. Mutation declaration
No ALO application source code, Go module, package scaffold, empty architecture directory, GitHub object, branch, commit, pull request, release, or remote repository file was created or modified. The bootstrap script was generated and validated locally but never run with `--apply`.
