# QoreLease state machines (implemented Phase 1)

## Provider

`UNREGISTERED -> ACTIVE` via `register_provider` with a passing staking query.
`ACTIVE` providers can deposit/withdraw unlocked bond and publish slots. There is
no implemented `pause_provider`/`CLOSED` transition in Phase 1; adding one is a
later protocol decision. Duplicate registration by id or owner is rejected.

## Slot

`PUBLISHED(active, end_time in future) -> PARTIALLY_RESERVED -> SETTLED/RELEASED`.

Invariant: `total_units >= reserved_units + consumed_units` at every transition,
using checked arithmetic. Slots must be published in chronological order and may
not overlap an unexpired slot. Reservation against a slot whose `end_time` has
passed fails with `SlotExpired`.

## Bond

`available_uqor + locked_uqor` equals current deposited collateral minus
withdrawals and penalties. `reserve` moves `bond_per_unit * units` from available
to locked. `finalize` returns all locked bond minus the optional penalty; a
penalty is sent to `penalty_recipient` as a `BankMsg::Send`. `release` returns all
locked bond. `withdraw_bond` only decreases unlocked available bond.

## Reservation (Native)

`ACTIVE -> FINALIZED` (one-time, delivered units consumed)
`ACTIVE -> RELEASED` (escrow or deterministic expiry).

The persisted presence of a job id is the replay guard across all transitions.

## EVM job

`None -> Created -> Funded -> Reserved -> Settled`
`Funded|Reserved -> Refunded`.

- `Created`: terms immutable, no funds committed.
- `Funded`: fUSD held; Native reservation not yet accepted.
- `Reserved`: Native response validated; evidence may be submitted.
- `Settled`: evidence accepted, Native finalize succeeded, payout complete.
- `Refunded`: Native release succeeded for reserved jobs; buyer refunded.

Any failure in a transition reverts the whole EVM transaction. The state machine
never permits a second settle or refund.

## Evidence

An authorized monitor may submit one canonical digest per job:
`keccak256(jobId, termsHash, deliveredUnits, providerId, slotId)`. Reused digests
and forged digests are rejected. This verifies report authenticity and binding,
not truthfulness. Quorum and external signature verification remain future work.
