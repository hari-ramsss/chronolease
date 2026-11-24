# ADR-0007: Proposed v1 Native response encoding

- Date: 2026-11-25
- Status: Proposed; locally implemented; Diana format NOT VERIFIED

## Context
A successful low-level bridge call can carry empty or unrelated bytes. Solidity
must not assume a Cosmos/Rust `Response.data` layout is ABI-compatible.

## Decision
Define v1 as exactly seven 32-byte big-endian words (224 bytes): version,
operation, jobId, termsHash, reservedUnits, deliveredUnits, availableUnits. Rust
emits it as `Response.data`; Solidity rejects any other length and validates all
fields. The bridge service also rejects empty return data and normalises
ABI-encoded versus raw bytes.

## Consequences
Both sides are locally tested against the same format. If Diana's actual encoding
differs, the adapter must be updated after capturing real evidence; until then,
the escrow fails closed rather than treating a call as successful.
