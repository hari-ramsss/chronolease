# Proposal A review: staking probe upload only

## Decision: NOT READY FOR SUBMISSION — v3.2.10 verified; gas and fee unresolved

The exact source commit is public, the dependency-risk acceptance is recorded by the project owner for this probe only, and the proposal JSON and payload integrity checks pass. This is **not ready for submission**: Proposal 39 does not provide a trusted v3.2.9 bundle URL; the live official manifest and applied upgrade are now v3.2.10; `qorechaind`/PQC CLI is not available on `PATH`; no local signing keys were verified; and no gas dry run was run. Direct upload remains disallowed and the circuit breaker remains active, so governance must execute the atomic reset/store/restore message sequence. No signing, cosigning, broadcast, upload, instantiation, or Diana G0-A test occurred.

## Source and build provenance

- Public source commit: [724729bcfc34bb43131165bbbe49f90dace5926e](https://github.com/hari-ramsss/chronolease/commit/724729bcfc34bb43131165bbbe49f90dace5926e) (Add reproducible G0-A staking probe source).
- Configured origin: `git@github.com:hari-ramsss/chronolease.git`. The source-only commit was pushed to `main`; post-push `git ls-remote` confirmed the exact commit hash.
- Source SHA-256: `65a609605d04562892084c9f3f7f74d557f0b27fb7922285d58af9ab32aaee24`; Cargo.toml SHA-256: `58c8d97616345e4e5e8dfdb134438c6739d2db8710ff91a4142e9b8c4684f542`; Cargo.lock SHA-256: `7ad75e85907241d8f58a68d18cdb2c28ef06f73600c4f9968f6185e365e084ce`.
- Optimizer `cosmwasm/optimizer:0.16.1`; image digest `sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e`; architecture `linux/amd64`.
- Two builds from these committed inputs match optimizer checksum `4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`. See `docs/SOURCE_PROVENANCE_G0A.md` and `docs/WASM_ARTIFACT_AUDIT.md`.

## Wasm and payload

Optimized Wasm size is 169,218 bytes; its SHA-256 is `4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`, matching `artifacts/contracts/checksums.txt`. Structural limits, MVP validation, and no-float checks pass. Existing `proposal-a-code.b64` decodes and decompresses to 169,218 bytes with the same hash. Payload is 77,424 base64 characters / 58,066 gzip bytes. It was not regenerated.

## Live Diana data used in JSON

The previous snapshot was superseded by the read-only preflight at height `10673893`, time `2026-11-24T15:08:00.897621278Z`. Full evidence: `docs/evidence/proposal-a-operator-preflight.json`; parameter responses were at heights `10673890`–`10673892`. The owner account balance was not queried because no public account address was supplied; no wallet storage was accessed.

- Governance module account: `qor10d07y265gmmuvt4z0w9aw880jnsr700jwfyxr3`.
- Upload permission `Nobody`; default instantiate permission `Everybody`.
- Circuit breaker disables `/cosmwasm.wasm.v1.MsgStoreCode`.
- Last code ID at snapshot: `865`; not included in the proposal.
- Regular deposit `10000000uqor`; voting period `14400s`; `expedited=false`.
- Cross-VM is enabled. Max message size is `65536`; max Cosmos tx gas `50000000`; max block Wasm gas `3000000`; current targets and pins are in the snapshot.
- Consensus block max gas is `500000000`.
- EVM fee-market base fee and minimum gas price are both `0.1uqor`/gas. Generic transaction-parameter endpoints returned HTTP 501, so exact gas and fees must be estimated using the official CLI and live state must be refreshed immediately before any later submission.
- Consensus block maximum gas is `500000000`; cross-VM maximum Cosmos tx gas is `50000000`.
- The official live release manifest identifies v3.2.10 with `minCompatible=3.2.10`, upgrade height `10654800`; applied-plan queries show v3.2.9 at `10424000` and v3.2.10 at `10654800`. These live values supersede the stale documentation statement that Diana still runs v3.2.9.

The JSON has exactly three messages in order: reset breaker, store code from the governance account, trip breaker. It has no instantiate message or code ID. The breaker exception is scoped to atomic proposal execution. Later instantiation must use the ID returned by successful storage.

## Final operator preparation

The owner accepted the residual dependency risks on 24 November 2026 for this exact testnet probe only; see `docs/SECURITY_RISK_ACCEPTANCE.md`. No acceptance transfers to production. Release evidence is in `docs/evidence/qorechain-release-provenance.json`: Proposal 39 supplies v3.2.9 binary and archive SHA-256 values and the archive filename, but no URL. The live manifest is already v3.2.10, so no bundle was downloaded or installed. The account/key limitations and operator procedure are in `artifacts/proposals/OPERATOR_CHECKLIST.md`. `qorechaind`/PQC CLI is absent from `PATH`; its help, shared libraries, and dry-run behavior were not inspected locally. No unsigned transaction was generated and no gas estimate was verified. The current proposal JSON and base64 payload were not changed.

## Dependency security findings

`cargo-audit v0.23.0` scanned 78 lockfile dependencies using a database containing 1,566 advisories. The lockfile scan is not a wasm32 target graph. The target-specific evidence and detailed limits are in `docs/WASM_DEPENDENCY_SECURITY_AUDIT.md`.

- `crypto-bigint 0.5.5`, RUSTSEC-2026-0387: timing variability in operations intended to be constant-time; patched in `>=0.7.6`.
- `curve25519-dalek 3.2.0`, RUSTSEC-2024-0344: timing variability in scalar subtraction; patched in `>=4.1.3`.
- `derivative 2.2.0`, RUSTSEC-2024-0388: unmaintained, no fixed version.

The first two resolve through `cosmwasm-crypto`, which CosmWasm 1.5.11 gates to `not(target_arch = "wasm32")`. Target Cargo trees and filtered metadata omit both vulnerable crates. The Wasm contains standard host crypto imports and wrapper code, but Binaryen call-graph plus conservative table/type reachability finds no route from any exported contract/API function to those wrappers. Thus the advisory-affected crate implementations and operations are not present/reachable in this module, based on the locked target graph; this does not audit Diana's own host crypto implementation. The native/build/test dependency exposure remains. The `zeroize` metadata discrepancy is resolved in `docs/WASM_DEPENDENCY_SECURITY_AUDIT.md`: its feature is not active in the wasm32 feature tree and is activated in the native crypto graph, while Cargo metadata's package-level feature list does not label the compilation unit. The `derivative 2.2.0` finding is an unmaintained proc-macro warning, not a confirmed vulnerability. `base64ct 1.7.3` and `zeroize 1.8.1` were not RustSec findings. No upgrades were made. Full audit output: `docs/evidence/cargo-audit.txt`; broader lockfile analysis: `artifacts/proposals/DEPENDENCY_AUDIT.md`.

## WASM-target dependency disposition (24 November 2026)

The committed probe manifest uses `cosmwasm-std 1.5.11`. QoreChain's official Native Development guide lists `cosmwasm-std 1.5+`. The latest official manifest and applied-upgrade query show Diana at v3.2.10, not v3.2.9; this API compatibility is not proof of live artifact acceptance or G0-A behavior. The exact internal wasmvm version for v3.2.10 is not stated in the release data captured here.

The current contract processes a provider address and public staking delegation results. It does not accept private keys or private cryptographic scalars, sign or verify signatures, accept arbitrary binary message data, make direct network calls, or load/execute untrusted dynamic code. The RustSec advisories describe timing leakage while operating on secret integer/scalar values. Source and entrypoint reachability analysis show those operations are not part of this probe's contract behavior. Host-native dependency risk persists for native builds/tests or other native users of the CosmWasm crypto APIs.

**Disposition:** the two vulnerable crate implementations are not in the deployed wasm32 graph, and the four corresponding CosmWasm wrappers are unreachable from exported entrypoints under the conservative call-table analysis. The owner accepted the bounded residual risk on 24 November 2026 for this probe only. Proposal A remains **NOT READY FOR SUBMISSION** until an authoritative v3.2.9 archive URL is established (or the owner explicitly changes the requested version), required local signing access is reviewed, the official CLI is verified, transaction gas is dry-run, and separate submission approval is given. G0-A remains untested and not passed.

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
- Governance submission readiness: **NOT READY; requested archive URL, CLI/PQC tooling, local signing access, owner balance, and transaction gas estimate are outstanding**.
- Product implementation: **NO-GO**.

## Superseding Diana v3.2.10 CLI and Proposal A readiness record — 24 November 2026

This record supersedes earlier v3.2.9/no-install and height 10673893 statements. The later verified snapshot and CLI results below are authoritative.

**Status: NOT READY FOR SUBMISSION.** The current official manifest at `https://download.qore.host/testnet/latest.json` reports version and minCompatible `3.2.10`, upgradeHeight `10654800`, and binary URL `https://download.qore.host/testnet/qorechaind-v3.2.10-final-r2-linux-amd64.tar.gz`. Manifest SHA-256 is `05bf891db98538dce1d9a710f93e5102c0e9ace79f57b4cbf10ae688c63fecb4` and size is `111890694` bytes. The live applied plan is v3.2.10 at height 10654800; latest Diana status is height `10677513`, timestamp `2026-11-24T16:34:02.221783810Z`. The sources agree. Evidence: `docs/evidence/qorechain-v3.2.10-manifest-preflight.json` and `docs/evidence/proposal-a-v3.2.10-final-preflight.json`.

The exact manifest URL was downloaded in Ubuntu WSL2 at `2026-11-24T15:35:54Z` (completed `15:36:16Z`) to `~/.local/qorechain/v3.2.10/qorechaind-v3.2.10-final-r2-linux-amd64.tar.gz`. The preserved archive matched both manifest size and SHA-256 before extraction. Its complete contents, including `lib/`, are installed under `~/.local/qorechain/v3.2.10/`. `env.sh` prepends the install's `bin` and `lib` locations while preserving existing PATH and LD_LIBRARY_PATH values; no shell startup file or system library configuration was changed. See the download, archive-list, and install metadata evidence under `docs/evidence/`.

The installed ELF is x86-64, SHA-256 `ffc76719d5f31bd59e42176c2d92c2e43e2386b4bcd5686964a847814ae81d3f`. `ldd` found no missing libraries; `LD_DEBUG=libs` confirms bundled `libqorepqc.so`, `libqoresvm.so`, and `libwasmvmqore_v1.x86_64.so` loaded for version/help invocation. The bundle's `libwasmvm.x86_64.so` is preserved but was not exercised by those commands. `qorechaind version` and `version --long` exited successfully but printed no version text; v3.2.10 provenance is established by the verified official manifest bundle, not that CLI output. Full command output: `docs/evidence/qorechain-v3.2.10-cli-verification.log`.

Installed help confirms PQC commands are integrated into `qorechaind`; no standalone `qorechain-pqc` binary is required. `tx pqc cosign` help documents `--dry-run` as a non-broadcast gas simulation and notes local Keybase is inaccessible in that mode. `gov submit-proposal --generate-only` successfully generated unsigned JSON from existing Proposal A without signing; signer/signature arrays are empty and it has no fees. The supplied public account `qor1f0zn99as5ymf0m4curxrx4csz096vnrupdtadq` has balance `99865000uqor`; live PQC registration reports `found=true`, `key_type=hybrid`, `possession_proven=true`. No wallet extension storage or private key was accessed.

An actual gas simulation did **not** occur. The first cosign dry-run failed because `--pqc-key` is required. A second attempt with a nonexistent placeholder key and in-memory keyring stopped because the CLI requires a local `.dilithium` key file. No key was created, recovered, read, or used, and no simulation reached the node. Logs and commands: `docs/evidence/proposal-a-gas-dry-run-v3.2.10.log` and `docs/evidence/dry-run-proposal-a-gas-v3.2.10.sh`. No genuine gas measurement exists and no fee has been calculated; the provisional 20-million estimate is invalid for use. The official measured-gas-plus-30% procedure cannot be applied until a separately reviewed safe signing-key procedure is available.

Latest live snapshot (height `10677513`, time `2026-11-24T16:34:02.221783810Z`): governance account `qor10d07y265gmmuvt4z0w9aw880jnsr700jwfyxr3`; upload permission `Nobody`; instantiate default `Everybody`; `MsgStoreCode` disabled; latest code ID 865; normal deposit `10000000uqor`; voting period `14400s`; quorum `.334`, threshold `.5`, veto `.334`; minimum gas price/base fee `.1uqor`; max block gas 500000000; cross-VM max Cosmos tx gas 50000000. Generic tx params endpoint returned HTTP 501. These are a dated snapshot and must be refreshed before any future submission.

The package remains **NOT READY FOR SUBMISSION** because a real no-broadcast gas result and reviewed fee are unavailable without local PQC signing material, which was not accessed. No transaction was signed, cosigned, broadcast or submitted; no code was uploaded or instantiated. G0-A remains untested and not passed.


Unsigned transaction preparation evidence: `docs/evidence/generate-proposal-a-unsigned-v3.2.10.sh` records the exact `qorechaind tx gov submit-proposal artifacts/proposals/proposal-a-store-probe.json --from qor1f0zn99as5ymf0m4curxrx4csz096vnrupdtadq --chain-id qorechain-diana --node https://rpc-testnet.qore.host:443 --generate-only --output json` invocation. Its valid unsigned output is `docs/evidence/proposal-a-unsigned-tx-v3.2.10.json`; generation log is adjacent. It is unsigned preparation only, has no final gas/fee, and is not a broadcast-ready transaction. The attempted dry-run command and its two key-related failures are preserved in `docs/evidence/dry-run-proposal-a-gas-v3.2.10.sh` and `docs/evidence/proposal-a-gas-dry-run-v3.2.10.log`.
