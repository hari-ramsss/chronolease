#!/usr/bin/env bash
set -euo pipefail

install_dir="${HOME}/.local/qorechain/v3.2.10"
repo_dir="/mnt/c/Users/Hari Ram/Documents/chronoquota"
source "${install_dir}/env.sh"
cd "$install_dir"

{
  printf '%s\n' '=== WSL architecture ==='
  uname -m
  printf '%s\n' '=== Executable file and digest ==='
  file ./qorechaind
  sha256sum ./qorechaind
  readelf -h ./qorechaind | grep -E 'Class:|Machine:'
  printf '%s\n' '=== Dynamic shared-library resolution ==='
  ldd_output="$(ldd ./qorechaind)"
  printf '%s\n' "$ldd_output"
  if grep -q 'not found' <<<"$ldd_output"; then
    printf '%s\n' 'Unresolved dynamic libraries detected.' >&2
    exit 10
  fi
  printf '%s\n' '=== qorechaind version ==='
  qorechaind version
  printf '%s\n' '=== qorechaind version --long ==='
  qorechaind version --long
  printf '%s\n' '=== qorechaind --help ==='
  qorechaind --help
  printf '%s\n' '=== qorechaind tx pqc --help ==='
  qorechaind tx pqc --help
  printf '%s\n' '=== qorechaind tx pqc cosign --help ==='
  qorechaind tx pqc cosign --help
  printf '%s\n' '=== qorechaind tx gov submit-proposal --help ==='
  qorechaind tx gov submit-proposal --help
  printf '%s\n' '=== Runtime loader trace for version command ==='
  LD_DEBUG=libs qorechaind version 2>&1
} 2>&1 | tee "${repo_dir}/docs/evidence/qorechain-v3.2.10-cli-verification.log"
