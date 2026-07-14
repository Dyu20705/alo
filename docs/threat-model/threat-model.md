# ALO v0.1 Threat Model

## Assets

- Integrity and availability of the evidence database.
- Correct identity correlation and temporal relationships.
- Confidentiality of GitHub credentials, local paths, and sensitive source fields.
- Integrity of migrations, fixtures, verification results, and ALO releases.
- Operator ability to distinguish claim, verification, trust, conflict, and uncertainty.

## Trust boundaries

1. Untrusted repository and Git metadata → Git collector.
2. Untrusted YAML/JSON/SBOM/provenance → bounded parsers.
3. Remote GitHub API → network collector and credential boundary.
4. Collector output → canonical validation.
5. Canonical batch → SQLite transaction.
6. Database → query and renderer.
7. Release CI/signing identity → release consumer.

## Primary threats and controls

| Threat | Required control |
|---|---|
| Path traversal or symlink escape | Repository-relative validation; no source-path writes; archive extraction disabled by default. |
| YAML/JSON bombs | Explicit byte, depth, alias, element, relation, and string limits. |
| Decompression bomb | No archive/layer extraction in v0.1. |
| Repository code execution | Never run hooks, workflows, actions, builds, binaries, or package managers. |
| Forged evidence | Preserve source claim; separate parsing, verification, trust, and confidence. |
| Signed statement from untrusted identity | Report signature validity and policy trust separately. |
| Identity confusion | Source scopes, algorithm-qualified digests, conservative aliases, no guessed links. |
| Digest downgrade or collision | Record algorithm, reject unsupported policy, preserve collision/conflict. |
| Partial write | Atomic transactions and fault-injection tests. |
| Migration corruption | Immutable checksummed migrations and backup-before-upgrade. |
| Secret leakage | Environment-only credentials, redaction, no token/header persistence. |
| Sensitive metadata leakage | Local-only default, no telemetry, path/author/environment redaction. |
| Resource exhaustion | Parser/query/batch/time/result limits and measured budgets. |
| Output injection | Escape terminal and Markdown control content; structured JSON encoding. |
| Tampered release | Checksums, signatures, SBOM, provenance, immutable action pins, independent verification. |

## Valid-but-misleading evidence example

A correctly signed provenance statement claims artifact D was built from commit C. ALO may verify the signature and subject digest while reporting builder trust as indeterminate if the signer or builder is not accepted by the user's trust context. “Signature valid” must never become “claim true.”

## Least privilege

- Local collectors read only explicit paths.
- GitHub collector requests minimum metadata permission for one explicit run/repository.
- Docker v0.2 collector uses read endpoints only; Docker socket access remains a residual risk.
- SQLite files use owner-only permissions where supported.

## Residual risks

- A compromised local account can alter inputs or database.
- Self-reported provenance cannot prove an honest build environment by itself.
- Source/event/observation clocks may be wrong.
- Unsupported standard fields may contain relevant facts not represented by the core.
