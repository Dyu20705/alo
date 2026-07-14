# Bootstrap Script Validation

## Script

`scripts/bootstrap-github.sh`

## Static and local validation performed

| Check | Result |
|---|---|
| `bash -n scripts/bootstrap-github.sh` | Passed. |
| `scripts/bootstrap-github.sh --help` | Passed without requiring `gh` authentication or creating temporary state. |
| Default dry-run with a read-only mock `gh` | Passed; planned 24 label creates, 5 milestone creates, and 32 issue creates. The mock rejects every mutation command, so completion confirms the dry-run path did not attempt a mutation. |
| Read-snapshot failure | Passed; a simulated `gh label list` failure exited with the same non-zero status before reconciliation or mutation. |
| Idempotent dry-run with all managed objects present | Passed; skipped 24 labels, 5 milestones, and 32 stable-marker issues with zero planned creates/updates. |
| Malformed `--repo bad` | Rejected with non-zero exit before any `gh` call. |
| External `jq` dependency | None. All JSON filtering uses GitHub CLI `--jq`. |
| Stable issue identifiers | Every issue contains `<!-- alo-bootstrap:key=... -->`; lookup does not depend on title. |
| Dependency ordering | Passed programmatic check: every dependency key exists and points to an earlier issue. |
| Label discipline | Passed programmatic check: every issue has exactly one `type:*`, one or two `area:*`, exactly one `priority:*`, and only declared labels. |
| Temporary files and cleanup | Uses a mode-700 `mktemp -d` directory and an EXIT cleanup trap. |
| Apply-mode guard | All GitHub writes are inside explicit `--apply` branches. Apply mode was not executed. |
| ShellCheck | Not available in the execution environment; no ShellCheck result is claimed. |

## Safety behavior inspected

- Verifies Bash version, `gh`, `gh auth status`, repository resolution, archive state, and apply permission.
- Defaults to authenticated reads and dry-run output.
- Creates/reconciles labels by exact name.
- Reuses milestones by exact title and does not invent due dates.
- Finds issues by stable body marker; duplicate markers are a hard failure.
- Normal reruns skip matching issues.
- `--update-existing` replaces only the delimited bootstrap-managed block, preserving body text outside that block and all issue comments.
- Existing unrelated labels are not removed.
- No close, delete, branch, commit, push, pull-request, or token operation exists.
- Long issue bodies use temporary body files rather than shell-interpolated command arguments.

## Not validated without GitHub mutation

Apply mode was deliberately not executed. Therefore the following remain to be observed by the owner after reviewing a real dry-run:

1. GitHub's acceptance of all label colours/descriptions and milestone descriptions.
2. Exact issue numbers assigned by GitHub and resulting `#number` dependency links.
3. Repository-specific permission or ruleset behavior.
4. Existing labels, milestones, releases, tags, or branches that were not available through the inspection connector.
5. `gh` version compatibility on the owner's machine.

The required safe sequence is:

```bash
bash scripts/bootstrap-github.sh
bash scripts/bootstrap-github.sh --apply
```

Use `--update-existing` only after reviewing the managed-block behavior and dry-run output.
