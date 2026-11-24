# ADR-0008: Local mocks are not Diana evidence

- Date: 2026-11-25
- Status: Accepted

## Context
The owner asked for implementation before the G0 gates closed, while the original
specification forbids claiming Diana compatibility without evidence.

## Decision
All tests that stand in for chain behaviour are explicitly labelled local mocks:
Rust `MockQuerier` staking entries, Solidity stateful bridge/native token mocks,
and the TypeScript in-memory Native client / OpenAI-compatible HTTP mock. The
local E2E script combines real contract code with these mocks but never broadcasts
or instantiates anything.

## Consequences
We can prove product logic, authorization, accounting, and local atomicity now.
No document or output may describe these as Diana verification. G0-A..E remain
open with the evidence requirements recorded in `FEASIBILITY_SPIKES.md`.
