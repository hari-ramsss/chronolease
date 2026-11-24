# QoreLease — Technical Source Reference

This file is the source index for the implementation agent. It is intentionally separate from the product README so the agent can retrieve primary material without treating this specification as a substitute for the chain's own documentation.

**Last reviewed:** 24 November 2026  
**Target network:** QoreChain Diana testnet (`qorechain-diana`)  
**Reference hierarchy:** Current QoreChain documentation and live network parameters take precedence over this file. QoreChain source code / released binaries take precedence over older tutorials. General CosmWasm documentation explains standard APIs but does not prove QoreChain enables them.

---
## main source (use this source for building it has all the kits required for the startup)
https://build.qorechain.io/kits
## 1. Read these first — essential QoreChain documentation

### 1.1 Cross-VM Interoperability

URL: https://docs.qorechain.io/developer-guide/cross-vm-interoperability/

Use this for:
- The architecture of EVM, QoreChain Native, and SVM.
- Difference between synchronous and queued cross-VM calls.
- EVM-to-Native precompile address `0x0000000000000000000000000000000000000901`.
- `executeCrossVMCall(uint8,string,bytes)` input shape.
- `targetVM = 1` for Native / CosmWasm.
- UTF-8 JSON execute payload for Native contracts.
- Raw response bytes.
- Message limits, gas, allowlist and network status.
- The warning that an inactive precompile can return empty data without executing the target.

Important implementation points:
- Fail closed on empty or malformed return data.
- Re-check the live cross-VM parameters before every test.
- Do not attach Native funds through the EVM precompile.
- Do not use the asynchronous path for a workflow that requires same-transaction escrow and reservation.

### 1.2 Cross-VM Calls Reference (v3.2.8)

URL: https://docs.qorechain.io/developer-guide/cross-vm-reference/

Use this for:
- Exact cross-VM message fields and execution behaviour.
- Caller / sender identity mapping.
- Authorization-window requirements.
- Error conditions and payload size.
- Atomic transaction behaviour.

Particularly important details to verify against the current page:
- A Solidity contract calling the bridge is represented to the Native contract through its `qor1...` address mapping.
- A revert anywhere in the enclosing EVM transaction is intended to undo the Native side as well.
- The `0x0901` call needs an open EVM authorization window that admits it.
- The target must be present in `bridge_allowed_targets` and its code pin must match.
- A Native contract invoked through the bridge must not assume `info.sender` is the original human buyer. It is the mapped caller identity described by the cross-VM docs.

### 1.3 EVM Precompiles and live network status

URL: https://docs.qorechain.io/developer-guide/evm-precompiles/

Use this for:
- Current precompile addresses and live active/inactive state.
- Difference between Diana testnet and Vladi mainnet.
- PQC verification precompiles if used in monitor-report verification.
- Important warning: a call to an address not active as a precompile can succeed with empty return data.

Do not assume the AI risk / anomaly precompiles are active. Do not assume the mainnet and testnet precompile lists match.

### 1.4 QoreChain Native Development

URL: https://docs.qorechain.io/developer-guide/cosmwasm-development/

Use this for:
- Native contract lifecycle: build, store, instantiate, execute, query.
- CosmWasm contract entry points and project prerequisites.
- Contract storage and smart-query examples.
- Module integration.
- QoreChain-specific gas / upload constraints.

The page demonstrates Native contract integration with:
- `BankMsg::Send` for native QOR (`uqor`) transfers.
- `StakingMsg::Delegate` for delegation operations.

**Do not over-interpret this page:** it demonstrates staking messages but does not establish that `StakingQuery::AllDelegations` is enabled for QoreChain CosmWasm contracts. That is a separate feasibility test.

### 1.5 Governance Proposals for Contracts: Upload Native Code and Open Cross-VM Access

URL: https://docs.qorechain.io/developer-guide/governance-proposals-contracts/

Use this for:
- Testnet Native code upload through governance.
- Contract instantiation procedure.
- Adding a Native contract to `bridge_allowed_targets`.
- Pinning the target to a specific code ID and code history length.
- Building reproducible Wasm checksums.
- Governance proposal deposits, voting windows, thresholds, hybrid signing, and troubleshooting.

Important:
- Read the live governance parameters before submitting anything.
- The page's 22 November 2026 figures are a snapshot, not permanent constants.
- A proposal submission is not approval.
- Prefer a no-admin deployment where appropriate; record and verify the actual code pin.
- `MsgUpdateParams` for Cross-VM can replace the whole parameter set. Preserve every current field and modify only the intended target / pin entries.

### 1.5.1 Optimizer image and WSL2 environment

Official optimizer source: https://github.com/CosmWasm/optimizer

The approved project build procedure pins `cosmwasm/optimizer:0.16.1`. The
official optimizer documentation identifies `cosmwasm/optimizer` as the
x86_64/default image and warns ARM images produce different Wasm bytes. On
24 November 2026 the tag was pulled for `linux/amd64` and resolved to immutable
image `cosmwasm/optimizer@sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e`.
The image reported Rust/Cargo 1.81.0 and `wasm-opt` 116. Two builds of the
standalone `contracts/staking-probe` crate produced identical Wasm SHA-256
`4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`.

The existing lockfile was adjusted only at dependency-resolution level to pin
`base64ct 1.7.3` and `zeroize 1.8.1`, versions parseable by optimizer Cargo
1.81; the earlier lockfile is retained under `docs/evidence/`. Keep the resulting
`contracts/staking-probe/Cargo.lock` with the source. Build command, artifact
size, checksums, and full logs are recorded in `docs/DEPLOYMENT_RUNBOOK.md` and
`docs/FEASIBILITY_SPIKES.md`. The official optimizer README explains the x86_64
image choice and notes that ARM builds differ:
https://github.com/CosmWasm/optimizer#notice. No proposal was prepared.

### 1.6 CosmWasm Gas, Pricing and Upload Limits

URL: https://docs.qorechain.io/developer-guide/cosmwasm-gas-and-limits/

Use this for:
- Current Native Wasm gas model.
- Per-block and per-transaction Wasm budget.
- Dynamic congestion pricing.
- Upload and module restrictions.
- Simulation and gas safety margin.

Do not hard-code gas from old Workshop examples. Simulate the real transaction on the target testnet and apply the current documented margin.

### 1.7 EVM Authorization Window Reference

URL: https://docs.qorechain.io/developer-guide/evm-window-reference/

Use this for:
- ML-DSA-87 / hybrid key registration requirements.
- Opening, closing, and reading EVM authorization windows.
- Transaction count, block duration, value cap, and target scoping.
- `allowed_targets` and version-specific query fields.
- Why the classical EVM key alone cannot open the authorization window.

The exact scope needed for the app's EVM transaction and internal precompile call must be verified on Diana. Do not assume the window only needs the EVM escrow address, or only needs `0x0901`; run the transaction and inspect the current scope rules.

### 1.8 Workshop 3 — CrossVmCheckout

URL: https://docs.qorechain.io/build-before-qday/workshop-3/

Official example repository:
https://github.com/qorechain/build-before-qday/tree/main/workshop-3/02-cross-vm

Use this as the canonical starter for:
- Foundry / Solidity project setup.
- Rust Native contract project setup.
- `CrossVmCheckout` contract interaction with `qday-receipts`.
- Bridge call scripts and EVM authorization window helpers.
- Native contract deployment / interaction scripts.
- Successful cross-VM execution and rollback test cases.

The workshop intentionally demonstrates a simple EVM counter plus Native receipt. QoreLease must go beyond this by implementing provider eligibility, provider-side capacity accounting, service-bond state, real workload execution, and measured settlement. Do not represent the workshop receipt book as a QoreLease registry.

---

## 2. Staking-query research — critical feasibility question

### 2.0 QoreChain runtime source wiring (supporting evidence only)

Source: https://github.com/qorechain/qorechain-core/blob/main/app/app.go

The current `main` source passes `app.StakingKeeper` into
`wasmkeeper.NewKeeper`. This establishes keeper wiring at that source revision,
but does not itself prove the deployed Diana v3.2.9 query router exposes
`StakingQuery::AllDelegations`. The inspected branch was not tied to the
deployed binary; G0-A remains a required on-chain probe.

### 2.1 CosmWasm standard-library definition

Source code:
https://github.com/CosmWasm/cosmwasm/blob/main/packages/std/src/query/staking.rs

This source defines `StakingQuery::AllDelegations { delegator: String }` and the corresponding `AllDelegationsResponse` structure in the standard library.

**This proves only that the API exists in the CosmWasm standard library. It does not prove QoreChain's deployed Wasm query router exposes it to contracts.**

### 2.2 QoreChain staking guide

URL: https://docs.qorechain.io/user-guide/staking-and-delegation/

Use this to understand:
- QOR staking and delegation behaviour.
- Native account and validator address formats.
- Unbonding, lock, and stake semantics.
- Current staking tier / lock rules.

Do not treat a REST/CLI staking query as proof that a CosmWasm contract can execute the same query internally.

### 2.3 QoreChain CLI staking query reference

URL: https://docs.qorechain.io/cli-reference/query-commands/

The CLI documentation includes a delegations query. Use the CLI / REST result as an independent reference when comparing the contract probe output.

Example query:

```bash
qorechaind query staking delegations <QOR_ADDRESS> --node https://rpc-testnet.qore.host:443
```

### 2.4 Required spike

Implement a minimal contract that tries the standard `query_all_delegations` / `StakingQuery::AllDelegations` route against the deployed Diana runtime. Record:

- Rust / `cosmwasm-std` versions.
- Wasm optimizer image and checksum.
- Contract code ID and address.
- Exact execute message and transaction hash.
- Query result stored by the contract.
- Matching CLI / REST query for the same provider.
- Whether the contract was invoked directly by a Native transaction, through the EVM bridge, or both.
- Which stake categories are returned and excluded.

If an unsupported-query error occurs, capture the exact response and stop. Do not replace it with an off-chain trusted API result while retaining a claim of on-chain staking admission.

---

## 3. QoreChain SDK / client references

### 3.1 QoreChain SDK overview

URL: https://docs.qorechain.io/sdk/overview/

Use this for the official SDK's network model, Native / EVM clients, account derivation, transaction submission, and current package surfaces.

### 3.2 SDK quickstart / repository

Repository: https://github.com/qorechain/qorechain-sdk

Use the current repository README and package docs rather than relying on a package snippet copied from an older tutorial. Confirm the published package version and API signatures before coding.

### 3.3 QoreChain SDK examples

URL: https://docs.qorechain.io/sdk/examples/

Use this for:
- Native smart queries.
- Reading deployed contract metadata.
- Client initialization.
- Current supported SDK examples.

### 3.4 Testnet connection details

URL: https://docs.qorechain.io/getting-started/connecting-to-testnet/

Current documented public Diana endpoints:

| Interface | Endpoint |
|---|---|
| Native REST | `https://api-testnet.qore.host` |
| Consensus RPC | `https://rpc-testnet.qore.host` |
| EVM JSON-RPC | `https://evm-testnet.qore.host` |
| EVM WebSocket | `wss://evm-ws-testnet.qore.host` |
| Explorer | `https://explore.qore.network` (select Testnet) |

The endpoints are shared and rate-limited. Use test accounts only.

---

## 4. Live network checks and useful endpoints

Run these checks immediately before deployment and preserve their output in `docs/evidence/`.

```bash
# Current cross-VM parameters, enabled state, allowlist, code pins, and limits
curl -s https://api-testnet.qore.host/qorechain/crossvm/v1/params | jq

# Current active / disabled circuit-breaker message types
curl -s https://api-testnet.qore.host/cosmos/circuit/v1/disable_list | jq

# CosmWasm upload parameters
curl -s https://api-testnet.qore.host/cosmwasm/wasm/v1/codes/params | jq

# Governance voting parameters; re-read all fields before any proposal
curl -s https://api-testnet.qore.host/cosmos/gov/v1/params/voting | jq

# Native staking delegations for comparison with the contract staking probe
curl -s "https://api-testnet.qore.host/cosmos/staking/v1beta1/delegations/<QOR_ADDRESS>" | jq

# EVM authorization-window state
curl -s "https://api-testnet.qore.host/qorechain/pqc/v1/evm_window/<QOR_ADDRESS>" | jq

# Confirm EVM chain ID
cast chain-id --rpc-url https://evm-testnet.qore.host
```

Expected EVM chain ID for Diana: `9800` (`0x2648`). Confirm from live RPC rather than assuming.

### Useful contract verification endpoints

```bash
# Contract metadata / code ID / admin
curl -s "https://api-testnet.qore.host/cosmwasm/wasm/v1/contract/<CONTRACT_ADDRESS>" | jq

# Contract code info / checksum
curl -s "https://api-testnet.qore.host/cosmwasm/wasm/v1/code/<CODE_ID>" | jq

# Code history
curl -s "https://api-testnet.qore.host/cosmwasm/wasm/v1/contract/<CONTRACT_ADDRESS>/history" | jq
```

Use the current documented API response structure and confirm it against the live gateway before parsing fields in scripts.

---

## 5. Denominations, addresses, and unit handling

### QOR denomination

QoreChain Native uses:
- Display denomination: `QOR`.
- Base denomination: `uqor`.
- Conversion: `1 QOR = 1,000,000 uqor` (6 decimals).

The EVM represents QOR using 18-decimal conventions. Confirm the exact token / bank bridge behaviour and never compare the Native integer amount directly with an EVM wei amount without conversion.

### Address formats

- Native account address: `qor1...`.
- Validator operator address: `qorvaloper1...`.
- EVM account / contract: `0x...`.

A unified key/account mapping does not mean the address strings are interchangeable. Use the documented SDK / chain address-conversion mechanism and verify the mapped identity for the deployed EVM escrow contract.

### fUSD

The Diana faucet documents test assets including fUSD. The agent must discover and verify the actual fUSD contract address, decimals, token behaviour, and faucet path on the live testnet. Do not guess or hard-code an address copied from an unrelated test deployment. Use a local mock token for deterministic unit tests if needed; use the actual supported test token for final integration.

---

## 6. Governance and custom contract deployment

### Required reading

https://docs.qorechain.io/developer-guide/governance-proposals-contracts/

The documented Diana workflow requires governance for code storage and Cross-VM allowlisting. The allowlist target is pinned to its code ID and code history length.

### Items to confirm from live chain state

- `code_upload_access`.
- `MsgStoreCode` circuit-breaker status.
- `instantiate_default_permission`.
- Current proposal deposit and voting parameters.
- Existing `bridge_allowed_targets` entries.
- Existing `bridge_target_pins` entries.
- Every current Cross-VM parameter field before constructing `MsgUpdateParams`.
- Whether the target code can be deployed without an admin.
- Whether the contract history length and code ID remain exactly as pinned.

Do not copy a stale complete Cross-VM parameter JSON object from this document or a prior proposal. A parameter update may replace the whole set. Fetch the current object and change only the intended allowlist / pin entries.

### Governance evidence to retain

- Wasm source commit.
- Optimizer image and architecture.
- SHA-256 checksum.
- Code upload proposal JSON.
- Instantiation proposal JSON, if separate.
- Allowlist proposal JSON.
- Proposal IDs and final status.
- Code ID and contract address.
- Contract history.
- Live allowlist and code pin query output.

---

## 7. General CosmWasm references

These sources explain standard Rust / CosmWasm development. Always check compatibility with the CosmWasm / wasmd versions actually deployed by QoreChain.

- CosmWasm documentation: https://docs.cosmwasm.com/
- CosmWasm standard library: https://github.com/CosmWasm/cosmwasm
- `StakingQuery` source: https://github.com/CosmWasm/cosmwasm/blob/main/packages/std/src/query/staking.rs
- `BankMsg` / `StakingMsg` standard APIs: https://docs.rs/cosmwasm-std/latest/cosmwasm_std/
- `cw-multi-test` repository: https://github.com/CosmWasm/cw-multi-test

Important: `cw-multi-test` is useful for fast unit / contract-flow tests, but it does not prove QoreChain-specific query-router support, precompile execution, governance allowlisting, or cross-runtime rollback. Those require QoreChain integration tests.

---

## 8. Solidity / Foundry references

Use the current official tools and pin versions in the repository:

- Foundry book: https://book.getfoundry.sh/
- Solidity documentation: https://docs.soliditylang.org/
- OpenZeppelin Contracts: https://docs.openzeppelin.com/contracts/
- QoreChain EVM development: https://docs.qorechain.io/developer-guide/evm-development/
- QoreChain EVM precompiles: https://docs.qorechain.io/developer-guide/evm-precompiles/

The bridge call should be isolated in a small library / interface. Keep the low-level call and response validation explicit. Do not assume OpenZeppelin's standard ERC-20 wrappers solve the chain-specific Cross-VM response or authorization-window requirements.

---

## 9. Current facts versus assumptions

| Statement | Status | Source / proof required |
|---|---|---|
| QoreChain Native is the CosmWasm runtime | Documented | QoreChain Native Development |
| Diana has a synchronous EVM-to-Native bridge at `0x0901` | Documented, but live status must be re-read | Cross-VM Interoperability + EVM Precompiles |
| Bridge target must be allowlisted | Documented | Cross-VM + Governance Proposals |
| Bridge call runs in same EVM transaction and is rolled back on EVM revert | Documented; must be integration-tested for this project's message effects | Cross-VM Reference + G0-D |
| EVM caller identity is mapped to a Native address | Documented; verify actual deployed escrow mapping | Cross-VM Reference + G0-C |
| Native contracts can emit `BankMsg::Send` | Documented as general Native module integration | Native Development; separately test from bridge context |
| Native contracts can emit `StakingMsg::Delegate` | Documented as general Native module integration | Native Development; separately test from bridge context |
| `StakingQuery::AllDelegations` exists in standard CosmWasm | Confirmed in standard library source | CosmWasm `staking.rs` |
| QoreChain Diana exposes `StakingQuery::AllDelegations` to deployed contracts | **Not verified** | Must pass G0-A |
| A bridge-invoked contract can safely emit Native bank messages with full rollback semantics | **Not verified for QoreLease path** | Must pass G0-B |
| Provider declared capacity matches physical API/GPU capacity | Not provable by registry alone | Requires independent provider/monitor assumptions |
| Monitor-signed SLA report is objectively truthful | Not guaranteed by signature | Requires independent measurement / challenge assumptions |
| Mainnet can run this Cross-VM architecture today | Not supported by current docs | Mainnet bridge / Native contract availability must be re-checked; target is Diana testnet |

---

## 10. Research discipline for the coding agent

When a question is not answered by this file:

1. Search the QoreChain docs for the exact feature and current release.
2. Open the primary documentation page; do not rely only on search snippets.
3. Inspect the official SDK or chain source if the docs are ambiguous.
4. Check live Diana parameters for current network state.
5. Build a minimal reproducer if the question concerns runtime behaviour.
6. Record the result in `docs/FEASIBILITY_SPIKES.md` or an ADR.
7. Update this source index with the exact source URL, version / date, and the conclusion.

Never invent an API, precompile, contract address, ABI, message type, query route, or governance result. If a capability remains unknown, label it `NOT VERIFIED` and stop work that depends on it.

## Phase 0 artifact and proposal review

The official optimizer build, its reproducibility evidence, and current local
milestone state are recorded in `docs/FEASIBILITY_SPIKES.md` and
`docs/DEPLOYMENT_RUNBOOK.md`. The unsigned upload-only Proposal A bundle is in
`artifacts/proposals/`; it is prepared for review only and has not been submitted.
The probe source inputs are public at commit
[`724729bcfc34bb43131165bbbe49f90dace5926e`](https://github.com/hari-ramsss/chronolease/commit/724729bcfc34bb43131165bbbe49f90dace5926e).
QoreChain's current proposal
message sequence and limits are documented at the [governance proposal guide](https://docs.qorechain.io/developer-guide/governance-proposals-contracts/)
and [CosmWasm gas and upload limits](https://docs.qorechain.io/developer-guide/cosmwasm-gas-and-limits/).

## G0-A source provenance and security audit (24 November 2026)

The probe build inputs are captured in public commit [724729bcfc34bb43131165bbbe49f90dace5926e](https://github.com/hari-ramsss/chronolease/commit/724729bcfc34bb43131165bbbe49f90dace5926e). The Proposal A review remains **NOT READY FOR SUBMISSION** because of the dependency findings. See `docs/SOURCE_PROVENANCE_G0A.md`.

The actual optimized Wasm passed the independent parser/wasm-opt limits audit; measured values and exact commands are in `docs/WASM_ARTIFACT_AUDIT.md`. `cargo audit` found vulnerabilities in transitive `crypto-bigint 0.5.5` (RUSTSEC-2026-0387) and `curve25519-dalek 3.2.0` (RUSTSEC-2024-0344), and marked `derivative 2.2.0` unmaintained (RUSTSEC-2024-0388). No dependency changes were made; full output and the compatibility lock diff are retained in `docs/evidence/` and summarized in `artifacts/proposals/DEPENDENCY_AUDIT.md`.
