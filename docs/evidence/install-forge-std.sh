#!/usr/bin/env bash
# Installs a pinned forge-std for local Foundry tests. Uses the official repo.
set -euo pipefail
export PATH="$HOME/.foundry/bin:$PATH"
cd "/mnt/c/Users/Hari Ram/Documents/chronoquota/contracts/evm"
mkdir -p lib
if [ ! -d lib/forge-std/.git ]; then
  git clone --depth 1 --branch v1.9.6 https://github.com/foundry-rs/forge-std.git lib/forge-std
fi
git -C lib/forge-std rev-parse HEAD
