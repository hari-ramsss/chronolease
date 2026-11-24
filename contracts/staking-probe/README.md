# Staking probe

This deliberately small Native contract is the G0-A feasibility probe. It does
not implement admission, bonds, capacity, escrow, or QoreLease product logic.

`Probe { provider }` calls CosmWasm's standard `query_all_delegations`, stores
the returned delegations, and aggregates only `uqor` with checked integer
arithmetic. `LastResult {}` exposes the persisted observation.

## Reproducible optimizer build

The crate is standalone; it has no parent Cargo workspace. The committed
`Cargo.lock` is the complete dependency resolution used by the build. Build
from Ubuntu WSL2 with Docker Desktop's WSL integration enabled, using the
pinned official x86_64 image by immutable digest:

```bash
cd "/mnt/c/Users/Hari Ram/Documents/chronoquota/contracts/staking-probe"
docker run --rm --platform linux/amd64 -v "$PWD":/code \
  --mount type=volume,source=staking-probe_cache,target=/target \
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
  cosmwasm/optimizer@sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e
sha256sum -c artifacts/checksums.txt
```

This is optimizer `cosmwasm/optimizer:0.16.1`, platform `linux/amd64`.
The expected optimized probe SHA-256 is
`4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`.
Do not substitute another optimizer version or a direct Cargo build for the
release artifact. The prior direct Cargo Wasm is diagnostic only.

A successful local test verifies only the standard-library call shape. G0-A
can pass only after this exact Wasm is governance-approved, deployed, and
executed on `qorechain-diana` directly and through the EVM bridge. See
`docs/FEASIBILITY_SPIKES.md` for required evidence and current status.