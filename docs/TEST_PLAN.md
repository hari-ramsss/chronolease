# Phase 0 test plan

All listed chain tests are planned, not executed. Retain exact commands,
versions, source commit, checksum, tx hash, block height, logs, and observed
state for each run.

| Gate | Positive case | Negative case | Evidence |
|---|---|---|---|
| G0-A | Probe zero/one/multiple delegations; compare REST/CLI | malformed address, unsupported query, wrong denom, overflow | persisted probe result and matching staking query |
| G0-B | bridged `BankMsg::Send` release/penalty | insufficient funds/module failure; EVM revert afterwards | balances and contract state before/after |
| G0-C | mapped escrow caller is authorized | wrong sender and out-of-window/out-of-scope calls | `info.sender`, mapping, window query and receipts |
| G0-D | Native and EVM changes persist | Native reject, later EVM revert, empty/malformed return, inactive bridge, unallowlisted target | state on both runtimes and receipts |
| G0-E | proposal reaches passed state and pin is live | rejected/failed proposal or wrong pin | proposal status, code info/history, live params |

Never call a case passed based only on mocks, docs, simulation, or proposal
submission. Do not broadcast until the operator explicitly approves the exact
transaction batch.
