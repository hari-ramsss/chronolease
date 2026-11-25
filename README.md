# QoreLease

> **Agentic capacity reservation and verified service settlement on QoreChain.**
>
> QoreLease is a proposed protocol for reserving measurable API / AI-inference capacity from service providers. QoreChain Native is intended to own provider-side commitments and capacity state; the EVM is intended to hold buyer-side fUSD escrow and settle verified delivery. The design is conditional on the Native-runtime feasibility checks in this document.

**Project status:** Phase 1 local implementation complete; live Diana integration gates still open  
**Target network:** QoreChain Diana testnet (`qorechain-diana`, EVM chain ID `9800`)  
**Target hackathon category:** Cross-VM  
**Primary implementation document:** This README  
**Technical source index:** [`SOURCES.md`](SOURCES.md)

> **Phase 1 implementation note (25 November 2026):** The project owner directed
> implementation to begin before G0-A..E were closed. Actual code now exists in
> `contracts/qorelease-registry/`, `contracts/evm/`, and
> `services/provider-adapter/`. All tests are **local**: 12 Rust, 13 Foundry, and
> 7 adapter tests pass, plus one combined local end-to-end run
> (`scripts/local-e2e.ps1`). The accepted staking probe, optimized Wasm,
> checksums, evidence, and Proposal A artifacts are preserved unchanged.
> No Diana transaction, proposal, upload, or instantiation occurred. The bridge
> response encoding, staking-query semantics, mapped EVM sender identity, and
> bridge rollback remain **NOT VERIFIED**. See `docs/ARCHITECTURE.md`,
> `docs/TEST_PLAN.md`, `docs/decisions/`, and `docs/FEASIBILITY_SPIKES.md`.

---

## 0. Instructions for the coding agent — read first

**Current state (25 November 2026): Phase 1 local implementation is already committed.**
Do not redo the original Phase 0 deliverables. Read the implemented code and the
current interface/test documents before making changes.

1. Read this README, [`SOURCES.md`](SOURCES.md), `docs/ARCHITECTURE.md`,
   `docs/INTERFACES.md`, `docs/STATE_MACHINES.md`, `docs/TEST_PLAN.md`, and
   `docs/decisions/ADR-0001..0008.md`.
2. The Phase 1 code lives in `contracts/qorelease-registry/` (Native),
   `contracts/evm/` (Solidity escrow and bridge service), and
   `services/provider-adapter/` (TypeScript). Run
   `powershell -ExecutionPolicy Bypass -File scripts/local-e2e.ps1` to reproduce
   the local tests before changing anything.
3. The accepted `contracts/staking-probe/`, optimized Wasm, checksums, evidence,
   and Proposal A artifacts must be preserved. They are not product code.
4. G0-A..E are still **NOT VERIFIED on Diana**. Local mocks prove logic only;
   never describe them as Diana compatibility. Marking a gate passed requires
   real chain evidence under `docs/evidence/`.
5. Do not assume Diana supports `StakingQuery::AllDelegations`. The exact
   bonded-vs-unbonding question is recorded in ADR-0002. The staking query is
   isolated in one Native helper and fails closed.
6. Do not describe the project as trustless proof of physical GPU ownership or AI-answer correctness. It enforces declared capacity and settles on independently measured service-level evidence.
7. Re-read live Diana parameters before every deployment or cross-VM integration test. Network status, allowlists, circuit breakers, gas limits, and governance parameters can change.
8. Keep on-chain state authoritative. Databases, indexers, provider APIs, and agents may cache data but are not the source of truth for reservations, bonds, escrow, or settlement.
9. Never invent deployed addresses, token addresses, RPC endpoints, precompile availability, governance approval, or successful test results. Record actual values and transaction hashes in deployment evidence.
10. Any change to a runtime boundary, trust assumption, state transition, or security property needs a new/updated ADR. UI/UX design guidance is in `docs/uiux/`; it is not implemented frontend code and does not imply an auction mechanism exists.

**Next deliverable:** close the live gates in order (G0-A..E), then deploy and
integrate. Do not generate another general feasibility report or resubmit
Proposal A as a substitute for implementation work.

---

## 1. Product thesis

AI systems and software agents increasingly consume external services: inference APIs, document-processing APIs, embedding endpoints, model-serving APIs, and other metered services. A buyer may need a guaranteed amount of service capacity during a specific time window, with measurable delivery conditions.

Today, a buyer can pay for a service without having an enforceable on-chain reservation of provider-declared capacity. A provider can also overcommit the same capacity across different applications, while a buyer may have limited recourse when the agreed service level is not met.

QoreLease aims to provide a shared commitment and settlement layer:

- Providers publish bounded service capacity for a defined time window.
- Buyers reserve capacity against an explicit service agreement.
- The provider's commitment is recorded in a shared Native contract.
- Buyer funds are locked in an EVM escrow in the same transaction that reserves capacity.
- A provider adapter executes the workload only after checking the Native reservation.
- Independent monitors produce signed, measurable delivery reports.
- Settlement, refund, and collateral outcomes follow deterministic contract rules.

### Example use case

A buyer agent needs **70 document-extraction requests** from 10:00–10:15. It requires at least 98% successful responses, a p95 latency below 800 ms, and a maximum spend of 20 fUSD.

Provider A has published one 100-unit capacity slot for that window. Buyer A reserves 70 units. A second buyer then attempts to reserve 50 units from the same slot. The second reservation must fail because only 30 units remain. The second buyer's EVM escrow transfer must roll back with the rejected Native reservation.

The provider runs the 70 requests. Independent monitors measure the agreed service-level metrics. The EVM contract then settles the payment, while the Native contract consumes the reservation and releases or penalizes the provider's application-level bond according to the agreement.

The numbers above are example demo parameters, not fixed protocol constants.

### Product positioning

QoreLease is **not** intended to be another general-purpose GPU marketplace, sealed-bid auction, agent-task marketplace, or generic escrow contract. The MVP is a capacity-commitment and service-delivery settlement layer for API / inference providers.

An AI agent may help discover providers, compare offers, and prepare requests. It is not trusted to decide whether a provider has fulfilled an SLA. Contract rules and independent measured evidence determine settlement.

---

## 2. Why use Cross-VM?

This question must have a technically defensible answer. A capacity mapping, escrow, signature verification, and payment settlement could all be implemented in Solidity. Merely moving a mapping from Solidity to CosmWasm does **not** justify Cross-VM.

### Intended runtime boundary

| Responsibility | Runtime | Reason for placement |
|---|---|---|
| Provider registration and provider-side service profile | Native / CosmWasm | Provider-side registry and native-lane operations |
| Provider capacity slots and reservation state | Native / CosmWasm | Shared canonical provider inventory consumed by EVM procurement applications and provider-side Native clients |
| Provider application-level QOR bond | Native / CosmWasm | Native token custody and provider-side bond lifecycle; must be tested in the synchronous bridge path |
| Native staking eligibility check | Native / CosmWasm | Potential use of the Cosmos staking module from the Native runtime; **not yet proven available to CosmWasm contracts on QoreChain** |
| Buyer fUSD escrow | EVM / Solidity | Buyer-side financial contract and ERC-20 flow |
| Signed service-evidence verification and payout rules | EVM / Solidity | Buyer-side settlement logic |
| Cross-runtime transaction coordination | EVM → Native synchronous bridge | Reserve Native capacity in the same transaction as EVM escrow |
| Actual inference / API processing | Off-chain provider infrastructure | Workload execution must not run inside the contracts |

### What is confirmed by QoreChain documentation

- QoreChain runs EVM and QoreChain Native (CosmWasm) as separate runtimes on one chain.
- The Diana testnet documents an EVM-to-Native synchronous bridge at `0x0000000000000000000000000000000000000901`, with a target allowlist.
- The bridge is designed to execute the Native contract in the same transaction; a later EVM revert is intended to undo the Native-side state change.
- The bridge call identifies the calling EVM account or contract to the Native contract using its QoreChain Native (`qor1...`) address mapping.
- The Native-development guide demonstrates `BankMsg::Send` and `StakingMsg::Delegate` for interacting with Cosmos SDK modules.
- The EVM precompile reference currently reports the Cross-VM bridge inactive on mainnet and active with an allowlist on Diana testnet. This must be checked live before use.

### What is not yet confirmed

The standard CosmWasm library defines `StakingQuery::AllDelegations`, but the QoreChain Native guide demonstrates staking **messages**, not that a custom CosmWasm contract can query arbitrary provider delegations through `StakingQuery`.

Therefore, the protocol must not claim Native staking eligibility enforcement until a test contract proves all of the following:

1. QoreChain's deployed CosmWasm runtime accepts the staking query type.
2. The query returns the expected delegations for a provider's `qor1...` address.
3. The amount and denomination semantics are understood and match the intended admission rule.
4. The query works in the Native contract execution context used by the synchronous EVM-to-Native bridge, not only in a normal Native transaction.
5. The returned eligibility result is checked on-chain inside the reservation path; it is not supplied by a trusted backend.

**Do not infer runtime support from the fact that `StakingQuery` exists in CosmWasm source code.** Standard-library support and chain runtime support are separate questions.

### Cross-VM go/no-go rule

The project proceeds as a Cross-VM application only if the feasibility work demonstrates a real Native-specific responsibility and the synchronous bridge actually enforces it atomically with EVM escrow.

The strongest intended Native-specific responsibility is an on-chain provider admission rule based on Native staking state, combined with Native-side capacity commitments. If the staking query is unavailable, do not quietly replace it with a backend-signed statement and claim that the Native contract verifies stake. Reassess the product and the category fit before building the rest.

A shared Native capacity ledger alone may be useful, but Solidity could also own one. The team must be prepared to explain why provider-side Native transactions and Native module integration are essential to the actual product rather than merely convenient implementation choices.

---

## 3. Scope

### MVP must include

1. A Native provider registry.
2. A Native provider admission/eligibility rule, subject to the feasibility gate.
3. A Native application-level QOR service bond, separate from delegated staking.
4. Native service-capacity slot publication and reservation accounting.
5. One EVM escrow contract that accepts buyer fUSD and invokes the Native reservation.
6. Atomic rollback tests in both directions: Native failure reverts EVM escrow; later EVM failure reverts Native state.
7. A provider adapter that checks the Native reservation before starting work.
8. A small, real API or inference workload with measurable service-level metrics.
9. At least two independent monitor processes or monitor identities that produce signed evidence.
10. A settlement path that pays, refunds, or penalizes according to deterministic rules.
11. A testnet demo with transaction hashes, addresses, test records, and reproducible steps.

### Explicitly out of scope for the first MVP

- Building a GPU cloud or operating physical GPU infrastructure.
- Running LLM inference, arbitrary AI logic, or heavy computation on-chain.
- Proving the semantic correctness of arbitrary AI-generated answers.
- Claiming cryptographic proof that the provider owns physical hardware.
- A general-purpose agent marketplace.
- A general-purpose sealed-bid auction as the main innovation.
- A native token launch or complex tokenomics.
- A multi-chain deployment.
- A full enterprise dispute-resolution system.
- A production-grade decentralized monitor network. The MVP can demonstrate a small independent monitor quorum, while clearly documenting its trust assumptions.

### MVP service vertical

Start with one measurable service class: **document extraction / structured inference API capacity**.

Use a fixed workload and an agreed response schema. The contract should verify service-level facts such as request count, success rate, latency bounds, time window, and report authenticity. It must not claim to prove that the model's extracted answer is semantically correct unless a separate adjudication system is designed and validated.

---

## 4. Mandatory feasibility gates — do these before product implementation

Local Phase 1 implementation and mocked tests are complete, but none of these
gates has Diana evidence. Live deployment, bridge use, and any claim of Diana
compatibility remain blocked until each gate is passed and recorded.

### Gate G0-A — Does QoreChain expose staking queries to CosmWasm contracts?

Build a minimal `staking-probe` Native contract. It should accept a provider address, attempt the standard `StakingQuery::AllDelegations` / `query_all_delegations` path, aggregate the returned `uqor` delegations using checked integer arithmetic, and persist the result for inspection.

Test at least:

- A provider with no delegations.
- A provider with one delegation.
- A provider with more than one delegation.
- A provider with an unbonding entry, to understand whether unbonding is included or excluded.
- A provider address that is malformed or not found.
- Denomination handling (`uqor`) and amount conversion.

**Pass condition:** the deployed QoreChain Native contract itself can query the provider's relevant staking state and use it in an on-chain allow/deny decision.

**Fail condition:** the runtime rejects the query, the query only works off-chain, or the contract receives an incomplete value that cannot support the intended rule.

If G0-A fails, do not use an off-chain API result as if it were a trustless on-chain staking check. Stop and reconsider the product's Cross-VM justification.

### Gate G0-B — Can a bridge-invoked Native contract execute required Native module messages?

Test whether a Native contract invoked by the EVM precompile can safely execute the specific Cosmos SDK message effects the design needs, including `BankMsg::Send` for an application-level bond release/penalty.

Test:

1. Native bond release succeeds and changes the expected balances.
2. Native bond penalty succeeds and changes the expected balances.
3. Native module-message failure reverts the entire enclosing cross-VM transaction.
4. A later EVM revert rolls back both the Native contract's storage changes and the Native module-message effects.

Do not assume that a normal Native transaction test proves these cross-VM execution semantics.

### Gate G0-C — Cross-VM sender identity and authorization

Prove that the Native contract sees the expected caller identity for a Solidity escrow contract. QoreChain documents the EVM caller/contract as the Native sender through its `qor1...` address mapping. Verify the mapping for the deployed escrow contract and whitelist only that identity for reservation/finalization calls.

Also verify the account's EVM authorization window and the `0x0901` scope required for the actual transaction path. Do not guess which addresses must be included in `allowed_targets`; inspect the live window rules and run a real test.

### Gate G0-D — Cross-VM atomicity

Use a minimal Solidity caller and a Native test contract. Demonstrate all of these on Diana testnet or a technically equivalent local QoreChain environment, then repeat on testnet before claiming completion:

| Test | Expected result |
|---|---|
| Native call succeeds, EVM call succeeds | Both EVM and Native state changes persist |
| Native contract rejects reservation | EVM escrow transfer and EVM state changes revert |
| Native call succeeds, Solidity deliberately reverts afterward | Native state changes revert too |
| Native response is empty or malformed | Solidity fails closed; no payment or reservation is treated as successful |
| Bridge inactive / target not allowlisted | Transaction is not mistaken for a successful reservation |

The precompile can return empty data when it is not active. A Solidity low-level call returning `ok == true` is therefore not sufficient. Check the response and decode a documented response format.

### Gate G0-E — Governance feasibility

Confirm that the team can get its custom Native contract stored, instantiated, and added to the Cross-VM allowlist in time. Custom Native code upload and bridge allowlisting are governance-controlled on Diana testnet.

Before building the full contract, confirm:

- Required proposal type and message structure.
- Current minimum deposit, voting period, quorum, yes threshold, and veto threshold.
- Whether a validator/community sponsor will help achieve quorum.
- Required hybrid-signing setup and the official `qorechaind` binary.
- Contract code checksum and no-admin / code-pin approach.
- Whether the target can be approved and pinned before the demo deadline.

Do not treat a proposal submission as approval. Record the proposal ID and final status.

### Gate report template

Create `docs/FEASIBILITY_SPIKES.md` and record each gate using this structure:

```text
Gate ID:
Question:
Chain / release / block height:
Contract source commit:
Wasm checksum / code ID / contract address:
Test accounts (public test addresses only):
Exact commands / transaction hashes:
Expected result:
Observed result:
Logs / query output:
Pass or fail:
Unresolved risks:
Decision / next step:
```

---

## 5. System architecture

```text
                       OFF-CHAIN LAYER
  ┌──────────────────────────────────────────────────────────────┐
  │                                                              │
  │  Buyer agent       Provider adapter          Monitor nodes   │
  │  - discover        - query Native slot       - run probes    │
  │  - rank offers     - verify reservation      - measure SLA   │
  │  - prepare request- execute API workload     - sign reports  │
  │                                                              │
  └──────────────┬─────────────────┬────────────────────┬────────┘
                 │                 │                    │
                 │                 │                    │
          ┌──────▼──────┐   ┌──────▼──────────┐  ┌──────▼─────────┐
          │ Next.js UI  │   │ Native queries  │  │ EVM evidence   │
          │ / client    │   │ / Native txs     │  │ submission     │
          └──────┬──────┘   └──────┬──────────┘  └──────┬─────────┘
                 │                 │                    │
  ═══════════════╪═════════════════╪════════════════════╪════════════
                 │                 │                    │
                 │          QORECHAIN DIANA TESTNET      │
                 │                                      │
          ┌──────▼──────────────────────────────────────▼──────┐
          │                     EVM                             │
          │                                                     │
          │  QoreLeaseEscrow.sol                                │
          │  - buyer fUSD escrow                                │
          │  - offer / reservation references                   │
          │  - report verification                              │
          │  - payout / refund / settlement                     │
          │                                                     │
          └────────────────────────┬────────────────────────────┘
                                   │
                    synchronous EVM → Native bridge
                            precompile 0x0901
                                   │
          ┌────────────────────────▼────────────────────────────┐
          │              QORECHAIN NATIVE                       │
          │                                                     │
          │  QoreLeaseRegistry.rs                               │
          │  - provider registry                                │
          │  - eligibility gate (only after G0-A passes)        │
          │  - liquid application-level bond                    │
          │  - slot capacity                                   │
          │  - reservation state machine                        │
          │  - replay / duplicate protection                    │
          │  - completion / release                             │
          │                                                     │
          └─────────────────────────────────────────────────────┘
```

### Data authority

| Data | Authoritative location | Notes |
|---|---|---|
| Provider profile | Native contract | UI / database may index it |
| Staking eligibility | Native contract, only if G0-A passes | Never accept a browser/backend boolean as authoritative |
| Provider's liquid service bond | Native contract + Native bank state | Separate from delegated staking |
| Published slot capacity | Native contract | Provider scheduler reads it |
| Active reservations | Native contract | No off-chain-only reservation state |
| Buyer funds | EVM escrow | Use exact ERC-20 base units |
| SLA terms and terms hash | EVM request / Native reservation reference | Same immutable commitment must be referenced by both sides |
| Monitor reports | EVM evidence records / event logs | Store digest and signatures; consider off-chain full report storage |
| Execution logs | Off-chain provider/monitor services | Evidence input, not the source of financial truth |

### Why the provider scheduler matters

A Native registry is not meaningful if providers ignore it and schedule jobs from a private database. The provider adapter must query `query_slot` / `query_reservation` immediately before starting work. The Native registry is the provider-side source of truth for all participating QoreLease applications.

This still does not stop a provider from selling the same capacity outside QoreLease. The protocol prevents overbooking only among participating applications and providers that honour the integration.

---

## 6. Roles and permissions

### Buyer

- Creates a service request with a time window, unit count, budget, and SLA terms.
- Selects or accepts a provider offer.
- Approves exact fUSD escrow allowance or uses a supported permit flow only if validated.
- Submits a reservation through the EVM escrow.
- Can inspect evidence and settlement status.

### Provider

- Registers a Native identity and service profile.
- Passes the configured admission rule, if G0-A validates it.
- Deposits a liquid Native QOR service bond.
- Publishes and updates capacity slots.
- Operates a provider adapter that checks Native reservation state before dispatching work.
- Can withdraw only unlocked / unencumbered bond subject to protocol rules.

### Monitor

- Is registered or authorized for a monitoring role.
- Runs a bounded, reproducible workload or probe.
- Measures only metrics defined in the job terms.
- Signs a canonical report digest.
- Cannot directly choose an arbitrary payout amount.

### Protocol administrator

- Configures contract-level roles / parameters during MVP deployment.
- Cannot rewrite an active job's terms or fabricate successful evidence.
- Must use a time-delayed / clearly documented admin model where practical.
- Must not have an undocumented emergency power to seize user funds or provider collateral.

---

## 7. Contract responsibilities and proposed interfaces

These tables describe the original design intent. The implemented message
schemas, wire format, error codes, and state transitions are recorded in
`docs/INTERFACES.md` and `docs/STATE_MACHINES.md`; use those documents when
working on the existing code.

### 7.1 Native contract — `QoreLeaseRegistry`

Proposed execute operations:

| Operation | Intended caller | Purpose |
|---|---|---|
| `register_provider` | Provider | Register provider profile and service identity |
| `deposit_bond` | Provider | Receive Native QOR into the contract as liquid service collateral |
| `publish_slot` | Provider | Publish capacity for a service class and time window |
| `update_slot` | Provider | Change only unreserved capacity / permitted metadata |
| `reserve` | Authorized EVM escrow identity | Reserve capacity and lock the required provider bond |
| `mark_running` | Provider adapter or authorized provider identity | Optional state transition; must not override reservation ownership |
| `finalize` | Authorized EVM escrow identity | Consume a completed reservation and release / penalize locked bond |
| `release` | Authorized EVM escrow identity or deterministic expiry path | Release unused capacity and unlock bond |
| `withdraw_bond` | Provider | Withdraw only currently unlocked bond |
| `pause_provider` | Authorized governance / admin path | Stop new reservations; do not erase active reservations |

Proposed query operations:

| Query | Purpose |
|---|---|
| `provider` | Read provider profile and current status |
| `slot` | Read total / reserved / available capacity |
| `reservation` | Read reservation state and linked terms hash |
| `provider_bond` | Read total, locked, and withdrawable bond |
| `eligibility` | Read eligibility details and last verified staking inputs, if G0-A passes |
| `authorized_escrows` | Read authorized EVM escrow identities |

### 7.2 EVM contract — `QoreLeaseEscrow`

Proposed public operations:

| Operation | Intended caller | Purpose |
|---|---|---|
| `createRequest` | Buyer | Publish buyer requirements / immutable terms hash |
| `acceptOffer` | Buyer | Pull buyer fUSD into escrow and synchronously reserve Native capacity |
| `submitEvidence` | Authorized monitor | Submit signed service report digest and metrics |
| `settle` | Permissionless after valid evidence / deadline | Verify evidence and execute the agreed settlement |
| `refund` | Buyer / permissionless after defined failure | Refund according to the job state and timeout rules |
| `getJob` | Anyone | Read EVM job, escrow, and settlement state |

The EVM contract must not trust a caller-supplied `providerBondLocked = true` flag. It must rely on a successful, correctly decoded Native response and its own recorded job state.

### 7.3 Cross-VM wire format

QoreChain documents the synchronous precompile as accepting:

```solidity
executeCrossVMCall(uint8 targetVM, string targetContract, bytes payload)
```

For a Native target:

- `targetVM = 1`.
- `targetContract` is the target Native contract's `qor1...` address as a string.
- `payload` is the UTF-8 JSON CosmWasm execute message.
- The precompile returns the target's raw response bytes.
- Funds cannot be attached to the EVM precompile call.
- The documented message size cap is 65,536 bytes; re-read live parameters.

The implementation must define and document a versioned response format before wiring Solidity settlement logic to it. Do not assume the Rust `Response` data encoding is automatically ABI-compatible. A successful low-level call with empty return data must be treated as failure because an inactive precompile may return empty data without executing the Native contract.

Suggested logical response fields:

```json
{
  "version": 1,
  "ok": true,
  "operation": "reserve",
  "job_id": "0x...",
  "reservation_id": "0x...",
  "reserved_units": "70",
  "remaining_units": "30",
  "state_hash": "0x..."
}
```

The actual on-wire representation may use a fixed binary encoding more suitable for Solidity decoding. The wire-format decision must be recorded in `docs/INTERFACES.md` and tested in both Rust and Solidity.

### 7.4 Sender identity and authorization

The Native contract must authorize only the intended EVM escrow contract's mapped Native identity for `reserve`, `finalize`, and other EVM-originated operations. Verify the mapping on the live testnet and record it in deployment configuration. Do not authorize every caller or trust an address supplied inside the JSON payload.

Provider-originated operations must verify `info.sender` equals the provider's registered Native identity. An EVM buyer must not be allowed to publish another provider's inventory or withdraw another provider's bond.

---

## 8. State machines

### Provider state

```text
UNREGISTERED
    │ register + admission checks
    ▼
ACTIVE ───────────────► PAUSED
  │                       │
  │ valid capacity        │ admin / provider action
  ▼                       │
ACTIVE ◄──────────────────┘
  │
  └──► EXITING ── no active reservations + no locked bond ──► CLOSED
```

The final state names and transitions must be implemented explicitly. A provider must not close while it has active reservations or locked collateral.

### Slot accounting

Maintain integer quantities only:

```text
available_units = total_units - reserved_units - consumed_units
```

This formula is illustrative; implementation must decide whether consumed capacity remains consumed for the slot or whether the service class models concurrency that can be released. Do not mix throughput units, concurrent-request units, and total-request units without separate fields.

A slot must include at least:

- `provider_id`
- `slot_id`
- `service_class_id`
- `start_time` / `end_time` or a clearly defined block/time representation
- `total_units`
- `reserved_units`
- `consumed_units` or a documented equivalent
- `terms_version`
- `status`

### Reservation state

```text
RESERVED
   │ provider begins work (off-chain; optional on-chain marker)
   ▼
RUNNING
   │ delivery report / completion
   ▼
PENDING_SETTLEMENT ───────► DISPUTED (only if dispute mechanism is in MVP)
   │ accepted evidence
   ▼
CONSUMED / SETTLED

RESERVED or RUNNING
   │ expiry / cancellation / deterministic failure
   ▼
RELEASED / REFUNDED / PENALIZED (according to terms)
```

Rules:

- A reservation is single-use.
- A job ID cannot be replayed to reserve, complete, settle, or slash twice.
- Terms are immutable after acceptance.
- A provider cannot reduce capacity below already reserved units.
- The reservation's terms hash must match the EVM job's terms hash.
- Timeout behaviour must be deterministic and specified before deployment.
- Avoid an unbounded on-chain dispute state machine in the MVP.

---

## 9. Cross-VM transaction flow

### 9.1 Provider onboarding

1. Provider creates a Native account / maps its identity for the EVM runtime as required by QoreChain.
2. Provider calls `register_provider` on the Native contract.
3. Native performs the admission check. The staking-based part is enabled only after G0-A passes.
4. Provider deposits liquid QOR service collateral through a Native transaction. The EVM-to-Native precompile cannot attach Native funds.
5. Provider publishes a service slot.
6. Provider adapter queries the Native slot and confirms that the available capacity matches the published state.

### 9.2 Buyer reservation

1. Buyer creates or selects a service request.
2. Buyer approves the EVM escrow to spend the exact fUSD amount.
3. Buyer calls `acceptOffer` on the EVM escrow.
4. EVM escrow validates request, offer, deadline, price, and unused job ID.
5. EVM escrow transfers buyer fUSD into escrow state.
6. EVM escrow calls the `0x0901` precompile with a `reserve` execute message for the Native registry.
7. Native verifies the authorized escrow identity, provider status, slot status, available units, job replay status, and locked-bond availability.
8. Native updates reservation and bond state and returns the versioned response.
9. EVM validates the response and records the EVM job state.
10. If the Native call fails, response is empty, or response is malformed, EVM reverts. The buyer's fUSD transfer must not remain committed.

### 9.3 Provider execution

1. Provider scheduler receives or discovers the reservation.
2. Before execution, it queries Native `reservation` and `slot` state.
3. It dispatches only if the reservation is active, valid, within the time window, and not previously consumed.
4. It runs the agreed API workload.
5. It records request IDs, timestamps, result hashes, status codes, and latency measurements, while avoiding unnecessary personal data.

### 9.4 Monitoring and settlement

1. At least two independently operated monitor processes run the same or equivalent fixed workload.
2. Each monitor constructs a canonical report containing job ID, terms hash, observation window, request count, success count, latency statistics, endpoint identity, and evidence digest.
3. Each monitor signs the canonical report digest.
4. EVM verifies monitor identity, signature, report freshness, job association, and metric bounds.
5. EVM applies deterministic quorum and SLA rules.
6. EVM calls Native `finalize` or `release` through `0x0901`.
7. Native verifies reservation state, job ID, terms hash, billable units, and one-time finalization. It consumes capacity and updates / releases / penalizes the application bond as required.
8. EVM pays the provider, refunds the buyer, or applies the agreed split.
9. Any failure in the synchronous cross-VM transaction must leave both runtime states uncommitted.

**MVP evidence limitation:** a monitor signature proves who signed a report, not that the report is truthful. Multiple monitors reduce single-monitor dependence but do not eliminate collusion or shared network measurement bias. Document this in the threat model.

---

## 10. Protocol invariants

These invariants must be represented in contract tests, and the critical ones must be observable in the live demo.

1. **Capacity bound:** `reserved_units + consumed_units <= total_units`, using the chosen slot accounting model.
2. **No double booking:** aggregate active reservations cannot exceed the slot's remaining capacity.
3. **Admission rule:** a provider that fails the configured Native admission check cannot publish or accept new reservations.
4. **Bond encumbrance:** a provider cannot withdraw bond reserved against active jobs.
5. **Escrow-reservation coupling:** no buyer fUSD escrow can remain committed if Native rejects the matching reservation.
6. **Terms consistency:** EVM and Native must store the same job ID and terms hash.
7. **Single-use reservation:** a job/reservation cannot be finalized, consumed, released, or penalized more than once.
8. **Evidence validity:** no provider payout occurs without the required accepted monitor quorum and in-bounds measurements.
9. **No overpayment:** total payout plus refund must not exceed the buyer's escrowed amount.
10. **Bond conservation:** locked plus available provider bond must reconcile with the contract's actual Native QOR balance, accounting for any explicitly documented fees or penalties.
11. **Atomicity:** a failure in either runtime must not leave only one side committed.
12. **Authorization:** only the registered provider can manage its own slots / bond; only the approved EVM escrow identity can invoke buyer-side reservation/finalization operations.
13. **Replay resistance:** unique IDs, nonces or consumed-state checks prevent replay of bridge payloads and evidence reports.
14. **Deadline enforcement:** actions outside their permitted time window fail deterministically.

The agent must add property-based / fuzz tests for capacity accounting, integer boundaries, replay protection, and settlement conservation.

---

## 11. Security and threat model

Create `docs/THREAT_MODEL.md` before the contracts are considered feature-complete.

Minimum threats to analyse:

| Threat | Required mitigation / honest limitation |
|---|---|
| Provider publishes fake capacity | Bond + monitoring + penalties; does not prove physical hardware exists |
| Provider sells the same capacity outside QoreLease | Not prevented by the protocol; claims apply only to participating capacity inventory |
| Provider lies about service execution | Independent monitors, signed evidence, challenge process if time allows |
| Monitor collusion | Independent operators, quorum, stake / reputation or challenge path; residual trust remains |
| Buyer replays reservation payload | Unique job ID, terms hash, state machine, one-time transitions |
| EVM contract spoofed as Native caller | Allowlist the verified mapped escrow identity; check `info.sender` |
| Native response empty because bridge is inactive | Fail closed on empty / malformed response; verify live precompile status |
| Target contract code changed after allowlisting | No-admin immutable deployment and governance code pin; verify live pin |
| Bridge or module state rolls back unexpectedly | Test synchronous journaling, bank-message rollback, and later EVM revert |
| fUSD approval / transfer issue | Exact allowance, safe ERC-20 handling, no fee-on-transfer assumptions unless explicitly supported |
| Provider drains / withdraws bond early | Track locked amount per reservation; only unlocked amount withdrawable |
| Staking query gives incomplete or misleading amount | G0-A test; document whether delegations, unbonding, locks, and rewards are included |
| Timestamp manipulation / boundary ambiguity | Conservative time windows, explicit source of time, test boundary blocks |
| Gas exhaustion / large payload | Bounded payloads, bounded loops, live simulation and gas margins |
| Admin compromise | Minimize privileged paths, document roles, avoid unilateral asset seizure |

### Bond terminology

Do not conflate these concepts:

- **Delegated stake:** QOR delegated by an account to one or more validators under the chain's staking module.
- **Native service bond:** QOR deposited into the QoreLease Native contract as application-level collateral.
- **Provider bond locked for a job:** a portion of the Native service bond encumbered by an active reservation.

The application must not claim it can slash a provider's validator delegation for an SLA violation. Any QoreLease penalty applies to the application's own liquid service bond, subject to the tested contract logic.

---

## 12. Suggested repository structure

The tree below was the original suggestion. The actual Phase 1 paths are
`contracts/qorelease-registry/`, `contracts/evm/`, `services/provider-adapter/`,
`scripts/local-e2e.{sh,ps1}`, `docs/uiux/`, and `docs/decisions/ADR-*.md`.
The probe remains at `contracts/staking-probe/`. Avoid unnecessary services and
frameworks; no marketplace UI, database, or monitor network exists yet.

```text
qorelease/
├── README.md
├── docs/
│   ├── SOURCE_REFERENCE.md
│   ├── FEASIBILITY_SPIKES.md
│   ├── ARCHITECTURE.md
│   ├── INTERFACES.md
│   ├── STATE_MACHINES.md
│   ├── THREAT_MODEL.md
│   ├── TEST_PLAN.md
│   ├── DEPLOYMENT_RUNBOOK.md
│   ├── DEMO_RUNBOOK.md
│   ├── decisions/
│   │   ├── ADR-0001-runtime-boundary.md
│   │   ├── ADR-0002-staking-admission.md
│   │   ├── ADR-0003-bond-accounting.md
│   │   └── ADR-0004-monitor-quorum.md
│   └── evidence/
│       ├── testnet-addresses.md
│       ├── governance-proposals.md
│       └── transaction-evidence.md
├── contracts/
│   ├── native-registry/
│   │   ├── Cargo.toml
│   │   ├── src/
│   │   ├── tests/
│   │   └── schema/
│   └── evm-escrow/
│       ├── foundry.toml
│       ├── src/
│       ├── test/
│       └── script/
├── apps/
│   └── web/                  # Next.js UI; do not build before G0 passes
├── services/
│   ├── provider-adapter/     # Native-aware provider scheduler
│   └── monitor/              # Independent signed SLA probes
├── packages/
│   ├── protocol-types/       # Shared IDs, hashes, metrics and schemas
│   └── qorechain-client/     # Thin, tested QoreChain helpers
├── scripts/
│   ├── check-network.ts
│   ├── check-bridge.ts
│   └── verify-deployment.ts
└── .env.example
```

### Stack direction

- **Native contract:** Rust + the CosmWasm version supported by the current QoreChain testnet. Confirm the exact toolchain and optimizer image in the live Native-development and governance-upload documentation; do not blindly copy versions from an older tutorial.
- **EVM contract:** Solidity, Foundry, explicit cross-VM precompile interface, fuzz / invariant tests.
- **Frontend:** Next.js + TypeScript. Build only after protocol feasibility and contract interfaces are stable.
- **QoreChain access:** official `@qorechain/sdk` / `@qorechain/evm` where appropriate, with viem or ethers for standard EVM operations. Verify the currently published package versions and APIs before coding.
- **Provider adapter and monitor:** TypeScript / Node.js initially. Keep workload execution and measurement independent of the UI process.
- **Database:** optional for cache, job display, and monitor evidence storage. It is not canonical state. Avoid introducing PostgreSQL or Redis until the MVP actually needs them.

---

## 13. Required engineering documentation

These files are not optional paperwork. They prevent the implementation agent from inventing protocol behaviour and make the project auditable for judges.

| Document | Must be created / updated when | Required contents |
|---|---|---|
| `docs/FEASIBILITY_SPIKES.md` | Before product implementation | G0-A through G0-E, exact commands, chain versions, results, and Go / No-Go decision |
| `docs/ARCHITECTURE.md` | After feasibility passes and whenever architecture changes | Component diagram, runtime boundary, trust boundaries, data authority, deployment topology |
| `docs/INTERFACES.md` | Before writing integration code | JSON execute messages, Rust schema, EVM ABI, response wire format, address mapping, versioning, error codes |
| `docs/STATE_MACHINES.md` | Before contract implementation | Provider, slot, reservation, bond, escrow and settlement states; allowed transitions; timeout behaviour |
| `docs/THREAT_MODEL.md` | Before security review | Assets, actors, trust assumptions, threats, mitigations, residual risks, admin powers |
| `docs/TEST_PLAN.md` | Before meaningful contract code | Unit tests, integration tests, fuzz tests, invariants, cross-VM rollback cases and live testnet cases |
| `docs/DEPLOYMENT_RUNBOOK.md` | Before testnet deployment | Build versions, checksums, proposal process, code IDs, addresses, pins, EVM window steps, environment variables, rollback / pause procedure |
| `docs/DEMO_RUNBOOK.md` | Before final demo rehearsal | Exact accounts, balances, setup, commands, UI steps, expected states, failure demo, explorer links, fallback recording |
| `docs/evidence/testnet-addresses.md` | Every deployment | Network, chain release, code IDs, contract addresses, mapped identities, token addresses, explorer links |
| `docs/evidence/governance-proposals.md` | Every proposal | Proposal ID, messages, deposit, voting status, result, code checksum, allowlist pin |
| `docs/evidence/transaction-evidence.md` | Every integration milestone | Tx hashes, block heights, expected and observed state changes, test output |
| `docs/decisions/ADR-*.md` | On a material design decision | Context, alternatives, decision, consequences, source references, date |

### Documentation rules

- Each technical claim must link to the source or to a reproducible test.
- Distinguish `CONFIRMED`, `TESTED LOCALLY`, `TESTED ON DIANA`, `ASSUMED`, and `NOT VERIFIED`.
- Include exact chain release / block height for testnet-specific results.
- Keep generated schemas and interface documents in version control.
- Every deployment must record code checksum and contract code history / pin state.
- Never overwrite a failed feasibility result with a later success without recording both and explaining the difference.

---

## 14. Implementation milestones

**Status note:** the owner directed implementation before the gates closed.
Local Phase 1 work covers the Native registry, EVM escrow, bridge wrapper,
provider adapter, stateful local atomicity tests, and one local end-to-end run
(the items described in Phases 1-3 and the adapter part of Phase 5 below).
Gates G0-A..E, reproducible production Wasm for the new registry, live Diana
integration, forced live rollback, on-chain monitor evidence, and the UI are
still outstanding. The phase numbering below is historical, not a live checklist.

### Phase 0 — Feasibility / no product UI

- Read official QoreChain Native, Cross-VM, EVM precompile, EVM window, governance, and gas-limit documentation.
- Build the staking-probe contract.
- Test staking-query availability and semantics.
- Test Native bank-message effects inside a bridge call.
- Test EVM caller identity mapping and authorization.
- Prove the four atomicity cases in G0-D.
- Confirm custom contract governance is feasible.
- Write the feasibility report and ADR-0001.

**Exit criterion:** all critical gates pass and the Native-specific value proposition remains valid.

### Phase 1 — Protocol specification

- Freeze provider, slot, reservation, bond, escrow, and evidence state machines.
- Define integer units and time representation.
- Define EVM / Native shared job IDs and terms hashes.
- Define versioned bridge message and response format.
- Define monitor identity, signatures, report canonicalization, and quorum.
- Write interface, threat model, and test plan documents.

**Exit criterion:** no ambiguous field meaning or untested runtime assumption remains in the interface contract.

### Phase 2 — Native registry

- Implement provider registration and status.
- Implement the validated admission rule.
- Implement liquid service-bond deposit / lock / release / penalty.
- Implement slot publication and capacity accounting.
- Implement reserve / finalize / release and replay protections.
- Add query endpoints and schema generation.
- Unit-test and integration-test all transitions.

**Exit criterion:** Native contract tests prove all provider-side invariants.

### Phase 3 — EVM escrow

- Implement buyer request and offer acceptance.
- Implement fUSD escrow with exact amount accounting.
- Implement `0x0901` bridge wrapper.
- Fail closed on inactive precompile, empty response, malformed response, wrong job ID, or wrong terms hash.
- Implement report verification and settlement rules.
- Add Foundry unit, fuzz, invariant, and rollback tests.

**Exit criterion:** local EVM tests prove escrow conservation and mocked bridge failure paths; Diana tests prove real bridge behaviour.

### Phase 4 — Testnet integration and governance

- Build reproducible Native Wasm artifact and checksum.
- Submit / coordinate governance upload, instantiation, and bridge allowlist proposal(s).
- Instantiate with no admin where possible; record code ID and code history.
- Verify allowlist and code pin from live parameters.
- Register / open required EVM authorization windows for test accounts.
- Run end-to-end reservation and forced rollback tests.
- Verify Native balance changes and EVM fUSD changes on-chain.

**Exit criterion:** reproducible cross-VM state changes with explorer evidence and rollback proof.

### Phase 5 — Provider adapter and monitor

- Implement Native reservation polling / queries.
- Prevent provider execution without a valid active reservation.
- Run one fixed API workload.
- Implement independent monitor jobs and canonical report signatures.
- Test monitor disagreement, missing monitor, stale report, replay, and failed SLA.

**Exit criterion:** service execution and settlement metrics are reproducible and not generated solely by the provider.

### Phase 6 — Minimal UI and demo hardening

- Provider view: register status, bond, published slots, reservations.
- Buyer view: request, offer, reserve, escrow, evidence and settlement.
- Monitor view / operator console: run checks and inspect signed reports.
- Network health view: chain, precompile, target allowlist, EVM window, contract versions.
- Prepare and rehearse the success and failure demos.

**Exit criterion:** judges can see Native and EVM state, the failed overbooking attempt, a successful service delivery, and atomic rollback evidence.

---

## 15. Required tests

### Native contract tests

- Provider registration with valid / invalid admission result.
- Bond deposit with exact funds and wrong denom.
- Bond lock, partial release, penalty, and withdrawal.
- Slot publish, update, expiry, and capacity boundary cases.
- Two reservations racing for the same remaining capacity.
- Duplicate job ID / replay attempt.
- Reservation by unauthorized EVM sender.
- Provider attempts to edit another provider's slot.
- Withdrawal while bond remains locked.
- Staking-query error, empty result, and denomination mismatch.

### EVM tests

- Correct fUSD transfer into escrow.
- Insufficient allowance / balance.
- Reservation accepted and response decoded.
- Native call reverts.
- Precompile call returns empty bytes.
- Precompile response has wrong version / operation / job ID.
- Native response valid but later EVM code deliberately reverts.
- Invalid monitor signature and unknown monitor.
- Duplicate / stale / wrong-job report.
- Quorum not reached.
- SLA passed, failed, and boundary values.
- Payout + refund never exceeds escrow.
- Settlement replay rejected.

### Cross-VM Diana tests

- Native update persists after successful EVM transaction.
- Native reject leaves buyer fUSD unchanged.
- EVM revert after Native update leaves Native state unchanged.
- Native bank-message effect reverts with the transaction, if the protocol relies on it.
- Caller identity matches the configured escrow mapping.
- Bridge precompile active and target allowlisted.
- EVM authorization window admits the intended call and rejects an out-of-scope call.
- Target code pin matches the actual code ID and contract history.

### Demo acceptance tests

1. Provider A publishes 100 units.
2. Buyer A reserves 70 units successfully.
3. Buyer B attempts 50 units and is rejected.
4. Buyer B's EVM fUSD balance and allowance/escrow accounting are correct after the failed transaction.
5. Provider A executes the real 70-unit workload.
6. Two of three independent monitors report valid results.
7. EVM settlement succeeds and Native reservation is consumed.
8. A deliberately forced EVM revert after a Native call proves rollback of both sides.

---

## 16. Network and deployment constraints

These are time-sensitive. The implementation agent must re-check live sources and endpoints before acting.

- The target is the Diana testnet, not mainnet.
- The documented Cross-VM EVM precompile is `0x0000000000000000000000000000000000000901`.
- The Cross-VM bridge has been documented as active on Diana with an allowlist and inactive on mainnet. Never rely on this static statement without checking live active-precompile and cross-VM parameters.
- A call to an inactive precompile may return success with empty data. The Solidity wrapper must reject empty data.
- The Native target must be in `bridge_allowed_targets` and its code must match the approved pin.
- Testnet Native code upload is governance-controlled. An ordinary `store` transaction is not an acceptable deployment plan.
- Every QoreChain EVM-signed account needs the required registered post-quantum key and an open EVM authorization window for the relevant operation. The window is opened with a hybrid-signed Native transaction.
- The synchronous precompile cannot attach Native funds. Provider Native QOR bond deposits must be funded through Native transactions.
- The documented Cross-VM message-size limit is 65,536 bytes; read the live parameter.
- QOR uses `uqor` with 6 decimals on the Native side. EVM representations use 18 decimals. Use exact integer conversions and do not use floating point for funds.
- Native Wasm gas has dynamic load / congestion pricing. Simulate and apply the documented margin; do not hard-code a gas limit from an old tutorial.
- The testnet is shared. Use throwaway test accounts and never use production secrets in `.env` files or commands.

### Testnet endpoints documented by QoreChain

| Service | Endpoint |
|---|---|
| Cosmos REST / LCD | `https://api-testnet.qore.host` |
| Consensus RPC | `https://rpc-testnet.qore.host` |
| EVM JSON-RPC | `https://evm-testnet.qore.host` |
| EVM WebSocket | `wss://evm-ws-testnet.qore.host` |
| Explorer | `https://explore.qore.network` (select Testnet) |

### Live checks to run before integration

```bash
# Cross-VM module parameters, including enabled flag, allowlist, pins and limits
curl -s https://api-testnet.qore.host/qorechain/crossvm/v1/params | jq

# Native code-upload parameters
curl -s https://api-testnet.qore.host/cosmwasm/wasm/v1/codes/params | jq

# EVM circuit breaker / disabled message types
curl -s https://api-testnet.qore.host/cosmos/circuit/v1/disable_list | jq

# Provider delegations (off-chain reference result for comparison with contract query)
# Replace <QOR_ADDRESS> with a public testnet provider address.
curl -s "https://api-testnet.qore.host/cosmos/staking/v1beta1/delegations/<QOR_ADDRESS>" | jq

# EVM authorization window
curl -s "https://api-testnet.qore.host/qorechain/pqc/v1/evm_window/<QOR_ADDRESS>" | jq

# EVM chain ID should be 9800 on Diana
cast chain-id --rpc-url https://evm-testnet.qore.host
```

The REST staking endpoint is an off-chain comparison source. Its existence does **not** prove that the same staking query is available from inside CosmWasm.

---

## 17. Definition of done

QoreLease is not considered a working Cross-VM product merely because the frontend loads or a transaction emits a Native receipt.

The project is ready for judging only when:

- The Native-specific capability has passed a reproducible feasibility test.
- The custom Native contract is deployed and the exact code is allowlisted / pinned.
- The EVM contract calls the actual Native contract through `0x0901` on Diana.
- Buyer escrow and Native capacity reservation are atomic.
- The overbooking attempt visibly fails with no buyer-fund loss.
- A real service workload is executed against a valid Native reservation.
- Independent monitor evidence is verified on-chain.
- Settlement updates EVM escrow and Native reservation / bond state consistently.
- A forced rollback proves both runtimes revert together.
- The threat model, known limitations, and all documentation listed in §13 are current.
- Deployment evidence contains real addresses, code IDs, checksums, proposal IDs, transaction hashes, and block heights.

## 18. Non-negotiable product honesty

- QoreLease enforces provider-declared capacity among participating applications; it does not prove physical GPU inventory.
- Staking eligibility is not the same as service-bond collateral.
- A monitor signature authenticates the monitor's statement; it does not prove the statement is true.
- SLA verification measures defined service-level metrics, not arbitrary model-output correctness.
- A Native contract is not automatically more secure or authoritative just because it is Native.
- A Cross-VM demo is not enough; the application must have a Native-specific responsibility that the product genuinely needs.

---

## 19. Start here (updated for the implemented repository)

The next coding session should do the following:

1. Read `README.md` sections 0 and 4, `docs/FEASIBILITY_SPIKES.md`,
   `docs/INTERFACES.md`, `docs/TEST_PLAN.md`, and `docs/decisions/ADR-*.md`.
2. Reproduce the local baseline: `cargo test --locked` in
   `contracts/qorelease-registry/`, `bash docs/evidence/run-foundry-tests.sh`
   in WSL2, and `powershell -ExecutionPolicy Bypass -File scripts/local-e2e.ps1`.
   Do not change contract logic without making these pass first.
3. Work on the **open gates**, not on re-creating the probe or rewriting Phase 1:
   - G0-A: get the accepted probe or new registry executed on Diana and record
     the staking result plus bonded-vs-unbonding semantics.
   - G0-B/G0-D: verify bank-message and bridge rollback with real transactions.
   - G0-C: verify the mapped `qor1...` identity of the deployed escrow and the
     EVM authorization-window scope. Capture the real bridge response format.
   - G0-E: governance upload, instantiation, allowlist and code pin for the new
     registry; verify from live parameters.
4. Only after those gates pass: build a reproducible optimized Wasm for the new
   registry, deploy, run the live E2E scenario, then implement the frontend from
   `docs/uiux/` guidance. The UI/UX documents are design handoff, not built code,
   and do not authorize an on-chain auction or sealed-bidding claims.

Do not submit Proposal A, broadcast transactions, request keys/seeds, or claim
Diana compatibility from the local mocks.


## Phase 0 status — 24 November 2026

The probe source inputs are public at commit [724729bcfc34bb43131165bbbe49f90dace5926e](https://github.com/hari-ramsss/chronolease/commit/724729bcfc34bb43131165bbbe49f90dace5926e). The pinned optimizer output is reproducible and passes the independent Wasm limits audit. RustSec found two transitive cryptographic vulnerabilities. Proposal A has not been submitted and is **NOT READY FOR SUBMISSION** pending dependency-security review. G0-A has not been tested on Diana or passed. See `docs/SOURCE_PROVENANCE_G0A.md`, `docs/WASM_ARTIFACT_AUDIT.md`, and `artifacts/proposals/PROPOSAL_A_REVIEW.md`.