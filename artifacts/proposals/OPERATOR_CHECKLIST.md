# Proposal A operator checklist

Status: **PREPARED FOR REVIEW — NOT READY FOR SUBMISSION**
Proposal file: `artifacts/proposals/proposal-a-store-probe.json`
Snapshot evidence: `docs/evidence/proposal-a-final-live-preflight.json`

This is an operator procedure only. The proposal has not been signed, cosigned, broadcast, submitted, uploaded, or instantiated. Owner approval of dependency risk is limited to the exact Diana testnet staking feasibility probe; it does not authorize any transaction or apply to production.

## Before any future submission attempt

1. Obtain the official QoreChain **v3.2.9** `qorechaind` bundle using the official [Diana testnet connection guide](https://docs.qorechain.io/getting-started/connecting-to-testnet/) and [v3.2.9 upgrade proposal 39](https://api-testnet.qore.host/cosmos/gov/v1/proposals/39). Verify the published bundle name, SHA-256, manifest version, and keep its complete `lib/` directory beside the binary. This environment currently has no `qorechaind` on `PATH`; binary availability and local version are not verified.
2. Confirm the expected CLI is available: `qorechaind version --long`, `qorechaind tx pqc --help`, and `qorechaind tx pqc cosign --help`. Confirm that its `--dry-run` mode is supported. The PQC commands are part of `qorechaind`; without that executable, PQC tool availability is also unverified.
3. Refresh all live preflight data immediately before preparing a real transaction: chain ID and height/time, governance account, upload and instantiate permissions, circuit breaker, code ID, governance deposit/voting/tally parameters, cross-VM parameters, fee-market values, and transaction gas limits. Current evidence is a dated snapshot only and must not be reused as future live state.
4. Confirm the current governance module address, upload permissions, and `MsgStoreCode` circuit breaker still support the atomic reset/store/restore sequence. Check the exact Wasm SHA-256 and verify the proposal payload again.
5. Confirm the owner has separately approved Proposal A submission. The recorded risk acceptance is not transaction authorization.

## Proposal and unsigned transaction generation

The prepared proposal JSON contains three messages, in order: reset the `MsgStoreCode` circuit breaker, store the optimized Wasm, and restore the breaker. It attaches the regular minimum deposit `10000000uqor` from the last snapshot. Do not regenerate it without an identified defect and a fresh review of all embedded values.

From the repository root, create an unsigned transaction using the current key alias configured in the operator's local wallet (the alias is a placeholder and no key material belongs in commands or logs):

```sh
qorechaind tx gov submit-proposal artifacts/proposals/proposal-a-store-probe.json \
  --from <owner-key-alias> \
  --chain-id qorechain-diana \
  --node https://rpc-testnet.qore.host:443 \
  --gas 20000000 \
  --fees 2000000uqor \
  --generate-only > /tmp/proposal-a-unsigned.json
```

The gas/fee pair above is a **provisional starting estimate**, not an approved final value. The public QoreChain governance guide recommends a dry run, then 30% headroom over measured gas, and fees of at least `gas × 0.1 uqor`; it cites 20,000,000 gas and 2,000,000 `uqor` for a roughly 100 KB proposal carrying code. This proposal JSON is 79,440 bytes. The live fee-market snapshot also reported `0.1uqor` minimum gas price and base fee. Transaction parameter REST endpoints returned HTTP 501 during this preflight. Recalculate from the actual dry run and fresh live fee data before any approved signing.

## PQC cosign dry run and fee selection

First run only the documented no-send dry run against the locally generated unsigned transaction:

```sh
qorechaind tx pqc cosign /tmp/proposal-a-unsigned.json \
  --from <owner-key-alias> \
  --pqc-key <owner-pqc-key-alias> \
  --chain-id qorechain-diana \
  --node https://rpc-testnet.qore.host:443 \
  --dry-run
```

Use the reported gas estimate plus at least 30%, round up, then set fees to at least the selected gas limit multiplied by the current minimum gas price. Regenerate the unsigned transaction with the reviewed `--gas` and `--fees`; repeat dry-run estimation. Confirm the exact proposal file and Wasm hashes once more. The official guide says `--generate-only` creates an unsigned transaction and that the non-dry-run `tx pqc cosign` command adds the hybrid signatures **and broadcasts**. Treat it as the final send step, not as a local signing-only operation.

## Manual broadcast — owner only after separate explicit approval

This is the broadcast command. Do not run it as part of preparation:

```sh
qorechaind tx pqc cosign /tmp/proposal-a-unsigned.json \
  --from <owner-key-alias> \
  --pqc-key <owner-pqc-key-alias> \
  --chain-id qorechain-diana \
  --node https://rpc-testnet.qore.host:443
```

Run it manually only after the owner has explicitly approved submission, the official binary and fee estimate are verified, and the live preflight has been refreshed. Never provide private keys, recovery phrases, or PQC seeds to this repository or chat.

## Post-submission verification

Using the returned transaction hash and proposal ID:

```sh
qorechaind query tx <TX_HASH> --node https://rpc-testnet.qore.host:443
qorechaind query gov proposal <PROPOSAL_ID> --node https://rpc-testnet.qore.host:443
```

Confirm the proposal title, deposit, status, and messages. A proposal in `PROPOSAL_STATUS_DEPOSIT_PERIOD` has not yet reached the minimum deposit; check the exact live state before any deposit transaction. After voting ends, confirm the proposal passed and has no `failed_reason`. Only then inspect the returned store-code event for the actual code ID, query `/cosmwasm/wasm/v1/code/<CODE_ID>`, and compare its `code_info.data_hash` with `4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`. Record the transaction hash, proposal ID, final status, height, and code ID. Do not instantiate as part of Proposal A.

Official command and gas references: [QoreChain contract governance proposal guide](https://docs.qorechain.io/developer-guide/governance-proposals-contracts/) and [transaction command reference](https://docs.qorechain.io/cli-reference/transaction-commands/).
