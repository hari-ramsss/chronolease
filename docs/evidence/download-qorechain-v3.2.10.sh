#!/usr/bin/env bash
set -euo pipefail

install_dir="${HOME}/.local/qorechain/v3.2.10"
repo_dir="/mnt/c/Users/Hari Ram/Documents/chronoquota"
archive="qorechaind-v3.2.10-final-r2-linux-amd64.tar.gz"
url="https://download.qore.host/testnet/qorechaind-v3.2.10-final-r2-linux-amd64.tar.gz"
expected_sha256="05bf891db98538dce1d9a710f93e5102c0e9ace79f57b4cbf10ae688c63fecb4"
expected_size=111890694

if [[ -e "$install_dir" ]]; then
  printf 'Refusing to overwrite existing directory: %s\n' "$install_dir" >&2
  exit 2
fi

mkdir -p "$install_dir"
cd "$install_dir"
started_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
curl --fail --location --show-error --retry 3 --output "$archive" "$url"
actual_sha256="$(sha256sum "$archive" | awk '{print $1}')"
actual_size="$(stat -c '%s' "$archive")"
completed_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

{
  printf 'Download URL: %s\n' "$url"
  printf 'Started UTC: %s\n' "$started_utc"
  printf 'Completed UTC: %s\n' "$completed_utc"
  printf 'Expected SHA-256: %s\n' "$expected_sha256"
  printf 'Actual SHA-256: %s\n' "$actual_sha256"
  printf 'Expected size: %s\n' "$expected_size"
  printf 'Actual size: %s\n' "$actual_size"
} | tee "$install_dir/download-metadata.txt" "$repo_dir/docs/evidence/qorechain-v3.2.10-download-metadata.txt"

if [[ "$actual_sha256" != "$expected_sha256" ]]; then
  printf 'SHA-256 mismatch; refusing extraction.\n' >&2
  exit 3
fi
if [[ "$actual_size" != "$expected_size" ]]; then
  printf 'Archive size mismatch; refusing extraction.\n' >&2
  exit 4
fi

printf 'Manifest SHA-256 and size verified. Archive preserved at %s/%s\n' "$install_dir" "$archive"
tar -tzf "$archive" | tee "$install_dir/archive-contents.txt" "$repo_dir/docs/evidence/qorechain-v3.2.10-archive-contents.txt"
