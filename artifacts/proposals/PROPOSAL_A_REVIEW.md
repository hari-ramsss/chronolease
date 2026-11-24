# Proposal A review: staking probe upload only

## Decision: NOT READY FOR SUBMISSION

The unsigned JSON shape and compressed payload validate. The exact source commit is now public, but submission remains blocked because the current RustSec scan reports transitive cryptographic vulnerabilities. No signing, broadcast, upload, instantiation, or Diana G0-A test occurred.

## Source and build provenance

- Public source commit: [724729bcfc34bb43131165bbbe49f90dace5926e](https://github.com/hari-ramsss/chronolease/commit/724729bcfc34bb43131165bbbe49f90dace5926e) (Add reproducible G0-A staking probe source).
- Configured origin: `git@github.com:hari-ramsss/chronolease.git`. The source-only commit was pushed to `main`; post-push `git ls-remote` confirmed the exact commit hash.
- Source SHA-256: `65a609605d04562892084c9f3f7f74d557f0b27fb7922285d58af9ab32aaee24`; Cargo.toml SHA-256: `58c8d97616345e4e5e8dfdb134438c6739d2db8710ff91a4142e9b8c4684f542`; Cargo.lock SHA-256: `7ad75e85907241d8f58a68d18cdb2c28ef06f73600c4f9968f6185e365e084ce`.
- Optimizer `cosmwasm/optimizer:0.16.1`; image digest `sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e`; architecture `linux/amd64`.
- Two builds from these committed inputs match optimizer checksum `4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`. See `docs/SOURCE_PROVENANCE_G0A.md` and `docs/WASM_ARTIFACT_AUDIT.md`.

## Wasm and payload

Optimized Wasm size is 169,218 bytes; its SHA-256 is `4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`, matching `artifacts/contracts/checksums.txt`. Structural limits, MVP validation, and no-float checks pass. Existing `proposal-a-code.b64` decodes and decompresses to 169,218 bytes with the same hash. Payload is 77,424 base64 characters / 58,066 gzip bytes. It was not regenerated.

## Live Diana data used in JSON

Snapshot height `10663567`, time `2026-11-24T11:02:15.000147343Z`; raw responses: `docs/evidence/proposal-a-live-state.json`.

- Governance module account: `qor10d07y265gmmuvt4z0w9aw880jnsr700jwfyxr3`.
- Upload permission `Nobody`; default instantiate permission `Everybody`.
- Circuit breaker disables `/cosmwasm.wasm.v1.MsgStoreCode`.
- Last code ID at snapshot: `865`; not included in the proposal.
- Regular deposit `10000000uqor`; voting period `14400s`; `expedited=false`.
- Cross-VM is enabled; current targets and pins are preserved in the snapshot and unaffected.

The JSON has exactly three messages in order: reset breaker, store code from the governance account, trip breaker. It has no instantiate message or code ID. The breaker exception is scoped to atomic proposal execution. Later instantiation must use the ID returned by successful storage.

## Dependency security findings

`cargo-audit v0.23.0` scanned 78 dependencies using a database containing 1,566 advisories:

- `crypto-bigint 0.5.5`, RUSTSEC-2026-0387: timing variability in operations intended to be constant-time; patched in `>=0.7.6`.
- `curve25519-dalek 3.2.0`, RUSTSEC-2024-0344: timing variability in scalar subtraction; patched in `>=4.1.3`.
- `derivative 2.2.0`, RUSTSEC-2024-0388: unmaintained, no fixed version.

The first two are vulnerabilities in transitive CosmWasm crypto dependencies. `base64ct 1.7.3` and `zeroize 1.8.1` were not themselves listed by this audit. The compatibility pins do not clear the findings. No upgrades were made; resolving them needs a compatible dependency/toolchain update, a fresh reproducible build, and a fresh artifact audit. Full output: `docs/evidence/cargo-audit.txt`; analysis: `artifacts/proposals/DEPENDENCY_AUDIT.md`.

## Later instantiation procedure (not performed)

After a separately approved upload succeeds, query actual code info and returned code ID. Review a separate instantiate transaction using that ID, current permissions, simulation, and fee parameters. Record address, transaction hash, and height. Do not infer a code ID or broadcast from this review.

## Milestones

- Optimized build verified: **yes**.
- Source inputs committed locally / public: **yes / yes**.
- Proposal JSON locally prepared: **yes, review only**.
- Proposal submitted / passed: **no / no**.
- Code uploaded / instantiated: **no / no**.
- G0-A tested on Diana / passed: **no / no**.
- Governance submission readiness: **NOT READY**.
- Product implementation: **NO-GO**.
