# Changelog

## 0.3.0 - 2026-09-23

### Added

- Idempotent interrupted-write recovery with bounded exact-byte intents, no replacement, and no automatic lock stealing.
- Pending-write diagnostics and regression coverage for Unicode, interpreter behavior, concurrent writers, and concurrent recovery.
- Bounded directory-name paging, continuation cursors, aggregate query byte limits, and fail-closed incomplete validation.

### Fixed

- Exclusive atomic lock files and no-replace record/history publication prevent same-ID writer races.
- Dry-run no longer creates state. Stored actor binding, UTC timestamps, policy types, CLI arguments, and configuration receive stricter validation.
- Correct UTF-8 byte limits and receipts, fractional expiry ordering, divergent revocation merging, and symlink/overwrite handling.
- Portable runtime discovery, record schema compatibility, executable quickstart fixtures, and clean cross-platform test scratch paths.

### Changed

- Requires **Kujo 1.5.0 or newer** for bounded directory paging and the upstream interpreter lexical-scope fix; CI pins the 1.5.0 release source.
- Emits 0.3.0 records while preserving validation of immutable 0.1.0 and 0.2.0 records. Schema and contract versions remain 1.0.0.
- Full validation is configured for Linux, macOS, and Windows. Exact run results are recorded in the audit reports; queued jobs are not counted as passing.
- Standardized README badges and local-artifact ignores; removed local engineering evidence from published source.

### Upgrade notes

Upgrade Kujo first, then upgrade all VersionSeal writers together before using recovery. Do not mix older rollback-capable writers with the new recovery protocol. Existing records need no migration. Recovery retains writer-owned locks; legacy claims require offline review. Power-loss/network-filesystem durability and simultaneous raw two-file visibility remain outside the supported guarantees. See [recovery instructions](docs/recovery.md) and [verification evidence](docs/audits/runtime-upgrade.md).

## 0.2.0 - 2026-08-14

- Preserved validation compatibility with immutable 0.1.0 records while emitting 0.2.0 records.
- Prevented audit-history conflicts from leaving partial records and added clean-retry regression coverage.
- Enforced safe package/approval references, SHA-256 checksum syntax, bounded action/destination sets, expiry timestamps, state compatibility, and stricter immutable-record validation.
- Added exact manifest-byte binding, actor binding, immutable audit storage, structured failures, CI, and expanded verification.

## 0.1.0 - 2026-08-14

- Initial Kujo-native release with working local records, validation, contracts, fixtures, and safety boundaries.
