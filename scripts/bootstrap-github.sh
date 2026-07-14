#!/usr/bin/env bash
set -Eeuo pipefail

PROGRAM_NAME="${0##*/}"
DEFAULT_REPO="Dyu20705/alo"
REPO="$DEFAULT_REPO"
APPLY=false
UPDATE_EXISTING=false
TMP_DIR=""

LABEL_CREATE=0
LABEL_UPDATE=0
LABEL_SKIP=0
MILESTONE_CREATE=0
MILESTONE_UPDATE=0
MILESTONE_SKIP=0
ISSUE_CREATE=0
ISSUE_UPDATE=0
ISSUE_SKIP=0

usage() {
  cat <<'USAGE'
Bootstrap or reconcile the approved GitHub project structure for ALO.

Usage:
  scripts/bootstrap-github.sh [options]

Options:
  --repo OWNER/NAME     Target repository (default: Dyu20705/alo)
  --apply               Perform GitHub mutations. Without this flag, dry-run only.
  --update-existing     In apply mode, reconcile bootstrap-managed milestone
                        descriptions and issue managed blocks. Text outside the
                        managed block and issue comments are preserved.
  -h, --help            Show this help.

Safety:
  - The default mode performs authenticated reads only.
  - No token is accepted or printed by this script.
  - Existing issues are identified by stable body markers, not titles.
  - Normal reruns skip matching issues.
  - The script never closes or deletes GitHub objects.
USAGE
}

log() {
  printf '[alo-bootstrap] %s\n' "$*"
}

die() {
  printf '[alo-bootstrap] ERROR: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "${TMP_DIR:-}" && -d "$TMP_DIR" ]]; then
    rm -rf -- "$TMP_DIR"
  fi
}

on_error() {
  local rc=$?
  printf '[alo-bootstrap] ERROR: command failed (exit=%d, line=%s): %s\n' \
    "$rc" "${BASH_LINENO[0]:-unknown}" "${BASH_COMMAND:-unknown}" >&2
  exit "$rc"
}

trap cleanup EXIT
trap on_error ERR

while (($# > 0)); do
  case "$1" in
    --repo)
      (($# >= 2)) || die "--repo requires OWNER/NAME"
      REPO="$2"
      shift 2
      ;;
    --apply)
      APPLY=true
      shift
      ;;
    --update-existing)
      UPDATE_EXISTING=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

if [[ ! "$REPO" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*/[A-Za-z0-9][A-Za-z0-9_.-]*$ ]]; then
  die "malformed repository name '$REPO'; expected OWNER/NAME"
fi

if ((BASH_VERSINFO[0] < 4)); then
  die "Bash 4 or newer is required"
fi

command -v gh >/dev/null 2>&1 || die "GitHub CLI 'gh' is required"
gh auth status --hostname github.com >/dev/null 2>&1 || die "gh is not authenticated for github.com"

repo_info="$(gh repo view "$REPO" \
  --json nameWithOwner,isArchived,viewerPermission \
  --jq '[.nameWithOwner, (.isArchived | tostring), .viewerPermission] | @tsv')"
IFS=$'\t' read -r resolved_repo is_archived viewer_permission <<<"$repo_info"

[[ "$resolved_repo" == "$REPO" ]] || die "repository resolved as '$resolved_repo', expected '$REPO'"
[[ "$is_archived" == "false" ]] || die "repository '$REPO' is archived"

if [[ "$APPLY" == true ]]; then
  case "$viewer_permission" in
    ADMIN|MAINTAIN|WRITE) ;;
    *) die "--apply requires WRITE, MAINTAIN, or ADMIN permission; found '$viewer_permission'" ;;
  esac
  log "mode=APPLY repo=$REPO permission=$viewer_permission"
else
  log "mode=DRY-RUN repo=$REPO permission=$viewer_permission"
fi

if [[ "$UPDATE_EXISTING" == true && "$APPLY" == false ]]; then
  log "--update-existing is being previewed only; no changes will be made"
fi

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/alo-bootstrap.XXXXXX")"
chmod 700 "$TMP_DIR"

declare -a LABEL_NAMES=()
declare -A LABEL_COLOR=()
declare -A LABEL_DESCRIPTION=()

declare -a MILESTONE_TITLES=()
declare -A MILESTONE_DESCRIPTION=()

declare -a ISSUE_KEYS=()
declare -A ISSUE_TITLE=()
declare -A ISSUE_MILESTONE=()
declare -A ISSUE_LABELS=()
declare -A ISSUE_DEPS=()
LABEL_NAMES+=(type:decision)
LABEL_COLOR[type:decision]=5319E7
LABEL_DESCRIPTION[type:decision]='Durable product, architecture, compatibility, or trust decision.'
LABEL_NAMES+=(type:feature)
LABEL_COLOR[type:feature]=1F883D
LABEL_DESCRIPTION[type:feature]='Externally observable product capability.'
LABEL_NAMES+=(type:security)
LABEL_COLOR[type:security]=B60205
LABEL_DESCRIPTION[type:security]='Threat reduction, verification, secure defaults, or vulnerability handling.'
LABEL_NAMES+=(type:quality)
LABEL_COLOR[type:quality]=FBCA04
LABEL_DESCRIPTION[type:quality]='Tests, fixtures, fuzzing, benchmarks, or correctness gates.'
LABEL_NAMES+=(type:operations)
LABEL_COLOR[type:operations]=0E8A16
LABEL_DESCRIPTION[type:operations]='Backup, recovery, migration, release, or operator workflow.'
LABEL_NAMES+=(type:research)
LABEL_COLOR[type:research]=8250DF
LABEL_DESCRIPTION[type:research]='Measurable experiment, benchmark, or research artifact.'
LABEL_NAMES+=(type:documentation)
LABEL_COLOR[type:documentation]=0075CA
LABEL_DESCRIPTION[type:documentation]='Documentation is the primary deliverable.'
LABEL_NAMES+=(area:product)
LABEL_COLOR[area:product]=C5DEF5
LABEL_DESCRIPTION[area:product]='Product contract, target user, scope, and non-goals.'
LABEL_NAMES+=(area:model)
LABEL_COLOR[area:model]=D4C5F9
LABEL_DESCRIPTION[area:model]='Evidence, identities, temporal semantics, and conflicts.'
LABEL_NAMES+=(area:storage)
LABEL_COLOR[area:storage]=BFDADC
LABEL_DESCRIPTION[area:storage]='SQLite, transactions, migrations, backup, and recovery.'
LABEL_NAMES+=(area:ingestion)
LABEL_COLOR[area:ingestion]=F9D0C4
LABEL_DESCRIPTION[area:ingestion]='Collectors and bounded parsing of external evidence.'
LABEL_NAMES+=(area:cli)
LABEL_COLOR[area:cli]=D4F4DD
LABEL_DESCRIPTION[area:cli]='CLI commands, outputs, errors, and reports.'
LABEL_NAMES+=(area:verification)
LABEL_COLOR[area:verification]=FEF2C0
LABEL_DESCRIPTION[area:verification]='Digest, provenance, signature status, and trust evaluation.'
LABEL_NAMES+=(area:release)
LABEL_COLOR[area:release]=FAD8C7
LABEL_DESCRIPTION[area:release]='CI, dependencies, packaging, release integrity, and upgrades.'
LABEL_NAMES+=(area:deployment)
LABEL_COLOR[area:deployment]=C2E0C6
LABEL_DESCRIPTION[area:deployment]='OCI and deployment snapshot correlation.'
LABEL_NAMES+=(area:research)
LABEL_COLOR[area:research]=E6E6FA
LABEL_DESCRIPTION[area:research]='Research questions, datasets, metrics, and reproducibility.'
LABEL_NAMES+=(priority:p0)
LABEL_COLOR[priority:p0]=D73A4A
LABEL_DESCRIPTION[priority:p0]='Blocks the next milestone or protects a core trust/data invariant.'
LABEL_NAMES+=(priority:p1)
LABEL_COLOR[priority:p1]=FBCA04
LABEL_DESCRIPTION[priority:p1]='Required for the milestone outcome but not the immediate blocker.'
LABEL_NAMES+=(priority:p2)
LABEL_COLOR[priority:p2]=C2E0C6
LABEL_DESCRIPTION[priority:p2]='Useful after higher-risk milestone obligations are satisfied.'
LABEL_NAMES+=(risk:data-integrity)
LABEL_COLOR[risk:data-integrity]=B60205
LABEL_DESCRIPTION[risk:data-integrity]='Failure can corrupt, mislink, or lose evidence.'
LABEL_NAMES+=(risk:security)
LABEL_COLOR[risk:security]=8B0000
LABEL_DESCRIPTION[risk:security]='Failure can weaken trust, expose secrets, or enable unsafe parsing.'
LABEL_NAMES+=(risk:compatibility)
LABEL_COLOR[risk:compatibility]=6F42C1
LABEL_DESCRIPTION[risk:compatibility]='Failure can break schemas, migrations, CLI, or external formats.'
LABEL_NAMES+=(status:blocked)
LABEL_COLOR[status:blocked]=000000
LABEL_DESCRIPTION[status:blocked]='Cannot proceed until an explicit dependency is resolved.'
LABEL_NAMES+=(status:needs-owner-decision)
LABEL_COLOR[status:needs-owner-decision]=D876E3
LABEL_DESCRIPTION[status:needs-owner-decision]='Requires a bounded repository-owner choice.'
MILESTONE_TITLES+=('M0 — Product, Trust, and Architecture Baseline')
MILESTONE_DESCRIPTION['M0 — Product, Trust, and Architecture Baseline']='Purpose: Freeze the smallest coherent product contract, trust model, evidence semantics, CLI contract, and production obligations before implementation. Exit: Product/non-goals, threat model, evidence and identity rules, compatibility policy, CLI contract, and production baseline are approved. Exclusions: No Go module, database, parser, collector, query implementation, release workflow, or GitHub mutation.'
MILESTONE_TITLES+=('M1 — Local Evidence Core')
MILESTONE_DESCRIPTION['M1 — Local Evidence Core']='Purpose: Deliver the first local SQLite-backed evidence path for Git and workflow-definition evidence with deterministic trace output. Exit: Database initialization/migration works; Git and workflow definitions ingest idempotently; bounded trace returns deterministic JSON. Exclusions: No SPDX, SLSA, remote workflow runs, signature verification, Markdown reports, PostgreSQL, or runtime evidence.'
MILESTONE_TITLES+=('M2 — Verifiable Ingestion and Trace Queries')
MILESTONE_DESCRIPTION['M2 — Verifiable Ingestion and Trace Queries']='Purpose: Add bounded SPDX/SLSA ingestion, workflow-run metadata, verification status, conflict handling, and complete report workflows. Exit: A fixture release connects repository, commit, workflow definition/run, artifact, SPDX, and provenance with explicit verification/conflict status. Exclusions: No generic policy engine, vulnerability database, SARIF, OpenTelemetry export, deployment correlation, or runtime sensor.'
MILESTONE_TITLES+=('M3 — Production-Ready v0.1')
MILESTONE_DESCRIPTION['M3 — Production-Ready v0.1']='Purpose: Harden the smallest useful product for repeatable release and local operation. Exit: Security policy, CI gates, fuzzing, benchmarks, backup/restore, recovery, signed release metadata, upgrade/rollback, and smoke tests are complete. Exclusions: No HA daemon, SaaS, Kubernetes, distributed graph store, plugin runtime, eBPF, or ML lineage.'
MILESTONE_TITLES+=('M4 — Deployment Correlation v0.2')
MILESTONE_DESCRIPTION['M4 — Deployment Correlation v0.2']='Purpose: Prove source-to-deployment correlation for local OCI and Docker environments without kernel or application telemetry. Exit: OCI metadata and one-shot Docker snapshots ingest; temporal trace/diff works; a reproducible correlation benchmark is published. Exclusions: No Kubernetes, eBPF, OpenTelemetry backend, SIEM behavior, runtime policy enforcement, or causality claims.'
ISSUE_KEYS+=(product-contract)
ISSUE_TITLE[product-contract]='Define the v0.1 product contract and first-year non-goals'
ISSUE_MILESTONE[product-contract]='M0 — Product, Trust, and Architecture Baseline'
ISSUE_LABELS[product-contract]='type:decision|area:product|priority:p0'
ISSUE_DEPS[product-contract]=''
ISSUE_KEYS+=(threat-model)
ISSUE_TITLE[threat-model]='Define the v0.1 threat model and trust boundaries'
ISSUE_MILESTONE[threat-model]='M0 — Product, Trust, and Architecture Baseline'
ISSUE_LABELS[threat-model]='type:security|area:verification|priority:p0|risk:security'
ISSUE_DEPS[threat-model]=product-contract
ISSUE_KEYS+=(evidence-invariants)
ISSUE_TITLE[evidence-invariants]='Specify canonical evidence invariants and initial relationship vocabulary'
ISSUE_MILESTONE[evidence-invariants]='M0 — Product, Trust, and Architecture Baseline'
ISSUE_LABELS[evidence-invariants]='type:decision|area:model|priority:p0|risk:data-integrity'
ISSUE_DEPS[evidence-invariants]='product-contract|threat-model'
ISSUE_KEYS+=(identity-rules)
ISSUE_TITLE[identity-rules]='Define v0.1 identity canonicalization, equality, aliases, and ambiguity'
ISSUE_MILESTONE[identity-rules]='M0 — Product, Trust, and Architecture Baseline'
ISSUE_LABELS[identity-rules]='type:decision|area:model|priority:p0|risk:data-integrity|risk:compatibility'
ISSUE_DEPS[identity-rules]=evidence-invariants
ISSUE_KEYS+=(schema-compatibility)
ISSUE_TITLE[schema-compatibility]='Define schema versioning and compatibility policy'
ISSUE_MILESTONE[schema-compatibility]='M0 — Product, Trust, and Architecture Baseline'
ISSUE_LABELS[schema-compatibility]='type:decision|area:model|area:storage|priority:p0|risk:compatibility'
ISSUE_DEPS[schema-compatibility]='evidence-invariants|identity-rules'
ISSUE_KEYS+=(cli-contract)
ISSUE_TITLE[cli-contract]='Specify staged CLI, deterministic output, and structured error contracts'
ISSUE_MILESTONE[cli-contract]='M0 — Product, Trust, and Architecture Baseline'
ISSUE_LABELS[cli-contract]='type:decision|area:cli|priority:p0|risk:compatibility'
ISSUE_DEPS[cli-contract]='product-contract|evidence-invariants|identity-rules|schema-compatibility'
ISSUE_KEYS+=(production-baseline)
ISSUE_TITLE[production-baseline]='Approve the measurable production baseline and release-integrity plan'
ISSUE_MILESTONE[production-baseline]='M0 — Product, Trust, and Architecture Baseline'
ISSUE_LABELS[production-baseline]='type:decision|area:release|priority:p0|risk:security'
ISSUE_DEPS[production-baseline]='product-contract|threat-model|schema-compatibility'
ISSUE_KEYS+=(sqlite-mapping)
ISSUE_TITLE[sqlite-mapping]='Design the SQLite relational mapping and append-oriented evidence store'
ISSUE_MILESTONE[sqlite-mapping]='M1 — Local Evidence Core'
ISSUE_LABELS[sqlite-mapping]='type:decision|area:storage|area:model|priority:p0|risk:data-integrity'
ISSUE_DEPS[sqlite-mapping]='evidence-invariants|identity-rules|schema-compatibility'
ISSUE_KEYS+=(migration-framework)
ISSUE_TITLE[migration-framework]='Implement database initialization and checksummed migration framework'
ISSUE_MILESTONE[migration-framework]='M1 — Local Evidence Core'
ISSUE_LABELS[migration-framework]='type:feature|area:storage|area:cli|priority:p0|risk:data-integrity|risk:compatibility'
ISSUE_DEPS[migration-framework]='cli-contract|sqlite-mapping'
ISSUE_KEYS+=(transaction-idempotency)
ISSUE_TITLE[transaction-idempotency]='Implement atomic evidence writes, idempotent ingestion, and interruption recovery'
ISSUE_MILESTONE[transaction-idempotency]='M1 — Local Evidence Core'
ISSUE_LABELS[transaction-idempotency]='type:feature|area:storage|area:ingestion|priority:p0|risk:data-integrity'
ISSUE_DEPS[transaction-idempotency]='evidence-invariants|sqlite-mapping|migration-framework'
ISSUE_KEYS+=(fixture-corpus)
ISSUE_TITLE[fixture-corpus]='Create the versioned evidence fixture and golden-output corpus'
ISSUE_MILESTONE[fixture-corpus]='M1 — Local Evidence Core'
ISSUE_LABELS[fixture-corpus]='type:quality|area:model|area:research|priority:p0'
ISSUE_DEPS[fixture-corpus]='evidence-invariants|identity-rules|schema-compatibility'
ISSUE_KEYS+=(git-ingestion)
ISSUE_TITLE[git-ingestion]='Implement local Git repository and commit evidence ingestion'
ISSUE_MILESTONE[git-ingestion]='M1 — Local Evidence Core'
ISSUE_LABELS[git-ingestion]='type:feature|area:ingestion|priority:p0|risk:security'
ISSUE_DEPS[git-ingestion]='identity-rules|migration-framework|transaction-idempotency|fixture-corpus'
ISSUE_KEYS+=(workflow-definition-ingestion)
ISSUE_TITLE[workflow-definition-ingestion]='Implement GitHub Actions workflow-definition ingestion'
ISSUE_MILESTONE[workflow-definition-ingestion]='M1 — Local Evidence Core'
ISSUE_LABELS[workflow-definition-ingestion]='type:feature|area:ingestion|priority:p1|risk:security|risk:compatibility'
ISSUE_DEPS[workflow-definition-ingestion]='identity-rules|migration-framework|transaction-idempotency|fixture-corpus'
ISSUE_KEYS+=(trace-json)
ISSUE_TITLE[trace-json]='Implement bounded trace traversal and deterministic JSON output'
ISSUE_MILESTONE[trace-json]='M1 — Local Evidence Core'
ISSUE_LABELS[trace-json]='type:feature|area:cli|area:model|priority:p0|risk:data-integrity'
ISSUE_DEPS[trace-json]='evidence-invariants|identity-rules|cli-contract|sqlite-mapping|migration-framework|transaction-idempotency|fixture-corpus'
ISSUE_KEYS+=(spdx-ingestion)
ISSUE_TITLE[spdx-ingestion]='Implement bounded SPDX SBOM document ingestion'
ISSUE_MILESTONE[spdx-ingestion]='M2 — Verifiable Ingestion and Trace Queries'
ISSUE_LABELS[spdx-ingestion]='type:feature|area:ingestion|priority:p0|risk:security|risk:compatibility'
ISSUE_DEPS[spdx-ingestion]='identity-rules|schema-compatibility|migration-framework|transaction-idempotency|fixture-corpus'
ISSUE_KEYS+=(slsa-ingestion)
ISSUE_TITLE[slsa-ingestion]='Implement bounded SLSA/in-toto provenance statement ingestion'
ISSUE_MILESTONE[slsa-ingestion]='M2 — Verifiable Ingestion and Trace Queries'
ISSUE_LABELS[slsa-ingestion]='type:feature|area:ingestion|area:verification|priority:p0|risk:security|risk:compatibility'
ISSUE_DEPS[slsa-ingestion]='identity-rules|schema-compatibility|migration-framework|transaction-idempotency|fixture-corpus'
ISSUE_KEYS+=(workflow-run-ingestion)
ISSUE_TITLE[workflow-run-ingestion]='Implement opt-in GitHub Actions workflow-run metadata ingestion'
ISSUE_MILESTONE[workflow-run-ingestion]='M2 — Verifiable Ingestion and Trace Queries'
ISSUE_LABELS[workflow-run-ingestion]='type:feature|area:ingestion|priority:p1|risk:security'
ISSUE_DEPS[workflow-run-ingestion]='identity-rules|schema-compatibility|migration-framework|transaction-idempotency|fixture-corpus|workflow-definition-ingestion'
ISSUE_KEYS+=(verification-status)
ISSUE_TITLE[verification-status]='Implement digest and provenance verification status evaluation'
ISSUE_MILESTONE[verification-status]='M2 — Verifiable Ingestion and Trace Queries'
ISSUE_LABELS[verification-status]='type:security|area:verification|priority:p0|risk:security|risk:data-integrity'
ISSUE_DEPS[verification-status]='evidence-invariants|identity-rules|schema-compatibility|transaction-idempotency|spdx-ingestion|slsa-ingestion'
ISSUE_KEYS+=(conflict-supersession)
ISSUE_TITLE[conflict-supersession]='Implement evidence conflict, ambiguity, and supersession behavior'
ISSUE_MILESTONE[conflict-supersession]='M2 — Verifiable Ingestion and Trace Queries'
ISSUE_LABELS[conflict-supersession]='type:feature|area:model|area:storage|priority:p0|risk:data-integrity'
ISSUE_DEPS[conflict-supersession]='evidence-invariants|identity-rules|schema-compatibility|transaction-idempotency|fixture-corpus'
ISSUE_KEYS+=(human-markdown-report)
ISSUE_TITLE[human-markdown-report]='Implement deterministic terminal and Markdown evidence reports'
ISSUE_MILESTONE[human-markdown-report]='M2 — Verifiable Ingestion and Trace Queries'
ISSUE_LABELS[human-markdown-report]='type:feature|area:cli|priority:p1|risk:compatibility'
ISSUE_DEPS[human-markdown-report]='cli-contract|trace-json'
ISSUE_KEYS+=(e2e-release-fixture)
ISSUE_TITLE[e2e-release-fixture]='Deliver the complete fixture release ingest–trace–verify workflow'
ISSUE_MILESTONE[e2e-release-fixture]='M2 — Verifiable Ingestion and Trace Queries'
ISSUE_LABELS[e2e-release-fixture]='type:quality|area:cli|area:verification|priority:p0'
ISSUE_DEPS[e2e-release-fixture]='git-ingestion|workflow-definition-ingestion|trace-json|spdx-ingestion|slsa-ingestion|workflow-run-ingestion|verification-status|conflict-supersession|human-markdown-report'
ISSUE_KEYS+=(security-policy)
ISSUE_TITLE[security-policy]='Publish security policy, vulnerability reporting, and secret-handling rules'
ISSUE_MILESTONE[security-policy]='M3 — Production-Ready v0.1'
ISSUE_LABELS[security-policy]='type:security|area:release|priority:p0|risk:security'
ISSUE_DEPS[security-policy]='threat-model|production-baseline'
ISSUE_KEYS+=(ci-dependency-gates)
ISSUE_TITLE[ci-dependency-gates]='Establish CI quality gates and dependency policy'
ISSUE_MILESTONE[ci-dependency-gates]='M3 — Production-Ready v0.1'
ISSUE_LABELS[ci-dependency-gates]='type:quality|area:release|priority:p0|risk:security|risk:compatibility'
ISSUE_DEPS[ci-dependency-gates]='production-baseline|fixture-corpus|git-ingestion|workflow-definition-ingestion|spdx-ingestion|slsa-ingestion|workflow-run-ingestion|verification-status|conflict-supersession|e2e-release-fixture'
ISSUE_KEYS+=(fuzz-property-tests)
ISSUE_TITLE[fuzz-property-tests]='Add parser fuzzing and identity/property test suites'
ISSUE_MILESTONE[fuzz-property-tests]='M3 — Production-Ready v0.1'
ISSUE_LABELS[fuzz-property-tests]='type:quality|area:ingestion|area:model|priority:p0|risk:security|risk:data-integrity'
ISSUE_DEPS[fuzz-property-tests]='identity-rules|fixture-corpus|workflow-definition-ingestion|spdx-ingestion|slsa-ingestion|conflict-supersession'
ISSUE_KEYS+=(bench-resource-budgets)
ISSUE_TITLE[bench-resource-budgets]='Establish reproducible performance benchmarks and resource budgets'
ISSUE_MILESTONE[bench-resource-budgets]='M3 — Production-Ready v0.1'
ISSUE_LABELS[bench-resource-budgets]='type:research|area:research|area:storage|priority:p1'
ISSUE_DEPS[bench-resource-budgets]='identity-rules|fixture-corpus|spdx-ingestion|slsa-ingestion|conflict-supersession|trace-json'
ISSUE_KEYS+=(backup-recovery)
ISSUE_TITLE[backup-recovery]='Implement backup, restore, integrity checking, and corruption recovery runbook'
ISSUE_MILESTONE[backup-recovery]='M3 — Production-Ready v0.1'
ISSUE_LABELS[backup-recovery]='type:operations|area:storage|priority:p0|risk:data-integrity'
ISSUE_DEPS[backup-recovery]='sqlite-mapping|migration-framework|transaction-idempotency|fixture-corpus|trace-json|e2e-release-fixture'
ISSUE_KEYS+=(release-dogfooding)
ISSUE_TITLE[release-dogfooding]='Produce checksums, SBOM, provenance, signatures, and an ALO release evidence bundle'
ISSUE_MILESTONE[release-dogfooding]='M3 — Production-Ready v0.1'
ISSUE_LABELS[release-dogfooding]='type:operations|area:release|area:verification|priority:p0|risk:security'
ISSUE_DEPS[release-dogfooding]='threat-model|production-baseline|migration-framework|transaction-idempotency'
ISSUE_KEYS+=(upgrade-release-verification)
ISSUE_TITLE[upgrade-release-verification]='Document and test upgrade, rollback, and end-to-end v0.1 release verification'
ISSUE_MILESTONE[upgrade-release-verification]='M3 — Production-Ready v0.1'
ISSUE_LABELS[upgrade-release-verification]='type:operations|area:release|area:storage|priority:p0|risk:compatibility'
ISSUE_DEPS[upgrade-release-verification]='schema-compatibility|e2e-release-fixture|ci-dependency-gates|backup-recovery|release-dogfooding'
ISSUE_KEYS+=(oci-adapter)
ISSUE_TITLE[oci-adapter]='Implement OCI image digest identity and local metadata ingestion'
ISSUE_MILESTONE[oci-adapter]='M4 — Deployment Correlation v0.2'
ISSUE_LABELS[oci-adapter]='type:feature|area:deployment|area:ingestion|priority:p0|risk:data-integrity'
ISSUE_DEPS[oci-adapter]='identity-rules|schema-compatibility|sqlite-mapping|migration-framework|transaction-idempotency|fixture-corpus|verification-status'
ISSUE_KEYS+=(docker-snapshots)
ISSUE_TITLE[docker-snapshots]='Implement local Docker deployment snapshot ingestion'
ISSUE_MILESTONE[docker-snapshots]='M4 — Deployment Correlation v0.2'
ISSUE_LABELS[docker-snapshots]='type:feature|area:deployment|area:ingestion|priority:p0|risk:security'
ISSUE_DEPS[docker-snapshots]='oci-adapter|fixture-corpus|migration-framework|transaction-idempotency'
ISSUE_KEYS+=(deployment-trace-diff)
ISSUE_TITLE[deployment-trace-diff]='Implement temporal deployment correlation and before/after diff queries'
ISSUE_MILESTONE[deployment-trace-diff]='M4 — Deployment Correlation v0.2'
ISSUE_LABELS[deployment-trace-diff]='type:feature|area:deployment|area:cli|priority:p0|risk:data-integrity'
ISSUE_DEPS[deployment-trace-diff]='evidence-invariants|identity-rules|schema-compatibility|trace-json|conflict-supersession|oci-adapter|docker-snapshots'
ISSUE_KEYS+=(deployment-benchmark)
ISSUE_TITLE[deployment-benchmark]='Publish the v0.2 deployment-correlation benchmark and limitations report'
ISSUE_MILESTONE[deployment-benchmark]='M4 — Deployment Correlation v0.2'
ISSUE_LABELS[deployment-benchmark]='type:research|area:research|area:deployment|priority:p1'
ISSUE_DEPS[deployment-benchmark]='bench-resource-budgets|upgrade-release-verification|oci-adapter|docker-snapshots|deployment-trace-diff'

issue_template() {
  local key="$1"
  local file="$2"

  case "$key" in
    product-contract)
      cat >"$file" <<'ALO_ISSUE_01'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=product-contract -->

## Context

ALO currently has only a name while the proposal spans source, build, artifacts, deployment, runtime, and research. A binding contract is required to prevent drift into a scanner, SIEM, observability backend, or GUAC clone.

## Goal

Approve one target user, one complete v0.1 use case, a one-paragraph definition, staged outcomes through v0.2, and explicit first-year exclusions.

## Scope

- Primary user: developer or release engineer investigating one repository/release on one machine.
- First use case: ingest local release evidence, trace artifact to source, verify checks, and report uncertainty.
- Principles: open source, local-first, developer-first, adapter-based, monorepo, production-oriented.

## Non-goals

- Choose package layout or implement commands.
- Promise runtime causality, compliance certification, vulnerability management, or enterprise scale.

## Design constraints

- Must work without cloud, Kubernetes, PostgreSQL, or privileged sensors.
- Application source is implemented manually by the owner.

## Tasks

- [ ] Finalize VISION.md, PRODUCT.md, and NON_GOALS.md.
- [ ] Map every M0–M4 issue to an approved outcome.
- [ ] Record bounded owner decisions.

## Acceptance criteria

- [ ] Documents identify one target user and one complete v0.1 workflow.
- [ ] Every excluded first-year technology is named.
- [ ] No v0.1 requirement depends on deployment/runtime evidence.
- [ ] Central question includes trust, queryability, and temporal accuracy.

## Verification

- Cross-reference every issue to the product contract.
- Search docs for excluded features and confirm roadmap/non-goal-only treatment.

## Documentation impact

Creates VISION.md, PRODUCT.md, and NON_GOALS.md.

## Research or measurement impact

Defines which research questions are measurable before v0.2.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Scope language must not imply a universal graph platform.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_01
      ;;
    threat-model)
      cat >"$file" <<'ALO_ISSUE_02'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=threat-model -->

## Context

ALO ingests attacker-controlled repositories, YAML, JSON, SBOMs, provenance, paths, and remote metadata. Syntactically valid evidence can still be false.

## Goal

Document assets, actors, entry points, trust boundaries, abuse cases, mitigations, and residual risks for the local userspace product.

## Scope

- CLI, SQLite, Git metadata, workflow files, SPDX/SLSA files, optional GitHub credentials, and release artifacts.
- Path traversal, parser bombs, forged evidence, identity confusion, secret leakage, database tampering, unsafe output, and release compromise.
- Status vocabulary: unverified, verified, failed, unsupported, indeterminate.

## Non-goals

- Kernel sensor threats, Kubernetes RBAC, multi-tenant authorization, or hosted isolation.
- Treat a trusted collector as proof that its upstream claim is true.

## Design constraints

- Collectors are least-privilege and never execute repository content.
- Network access is opt-in.

## Tasks

- [ ] Create data-flow/trust-boundary diagrams.
- [ ] Define parser/path/archive limits.
- [ ] Map P0 threats to implementation issues or accepted residual risks.

## Acceptance criteria

- [ ] Every v0.1 input crosses a named trust boundary.
- [ ] Authenticity, conformance, trust, and confidence are distinct.
- [ ] Parser limits, redaction, permissions, and release-integrity controls are explicit.
- [ ] Includes valid-but-misleading signed provenance.

## Verification

- STRIDE-style review of each flow.
- Trace every P0 threat to a backlog issue or residual-risk statement.

## Documentation impact

Creates docs/threat-model/threat-model.md.

## Research or measurement impact

Identifies adversarial fixtures for trust experiments.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Signed evidence may be over-trusted if signer policy is not separated.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_02
      ;;
    evidence-invariants)
      cat >"$file" <<'ALO_ISSUE_03'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=evidence-invariants -->

## Context

The evidence model is ALO's central asset. Subject-predicate-object alone is insufficient without enforceable identity, time, source, verification, conflict, and provenance semantics.

## Goal

Define the design-level canonical evidence record and minimal v0.1 relationship vocabulary.

## Scope

- Evidence ID, subject, predicate, object, observed_at, valid interval, source/source instance, content digest, optional signature reference, verification status, confidence, record provenance, schema version, ingested_at, conflict_of, and supersedes.
- Initial relationships among repository, commit, workflow definition/run, artifact, SPDX document, and provenance statement.

## Non-goals

- Custom query language.
- Active runtime identity types.
- Vulnerability findings or policy verdicts in the core vocabulary.

## Design constraints

- Same logical input yields the same canonical semantic record.
- Corrections use supersession; original evidence is retained.

## Tasks

- [ ] Define fields, cardinality, normalization, mutability, and validation.
- [ ] Define relationship direction and temporal meaning.
- [ ] Provide duplicate/conflict/supersession examples.
- [ ] Record rejected alternatives.

## Acceptance criteria

- [ ] Every field has precise semantics.
- [ ] Intervals are half-open [from, until); null until means open-ended.
- [ ] Evidence ID excludes volatile ingestion fields.
- [ ] Contradiction and supersession never delete source evidence.

## Verification

- Review examples against invariants.
- Produce a duplicate/corroboration/conflict/correction decision table.

## Documentation impact

Creates docs/architecture/evidence-model.md and ADR-0002.

## Research or measurement impact

Defines variables for conflict and temporal studies.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Vocabulary that is too broad hides adapter semantics; too narrow leaks format details into core.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_03
      ;;
    identity-rules)
      cat >"$file" <<'ALO_ISSUE_04'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=identity-rules -->

## Context

Cross-system correlation fails when repository URLs, commits, workflow paths, artifacts, OCI references, and documents use inconsistent identifiers. False linkage is worse than unresolved identity.

## Goal

Specify canonical identities and conservative matching for the deliberately small first-year identity set.

## Scope

- Git repository, Git commit, workflow definition, workflow run, generic artifact/file digest, OCI image digest, SPDX document, and SLSA/in-toto statement.
- Canonical serialization, equality, aliases, source scopes, invalid forms, ambiguity, algorithms, Unicode/case/path handling, and collision behavior.

## Non-goals

- Process, socket, syscall, Kubernetes workload, model, dataset, person, or vulnerability identities.
- Heuristic auto-merge of ambiguous identities.

## Design constraints

- Content identities include digest algorithm.
- Repository identity preserves host and owner/path.
- Workflow-run IDs are source-instance scoped.
- OCI tags are observations, not immutable identities.

## Tasks

- [ ] Define canonical text forms.
- [ ] Separate strict equality, aliases, and candidates.
- [ ] Create at least 40 equivalence/non-equivalence examples.
- [ ] Record rejected alternatives.

## Acceptance criteria

- [ ] Canonicalization is deterministic and idempotent.
- [ ] Proven GitHub SSH/HTTPS forms normalize consistently.
- [ ] Ambiguous or unsupported inputs fail closed.
- [ ] Bare digest, tag, or abbreviated commit is never silently globalized.

## Verification

- Golden/property tests are specified for Unicode, URL, path, case, algorithm, malformed digest, and ambiguity cases.

## Documentation impact

Extends docs/architecture/evidence-model.md.

## Research or measurement impact

Provides ground truth for identity precision/recall.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Host-specific path case rules can create false equality.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_04
      ;;
    schema-compatibility)
      cat >"$file" <<'ALO_ISSUE_05'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=schema-compatibility -->

## Context

Evidence schema, database migration number, exported JSON version, collector compatibility, and application version are distinct and must evolve without silent semantic change.

## Goal

Approve versioning, deprecation, migration, import/export, unknown-field, and rollback rules before persistence exists.

## Scope

- v0alpha1 lifecycle.
- Additive versus breaking versus semantic changes.
- Unknown critical field/predicate handling.
- Historical fixture retention and pre-v1 compatibility promises.

## Non-goals

- Permanent stability for experimental fields.
- Schema-registry service or distributed migration coordinator.

## Design constraints

- Readers reject unsafe semantics they cannot interpret.
- Released migrations are ordered, checksummed, and immutable.

## Tasks

- [ ] Write compatibility matrix.
- [ ] Separate schema, DB migration, CLI output, and app versions.
- [ ] Define newer/older record behavior and downgrade boundary.

## Acceptance criteria

- [ ] Unknown critical fields are not silently ignored.
- [ ] Three example changes classify required version/migration action.
- [ ] Rollback states when downgrade is safe versus backup restore required.
- [ ] Historical schemas remain testable.

## Verification

- Cross-document version-term audit.
- Review sample additive, breaking, and semantic changes.

## Documentation impact

Updates evidence-model and storage-and-migrations documents.

## Research or measurement impact

Preserves benchmark comparability across releases.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Over-promising stability can freeze a weak model; unconstrained alpha changes can invalidate stored evidence.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_05
      ;;
    cli-contract)
      cat >"$file" <<'ALO_ISSUE_06'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=cli-contract -->

## Context

The CLI is the first product and automation surface. Proposal commands are illustrative; command staging and failure semantics must be frozen before implementation.

## Goal

Define M1–M4 command availability, inputs, side effects, output envelopes, ordering, exit codes, error classes, config precedence, and stdout/stderr rules.

## Scope

- init; ingest git/workflow/SBOM/provenance/workflow-run; trace; verify; report; DB check/backup/restore; later OCI/Docker/diff.
- Versioned deterministic JSON and testable terminal/Markdown output.

## Non-goals

- Custom query language, web API, daemon protocol, SARIF, OpenTelemetry output, or shell completion.

## Design constraints

- Warnings never contaminate JSON stdout.
- Verification failure differs from command execution failure.
- Queries are bounded by defaults.

## Tasks

- [ ] Write command contract and milestone matrix.
- [ ] Define stable error classes/exit codes.
- [ ] Define no-telemetry default and config precedence.

## Acceptance criteria

- [ ] Every command has inputs, outputs, side effects, failure modes, and milestone.
- [ ] JSON has an explicit schema version and deterministic ordering.
- [ ] Ambiguous/no-result/truncated results are distinguishable.
- [ ] Secrets are redacted.

## Verification

- Walk through the full fixture use case from the contract alone.
- Review stdout/stderr and exit-code examples.

## Documentation impact

Updates PRODUCT.md and production-baseline.md.

## Research or measurement impact

Makes benchmark output machine-parseable.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Broad command namespaces can expose unstable internals.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_06
      ;;
    production-baseline)
      cat >"$file" <<'ALO_ISSUE_07'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=production-baseline -->

## Context

Production-first must mean bounded, correct, recoverable, and verifiable—not premature distributed architecture or a vague final hardening phase.

## Goal

Allocate measurable correctness, security, reliability, testing, operations, and supply-chain obligations across M1–M3.

## Scope

- Determinism, transactions, migrations, parser limits, least privilege, redaction, backup/restore, recovery, logs, telemetry defaults, tests, fuzzing, benchmarks, and release evidence.
- Release-blocking versus advisory checks.

## Non-goals

- Enterprise SLA, compliance certification, formal verification, or universal bit-reproducibility claims.

## Design constraints

- Every obligation has a test, measurement, review, or artifact.
- No mandatory paid service.

## Tasks

- [ ] Create requirement-to-milestone matrix.
- [ ] Define v0.1 release gate.
- [ ] Define checksums/SBOM/provenance/signature/evidence-bundle distinctions.

## Acceptance criteria

- [ ] All production requirements map to an issue and verification method.
- [ ] Backup/restore and migration tests are release gates.
- [ ] Telemetry is disabled by default.
- [ ] Reproducibility claims include limitations.

## Verification

- Backlog audit for deferred security/reliability work.
- Adversarial design review against threat model.

## Documentation impact

Creates docs/operations/production-baseline.md.

## Research or measurement impact

Defines reproducibility requirements for studies.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Non-numeric promises such as fast/lightweight/scalable are prohibited until measured.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_07
      ;;
    sqlite-mapping)
      cat >"$file" <<'ALO_ISSUE_08'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=sqlite-mapping -->

## Context

The canonical model is graph-shaped, but v0.1 does not need a graph database. SQLite must preserve immutable evidence, identities, aliases, time, conflicts, and provenance efficiently.

## Goal

Define the normalized logical schema, constraints, indexes, deletion rules, and representative trace queries before implementation.

## Scope

- Identities, aliases/candidates, sources/source instances, evidence, endpoints, verification records, conflicts/supersession, batches, and migration metadata.
- Indexes for identity, subject/object traversal, time range, digest, source, and evidence ID.

## Non-goals

- Distributed graph store, PostgreSQL schema, full-text search, vulnerability tables, or telemetry storage.

## Design constraints

- Foreign keys enabled.
- Core semantics are not hidden in catch-all JSON.
- Derived caches are rebuildable and not source of truth.

## Tasks

- [ ] Create logical ER design.
- [ ] Define uniqueness/dedup constraints.
- [ ] Specify representative SQL/query-plan expectations.
- [ ] Estimate storage at 10k/100k/1M records.

## Acceptance criteria

- [ ] Every v0.1 evidence field is representable.
- [ ] Indexes avoid full scans for reference trace queries.
- [ ] Cascade rules cannot erase history accidentally.
- [ ] Schema carries compatibility/migration metadata.

## Verification

- Review duplicate/conflict inserts against constraints.
- Document expected EXPLAIN QUERY PLAN characteristics.

## Documentation impact

Creates docs/architecture/storage-and-migrations.md.

## Research or measurement impact

Defines storage-overhead variables.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Over-normalization can complicate transactions; under-normalization can weaken invariants.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_08
      ;;
    migration-framework)
      cat >"$file" <<'ALO_ISSUE_09'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=migration-framework -->

## Context

Every stored feature depends on safe creation, open, upgrade, incompatibility refusal, and migration rollback behavior.

## Goal

Implement `alo init`, ordered checksummed forward migrations, compatibility metadata, and failure-safe opening.

## Scope

- Configurable DB path, safe file permissions, ordered migrations, checksum validation, migration locking/transactions, newer-schema refusal, and historical fixtures.

## Non-goals

- Automatic downgrade migrations, PostgreSQL, or distributed/online migrations.

## Design constraints

- Released migration definitions are immutable.
- Failed migration leaves prior DB usable or restoreable.
- Unsupported newer DB is not modified.

## Tasks

- [ ] Implement DB initialization/open checks.
- [ ] Implement migration metadata/checksums.
- [ ] Add empty/current/old/newer/corrupt-metadata fixtures.
- [ ] Inject a migration failure.

## Acceptance criteria

- [ ] Repeated init is idempotent.
- [ ] Changed released migration checksum fails hard.
- [ ] Newer unsupported schema is not changed.
- [ ] Injected failure rolls back its migration.

## Verification

- Unit tests for ordering/checksums.
- Integration tests across historical DB fixtures.
- Clean-directory repeated-init manual check.

## Documentation impact

Updates storage/migration and CLI documentation.

## Research or measurement impact

Historical DB fixtures preserve reproducibility.

__ALO_DEPENDENCIES__

## Risks and edge cases

- SQLite DDL transaction behavior must be tested, not assumed.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_09
      ;;
    transaction-idempotency)
      cat >"$file" <<'ALO_ISSUE_10'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=transaction-idempotency -->

## Context

Collectors can fail midway, retry, or submit duplicates. Partial graph writes and duplicate semantic records would make traces untrustworthy.

## Goal

Define and implement one ingestion-unit transaction with deterministic deduplication, conflict insertion, batch outcomes, and stale-operation recovery.

## Scope

- Pre-commit validation, all-or-nothing writes, inserted/duplicate/conflict/rejected counts, fault injection, and stale batch markers.

## Non-goals

- Exactly-once across machines, distributed transactions, or automatic conflict resolution.

## Design constraints

- Collectors cannot write outside the storage API.
- Evidence ID and constraints drive deduplication.
- Batch size/retry are bounded.

## Tasks

- [ ] Define ingestion-unit boundary.
- [ ] Implement rollback and retry semantics.
- [ ] Add failure points before/during/after writes.
- [ ] Implement safe stale-marker recovery.

## Acceptance criteria

- [ ] Identical rerun creates zero semantic duplicates.
- [ ] Kill/failure before commit leaves no visible partial batch.
- [ ] Contradiction is not misclassified as duplicate.
- [ ] Recovery never removes committed evidence.

## Verification

- Fault-injection integration tests.
- Row-count and trace comparisons before/after retry.

## Documentation impact

Updates transaction and collector-boundary docs.

## Research or measurement impact

Creates controlled duplicate/conflict fixtures.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Large transactions may increase lock time and memory; limits must be measured.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_10
      ;;
    fixture-corpus)
      cat >"$file" <<'ALO_ISSUE_11'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=fixture-corpus -->

## Context

Parser, identity, migration, output, and benchmark claims require stable, reviewable ground truth with both valid and adversarial cases.

## Goal

Create a small synthetic repository/release corpus, fixture manifest, hashes, provenance, and versioned expected identities/relationships/errors.

## Scope

- Git history; workflow YAML; valid/invalid SPDX and SLSA; duplicates/conflicts; Unicode/path/digest cases; expected trace paths; generation instructions.

## Non-goals

- Real proprietary repositories, malware samples, network-required fixtures, or a large benchmark corpus.

## Design constraints

- No secrets.
- Offline reproducibility.
- Committed or deterministically generated fixtures have hashes/licenses/origin.

## Tasks

- [ ] Design happy-path release and adversarial variants.
- [ ] Define expected canonical records and failures.
- [ ] Define golden-update review policy.
- [ ] Add fixture integrity check.

## Acceptance criteria

- [ ] Clean clone verifies all hashes offline.
- [ ] Covers malformed, boundary, duplicate, conflict, alias, ambiguity, and unsupported cases.
- [ ] Golden outputs are sorted and schema-versioned.
- [ ] Licensing/origin documented.

## Verification

- Offline fixture verification.
- Manual mapping from each fixture to an invariant or threat.

## Documentation impact

Adds fixture documentation and research references.

## Research or measurement impact

Initial ground-truth dataset for identity/conflict studies.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Golden files can normalize bugs; semantic changes need rationale and review.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_11
      ;;
    git-ingestion)
      cat >"$file" <<'ALO_ISSUE_12'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=git-ingestion -->

## Context

Git is the first source layer and must be inspected without executing hooks or repository code.

## Goal

Ingest one local repository observation, selected commit, parent relationships, remote aliases, and source metadata into canonical evidence.

## Scope

- Normal, bare, shallow, detached, no-remote, multiple-remote, and unborn repositories.
- Explicit commit/default HEAD; full object ID validation; local path as observation.

## Non-goals

- Remote clone, signed-commit verification, file-content scanning, submodule execution, hooks, builds, or dependency scanning.

## Design constraints

- Use non-executing Git plumbing/library behavior.
- No global identity invented from a local path.
- Personal metadata follows privacy/redaction policy.

## Tasks

- [ ] Implement bounded repository discovery and commit resolution.
- [ ] Normalize remote aliases conservatively.
- [ ] Emit repository/commit/parent evidence and source instance.

## Acceptance criteria

- [ ] Identical commit ingestion is idempotent.
- [ ] No-remote repository remains representable without guessed global identity.
- [ ] Malformed/missing commit causes no DB change.
- [ ] Hooks/executables are never run.

## Verification

- Integration tests across listed Git states.
- Golden identity assertions.
- Audit commands/library calls for execution risk.

## Documentation impact

Documents supported Git states and privacy treatment.

## Research or measurement impact

Provides source-side identity ground truth.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Remote URL normalization and author metadata can create equality/privacy errors.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_12
      ;;
    workflow-definition-ingestion)
      cat >"$file" <<'ALO_ISSUE_13'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=workflow-definition-ingestion -->

## Context

Workflow definitions bridge commits to declared build processes, but YAML is untrusted and full GitHub Actions semantics are out of scope.

## Goal

Ingest immutable workflow-definition identity and a bounded structural summary without expression/action execution.

## Scope

- `.github/workflows` only; commit+relative path identity; content digest; name/triggers/jobs/step identifiers; byte/depth/alias/string/job/step limits.

## Non-goals

- Expression evaluation, remote reusable workflow resolution, action execution, security score, or runner-semantic emulation.

## Design constraints

- Exact file digest remains primary evidence.
- Unsupported constructs emit explicit warnings.
- Path discovery cannot escape repository root.

## Tasks

- [ ] Publish supported subset/limits.
- [ ] Implement safe discovery and parse.
- [ ] Emit commit-defines-workflow evidence.
- [ ] Add abuse fixtures.

## Acceptance criteria

- [ ] Only approved workflow paths are considered.
- [ ] Over-limit YAML is rejected deterministically.
- [ ] Unknown constructs are not guessed.
- [ ] Repeated ingestion is idempotent.

## Verification

- Unit/golden tests for valid and abusive YAML.
- Register fuzz target for M3.
- Boundary ±1 tests for limits.

## Documentation impact

Documents supported GitHub Actions subset and limits.

## Research or measurement impact

Provides declared-build structure.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Attempting full Actions semantics would consume the project.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_13
      ;;
    trace-json)
      cat >"$file" <<'ALO_ISSUE_14'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=trace-json -->

## Context

Ingestion becomes useful only when users can trace relationships and see the evidence supporting each edge.

## Goal

Implement exact/candidate identity lookup and bounded graph traversal with deterministic versioned JSON for M1 evidence types.

## Scope

- Incoming/outgoing/both traversal, depth/result limits, cycles, aliases/ambiguity, evidence/source annotations, stable ordering, truncation metadata, and no-result behavior.

## Non-goals

- Custom query language, ranking, dashboard, policy evaluation, or unbounded shortest-path search.

## Design constraints

- Read-only queries.
- Every returned edge references evidence.
- Defaults prevent path explosion.
- Same DB/options yield deterministic canonical JSON.

## Tasks

- [ ] Implement indexed traversal.
- [ ] Implement result model and ordering.
- [ ] Expose staged `alo trace`.
- [ ] Add candidate/no-result/truncation behavior.

## Acceptance criteria

- [ ] Cycles terminate without duplicate paths.
- [ ] Ambiguity returns candidates instead of a guess.
- [ ] Limit exhaustion is explicit truncation.
- [ ] Golden JSON is stable for the same state.

## Verification

- Golden JSON tests.
- Integration tests for cycles, depth, limits, aliases, missing identity, and conflicts.
- Query-plan review.

## Documentation impact

Updates query and CLI semantics.

## Research or measurement impact

Creates baseline query latency/count measurements.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Path explosion and volatile fields can break determinism.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_14
      ;;
    spdx-ingestion)
      cat >"$file" <<'ALO_ISSUE_15'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=spdx-ingestion -->

## Context

SPDX is an adapter, not ALO's domain model. The first parser should extract only lineage-relevant facts while preserving unsupported semantics safely.

## Goal

Ingest a documented SPDX JSON subset into canonical document, artifact/package, digest, and relationship evidence.

## Scope

- Supported SPDX version/profile subset; document namespace/identity; creation metadata; digest-addressable packages/files; selected relationships; unresolved external references; parser limits.

## Non-goals

- SBOM viewer, vulnerability scanner, license-compliance engine, all serializations, or all profiles.

## Design constraints

- No network dereference.
- Document element IDs are scoped to their SPDX document.
- Malformed/over-limit input creates no partial evidence.

## Tasks

- [ ] Publish field/relationship compatibility matrix.
- [ ] Implement bounded decode and mapping.
- [ ] Emit unsupported warnings and source digest.
- [ ] Add version/boundary/adversarial fixtures.

## Acceptance criteria

- [ ] Document-scoped IDs never collide across documents.
- [ ] Unknown relationships are not coerced.
- [ ] Digest-addressed artifacts match canonical identity rules.
- [ ] Repeated ingestion is idempotent.

## Verification

- Golden valid/invalid documents.
- Boundary tests for bytes, depth, counts, duplicate IDs, external refs, and unsupported versions.

## Documentation impact

Documents SPDX subset and limitations.

## Research or measurement impact

Adds heterogeneous identity cases.

__ALO_DEPENDENCIES__

## Risks and edge cases

- SPDX breadth can overwhelm v0.1; subset boundaries must be enforceable.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_15
      ;;
    slsa-ingestion)
      cat >"$file" <<'ALO_ISSUE_16'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=slsa-ingestion -->

## Context

Provenance statements connect subjects, source, builder, and invocation, but syntactic conformance and trust are separate.

## Goal

Ingest a documented statement/predicate subset and map subjects, source commit claims, builder claims, timestamps, and statement provenance into canonical evidence.

## Scope

- Supported in-toto statement/SLSA predicate versions; subject digests; builder/source/invocation claims; exact statement digest; bounded JSON.

## Non-goals

- Trust arbitrary builders, fetch transparency logs, full in-toto verification, or infer reproducibility from one claim.

## Design constraints

- Ingestion status is not verification status.
- All claims retain source statement and adapter version.
- Unsupported predicates remain explicit.

## Tasks

- [ ] Publish compatibility matrix.
- [ ] Implement bounded extraction/mapping.
- [ ] Preserve builder/source as claims.
- [ ] Add supported/unsupported/tampered fixtures.

## Acceptance criteria

- [ ] Subjects without supported digest are not globalized.
- [ ] Malformed/unsupported statements create no partial evidence.
- [ ] Builder remains untrusted until verifier/policy says otherwise.
- [ ] Repeated ingestion is idempotent.

## Verification

- Golden tests across versions and malicious inputs.
- Cross-check subjects with SPDX artifact identities.

## Documentation impact

Documents SLSA/in-toto subset and trust limits.

## Research or measurement impact

Adds complete/incomplete provenance cases.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Conflating parsed, signed, and trusted would undermine the project.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_16
      ;;
    workflow-run-ingestion)
      cat >"$file" <<'ALO_ISSUE_17'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=workflow-run-ingestion -->

## Context

Workflow runs bridge declared workflow and build execution but require network access and credentials. Remote metadata must be source-scoped, rate-bounded, and privacy-aware.

## Goal

Ingest selected metadata for one explicit GitHub repository/run and link it to commit and workflow definition evidence.

## Scope

- Run ID and attempt; workflow path; head SHA; event; status/conclusion; timestamps; source API metadata; offline replay fixtures; bounded retries/rate handling.

## Non-goals

- Download logs/artifacts by default, enumerate accounts, trigger workflows, infer produced artifacts without evidence, or support other CI providers.

## Design constraints

- Network collector is opt-in.
- Tokens/headers are never persisted or printed.
- Run identity is provider/repository scoped.

## Tasks

- [ ] Define required API fields/permissions.
- [ ] Implement explicit run fetch and normalization.
- [ ] Implement redaction, rate-limit, retry, and fixture replay.
- [ ] Record source response digest/adapter version.

## Acceptance criteria

- [ ] Local-only commands make no network call.
- [ ] Missing/invalid credentials return structured redacted errors.
- [ ] Run attempt semantics are preserved.
- [ ] Fixture replay normalizes identically to live response.

## Verification

- Mock API tests: success, rate limit, not found, denied, retry exhaustion, malformed response, and redaction.

## Documentation impact

Documents permissions, privacy, and network behavior.

## Research or measurement impact

Provides build-run links for end-to-end lineage.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Provider API drift requires raw response digest and adapter-version traceability.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_17
      ;;
    verification-status)
      cat >"$file" <<'ALO_ISSUE_18'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=verification-status -->

## Context

A boolean verified flag cannot express unsupported algorithms, missing bytes, mismatches, partial checks, or untrusted signer/builder context.

## Goal

Implement append-only verification records and deterministic local digest/provenance consistency checks.

## Scope

- Statuses: unverified, verified, failed, unsupported, indeterminate; verifier identity/version; exact input; trust/policy context reference; reason codes; aggregate command result.

## Non-goals

- General signature/key management, transparency-log verification, Sigstore policy engine, vulnerability validation, or compliance verdict.

## Design constraints

- Verified digest does not imply safe artifact or trusted builder.
- Checks never mutate source evidence.
- Required and optional checks are explicit.

## Tasks

- [ ] Define verifier boundary/status aggregation.
- [ ] Implement supported digest checks and file safety.
- [ ] Implement provenance subject consistency.
- [ ] Add tamper/missing/unsupported fixtures.

## Acceptance criteria

- [ ] Each result states exactly what was and was not checked.
- [ ] Unsupported is not success or failure.
- [ ] Digest mismatch records failed verification without rewriting claims.
- [ ] Aggregate cannot hide failed/indeterminate required checks.

## Verification

- Unit/property tests for digest normalization and aggregation.
- Golden end-to-end matching/mismatch/missing/unsupported cases.

## Documentation impact

Updates evidence model, threat model, and CLI verify contract.

## Research or measurement impact

Defines evidence-trust variables.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Aggregation rules can conceal partial failure unless explicit.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_18
      ;;
    conflict-supersession)
      cat >"$file" <<'ALO_ISSUE_19'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=conflict-supersession -->

## Context

Collectors can disagree about source, time, subject, or relationship. ALO must retain disagreement and avoid choosing a winner without policy.

## Goal

Detect defined contradiction classes, persist conflict groups, expose ambiguity, and support explicit superseding corrections.

## Scope

- Duplicate versus corroboration versus contradiction; conflict groups; supersedes links; active-view derivation; query/report annotations; confidence vocabulary.

## Non-goals

- Automatic truth resolution, ML confidence, source reputation service, or deleting superseded evidence.

## Design constraints

- Conflicts are symmetric; supersession is directional.
- Time-varying non-overlapping observations are not conflicts.
- Confidence is qualitative and not averaged.

## Tasks

- [ ] Define contradiction rules per predicate.
- [ ] Implement persistence/query exposure.
- [ ] Add overlapping/non-overlapping/conflict/correction fixtures.
- [ ] Document confidence semantics.

## Acceptance criteria

- [ ] Contradictory artifact-to-commit claims are both retained and linked.
- [ ] Supersession preserves prior evidence.
- [ ] Trace/report visibly marks unresolved conflict.
- [ ] Repeated conflict ingestion is idempotent.

## Verification

- Golden conflict cases.
- Property tests for conflict symmetry and deduplication.
- Migration tests preserve links.

## Documentation impact

Updates evidence and reporting semantics.

## Research or measurement impact

Enables incomplete/conflicting evidence experiments.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Over-eager conflict detection can misclassify legitimate temporal change.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_19
      ;;
    human-markdown-report)
      cat >"$file" <<'ALO_ISSUE_20'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=human-markdown-report -->

## Context

JSON is the automation contract, but the first user needs an inspectable explanation showing lineage, source, verification, conflict, uncertainty, and truncation.

## Goal

Render terminal and Markdown reports from the same query result model without changing semantics.

## Scope

- Tree/path view; identity short forms; source/evidence references; verification summary; conflict/ambiguity/truncation warnings; no-color fallback; path/secret redaction.

## Non-goals

- Dashboard, HTML, graph visualization, SARIF, localization, or interactive TUI.

## Design constraints

- All formats represent the same semantic result.
- Markdown/terminal escape untrusted control text.
- No-color output is complete.

## Tasks

- [ ] Define renderer-independent result model.
- [ ] Implement terminal/no-color/Markdown renderers.
- [ ] Add deterministic golden outputs.
- [ ] Cross-check semantics against JSON.

## Acceptance criteria

- [ ] Ordering/headings are deterministic.
- [ ] No sensitive absolute paths unless explicitly requested.
- [ ] Terminal, Markdown, and JSON contain the same identities/edges/statuses.
- [ ] Warnings cannot be silently omitted.

## Verification

- Golden renderer tests.
- Cross-format semantic comparison.
- Control-character/Markdown injection tests.

## Documentation impact

Adds report format documentation and examples.

## Research or measurement impact

Provides materials for later investigation studies.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Renderer shortcuts can drift from the machine contract.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_20
      ;;
    e2e-release-fixture)
      cat >"$file" <<'ALO_ISSUE_21'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=e2e-release-fixture -->

## Context

Subsystems are only useful when a clean user workflow connects them. This is the integration gate, not a new design epic.

## Goal

Provide one reproducible offline fixture release and end-to-end commands demonstrating the v0.1 product thesis.

## Scope

- Empty temporary directory; DB init; Git/workflow/run/SPDX/SLSA ingestion; trace artifact to source; verify; JSON/text/Markdown; failure/conflict variant; rerun idempotency.

## Non-goals

- New formats, deployment evidence, policy engine, or release packaging.

## Design constraints

- CI uses offline workflow-run fixtures.
- Test begins from a clean directory.
- Expected output hashes are versioned.

## Tasks

- [ ] Assemble fixture bundle.
- [ ] Write end-to-end test and walkthrough.
- [ ] Verify second ingestion creates no duplicates.
- [ ] Add failed/indeterminate/conflict scenario.

## Acceptance criteria

- [ ] Clean checkout runs offline.
- [ ] Trace reaches source commit via supported evidence.
- [ ] Failure variant reports failed/indeterminate verification and conflict.
- [ ] DB integrity check passes after rerun.

## Verification

- End-to-end CI test.
- Golden JSON/Markdown hash comparison.
- Row/evidence counts and DB integrity assertions.

## Documentation impact

Adds first-use walkthrough.

## Research or measurement impact

Establishes the reference task/dataset.

__ALO_DEPENDENCIES__

## Risks and edge cases

- A generic integration failure must not hide collector-specific errors.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_21
      ;;
    security-policy)
      cat >"$file" <<'ALO_ISSUE_22'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=security-policy -->

## Context

Before public releases, users and contributors need a private reporting path, supported-version policy, disclosure process, and explicit secret-handling rules.

## Goal

Publish project-specific security operations aligned with the v0.1 threat model.

## Scope

- Supported versions; private reporting channel; triage/disclosure process; credential/log redaction; test-secret rules; dependency advisory handling; issue-template guidance.

## Non-goals

- Paid bug bounty, 24/7 support, formal SLA, or support for unreleased components.

## Design constraints

- No real credentials in fixtures, logs, examples, or issues.
- Sensitive reports are directed away from public issues.

## Tasks

- [ ] Write SECURITY.md and triage checklist.
- [ ] Define severity/release-blocking criteria.
- [ ] Audit examples/scripts for secret exposure.
- [ ] Document best-effort response expectations.

## Acceptance criteria

- [ ] Reporter can identify private channel and required information.
- [ ] Supported/out-of-scope versions are explicit.
- [ ] Token/path/header redaction rules are concrete.
- [ ] High-severity parser/storage cases map to release response.

## Verification

- Tabletop: malicious SPDX parser crash and accidental GitHub token disclosure.
- Manual policy cross-check against threat model.

## Documentation impact

Creates SECURITY.md or approved equivalent.

## Research or measurement impact

Defines ethical handling of adversarial fixtures.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Unrealistic response promises create operational debt.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_22
      ;;
    ci-dependency-gates)
      cat >"$file" <<'ALO_ISSUE_23'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=ci-dependency-gates -->

## Context

A production-ready release needs repeatable gates for formatting, static analysis, tests, migrations, fixtures, dependencies, and release metadata.

## Goal

Create minimal CI workflows and a dependency policy that protect the v0.1 contract without paid infrastructure.

## Scope

- Format/vet/static checks; unit/integration/e2e/migration/golden tests; fixture hash check; race tests where supported; dependency review; pinned actions; least permissions; fast versus deep checks.

## Non-goals

- Huge OS/Go matrix, auto-merge, AI review, or custom vulnerability database.

## Design constraints

- Workflow permissions default read-only.
- External actions are pinned to immutable commits.
- PR tests require no repository secrets.

## Tasks

- [ ] Define required checks and branch-protection recommendation.
- [ ] Implement CI gates.
- [ ] Document dependency add/update/remove criteria and cadence.
- [ ] Audit cache/artifact trust.

## Acceptance criteria

- [ ] Failure in migration, fixture hash, golden output, required test, or static check blocks merge/release.
- [ ] Permissions are explicit.
- [ ] Direct dependencies need justification.
- [ ] No secret-dependent pull_request workflow.

## Verification

- Review effective permissions/action pins.
- Trigger representative safe failures.
- Dependency policy walkthrough.

## Documentation impact

Updates production and contributor/release docs.

## Research or measurement impact

Makes fixture/benchmark checks reproducible in CI.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Slow/noisy gates can encourage bypass; separate fast and scheduled/deep work.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_23
      ;;
    fuzz-property-tests)
      cat >"$file" <<'ALO_ISSUE_24'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=fuzz-property-tests -->

## Context

Parsers and canonicalization process hostile, high-combinatoric inputs that example tests cannot cover.

## Goal

Add bounded fuzz targets and algebraic/property tests for all v0.1 parsers and identity/evidence invariants.

## Scope

- Workflow YAML; SPDX/SLSA JSON; digest/URI/path normalization; evidence ID stability; deduplication; conflict symmetry; canonicalization idempotence; seeded regression corpus.

## Non-goals

- Fuzz network APIs, future kernel/plugin code, or claim exhaustive security.

## Design constraints

- Fuzz runs enforce time/memory/input budgets.
- Minimized crashes become reviewed regression fixtures.
- No secret or unsafe executable samples.

## Tasks

- [ ] Define properties/oracles.
- [ ] Add short CI fuzz smoke and longer local/scheduled procedure.
- [ ] Seed from fixture corpus.
- [ ] Document triage and retention.

## Acceptance criteria

- [ ] Accepted identities satisfy canonicalize(canonicalize(x)) = canonicalize(x).
- [ ] Parsers do not panic.
- [ ] Over-limit inputs return classified errors.
- [ ] Each parser has seeded regression cases.

## Verification

- Fixed-duration CI fuzz smoke.
- Longer local campaign with command, duration, seed, environment, and findings report.

## Documentation impact

Documents targets, budgets, and triage.

## Research or measurement impact

Adds adversarial corpus and validity evidence.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Fuzzing without semantic/resource oracles can miss denial-of-service behavior.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_24
      ;;
    bench-resource-budgets)
      cat >"$file" <<'ALO_ISSUE_25'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=bench-resource-budgets -->

## Context

ALO must run on one developer machine. Performance claims require raw results, environment metadata, variance, and explicit budgets.

## Goal

Create deterministic 10k/100k evidence benchmarks for ingestion, storage, trace, output, rejection, backup, CPU, and memory.

## Scope

- Cold/warm trace latency; insertion throughput; peak RSS; DB bytes/record; output size; parser boundary rejection time; raw result format; regression thresholds.

## Non-goals

- Internet-scale claims, PostgreSQL/eBPF/Kubernetes benchmarks, or product comparison against GUAC.

## Design constraints

- Offline and reproducible.
- Dataset seed/version/hash retained.
- Budgets approved before final v0.1 candidate.
- Negative results reported.

## Tasks

- [ ] Define hypotheses/metrics/baselines/budgets.
- [ ] Implement deterministic generator.
- [ ] Run repeated measurements.
- [ ] Publish raw data, variance, environment, and limitations.

## Acceptance criteria

- [ ] Every metric has units, dataset, command, environment, repetitions, and budget.
- [ ] Raw machine-readable data is stored.
- [ ] Noise versus release-blocking regression policy is defined.
- [ ] Clean checkout reproduces dataset hashes.

## Verification

- Repeat runs and variance analysis.
- Independent fixture/generator hash check.
- Release-candidate budget comparison.

## Documentation impact

Creates initial benchmark report and updates production baseline.

## Research or measurement impact

Evaluates identity/query/storage overhead.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Single-machine results have limited external validity.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_25
      ;;
    backup-recovery)
      cat >"$file" <<'ALO_ISSUE_26'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=backup-recovery -->

## Context

The local evidence database accumulates valuable history. Users need a safe supported workflow for protection and recovery from interrupted writes, bad migrations, or corruption.

## Goal

Implement tested backup/restore/integrity behavior and a conservative recovery runbook.

## Scope

- Consistent backup including WAL state; backup metadata; restore to new path; integrity checks; corrupt DB refusal; interrupted backup fixtures; preservation of corrupt originals.

## Non-goals

- Cloud backup, point-in-time recovery, arbitrary auto-repair, or replication.

## Design constraints

- Restore never overwrites without explicit flag.
- Normal commands do not modify a corrupt DB.
- Recovery defaults to preservation and last known good backup.

## Tasks

- [ ] Choose/test backup method.
- [ ] Implement DB check/backup/restore workflow.
- [ ] Add corruption/interruption fixtures.
- [ ] Write operator runbook and data-loss boundaries.

## Acceptance criteria

- [ ] Restored DB yields equivalent trace/report semantics.
- [ ] Restore validates metadata/schema before use.
- [ ] Corruption is detected and source preserved.
- [ ] Runbook states when recovery is impossible.

## Verification

- End-to-end backup/restore.
- Safe injected corruption cases for header/page/WAL.
- Semantic/hash comparison after restore.

## Documentation impact

Creates corruption and recovery runbook.

## Research or measurement impact

Protects benchmark datasets and longitudinal histories.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Misleading repair claims can destroy evidence.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_26
      ;;
    release-dogfooding)
      cat >"$file" <<'ALO_ISSUE_27'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=release-dogfooding -->

## Context

ALO should explain the origin of its own binaries. Dogfooding must be exact and must not claim stronger provenance or reproducibility than the pipeline provides.

## Goal

Design and implement v0.1 release artifacts, integrity metadata, signing, independent verification instructions, and an ingestible ALO evidence bundle.

## Scope

- Versioned archives/binaries for approved targets; SHA-256 checksums; SPDX SBOM; build provenance; signature or signed manifest; release manifest; self-lineage evidence bundle.

## Non-goals

- Universal bit-reproducibility guarantee, private PKI, package-manager publishing, or secret-based signing requirement.

## Design constraints

- Every metadata object refers to exact artifact digest.
- CI permissions/actions are hardened.
- Signer issuer/subject/trust assumptions documented.

## Tasks

- [ ] Define artifact naming/manifest.
- [ ] Generate release metadata in candidate workflow.
- [ ] Verify independently and with ALO.
- [ ] Add tamper variants.
- [ ] Document reproducibility limitations.

## Acceptance criteria

- [ ] Checksums cover every artifact.
- [ ] SBOM/provenance/signature bind exact digests.
- [ ] Independent verification commands are documented.
- [ ] ALO ingests/traces its own bundle without special-case model fields.

## Verification

- Local release-candidate workflow without publishing release.
- Artifact/checksum/SBOM/provenance/signature tamper tests.

## Documentation impact

Creates release integrity and trust docs.

## Research or measurement impact

Creates a real longitudinal self-lineage dataset.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Keyless signing identity/trust can be misunderstood unless issuer and policy are explicit.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_27
      ;;
    upgrade-release-verification)
      cat >"$file" <<'ALO_ISSUE_28'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=upgrade-release-verification -->

## Context

A release is not production-ready if users cannot install, upgrade, verify, and recover predictably from packaged artifacts.

## Goal

Create the v0.1 release checklist and automated smoke tests for clean install, migration, backup, rollback boundary, fixture workflow, and self-verification.

## Scope

- Supported OS/architecture matrix; packaged artifact install; DB init; historical DB upgrade; backup-before-upgrade; downgrade rules; integrity metadata verification; uninstall/data-retention notes.

## Non-goals

- Automatic updater, LTS policy, package-manager publishing, or zero-downtime server upgrade.

## Design constraints

- No destructive downgrade.
- Smoke tests consume packaged immutable artifacts, not working-tree binaries.
- Failed self-verification blocks release.

## Tasks

- [ ] Write release checklist/runbook.
- [ ] Automate supported-target smoke test.
- [ ] Test one forward migration and restore-based rollback.
- [ ] Verify complete fixture and self-evidence bundle.

## Acceptance criteria

- [ ] User can determine downgrade safety before attempting it.
- [ ] Smoke covers install, verify, migrate, fixture workflow, backup, restore, and deterministic reports.
- [ ] Migration/self-lineage failure blocks release.

## Verification

- Run smoke tests against local packaged candidates.
- Cross-check checklist against threat model and production baseline.

## Documentation impact

Creates upgrade, rollback, and release verification docs.

## Research or measurement impact

Captures environment/artifact metadata for reproducibility.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Source-tree tests can pass while packaged artifacts fail.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_28
      ;;
    oci-adapter)
      cat >"$file" <<'ALO_ISSUE_29'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=oci-adapter -->

## Context

Deployment correlation requires a stable content-addressed OCI identity before Docker-specific observations. Tags are mutable and cannot be the core identity.

## Goal

Ingest bounded local OCI manifest/config metadata by digest and relate it to generic artifact/provenance evidence.

## Scope

- Manifest/index/config digest identities; media type; platform; annotations as observations; explicit local archive or engine metadata source; tag aliases with source/time.

## Non-goals

- Registry service, image pull, vulnerability scan, layer extraction, signature policy, or Kubernetes image resolution.

## Design constraints

- Digest is identity; tag is a mutable observation.
- No layer execution or unbounded extraction.
- Index and platform-manifest digests remain distinct.

## Tasks

- [ ] Define supported OCI subset.
- [ ] Implement bounded local metadata ingestion.
- [ ] Add multi-platform, invalid digest, missing config, and tag-movement fixtures.
- [ ] Map to generic artifact identity.

## Acceptance criteria

- [ ] Same digest from two sources resolves to one OCI identity.
- [ ] Tag changes create time-scoped observations without rewriting history.
- [ ] Unsupported media types are explicit.
- [ ] No layer content is executed/extracted by default.

## Verification

- Golden OCI fixtures.
- Cross-source identity tests.
- Boundary/tamper tests for digest and metadata size.

## Documentation impact

Updates identity and collector compatibility docs.

## Research or measurement impact

Adds source-to-deployment identity cases.

__ALO_DEPENDENCIES__

## Risks and edge cases

- OCI/Docker sources may disagree; source/time/conflict must be preserved.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_29
      ;;
    docker-snapshots)
      cat >"$file" <<'ALO_ISSUE_30'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=docker-snapshots -->

## Context

The smallest deployment layer is a point-in-time read-only local Docker snapshot, not a daemon, Kubernetes operator, or live telemetry collector.

## Goal

Capture bounded container/deployment observations and link them to immutable OCI image digest identities.

## Scope

- Explicit local Docker endpoint; source-scoped container ID; image digest; name/labels; created/started/status timestamps; selected configuration fingerprints; snapshot identity/time; redaction.

## Non-goals

- Exec into containers, collect logs, store environment/secrets, enforce policy, continuous monitoring, or support Kubernetes/Podman initially.

## Design constraints

- Collector uses read endpoints only.
- Sensitive environment/mount values are excluded/redacted by default.
- Collection time and event time are separate.

## Tasks

- [ ] Define snapshot/privacy schema.
- [ ] Implement one-shot read-only collection.
- [ ] Add mocked deterministic engine fixtures.
- [ ] Audit API endpoints and permissions.

## Acceptance criteria

- [ ] Snapshot links container observation to digest when available.
- [ ] Tag-only/missing digest is ambiguous, not guessed.
- [ ] No mutation endpoints are called.
- [ ] Secrets/environment values are not stored by default.

## Verification

- Mock API success/denied/malformed tests.
- Manual endpoint audit.
- Golden privacy/redaction output.

## Documentation impact

Documents Docker permissions, fields, and privacy defaults.

## Research or measurement impact

Provides declared deployment observations without runtime claims.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Docker socket access is highly privileged even when using read endpoints.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_30
      ;;
    deployment-trace-diff)
      cat >"$file" <<'ALO_ISSUE_31'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=deployment-trace-diff -->

## Context

v0.2 must explain what a deployment snapshot points to and what changed without claiming observed runtime behavior or causality.

## Goal

Extend trace/report semantics for snapshot→container→image→provenance→workflow run→commit and add deterministic point-in-time/before-after diff.

## Scope

- Valid-time filter; added/removed/expired/changed alias/unresolved relationships; supporting evidence/source times; conflict/ambiguity/truncation; bounded output.

## Non-goals

- Incident root cause, live drift alert, syscall/network behavior, application telemetry, or policy enforcement.

## Design constraints

- Snapshot observations are source/time scoped.
- Diff reports evidence change, not cause.
- Event and collection times remain explicit.

## Tasks

- [ ] Define temporal query/diff model.
- [ ] Implement correlation paths.
- [ ] Add mutable-tag, missing-time, overlap, conflict, and supersession cases.
- [ ] Update all renderers.

## Acceptance criteria

- [ ] Query at T excludes relationships invalid at T.
- [ ] Diff distinguishes added, removed/expired, alias-changed, and unresolved.
- [ ] Every result links supporting evidence/time.
- [ ] Output never labels snapshot as runtime proof.

## Verification

- Golden temporal/diff tests.
- End-to-end Docker fixture trace.
- Cross-format semantic comparison.

## Documentation impact

Updates temporal evidence, CLI, and limitations docs.

## Research or measurement impact

Creates measurable source-to-deployment correlation task.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Collection time can be mistaken for event time.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_31
      ;;
    deployment-benchmark)
      cat >"$file" <<'ALO_ISSUE_32'
<!-- alo-bootstrap:managed-begin -->
<!-- alo-bootstrap:key=deployment-benchmark -->

## Context

Deployment correlation is a research result only if evaluated against independent ground truth with raw data and threats to validity.

## Goal

Measure identity-link accuracy, unresolved/false-link rate, temporal accuracy, query effort, latency, memory, and storage on reproducible local Docker scenarios.

## Scope

- Digest-correct, tag-moved, missing-digest, conflicting provenance, delayed snapshot, and interval-overlap scenarios; precision/recall/false-link/ambiguity metrics; raw data; repeated runs.

## Non-goals

- Incident root-cause claim, enterprise-tool comparison, Kubernetes benchmark, or generalization beyond tested scenarios.

## Design constraints

- Ground truth generated independently of ALO output.
- Seeds, scenario manifests, environment, and hashes are versioned.
- False links reported separately from unresolved.

## Tasks

- [ ] Pre-register hypotheses/baselines/metrics.
- [ ] Create deterministic scenario generator/manifest.
- [ ] Run repeated measurements.
- [ ] Publish raw results, variance, and limitations.

## Acceptance criteria

- [ ] Report contains hypotheses, variables, baselines, dataset, repetitions, raw results, environment, and threats.
- [ ] All scenarios reproduce offline.
- [ ] Ground truth check is independent.
- [ ] No causal/runtime claim is made.

## Verification

- Independent manifest/ground-truth review.
- Repeat-run variance analysis.
- Hash raw results and scenario corpus.

## Documentation impact

Creates the first deployment-correlation research report.

## Research or measurement impact

Evaluates identity resolution and temporal semantics at deployment boundary.

__ALO_DEPENDENCIES__

## Risks and edge cases

- Synthetic scenarios may overstate accuracy; limitations must be prominent.

## Definition of done

- All acceptance criteria are demonstrated with the specified verification evidence.
- Required tests, fixtures, or documentation are committed in the same change or an explicitly linked prerequisite.
- No out-of-scope subsystem or speculative abstraction is introduced.
- Review confirms compatibility with the product contract, evidence invariants, threat model, and migration policy.

<!-- alo-bootstrap:managed-end -->
ALO_ISSUE_32
      ;;
    *)
      die "unknown issue key '$key'"
      ;;
  esac
}

declare -A EXISTING_LABEL_COLOR=()
declare -A EXISTING_LABEL_DESCRIPTION=()
label_snapshot="$TMP_DIR/labels.tsv"
gh label list --repo "$REPO" --limit 1000 \
  --json name,color,description \
  --jq '.[] | [.name, .color, (.description // "")] | @tsv' >"$label_snapshot"
while IFS=$'\t' read -r name color description; do
  [[ -n "$name" ]] || continue
  EXISTING_LABEL_COLOR["$name"]="$color"
  EXISTING_LABEL_DESCRIPTION["$name"]="$description"
done <"$label_snapshot"

declare -A EXISTING_MILESTONE_NUMBER=()
declare -A EXISTING_MILESTONE_DESCRIPTION=()
milestone_snapshot="$TMP_DIR/milestones.tsv"
gh api --paginate "repos/$REPO/milestones?state=all&per_page=100" \
  --jq '.[] | [.title, (.number | tostring), (.description // "")] | @tsv' >"$milestone_snapshot"
while IFS=$'\t' read -r title number description; do
  [[ -n "$title" ]] || continue
  if [[ -n "${EXISTING_MILESTONE_NUMBER[$title]+x}" ]]; then
    die "duplicate existing milestone title '$title'"
  fi
  EXISTING_MILESTONE_NUMBER["$title"]="$number"
  EXISTING_MILESTONE_DESCRIPTION["$title"]="$description"
done <"$milestone_snapshot"

declare -A ISSUE_NUMBERS=()
issue_snapshot="$TMP_DIR/issues.tsv"
gh api --paginate "repos/$REPO/issues?state=all&per_page=100" \
  --jq '.[] | select(.pull_request == null) | (.body // "") as $body | ($body | match("<!-- alo-bootstrap:key=([a-z0-9-]+) -->"; "g").captures[0].string) as $key | [$key, (.number | tostring)] | @tsv' >"$issue_snapshot"
while IFS=$'\t' read -r key number; do
  [[ -n "$key" ]] || continue
  if [[ -n "${ISSUE_NUMBERS[$key]+x}" ]]; then
    die "duplicate bootstrap marker for issue key '$key'"
  fi
  ISSUE_NUMBERS["$key"]="$number"
done <"$issue_snapshot"

reconcile_labels() {
  local name expected_color expected_description current_color current_description
  for name in "${LABEL_NAMES[@]}"; do
    expected_color="${LABEL_COLOR[$name]}"
    expected_description="${LABEL_DESCRIPTION[$name]}"

    if [[ -z "${EXISTING_LABEL_COLOR[$name]+x}" ]]; then
      ((LABEL_CREATE+=1))
      if [[ "$APPLY" == true ]]; then
        log "CREATE label '$name'"
        gh label create "$name" --repo "$REPO" \
          --color "$expected_color" --description "$expected_description" >/dev/null
      else
        log "WOULD CREATE label '$name' color=#$expected_color"
      fi
      continue
    fi

    current_color="${EXISTING_LABEL_COLOR[$name]^^}"
    current_description="${EXISTING_LABEL_DESCRIPTION[$name]}"
    if [[ "$current_color" == "${expected_color^^}" && "$current_description" == "$expected_description" ]]; then
      ((LABEL_SKIP+=1))
      log "SKIP label '$name' (already reconciled)"
    else
      ((LABEL_UPDATE+=1))
      if [[ "$APPLY" == true ]]; then
        log "RECONCILE label '$name'"
        gh label create "$name" --repo "$REPO" \
          --color "$expected_color" --description "$expected_description" --force >/dev/null
      else
        log "WOULD RECONCILE label '$name' color=#$expected_color"
      fi
    fi
  done
}

reconcile_milestones() {
  local title expected_description number current_description
  for title in "${MILESTONE_TITLES[@]}"; do
    expected_description="${MILESTONE_DESCRIPTION[$title]}"

    if [[ -z "${EXISTING_MILESTONE_NUMBER[$title]+x}" ]]; then
      ((MILESTONE_CREATE+=1))
      if [[ "$APPLY" == true ]]; then
        log "CREATE milestone '$title'"
        number="$(gh api -X POST "repos/$REPO/milestones" \
          -f title="$title" -f description="$expected_description" --jq '.number')"
        [[ "$number" =~ ^[0-9]+$ ]] || die "could not capture milestone number for '$title'"
        EXISTING_MILESTONE_NUMBER["$title"]="$number"
        EXISTING_MILESTONE_DESCRIPTION["$title"]="$expected_description"
      else
        log "WOULD CREATE milestone '$title'"
      fi
      continue
    fi

    number="${EXISTING_MILESTONE_NUMBER[$title]}"
    current_description="${EXISTING_MILESTONE_DESCRIPTION[$title]}"
    if [[ "$current_description" == "$expected_description" ]]; then
      ((MILESTONE_SKIP+=1))
      log "SKIP milestone '$title' (#$number)"
    elif [[ "$UPDATE_EXISTING" == true ]]; then
      ((MILESTONE_UPDATE+=1))
      if [[ "$APPLY" == true ]]; then
        log "RECONCILE milestone '$title' (#$number)"
        gh api -X PATCH "repos/$REPO/milestones/$number" \
          -f title="$title" -f description="$expected_description" >/dev/null
      else
        log "WOULD RECONCILE milestone '$title' (#$number)"
      fi
    else
      ((MILESTONE_SKIP+=1))
      log "SKIP milestone '$title' (#$number; description differs; use --update-existing)"
    fi
  done
}

write_dependency_section() {
  local key="$1"
  local file="$2"
  local dep_string dep number
  dep_string="${ISSUE_DEPS[$key]}"

  {
    printf '## Dependencies\n\n'
    if [[ -z "$dep_string" ]]; then
      printf '%s\n' '- None.'
    else
      IFS='|' read -r -a deps <<<"$dep_string"
      for dep in "${deps[@]}"; do
        if [[ -n "${ISSUE_NUMBERS[$dep]+x}" ]]; then
          number="${ISSUE_NUMBERS[$dep]}"
          printf -- '- Depends on #%s (`%s`).\n' "$number" "$dep"
        else
          printf -- '- Depends on bootstrap issue `%s`; its number is resolved in apply mode.\n' "$dep"
        fi
      done
    fi
  } >"$file"
}

render_issue_body() {
  local key="$1"
  local output="$2"
  local template_file="$TMP_DIR/${key}.template.md"
  local dependency_file="$TMP_DIR/${key}.dependencies.md"

  issue_template "$key" "$template_file"
  write_dependency_section "$key" "$dependency_file"

  awk -v depfile="$dependency_file" '
    $0 == "__ALO_DEPENDENCIES__" {
      while ((getline line < depfile) > 0) {
        print line
      }
      close(depfile)
      next
    }
    { print }
  ' "$template_file" >"$output"
}

merge_managed_body() {
  local current_file="$1"
  local desired_file="$2"
  local output_file="$3"
  local line state=before found_begin=false found_end=false

  : >"$output_file"
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$state" == "before" && "$line" == "<!-- alo-bootstrap:managed-begin -->" ]]; then
      found_begin=true
      state=managed
      cat "$desired_file" >>"$output_file"
      continue
    fi

    if [[ "$state" == "managed" ]]; then
      if [[ "$line" == "<!-- alo-bootstrap:managed-end -->" ]]; then
        found_end=true
        state=after
      fi
      continue
    fi

    printf '%s\n' "$line" >>"$output_file"
  done <"$current_file"

  [[ "$found_begin" == true && "$found_end" == true ]] || return 1
}

reconcile_issues() {
  local key title milestone label_string body_file existing_number
  local url number current_file merged_file
  local -a issue_labels label_args deps

  for key in "${ISSUE_KEYS[@]}"; do
    title="${ISSUE_TITLE[$key]}"
    milestone="${ISSUE_MILESTONE[$key]}"
    label_string="${ISSUE_LABELS[$key]}"
    body_file="$TMP_DIR/${key}.body.md"
    render_issue_body "$key" "$body_file"

    IFS='|' read -r -a issue_labels <<<"$label_string"
    label_args=()
    for label in "${issue_labels[@]}"; do
      label_args+=(--label "$label")
    done

    if [[ -n "${ISSUE_NUMBERS[$key]+x}" ]]; then
      existing_number="${ISSUE_NUMBERS[$key]}"
      if [[ "$UPDATE_EXISTING" != true ]]; then
        ((ISSUE_SKIP+=1))
        log "SKIP issue '$key' (#$existing_number)"
        continue
      fi

      ((ISSUE_UPDATE+=1))
      if [[ "$APPLY" == true ]]; then
        current_file="$TMP_DIR/${key}.current.md"
        merged_file="$TMP_DIR/${key}.merged.md"
        gh issue view "$existing_number" --repo "$REPO" --json body --jq '.body // ""' >"$current_file"
        if ! merge_managed_body "$current_file" "$body_file" "$merged_file"; then
          die "issue #$existing_number has the stable marker but no complete managed block; refusing to overwrite it"
        fi

        log "RECONCILE issue '$key' (#$existing_number); preserving text outside managed block and all comments"
        gh issue edit "$existing_number" --repo "$REPO" \
          --title "$title" --body-file "$merged_file" --milestone "$milestone" \
          "${label_args[@]}" >/dev/null
      else
        log "WOULD RECONCILE issue '$key' (#$existing_number); managed block only"
      fi
      continue
    fi

    ((ISSUE_CREATE+=1))
    if [[ "$APPLY" == true ]]; then
      log "CREATE issue '$key' in '$milestone'"
      url="$(gh issue create --repo "$REPO" \
        --title "$title" --body-file "$body_file" --milestone "$milestone" \
        "${label_args[@]}")"
      number="${url##*/}"
      [[ "$number" =~ ^[0-9]+$ ]] || die "could not capture issue number from: $url"
      ISSUE_NUMBERS["$key"]="$number"
      log "CREATED issue '$key' as #$number"
    else
      log "WOULD CREATE issue '$key' in '$milestone' labels=[$label_string]"
    fi
  done
}

reconcile_labels
reconcile_milestones
reconcile_issues

printf '\n[alo-bootstrap] Summary for %s (%s)\n' "$REPO" "$([[ "$APPLY" == true ]] && printf APPLY || printf DRY-RUN)"
printf '  labels:     create=%d update=%d skip=%d\n' "$LABEL_CREATE" "$LABEL_UPDATE" "$LABEL_SKIP"
printf '  milestones: create=%d update=%d skip=%d\n' "$MILESTONE_CREATE" "$MILESTONE_UPDATE" "$MILESTONE_SKIP"
printf '  issues:      create=%d update=%d skip=%d\n' "$ISSUE_CREATE" "$ISSUE_UPDATE" "$ISSUE_SKIP"

if [[ "$APPLY" == false ]]; then
  printf '  No GitHub mutations were performed. Re-run with --apply after review.\n'
fi
