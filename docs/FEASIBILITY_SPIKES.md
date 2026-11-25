# QoreLease feasibility spikes

Status labels used here: **CONFIRMED** means a primary documentation or live
parameter read supports the claim; **TESTED LOCALLY** means only local test
coverage; **TESTED ON DIANA** means a real public testnet transaction and its
evidence are recorded. No status in this document should be read as a product
implementation approval.

## Baseline captured 24 November 2026

- **Chain:** `qorechain-diana`, height `10,650,195`, observed at
  `2026-11-24T05:39:25.837822445Z`.
- **Live Cross-VM parameters:** `enabled: true`; max message size `65,536`;
  four allowlisted and code-pinned Native targets. None is a QoreLease target.
- **Live EVM parameters:** the active static precompile list contains
  `0x0000000000000000000000000000000000000901`.
- **Live circuit breaker:** `/cosmwasm.wasm.v1.MsgStoreCode` is disabled;
  `MsgCrossVMCall` is absent from the disabled list.
- **Live Wasm permissions:** upload access is `Nobody`; default instantiation
  permission is `Everybody`. A custom code upload needs governance approval.
- **Governance:** minimum normal deposit is `10,000,000uqor` (10 QOR), voting
  period is 14,400 seconds, quorum is 0.334, and threshold is 0.5.
- **Local toolchain:** Rust 1.93.0 with `wasm32-unknown-unknown`; Docker is
  installed but its daemon was unavailable. `qorechaind`, Foundry `forge`, and
  `cast` were not installed.

Sources: the live endpoints prescribed in `SOURCES.md` §4; QoreChain's
[Cross-VM reference](https://docs.qorechain.io/developer-guide/cross-vm-reference/),
[precompile reference](https://docs.qorechain.io/developer-guide/evm-precompiles/),
and [contract-governance guide](https://docs.qorechain.io/developer-guide/governance-proposals-contracts/).

## G0-A — Can a CosmWasm contract query Native delegations?

**Question:** Does the deployed Diana runtime expose
`StakingQuery::AllDelegations` to a QoreChain Native contract, with complete
and correctly understood `uqor` semantics?

**Contract source commit:** [`724729bcfc34bb43131165bbbe49f90dace5926e`](https://github.com/hari-ramsss/chronolease/commit/724729bcfc34bb43131165bbbe49f90dace5926e); the source inputs are public.

**Source inspection (24 November 2026):** the QoreChain core `main` branch's
`app/app.go` constructs `wasmkeeper.NewKeeper` with `app.StakingKeeper` as an
argument ([source](https://github.com/qorechain/qorechain-core/blob/main/app/app.go),
around the `CosmWasm (x/wasm)` initialization). This confirms staking keeper
wiring at that source revision. The inspected code does not explicitly
establish that the Diana v3.2.9 binary routes `StakingQuery::AllDelegations`
from contract execution, and `main` was not matched to the deployed binary.
So this is supporting source evidence only; it does not pass G0-A.

**Probe design:** `Probe { provider }` calls
`deps.querier.query_all_delegations(provider)`, preserves returned delegation
denominations and amounts, aggregates only `uqor` via checked integer
arithmetic, and persists the result and observation height. `LastResult {}`
returns that persisted value. The probe intentionally has no provider registry
or admission policy.

**Exact reproducible local command:**

```powershell
Set-Location contracts/staking-probe
cargo test
cargo build --release --target wasm32-unknown-unknown
```

**Required Diana procedure (not yet run):**

1. Build deterministic Wasm with the currently documented optimizer and record
   image, architecture, SHA-256, source commit, and artifact name.
2. Obtain governance approval to store the exact Wasm; instantiate it without
   an admin; record proposal ID, code ID, address, and code history.
3. Execute `Probe` directly for public provider addresses representing: zero,
   one, multiple, and unbonding delegations. Record each transaction hash and
   compare each stored result to the REST/CLI response for that same address.
4. Approve and pin this exact contract as a bridge target; call the same probe
   through a minimal EVM caller and record the bridge transaction and response.
5. Capture and retain an unsupported-query error if any occurs. An error, an
   incomplete result, or a route that only works off-chain is a **fail**.

**Wasm checksum / code ID / contract address:** optimized Wasm SHA-256 is
`4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`.
No code has been uploaded or instantiated; code ID and contract address are
therefore unavailable.

**Build attempt (24 November 2026):** `cargo build --release --target
wasm32-unknown-unknown` succeeded with Rust 1.93.0. The resulting unoptimized-
by-the-QoreChain-guide artifact is
`contracts/staking-probe/target/wasm32-unknown-unknown/release/qorelease_staking_probe.wasm`,
SHA-256 `EEE375F28CF27C82612DD3E1B1F04E36911827F371C27EC06F4BBAF22867851F`.
This hash is informational only and is not the optimizer artifact checksum.
The original base commit `483b7fa6957719a826f193594680dd635b408dcf` did not contain the probe. Source commit `724729bcfc34bb43131165bbbe49f90dace5926e` is now public; see `docs/SOURCE_PROVENANCE_G0A.md`. The direct Cargo Wasm
is preserved separately at
`artifacts/contracts/qorelease_staking_probe.cargo-diagnostic.wasm`.

**WSL2 optimizer environment inspection (24 November 2026):** WSL reports the
default version is 2; Ubuntu is running as WSL 2 and `docker-desktop` is
installed but stopped. Ubuntu is 24.04.3 LTS on `x86_64`. Docker Desktop is
installed on Windows but no Docker Desktop/backend process was running. The
Windows Docker CLI is present; the Ubuntu Docker CLI is absent and its message
recommends enabling Docker Desktop WSL integration. No daemon could be
contacted, so `docker version`, `docker info`, and `docker context ls` inside
Ubuntu could not complete. Per the runbook, no Docker daemon was installed or
started and no image pull/build was attempted. **OPTIMIZED LOCALLY: NO.**
**REPRODUCIBLE BUILD VERIFIED: NO.** The existing Rust build remains
**TESTED LOCALLY** only; these environment checks do not change G0-A.

Inspection output (PowerShell output decoded from WSL's UTF-16 stream):

```text
wsl --status
Default Distribution: Ubuntu
Default Version: 2

wsl -l -v
  NAME              STATE      VERSION
* Ubuntu            Running    2
  docker-desktop    Stopped    2

Inside Ubuntu:
uname -m: x86_64
PRETTY_NAME="Ubuntu 24.04.3 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION_CODENAME=noble

docker version / docker info / docker context ls:
The command 'docker' could not be found in this WSL 2 distro.
We recommend to activate the WSL integration in Docker Desktop settings.
For details about using Docker Desktop with WSL 2, visit:
https://docs.docker.com/go/wsl2/

Windows inspection:
Docker CLI: C:\Program Files\Docker\Docker\resources\bin\docker.exe
Docker Desktop executable: C:\Program Files\Docker\Docker\Docker Desktop.exe
Docker Desktop/backend processes: none running
```

The WSL inspection above is a historical blocked-state snapshot and was
superseded later on 24 November 2026 when Docker Desktop WSL integration became
available. The successful environment and optimizer results follow.

**Official optimizer build (24 November 2026): OPTIMIZED LOCALLY.** The build
ran in Ubuntu 24.04.3 WSL2 (`x86_64`). Docker Desktop was version 4.44.0; Docker
client and server were 28.3.2 and both reported `linux/amd64`. The approved
image tag was `cosmwasm/optimizer:0.16.1`, pulled for `linux/amd64`. Its
immutable image reference is
`cosmwasm/optimizer@sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e`.
The image reports Rust 1.81.0, Cargo 1.81.0, and `wasm-opt` 116. The probe uses
`cosmwasm-std` 1.5.11. `contracts/staking-probe` is a standalone crate; no root
workspace configuration is present.

The preexisting lock resolved `base64ct 1.8.3` and `zeroize 1.9.2`, which
Cargo 1.81 cannot parse because they require Edition 2024 support. The original
lock is preserved at `docs/evidence/Cargo.lock.before-optimizer`. A lockfile-only
compatibility resolution pins `base64ct 1.7.3` and `zeroize 1.8.1`; no Rust
source or probe logic changed. Keep the resulting
`contracts/staking-probe/Cargo.lock` with the source for reproducible builds.

Exact Ubuntu command, pinned to the pulled image digest:

```bash
cd "/mnt/c/Users/Hari Ram/Documents/chronoquota/contracts/staking-probe"
docker run --rm --platform linux/amd64 -v "$PWD":/code \
  --mount type=volume,source=staking-probe_cache,target=/target \
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
  cosmwasm/optimizer@sha256:b9c92b2900b7ebaab3499203615c1b8589592bc557355ed3432e48851ffde69e
```

The optimizer produced a 169,218-byte `qorelease_staking_probe.wasm`. SHA-256
is `4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`, matching
the optimizer-generated `checksums.txt`. The identical digest-pinned build ran
twice; both Wasm hashes and checksum lines match. **REPRODUCIBLE BUILD VERIFIED.**
The first optimized artifact and checksum, full logs, original lockfile, and
initial dependency compatibility failure logs are retained under
`docs/evidence/`. The artifact and optimizer checksum are at
`artifacts/contracts/`. The direct Cargo Wasm remains separate, 242,869 bytes,
with SHA-256
`eee375f28cf27c82612dd3e1b1f04e36911827f371c27ec06f4bbaf22867851f`.

This build does not pass G0-A. The Diana staking query remains unverified; no
code was uploaded and no proposal was submitted.

**Test accounts / transactions / logs:** none. No account, hybrid key,
governance proposal, or testnet transaction was supplied or invented.

**Observed result:** **TESTED LOCALLY.** The existing note records two local
tests: a
no-delegation result and a multi-delegation result with a checked `uqor`
aggregate while retaining a non-`uqor` denomination. **NOT VERIFIED ON DIANA.**
The existence of the standard CosmWasm API is not runtime evidence.

**Pass or fail:** **UNKNOWN — blocking.**

**Unresolved risks:** whether the Diana query router supports the request from
contract execution; returned denomination/stake-category semantics; malformed
or nonexistent provider behaviour; and bridge-context equivalence.

**Decision / next step:** do not implement provider admission or any product
component dependent on this query until the required deployment evidence is
recorded.

## G0-B — Native bank-message effects through the bridge

**Question:** Can a bridge-invoked Native contract issue `BankMsg::Send` for a
service-bond release or penalty, with all state and balance changes journaled
when either runtime later reverts?

**Observed result:** **NOT VERIFIED.** No contract is deployed; no governed
bridge target or test account is available. The docs demonstrate Native bank
messages, but that does not prove this bridge path.

**Pass or fail:** **UNKNOWN — blocking.**

**Required evidence:** direct success, direct failure, bridge success,
Native-module failure, and a deliberate later EVM revert; each must include
EVM/Native before-and-after balances, transaction hash, and block height.

## G0-C — Sender identity and authorization

**Question:** Does the Native contract see the verified mapped identity of the
deployed Solidity escrow, and does the relevant EVM authorization window admit
the transaction path?

**Observed result:** **NOT VERIFIED.** Live documentation confirms that the
window exists and live precompile activation was verified, but no EVM escrow
exists and no account/window details were provided.

**Pass or fail:** **UNKNOWN — blocking.**

**Required evidence:** deployed escrow address, its exact `qor1...` mapping,
Native `info.sender` observation, current window query output, allowed-target
scope, and a successful plus deliberately out-of-scope call.

## G0-D — Atomicity

**Question:** Are Native reservation state and buyer escrow atomic in this
project's actual cross-VM call path?

**Observed result:** **NOT VERIFIED.** Current docs and live enablement support
the prerequisite only. No QoreLease target or Solidity caller exists.

**Pass or fail:** **UNKNOWN — blocking.**

**Required evidence:** a real Diana transaction for every required case:
success/success; Native rejection; later EVM revert; empty/malformed response;
and inactive/unauthorised bridge handling. The EVM wrapper must fail closed.

## G0-E — Governance feasibility

**Question:** Can the project receive a governed code upload, instantiation,
and bridge allowlist/pin before the demo deadline?

**Observed result:** **PARTIALLY CONFIRMED.** Live state confirms that direct
uploads are disabled and bridge targets are code-pinned. The current normal
proposal deposit is 10 QOR and voting period is four hours. Sponsor/quorum
availability, a hybrid-signing account, and approval for this code are unknown.

**Pass or fail:** **UNKNOWN — blocking.**

**Required evidence:** a reviewed proposal payload, source checksum, governance
proposal ID and final status, actual code ID/contract address/history, and live
allowlist/pin query after approval.

## Go / No-Go recommendation

**NO-GO for product implementation.** Proceed only with the G0 probe work.
The live network prerequisites are promising, but G0-A through G0-D have no
Diana execution evidence and G0-E lacks governance/signer feasibility. Building
the registry, escrow, UI, or service flow now would violate the project’s
mandatory gates.


### Current artifact, provenance, and submission state (24 November 2026)

The pinned optimizer was run twice after local source commit `724729bcfc34bb43131165bbbe49f90dace5926e`, using the committed source and lockfile. Both outputs match SHA-256 `4b0125a5b04a93295ebf6f8f15b4cf866a5c45506425d3eee3251245c6df0509`. Source and lock provenance is documented in `docs/SOURCE_PROVENANCE_G0A.md`; the independent Wasm audit is in `docs/WASM_ARTIFACT_AUDIT.md`.

Source commit `724729bcfc34bb43131165bbbe49f90dace5926e` is now public at [the chronolease commit](https://github.com/hari-ramsss/chronolease/commit/724729bcfc34bb43131165bbbe49f90dace5926e). The existing upload-only Proposal A JSON and payload remain local. No proposal was submitted or passed; no code was uploaded or instantiated. G0-A remains not tested on Diana and not passed.

`cargo audit` reports crypto-bigint RUSTSEC-2026-0387 and curve25519-dalek RUSTSEC-2024-0344 vulnerabilities plus derivative RUSTSEC-2024-0388 unmaintained. The owner accepted the documented residual dependency risks on 24 November 2026, limited to the exact Diana testnet staking-probe source/Wasm identified in `docs/SECURITY_RISK_ACCEPTANCE.md`; this acceptance does not cover future QoreLease product code. The target-specific dependency and Wasm reachability analysis is in `docs/WASM_DEPENDENCY_SECURITY_AUDIT.md`.

The latest read-only Diana preflight is height `10673893` at `2026-11-24T15:08:00.897621278Z`; raw query evidence is `docs/evidence/proposal-a-operator-preflight.json`. Proposal 39 records the v3.2.9 archive name and hashes but omits its URL. The official live manifest and applied-plan query now show v3.2.10 at upgrade height `10654800`; the stale v3.2.9 bundle was not downloaded. Proposal A's Wasm and payload integrity checks pass, but governance submission remains **NOT READY** because no verified archive URL, official CLI/PQC binary, local signing access, or actual gas dry run is available. The owner balance was not queried because no public account address was supplied. G0-A remains untested and not passed. Product implementation remains **NO-GO**. See `docs/evidence/qorechain-release-provenance.json` and `docs/DEPLOYMENT_RUNBOOK.md`.

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
