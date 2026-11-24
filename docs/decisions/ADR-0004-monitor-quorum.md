# ADR-0004: Monitor evidence in Phase 1

- Date: 2026-11-25
- Status: Accepted for local milestone; trust model incomplete

## Context
The specification requires independent monitors but a full decentralized monitor
network is out of scope for the first milestone.

## Decision
The local EVM escrow accepts a canonical evidence digest from an authorized
monitor identity: `keccak256(jobId, termsHash, deliveredUnits, providerId, slotId)`.
A digest is one-use per job. The adapter's execution report supplies the measured
fields, and the TypeScript demo generates two independent local monitor reports.

## Consequences
Report authenticity and job binding are enforced; report truthfulness is not.
Local attestations are deterministic digests, not signatures. Quorum, staking or
challenge mechanisms, and PQC precompile verification are deferred and must be
documented before production claims.
