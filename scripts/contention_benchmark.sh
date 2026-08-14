#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; KUJO_RUNTIME="${KUJO_BIN:-$ROOT/../kujo/target/release/kujo}"; if [[ ! -x "$KUJO_RUNTIME" && -x "$KUJO_RUNTIME.exe" ]]; then KUJO_RUNTIME="$KUJO_RUNTIME.exe"; fi; STATE="$(mktemp -d)/state"
trap 'find "${STATE%/state}" -depth -delete' EXIT
for i in $(seq 1 32); do input="${STATE%/state}/input-$i.json"; printf '{"schema_version":"1.0.0","package_id":"package-%s","package_version":"1","manifest_checksum":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","requested_by":"benchmark","expires_at":"2026-12-31T00:00:00Z","destinations":["local"],"actions":["publish"]}\n' "$i" > "$input"; KUJO_BIN="$KUJO_RUNTIME" "$ROOT/bin/versionseal" request --state "$STATE" --input "$input" --actor benchmark --timestamp "2026-08-14T00:00:00Z" --id "request-benchmark-$i" --json >/dev/null & done
wait; count="$(find "$STATE/records" -type f -name 'request-benchmark-*.json' | wc -l | tr -d ' ')"; test "$count" = 32; printf 'VersionSeal contention benchmark passed: platform=%s workers=32 records=%s\n' "$(uname -s)" "$count"
