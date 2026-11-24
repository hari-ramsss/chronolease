# QoreLease EVM escrow and Cross-VM caller

Foundry/Solidity 0.8.24 project. All components are local implementations; none
have been deployed or tested on Diana.

## Source map

- `src/QoreLeaseEscrow.sol` — fUSD escrow, job state machine, evidence-bound
  settlement, refunds, and JSON execute-message construction.
- `src/CrossVMBridgeService.sol` — isolated low-level `CALL` wrapper for the
  bridge address, with zero value, explicit call-failure revert, empty-response
  rejection, and ABI/raw return normalisation.
- `src/CrossVMResponseCodec.sol` — strict decoder for the proposed seven-word
  Native response. Diana's real encoding is **NOT VERIFIED**.
- `src/QoreLeaseConfig.sol` — bridge address, Native target, mapped escrow identity
  and monitor authorization, separated from product logic.
- `test/mocks/` — stateful bridge and native mocks plus a mock fUSD token.

## Local setup (Ubuntu WSL2)

Foundry 1.5.1-stable is installed at `~/.foundry/bin`. The pinned forge-std
v1.9.6 (`3b20d60d14b343ee4f908cb8079495c07f5e8981`) is installed with
`bash docs/evidence/install-forge-std.sh`.

```bash
bash docs/evidence/run-foundry-tests.sh
```

13 local tests pass. These include overbooking rejection with buyer fUSD rollback,
empty/malformed response handling, duplicate reservation/settlement rejection,
invalid evidence rejection, failed settlement leaving funds in escrow, and a
forced later EVM revert undoing the stateful native mock's change. They are
**local atomicity tests only** and are not evidence of Diana bridge behaviour.

Production configuration still requires live verification of the `0x0901`
precompile, target allowlist/code pin, mapped `qor1...` sender identity, EVM
authorization window, fUSD token address/decimals, and actual response encoding.
