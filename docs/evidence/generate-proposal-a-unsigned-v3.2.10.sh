#!/usr/bin/env bash
set -euo pipefail

install_dir="${HOME}/.local/qorechain/v3.2.10"
repo_dir="/mnt/c/Users/Hari Ram/Documents/chronoquota"
proposal="${repo_dir}/artifacts/proposals/proposal-a-store-probe.json"
account="qor1f0zn99as5ymf0m4curxrx4csz096vnrupdtadq"
unsigned_tx="${repo_dir}/docs/evidence/proposal-a-unsigned-tx-v3.2.10.json"
temp_tx="${unsigned_tx}.tmp"
log="${repo_dir}/docs/evidence/proposal-a-unsigned-tx-v3.2.10.log"

source "${install_dir}/env.sh"
if [[ -e "$unsigned_tx" || -e "$temp_tx" ]]; then
  printf 'Refusing to overwrite existing output: %s\n' "$unsigned_tx" >&2
  exit 2
fi

printf 'UTC: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee "$log"
printf 'Command: qorechaind tx gov submit-proposal %s --from %s --chain-id qorechain-diana --node https://rpc-testnet.qore.host:443 --generate-only --output json\n' "$proposal" "$account" | tee -a "$log"

if qorechaind tx gov submit-proposal "$proposal" \
  --from "$account" \
  --chain-id qorechain-diana \
  --node https://rpc-testnet.qore.host:443 \
  --generate-only \
  --output json > "$temp_tx" 2>> "$log"; then
  mv "$temp_tx" "$unsigned_tx"
  printf 'Generated unsigned transaction at %s\n' "$unsigned_tx" | tee -a "$log"
else
  cat "$log" >&2
  exit 3
fi

python3 -m json.tool "$unsigned_tx" >/dev/null
printf 'JSON syntax: valid\n' | tee -a "$log"
