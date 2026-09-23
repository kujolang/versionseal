# Runtime and bounded scans — 2026-09-23

Repository: kujolang/versionseal, main. Starting SHA: `7631b93d3b27aee3e1c683292a3e8e8dab90414e`. Implementation commits: `a6ca13d8c4dac13db947f590c657187e81a45396`, `b4b2938244b67bd797a24b10f01cdd5b60da9f29`. Final documentation commit carries this receipt; no source changes follow those commits.

## Changes and compatibility

- Installed the official macOS x64 Kujo 1.5.0 release at `/Users/robertdevore/.local/bin/kujo`, after checking the published archive SHA-256. Preserved the previous binary under ignored `.tmp/runtime-v1.5.0/kujo-1.4.0.previous`. This upgrades this host only; no remote deployment was accessed.
- CI now pins released source `cc2d7dbb59a8dc05f00d629e100932f56f4062f6`, which includes the upstream lexical-scope fix. Minimum runtime is explicitly **1.5.0**, reflected in README, recovery documentation, `version`, and `doctor`. Scripts prefer the installed runtime consistently with the launcher, while preserving explicit `KUJO_BIN` overrides and sibling-build fallback.
- Record listing and pending-intent scans use the runtime's bounded `list_dir_page` selector instead of materializing and sorting the whole directory. Kept existing exclusive ID filtering, filename ordering, 1,000-candidate cap, byte limit, warnings, and fail-closed truncation. A removed pending lock cannot hide the native selector's incomplete scan status.
- Added 24 assertions, executed in both VM and interpreter: upstream caller isolation, declared runtime, native retained-name receipt, five complete 1,000-candidate pages, terminal cursor, prefix IDs, and exact/over-budget pending scans. Existing query tests retain byte-budget and corrupt-record pagination coverage.

No record/history/configuration formats, environment variable names, or command signatures changed. The runtime minimum change is intentional and requires users of older Kujo versions to upgrade. Non-UTF-8 directory filenames now fail closed in the native selector rather than being lossily decoded. Safe record IDs are ASCII, so these were never valid records.

## Measured resource effect

The regression fixture creates 5,000 record filenames. The previous `list_dir` produces 5,000 names. The new selector reports `examined_entries=5000`, `buffered_entries=1003`, and returns at most 1,002 names. Pending scans retain at most 1,002 names and return at most 1,001. These are measured native/name-count bounds, not process-memory or latency claims. Enumeration still takes O(N) time per page; no snapshot across directory changes or indexed-query performance is promised.

## Verification

The pre-change source archived at `.tmp/runtime-baseline` passed its complete gate on the downloaded 1.5.0 release: 148 assertions and both contention checks. The old default/interpreter scope reproducer prints `caller` in both release-runtime modes.

Final local gate: **196 assertions passed** (135 distinct plus 61 repeated in interpreter mode), 32 distinct writers, 32 same-ID contenders with one winner, and 16 concurrent recoveries. The existing `eprint` type-check warning remains visible. Hosted run [35904969683](https://github.com/kujolang/versionseal/actions/runs/35904969683) for source `b4b2938` is queued with no runner assigned as of this receipt; cross-platform verification of this runtime upgrade is pending, not passed.

Final verification results and exact release checksum are recorded in `runtime-upgrade-evidence/`. Commands:

```sh
# Within the release download directory:
shasum -a 256 -c kujo-v1.5.0-macos-x64.tar.gz.sha256
# Repository root:
KUJO_BIN="$PWD/.tmp/runtime-v1.5.0/kujo" bash .tmp/runtime-baseline/scripts/validate.sh
kujo run docs/audits/runtime-scope-repro.kujo
kujo run docs/audits/runtime-scope-repro.kujo --interpreter
bash scripts/validate.sh
../kujo/target/release/kujo run tests/test.kujo
bash -n scripts/validate.sh scripts/contention_benchmark.sh
git diff --check
```

## Boundaries that cannot be safely automated away

- **Legacy claims:** no live `.versionseal` store was present in this checkout. No operator locks were deleted. Claims without an intent contain no reconstructable decision evidence; offline review remains required. Age/PID-based lock stealing would introduce a race rather than resolve this limitation.
- **Raw two-file visibility:** immutable record and history remain separate files for compatibility. Use VersionSeal verification or wait for writer completion. Simultaneous visibility would require a different publication/reader contract, not a cleanup patch.
- **Power loss/network filesystems:** Kujo 1.5.0 atomic writes sync the temporary file, then rename/link it, but do not sync the parent directory. Process-interruption tests cannot establish hardware power-loss or network-server durability. An upstream durability API must distinguish a published-but-not-confirmed-durable result before VersionSeal can safely retry it. No such guarantee was added or implied here.

The remaining items are explicit operating/architecture limits, not hidden completed work. Stronger durability or distributed storage requires a separately specified contract and filesystem-specific fault testing. No sibling source was changed.

Upstream durability review recorded as SignalBox capture `cap_17d7080c-e46e-45e7-ac6e-4dbcf7997f51` and signal `sig_7eaefae1-7b50-4616-afe0-4727ff0fa4c5`; exact-ID and concept retrieval verified. No duplicates found for directory fsync / write_file_atomically. Resolved runtime and paging changes were excluded from SignalBox.
