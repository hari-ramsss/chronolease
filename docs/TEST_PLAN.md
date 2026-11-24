# QoreLease test plan and actual Phase 1 results

All results below are **local**. Status labels: `TESTED LOCALLY`, `NOT VERIFIED ON DIANA`.

## Commands (Windows PowerShell + Ubuntu WSL2)

```powershell
cd contracts/qorelease-registry
cargo test --locked
cd ..\..
powershell -ExecutionPolicy Bypass -File scripts/local-e2e.ps1 -SaveEvidence
```

The orchestration script runs Rust e2e, Foundry, adapter tests and the local
provider/monitor demo. Evidence: `docs/evidence/local-e2e.log`.

## Native Rust — `TESTED LOCALLY` (12 passed)

Registration with valid/insufficient stake; `uqor`-only checked aggregation;
staking query error propagation via controlled mock; bond deposit with correct
and wrong denomination; bond lock/release/withdraw; slot publication and
overlap rejection; successful reservation; insufficient capacity; insufficient
bond; duplicate job; unauthorized escrow caller; expired slot; permissionless
expiry release; double finalization; breach penalty accounting; strict response
layout; config authorization. `tests/e2e_native.rs` drives the real entry points
for the 100/70/50 overbooking scenario.

These tests use `MockQuerier` staking entries. They are not Diana verification.

## Solidity / Foundry — `TESTED LOCALLY` (13 passed)

Successful escrow + Native reservation; overbooking rejection with buyer B fUSD
rollback; Native rejection revert; empty bridge response; malformed response;
wrong job/terms in response; duplicate reservation; bridge failure; invalid
evidence cannot pay; valid settlement with duplicate rejection; failed
settlement leaves funds in escrow; refund releases Native state; forced later
EVM revert undoes the stateful native mock's change.

Foundry 1.5.1-stable, solc 0.8.24, forge-std v1.9.6 pinned. Atomicity tests use
stateful mocked bridge/native contracts. They do not prove Diana bridge behaviour.

## Provider adapter — `TESTED LOCALLY` (7 passed)

Valid reservation permits execution; missing reservation rejects before any
workload call; expired reservation rejects; request exceeding reserved units
rejected; terms mismatch rejected; released reservation and invalid job id
rejected; evidence contains correct job id/terms hash and monitor bindings.

## Local E2E — `TESTED LOCALLY`

`scripts/local-e2e.sh` reproduces the 14-step local scenario across the three
components. Steps 1-9/13 use real Rust code with mocked staking; steps 5/7-9/12/14
use real Solidity with a stateful local bridge/native mock; steps 10-11 use the
adapter against a local OpenAI-compatible HTTP endpoint. No Diana transactions.

## Still required on Diana (all `NOT VERIFIED`)

G0-A staking query semantics; G0-B bank-message effects through bridge; G0-C
sender mapping/window; G0-D all bridge atomicity and response cases; G0-E
governance. Do not mark any of these passed from local mocks.
