#!/usr/bin/env bash
# Reproducible LOCAL end-to-end demonstration for QoreLease Phase 1E.
# Runs in Ubuntu WSL2 (Rust + Foundry) and uses the Windows Node 24 binary for
# TypeScript type-stripping. NOT Diana: all bridge/native/staking behaviour is
# mocked or locally executed.
set -euo pipefail
ROOT="/mnt/c/Users/Hari Ram/Documents/chronoquota"
export PATH="$HOME/.cargo/bin:$HOME/.foundry/bin:$PATH"
WIN_NODE="/mnt/c/Program Files/nodejs/node.exe"
if [ ! -x "$WIN_NODE" ]; then echo "Windows Node binary not found: $WIN_NODE" >&2; exit 1; fi

echo "=== STEP 1-9, 13: real Native contract code with mocked staking queries ==="
cd "$ROOT/contracts/qorelease-registry"
cargo test --locked --test e2e_native

echo "=== STEP 5, 7-9, 12, 14: local EVM escrow + stateful bridge/native mocks ==="
cd "$ROOT/contracts/evm"
forge test -vv --match-path 'test/QoreLeaseEscrow.t.sol'

echo "=== STEP 10-11: Native-gated provider adapter + local OpenAI-compatible workload ==="
cd "$ROOT/services/provider-adapter"
"$WIN_NODE" --experimental-strip-types --test src/adapter.test.ts
"$WIN_NODE" --experimental-strip-types src/e2e.ts

echo "=== LOCAL E2E COMPLETE (no Diana transactions) ==="
