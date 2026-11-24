# Proposal A operator checklist

Status: **NOT READY FOR SUBMISSION — v3.2.10 installed; no genuine gas simulation or reviewed fee**
Proposal file: `artifacts/proposals/proposal-a-store-probe.json`
Current snapshot: `docs/evidence/proposal-a-operator-preflight.json`
Release evidence: `docs/evidence/qorechain-release-provenance.json`

This is an operator procedure only. The proposal has not been signed, cosigned, broadcast, submitted, uploaded, or instantiated. Owner approval of dependency risk is limited to the exact Diana testnet staking feasibility probe; it does not authorize any transaction or apply to production.

## Before any future submission attempt

1. **Do not download or extract the requested v3.2.9 artifact yet.** Diana Proposal 39 records `qorechaind v3.2.9 (final-r26)` binary SHA-256 `29a74776c93d8390266dbb9be56dda55bb44c42aa6ff75654af1a0a00056a4c9` and archive `qore-artifact-v3.2.9-final-r26-linux-amd64.tgz` SHA-256 `58bf0894010e3bab77a373b723aa7bf50cf93bfa9f5ce49ade4bdb06dbafc1a2`. Proposal 39 does **not** include a URL. The live official manifest now says v3.2.10, minCompatible v3.2.10, upgrade height `10654800`; its binary URL points to v3.2.10, so it is not substituted here. Obtain an exact official v3.2.9 URL from QoreChain and verify it against the on-chain filename/hash before download. The official [testnet guide](https://docs.qorechain.io/getting-started/connecting-to-testnet/) still describes v3.2.9, but its manifest differs from the current live manifest.
2. Ubuntu WSL2 reports `x86_64`; `command -v qorechaind` and `command -v qorechain-pqc` returned no paths. No binary was installed. Therefore version, `--help`, PQC subcommand availability, the archive's actual binary architecture, archive size, and bundled shared-library contents/load status have not been verified. Do not run a GitHub-source build as a substitute for the official signer.
3. Refresh all live preflight data immediately before any future transaction: chain ID and height/time, governance account, upload and instantiate permissions, circuit breaker, code ID, governance deposit/voting/tally parameters, cross-VM parameters, fee-market values, and transaction gas limits. Current evidence is a dated snapshot only and must not be reused as future live state. The owner account balance remains unknown because no public account address was supplied; wallet storage was not accessed.
4. Confirm the current governance module address, upload permissions, and `MsgStoreCode` circuit breaker still support the atomic reset/store/restore sequence. Check the exact Wasm SHA-256 and verify the proposal payload again.
5. Confirm the owner has separately approved Proposal A submission. The recorded risk acceptance is not transaction authorization.

## Proposal and unsigned transaction generation

The prepared proposal JSON contains three messages, in order: reset the `MsgStoreCode` circuit breaker, store the optimized Wasm, and restore the breaker. It attaches the regular minimum deposit `10000000uqor` from the last snapshot. Do not regenerate it without an identified defect and a fresh review of all embedded values.

The following is the command shape from the official guide, **not verified against an installed binary**. Do not run until the official bundle is verified, installed, and the installed CLI help confirms the flags and keyring alias. No gas value is supplied here because the required actual-proposal dry run has not occurred:

```sh
qorechaind tx gov submit-proposal artifacts/proposals/proposal-a-store-probe.json \
  --from <owner-key-alias> \
  --chain-id qorechain-diana \
  --node https://rpc-testnet.qore.host:443 \
  --gas <REVIEWED_GAS_LIMIT> \
  --fees <REVIEWED_FEE>uqor \
  --generate-only > /tmp/proposal-a-unsigned.json
```

Do not reuse the earlier 20,000,000 gas / 2,000,000 `uqor` placeholder. The official [governance guide](https://docs.qorechain.io/developer-guide/governance-proposals-contracts/) says to dry-run the actual transaction, add 30% to measured gas, and use fees of at least `gas Ã— 0.1 uqor`. The current snapshot reports minimum gas price and base fee `0.1uqor`, consensus max block gas `500000000`, and cross-VM max Cosmos tx gas `50000000`. Generic transaction parameter REST endpoints return HTTP 501. The correct gas and fee cannot be fixed until an actual safe dry run and immediate live refresh.

## PQC cosign dry run and fee selection

The official governance guide documents `qorechaind tx pqc cosign ... --dry-run` as estimating gas without sending. The installed CLI help could not be inspected, and there is no local CLI keyring confirmed for the account. **Do not run this command until both issues are resolved.** This command shape is informational only:

```sh
qorechaind tx pqc cosign /tmp/proposal-a-unsigned.json \
  --from <owner-key-alias> \
  --pqc-key <owner-pqc-key-alias> \
  --chain-id qorechain-diana \
  --node https://rpc-testnet.qore.host:443 \
  --dry-run
```

If the verified installed help confirms no-send behavior and the approved local account keys are already available, use reported gas plus at least 30%, round up, and set fees to at least gas times the refreshed minimum gas price. Regenerate the unsigned transaction with reviewed values and repeat the no-send estimate. Confirm the proposal and Wasm hashes again. The official guide says the non-dry-run `tx pqc cosign` adds hybrid signatures **and broadcasts**; it is not a local signing-only operation.

## Account and signing compatibility â€” owner review required

QoreChain's [official account guide](https://docs.qorechain.io/getting-started/deploy-in-5-minutes/) documents the Ethereum/coin-60 path `m/44'/60'/0'/0/i` and `eth_secp256k1`; the default Cosmos coin-118 key is a different account. `qor1...` and `0x...` are two encodings of the same 20-byte account address when derived from the same key. The CLI keyring must already contain an alias for the exact account; the documented `qorechaind keys import <name> <keyfile>` imports key material from a local file, and `keys add --recover` derives from a mnemonic. Neither operation was run, and no QoreX extension data was inspected.

The registered ML-DSA-87 key is address-bound. QoreChain documents its derivation as `SHAKE-256("qorechain:pqc:v1|" + cosmosAddress + "|" + mnemonic)`. The official CLI `tx pqc recover-key <name> <qor1-address>` reads a mnemonic from stdin and writes an unencrypted key file with mode `0600`; it can recover the registered key when supplied the same phrase and address, but it was **not run** and I am not asking the owner to run it. No mnemonic, extension storage, or key files were accessed. The CLI signing path needs local classical and PQC signing keys; none has been confirmed in this environment.

QoreChain's [QoreX integration](https://docs.qorechain.io/developer-tools/qorex-integrations/) exposes native `signAndBroadcast`, which signs with both keys and broadcasts. Its documented `signDirect` requires the SignDoc to already contain the hybrid layer; adding that layer via `signDirect` is listed as planned. Therefore the documented QoreX API does not provide a verified no-broadcast cosign path for this dry run. The SDK can hybrid-sign when supplied the PQC keypair, but does not remove the key-access requirement. The owner must review a separate secure local key-access procedure before any key setup or signing; no key recovery is requested here.

## Manual broadcast â€” owner only after separate explicit approval

This is the broadcast command. Do not run it as part of preparation:

```sh
qorechaind tx pqc cosign /tmp/proposal-a-unsigned.json \
  --from <owner-key-alias> \
  --pqc-key <owner-pqc-key-alias> \
  --chain-id qorechain-diana \
  --node https://rpc-testnet.qore.host:443
```

This step remains disabled. Run it manually only after the owner has explicitly approved submission, the official binary and fee estimate are verified, and live preflight is refreshed. Never provide private keys, recovery phrases, or PQC seeds to this repository or chat.

## Post-submission verification

Using the returned transaction hash and proposal ID:

```sh
qorechaind query tx <TX_HASH> --node https://rpc-testnet.qore.host:443
qorechaind query gov proposal <PROPOSAL_ID> --node https://rpc-testnet.qore.host:443
```

Confirm the proposal title, deposit, status, and messages. A proposal in `PROPOSAL_STATUS_DEPOSIT_PERIOD` has not yet reached the minimum deposit; check the exact live state before any deposit transaction. After voting ends, confirm the proposal passed and has no `failed_reason`. Only then inspect the returned store-code event for the actual code ID, query `/cosmwasm/wasm/v1/code/<CODE_ID>`, and compare its `code_info.data_hash` with `4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`. Record the transaction hash, proposal ID, final status, height, and code ID. Do not instantiate as part of Proposal A.

Official command and gas references: [QoreChain contract governance proposal guide](https://docs.qorechain.io/developer-guide/governance-proposals-contracts/) and [transaction command reference](https://docs.qorechain.io/cli-reference/transaction-commands/).

## Superseding Diana v3.2.10 CLI and Proposal A readiness record â€” 24 November 2026

This record supersedes earlier v3.2.9/no-install and height 10673893 statements. The later verified snapshot and CLI results below are authoritative.

**Status: NOT READY FOR SUBMISSION.** The current official manifest at `https://download.qore.host/testnet/latest.json` reports version and minCompatible `3.2.10`, upgradeHeight `10654800`, and binary URL `https://download.qore.host/testnet/qorechaind-v3.2.10-final-r2-linux-amd64.tar.gz`. Manifest SHA-256 is `05bf891db98538dce1d9a710f93e5102c0e9ace79f57b4cbf10ae688c63fecb4` and size is `111890694` bytes. The live applied plan is v3.2.10 at height 10654800; latest Diana status is height `10677513`, timestamp `2026-11-24T16:34:02.221783810Z`. The sources agree. Evidence: `docs/evidence/qorechain-v3.2.10-manifest-preflight.json` and `docs/evidence/proposal-a-v3.2.10-final-preflight.json`.

The exact manifest URL was downloaded in Ubuntu WSL2 at `2026-11-24T15:35:54Z` (completed `15:36:16Z`) to `~/.local/qorechain/v3.2.10/qorechaind-v3.2.10-final-r2-linux-amd64.tar.gz`. The preserved archive matched both manifest size and SHA-256 before extraction. Its complete contents, including `lib/`, are installed under `~/.local/qorechain/v3.2.10/`. `env.sh` prepends the install's `bin` and `lib` locations while preserving existing PATH and LD_LIBRARY_PATH values; no shell startup file or system library configuration was changed. See the download, archive-list, and install metadata evidence under `docs/evidence/`.

The installed ELF is x86-64, SHA-256 `ffc76719d5f31bd59e42176c2d92c2e43e2386b4bcd5686964a847814ae81d3f`. `ldd` found no missing libraries; `LD_DEBUG=libs` confirms bundled `libqorepqc.so`, `libqoresvm.so`, and `libwasmvmqore_v1.x86_64.so` loaded for version/help invocation. The bundle's `libwasmvm.x86_64.so` is preserved but was not exercised by those commands. `qorechaind version` and `version --long` exited successfully but printed no version text; v3.2.10 provenance is established by the verified official manifest bundle, not that CLI output. Full command output: `docs/evidence/qorechain-v3.2.10-cli-verification.log`.

Installed help confirms PQC commands are integrated into `qorechaind`; no standalone `qorechain-pqc` binary is required. `tx pqc cosign` help documents `--dry-run` as a non-broadcast gas simulation and notes local Keybase is inaccessible in that mode. `gov submit-proposal --generate-only` successfully generated unsigned JSON from existing Proposal A without signing; signer/signature arrays are empty and it has no fees. The supplied public account `qor1f0zn99as5ymf0m4curxrx4csz096vnrupdtadq` has balance `99865000uqor`; live PQC registration reports `found=true`, `key_type=hybrid`, `possession_proven=true`. No wallet extension storage or private key was accessed.

An actual gas simulation did **not** occur. The first cosign dry-run failed because `--pqc-key` is required. A second attempt with a nonexistent placeholder key and in-memory keyring stopped because the CLI requires a local `.dilithium` key file. No key was created, recovered, read, or used, and no simulation reached the node. Logs and commands: `docs/evidence/proposal-a-gas-dry-run-v3.2.10.log` and `docs/evidence/dry-run-proposal-a-gas-v3.2.10.sh`. No genuine gas measurement exists and no fee has been calculated; the provisional 20-million estimate is invalid for use. The official measured-gas-plus-30% procedure cannot be applied until a separately reviewed safe signing-key procedure is available.

Latest live snapshot (height `10677513`, time `2026-11-24T16:34:02.221783810Z`): governance account `qor10d07y265gmmuvt4z0w9aw880jnsr700jwfyxr3`; upload permission `Nobody`; instantiate default `Everybody`; `MsgStoreCode` disabled; latest code ID 865; normal deposit `10000000uqor`; voting period `14400s`; quorum `.334`, threshold `.5`, veto `.334`; minimum gas price/base fee `.1uqor`; max block gas 500000000; cross-VM max Cosmos tx gas 50000000. Generic tx params endpoint returned HTTP 501. These are a dated snapshot and must be refreshed before any future submission.

The package remains **NOT READY FOR SUBMISSION** because a real no-broadcast gas result and reviewed fee are unavailable without local PQC signing material, which was not accessed. No transaction was signed, cosigned, broadcast or submitted; no code was uploaded or instantiated. G0-A remains untested and not passed.


Unsigned transaction preparation evidence: `docs/evidence/generate-proposal-a-unsigned-v3.2.10.sh` records the exact `qorechaind tx gov submit-proposal artifacts/proposals/proposal-a-store-probe.json --from qor1f0zn99as5ymf0m4curxrx4csz096vnrupdtadq --chain-id qorechain-diana --node https://rpc-testnet.qore.host:443 --generate-only --output json` invocation. Its valid unsigned output is `docs/evidence/proposal-a-unsigned-tx-v3.2.10.json`; generation log is adjacent. It is unsigned preparation only, has no final gas/fee, and is not a broadcast-ready transaction. The attempted dry-run command and its two key-related failures are preserved in `docs/evidence/dry-run-proposal-a-gas-v3.2.10.sh` and `docs/evidence/proposal-a-gas-dry-run-v3.2.10.log`.
