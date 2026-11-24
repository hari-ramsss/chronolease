# QoreLease interfaces (implemented Phase 1)

## Native CosmWasm `qorelease-registry`

Instantiate: `admin`, `authorized_escrow` (mapped Native identity of the EVM
escrow), `penalty_recipient`, `minimum_stake_uqor`, `bond_per_unit_uqor`,
`breach_penalty_bps` (<= 10000).

Execute messages:

| Message | Caller | Notes |
|---|---|---|
| `register_provider {provider_id, service_profile, endpoint_manifest_hash}` | provider | Validates identity, calls the staking helper, rejects below threshold |
| `deposit_bond {}` | provider | Exactly one non-zero `uqor` coin in Native `funds` |
| `withdraw_bond {amount}` | provider | Only unlocked collateral; emits `BankMsg::Send` |
| `publish_slot {slot_id, service_type, start_time, end_time, total_units, terms_hash}` | provider | Future, non-overlapping chronological slots; stake recheck |
| `reserve {job_id, provider_id, slot_id, units, terms_hash, slot_terms_hash}` | configured escrow only | `info.sender` check; duplicate job guard; locks bond |
| `finalize {job_id, terms_hash, delivered_units, accepted_breach}` | configured escrow only | One-time; consumed units; penalty from bond |
| `release {job_id}` | escrow, or anyone after expiry | Unlocks bond and reserved capacity |
| `update_config {...}` | admin | Threshold, bond/unit, penalty, escrow identity, recipient |

Queries: `provider`, `slot`, `reservation`, `available_capacity`,
`provider_bond`, `config`. Amounts are `uqor` integer amounts; hashes are
0x-prefixed 32-byte hex strings.

## EVM `QoreLeaseEscrow`

Operations: `createRequest`, `acceptOffer`, `reserveCapacity`, `submitEvidence`,
`settle`, `refund`, `getJobStatus`, plus admin configuration/monitor authorization.

- Job id: `keccak256(abi.encode(escrow, buyer, salt, termsHash, slotTermsHash,
  providerId, slotId, units, pricePerUnit))`.
- `acceptOffer` performs the fUSD transfer and Native reservation atomically;
  any Native/bridge failure reverts the transfer.
- `settle` requires accepted evidence, calls Native `finalize`, validates the
  response, then pays `deliveredUnits * pricePerUnit` fUSD to the provider and
  refunds the remainder to the buyer.
- `refund` calls Native `release` for reserved jobs, then refunds the buyer.

## Bridge call shape

```solidity
executeCrossVMCall(uint8 targetVM, string targetContract, bytes payload)
```

- `targetVM = 1` (Native).
- `targetContract` is the configured `qor1...` registry address string.
- `payload` is the UTF-8 JSON CosmWasm execute message.
- Normal `CALL` with `msg.value == 0`. The low-level call failure reverts; empty
  return data is rejected; ABI-wrapped and raw return shapes are normalised.
- No caller identity is sent in JSON. The Native registry uses `info.sender`.

## Proposed Native response wire format (v1)

Seven 32-byte big-endian words, total 224 bytes, no dynamic offsets:

| Word | Field |
|---|---|
| 0 | version (`1`) |
| 1 | operation (`1` reserve, `2` finalize, `3` release) |
| 2 | job id (32 bytes) |
| 3 | terms hash (32 bytes) |
| 4 | reserved units |
| 5 | delivered units |
| 6 | remaining available units |

This is implemented and locally tested in both Rust and Solidity, but the actual
Diana precompile passthrough encoding of `Response.data` has **not** been
verified. Until G0-D evidence exists, any non-224-byte response is rejected.

## Deployment configuration sources

Bridge address, Native target address, mapped escrow identity, and monitor roles
are kept in `QoreLeaseConfig.sol`, separate from product logic. Production values
must come from live Diana state and operator review; no address is invented here.
