# Adversarial Review

## Review result

The plan was reviewed against the failure modes named in the execution brief and revised before publication. The current backlog remains a local userspace evidence engine through v0.1 and a bounded local deployment-correlation experiment in v0.2.

## Findings and revisions

| Risk | Finding | Revision applied |
|---|---|---|
| Accidental GUAC reimplementation | A generic graph platform or broad package-security knowledge base would overlap GUAC and exceed one-developer scope. | ALO stores only evidence needed for its trace/verify use case, uses SQLite relational projections, and treats ecosystem interoperability as an adapter concern. |
| Premature runtime technology | eBPF, WASI, OpenTelemetry, process/socket/syscall identities were present in the long-term proposal. | Removed from M0–M4 implementation issues; retained only behind explicit roadmap entry criteria. |
| Premature Kubernetes/SaaS | Neither is needed for the first target user or complete use case. | Explicit first-year non-goals; no labels, milestones, or issues created for them. |
| Technology-driven scope | Standards could become the product rather than adapters. | Durable `Identity`, `Evidence`, time, trust, and conflict semantics are separated from GitHub/SPDX/SLSA/OCI adapters. |
| Hidden dependency cycles | Storage, schema, fixtures, parsers, and output could have circular prerequisites. | Every dependency points to an earlier issue; schema/identity precede storage, fixtures precede parsers, CLI contracts precede commands. |
| Unverifiable milestones | “Architecture complete” or “production ready” can be subjective. | Each milestone has an entry condition, exit condition, executable demonstration, and exclusions. |
| Unbounded parser inputs | SPDX, provenance, workflow YAML, paths, and future archives are untrusted. | Threat model and parser issues require byte/depth/count limits, cancellation, no code execution, and safe path handling. |
| Schema evolution gaps | Append-only evidence still requires reproducible migration and compatibility behavior. | Checksummed migrations, transactional upgrades, backup-before-upgrade, fixture migration tests, and rollback boundaries are explicit. |
| Trust conflation | A valid signature could be mistaken for a trusted issuer or true claim. | Verification status, source trust, confidence, and evidence provenance are independent fields and query/report dimensions. |
| False identity links | Over-aggressive aliasing would make traces persuasive but wrong. | Canonical equality is strict; aliases require evidence; ambiguity is retained; the initial research objective prioritizes zero false links. |
| Release work deferred too late | Dogfooding could become a final packaging task. | Production baseline is approved in M0, release metadata is designed in CI/dependency work, and dogfooding is a dedicated M3 issue. |
| Issue overload | A five-year backlog would decay. | Limited to 32 issues through local deployment correlation; later runtime research remains in `ROADMAP.md`. |
| Label duplication | Milestones, status, and areas can encode the same thing. | Restrained 24-label taxonomy with exact application rules; milestones alone encode delivery phase. |
| Unsafe bootstrap updates | Updating existing issue bodies could erase owner notes. | Normal reruns skip managed issues. `--update-existing` updates only a delimited managed block and preserves text outside it and all comments. |
| Script non-idempotency | Titles are mutable and insufficient identifiers. | Stable body markers identify issues; labels use exact names; milestones use exact titles; dependencies use captured issue numbers. |
| GitHub inspection gaps | The available connector did not expose authoritative enumeration for every labels/milestones/releases endpoint. | No absence claim is made for those categories. The script performs authenticated read/reconcile at execution time and defaults to dry-run. |

## Remaining bounded assumptions

1. Go is the first-year implementation language unless the owner records a contrary ADR before the first application-code issue.
2. Linux amd64 is the primary supported release target for v0.1; broader platform guarantees require owner approval and CI evidence.
3. Remote GitHub workflow-run ingestion is opt-in and may use an existing `gh` authentication context; no embedded token store is planned.
4. v0.2 correlation supports OCI metadata and one-shot local Docker snapshots only; it does not claim observed runtime behavior.
5. A signature proves cryptographic validity, not issuer authorization; the initial trust policy remains explicit and local.
