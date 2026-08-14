# Quickstart

`./bin/versionseal init --state /tmp/versionseal-demo --json`

`./bin/versionseal approve --state /tmp/versionseal-demo --input fixtures/core.json --actor operator --timestamp 2026-08-14T00:00:00Z --json`

The fixed timestamp makes fixture IDs deterministic; repeating the command is rejected.
