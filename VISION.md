# Artifact Lineage Observatory — Vision

ALO is an open-source, local-first evidence engine that connects software source, build processes, release artifacts, deployment observations, and—only in later phases—observed runtime behavior. It helps a developer or release engineer answer: what is this artifact or deployment, where did it come from, which claims support that conclusion, what was verified, when was each relationship valid, and where does evidence disagree or remain incomplete?

## Durable problem

Software lifecycle evidence is fragmented across source control, CI systems, SBOMs, provenance statements, artifact stores, deployment engines, and telemetry systems. The durable value is not owning those systems. It is converting their claims into a conservative, queryable, time-aware chain of evidence that preserves source, trust status, uncertainty, and conflict.

## Durable domain model

ALO's long-lived core is:

- canonical identities;
- immutable evidence records and supporting sources;
- typed relationships;
- observation time and validity time;
- verification status;
- ambiguity, contradiction, and supersession;
- deterministic traversal and reporting.

## Replaceable adapters

Git, GitHub Actions, SPDX, SLSA/in-toto, OCI, Docker, future OpenTelemetry, future eBPF, and future ML registries are adapters. They may change without changing the product thesis.

## Product principles

1. **Local-first:** useful on one developer machine with SQLite and no cloud account.
2. **Developer-first:** command-line workflows and inspectable evidence precede dashboards.
3. **Conservative correlation:** unresolved identity is safer than a false link.
4. **Evidence over verdicts:** every conclusion points to supporting records, source, time, and verification status.
5. **Integration over reinvention:** ALO does not rebuild vulnerability databases, registries, CI systems, telemetry backends, or SIEMs.
6. **Production discipline from the first release:** bounded parsers, migrations, deterministic output, recovery, tests, and release integrity.
7. **Adapter independence:** standards and platforms are replaceable at the boundary.

## Central question

> Can we construct a trustworthy, queryable, and temporally accurate chain of evidence from source code to deployment—and eventually observed runtime behavior—without requiring a cloud platform or privileged runtime sensor?

“Trustworthy” means that ALO reports origin, verification process, trust context, and limitations. It does not mean that every ingested claim is true.
