# ALO Research Plan

ALO research claims require a pre-stated hypothesis, ground truth, baseline, raw results, environment details, and explicit limitations. Engineering demonstrations are not automatically research evidence.

## RQ1 — Cross-system identity resolution

**Question:** How accurately can ALO correlate identities across source, workflow, artifact, SBOM, provenance, and later deployment sources?

**Hypothesis:** Conservative algorithm-qualified and source-scoped rules achieve zero false links on the reference corpus while resolving most exact source/build/artifact links.

- **Independent variables:** normalization strategy; fields available; alias evidence present/absent; source adapter combination.
- **Dependent variables:** precision, recall, false-link rate, unresolved rate, ambiguous rate.
- **Metrics:** true/false links against a committed ground-truth mapping; per-identity-type confusion matrix.
- **Baselines:** raw string equality; provider-URL equality; digest-only equality without source scope.
- **Dataset/fixtures:** versioned Git/workflow/SPDX/SLSA corpus with exact expected mappings; OCI/Docker extension in M4.
- **Threats to validity:** synthetic corpus; GitHub bias; limited hash algorithms; fixtures authored by implementer; insufficient malformed cases.
- **Reproducibility:** committed corpus/generator, hashes, seeds, expected mapping, command line, ALO version, environment, and raw machine-readable results.
- **Earliest evaluation:** M1 partial; M2 complete source/build/artifact evaluation; M4 deployment extension.

## RQ2 — Declared versus observed state

**Question:** Can later observed evidence identify meaningful divergence from declared build/deployment state without overstating causality?

The full runtime question requires runtime evidence and is not a first-year implementation issue. M4 evaluates only a deployment-snapshot proxy.

**Near-term hypothesis:** Digest-based point-in-time Docker snapshots detect declared deployment/image changes more accurately than tag-only comparison.

- **Independent variables:** tag movement; digest availability; snapshot interval; missing metadata; provenance completeness.
- **Dependent variables:** detected change, false change, missed change, unresolved correlation.
- **Metrics:** precision/recall of image-change detection and correlation coverage against a scripted ground-truth timeline.
- **Baselines:** manual `docker inspect` comparison; tag-only comparison; latest-snapshot-only state.
- **Dataset/fixtures:** replayable local Docker scenarios with fixed image digests, moved tags, restarts, and missing metadata; no production telemetry.
- **Threats to validity:** Docker-only scope; controlled local timing; snapshot loss; no process-behavior observation; synthetic deployments.
- **Reproducibility:** versioned scenario definitions, image digests, snapshot timestamps, engine version, commands, and raw outputs.
- **Earliest evaluation:** M4 proxy. Full declared-versus-runtime behavior evaluation is roadmap-only after a replayable runtime adapter exists.

## RQ3 — Conflicting and incomplete evidence

**Question:** Which representation best preserves uncertainty when lifecycle sources disagree or omit required fields?

**Hypothesis:** Explicit conflict and ambiguity representation reduces false certainty compared with last-write-wins or silent omission.

- **Independent variables:** conflict policy; missing fields; temporal overlap; source trust; supersession presence.
- **Dependent variables:** false resolved conclusions, unresolved rate, preserved contradictory claims, query explanation completeness.
- **Metrics:** decision outcome against fixture ground truth; count of hidden/dropped claims; percentage of conclusions with supporting/conflicting evidence.
- **Baselines:** last-write-wins; first-write-wins; drop-conflicts; reject-entire-batch.
- **Dataset/fixtures:** duplicate, contradiction, supersession, missing-digest, invalid-signature, and time-varying cases.
- **Threats to validity:** hand-designed conflicts may not represent ecosystem failures; subjective expected outcomes; small source diversity.
- **Reproducibility:** versioned cases, expected contradiction groups, fixed temporal data, raw result JSON, and adjudication notes.
- **Earliest evaluation:** M2.

## RQ4 — Temporal evidence graphs

**Question:** Do separate observation and validity times improve point-in-time lineage accuracy?

**Hypothesis:** Separate observation time and half-open validity intervals correctly answer point-in-time queries on generated histories more often than latest-record-only storage.

- **Independent variables:** collection delay; overlapping intervals; missing claimed time; supersession; out-of-order ingestion.
- **Dependent variables:** temporal accuracy, stale-edge rate, ambiguous-time rate, order sensitivity.
- **Metrics:** correct edge set at each ground-truth timestamp; false active/inactive edges; deterministic result under ingestion permutations.
- **Baselines:** latest-record-only graph; ingestion-time-as-valid-time; closed intervals.
- **Dataset/fixtures:** generated release/deployment histories with known intervals, delayed observations, overlap, and corrections.
- **Threats to validity:** generated timelines; clock precision assumptions; timezone/parser differences; limited long-running histories.
- **Reproducibility:** fixed seeds, generator version, timestamp precision, expected snapshots, permutation list, raw outputs.
- **Earliest evaluation:** model/property tests in M2; deployment study in M4.

## RQ5 — Incident investigation efficiency

**Question:** Does a source-to-runtime evidence graph reduce investigation effort and improve conclusion accuracy versus separate tools?

**Hypothesis:** For bounded replayable incidents, investigators using ALO reach the correct faulty source/deployment conclusion with fewer tool switches and less time than investigators using raw source, CI, deployment, and telemetry records separately.

- **Independent variables:** tool condition (ALO versus separate records); scenario complexity; participant experience.
- **Dependent variables:** correct conclusion, completion time, queries/actions, tool switches, confidence calibration.
- **Metrics:** accuracy, median/p95 time, action count, calibration error, qualitative failure categories.
- **Baselines:** the same evidence exposed as separate raw tool exports; no-evidence-graph condition.
- **Dataset/fixtures:** replayable runtime incidents with independently reviewed ground truth and equivalent information in both conditions.
- **Threats to validity:** learning/order effects; small participant pool; synthetic incidents; implementer bias; unequal UI familiarity.
- **Reproducibility:** preregistered protocol, randomized ordering, anonymized raw observations where consent permits, scenario hashes, analysis script, and limitations.
- **Earliest evaluation:** after runtime evidence exists and at least one external adopter/participant cohort is available; no first-year implementation issue.

## RQ6 — Collection and storage overhead

**Question:** What resource cost is required for useful local evidence ingestion and tracing?

**Hypothesis:** SQLite can ingest and trace 100,000 bounded evidence records within owner-approved laptop budgets while preserving deterministic output and zero event loss.

- **Independent variables:** record count; relationship density; conflict rate; input size; transaction batch; index design.
- **Dependent variables:** throughput, query latency, peak RSS, database growth, backup time, failed/truncated operations.
- **Metrics:** records/second; p50/p95/p99 latency; peak resident memory; bytes/record; backup/restore duration; integrity result.
- **Baselines:** unindexed reference schema; single-record transactions; simple adjacency scan.
- **Dataset/fixtures:** deterministic 10k/100k generator plus the semantic fixture corpus.
- **Threats to validity:** one laptop; filesystem cache; thermal throttling; synthetic topology; SQLite/library/version variance.
- **Reproducibility:** raw samples, warm/cold protocol, hardware/OS/filesystem/Go/SQLite versions, seed, dataset hash, commands, and statistical summary.
- **Earliest evaluation:** M3.

## RQ7 — Reproducibility and evidence trust

**Question:** Can an ALO self-evidence bundle independently expose tampering or unverifiable release claims?

**Hypothesis:** An ALO release evidence bundle detects artifact, checksum, SBOM, provenance, or signature mismatch without classifying unavailable/unsupported verification as success.

- **Independent variables:** tampered component; verifier availability; signer policy; platform; reproducibility variance.
- **Dependent variables:** detection outcome, false-verified rate, indeterminate rate, verification time, explanation completeness.
- **Metrics:** per-tamper detection matrix; false acceptance; unsupported/indeterminate classification; time; missing-evidence diagnostics.
- **Baselines:** checksum-only release; unsigned SBOM/provenance bundle.
- **Dataset/fixtures:** v0.1 self-release bundle, independently generated expected digests, and one tampered variant per component.
- **Threats to validity:** self-produced evidence; limited signing ecosystems; key/trust-policy assumptions; platform-specific reproducibility.
- **Reproducibility:** immutable release artifacts, public verification commands, tool versions, trust-policy fixture, raw outcomes, and variance report.
- **Earliest evaluation:** M3.

## Research governance

- Pre-state hypotheses, ground truth, exclusion rules, and metrics before final measurement.
- Store raw machine-readable results, commands, versions, environment, seed, and hashes.
- Separate engineering budget pass/fail from scientific conclusions.
- Report negative, ambiguous, unsupported, and indeterminate results.
- Do not generalize beyond tested datasets, providers, participants, or platforms.
- Do not create implementation issues for RQ5 or full runtime RQ2 until their measurement prerequisites exist.
