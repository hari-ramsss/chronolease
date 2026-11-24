# Phase 0 operator runbook

No deployment or proposal is authorized by this document.

1. Verify Diana chain ID/version/height and reread cross-VM params, circuit
   breaker, Wasm permissions, governance params, EVM precompiles, fee/gas params,
   and the operator's EVM window.
2. Install the official testnet `qorechaind` bundle, keeping its `lib/` beside
   the binary; record version and SHA-256. Confirm hybrid-signing support.
3. The pinned official cosmwasm/optimizer:0.16.1 linux/amd64 build
   has now been verified twice; see the build record below.
4. Proposal A is prepared as upload-only JSON for review. It stores the probe
   Wasm and does not instantiate; see the review bundle and live snapshot.
5. Operator separately approves/submits Proposal A. Record proposal ID/status,
   tx hash, height, code ID, contract address, checksum, and history.
6. Prepare Proposal B from live params, preserving every existing field while
   adding the actual `cosmwasm:<address>` and exact code ID/history pin. Review
   unsigned JSON. Operator separately approves/submits; verify live state.
7. Deploy the minimal Solidity caller during an unscoped authorization window.
   Then open a distinct scoped window allowing `0x0901` and the caller address.
   Calculate blocks, transaction count, and value cap from current CLI help and
   simulated fees; the suggested 600-block sizing in the feasibility report is
   provisional only.
8. Run approved G0-A through G0-D cases; preserve full evidence. No product
   deployment follows unless all gates pass and a new decision approves it.

Never put wallet secrets in files, commands, logs, or chat. Never submit a
proposal or broadcast a transaction without the operator's explicit approval.

## WSL2 optimizer build record

Completed 24 November 2026 in Ubuntu 24.04.3 LTS on WSL2, architecture
`x86_64`. Docker Desktop 4.44.0, Docker client/server 28.3.2; both report
`linux/amd64`. The approved optimizer tag is `cosmwasm/optimizer:0.16.1`, pulled
with `--platform linux/amd64`. The immutable image reference used for both
builds is:

```text
cosmwasm/optimizer@sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e
```

Image tool versions: Rust 1.81.0, Cargo 1.81.0, `wasm-opt` 116. The crate uses
`cosmwasm-std` 1.5.11 and is standalone (no workspace configuration). Cargo
initially could not parse `base64ct 1.8.3` and `zeroize 1.9.2` because they
require Edition 2024. The original lockfile is preserved at
`docs/evidence/Cargo.lock.before-optimizer`; the current lock uses compatible
`base64ct 1.7.3` and `zeroize 1.8.1`. No contract source or logic changed.

Exact reproducible command from Ubuntu:

```bash
cd "/mnt/c/Users/Hari Ram/Documents/chronoquota/contracts/staking-probe"
docker run --rm --platform linux/amd64 -v "$PWD":/code \
  --mount type=volume,source=staking-probe_cache,target=/target \
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
  cosmwasm/optimizer@sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e
```

The exact command ran twice against the same image digest and lockfile. Both
optimizer checksum lines match:

```text
4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509  qorelease_staking_probe.wasm
```

The optimized artifact is 169,218 bytes at
`artifacts/contracts/qorelease_staking_probe.wasm`; the optimizer-generated
checksum file is `artifacts/contracts/checksums.txt`. The first optimized build
and checksum are preserved under `docs/evidence/optimizer-build-1/`; full build
logs are `docs/evidence/optimizer-build-1.log` and
`docs/evidence/optimizer-build-2.log`. The previous direct Cargo output remains
separate as `artifacts/contracts/qorelease_staking_probe.cargo-diagnostic.wasm`
with `checksums-cargo-diagnostic.txt`.

Status: **OPTIMIZED LOCALLY** and **REPRODUCIBLE BUILD VERIFIED**. This does not
pass G0-A or authorize uploading Wasm, submitting Proposal A, or broadcasting
a transaction. Any governance action requires separate review.

## Proposal A review bundle status ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â 24 November 2026

An unsigned upload-only JSON and deterministic gzip/base64 Wasm payload are
prepared under `artifacts/proposals/` using the live Diana state snapshot in
`docs/evidence/proposal-a-live-state.json` (height 10663567). The JSON has exactly
ResetCircuitBreaker, StoreCode, and TripCircuitBreaker in that order; it contains
no instantiate message, code ID, fee, or gas limit. The regular deposit is
`10000000uqor`, expedited is false. See `artifacts/proposals/PROPOSAL_A_REVIEW.md`
and `artifacts/proposals/DEPENDENCY_AUDIT.md` before any separate operator
review. Current milestones: optimized build verified; Proposal A locally prepared;
proposal not submitted or passed; contract not instantiated; G0-A not tested on
Diana and not passed. Probe source commit `724729bcfc34bb43131165bbbe49f90dace5926e` is public at the configured chronolease origin. Dependency audit findings keep the proposal NOT READY. No chain action is authorized by this record.
