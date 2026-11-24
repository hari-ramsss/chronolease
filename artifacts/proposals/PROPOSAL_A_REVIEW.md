# Proposal A review: staking probe upload only

## Decision: NOT READY FOR SUBMISSION — OWNER RISK ACCEPTED; OPERATOR READINESS INCOMPLETE

The exact source commit is public, the dependency-risk acceptance is recorded by the project owner for this probe only, and the proposal JSON and payload integrity checks pass. This is **not ready for submission**: `qorechaind` v3.2.9 and its PQC commands are not available on `PATH` (availability outside `PATH` is unverified), and transaction-level gas estimation has not been run. Fresh endpoint reads confirm the upload circuit is disabled and direct upload permissions remain `Nobody`; governance therefore needs to execute the three-message circuit reset, store, and restore proposal atomically. No signing, cosigning, broadcast, upload, instantiation, or Diana G0-A test occurred.

## Source and build provenance

- Public source commit: [724729bcfc34bb43131165bbbe49f90dace5926e](https://github.com/hari-ramsss/chronolease/commit/724729bcfc34bb43131165bbbe49f90dace5926e) (Add reproducible G0-A staking probe source).
- Configured origin: `git@github.com:hari-ramsss/chronolease.git`. The source-only commit was pushed to `main`; post-push `git ls-remote` confirmed the exact commit hash.
- Source SHA-256: `65a609605d04562892084c9f3f7f74d557f0b27fb7922285d58af9ab32aaee24`; Cargo.toml SHA-256: `58c8d97616345e4e5e8dfdb134438c6739d2db8710ff91a4142e9b8c4684f542`; Cargo.lock SHA-256: `7ad75e85907241d8f58a68d18cdb2c28ef06f73600c4f9968f6185e365e084ce`.
- Optimizer `cosmwasm/optimizer:0.16.1`; image digest `sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e`; architecture `linux/amd64`.
- Two builds from these committed inputs match optimizer checksum `4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`. See `docs/SOURCE_PROVENANCE_G0A.md` and `docs/WASM_ARTIFACT_AUDIT.md`.

## Wasm and payload

Optimized Wasm size is 169,218 bytes; its SHA-256 is `4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`, matching `artifacts/contracts/checksums.txt`. Structural limits, MVP validation, and no-float checks pass. Existing `proposal-a-code.b64` decodes and decompresses to 169,218 bytes with the same hash. Payload is 77,424 base64 characters / 58,066 gzip bytes. It was not regenerated.

## Live Diana data used in JSON

The original snapshot was superseded by the fresh read-only preflight at height `10673181`, time `2026-11-24T14:50:59.553178651Z`. Full evidence: `docs/evidence/proposal-a-final-live-preflight.json`; query responses were at heights `10673178`–`10673180`.

- Governance module account: `qor10d07y265gmmuvt4z0w9aw880jnsr700jwfyxr3`.
- Upload permission `Nobody`; default instantiate permission `Everybody`.
- Circuit breaker disables `/cosmwasm.wasm.v1.MsgStoreCode`.
- Last code ID at snapshot: `865`; not included in the proposal.
- Regular deposit `10000000uqor`; voting period `14400s`; `expedited=false`.
- Cross-VM is enabled. Max message size is `65536`; max Cosmos tx gas `50000000`; max block Wasm gas `3000000`; current targets and pins are in the snapshot.
- Consensus block max gas is `500000000`.
- EVM fee-market base fee and minimum gas price are both `0.1uqor`/gas. Generic transaction-parameter endpoints returned HTTP 501, so exact gas and fees must be estimated using the official CLI and live state must be refreshed immediately before any later submission.

The JSON has exactly three messages in order: reset breaker, store code from the governance account, trip breaker. It has no instantiate message or code ID. The breaker exception is scoped to atomic proposal execution. Later instantiation must use the ID returned by successful storage.

## Final operator preparation

The owner accepted the residual dependency risks on 24 November 2026 for this exact testnet probe only; see `docs/SECURITY_RISK_ACCEPTANCE.md`. No acceptance transfers to production. The detailed unsigned generation, gas-estimation, dry-run, manual broadcast, and post-submission verification procedure is in `artifacts/proposals/OPERATOR_CHECKLIST.md`. `qorechaind` and the PQC CLI are not installed here, so no unsigned transaction has been generated and no gas estimate has been verified. The current proposal JSON and base64 payload were not changed.

## Dependency security findings

`cargo-audit v0.23.0` scanned 78 lockfile dependencies using a database containing 1,566 advisories. The lockfile scan is not a wasm32 target graph. The target-specific evidence and detailed limits are in `docs/WASM_DEPENDENCY_SECURITY_AUDIT.md`.

- `crypto-bigint 0.5.5`, RUSTSEC-2026-0387: timing variability in operations intended to be constant-time; patched in `>=0.7.6`.
- `curve25519-dalek 3.2.0`, RUSTSEC-2024-0344: timing variability in scalar subtraction; patched in `>=4.1.3`.
- `derivative 2.2.0`, RUSTSEC-2024-0388: unmaintained, no fixed version.

The first two resolve through `cosmwasm-crypto`, which CosmWasm 1.5.11 gates to `not(target_arch = "wasm32")`. Target Cargo trees and filtered metadata omit both vulnerable crates. The Wasm contains standard host crypto imports and wrapper code, but Binaryen call-graph plus conservative table/type reachability finds no route from any exported contract/API function to those wrappers. Thus the advisory-affected crate implementations and operations are not present/reachable in this module, based on the locked target graph; this does not audit Diana's own host crypto implementation. The native/build/test dependency exposure remains. The `zeroize` metadata discrepancy is resolved in `docs/WASM_DEPENDENCY_SECURITY_AUDIT.md`: its feature is not active in the wasm32 feature tree and is activated in the native crypto graph, while Cargo metadata's package-level feature list does not label the compilation unit. The `derivative 2.2.0` finding is an unmaintained proc-macro warning, not a confirmed vulnerability. `base64ct 1.7.3` and `zeroize 1.8.1` were not RustSec findings. No upgrades were made. Full audit output: `docs/evidence/cargo-audit.txt`; broader lockfile analysis: `artifacts/proposals/DEPENDENCY_AUDIT.md`.

## WASM-target dependency disposition (24 November 2026)

The committed probe manifest uses `cosmwasm-std 1.5.11`. QoreChain's official Native Development guide lists `cosmwasm-std 1.5+`; Diana's v3.2.9 release is documented as active since 20 November 2026. This is documented API compatibility, not proof of live artifact acceptance or G0-A behavior. The exact internal wasmvm version for v3.2.9 is not stated in the public release documentation reviewed.

The current contract processes a provider address and public staking delegation results. It does not accept private keys or private cryptographic scalars, sign or verify signatures, accept arbitrary binary message data, make direct network calls, or load/execute untrusted dynamic code. The RustSec advisories describe timing leakage while operating on secret integer/scalar values. Source and entrypoint reachability analysis show those operations are not part of this probe's contract behavior. Host-native dependency risk persists for native builds/tests or other native users of the CosmWasm crypto APIs.

**Disposition:** the two vulnerable crate implementations are not in the deployed wasm32 graph, and the four corresponding CosmWasm wrappers are unreachable from exported entrypoints under the conservative call-table analysis. The owner accepted the bounded residual risk on 24 November 2026 for this probe only. Proposal A remains **NOT READY FOR SUBMISSION** until official CLI availability, transaction gas estimation, and separate submission approval. G0-A remains untested and not passed.

## Later instantiation procedure (not performed)

After a separately approved upload succeeds, query actual code info and returned code ID. Review a separate instantiate transaction using that ID, current permissions, simulation, and fee parameters. Record address, transaction hash, and height. Do not infer a code ID or broadcast from this review.

## Milestones

- Optimized build verified: **yes**.
- Source inputs committed locally / public: **yes / yes**.
- Proposal JSON locally prepared: **yes, review only**.
- Proposal submitted / passed: **no / no**.
- Code uploaded / instantiated: **no / no**.
- G0-A tested on Diana / passed: **no / no**.
- Owner risk acceptance: **ACCEPTED for this Diana testnet probe only (24 November 2026)**.
- Governance submission readiness: **NOT READY; CLI/PQC tooling and transaction gas estimation remain outstanding**.
- Product implementation: **NO-GO**.
