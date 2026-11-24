# Phase 0 operator runbook

No deployment or proposal is authorized by this document.

1. Verify Diana chain ID/version/height and reread cross-VM params, circuit
   breaker, Wasm permissions, governance params, EVM precompiles, fee/gas params,
   and the operator's EVM window.
2. Install the official testnet `qorechaind` bundle, keeping its `lib/` beside
   the binary; record version and SHA-256. Confirm hybrid-signing support.
3. The pinned official cosmwasm/optimizer:0.16.1 linux/amd64 build
   has now been verified twice; see the build record below.
4. Proposal A is prepared as upload-only JSON for review. It stores the probe
   Wasm and does not instantiate; see the review bundle and live snapshot.
5. Operator separately approves/submits Proposal A. Record proposal ID/status,
   tx hash, height, code ID, contract address, checksum, and history.
6. Prepare Proposal B from live params, preserving every existing field while
   adding the actual `cosmwasm:<address>` and exact code ID/history pin. Review
   unsigned JSON. Operator separately approves/submits; verify live state.
7. Deploy the minimal Solidity caller during an unscoped authorization window.
   Then open a distinct scoped window allowing `0x0901` and the caller address.
   Calculate blocks, transaction count, and value cap from current CLI help and
   simulated fees; the suggested 600-block sizing in the feasibility report is
   provisional only.
8. Run approved G0-A through G0-D cases; preserve full evidence. No product
   deployment follows unless all gates pass and a new decision approves it.

Never put wallet secrets in files, commands, logs, or chat. Never submit a
proposal or broadcast a transaction without the operator's explicit approval.

## Diana CLI and Proposal A readiness investigation — 24 November 2026

**Status: NOT READY FOR SUBMISSION.** Ubuntu WSL2 reports `x86_64`; read-only
`command -v qorechaind` and `command -v qorechain-pqc` checks returned no paths.
No qorechaind binary was installed; no version/help output, PQC command help,
or shared-library load check exists. No archive was downloaded or extracted,
no wallet storage was accessed, and no key was created, recovered, or used. No
transaction was generated and no gas dry run was performed.

The official Diana [connecting guide](https://docs.qorechain.io/getting-started/connecting-to-testnet/)
still describes v3.2.9, but the live official manifest fetched at this review
reports version/minCompatible `3.2.10`, upgrade height `10654800`, and points to
the v3.2.10 archive. The live applied-plan endpoints report v3.2.9 at
`10424000` and v3.2.10 at `10654800`; current Diana snapshot is height
`10673893`, time `2026-11-24T15:08:00.897621278Z`. This supersedes the prior
snapshot and establishes that the chain has advanced beyond the requested
v3.2.9 release. We did not substitute v3.2.10.

Live proposal 39 establishes the v3.2.9 artifact identifiers:

- Binary: `qorechaind v3.2.9 (final-r26)`, SHA-256
  `29a74776c93d8390266dbb9be56dda55bb44c42aa6ff75654af1a0a00056a4c9`.
- Archive: `qore-artifact-v3.2.9-final-r26-linux-amd64.tgz`, SHA-256
  `58bf0894010e3bab77a373b723aa7bf50cf93bfa9f5ce49ade4bdb06dbafc1a2`.
- Proposal 39 says to copy the whole `lib/` folder, but does not provide an
  archive URL, size, or list of shared libraries. Per the run instructions, no
  URL was guessed and no download was attempted.

Full release evidence: `docs/evidence/qorechain-release-provenance.json`.
Current public-chain parameter responses: `docs/evidence/proposal-a-operator-preflight.json`.
The snapshot at height `10673893` (`2026-11-24T15:08:00.897621278Z`) reports
governance address `qor10d07y265gmmuvt4z0w9aw880jnsr700jwfyxr3`, upload
permission `Nobody`, instantiate permission `Everybody`, `MsgStoreCode` still
disabled, latest code ID `865`, regular deposit `10000000uqor`, voting period
`14400s`, base/minimum gas price `0.1uqor`, consensus max block gas
`500000000`, and cross-VM max Cosmos tx gas `50000000`. The owner QOR balance
could not be retrieved without the public account address.
The operator checklist records the coin-60/PQC account compatibility assessment
and why the CLI dry run is blocked. QoreX's documented native
`signAndBroadcast` broadcasts, so it is not a no-send substitute for this
estimate. The QoreX account address was not provided, so the owner balance and
registered-key record were not queried.

To resume v3.2.9 installation, obtain the exact official archive URL from
QoreChain and verify the archive hash against Proposal 39 before extracting it
under the proposed user-local WSL path with the complete bundled `lib/`
directory. Separately review an owner-only, non-exporting local signing setup
for the already registered coin-60 account. Do not use `recover-key` without a
separate reviewed procedure: the documented command consumes the mnemonic and
writes an unencrypted private key file. Do not run normal `tx pqc cosign`; the
official proposal guide says that mode broadcasts.

## WSL2 optimizer build record

Completed 24 November 2026 in Ubuntu 24.04.3 LTS on WSL2, architecture
`x86_64`. Docker Desktop 4.44.0, Docker client/server 28.3.2; both report
`linux/amd64`. The approved optimizer tag is `cosmwasm/optimizer:0.16.1`, pulled
with `--platform linux/amd64`. The immutable image reference used for both
builds is:

```text
cosmwasm/optimizer@sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e
```

Image tool versions: Rust 1.81.0, Cargo 1.81.0, `wasm-opt` 116. The crate uses
`cosmwasm-std` 1.5.11 and is standalone (no workspace configuration). Cargo
initially could not parse `base64ct 1.8.3` and `zeroize 1.9.2` because they
require Edition 2024. The original lockfile is preserved at
`docs/evidence/Cargo.lock.before-optimizer`; the current lock uses compatible
`base64ct 1.7.3` and `zeroize 1.8.1`. No contract source or logic changed.

Exact reproducible command from Ubuntu:

```bash
cd "/mnt/c/Users/Hari Ram/Documents/chronoquota/contracts/staking-probe"
docker run --rm --platform linux/amd64 -v "$PWD":/code \
  --mount type=volume,source=staking-probe_cache,target=/target \
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
  cosmwasm/optimizer@sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e
```

The exact command ran twice against the same image digest and lockfile. Both
optimizer checksum lines match:

```text
4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509  qorelease_staking_probe.wasm
```

The optimized artifact is 169,218 bytes at
`artifacts/contracts/qorelease_staking_probe.wasm`; the optimizer-generated
checksum file is `artifacts/contracts/checksums.txt`. The first optimized build
and checksum are preserved under `docs/evidence/optimizer-build-1/`; full build
logs are `docs/evidence/optimizer-build-1.log` and
`docs/evidence/optimizer-build-2.log`. The previous direct Cargo output remains
separate as `artifacts/contracts/qorelease_staking_probe.cargo-diagnostic.wasm`
with `checksums-cargo-diagnostic.txt`.

Status: **OPTIMIZED LOCALLY** and **REPRODUCIBLE BUILD VERIFIED**. This does not
pass G0-A or authorize uploading Wasm, submitting Proposal A, or broadcasting
a transaction. Any governance action requires separate review.

## Proposal A review bundle status ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â 24 November 2026

An unsigned upload-only JSON and deterministic gzip/base64 Wasm payload are
prepared under `artifacts/proposals/` using the live Diana state snapshot in
`docs/evidence/proposal-a-live-state.json` (height 10663567). The JSON has exactly
ResetCircuitBreaker, StoreCode, and TripCircuitBreaker in that order; it contains
no instantiate message, code ID, fee, or gas limit. The regular deposit is
`10000000uqor`, expedited is false. See `artifacts/proposals/PROPOSAL_A_REVIEW.md`
and `artifacts/proposals/DEPENDENCY_AUDIT.md` before any separate operator
review. Current milestones: optimized build verified; Proposal A locally prepared;
proposal not submitted or passed; contract not instantiated; G0-A not tested on
Diana and not passed. Probe source commit `724729bcfc34bb43131165bbbe49f90dace5926e` is public at the configured chronolease origin. Dependency audit findings keep the proposal NOT READY. No chain action is authorized by this record.

## Superseding Diana v3.2.10 CLI and Proposal A readiness record — 24 November 2026

This record supersedes earlier v3.2.9/no-install and height 10673893 statements. The later verified snapshot and CLI results below are authoritative.

**Status: NOT READY FOR SUBMISSION.** The current official manifest at `https://download.qore.host/testnet/latest.json` reports version and minCompatible `3.2.10`, upgradeHeight `10654800`, and binary URL `https://download.qore.host/testnet/qorechaind-v3.2.10-final-r2-linux-amd64.tar.gz`. Manifest SHA-256 is `05bf891db98538dce1d9a710f93e5102c0e9ace79f57b4cbf10ae688c63fecb4` and size is `111890694` bytes. The live applied plan is v3.2.10 at height 10654800; latest Diana status is height `10677513`, timestamp `2026-11-24T16:34:02.221783810Z`. The sources agree. Evidence: `docs/evidence/qorechain-v3.2.10-manifest-preflight.json` and `docs/evidence/proposal-a-v3.2.10-final-preflight.json`.

The exact manifest URL was downloaded in Ubuntu WSL2 at `2026-11-24T15:35:54Z` (completed `15:36:16Z`) to `~/.local/qorechain/v3.2.10/qorechaind-v3.2.10-final-r2-linux-amd64.tar.gz`. The preserved archive matched both manifest size and SHA-256 before extraction. Its complete contents, including `lib/`, are installed under `~/.local/qorechain/v3.2.10/`. `env.sh` prepends the install's `bin` and `lib` locations while preserving existing PATH and LD_LIBRARY_PATH values; no shell startup file or system library configuration was changed. See the download, archive-list, and install metadata evidence under `docs/evidence/`.

The installed ELF is x86-64, SHA-256 `ffc76719d5f31bd59e42176c2d92c2e43e2386b4bcd5686964a847814ae81d3f`. `ldd` found no missing libraries; `LD_DEBUG=libs` confirms bundled `libqorepqc.so`, `libqoresvm.so`, and `libwasmvmqore_v1.x86_64.so` loaded for version/help invocation. The bundle's `libwasmvm.x86_64.so` is preserved but was not exercised by those commands. `qorechaind version` and `version --long` exited successfully but printed no version text; v3.2.10 provenance is established by the verified official manifest bundle, not that CLI output. Full command output: `docs/evidence/qorechain-v3.2.10-cli-verification.log`.

Installed help confirms PQC commands are integrated into `qorechaind`; no standalone `qorechain-pqc` binary is required. `tx pqc cosign` help documents `--dry-run` as a non-broadcast gas simulation and notes local Keybase is inaccessible in that mode. `gov submit-proposal --generate-only` successfully generated unsigned JSON from existing Proposal A without signing; signer/signature arrays are empty and it has no fees. The supplied public account `qor1f0zn99as5ymf0m4curxrx4csz096vnrupdtadq` has balance `99865000uqor`; live PQC registration reports `found=true`, `key_type=hybrid`, `possession_proven=true`. No wallet extension storage or private key was accessed.

An actual gas simulation did **not** occur. The first cosign dry-run failed because `--pqc-key` is required. A second attempt with a nonexistent placeholder key and in-memory keyring stopped because the CLI requires a local `.dilithium` key file. No key was created, recovered, read, or used, and no simulation reached the node. Logs and commands: `docs/evidence/proposal-a-gas-dry-run-v3.2.10.log` and `docs/evidence/dry-run-proposal-a-gas-v3.2.10.sh`. No genuine gas measurement exists and no fee has been calculated; the provisional 20-million estimate is invalid for use. The official measured-gas-plus-30% procedure cannot be applied until a separately reviewed safe signing-key procedure is available.

Latest live snapshot (height `10677513`, time `2026-11-24T16:34:02.221783810Z`): governance account `qor10d07y265gmmuvt4z0w9aw880jnsr700jwfyxr3`; upload permission `Nobody`; instantiate default `Everybody`; `MsgStoreCode` disabled; latest code ID 865; normal deposit `10000000uqor`; voting period `14400s`; quorum `.334`, threshold `.5`, veto `.334`; minimum gas price/base fee `.1uqor`; max block gas 500000000; cross-VM max Cosmos tx gas 50000000. Generic tx params endpoint returned HTTP 501. These are a dated snapshot and must be refreshed before any future submission.

The package remains **NOT READY FOR SUBMISSION** because a real no-broadcast gas result and reviewed fee are unavailable without local PQC signing material, which was not accessed. No transaction was signed, cosigned, broadcast or submitted; no code was uploaded or instantiated. G0-A remains untested and not passed.

Unsigned transaction preparation evidence: `docs/evidence/generate-proposal-a-unsigned-v3.2.10.sh` records the exact `qorechaind tx gov submit-proposal artifacts/proposals/proposal-a-store-probe.json --from qor1f0zn99as5ymf0m4curxrx4csz096vnrupdtadq --chain-id qorechain-diana --node https://rpc-testnet.qore.host:443 --generate-only --output json` invocation. Its valid unsigned output is `docs/evidence/proposal-a-unsigned-tx-v3.2.10.json`; generation log is adjacent. It is unsigned preparation only, has no final gas/fee, and is not a broadcast-ready transaction. The attempted dry-run command and its two key-related failures are preserved in `docs/evidence/dry-run-proposal-a-gas-v3.2.10.sh` and `docs/evidence/proposal-a-gas-dry-run-v3.2.10.log`.

---

## Phase 1 local implementation record — 25 November 2026

The owner directed implementation to begin while G0-A..E remain open. This does
not change their status. No proposal was submitted, no code uploaded, no contract
instantiated, no transaction signed or broadcast, and no Diana RPC state changed
during this work. The accepted staking probe, optimized Wasm, checksums, evidence,
and Proposal A bundle were preserved unchanged.

### New source and tools

- `contracts/qorelease-registry/` — standalone CosmWasm 1.5.11 registry; pinned
  `Cargo.lock` generated locally with the same dependency versions.
- `contracts/evm/` — Foundry 1.5.1-stable in Ubuntu WSL2, Solidity 0.8.24,
  forge-std v1.9.6 (`3b20d60d14b343ee4f908cb8079495c07f5e8981`).
- `services/provider-adapter/` — TypeScript adapter, Node 24 type stripping.
- `scripts/local-e2e.sh` and `scripts/local-e2e.ps1` — local demonstration.

No live deployment configuration is claimed. The EVM bridge address defaults to
the documented `0x0901` only as configuration; the escrow's actual bridge address
is an admin-controlled deployment input. Diana live checks in the Phase 0 sections
above must be refreshed before any deployment.

### Actual local results

- Native: 11 unit tests + 1 e2e integration test pass (`cargo test --locked`).
- Solidity: 13 Foundry tests pass (`bash docs/evidence/run-foundry-tests.sh`).
- Adapter: 7 Node tests pass; local demo executes 70 requests against a local
  OpenAI-compatible HTTP endpoint and emits two independent monitor reports.
- Full combined run: `powershell -ExecutionPolicy Bypass -File scripts/local-e2e.ps1 -SaveEvidence`.

Evidence log: `docs/evidence/local-e2e.log`.

### Deployment gates still blocking live use

G0-A staking query semantics and unbonding inclusion; G0-B bank-message rollback
through the bridge; G0-C mapped escrow sender and EVM window scope; G0-D real
bridge atomicity, empty/malformed response, and response encoding; G0-E governance
upload/allowlist/code pin. See `docs/FEASIBILITY_SPIKES.md` and
`docs/decisions/ADR-0008-local-mocks.md`.
