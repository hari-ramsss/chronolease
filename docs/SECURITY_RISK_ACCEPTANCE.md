# Security risk acceptance — Diana staking-probe feasibility review

Status: **ACCEPTED — LIMITED TO DIANA TESTNET FEASIBILITY PROBE**
Prepared: 24 November 2026
Owner decision date: 24 November 2026
Repository state reviewed: `b0dd15e03e4bc7b37a35eab16f6413048fb25cfd`
Probe source commit: `724729bcfc34bb43131165bbbe49f90dace5926e`
Contract: `qorelease-staking-probe 0.1.0`
Wasm SHA-256: `4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`
Cargo.lock SHA-256: `7ad75e85907241d8f58a68d18cdb2c28ef06f73600c4f9968f6185e365e084ce`

## Purpose and scope

This record documents the project owner's acceptance of residual dependency risk for the **Diana testnet staking-query feasibility probe only**. It does not authorize proposal submission, upload, instantiation, signing, or transaction broadcast.

The scope is the exact probe source commit, manifest, lockfile and optimized Wasm hashes listed above, built with official `cosmwasm/optimizer:0.16.1` on `linux/amd64` using image digest `sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e`. This acceptance, if signed, is not a policy waiver for production or for any future QoreLease code.

## Findings and target disposition

| Advisory | Exact locked package | Unrestricted dependency path | Compiled into this wasm32 module? | Reachability / data |
|---|---|---|---|---|
| RUSTSEC-2026-0387 | `crypto-bigint 0.5.5` | `crypto-bigint -> elliptic-curve 0.13.8 -> ecdsa 0.16.9 -> k256 0.13.4 -> cosmwasm-crypto 1.5.11 -> cosmwasm-std 1.5.11 -> probe` | **No.** The pinned CosmWasm 1.5.11 manifest gates `cosmwasm-crypto` under `cfg(not(target_arch = "wasm32"))`; the locked wasm32 inverse tree and filtered resolved package list omit `crypto-bigint`. | The advisory concerns timing variability in operations intended to be constant-time on secret integers. The probe does not handle private scalars or keys. |
| RUSTSEC-2024-0344 | `curve25519-dalek 3.2.0` | `curve25519-dalek -> ed25519-zebra 3.1.0 -> cosmwasm-crypto 1.5.11 -> cosmwasm-std 1.5.11 -> probe` | **No.** Same target-gated CosmWasm dependency; no wasm32 inverse path or filtered metadata package. | The advisory concerns timing variability in scalar subtraction. The probe does not handle private scalars or keys. |
| RUSTSEC-2024-0388 | `derivative 2.2.0` | `derivative (proc-macro) -> cosmwasm-std 1.5.11 -> probe` | The procedural macro is a host compile-time tool and is not a runtime crate in the Wasm. | RustSec labels it unmaintained (`INFO`), not a confirmed vulnerability. No fixed version is listed. |

The Wasm imports the chain host APIs `secp256k1_verify`, `secp256k1_recover_pubkey`, `ed25519_verify`, and `ed25519_batch_verify`. Their local wrapper functions are present in the binary/table and call those imported APIs. A Binaryen call graph plus a conservative direct-call and indirect-table/type closure found none reachable from `instantiate`, `execute`, `query`, `interface_version_8`, `allocate`, or `deallocate`. Wrapper IDs are $165, $166, $167 and $168; their matching call-indirect types ($10 and $8) are not used by any call-indirect site reachable from those exports. The table is not exported. The chain host implementations are external to this Wasm; these wrappers do not contain the vulnerable RustSec crate implementations.

| Crypto operation | Wasm host import | Wrapper function | Classification |
|---|---|---|---|
| secp256k1 verification | `$fimport$9` | `$165` | **2 — present in binary but unreachable from exported entrypoints** |
| secp256k1 public-key recovery | `$fimport$10` | `$166` | **2 — present in binary but unreachable from exported entrypoints** |
| Ed25519 verification | `$fimport$11` | `$167` | **2 — present in binary but unreachable from exported entrypoints** |
| Ed25519 batch verification | `$fimport$12` | `$168` | **2 — present in binary but unreachable from exported entrypoints** |

## Zeroize metadata discrepancy — resolved

The lock pins `zeroize 1.8.1`. The target inverse tree prints no path, and `cargo tree -e features --target wasm32-unknown-unknown` shows `generic-array` `default` and `more_lengths` features without `zeroize`. The unrestricted native feature tree shows `generic-array/zeroize` and `crypto-bigint/zeroize` active in the host crypto graph. Filtered Cargo metadata still reports `zeroize` in the package resolution and `generic-array` feature list (`more_lengths,zeroize`), because that package-level feature view does not identify the host/target compilation unit that activated the feature. The target-aware feature tree and inverse graph show it is **present only in native/host dependency resolution**, not active for this Wasm target. `zeroize` is not a finding in the saved RustSec output.

Evidence: `docs/evidence/cargo-tree-wasm-features.log`, `cargo-tree-wasm-generic-array-features.log`, `cargo-tree-host-generic-array-features.log`, `cargo-tree-wasm-kinds-zeroize.log`, `cargo-metadata-wasm.json`, and `cargo-metadata-unfiltered.json`.

## Probe behavior and security boundary

The committed source (`contracts/staking-probe/src/lib.rs`; Git blob `5d32219acb1b50562c4a833a6328582445ccf11f`) implements instantiate, execute, and query entrypoints. Execute accepts a JSON enum containing a provider address string, validates it with CosmWasm `addr_validate`, issues the standard `query_all_delegations` request through the chain query host, stores returned delegation results and the checked `uqor` sum. Query serializes the stored result.

| Security-boundary question | Source-confirmed finding |
|---|---|
| Processes private keys? | No. |
| Processes private scalar values? | No. |
| Performs cryptographic signing? | No. |
| Performs cryptographic verification? | No. The source calls address validation and a staking query; it does not call signature-verification APIs. The four signature wrapper functions in the Wasm are unreachable from its exports. |
| Accepts user-controlled binary data? | No arbitrary binary field. Execute accepts a JSON provider-address string; returned chain-query data is decoded by CosmWasm. |
| Processes sensitive information? | No secrets or credentials. Provider addresses and delegation amounts are public chain data, though they may still be identifying or financially sensitive metadata. The probe stores its result in public contract state. |
| Makes network calls? | No direct network client or socket call. It submits a standard query through the chain host (`query_chain` ABI), which is not an arbitrary outbound network request from contract code. |
| Executes untrusted dynamic code? | No. No dynamic loader, evaluator, or code-instantiation mechanism is present in the committed source. |

## Residual risk and limitations

- The unrestricted Cargo graph includes the two vulnerable crates, so native builds/test tools and any native use of CosmWasm crypto remain in scope. The contract's current unit tests use mocks and do not process secret scalar values; no general approval is given for developers to pass secrets through native test tools.
- This is static analysis of the committed artifact and locked Cargo graphs. It is not a formal proof of compiler/linker correctness, supply-chain integrity, side-channel behavior of Diana's node implementation, or runtime acceptance.
- Wasm dependency names are stripped/unreliable. Attribution relies on exact target resolution and the pinned CosmWasm manifest, not absence of crate-name strings.
- The indirect reachability walk over-approximates possible table targets by matching every table function with each reachable call-indirect signature. It found no compatible crypto-wrapper signature reachable from the contract exports. It does not analyze Diana runtime internals or prove all behavior of the imported host functions.
- Public QoreChain documentation lists `cosmwasm-std 1.5+` and therefore documents API compatibility with 1.5.11. The exact internal wasmvm version bundled with Diana v3.2.9 is not stated in the docs, and this probe has not been uploaded or run; G0-A is not passed.
- This statement is limited to the Diana testnet feasibility probe and its exact source/lock/Wasm provenance. Future QoreLease product code can have different inputs, features, dependencies, execution paths, assets, and threat exposure. It needs a new security review and separate explicit risk acceptance; this acceptance conveys no approval to production.

## Reproducible evidence

- Wasm text emission and the pinned-image `wasm-opt --print-call-graph` command, including the exact immutable image digest, are recorded in `docs/WASM_DEPENDENCY_SECURITY_AUDIT.md`.
- Call-graph output: `docs/evidence/wasm-call-graph.log`.
- Entrypoint closure script and result: `docs/evidence/wasm-reachability.ps1` and `docs/evidence/wasm-entrypoint-reachability.txt`.
- Target/native feature and dependency evidence: `docs/evidence/cargo-tree-wasm-features.log`, `cargo-tree-wasm-generic-array-features.log`, `cargo-tree-host-generic-array-features.log`, `cargo-tree-wasm-kinds-zeroize.log`, `cargo-metadata-wasm.json`, and `cargo-metadata-unfiltered.json`.
- Probe source identity was checked against the committed blob (`5d32219acb1b50562c4a833a6328582445ccf11f`); no source or lockfile edits were made.

## Owner decision

> I acknowledge that the locked native/build/test dependency graph for the Diana staking-probe feasibility work contains `crypto-bigint 0.5.5` (RUSTSEC-2026-0387) and `curve25519-dalek 3.2.0` (RUSTSEC-2024-0344), with the paths and limitations documented above. Based on the reviewed target-specific graph and Wasm reachability analysis, I accept this residual risk only for the exact Diana testnet feasibility probe identified by source commit `724729bcfc34bb43131165bbbe49f90dace5926e` and Wasm SHA-256 `4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`. This acceptance does not cover production or future QoreLease product code, does not waive future dependency review, and does not authorize governance submission, upload, instantiation, signing, or transaction broadcast.

**Owner approval: ACCEPTED**
Owner: Project owner (decision communicated in this conversation)
Decision: Accept the documented residual risks solely for the exact Diana testnet staking-probe feasibility artifact and provenance identified above.
Date: 24 November 2026
Conditions: Scope, limitations, and non-transfer to production stated in this document remain in force. This acceptance does not authorize submission, upload, instantiation, signing, or transaction broadcast.

This owner decision addresses only this dependency-risk disposition. Proposal A remains a separate governance decision and is **not ready for submission solely because this acceptance exists**.
