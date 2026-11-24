# ADR-0003: Application bond accounting

- Date: 2026-11-25
- Status: Accepted

## Context
Delegated stake, service bond, and job-locked bond are distinct concepts. The EVM
precompile cannot attach Native funds.

## Decision
Provider bond is deposited only via Native `funds` as one exact non-zero `uqor`
coin. `ProviderBond` tracks `available_uqor`, `locked_uqor`,
`penalties_paid_uqor`, `withdrawn_uqor`, and `total_deposited_uqor`. Reservation
locks `bond_per_unit * units`; finalization returns all locked bond minus a
basis-point penalty on accepted breach; release returns all locked bond. Only
unlocked bond can be withdrawn. Penalty uses `BankMsg::Send` to a configured
recipient.

## Consequences
Bond conservation is testable locally. G0-B must still verify bank-message
effects and rollback inside a bridge-invoked Native transaction on Diana.
