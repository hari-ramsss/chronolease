# ADR-0002: Staking admission helper and the unresolved delegation question

- Date: 2026-11-25
- Status: Accepted with an open deployment gate

## Context
`StakingQuery::AllDelegations` exists in CosmWasm 1.5.11 but Diana runtime support
is not proven. The accepted probe is the canonical feasibility artifact.

## Decision
`query_uqor_delegations` in `qorelease-registry/src/lib.rs` is the only place that
issues the query. It sums only `uqor` with checked arithmetic and returns any query
error to the caller (fail closed). Threshold is configurable at instantiate and
via admin update. Registrations, slot publications, and reservations recheck it.

## Consequences / unresolved question
We do not know whether Diana's `AllDelegations` returns bonded-only delegations
or also unbonding entries, nor whether the query works inside the bridge context.
G0-A must record this before any live admission claim. No backend-signed stake
boolean is substituted.
