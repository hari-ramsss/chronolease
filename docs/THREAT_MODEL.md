# QoreLease threat model (Phase 1 implementation)

## Assets

Buyer fUSD in escrow; provider QOR service bond in the Native contract;
reservation capacity records; job/terms hashes; delivery evidence digests.

## Actors and trust boundaries

Buyer, provider, provider adapter, independent monitors (local mock identities),
Native registry, EVM escrow, bridge, chain governance/admin.

## Mitigations implemented locally

| Threat | Mitigation in code |
|---|---|
| Buyer pays into a failed reservation | `acceptOffer` reserves within the same tx; any bridge/Native/response failure reverts the fUSD transfer (local test proves this) |
| Overbooking | Native capacity and bond checks with checked integers; duplicates rejected by persisted job id |
| Forged Native acceptance | Strict 224-byte response decode; operation/version/job/terms/units checked; empty response rejected |
| Caller spoofing via JSON | Native compares `info.sender` to configured escrow; no caller field is sent or trusted |
| Double settlement / replay | EVM state machine + Native one-time finalization + persisted job ids |
| Invalid evidence payout | Monitor authorization, canonical digest, delivered-units bound, one digest per job |
| Fee-on-transfer token surprises | Escrow checks post-transfer balance delta; no fee-on-transfer support claimed |
| Bond withdrawal with active jobs | `withdraw_bond` only lowers unlocked collateral; reservation locks first |
| Staking query failure | Error propagated; no fallback to a backend boolean |
| Reentrancy | External token/bridge calls occur after state checks; state updated before payout in `settle`; no callbacks can re-enter a valid state |

## Residual risks / NOT VERIFIED

- Diana actual `StakingQuery::AllDelegations` availability and bonded-vs-unbonding
  semantics (G0-A).
- Mapped `qor1...` identity of the deployed escrow and EVM window scope (G0-C).
- Real bridge atomicity, settle/revert journaling, and response encoding (G0-D).
- `BankMsg::Send` behaviour inside a bridge-invoked Native transaction (G0-B).
- Governance upload, allowlist and code pin (G0-E).
- Local monitor attestations are deterministic digests, not real signatures; no
  quorum, stake, or challenge mechanism exists yet. Monitor collusion remains.
- Provider-declared capacity cannot prove physical API/GPU inventory.
- fUSD address, decimals and transfer behaviour on Diana are not verified.
- Admin can change configuration; admin compromise mitigation and timelock are
  future work. Admin cannot rewrite an active job's terms or evidence.
