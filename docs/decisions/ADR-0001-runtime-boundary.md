# ADR-0001: Runtime boundary for Phase 1

- Date: 2026-11-25
- Status: Accepted for local implementation; live Diana value NOT VERIFIED

## Context
The specification assigns provider registry, staking eligibility, QOR bond, and
capacity lifecycle to QoreChain Native; buyer fUSD escrow and settlement to EVM;
and execution to an off-chain adapter. The owner directed implementation to begin
before the G0 gates were closed.

## Decision
Implement the split exactly as specified, but isolate every runtime-dependent
behind an explicit helper or injected client: Native staking helper, Solidity
bridge service/config, and a TypeScript Native client interface. Local mocks
prove logic only; live integration remains a deployment gate.

## Consequences
Product code exists and is testable without claiming Diana compatibility. Every
live claim is deliberately deferred to G0-A..E evidence.
