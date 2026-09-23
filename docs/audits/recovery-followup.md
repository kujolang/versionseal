# Recovery and portability follow-up — 2026-09-22

Repository: `kujolang/versionseal`, branch `main`. Starting SHA: `d63bf309c0b10fd9b54f40747287f7c3910d69f3`. Implementation SHA: `9edd823ddc670328612c5a800963a414acace02d`. The following evidence-only documentation commit completes this receipt.

## Outcome and compatibility

Added explicit recovery for writes interrupted after a durable intent is published. It restores exactly the original record and history bytes, permits identical concurrent replay, refuses conflicting or unsafe destinations, and never steals a lock. Reads, doctor, and whole-store validation fail closed on incomplete intents, including crashes before a record exists. Recovery does not grant authority or create a replacement decision.

The original writer still owns lock release. Before publication it obtains a non-recoverable exclusive claim and rechecks duplicates; only then does it atomically install the recovery intent. This order prevents a stale duplicate contender from leaving a divergent journal over a previously committed record. After publishing the intent, errors preserve evidence rather than rolling back files that another recovery could already have completed.

The record, history, IDs, schema/contract/tool versions, existing command signatures, legacy 0.1.0 compatibility, and minimum runtime are unchanged. `recover --id [--dry-run]` and `pending_writes` diagnostic data are additive. Internal lock contents gain the bounded intent format. See [the protocol and recovery instructions](../recovery.md) before operating on a stale lock. Upgrade all writers together; older rollback-capable writers must not participate in recovery.

## Findings and changes

| ID | Priority | Evidence | Change | Status |
|---|---|---|---|---|
| RF-01 | P1 | Separate record/history atomic writes could leave an unexplained partial pair after process death | Exact-byte write intent, idempotent recovery, no replacement, pending-write validation | Implemented and tested |
| RF-02 | P1 | `len("Zoë💾")` counts characters; file size counts 8 UTF-8 bytes. Unicode recovery initially failed exact-size checks; an oversized Unicode record could be accepted then rejected on load | Compatible UTF-8 size helper for writes/exports; actual file-size receipts on load; tests for replay, export, and pre-lock bounds | Fixed |
| RF-03 | P2 | Prior cross-platform jobs exercised only contention; the earlier run actually succeeded on all three OSes | Full validation in the existing OS matrix; isolated relative scratch paths, cleanup, `.exe` resolution, real native symlink assertions, stable source/fixture line endings | Expanded; hosted results below |
| RF-04 | P1, cross-repo | Minimal scope reproducer prints `caller` in VM execution but `nested` with `--interpreter`; imported helpers can change caller-local destinations | Distinct transaction-helper locals and recovery tests in both modes; reproducible Kujo follow-up | Fixed upstream in `a8f50ab`; verified 2026-09-23 (see below) |

Implementation files: `src/storage.kujo`, `src/core.kujo`, `src/profile.kujo`, `src/common.kujo`; regression files: `tests/recovery_test.kujo`, `tests/recovery_fixture.kujo`, `tests/support.kujo` and existing filesystem suites. Existing test assertions were preserved; native symlink fixture creation is now asserted rather than silently skipped. Gates and portability changes are in `scripts/validate.sh`, `scripts/contention_benchmark.sh`, `.github/workflows/validate.yml`, and `.gitattributes`.

The deterministic persisted-state tests cover: claim without intent, intent without record, record without history, complete pair with retained intent, repeated recovery, conflicting history/record bytes, malformed/oversized/tampered intents, filename mismatch, traversal, dangling symlinks, `--force` refusal, Unicode byte equivalence, and bounded pending-intent scans. They construct crash states without production fault-injection hooks or timing-dependent sleeps. Concurrent replay tests use 16 real processes; the existing 32 distinct and 32 same-ID writer checks remain.

## Evidence and cost

Baseline: `bash scripts/validate.sh` passed 71 assertions and the existing contention gates. Final local verification executes **148 assertions**: 111 distinct assertions, including 37 recovery assertions, plus those 37 repeated through `--interpreter`. All pass. The interpreter emits its pre-existing `eprint` type-check warning; diagnostics were preserved, not suppressed. Receipts are under `recovery-evidence/`.

The same fixture approval, actor, ID, UTC timestamp, absolute manifest path, and runtime were used against archived starting source and current source from their own working directories. `cmp` accepted the record bytes and `diff -r` accepted the history directories. Both record SHA-256 values were:

```text
1c37616ab6fe8305737d96e74fd357619b1e2ae6780039d86aff8338415611a2
```

This is direct evidence that successful publication preserves existing wire/disk formats.

The protocol adds **one atomic write per successful creation** (claim → intent replacement → record → history, then unlink), compared with the previous claim → record → history protocol. During a pending write the intent contains a duplicate serialized record, capped at 1 MiB embedded UTF-8 and 4 MiB for the intent envelope. Normal completion removes it. Recovered completed intents remain until their original writer or an offline operator removes them. This is an explicit durability cost; no latency, memory, or throughput improvement is claimed.

The minimum runtime has no native byte-length primitive. The compatibility helper obtains exact UTF-8 size from the standard base64 encoder and padding length. Loading uses filesystem size directly, so normal queries do not encode every record to count bytes. No package dependencies, new database, state index, or minimum-runtime upgrade were introduced.

## Hosted verification

The starting implementation's [GitHub run 35769529426](https://github.com/kujolang/versionseal/actions/runs/35769529426) completed successfully: Linux native validation plus Linux/macOS/Windows contention. This closes the prior report's uncertainty about that run.

Expanded full-suite implementation run: [35797226298](https://github.com/kujolang/versionseal/actions/runs/35797226298), SHA `9edd823ddc670328612c5a800963a414acace02d`. All four jobs completed successfully: Linux native validation plus full Linux/macOS/Windows matrix validation. Each full gate executed 148 assertions and both contention checks. Exact results are recorded in `recovery-evidence/hosted-run.json`, `hosted-jobs.json`, and the per-OS check receipts. No pending or failed job is treated as passed.

## Remaining boundaries and follow-up

- Process interruption after intent publication is recoverable; simultaneous two-file visibility to raw filesystem readers is not promised. Consumers must wait for successful completion or use VersionSeal verification.
- Pre-intent claims and legacy locks lack the evidence needed for automatic recovery. Stop writers and review them offline. Recovery intentionally never infers process death from age or a PID.
- Power-loss durability and network filesystem semantics remain runtime/filesystem concerns. This patch does not claim parent-directory fsync or distributed transactions.
- The pinned minimum runtime materializes directory names before sorting. A newer iterator cannot be adopted without changing the runtime compatibility promise; adding a persistent index would add migration and invalidation risks. Existing record-byte and scan-count limits remain in force. No speculative index or silent truncation was added.
- Kujo lexical-scope discrepancy: `docs/audits/runtime-scope-repro.kujo` is a minimal reproducer. Local Kujo 1.4.0 binary SHA-256 was `6178fd8bf108a7be03981c701174814b32e86dcdeabf79fef715d96340b4821f`; inspected Kujo HEAD was `cf785c0a7953717af16b657cda05b85d628144c5`. `docs/LANGUAGE_SPEC.md` §5.2 specifies function lexical boundaries. No sibling source was modified, and VersionSeal does not require a runtime fix to use this patch.

SignalBox stored source capture `cap_4aa535ff-06ce-4d0b-bab0-4eeca5d3eda8` and review Signal `sig_06622b48-ec42-4194-a4db-1c9dd71b7dc2` for that runtime discrepancy. Exact-ID and conceptual retrieval succeeded. No exact duplicate was found; an older helper-name-shadowing report is related but lacks this caller-binding/VM-parity reproducer. Resolved VersionSeal work was excluded from SignalBox.

## Verification commands

```sh
bash scripts/validate.sh
../kujo/target/release/kujo run tests/storage_test.kujo
../kujo/target/release/kujo run tests/recovery_test.kujo
../kujo/target/release/kujo run tests/recovery_test.kujo --interpreter
bash scripts/contention_benchmark.sh
bash -n scripts/validate.sh
sh -n bin/versionseal
git diff --check
cmp .tmp/compatibility-old/records/approve-compatibility.json .tmp/compatibility-new/records/approve-compatibility.json
diff -r .tmp/compatibility-old/history .tmp/compatibility-new/history
```

The scope reproducer was deliberately run in both modes to preserve the discrepant outputs; it is evidence for an upstream issue, not a passing VersionSeal test. Full gates and compatibility comparisons above passed locally; hosted results are separately attributed to their exact revision.

## Upstream scope resolution — 2026-09-23

The earlier RF-04 status was based on the older local release binary, not the current upstream source. Kujo commit `a8f50ab50843b86cabc28da88dbb351a154b97ad` (Isolate top-level interpreter calls from caller-local scopes) is already contained in fetched `origin/main`, verified at `58c087b5d7af2a05d5d9fd2ad26a5a533044c5f6`. It suspends unrelated caller scopes during top-level calls and restores them afterward, preserving globals and captured closures. No additional Kujo source modification was needed.

Verification against the current debug build:

- `cargo test --test vm_interpreter_parity_surfaces` in Kujo: **115 passed**, including caller-local reads/writes, direct/indirect/pipe calls, lexical capture, and global immutability.
- `target/debug/kujo run ../versionseal/docs/audits/runtime-scope-repro.kujo`, repeated with `--interpreter`: **caller** in both modes.
- `KUJO_BIN=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/debug/kujo bash scripts/validate.sh`: **148 assertions and both contention gates passed** locally on macOS. This is additional validation, not a new three-platform hosted claim.
- Existing release runtime: `../kujo/target/release/kujo run tests/test.kujo`: **16 passed**.
- `git diff --check`: passed.

VersionSeal keeps its descriptive helper-local names for compatibility with older supported runtimes. Removing that compatibility protection would not improve correctness. The old SignalBox report and prior memory are historical; this verified resolution supersedes their unresolved-runtime status. No new unresolved finding was created.

Remaining work is limited to the documented legacy-lock/operator, two-file visibility, power-loss/network-filesystem, and directory-enumeration boundaries above. No demonstrated VersionSeal defect remains from RF-04. Adopt a runtime build containing the upstream fix when updating deployments; the old release binary used for the original report does not acquire fixes merely because source is updated.

## Runtime adoption update

The [2026-09-23 runtime and bounded-scan follow-up](runtime-upgrade.md) supersedes the unchanged-minimum-runtime and full directory materialization limits above. It adopts Kujo 1.5.0 explicitly, installs the fixed runtime on this host, and records final verification and remaining durability boundaries.
