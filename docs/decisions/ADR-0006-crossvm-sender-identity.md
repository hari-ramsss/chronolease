# ADR-0006: Cross-VM caller authorization

- Date: 2026-11-25
- Status: Accepted with G0-C open

## Context
The bridge maps an EVM caller/contract to a Native `qor1...` identity. A JSON
field cannot be trusted as identity proof.

## Decision
The Native registry stores `authorized_escrow` at instantiate (admin-updatable)
and compares it directly to `info.sender` for `reserve` and `finalize`. The Solidity
payload deliberately contains no caller/sender field. The EVM escrow stores the
mapped identity only as operator configuration/documentation.

## Consequences
Local tests prove that a wrong sender is rejected and that the payload carries no
identity field. The actual mapping of the deployed escrow and the EVM window scope
remain **NOT VERIFIED** until G0-C runs on Diana. No mapping is invented.
