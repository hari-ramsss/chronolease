# ADR-0005: EVM escrow state machine and atomic reservation

- Date: 2026-11-25
- Status: Accepted

## Context
Buyer fUSD must never remain committed when a Native reservation fails, and a job
must not settle or refund twice.

## Decision
`None -> Created -> Funded -> Reserved -> Settled|Refunded`. `acceptOffer` performs
the fUSD transfer and cross-VM reservation in one transaction; any failure reverts
both. `reserveCapacity` exists as a separate explicit call for Funded jobs and
fails for any other state. Settlement and refund set terminal state before token
transfers and validate the Native response first.

## Consequences
Duplicate reservation, double settlement, and stale transitions are rejected.
The local Foundry suite proves these cases against a stateful mock; real atomicity
requires G0-D.
