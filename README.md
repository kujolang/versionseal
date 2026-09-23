# VersionSeal

[![Version](https://img.shields.io/badge/version-0.3.0-black)](VERSION)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)
[![built with Kujo](https://img.shields.io/badge/built%20with-Kujo-white.svg)](https://github.com/kujolang/kujo)
[![CI](https://github.com/kujolang/versionseal/actions/workflows/validate.yml/badge.svg)](https://github.com/kujolang/versionseal/actions/workflows/validate.yml)

VersionSeal is a local-first Kujo tool for exact-version human approvals, explicit authority, revocation, and checksum-backed verification. It has no required hosted service, database server, model key, or sibling-tool dependency.

## Production capabilities

VersionSeal provides immutable records, append-only audit events, atomic writes, exclusive per-record locks, bounded inputs and queries, opt-in RSA/HMAC verification library adapters, offline public-key fixtures, quorum and separation-of-duties policy evaluation, injected-clock expiry, conflict-aware replication with revocation precedence, and full three-platform validation gates. Optional external capabilities fail honestly when no adapter is configured. It does not claim hosted identity.

See the [production review](docs/PRODUCTION_READINESS_REVIEW.md) and completed [hardening worklist](docs/NEXT_SESSION.md).

## Version 0.3.0

Adds interrupted-write recovery, stronger immutable storage and validation, and bounded directory-name paging. Requires Kujo 1.5.0 or newer. Existing 0.1.0 and 0.2.0 records remain supported; upgrade all writers before using recovery. See the [changelog](CHANGELOG.md) and [recovery guide](docs/recovery.md).

## Quick install

Requires Kujo 1.5.0 or newer (see [runtime requirements](#runtime-requirement)).

```bash
git clone https://github.com/kujolang/versionseal.git
cd versionseal
export KUJO_BIN=/absolute/path/to/kujo
export PATH="$PWD/bin:$PATH"
versionseal --version --json
versionseal doctor --json
```

## Quick start

```bash
versionseal init --state .versionseal --json
versionseal approve --input fixtures/core.json --path fixtures/manifest.txt --actor fixture-human --json
versionseal validate --json
versionseal export --output versionseal-export.json --json
```

Run `versionseal --help` for the complete command surface. Common flags include `--state`, `--config`, `--input`, `--actor`, `--timestamp`, `--id`, `--path`, `--type`, `--after`, `--limit`, `--output`, `--force`, `--dry-run`, and `--json`. JSON mode uses the stable `ok/data/error/error_code/tool_version/contract_version` envelope. Exit codes are 0 success, 1 operational failure, and 2 usage error.

State defaults to `.versionseal/`. Traversal, symlinks, secret-shaped fields, malformed JSON, incompatible schemas, duplicate IDs, checksum drift, oversized resources, and unsafe overwrites fail closed. Core behavior is implemented entirely in Kujo; adapters remain optional.

## Project structure

```text
versionseal.kujo       canonical entrypoint
src/                  CLI, domain, storage, and shared Kujo modules
tests/                regression, security, and domain suites
schemas/              public JSON contracts
fixtures/             deterministic offline inputs
scripts/              validation gates
docs/                 contracts, security, review, and future work
bin/versionseal        logic-free launcher
```

## Verification

```bash
bash scripts/validate.sh
```

The gate checks the entrypoint, every Kujo suite, JSON artifacts, CLI smoke paths, foreign-runtime boundaries, and the Git diff.

See [audit evidence](docs/audits/repository-hardening.md) for verification scope, measurements, and remaining limits. Query pages expose `next_after`; incomplete whole-state scans fail closed.

Interrupted writes can be inspected with `recover --id ID --dry-run` and completed with `recover --id ID`. See [recovery and ownership rules](docs/recovery.md); recovery never steals a writer lock. Full validation now runs on Linux, macOS, and Windows in CI.

### Runtime requirement

Kujo **1.5.0 or newer** is required for bounded directory-name pages and the upstream interpreter lexical-scope fix. CI pins the 1.5.0 source commit `cc2d7dbb59a8dc05f00d629e100932f56f4062f6`. Set `KUJO_BIN` to override the installed runtime; validation and the launcher otherwise prefer `kujo` on PATH. Record, history, and configuration formats remain unchanged.
