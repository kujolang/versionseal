# VersionSeal repository hardening — 2026-09-22

## Repository and scope

- Repository: `kujolang/versionseal`, branch `main`.
- Starting SHA: `4c84f2607f60011c5800790347d7479ec07554e9` (clean).
- Ending implementation SHA: `5141246dc52b728944c1df86af0d35929bfa9658`; the following documentation-only commit contains this report and receipts (its SHA is in Git history and the final delivery receipt).
- Purpose: local immutable exact-manifest approval decisions and requests, revocation/expiration records, bounded inspection/export, and explicit opt-in verification/policy/replication library adapters.
- Runtime tested: local Kujo 1.4.0. CI retains pinned runtime `5059695d14d6726bc17fef55e0b95511624967cf`; its atomic writer was inspected and supports exclusive no-replace publication. No new runtime/development packages.
- Integrations: PressWire reads 1.0.0-contract approval records from 0.1.0/0.2.0 tools and checks actor/checksum/action/destination scope. No hosted identity, network requests, model/provider calls, MCP server, database, or cache exists here.

All tracked implementation, test, fixture, schema, launcher, validation, workflow, and documentation files were inspected. The hot paths are initialization, canonical ID construction, bounded artifact hashing, record/history writes, and sorted directory queries. Kujo owns filesystem/JSON/crypto primitives; shell scripts only launch/gate Kujo. No sibling repository was modified.

## Baseline

`bash scripts/validate.sh` passed: 40 assertions, entrypoint check, JSON parsing, CLI smoke, 32 distinct-ID writes, foreign-runtime checks, badge/ignore checks, and whitespace. See `baseline.txt`. No existing gate failed, but it did not check same-ID contention, missing flag values, actual quickstart approval, dry-run state creation, calendar validity, or incomplete scans.

A new 12-assertion regression suite against the starting implementation reported **1 pass / 11 failures** (`regressions-before.txt`). The failures independently covered dry-run writes, calendar/leap dates, three fractional expiry comparisons, missing flag values, stored actor/secret checks, config types, and unknown direct-dispatch commands. An initial test-authoring experiment used unsupported nested assignments; that test was corrected before collecting the retained baseline. This is not reported as a product defect.

The stronger contention harness also passed once against the starting version (`contention-before.txt`): the lock defect is supported by the runtime's idempotent `create_dir_all` semantics, not claimed to have reproduced in that nondeterministic run.

## Findings

| ID | Priority | Area | Finding and evidence | Action | Status |
|---|---|---|---|---|---|
| VS-01 | P0 | Integrity/concurrency | `acquire_lock` checked existence then used idempotent recursive `create_dir`; record/history publication used overwrite=true | Exclusive atomic lock file; no-replace records/history/metadata; all worker statuses checked | Fixed |
| VS-02 | P1 | Side effects | `create_record` initialized state before input checks and dry-run return; baseline regression failed | Initialize only after successful validation and dry-run return | Fixed |
| VS-03 | P1 | Time | Regex accepted February 31; lexical comparison misordered fractional UTC instants | Gregorian day/leap validation and fixed-width nanosecond comparison | Fixed |
| VS-04 | P1 | Verification | Stored records omitted creation-time actor binding, secret checks, command/prefix and artifact shape checks | Revalidate those invariants while accepting 0.1.0/0.2.0 records | Fixed |
| VS-05 | P1 | Resources/completeness | Corrupt/type-filtered scans had no candidate budget; record-count cap permitted ~1 GiB retained text; incomplete scan could report valid/healthy | 1,000-candidate and 8 MiB retained-text page budgets, cursors, `scan_incomplete` | Fixed |
| VS-06 | P2 | CLI/config/errors | Missing values silently became defaults; config types unchecked; --version discarded --json; launcher contained developer path | Strict values/types, correct version parsing, portable resolution, structured exception envelope with stderr detail | Fixed |
| VS-07 | P2 | Adapter contracts | Non-integer quorum/versions and non-text actors accepted or errored inconsistently; equal-version divergent revocations ignored | Typed bounded policy data; replica types and revoke/revoke conflict checking | Fixed |
| VS-08 | P2 | Filesystem | Dangling metadata/output/managed-directory symlinks skipped existence-based checks; export had no-replace race | lstat helper, managed-directory rechecks, atomic no-replace export without --force | Fixed within local-storage model |
| VS-09 | P2 | Docs/schema | Quickstart had wrong actor, missing manifest and invalid checksum; schema excluded supported legacy records | Real offline manifest fixture, executable CLI smoke, corrected record/envelope docs/schema | Fixed |
| VS-10 | P2 | Crash recovery | Record and history are separate atomic writes; crash can leave orphan record/lock | Explicit operator boundary; no unsafe automatic lock stealing | Documented remaining boundary |
| VS-11 | Needs evidence | Directory scale | Runtime `list_dir` materializes all names before sorting; bounded record scanning does not bound name enumeration | Retain deterministic ordering; document need for measured runtime iterator/index work before redesign | Deferred |

## Changes implemented

**Storage and queries** (`src/storage.kujo`, `src/core.kujo`): atomic no-replace lock acquisition removes the check/create race. Stale legacy lock directories remain conflicts. Record serialization happens before acquisition, and cleanup failures are no longer silently discarded. Record/history/metadata creation does not replace a concurrent winner. Initialization validates existing metadata after a competing initializer wins. Export preserves replacement only behind `--force`. Tests cover history conflicts, clean retry, duplicate integrity, lock cleanup, dangling metadata symlinks, 32 distinct writers, 32 competing writers, and matching history checksums.

Query pages now retain at most 8 MiB of record text and inspect at most 1,000 candidate files. `next_after` and `scanned` expose work performed; filtering and corrupt safe-ID filenames can advance even on empty pages. A limit may conservatively report another candidate page that contains no matching records. Unsafe filenames cannot become safe cursors; repair corrupt names when continuation cannot advance. Whole-store verification/doctor refuses success on a truncated scan. Individual ID validation remains available. Tests exercise byte truncation, two-page completeness, corrupt-file budgets, and incomplete validation.

**Input and approval correctness** (`src/args.kujo`, `src/common.kujo`, `src/core.kujo`, `src/hardening.kujo`): dry-run has no state creation; calendar dates and fractional expiry are correct; missing/empty CLI values and schema-invalid config fail; direct dispatch rejects unknown commands. Stored validation checks actor/payload binding, secret fields, command/prefix, artifact shape, and existing exact bytes. Policy/replica adapters reject malformed bounded contracts. Unsupported generic abstractions were not introduced; one unused storage helper/import was removed.

**Operational contracts** (`bin/versionseal`, `schemas/record.schema.json`, fixtures, README, contracts, quickstart): preserve public record bytes and stable versions, document library-only adapters and verification limits, make runtime discovery portable, and run the actual documented approval/validate/export path in the gate. `scripts/validate.sh` includes all new suites and propagates its selected runtime into contention. Existing pinned actions and three-platform contention matrix remain in place.

## Performance and efficiency

A deterministic query fixture has 160 records, each containing 65,536 padding bytes. `scripts/query_fixture.kujo` recreates it; `scripts/query_benchmark.kujo` emits only a compact receipt. Measurements use the same local runtime, original source extracted under `.tmp/baseline`, and source-specific working directories. An initial wrong-working-directory run resolved current imports; it was discarded and the baseline rerun from its own directory.

| Dimension | Starting implementation | Hardened implementation |
|---|---:|---:|
| First-page records | 160 | 127, explicit continuation |
| Compact JSON result bytes | 10,497,325 | 8,332,302 |
| Maximum resident set (one observed run) | 45,473,792 bytes | 38,916,096 bytes |
| Wall time (one observed run) | 3.14 s | 2.73 s |
| User CPU (one observed run) | 0.73 s | 0.71 s |
| Corrupt safe-ID warnings from 1,100 files | 1,100 by source behavior | 1,000 + 100 next page, tested |
| Gate assertions | 40 | 71 |
| Package dependencies | Kujo only | Kujo only |

`query-before.txt` / `query-after.txt` retain raw measurements. These are **bounded-page observations, not equal-work speedup claims**: retrieving all records requires the second page. Timing is a single sample on a busy shared host; no throughput claim or flaky timing CI threshold is introduced. Stable byte/candidate limits and complete cursor traversal are the regression ratchets.

There are no model prompts, schemas for model tools, or context-replay machinery. No token counts are claimed. Existing `--output` exports preserve evidence on disk and return a receipt; normal data-query output remains compatible and detailed. Build/binary optimizations do not apply to this source-only package. Full directory-name allocation remains a documented limitation.

## Security and failure boundaries

Reviewed untrusted CLI/config/payloads, record IDs, stored JSON, artifact paths, output paths, actor binding, signature/policy functions, replication, and filesystem concurrency. Product source invokes no shell subprocesses or network endpoints. No credentials were used; RSA material is a public offline fixture. CI action/runtime revisions are pinned; no speculative dependency upgrades were made.

Fixed controls are integrity hardening in operator-controlled local storage. They do not make the tool a multi-tenant sandbox or authenticate an actor. Trusted parent directories may contain OS aliases (for example macOS `/tmp`); ancestor retargeting, hostile mutation between stat/read, power-loss durability, and transaction recovery are outside the present threat model. Terminal text failures retain diagnostics on stderr; expected failures use the stable JSON envelope. Unknown exceptions are not turned into success.

The Codex Security plugin failed to start: its workbench Python import raised `TypeError: unsupported operand type(s) for |: 'type' and 'NoneType'`. No registered scan, sealed scan report, independent security worker, or hosted security result is claimed. Source review and regression verification were completed directly for this engineering audit.

## Compatibility

- Public function signatures and CLI command names unchanged; additive `bytes` in storage load results and pagination metadata in query/export data.
- Record serialization and schema/contract/tool version values unchanged; record schema now documents required contract_version and accepts both supported tool versions.
- CLI fixes intentionally reject missing/empty values, invalid calendar timestamps, invalid stored bindings, malformed policy/config types, and incomplete whole-store scans. Existing valid records and fixtures pass.
- Config names and environment variables unchanged. `KUJO_BIN` still wins; launcher adds PATH and sibling-runtime discovery.
- Internal lock representation changes from directories to exclusive files. Do not run mixed old/new writers; upgrade writers together. Confirm no active writer before clearing old stale locks.
- PressWire's inspected record consumer needs no change. Callers that assumed a full first page must honor `truncated`/`next_after`; all evidence remains retrievable.

## Cross-repository follow-ups

No sibling change is required by this implementation. StoryDesk initially appeared to share the directory-lock defect, but reinspection during concurrent work found an exclusive owner-file fix in its current source at HEAD `e3707994b564c5b746493393c697424cc8503209`. The earlier observation is withdrawn; no unresolved StoryDesk issue or Signal is claimed. No sibling edits were made.

Optional tooling repair: Codex Security's selected Python must support its package annotations. This does not block VersionSeal runtime or tests. A runtime-level streaming directory iterator would require a separate compatibility/performance proposal; it is not required for this patch.

## Remaining work

- P0/P1: no known introduced regression or unresolved demonstrated defect within the supported local-operator boundary.
- P2: transactional crash recovery would need a specified record/history recovery protocol; current failure rollback is tested but crash atomicity is not claimed.
- Needs more evidence: huge directory-name sets, network filesystems, and adversarial concurrent filesystem mutation. Cross-platform CI is configured; only macOS was executed locally, and the pinned older runtime was inspected rather than rebuilt.
- P3/not worth changing: reformatting every dense module, replacing Kujo JSON/crypto, a cache without invalidation needs, cosmetic schema shrinkage, or new dependencies.

## Verification receipt

Executed from the repository unless stated otherwise:

```sh
bash scripts/validate.sh
/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo run tests/test.kujo
../kujo/target/release/kujo run tests/audit_test.kujo
../kujo/target/release/kujo run tests/security_test.kujo
../kujo/target/release/kujo run tests/storage_test.kujo
../kujo/target/release/kujo run tests/hardening_test.kujo
../kujo/target/release/kujo run tests/query_test.kujo
bash scripts/contention_benchmark.sh
sh -n bin/versionseal
bash -n scripts/validate.sh scripts/contention_benchmark.sh
../kujo/target/release/kujo check scripts/query_fixture.kujo
git diff --check
```

The gate also executes `kujo check versionseal.kujo`, the domain suite, every committed JSON parse check, help/version/doctor/approval/validate/export CLI paths, missing-value exit-code assertions, and repository policy gates. Final output is retained in `verification.txt`. Baseline regression failures were expected and retained separately; final suites pass.

Benchmark commands (replace `$REPO` with this absolute checkout and `$KUJO` with the absolute runtime):

```sh
# Fresh setup: kujo run scripts/query_fixture.kujo -- "$REPO/.tmp/benchmark-state"
# Copy scripts/query_benchmark.kujo into the baseline's scripts directory.
(cd "$REPO/.tmp/baseline" && /usr/bin/time -l "$KUJO" run scripts/query_benchmark.kujo -- "$REPO/.tmp/benchmark-state")
/usr/bin/time -l "$KUJO" run scripts/query_benchmark.kujo -- "$REPO/.tmp/benchmark-state"
```

No timing thresholds, remote CI pass, hosted vulnerability certification, or minimum-runtime execution beyond the local tested binary is implied.

## Follow-up

The [recovery and portability follow-up](recovery-followup.md) implements interrupted-write recovery, correct UTF-8 byte limits, and broader cross-platform verification. The limits above describe the original audit checkpoint; consult the follow-up for current recovery behavior and remaining runtime boundaries.
