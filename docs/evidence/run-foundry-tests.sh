#!/usr/bin/env bash
# Local Foundry build/test runner. Executed in Ubuntu 24.04 WSL2.
set -euo pipefail
export PATH="$HOME/.foundry/bin:$PATH"
cd "/mnt/c/Users/Hari Ram/Documents/chronoquota/contracts/evm"
forge --version
forge build
forge test -vv "$@"
