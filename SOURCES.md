# ChronoQuota — Research Sources and Technical Reference Pack

**Last curated:** 23 November 2026  
**Purpose:** Give the coding/research agent a reliable starting set of official documentation, live endpoints, standards, source code, and prize-winning project references.  
**Important:** This list is not exhaustive. The agent is encouraged to inspect linked repositories, search beyond these sources, read new release notes, and verify every chain-dependent fact live.

---

## 1. Source hierarchy and research rules

Use sources in this order when there is a conflict:

1. Live QoreChain Diana testnet parameters, on-chain contract metadata/code hashes, and verified transaction behaviour.
2. Current official QoreChain documentation and governance proposals.
3. Exact source code and SDK/package versions that match the network/deployed contract.
4. Upstream standards and implementation sources such as CosmWasm/CW20, NIST, MCP, and x402.
5. Official ETHGlobal/DoraHacks winner records and project repositories.
6. Secondary articles and community write-ups.

For each technical assumption record: URL, read date, version, command/endpoint, observed result, and unresolved caveats. Do not hard-code a target address or ABI from this document without a live verification.

---

## 2. Official QoreChain hackathon resources

| Resource | URL | Why it matters |
|---|---|---|
| Build Before Q-Day home | https://build.qorechain.io/ | Official event description, current activity and developer entry point. |
| Rules | https://build.qorechain.io/rules | Eligibility, team size, timelines, required submission materials, project rules. |
| Prizes | https://build.qorechain.io/prizes | Official category requirements, including Cross-VM: EVM contract atomically calls approved Native contract; current prize information. |
| Project gallery | https://build.qorechain.io/projects | Inspect existing submissions and avoid duplicating current Cross-VM projects. |
| Developer kits | https://build.qorechain.io/kits | Official SDKs, templates and kits. |
| Workshop overview | https://docs.qorechain.io/build-before-qday/ | Current tutorial index and setup requirements. |
| Workshop 1 | https://docs.qorechain.io/build-before-qday/workshop-1/ | Basic dApp / QoreChain setup as linked from workshop index; confirm current URL from the index if moved. |
| Workshop 2 | https://docs.qorechain.io/build-before-qday/workshop-2/ | PQC account / agent material; use the live workshop index if moved. |
| Workshop 3 — Encrypted apps and Cross-VM | https://docs.qorechain.io/build-before-qday/workshop-3/ | Most important starting implementation. Includes EVM-to-Native bridge example, approved `qday-receipts` contract, scoped EVM window, success and rollback scenarios, and troubleshooting. |

### Cross-VM acceptance criteria

The official prize page is the source of truth for the category. Verify it again immediately before submission. The core requirement is a working EVM-to-Native call to an approved Native contract, with atomic execution demonstrated on testnet.

---

## 3. Core QoreChain technical documentation

| Topic | URL | What to extract |
|---|---|---|
| Cross-VM interoperability overview | https://docs.qorechain.io/developer-guide/cross-vm-interoperability/ | Which directions and lanes work today; synchronous vs queued calls; bridge/precompile constraints. |
| Cross-VM calls reference | https://docs.qorechain.io/developer-guide/cross-vm-reference/ | Current call fields, gas/limits, payload, failure behaviour, allowlist and return semantics. The page may be labelled v3.2.8 while Diana has moved to v3.2.9; reconcile with live data. |
| EVM precompiles | https://docs.qorechain.io/developer-guide/evm-precompiles/ | Addresses, active-precompile status, ABIs, empty-return behaviour and available functionality. |
| EVM authorization-window reference | https://docs.qorechain.io/developer-guide/evm-window-reference/ | Registered ML-DSA-87 key, opening/closing windows, scope, target restrictions, value and transaction caps, nonce behaviour. |
| Post-quantum signing | https://docs.qorechain.io/developer-guide/post-quantum-signing/ | QoreChain's ML-DSA/ML-KEM/SHAKE use and sign-bytes details. |
| PQC library | https://docs.qorechain.io/developer-tools/pqc-library/ | Official API and language bindings for ML-DSA-87, ML-KEM-1024 and SHAKE-256. |
| SDK/package overview | https://docs.qorechain.io/developer-tools/overview/ | Current package list, chain endpoints, package names and network parameters. |
| Chain Developer Kit | https://docs.qorechain.io/developer-tools/chain-dev-sdk/ | Current EVM window helpers, QoreChain SDK workflows and network requirements. |
| Governance proposals for Native contracts | https://docs.qorechain.io/developer-guide/governance-proposals-contracts/ | How to store/instantiate a CosmWasm contract and add it to the Cross-VM allowlist via governance; checked against Diana on 22 Nov 2026. |
| CosmWasm gas and limits | https://docs.qorechain.io/developer-guide/cosmwasm-gas-and-limits/ | Native contract upload limits, gas and build considerations. |
| QoreChain feature/version status | https://docs.qorechain.io/introduction/key-features/ | Release history and feature status. Verify against the newest live version; documentation pages may lag. |
| QoreChain version history | https://docs.qorechain.io/appendix/version-history/ | Upgrade notes, circuit-breaker and contract upload restrictions. |

### Important snapshot facts to re-verify

- Diana testnet EVM chain ID: `9800`.
- Diana chain ID: `qorechain-diana`.
- Official governance-proposal guide reports Diana v3.2.9 since 20 November 2026.
- Synchronous EVM-to-Native bridge precompile: `0x0000000000000000000000000000000000000901`.
- Documented function: `executeCrossVMCall(uint8 targetVM, string targetContract, bytes payload)`.
- `targetVM = 1` denotes QoreChain Native / CosmWasm.
- Mainnet Cross-VM is paused/not the target for the hackathon demo; confirm live state before relying on this.
- The Cross-VM reference page may still carry the v3.2.8 label. Treat live network endpoints and latest governance guide as necessary checks.
- The synchronous precompile requires a governance-approved Native target. It can return empty data if inactive; low-level Solidity must check `ok` and response length.
- Native reads should use Native REST smart queries; do not assume the EVM bridge supports `STATICCALL` queries.
- Ordinary EVM txs use secp256k1 but require the account to have a registered ML-DSA-87 key and a live Native-lane hybrid-authorized EVM window. Do not claim that each EVM tx itself carries an ML-DSA signature.

---

## 4. Live Diana endpoints to inspect before deployment

These endpoints are for reads. Use them in a read-only preflight script and retain the raw JSON output in `docs/RESEARCH_LOG.md`.

| Endpoint | Purpose |
|---|---|
| `https://api-testnet.qore.host/qorechain/crossvm/v1/params` | `enabled`, `bridge_allowed_targets`, `bridge_target_pins`, and current Cross-VM limits. |
| `https://api-testnet.qore.host/cosmos/circuit/v1/disable_list` | Confirm whether `/qorechain.crossvm.v1.MsgCrossVMCall` is disabled. |
| `https://api-testnet.qore.host/cosmos/evm/vm/v1/params` | Inspect `active_static_precompiles`. |
| `https://api-testnet.qore.host/cosmwasm/wasm/v1/codes/params` | Inspect code-upload permissions. |
| `https://api-testnet.qore.host/cosmwasm/wasm/v1/code?pagination.reverse=true&pagination.limit=1` | Read current latest Native code ID. |
| `https://api-testnet.qore.host/cosmwasm/wasm/v1/code/{CODE_ID}` | Inspect stored code metadata and data hash. |
| `https://api-testnet.qore.host/cosmwasm/wasm/v1/code/{CODE_ID}/contracts` | List contracts instantiated from a code ID. |
| `https://api-testnet.qore.host/cosmwasm/wasm/v1/contract/{CONTRACT_ADDRESS}` | Inspect Native contract metadata, code ID, admin. |
| `https://api-testnet.qore.host/cosmwasm/wasm/v1/contract/{CONTRACT_ADDRESS}/history` | Inspect contract code history and pin information. |
| `https://api-testnet.qore.host/cosmwasm/wasm/v1/contract/{CONTRACT_ADDRESS}/smart/{BASE64_QUERY}` | Execute a read-only Native smart query. Base64-encode the JSON query. |
| `https://api-testnet.qore.host/qorechain/pqc/v1/evm_window/{QOR1_ADDRESS}` | Inspect a QoreChain EVM authorization window. |
| `https://evm-testnet.qore.host` | EVM JSON-RPC. |
| `https://rpc-testnet.qore.host:443` | Consensus RPC endpoint used in official CLI examples. |

### Current documented Native receipt target

The official Workshop 3 guide identifies:

```text
qday-receipts:
qor1xjayq5ev55tkzpml9klxwyshr7gdrha0nurha9jhm0f0gdckksgs3gltw8
```

Its documented execute/query schemas are in Workshop 3. It is an append-only receipt contract and a useful rollback demonstration target, **not** a purpose-built quota engine.

### WDT candidate — re-verify before any use

The previous research report identified this candidate WDT CW20 address:

```text
qor14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9s93uuqt
```

Do not assume it is currently in `bridge_allowed_targets`. Verify the live Cross-VM params, code ID, code hash, contract metadata and query/execute schema.

---

## 5. Critical CW20 semantics source

| Source | URL | Why it matters |
|---|---|---|
| CW20 README / semantics | https://github.com/CosmWasm/cw-plus/blob/main/packages/cw20/README.md | Documents `IncreaseAllowance`, `DecreaseAllowance`, expiry and the intentional saturating-to-zero behaviour. |
| CW20-base contract | https://github.com/CosmWasm/cw-plus/blob/main/contracts/cw20-base/src/contract.rs | Shows execute dispatch and which allowance functions are called. |
| CW20 allowance implementation | https://github.com/CosmWasm/cw-plus/blob/main/contracts/cw20-base/src/allowances.rs | Inspect exact `execute_decrease_allowance`, `execute_increase_allowance`, and `deduct_allowance` implementation. |
| CW20 package types | https://github.com/CosmWasm/cw-plus/blob/main/packages/cw20/src/msg.rs | Exact message fields and `Expiration` type. |

**Key caution:** `DecreaseAllowance` is not a generic checked quota decrement. The upstream interface describes it as robust: reducing by the current amount or more clears the allowance rather than behaving like an underflow error. Do not assume that a pre-existing expiry will make every `decrease_allowance` call fail after expiration. Inspect exact deployed code and test its behaviour. A purpose-built Native state machine with explicit height checks and checked arithmetic is preferred for real capability enforcement.

---

## 6. QoreChain starter source code and packages

| Source | URL | Use |
|---|---|---|
| Build Before Q-Day workshops | https://github.com/qorechain/build-before-qday | Use Workshop 3 as the smallest known EVM-to-Native working implementation and adapt its code with attribution. |
| QoreChain core | https://github.com/qorechain/qorechain-core | Protocol source, changelog, precompile and Cross-VM behaviour. Use the correct release/tag for the testnet. |
| QoreChain PQC library | https://github.com/qorechain/qorechain-pqc | Canonical cross-language PQC implementation and test vectors. |
| QoreChain SDK | https://www.npmjs.com/package/@qorechain/sdk | Check current published package version and helpers. |
| QoreChain EVM package | https://www.npmjs.com/package/@qorechain/evm | Check current ABI and precompile helpers. |
| QoreChain RDK | https://www.npmjs.com/package/@qorechain/rdk | Reference for Cross-VM encoder helpers as documented by QoreChain. |
| QoreChain PQC package | https://www.npmjs.com/package/@qorechain/pqc | TypeScript/JavaScript PQC operations. |
| QoreChain QoreSeal docs | https://docs.qorechain.io/developer-tools/qoreseal/ | Optional encrypted payload approach; do not add to MVP unless useful. |

Before pinning versions, inspect the package registry, repository release tags, changelog, current docs, and example lockfiles. Prefer the versions used by the current official Workshop 3.

---

## 7. Competitive research — confirmed winners only

These projects are included because their official organizer or ETHGlobal pages confirm a prize/award. Use them as architecture and product research. Do not copy their code without respecting the license and attribution. Do not claim ChronoQuota invented features they already demonstrate.

### 7.1 AgentFabric — closest overall product precedent

- **Award:** Cronos x402 PayTech Hackathon, Main Track / x402 Applications, 1st place; Cronos announced a $24,000 Cronos Ignition Builder Residency.
- **Official winner announcement:** https://blog.cronos.com/p/announcing-the-cronos-x402-hackathon
- **DoraHacks submission:** https://dorahacks.io/buidl/38376
- **Source repository:** https://github.com/nschwermann/agent_fabric
- **Demo:** https://www.youtube.com/watch?v=xfvH6TqvJd8
- **What it demonstrates:** Scoped session keys, smart-account permissions, paid APIs through x402, API proxies, reusable workflows, MCP servers, and bounded agent execution without giving the agent the owner's primary key.
- **Research questions:** How does it create/deploy the smart account? Where is scope enforced? What does the session key actually sign? How do x402 quote/verification/settlement work? What is off-chain versus on-chain? How are workflow APIs exposed to MCP?
- **ChronoQuota differentiation to prove:** Native capability/quota lifecycle, atomic Native reservation + EVM escrow state, provider receipt and job-state binding, and independent dual-VM invariant checks. Do not merely rebuild scoped permissions + MCP + x402.

### 7.2 ETHGlobal winners relevant to agent authority

| Project | Confirmed award | Official page | Architectural pattern to study |
|---|---|---|---|
| Harness | ETHOnline 2026 — Ledger AI Agents x Ledger, 1st | https://ethglobal.com/showcase/harness-vvvaq | Per-agent isolated execution environment, identity, owner-defined spending limit, hardware approval for escalation. |
| Kagi Wallet | ETHGlobal Tokyo 2026 — Intercepta, 1st | https://ethglobal.com/showcase/kagi-wallet-tc9fp | Threshold wallet authority, capped/expiring delegated keys, hardware threshold approvals. |
| Signel | ETHGlobal Cannes 2026 — Ledger AI Agents x Ledger, 1st | https://ethglobal.com/showcase/signel-jfdgu | Contract/function selector/amount/period-scoped delegated permissions. |
| allowance.eth | ETHGlobal New York 2026 — ENS award | https://ethglobal.com/showcase/allowance-eth-ejosk | Policy attached to agent identity, natural language to validated policy JSON, on-chain PolicyGuard. |
| AgentGate | ETHGlobal Cannes 2026 — World AgentKit, Best use of Agent Kit, 1st | https://ethglobal.com/showcase/agentgate-scs65 | Provider-facing pay-per-call API gateway, API registration, x402 service access and pricing. |

### 7.3 ETHGlobal winners relevant to usage-based agent commerce

| Project | Confirmed award | Official page | Pattern |
|---|---|---|---|
| Turnstile | ETHOnline 2026 sponsor awards (verify exact sponsor/category on the official project page before citing it in submission) | https://ethglobal.com/showcase/turnstile-ovks1 | Agent-to-agent paid analysis/API consumption. |
| AgentGate | Cannes 2026 — World AgentKit, 1st | https://ethglobal.com/showcase/agentgate-scs65 | Pay-per-call provider gateway. |
| AgentFabric | Cronos x402 PayTech Hackathon — Main Track, 1st | https://dorahacks.io/buidl/38376 | End-to-end agent execution fabric, MCP, scoped session keys, x402. |

When using Turnstile in external claims, re-check its live official page and prize label. If the precise award is not visible, discuss it as a technical reference, not as a confirmed prize winner.

---

## 8. Standards and protocol references

| Topic | URL | Relevance |
|---|---|---|
| x402 neutral documentation | https://github.com/x402-foundation/x402/tree/main/docs | Open HTTP 402 payment protocol, client/server/facilitator flows, batch settlement. |
| x402 introduction | https://github.com/x402-foundation/x402/blob/main/docs/introduction.md | High-level payment flow and terminology. |
| MCP specification — tools | https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/docs/specification/2026-07-28/server/tools.mdx | MCP tool discovery and invocation semantics; review current specification version and security guidance. |
| NIST FIPS 204 — ML-DSA | https://csrc.nist.gov/pubs/fips/204/final | Official standard for post-quantum digital signatures. |
| NIST FIPS 203 — ML-KEM | https://csrc.nist.gov/pubs/fips/203/final | Official standard for post-quantum key encapsulation. |
| NIST post-quantum standards overview | https://www.nist.gov/pqc | Broader standards and transition guidance. |

Use QoreChain's official `@qorechain/pqc` and protocol-compatible helpers for implementation. Do not create a modified ML-DSA or ML-KEM implementation.

---

## 9. Suggested research questions for the coding agent

The agent should go beyond this list, but these are useful starting questions:

1. What is the exact return-data encoding of `executeCrossVMCall` on the current Diana version? Verify via a minimal transaction and the latest QoreChain source.
2. What is the exact `pqcVerify` ABI and how are message digest, public key and signature bytes passed? What is the gas requirement?
3. Which EVM authorization-window settings are required for a contract to invoke `0x0901` under the latest network version?
4. What is the currently live allowlist and code pin list? Do not use an old list.
5. Can a custom CosmWasm contract be stored, instantiated, and allowlisted within the time and governance constraints? What exact deposit and vote process is live?
6. What Native caller identity does the EVM precompile present to CosmWasm (`info.sender`)? Verify experimentally and use it in access control.
7. Can a single Native quota state machine support atomic reserve/finalize/cancel while remaining within gas/message limits?
8. What are the reentrancy and nested execution semantics of the EVM bridge? Use the current QoreChain core source and testnet.
9. How should the provider's receipt be domain-bound to chain, contract, capability, job, provider, tool-version hash, usage, and price?
10. What are the failure and timeout economics? Failed synchronous calls still consume gas; design tests and user messaging accordingly.
11. Does using a custom Native quota contract provide a real multi-provider/shared-state advantage over an EVM-only contract? If not, challenge the product thesis rather than adding an unnecessary VM call.
12. What would be required to support multiple parallel reservations without overspending or deadlocking a capability?

---

## 10. How to cite and credit these sources

- Credit QoreChain Workshop 3, SDKs, starter code, packages, and any templates used.
- Credit AgentFabric, Harness, Kagi Wallet, Signel, allowance.eth, AgentGate, and other studied projects in internal research notes and product differentiation documents. Do not imply endorsement or affiliation.
- Verify the license of any code imported from a third-party repository. Do not copy code from a project with an incompatible or unclear license.
- Keep a research log with exact commits/tags and the date checked.
- Re-check QoreChain network status and the hackathon rules before final submission because network/governance state and event rules may change.
