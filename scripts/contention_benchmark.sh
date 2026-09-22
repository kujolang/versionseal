#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_RUNTIME="${KUJO_BIN:-$ROOT/../kujo/target/release/kujo}"
if [[ ! -x "$KUJO_RUNTIME" && -x "$KUJO_RUNTIME.exe" ]]; then KUJO_RUNTIME="$KUJO_RUNTIME.exe"; fi
STATE="$(mktemp -d)/state"
trap 'find "${STATE%/state}" -depth -delete' EXIT
pids=()
for i in $(seq 1 32); do
  input="${STATE%/state}/input-$i.json"
  printf '{"schema_version":"1.0.0","package_id":"package-%s","package_version":"1","manifest_checksum":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","requested_by":"benchmark","expires_at":"2026-12-31T00:00:00Z","destinations":["local"],"actions":["publish"]}\n' "$i" > "$input"
  KUJO_BIN="$KUJO_RUNTIME" "$ROOT/bin/versionseal" request --state "$STATE" --input "$input" --actor benchmark --timestamp "2026-08-14T00:00:00Z" --id "request-benchmark-$i" --json >"${STATE%/state}/result-$i.json" &
  pids+=("$!")
done
for pid in "${pids[@]}"; do wait "$pid"; done
count="$(find "$STATE/records" -type f -name 'request-benchmark-*.json' | wc -l | tr -d ' ')"
test "$count" = 32
pids=()
for i in $(seq 1 32); do
  (
    set +e
    KUJO_BIN="$KUJO_RUNTIME" "$ROOT/bin/versionseal" request --state "$STATE" --input "${STATE%/state}/input-$i.json" --actor benchmark --timestamp "2026-08-14T00:00:00Z" --id request-contended --json >"${STATE%/state}/collision-$i.json"
    status=$?
    test "$status" = 0 || test "$status" = 1 || exit "$status"
    printf '%s\n' "$status" >"${STATE%/state}/status-$i"
  ) &
  pids+=("$!")
done
for pid in "${pids[@]}"; do wait "$pid"; done
winners="$(grep -l '^0$' "${STATE%/state}"/status-* | wc -l | tr -d ' ')"
test "$winners" = 1
"$KUJO_RUNTIME" run "$ROOT/scripts/validate_contention.kujo" -- "$STATE"
printf 'VersionSeal contention passed: platform=%s distinct=32 same-id-winners=%s history=33\n' "$(uname -s)" "$winners"
