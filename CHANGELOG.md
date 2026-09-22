# Changelog

## Unreleased

- Standardized README badge ordering and repository-local artifact ignores.
- Kept Loop Engineering evidence available locally while removing it from published source.

## 0.2.0 - 2026-08-14

- Preserved validation compatibility with immutable 0.1.0 records while emitting 0.2.0 records.
- Prevented audit-history conflicts from leaving partial records and added clean-retry regression coverage.
- Enforced safe package/approval references, SHA-256 checksum syntax, bounded action/destination sets, expiry timestamps, state compatibility, and stricter immutable-record validation.
- Added exact manifest-byte binding, actor binding, immutable audit storage, structured failures, CI, and expanded verification.

## 0.1.0 - 2026-08-14

- Initial Kujo-native release with working local records, validation, contracts, fixtures, and safety boundaries.

### Repository hardening (2026-09-22)

- Replaced idempotent directory locks with exclusive atomic files and no-replace record/history writes.
- Made dry-run side-effect free; tightened stored actor binding, timestamps, policy types, CLI arguments, and configuration validation.
- Bounded query bytes and corrupt scans, added continuation cursors, and made incomplete validation fail closed.
- Corrected fractional expiry, divergent revocation merging, portable runtime discovery, record schema compatibility, and executable quickstart fixtures.
- Added regression suites and same-ID contention/history integrity gates; see `docs/audits/repository-hardening.md`.
