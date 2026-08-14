# VersionSeal

Exact-version human approval records bound to package checksums, destinations, actions, conditions, expiration, and revocation.

VersionSeal 0.1.0 is an independently installable, local-first Kujo tool. It requires no hosted service, Chain of Command, WebOps, or sibling Publishing House tool. The canonical entrypoint is `versionseal.kujo`; `bin/versionseal` contains no product logic.

## CLI

Commands: approve; request; inspect; reject; request-changes; verify; revoke; expire; list; history; doctor; version; init; show; export; validate. Run `./bin/versionseal help` for flags. Mutations require `--actor`; JSON input uses `--input`. Common flags include `--json`, `--dry-run`, `--state`, `--output`, `--config`, and `--force`. Exit codes: 0 success, 1 validation/operation failure, 2 usage error.

State defaults to `.versionseal/`. Immutable JSON records and append-only history use atomic writes. IDs reject traversal; symlinks and oversized inputs are rejected. See [contracts](docs/contracts.md), [security](docs/security.md), and [quickstart](examples/quickstart.md).

Test with `/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo run tests/test.kujo`, then run `./bin/versionseal doctor --json`.

0.1.0 covers the documented local records, fixtures, validation, checksums, deterministic fixed-time IDs, and structured export. It does not manufacture human judgment, consent, rights, approval, or causation. VersionSeal records and verifies human decisions but cannot impersonate a human, broaden scope, publish, or reuse approval after checksum drift.
