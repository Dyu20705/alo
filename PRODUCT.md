# ALO Product Contract

## Product definition

Artifact Lineage Observatory (ALO) is an open-source, local-first command-line evidence engine for developers and release engineers. It ingests bounded lifecycle evidence from a local Git repository, GitHub Actions metadata, SPDX SBOMs, SLSA/in-toto provenance, and later local OCI/Docker deployment snapshots; normalizes that material into a versioned canonical evidence model stored in SQLite; and produces deterministic traces, verification status, conflict annotations, and human- or machine-readable reports.

## First target user

A developer or release engineer responsible for one repository who needs to investigate or verify one release on a laptop or workstation. This user should not need Kubernetes, a cloud account, a graph database, or a hosted ALO service.

## First complete use case

Given a local repository and an offline fixture or export containing workflow-run metadata, an SPDX SBOM, and SLSA provenance for one release, the user can:

1. initialize a local ALO database;
2. ingest repository, commit, workflow definition/run, SBOM, and provenance evidence;
3. rerun ingestion without duplicate semantic records;
4. trace an artifact digest back to workflow and source commit;
5. see which checks were verified, failed, unsupported, or indeterminate;
6. see unresolved identity and contradictory evidence;
7. produce deterministic JSON, terminal, and Markdown reports.

## Staged CLI contract

### M1

```text
alo init [--db PATH]
alo ingest git PATH [--commit REF]
alo ingest workflow PATH
alo trace IDENTITY [--direction both] [--max-depth N] [--format json]
```

### M2

```text
alo ingest sbom FILE
alo ingest provenance FILE
alo ingest workflow-run SOURCE
alo verify IDENTITY [--format json|text]
alo report IDENTITY [--format json|text|markdown]
```

### M3 operations

```text
alo db check
alo db backup DESTINATION
alo db restore BACKUP --to PATH
alo version --json
```

### M4

```text
alo ingest oci SOURCE
alo ingest docker-snapshot [OPTIONS]
alo trace IDENTITY --at TIMESTAMP
alo diff SNAPSHOT_A SNAPSHOT_B
```

Exact spelling remains subject to owner approval before implementation, but scope and behavior are binding.

## v0.1 success criteria

- The complete fixture workflow runs offline from a clean checkout.
- Identical ingestion is idempotent.
- Canonical JSON is deterministic for identical database state and options.
- Every returned trace edge identifies its supporting evidence and source.
- Verification failure and unsupported checks are distinguishable.
- Conflicts remain stored and visible.
- Migration, backup, restore, and corruption refusal are tested.
- Tagged release artifacts have checksums, SBOM, provenance, signatures, and an ingestible ALO evidence bundle.

## Product boundary

ALO is not an authority that decides whether software is safe. It reports evidence and verification outcomes under an explicit trust context. Organizational risk acceptance and broad policy enforcement remain outside the v0.1 core.
