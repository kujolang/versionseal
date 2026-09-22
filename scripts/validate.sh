#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_RUNTIME="${KUJO_BIN:-$ROOT/../kujo/target/release/kujo}"
if [[ ! -x "$KUJO_RUNTIME" ]] && command -v kujo >/dev/null 2>&1; then KUJO_RUNTIME="$(command -v kujo)"; fi
if [[ ! -x "$KUJO_RUNTIME" ]]; then printf 'versionseal: Kujo runtime not found; set KUJO_BIN.\n' >&2; exit 2; fi
cd "$ROOT"
"$KUJO_RUNTIME" check versionseal.kujo
"$KUJO_RUNTIME" run tests/test.kujo
"$KUJO_RUNTIME" run tests/security_test.kujo
"$KUJO_RUNTIME" run tests/storage_test.kujo
"$KUJO_RUNTIME" run tests/domain_test.kujo
"$KUJO_RUNTIME" run tests/hardening_test.kujo
"$KUJO_RUNTIME" run tests/audit_test.kujo
"$KUJO_RUNTIME" run tests/query_test.kujo
KUJO_BIN="$KUJO_RUNTIME" bash scripts/contention_benchmark.sh
while IFS= read -r document; do "$KUJO_RUNTIME" run scripts/validate_json.kujo -- "$document"; done < <(find fixtures schemas -type f -name '*.json' -print | sort)
tmp_state="$(mktemp -d)"; trap 'find "$tmp_state" -depth -delete' EXIT
KUJO_BIN="$KUJO_RUNTIME" ./bin/versionseal --help >/dev/null
KUJO_BIN="$KUJO_RUNTIME" ./bin/versionseal --version --json >/dev/null
KUJO_BIN="$KUJO_RUNTIME" ./bin/versionseal doctor --state "$tmp_state/state" --json >/dev/null
KUJO_BIN="$KUJO_RUNTIME" ./bin/versionseal approve --state "$tmp_state/state" --input fixtures/core.json --path fixtures/manifest.txt --actor fixture-human --json >/dev/null
KUJO_BIN="$KUJO_RUNTIME" ./bin/versionseal validate --state "$tmp_state/state" --json >/dev/null
KUJO_BIN="$KUJO_RUNTIME" ./bin/versionseal export --state "$tmp_state/state" --output "$tmp_state/export.json" --json >/dev/null
if KUJO_BIN="$KUJO_RUNTIME" ./bin/versionseal list --limit >/dev/null 2>&1; then exit 1; else test "$?" = 2; fi
KUJO_BIN="$KUJO_RUNTIME" ./bin/versionseal --version --json > "$tmp_state/version.json"
"$KUJO_RUNTIME" run scripts/validate_json.kujo -- "$tmp_state/version.json"
if grep -REn --include='*.kujo' 'python3|node |\.py\b|\.mjs\b' src tests scripts versionseal.kujo kujo.toml; then
  printf 'versionseal validation failed: foreign runtime dependency reference found.\n' >&2; exit 1
fi
test ! -f package.json && test ! -f requirements.txt && test ! -f go.mod && test ! -f Cargo.toml
badge_line() { grep -En -m 1 "$1" README.md 2>/dev/null | cut -d: -f1 || true; }
version_badge="$(badge_line 'shields.io/badge/version-')"
license_badge="$(badge_line 'shields.io/badge/license-')"
kujo_badge="$(badge_line 'shields.io/badge/built%20with-Kujo-')"
ci_badge="$(badge_line 'actions/workflows/validate.yml/badge.svg')"
if [[ -z "$version_badge" || -z "$license_badge" || -z "$kujo_badge" || -z "$ci_badge" ]] ||
   ! (( version_badge < license_badge && license_badge < kujo_badge && kujo_badge < ci_badge )); then
  printf 'validation failed: README badges must be ordered version, license, built with Kujo, then CI.\n' >&2
  exit 1
fi
if ! grep -Eq '^# Kujo ecosystem local artifact ignore block\.$' .gitignore ||
   ! git check-ignore -q .loop-engineering/loop.yml; then
  printf 'validation failed: the standard Kujo local-artifact ignore block is missing or incomplete.\n' >&2
  exit 1
fi
if [[ -n "$(git ls-files '.loop-engineering/**')" ]]; then
  printf 'validation failed: Loop Engineering evidence must remain local and untracked.\n' >&2
  exit 1
fi
git diff --check -- . ':(exclude).loop-engineering/**'
printf 'versionseal validation passed.\n'
