# QoreLease architecture

Status: **Phase 1 local implementation complete; live Diana integration NOT VERIFIED.**
The historical Phase 0 boundary record is preserved below as the baseline; the
owner directed implementation to proceed while those gates remain open, so every
runtime-dependent behaviour is explicitly isolated and marked as a deployment gate.

## Implemented local architecture

```text
Provider (Native tx) ──> contracts/qorelease-registry
                              │ register / bond / slot / reserve / finalize / release
                              │ standard StakingQuery helper (Diana support unknown)
                              ▼
Buyer (EVM tx) ──> contracts/evm/QoreLeaseEscrow.sol
                        │ fUSD escrow + job state machine + evidence-bound payout
                        ▼
             CrossVMBridgeService ── CALL(value 0) ── bridge address
                        │  targetVM=1, qor1... target, UTF-8 JSON payload
                        ▼  strict 7-word response decode (encoding unverified)
             Native registry (canonical capacity + bond state)

Provider adapter (services/provider-adapter)
   queries reservation/slot BEFORE executing
   ──> local OpenAI-compatible HTTP mock ──> execution report
   ──> independent local monitor attestations (not real signatures)

Independent monitors (local) ──> delivery reports ──> EVM evidence validation
```

Runtime authority:

| Data | Authority in implemented code |
|---|---|
| Provider profile, service bond, slot capacity, reservations | Native Rust contract storage plus Native bank state |
| Buyer fUSD escrow and settlement | Solidity escrow contract |
| Cross-VM reservation acceptance | Strictly decoded Native response, never a caller-supplied flag |
| Workload truth | Off-chain adapter + independent monitor reports; not on-chain proof |
| Staking eligibility | Native `StakingQuery::AllDelegations` helper; mocked locally, unverified on Diana |

The central invariant implemented and locally proven: a buyer fUSD commitment can
only complete when the Native registry accepts the capacity commitment, and
settlement references the same job id, terms hash, and accepted delivered units.

## Historical Phase 0 boundary (preserved)

```text
Native staking probe ── query AllDelegations ── Diana staking keeper (unknown)
          ▲
          │ synchronous call, targetVM=1
Solidity test caller ── 0x0901 ── allowlisted Native probe
          │
          └── forced revert tests bridge journaling
```

The probe stores the returned delegation list and checked `uqor` sum. It does
not custody provider service bonds. Delegated stake, unbonding entries, and
liquid application collateral are separate concepts. `AllDelegations` behavior
and unbonding inclusion remain NOT VERIFIED against Diana v3.2.10 source/runtime.

Canonical live evidence remains chain state and transaction receipts. Source
commit, release binary hash, Wasm checksum, code ID, address, governance result,
pin, and block heights must accompany any result. No such evidence exists yet.
