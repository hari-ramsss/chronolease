#!/usr/bin/env bash
set -euo pipefail

image='cosmwasm/optimizer@sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e'
wasm='/code/artifacts/contracts/qorelease_staking_probe.wasm'
wat='/tmp/qorelease_staking_probe.audit.wat'

docker run --rm --platform linux/amd64 -v "$PWD":/code \
  --entrypoint wasm-opt "$image" "$wasm" --emit-text -o /dev/stdout > "$wat"

echo 'wasm-opt parse/validation: PASS'
printf 'module bytes: '
wc -c < artifacts/contracts/qorelease_staking_probe.wasm
count_top_level() {
  local expression="$1"
  (grep -Ec "$expression" "$wat" || true)
}
printf 'defined functions: '
count_top_level '^[[:space:]]*\(func([[:space:]]|\$)'
printf 'function types: '
count_top_level '^[[:space:]]*\(type[[:space:]]+\$'
printf 'exports: '
count_top_level '^[[:space:]]*\(export([[:space:]]|\$)'
printf 'globals: '
count_top_level '^[[:space:]]*\(global([[:space:]]|\$)'
printf 'element segments: '
count_top_level '^[[:space:]]*\(elem([[:space:]]|\$)'
printf 'data segments: '
count_top_level '^[[:space:]]*\(data([[:space:]]|\$)'
echo 'memory declarations:'
(grep -E '^[[:space:]]*\(memory([[:space:]]|\$)' "$wat" || true)
echo 'table declarations:'
(grep -E '^[[:space:]]*\(table([[:space:]]|\$)' "$wat" || true)
echo 'element declarations:'
(grep -E '^[[:space:]]*\(elem([[:space:]]|\$)' "$wat" || true)
printf 'floating-point instructions (f32/f64): '
(grep -Eo 'f32\.[[:alpha:]_]+|f64\.[[:alpha:]_]+' "$wat" || true) | wc -l

# A strict MVP re-parse detects use of post-MVP proposals. Preserve its result
# as evidence; chain compatibility must still follow the deployed WasmVM rules.
if docker run --rm --platform linux/amd64 -v "$PWD":/code \
  --entrypoint wasm-opt "$image" "$wasm" --mvp-features -o /dev/null; then
  echo 'strict MVP validation: PASS'
else
  echo 'strict MVP validation: FAIL (module uses a post-MVP feature)'
fi
