#!/usr/bin/env bash
set -euo pipefail

install_dir="${HOME}/.local/qorechain/v3.2.10"
repo_dir="/mnt/c/Users/Hari Ram/Documents/chronoquota"
unsigned_tx="${repo_dir}/docs/evidence/proposal-a-unsigned-tx-v3.2.10.json"
log="${repo_dir}/docs/evidence/proposal-a-gas-dry-run-v3.2.10.log"
account="qor1f0zn99as5ymf0m4curxrx4csz096vnrupdtadq"

source "${install_dir}/env.sh"
{
  printf 'UTC: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'Command: qorechaind tx pqc cosign %s --from %s --pqc-key dry-run-no-key --keyring-backend memory --chain-id qorechain-diana --node https://rpc-testnet.qore.host:443 --dry-run\n' "$unsigned_tx" "$account"
  qorechaind tx pqc cosign "$unsigned_tx" \
    --from "$account" \
    --pqc-key dry-run-no-key \
    --keyring-backend memory \
    --chain-id qorechain-diana \
    --node https://rpc-testnet.qore.host:443 \
    --dry-run
} 2>&1 | tee -a "$log"
